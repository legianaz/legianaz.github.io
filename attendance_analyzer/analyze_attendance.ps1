param(
    [Parameter(Mandatory)][string]$CsvPath,
    [string]$ShiftStart = '09:00',   # expected start time, 24h HH:mm
    [int]$GraceMinutes  = 0,         # minutes after ShiftStart before a punch counts as late
    [double]$DailyOtThreshold  = 8,  # hours per day beyond which daily OT accrues
    [double]$WeeklyOtThreshold = 40, # hours per week beyond which weekly OT accrues
    [string]$OutputDir = ''
)

# analyze_attendance.ps1
# Reads a daily attendance CSV and summarizes hours, lateness, overtime, absences.
# Format expected: one row per employee per day, with time-in / time-out columns,
# optional break-in / break-out columns, and an optional status column.
# Late, grace, and overtime thresholds are all parameters so the same tool fits
# different workplace rules. Runs locally. Source file is read, never modified.

$ErrorActionPreference = 'Stop'

if (-not (Test-Path $CsvPath)) { Write-Error "Could not find the file: $CsvPath"; return }
$data = Import-Csv -Path $CsvPath
if (-not $data -or $data.Count -eq 0) { Write-Error "The file has no rows."; return }
$cols = $data[0].PSObject.Properties.Name

# --- find the columns we need, tolerant of naming ---
function Find-Col {
    param([string[]]$cands)
    foreach ($c in $cands) {
        $hit = $cols | Where-Object { ($_ -replace '[\s_]','') -ieq ($c -replace '[\s_]','') } | Select-Object -First 1
        if ($hit) { return $hit }
    }
    return $null
}
$empCol     = Find-Col @('Employee','EmployeeName','Name','EmpID','EmployeeID')
$dateCol    = Find-Col @('Date','WorkDate','Day')
$inCol      = Find-Col @('TimeIn','ClockIn','In','StartTime','PunchIn')
$outCol     = Find-Col @('TimeOut','ClockOut','Out','EndTime','PunchOut')
$bInCol     = Find-Col @('BreakIn','BreakStart','LunchOut','BreakOut')
$bOutCol    = Find-Col @('BreakOut','BreakEnd','LunchIn','BreakIn')
$statusCol  = Find-Col @('Status','Attendance','State')

# break columns are ambiguous by name; resolve them explicitly if both exist
$breakStartCol = Find-Col @('BreakStart','BreakIn','LunchStart','LunchOut')
$breakEndCol   = Find-Col @('BreakEnd','BreakOut','LunchEnd','LunchIn')

if (-not $empCol)  { Write-Error "No employee/name column found."; return }
if (-not $dateCol) { Write-Error "No date column found."; return }
if (-not $inCol -or -not $outCol) { Write-Error "Need both a time-in and a time-out column."; return }

# --- time parsing helper: returns a DateTime on a common base date, or $null ---
function Parse-Time {
    param($v)
    if ([string]::IsNullOrWhiteSpace($v)) { return $null }
    $dt = [datetime]::MinValue
    if ([datetime]::TryParse($v, [ref]$dt)) { return $dt }
    return $null
}

# shift start as minutes-after-midnight for late comparison
$shiftDt = [datetime]::MinValue
if (-not [datetime]::TryParse($ShiftStart, [ref]$shiftDt)) { Write-Error "ShiftStart '$ShiftStart' is not a valid time."; return }
$shiftMinutes = $shiftDt.Hour * 60 + $shiftDt.Minute + $GraceMinutes

# --- per-row calculations ---
$records = foreach ($r in $data) {
    $emp  = $r.$empCol
    $date = $r.$dateCol
    $status = if ($statusCol) { "$($r.$statusCol)".Trim() } else { '' }

    $isAbsent = ($status -match '^(absent|leave|off|no\s*show)$')

    $tin  = Parse-Time $r.$inCol
    $tout = Parse-Time $r.$outCol

    # if no times and not explicitly marked, treat blank work times as absent
    if (-not $tin -or -not $tout) {
        if (-not $isAbsent -and [string]::IsNullOrWhiteSpace($status)) { $isAbsent = $true }
    }

    $worked = 0.0
    $late = $false
    $lateBy = 0

    if (-not $isAbsent -and $tin -and $tout) {
        $span = ($tout - $tin).TotalHours
        if ($span -lt 0) { $span += 24 }  # crossed midnight

        # subtract break if both break columns parse
        if ($breakStartCol -and $breakEndCol) {
            $bs = Parse-Time $r.$breakStartCol
            $be = Parse-Time $r.$breakEndCol
            if ($bs -and $be) {
                $bspan = ($be - $bs).TotalHours
                if ($bspan -lt 0) { $bspan += 24 }
                if ($bspan -gt 0 -and $bspan -lt $span) { $span -= $bspan }
            }
        }
        $worked = [math]::Round($span, 2)

        # lateness from time-in vs shift start + grace
        $inMinutes = $tin.Hour * 60 + $tin.Minute
        if ($inMinutes -gt $shiftMinutes) {
            $late = $true
            $lateBy = $inMinutes - $shiftMinutes
        }
    }

    $dailyOt = if ($worked -gt $DailyOtThreshold) { [math]::Round($worked - $DailyOtThreshold, 2) } else { 0 }

    # week key for weekly rollup (ISO-ish: year + week number)
    $weekKey = ''
    $dParsed = [datetime]::MinValue
    if ([datetime]::TryParse($date, [ref]$dParsed)) {
        $cal = [System.Globalization.CultureInfo]::InvariantCulture.Calendar
        $wk = $cal.GetWeekOfYear($dParsed, [System.Globalization.CalendarWeekRule]::FirstFourDayWeek, [System.DayOfWeek]::Monday)
        $weekKey = "{0}-W{1:D2}" -f $dParsed.Year, $wk
    }

    [PSCustomObject]@{
        Employee   = $emp
        Date       = $date
        WeekKey    = $weekKey
        Status     = if ($isAbsent) { 'Absent' } elseif ($status) { $status } else { 'Present' }
        HoursWorked= $worked
        Late       = $late
        LateByMin  = $lateBy
        DailyOT    = $dailyOt
        Absent     = $isAbsent
    }
}

