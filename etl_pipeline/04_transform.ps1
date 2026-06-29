param(
    [Parameter(Mandatory)][string]$WorkDir,
    [Parameter(Mandatory)][string]$LogPath,
    [string]$AmountColumn   = '',
    [string]$QuantityColumn = '',
    [string]$PriceColumn    = '',
    [string]$ProductColumn  = '',
    [string]$CustomerColumn = '',
    [string]$DateColumn     = ''
)
$ErrorActionPreference = 'Stop'
. (Join-Path $PSScriptRoot 'pipeline_common.ps1')

Write-Log "Stage 4 - Transform: reshaping into clean sales records." 'INFO' $LogPath

$in = Join-Path $WorkDir '03_validated.csv'
$data = Import-Csv -Path $in
$cols = $data[0].PSObject.Properties.Name

if (-not $AmountColumn)   { $AmountColumn   = Find-Column @('Amount','Total','TotalSales','Sales','Revenue','LineTotal','NetAmount') $cols }
if (-not $QuantityColumn) { $QuantityColumn = Find-Column @('Quantity','Qty','Units','Count') $cols }
if (-not $PriceColumn)    { $PriceColumn    = Find-Column @('UnitPrice','Price','Rate','CostEach') $cols }
if (-not $ProductColumn)  { $ProductColumn  = Find-Column @('Product','ProductName','Item','ItemName','SKU','Description') $cols }
if (-not $CustomerColumn) { $CustomerColumn = Find-Column @('Customer','CustomerName','Client','Account','Buyer') $cols }
if (-not $DateColumn)     { $DateColumn     = Find-Column @('Date','OrderDate','SaleDate','TransactionDate','InvoiceDate') $cols }

$mode = if ($AmountColumn) { 'direct' } else { 'compute' }
Write-Log "Amount source: $mode$(if($mode -eq 'direct'){" ($AmountColumn)"}else{" ($QuantityColumn x $PriceColumn)"})" 'INFO' $LogPath

$rows = foreach ($r in $data) {
    if ($mode -eq 'direct') {
        $amt = To-Number $r.$AmountColumn
    } else {
        $q = To-Number $r.$QuantityColumn; $p = To-Number $r.$PriceColumn
        $amt = if (($null -ne $q) -and ($null -ne $p)) { $q * $p } else { 0 }
    }
    if ($null -eq $amt) { $amt = 0 }

    $dtOut = ''
    if ($DateColumn) {
        $dt = [datetime]::MinValue
        if ([datetime]::TryParse($r.$DateColumn, [ref]$dt)) { $dtOut = $dt.ToString('yyyy-MM-dd') }
    }

    [PSCustomObject]@{
        Product  = if ($ProductColumn)  { $r.$ProductColumn }  else { 'Unknown' }
        Customer = if ($CustomerColumn) { $r.$CustomerColumn } else { 'Unknown' }
        Date     = $dtOut
        Amount   = [math]::Round([double]$amt, 2)
    }
}

$out = Join-Path $WorkDir '04_transformed.csv'
$rows | Export-Csv -Path $out -NoTypeInformation -Encoding UTF8
Write-Log "Reshaped $($rows.Count) records into Product, Customer, Date, Amount." 'INFO' $LogPath
Write-Log "Stage 4 complete. Saved $out" 'OK' $LogPath
