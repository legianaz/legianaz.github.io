param(
    [Parameter(Mandatory)][string]$WorkDir,
    [Parameter(Mandatory)][string]$OutputDir,
    [Parameter(Mandatory)][string]$LogPath,
    [string]$SourceName = ''
)
$ErrorActionPreference = 'Stop'
. (Join-Path $PSScriptRoot 'pipeline_common.ps1')

Write-Log "Stage 6 - Load: building the HTML dashboard." 'INFO' $LogPath

$summary      = Import-Csv (Join-Path $WorkDir '05_summary.csv')
$topProducts  = Import-Csv (Join-Path $WorkDir '05_top_products.csv')
$topCustomers = Import-Csv (Join-Path $WorkDir '05_top_customers.csv')
$byMonth      = Import-Csv (Join-Path $WorkDir '05_sales_by_month.csv')
$byDay        = Import-Csv (Join-Path $WorkDir '05_sales_by_day.csv')

function To-Rows {
    param($Items, [string[]]$Props)
    if (-not $Items) { return "<tr><td colspan='$($Props.Count)' style='color:#999'>No data</td></tr>" }
    ($Items | ForEach-Object {
        $r = $_
        "<tr>" + (($Props | ForEach-Object { "<td>$([System.Web.HttpUtility]::HtmlEncode($r.$_))</td>" }) -join '') + "</tr>"
    }) -join "`n"
}
Add-Type -AssemblyName System.Web

$reportDate = Get-Date -Format 'yyyy-MM-dd HH:mm'
$prodRows = To-Rows $topProducts  @('Product','Sales','Orders')
$custRows = To-Rows $topCustomers @('Customer','Sales','Orders')
$monRows  = To-Rows $byMonth      @('Month','Sales')
$dayRows  = To-Rows $byDay        @('Day','Sales')

$s = $summary

$html = @"
<!DOCTYPE html>
<html lang="en">
<head>
<meta charset="utf-8">
<title>Daily Sales Report</title>
<style>
  body { font-family: Segoe UI, Arial, sans-serif; margin: 40px; color: #222; background: #fafafa; }
  h1 { margin-bottom: 4px; }
  .sub { color: #777; margin-top: 0; font-size: 14px; }
  .cards { display: flex; flex-wrap: wrap; gap: 16px; margin: 24px 0; }
  .card { background: #fff; border: 1px solid #e3e3e3; border-radius: 10px; padding: 18px 22px; min-width: 150px; }
  .card .label { font-size: 12px; color: #888; text-transform: uppercase; letter-spacing: .5px; }
  .card .value { font-size: 26px; font-weight: 700; margin-top: 6px; color: #5b3f8c; }
  h2 { margin-top: 36px; border-bottom: 2px solid #5b3f8c; padding-bottom: 6px; }
  table { border-collapse: collapse; width: 100%; background: #fff; margin-top: 10px; }
  th, td { text-align: left; padding: 9px 12px; border-bottom: 1px solid #eee; font-size: 14px; }
  th { background: #5b3f8c; color: #fff; }
  tr:nth-child(even) td { background: #f6f4fb; }
  .foot { margin-top: 40px; color: #999; font-size: 12px; }
</style>
</head>
<body>
  <h1>Daily Sales Report</h1>
  <p class="sub">Generated $reportDate &nbsp;|&nbsp; Source: $SourceName</p>
  <div class="cards">
    <div class="card"><div class="label">Total Sales</div><div class="value">$($s.TotalSales)</div></div>
    <div class="card"><div class="label">Transactions</div><div class="value">$($s.TransactionCount)</div></div>
    <div class="card"><div class="label">Avg / Transaction</div><div class="value">$($s.AveragePerTxn)</div></div>
    <div class="card"><div class="label">Unique Customers</div><div class="value">$($s.UniqueCustomers)</div></div>
    <div class="card"><div class="label">Avg / Customer</div><div class="value">$($s.AveragePerCustomer)</div></div>
  </div>
  <h2>Top 10 Products</h2>
  <table><tr><th>Product</th><th>Sales</th><th>Orders</th></tr>$prodRows</table>
  <h2>Top 10 Customers</h2>
  <table><tr><th>Customer</th><th>Sales</th><th>Orders</th></tr>$custRows</table>
  <h2>Sales by Month</h2>
  <table><tr><th>Month</th><th>Sales</th></tr>$monRows</table>
  <h2>Sales by Day</h2>
  <table><tr><th>Day</th><th>Sales</th></tr>$dayRows</table>
  <p class="foot">All processing ran locally. No data left this machine.</p>
</body>
</html>
"@

if (-not (Test-Path $OutputDir)) { New-Item -ItemType Directory -Path $OutputDir | Out-Null }
$htmlPath = Join-Path $OutputDir 'sales_report.html'
$html | Out-File -FilePath $htmlPath -Encoding UTF8

# copy the final summary CSVs to the output folder for Power BI / Excel
Copy-Item (Join-Path $WorkDir '05_summary.csv')        (Join-Path $OutputDir 'summary.csv')        -Force
Copy-Item (Join-Path $WorkDir '05_top_products.csv')   (Join-Path $OutputDir 'top_products.csv')   -Force
Copy-Item (Join-Path $WorkDir '05_top_customers.csv')  (Join-Path $OutputDir 'top_customers.csv')  -Force
Copy-Item (Join-Path $WorkDir '05_sales_by_month.csv') (Join-Path $OutputDir 'sales_by_month.csv') -Force
Copy-Item (Join-Path $WorkDir '05_sales_by_day.csv')   (Join-Path $OutputDir 'sales_by_day.csv')   -Force

Write-Log "Dashboard ready: $htmlPath" 'OK' $LogPath
Write-Log "Stage 6 complete." 'OK' $LogPath