# --- weekly overtime per employee per week ---
$weekly = $records | Where-Object { $_.WeekKey -and -not $_.Absent } |
    Group-Object Employee, WeekKey | ForEach-Object {
        $wkHours = [math]::Round(($_.Group | Measure-Object HoursWorked -Sum).Sum, 2)
        $wkOt = if ($wkHours -gt $WeeklyOtThreshold) { [math]::Round($wkHours - $WeeklyOtThreshold, 2) } else { 0 }
        [PSCustomObject]@{
            Employee  = $_.Group[0].Employee
            Week      = $_.Group[0].WeekKey
            WeekHours = $wkHours
            WeeklyOT  = $wkOt
        }
    }

# --- per-employee summary ---
$summary = $records | Group-Object Employee | ForEach-Object {
    $g = $_.Group
    $emp = $_.Name
    $empWeekly = $weekly | Where-Object Employee -eq $emp
    [PSCustomObject]@{
        Employee      = $emp
        DaysPresent   = ($g | Where-Object { -not $_.Absent }).Count
        DaysAbsent    = ($g | Where-Object { $_.Absent }).Count
        TotalHours    = [math]::Round(($g | Measure-Object HoursWorked -Sum).Sum, 2)
        AvgHoursPerDay= if (($g | Where-Object { -not $_.Absent }).Count) { [math]::Round((($g | Measure-Object HoursWorked -Sum).Sum) / ($g | Where-Object { -not $_.Absent }).Count, 2) } else { 0 }
        LateCount     = ($g | Where-Object { $_.Late }).Count
        TotalLateMin  = ($g | Measure-Object LateByMin -Sum).Sum
        DailyOT_Hours = [math]::Round(($g | Measure-Object DailyOT -Sum).Sum, 2)
        WeeklyOT_Hours= [math]::Round(($empWeekly | Measure-Object WeeklyOT -Sum).Sum, 2)
    }
} | Sort-Object Employee

# --- output folder ---
if (-not $OutputDir) {
    $base  = Split-Path $CsvPath -Parent
    $stamp = Get-Date -Format 'yyyyMMdd_HHmmss'
    $OutputDir = Join-Path $base "attendance_report_$stamp"
}
if (-not (Test-Path $OutputDir)) { New-Item -ItemType Directory -Path $OutputDir | Out-Null }

# --- totals for the cards ---
$totalEmp     = ($summary | Measure-Object).Count
$totalHours   = [math]::Round(($summary | Measure-Object TotalHours -Sum).Sum, 2)
$totalLate    = ($summary | Measure-Object LateCount -Sum).Sum
$totalAbsent  = ($summary | Measure-Object DaysAbsent -Sum).Sum
$totalDailyOT = [math]::Round(($summary | Measure-Object DailyOT_Hours -Sum).Sum, 2)
$totalWeeklyOT= [math]::Round(($summary | Measure-Object WeeklyOT_Hours -Sum).Sum, 2)

# --- HTML report (always) ---
Add-Type -AssemblyName System.Web
function HtmlRows {
    param($items, [string[]]$props)
    ($items | ForEach-Object {
        $r = $_
        "<tr>" + (($props | ForEach-Object { "<td>$([System.Web.HttpUtility]::HtmlEncode("$($r.$_)"))</td>" }) -join '') + "</tr>"
    }) -join "`n"
}
$sumProps = @('Employee','DaysPresent','DaysAbsent','TotalHours','AvgHoursPerDay','LateCount','TotalLateMin','DailyOT_Hours','WeeklyOT_Hours')
$sumRows = HtmlRows $summary $sumProps
$reportDate = Get-Date -Format 'yyyy-MM-dd HH:mm'

