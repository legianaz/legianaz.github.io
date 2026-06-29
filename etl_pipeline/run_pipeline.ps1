param(
    [Parameter(Mandatory)][string]$InputPath,
    [string]$OutputDir = '',
    # optional column overrides, passed through to the stages that need them
    [string[]]$DateColumns   = @(),
    [string[]]$NumberColumns = @(),
    [string[]]$NameColumns   = @(),
    [string]$AmountColumn   = '',
    [string]$QuantityColumn = '',
    [string]$PriceColumn    = '',
    [string]$ProductColumn  = '',
    [string]$CustomerColumn = '',
    [string]$DateColumn     = ''
)

$ErrorActionPreference = 'Stop'
. (Join-Path $PSScriptRoot 'pipeline_common.ps1')

# --- set up the run folder ---
if (-not $OutputDir) {
    $base  = Split-Path $InputPath -Parent
    $stamp = Get-Date -Format 'yyyyMMdd_HHmmss'
    $OutputDir = Join-Path $base "sales_report_$stamp"
}
$workDir = Join-Path $OutputDir 'pipeline_work'
New-Item -ItemType Directory -Path $workDir -Force | Out-Null
$logPath = Join-Path $OutputDir 'run.log'

$totalStages = 6
$sourceName  = Split-Path $InputPath -Leaf

Write-Log "==== Sales ETL pipeline started ====" 'INFO' $logPath
Write-Log "Source: $sourceName" 'INFO' $logPath
Write-Log "Output: $OutputDir" 'INFO' $logPath

try {
    Show-StageProgress 1 $totalStages 'Extract'
    & (Join-Path $PSScriptRoot '01_extract.ps1') -InputPath $InputPath -WorkDir $workDir -LogPath $logPath

    Show-StageProgress 2 $totalStages 'Clean'
    & (Join-Path $PSScriptRoot '02_clean.ps1') -WorkDir $workDir -LogPath $logPath `
        -DateColumns $DateColumns -NumberColumns $NumberColumns -NameColumns $NameColumns

    Show-StageProgress 3 $totalStages 'Validate'
    & (Join-Path $PSScriptRoot '03_validate.ps1') -WorkDir $workDir -LogPath $logPath `
        -AmountColumn $AmountColumn -QuantityColumn $QuantityColumn -PriceColumn $PriceColumn -DateColumn $DateColumn

    Show-StageProgress 4 $totalStages 'Transform'
    & (Join-Path $PSScriptRoot '04_transform.ps1') -WorkDir $workDir -LogPath $logPath `
        -AmountColumn $AmountColumn -QuantityColumn $QuantityColumn -PriceColumn $PriceColumn `
        -ProductColumn $ProductColumn -CustomerColumn $CustomerColumn -DateColumn $DateColumn

    Show-StageProgress 5 $totalStages 'Aggregate'
    & (Join-Path $PSScriptRoot '05_aggregate.ps1') -WorkDir $workDir -LogPath $logPath

    Show-StageProgress 6 $totalStages 'Load'
    & (Join-Path $PSScriptRoot '06_load.ps1') -WorkDir $workDir -OutputDir $OutputDir -LogPath $logPath -SourceName $sourceName

    Write-Progress -Activity "Sales ETL Pipeline" -Completed
    Write-Log "==== Pipeline finished successfully ====" 'OK' $logPath
    Write-Log "Open the report: $(Join-Path $OutputDir 'sales_report.html')" 'OK' $logPath
}
catch {
    Write-Progress -Activity "Sales ETL Pipeline" -Completed
    Write-Log "Pipeline stopped: $($_.Exception.Message)" 'ERROR' $logPath
    Write-Log "Nothing further was produced. Fix the issue above and run again." 'ERROR' $logPath
    Write-Log "Full details are in: $logPath" 'INFO' $logPath
    exit 1
}
