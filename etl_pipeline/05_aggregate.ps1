param(
    [Parameter(Mandatory)][string]$WorkDir,
    [Parameter(Mandatory)][string]$LogPath
)
$ErrorActionPreference = 'Stop'
. (Join-Path $PSScriptRoot 'pipeline_common.ps1')

Write-Log "Stage 5 - Aggregate: calculating totals, averages and rankings." 'INFO' $LogPath

$in = Join-Path $WorkDir '04_transformed.csv'
$rows = Import-Csv -Path $in
# Amount comes back as text from CSV; convert once
$rows = $rows | ForEach-Object {
    $_.Amount = [double]$_.Amount
    $_
}

$totalSales = [math]::Round(($rows | Measure-Object Amount -Sum).Sum, 2)
$txnCount   = $rows.Count
$avgPerTxn  = if ($txnCount) { [math]::Round($totalSales / $txnCount, 2) } else { 0 }
$uniqueCust = ($rows | Where-Object { $_.Customer -and $_.Customer -ne 'Unknown' } |
               Select-Object -ExpandProperty Customer -Unique).Count
$avgPerCust = if ($uniqueCust) { [math]::Round($totalSales / $uniqueCust, 2) } else { 0 }

$summary = [PSCustomObject]@{
    TotalSales = $totalSales; TransactionCount = $txnCount; AveragePerTxn = $avgPerTxn
    UniqueCustomers = $uniqueCust; AveragePerCustomer = $avgPerCust
}

$topProducts = $rows | Group-Object Product | ForEach-Object {
    [PSCustomObject]@{ Product = $_.Name; Sales = [math]::Round(($_.Group | Measure-Object Amount -Sum).Sum,2); Orders = $_.Count }
} | Sort-Object Sales -Descending | Select-Object -First 10

$topCustomers = $rows | Group-Object Customer | ForEach-Object {
    [PSCustomObject]@{ Customer = $_.Name; Sales = [math]::Round(($_.Group | Measure-Object Amount -Sum).Sum,2); Orders = $_.Count }
} | Sort-Object Sales -Descending | Select-Object -First 10

$byMonth = $rows | Where-Object { $_.Date } | Group-Object { ([datetime]$_.Date).ToString('yyyy-MM') } | ForEach-Object {
    [PSCustomObject]@{ Month = $_.Name; Sales = [math]::Round(($_.Group | Measure-Object Amount -Sum).Sum,2) }
} | Sort-Object Month

$byDay = $rows | Where-Object { $_.Date } | Group-Object { ([datetime]$_.Date).ToString('yyyy-MM-dd') } | ForEach-Object {
    [PSCustomObject]@{ Day = $_.Name; Sales = [math]::Round(($_.Group | Measure-Object Amount -Sum).Sum,2) }
} | Sort-Object Day

$summary      | Export-Csv (Join-Path $WorkDir '05_summary.csv')        -NoTypeInformation -Encoding UTF8
$topProducts  | Export-Csv (Join-Path $WorkDir '05_top_products.csv')   -NoTypeInformation -Encoding UTF8
$topCustomers | Export-Csv (Join-Path $WorkDir '05_top_customers.csv')  -NoTypeInformation -Encoding UTF8
$byMonth      | Export-Csv (Join-Path $WorkDir '05_sales_by_month.csv') -NoTypeInformation -Encoding UTF8
$byDay        | Export-Csv (Join-Path $WorkDir '05_sales_by_day.csv')   -NoTypeInformation -Encoding UTF8

Write-Log "Total sales $totalSales across $txnCount transactions." 'INFO' $LogPath
Write-Log "Stage 5 complete. Saved 5 summary files." 'OK' $LogPath
