param(
    [Parameter(Mandatory)][string]$CsvPath,
    [string]$OutputDir = ''
)

# profile_data.ps1
# Standalone data quality profiler. Reads any CSV and reports what is inside it,
# how clean it is, and what issues to fix before using it.
# Outputs: HTML always; real .xlsx if the ImportExcel module is present, else CSVs.
# No data leaves the machine. The source file is only read, never modified.

$ErrorActionPreference = 'Stop'

# --- load ---
if (-not (Test-Path $CsvPath)) { Write-Error "Could not find the file: $CsvPath"; return }
$data = Import-Csv -Path $CsvPath
if (-not $data -or $data.Count -eq 0) { Write-Error "The file has no rows."; return }
$cols = $data[0].PSObject.Properties.Name
$rowCount = $data.Count

# --- helpers ---
function To-Number {
    param($v)
    if ($null -eq $v) { return $null }
    $c = "$v" -replace '[\$,\s]', ''
    $n = 0.0
    if ([double]::TryParse($c, [ref]$n)) { return $n }
    return $null
}

function Get-Median {
    param([double[]]$nums)
    if ($nums.Count -eq 0) { return $null }
    $sorted = $nums | Sort-Object
    $mid = [int]($sorted.Count / 2)
    if ($sorted.Count % 2 -eq 0) {
        return [math]::Round((($sorted[$mid - 1] + $sorted[$mid]) / 2), 2)
    }
    return [math]::Round($sorted[$mid], 2)
}

function Get-Percentile {
    param([double[]]$sorted, [double]$p)
    # linear interpolation between closest ranks
    if ($sorted.Count -eq 1) { return $sorted[0] }
    $rank = $p * ($sorted.Count - 1)
    $low  = [math]::Floor($rank)
    $high = [math]::Ceiling($rank)
    if ($low -eq $high) { return $sorted[[int]$low] }
    $frac = $rank - $low
    return $sorted[[int]$low] + $frac * ($sorted[[int]$high] - $sorted[[int]$low])
}

# --- detect column kinds by sampling values ---
function Get-ColumnKind {
    param([string]$col)
    $vals = $data | ForEach-Object { $_.$col } | Where-Object { -not [string]::IsNullOrWhiteSpace($_) }
    if ($vals.Count -eq 0) { return 'empty' }
    $sample = $vals | Select-Object -First 50

    $numHits = 0; $dateHits = 0; $emailHits = 0
    foreach ($v in $sample) {
        if ($null -ne (To-Number $v)) { $numHits++ }
        $dt = [datetime]::MinValue
        if ([datetime]::TryParse($v, [ref]$dt)) { $dateHits++ }
        if ($v -match '^[^@\s]+@[^@\s]+\.[^@\s]+$') { $emailHits++ }
    }
    $n = $sample.Count
    if ($emailHits / $n -ge 0.7) { return 'email' }
    if ($numHits  / $n -ge 0.8) { return 'number' }
    # only call it a date if it parses AND is not mostly numeric (avoids treating IDs as dates)
    if ($dateHits / $n -ge 0.7 -and $numHits / $n -lt 0.8) { return 'date' }
    return 'text'
}