$html = @"
<!DOCTYPE html>
<html lang="en"><head><meta charset="utf-8"><title>Attendance Report</title>
<style>
 body{font-family:Segoe UI,Arial,sans-serif;margin:40px;color:#222;background:#fafafa}
 h1{margin-bottom:2px} .sub{color:#777;margin-top:0;font-size:14px}
 .cards{display:flex;flex-wrap:wrap;gap:14px;margin:24px 0}
 .card{background:#fff;border:1px solid #e3e3e3;border-radius:10px;padding:16px 20px;min-width:130px}
 .card .l{font-size:12px;color:#888;text-transform:uppercase;letter-spacing:.5px}
 .card .v{font-size:24px;font-weight:700;margin-top:6px;color:#5b3f8c}
 h2{margin-top:34px;border-bottom:2px solid #5b3f8c;padding-bottom:6px}
 table{border-collapse:collapse;width:100%;background:#fff;margin-top:10px;font-size:13px}
 th,td{text-align:left;padding:8px 10px;border-bottom:1px solid #eee}
 th{background:#5b3f8c;color:#fff} tr:nth-child(even) td{background:#f6f4fb}
 .rules{background:#fff;border:1px solid #e3e3e3;border-radius:10px;padding:14px 18px;font-size:13px;color:#555}
 .foot{margin-top:36px;color:#999;font-size:12px}
</style></head><body>
<h1>Attendance Report</h1>
<p class="sub">Generated $reportDate &nbsp;|&nbsp; Source: $(Split-Path $CsvPath -Leaf)</p>
<div class="cards">
 <div class="card"><div class="l">Employees</div><div class="v">$totalEmp</div></div>
 <div class="card"><div class="l">Total hours</div><div class="v">$totalHours</div></div>
 <div class="card"><div class="l">Late instances</div><div class="v">$totalLate</div></div>
 <div class="card"><div class="l">Absences</div><div class="v">$totalAbsent</div></div>
 <div class="card"><div class="l">Daily OT hrs</div><div class="v">$totalDailyOT</div></div>
 <div class="card"><div class="l">Weekly OT hrs</div><div class="v">$totalWeeklyOT</div></div>
</div>
<div class="rules"><b>Rules applied:</b> shift start $ShiftStart, grace $GraceMinutes min (late after that).
Daily OT above $DailyOtThreshold hrs/day. Weekly OT above $WeeklyOtThreshold hrs/week.
Daily and weekly OT are reported separately and are not reconciled against each other.</div>
<h2>Per-employee summary</h2>
<table><tr>$(($sumProps | ForEach-Object { "<th>$_</th>" }) -join '')</tr>
$sumRows</table>
<p class="foot">All processing ran locally. No data left this machine. Source file was not modified.</p>
</body></html>
"@
$htmlPath = Join-Path $OutputDir 'attendance_report.html'
$html | Out-File -FilePath $htmlPath -Encoding UTF8

# --- Excel if ImportExcel present, else CSV fallback ---
$excelMade = $false
if (Get-Module -ListAvailable -Name ImportExcel) {
    try {
        Import-Module ImportExcel -ErrorAction Stop
        $xlsx = Join-Path $OutputDir 'attendance_report.xlsx'
        if (Test-Path $xlsx) { Remove-Item $xlsx }
        $summary | Export-Excel -Path $xlsx -WorksheetName 'Summary' -AutoSize -BoldTopRow -FreezeTopRow
        $records | Select-Object Employee,Date,Status,HoursWorked,Late,LateByMin,DailyOT |
            Export-Excel -Path $xlsx -WorksheetName 'Daily detail' -AutoSize -BoldTopRow -FreezeTopRow
        $weekly  | Export-Excel -Path $xlsx -WorksheetName 'Weekly OT' -AutoSize -BoldTopRow -FreezeTopRow
        $excelMade = $true
        Write-Host "Excel report written (ImportExcel): $xlsx"
    } catch {
        Write-Host "ImportExcel found but failed; falling back to CSV. $_"
    }
}
if (-not $excelMade) {
    $summary | Export-Csv (Join-Path $OutputDir 'attendance_summary.csv')  -NoTypeInformation -Encoding UTF8
    $records | Select-Object Employee,Date,Status,HoursWorked,Late,LateByMin,DailyOT |
        Export-Csv (Join-Path $OutputDir 'attendance_daily.csv') -NoTypeInformation -Encoding UTF8
    $weekly  | Export-Csv (Join-Path $OutputDir 'attendance_weekly_ot.csv') -NoTypeInformation -Encoding UTF8
    Write-Host "ImportExcel not installed. Wrote CSVs instead. (Install-Module ImportExcel for native .xlsx)"
}

Write-Host ""
Write-Host "Analyzed $($records.Count) day-records for $totalEmp employee(s)."
Write-Host "Total hours $totalHours | Late $totalLate | Absences $totalAbsent | Daily OT $totalDailyOT | Weekly OT $totalWeeklyOT"
Write-Host "Open the report: $htmlPath"
