param(
    [Parameter(Mandatory)][string]$WorkDir,
    [Parameter(Mandatory)][string]$LogPath,
    [string]$AmountColumn   = '',
    [string]$QuantityColumn = '',
    [string]$PriceColumn    = '',
    [string]$DateColumn     = ''
)
$ErrorActionPreference = 'Stop'
. (Join-Path $PSScriptRoot 'pipeline_common.ps1')

Write-Log "Stage 3 - Validate: checking the data is good enough to report on." 'INFO' $LogPath

$in = Join-Path $WorkDir '02_cleaned.csv'
$data = Import-Csv -Path $in
$cols = $data[0].PSObject.Properties.Name
$problems = @()

# resolve amount source the same way the report will
if (-not $AmountColumn)   { $AmountColumn   = Find-Column @('Amount','Total','TotalSales','Sales','Revenue','LineTotal','NetAmount') $cols }
if (-not $QuantityColumn) { $QuantityColumn = Find-Column @('Quantity','Qty','Units','Count') $cols }
if (-not $PriceColumn)    { $PriceColumn    = Find-Column @('UnitPrice','Price','Rate','CostEach') $cols }
if (-not $DateColumn)     { $DateColumn     = Find-Column @('Date','OrderDate','SaleDate','TransactionDate','InvoiceDate') $cols }

# check 1: can we get an amount at all?
$haveAmount = [bool]$AmountColumn
$haveQtyPrice = ($QuantityColumn -and $PriceColumn)
if (-not $haveAmount -and -not $haveQtyPrice) {
    $problems += "No amount column found, and no quantity + price pair to calculate one. Name the column with -AmountColumn (or -QuantityColumn and -PriceColumn)."
}

# check 2: are the amount-related values actually numeric?
$badNums = 0
foreach ($r in $data) {
    if ($haveAmount) {
        if ($null -eq (To-Number $r.$AmountColumn)) { $badNums++ }
    } elseif ($haveQtyPrice) {
        if (($null -eq (To-Number $r.$QuantityColumn)) -or ($null -eq (To-Number $r.$PriceColumn))) { $badNums++ }
    }
}
if (($haveAmount -or $haveQtyPrice) -and $badNums -gt 0) {
    $pct = [math]::Round(($badNums / $data.Count) * 100, 1)
    if ($pct -ge 20) {
        $problems += "$badNums rows ($pct%) have an amount that is not a number. The source data needs fixing before reporting."
    } else {
        Write-Log "Note: $badNums rows ($pct%) have a non-numeric amount and will count as 0." 'WARN' $LogPath
    }
}

# check 3: if a date column exists, can at least some dates be read?
if ($DateColumn) {
    $goodDates = 0
    foreach ($r in $data) {
        $dt = [datetime]::MinValue
        if ([datetime]::TryParse($r.$DateColumn, [ref]$dt)) { $goodDates++ }
    }
    if ($goodDates -eq 0) {
        Write-Log "Note: the date column '$DateColumn' had no readable dates. Time breakdowns will be empty." 'WARN' $LogPath
    }
}

if ($problems.Count -gt 0) {
    Write-Log "Validation failed. The pipeline stopped so no misleading report is produced:" 'ERROR' $LogPath
    foreach ($p in $problems) { Write-Log "  - $p" 'ERROR' $LogPath }
    Write-Log "Fix the source file and run the pipeline again." 'ERROR' $LogPath
    throw "Validation failed."
}

# passes: copy forward unchanged so the file chain stays numbered
$out = Join-Path $WorkDir '03_validated.csv'
$data | Export-Csv -Path $out -NoTypeInformation -Encoding UTF8
Write-Log "Validation passed. Data is good to report on." 'OK' $LogPath
Write-Log "Stage 3 complete. Saved $out" 'OK' $LogPath