# --- per-column profile ---
$profile = foreach ($col in $cols) {
    $raw = $data | ForEach-Object { $_.$col }
    $nonBlank = $raw | Where-Object { -not [string]::IsNullOrWhiteSpace($_) }
    $missing = $rowCount - $nonBlank.Count
    $completeness = [math]::Round((($rowCount - $missing) / $rowCount) * 100, 1)
    $distinct = ($nonBlank | Select-Object -Unique).Count
    $kind = Get-ColumnKind $col

    $obj = [ordered]@{
        Column        = $col
        Type          = $kind
        Rows          = $rowCount
        Missing       = $missing
        'Complete %'  = $completeness
        Distinct      = $distinct
        Min           = ''
        Max           = ''
        Average       = ''
        Median        = ''
        Issues        = ''
    }

    $issues = @()

    if ($kind -eq 'number') {
        $nums = @()
        foreach ($v in $nonBlank) { $x = To-Number $v; if ($null -ne $x) { $nums += $x } }
        if ($nums.Count -gt 0) {
            $sorted = $nums | Sort-Object
            $obj.Min     = [math]::Round(($nums | Measure-Object -Minimum).Minimum, 2)
            $obj.Max     = [math]::Round(($nums | Measure-Object -Maximum).Maximum, 2)
            $obj.Average = [math]::Round(($nums | Measure-Object -Average).Average, 2)
            $obj.Median  = Get-Median $nums

            # IQR outliers: values beyond 1.5x the interquartile range
            $q1 = Get-Percentile $sorted 0.25
            $q3 = Get-Percentile $sorted 0.75
            $iqr = $q3 - $q1
            $lowFence  = $q1 - 1.5 * $iqr
            $highFence = $q3 + 1.5 * $iqr
            $outliers = ($nums | Where-Object { $_ -lt $lowFence -or $_ -gt $highFence }).Count
            if ($outliers -gt 0) { $issues += "$outliers outlier(s)" }

            # negatives: flagged where a column reads like a money/count field
            if ($col -match 'amount|price|qty|quantity|total|cost|revenue|sales|count|hours|age') {
                $neg = ($nums | Where-Object { $_ -lt 0 }).Count
                if ($neg -gt 0) { $issues += "$neg negative value(s) in a column that likely should not be negative" }
            }
        }
    }
    elseif ($kind -eq 'email') {
        $bad = ($nonBlank | Where-Object { $_ -notmatch '^[^@\s]+@[^@\s]+\.[^@\s]+$' }).Count
        if ($bad -gt 0) { $issues += "$bad invalid email(s)" }
    }
    elseif ($kind -eq 'date') {
        $bad = 0
        foreach ($v in $nonBlank) { $dt = [datetime]::MinValue; if (-not [datetime]::TryParse($v, [ref]$dt)) { $bad++ } }
        if ($bad -gt 0) { $issues += "$bad unreadable date(s)" }
    }

    if ($missing -gt 0) { $issues += "$missing missing value(s)" }

    $obj.Issues = if ($issues.Count) { $issues -join '; ' } else { 'none' }
    [PSCustomObject]$obj
}

# --- dataset-level summary ---
$seen = @{}
$dupCount = 0
foreach ($row in $data) {
    $key = ($cols | ForEach-Object { "$($row.$_)" }) -join '|~|'
    if ($seen.ContainsKey($key)) { $dupCount++ } else { $seen[$key] = $true }
}
$totalMissing = ($profile | Measure-Object Missing -Sum).Sum
$cellCount = $rowCount * $cols.Count
$overallComplete = [math]::Round((($cellCount - $totalMissing) / $cellCount) * 100, 1)
$colsWithIssues = ($profile | Where-Object { $_.Issues -ne 'none' }).Count

$datasetSummary = [PSCustomObject]@{
    File              = Split-Path $CsvPath -Leaf
    Rows              = $rowCount
    Columns           = $cols.Count
    'Duplicate rows'  = $dupCount
    'Total missing'   = $totalMissing
    'Overall complete %' = $overallComplete
    'Columns with issues' = $colsWithIssues
}

# --- output folder ---
if (-not $OutputDir) {
    $base  = Split-Path $CsvPath -Parent
    $stamp = Get-Date -Format 'yyyyMMdd_HHmmss'
    $name  = [System.IO.Path]::GetFileNameWithoutExtension($CsvPath)
    $OutputDir = Join-Path $base "profile_${name}_$stamp"
}
if (-not (Test-Path $OutputDir)) { New-Item -ItemType Directory -Path $OutputDir | Out-Null }

# --- HTML report (always) ---
Add-Type -AssemblyName System.Web
function HtmlRows {
    param($items, [string[]]$props)
    ($items | ForEach-Object {
        $r = $_
        "<tr>" + (($props | ForEach-Object {
            $cell = [System.Web.HttpUtility]::HtmlEncode("$($r.$_)")
            if ($_ -eq 'Issues' -and "$($r.$_)" -ne 'none') { "<td class='warn'>$cell</td>" } else { "<td>$cell</td>" }
        }) -join '') + "</tr>"
    }) -join "`n"
}

$profileProps = @('Column','Type','Missing','Complete %','Distinct','Min','Max','Average','Median','Issues')
$profileRows = HtmlRows $profile $profileProps
$reportDate = Get-Date -Format 'yyyy-MM-dd HH:mm'

