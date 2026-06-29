param(
    [Parameter(Mandatory)][string]$InputPath,
    [Parameter(Mandatory)][string]$WorkDir,
    [Parameter(Mandatory)][string]$LogPath
)
$ErrorActionPreference = 'Stop'
. (Join-Path $PSScriptRoot 'pipeline_common.ps1')

Write-Log "Stage 1 - Extract: reading the source file." 'INFO' $LogPath

if (-not (Test-Path $InputPath)) {
    Write-Log "Could not find the input file: $InputPath. Check the path and run again." 'ERROR' $LogPath
    throw "Input file not found."
}

$data = Import-Csv -Path $InputPath
if (-not $data -or $data.Count -eq 0) {
    Write-Log "The file opened but has no rows. Add data and run again." 'ERROR' $LogPath
    throw "Empty input."
}

$cols = $data[0].PSObject.Properties.Name
Write-Log "Found $($data.Count) rows and $($cols.Count) columns." 'INFO' $LogPath

$out = Join-Path $WorkDir '01_extracted.csv'
$data | Export-Csv -Path $out -NoTypeInformation -Encoding UTF8
Write-Log "Stage 1 complete. Saved $out" 'OK' $LogPath
