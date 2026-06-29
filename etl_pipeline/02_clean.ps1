param(
    [Parameter(Mandatory)][string]$WorkDir,
    [Parameter(Mandatory)][string]$LogPath,
    [string[]]$DateColumns   = @(),
    [string[]]$NumberColumns = @(),
    [string[]]$NameColumns   = @()
)
$ErrorActionPreference = 'Stop'
. (Join-Path $PSScriptRoot 'pipeline_common.ps1')

Write-Log "Stage 2 - Clean: tidying spaces, blanks, formats and duplicates." 'INFO' $LogPath

$in = Join-Path $WorkDir '01_extracted.csv'
$data = Import-Csv -Path $in
$cols = $data[0].PSObject.Properties.Name
$startCount = $data.Count
$ti = (Get-Culture).TextInfo

$cleaned = foreach ($row in $data) {
    # skip fully blank rows, judged on original values
    $isEmpty = $true
    foreach ($c in $cols) { if (-not [string]::IsNullOrWhiteSpace($row.$c)) { $isEmpty = $false; break } }
    if ($isEmpty) { continue }

    foreach ($c in $cols) {
        $val = $row.$c
        if ($null -ne $val) { $val = ($val -replace '\s+', ' ').Trim() }

        if ([string]::IsNullOrWhiteSpace($val)) {
            if ($NumberColumns -contains $c) { $val = '0' } else { $val = 'N/A' }
        }
        else {
            if ($NumberColumns -contains $c) {
                $n = To-Number $val
                if ($null -ne $n) { $val = $n }
            }
            if ($DateColumns -contains $c) {
                $dt = [datetime]::MinValue
                if ([datetime]::TryParse($val, [ref]$dt)) { $val = $dt.ToString('yyyy-MM-dd') }
            }
            if ($NameColumns -contains $c) { $val = $ti.ToTitleCase($val.ToLower()) }
        }
        $row.$c = $val
    }
    $row
}

# remove exact duplicate rows
$seen = @{}
$unique = foreach ($row in $cleaned) {
    $key = ($cols | ForEach-Object { "$($row.$_)" }) -join '|~|'
    if (-not $seen.ContainsKey($key)) { $seen[$key] = $true; $row }
}

$removed = $startCount - $unique.Count
Write-Log "Cleaned rows. Removed $removed empty or duplicate rows ($startCount in, $($unique.Count) out)." 'INFO' $LogPath

$out = Join-Path $WorkDir '02_cleaned.csv'
$unique | Export-Csv -Path $out -NoTypeInformation -Encoding UTF8
Write-Log "Stage 2 complete. Saved $out" 'OK' $LogPath