$healthColor = if ($overallComplete -ge 95 -and $colsWithIssues -eq 0) { '#1d9e75' }
               elseif ($overallComplete -ge 80) { '#ba7517' } else { '#a32d2d' }

$html = @"
<!DOCTYPE html>
<html lang="en"><head><meta charset="utf-8"><title>Data Profile</title>
<style>
 body{font-family:Segoe UI,Arial,sans-serif;margin:40px;color:#222;background:#fafafa}
 h1{margin-bottom:2px} .sub{color:#777;margin-top:0;font-size:14px}
 .cards{display:flex;flex-wrap:wrap;gap:14px;margin:24px 0}
 .card{background:#fff;border:1px solid #e3e3e3;border-radius:10px;padding:16px 20px;min-width:130px}
 .card .l{font-size:12px;color:#888;text-transform:uppercase;letter-spacing:.5px}
 .card .v{font-size:24px;font-weight:700;margin-top:6px;color:#5b3f8c}
 .health{font-size:24px;font-weight:700;color:$healthColor}
 h2{margin-top:34px;border-bottom:2px solid #5b3f8c;padding-bottom:6px}
 table{border-collapse:collapse;width:100%;background:#fff;margin-top:10px;font-size:13px}
 th,td{text-align:left;padding:8px 10px;border-bottom:1px solid #eee}
 th{background:#5b3f8c;color:#fff} tr:nth-child(even) td{background:#f6f4fb}
 td.warn{color:#a32d2d} .foot{margin-top:36px;color:#999;font-size:12px}
</style></head><body>
<h1>Data Profile Report</h1>
<p class="sub">Generated $reportDate &nbsp;|&nbsp; Source: $($datasetSummary.File)</p>
<div class="cards">
 <div class="card"><div class="l">Rows</div><div class="v">$rowCount</div></div>
 <div class="card"><div class="l">Columns</div><div class="v">$($cols.Count)</div></div>
 <div class="card"><div class="l">Duplicate rows</div><div class="v">$dupCount</div></div>
 <div class="card"><div class="l">Missing cells</div><div class="v">$totalMissing</div></div>
 <div class="card"><div class="l">Overall complete</div><div class="health">$overallComplete%</div></div>
 <div class="card"><div class="l">Columns w/ issues</div><div class="v">$colsWithIssues</div></div>
</div>
<h2>Column profile</h2>
<table><tr>$(($profileProps | ForEach-Object { "<th>$_</th>" }) -join '')</tr>
$profileRows</table>
<p class="foot">All processing ran locally. No data left this machine. Source file was not modified.<br>
Outliers flagged using the IQR method: values beyond 1.5x the interquartile range.</p>
</body></html>
"@
$htmlPath = Join-Path $OutputDir 'data_profile.html'
$html | Out-File -FilePath $htmlPath -Encoding UTF8

# --- Excel if ImportExcel present, else CSV fallback ---
$excelMade = $false
if (Get-Module -ListAvailable -Name ImportExcel) {
    try {
        Import-Module ImportExcel -ErrorAction Stop
        $xlsx = Join-Path $OutputDir 'data_profile.xlsx'
        if (Test-Path $xlsx) { Remove-Item $xlsx }
        $datasetSummary | Export-Excel -Path $xlsx -WorksheetName 'Summary' -AutoSize -BoldTopRow
        $profile        | Export-Excel -Path $xlsx -WorksheetName 'Column profile' -AutoSize -BoldTopRow -FreezeTopRow
        $excelMade = $true
        Write-Host "Excel report written (ImportExcel): $xlsx"
    } catch {
        Write-Host "ImportExcel found but failed; falling back to CSV. $_"
    }
}
if (-not $excelMade) {
    $datasetSummary | Export-Csv (Join-Path $OutputDir 'profile_summary.csv') -NoTypeInformation -Encoding UTF8
    $profile        | Export-Csv (Join-Path $OutputDir 'profile_columns.csv') -NoTypeInformation -Encoding UTF8
    Write-Host "ImportExcel not installed. Wrote CSVs instead. (Install-Module ImportExcel for native .xlsx)"
}

Write-Host ""
Write-Host "Profiled $rowCount rows across $($cols.Count) columns."
Write-Host "Overall completeness: $overallComplete%   Duplicate rows: $dupCount   Columns with issues: $colsWithIssues"
Write-Host "Open the report: $htmlPath"
