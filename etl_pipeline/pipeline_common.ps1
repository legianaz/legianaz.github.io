# pipeline_common.ps1
# Shared helpers for logging and progress, dot-sourced by every stage.
# No network calls. Writes only to the run's own output folder.

function Write-Log {
    param(
        [Parameter(Mandatory)][string]$Message,
        [ValidateSet('INFO','WARN','ERROR','OK')][string]$Level = 'INFO',
        [string]$LogPath
    )
    $stamp = Get-Date -Format 'yyyy-MM-dd HH:mm:ss'
    $line  = "[{0}] [{1}] {2}" -f $stamp, $Level, $Message

    # plain-English to the screen for non-technical users
    switch ($Level) {
        'OK'    { Write-Host $Message -ForegroundColor Green }
        'WARN'  { Write-Host $Message -ForegroundColor Yellow }
        'ERROR' { Write-Host $Message -ForegroundColor Red }
        default { Write-Host $Message }
    }

    # full timestamped line to the log file for technical users
    if ($LogPath) {
        Add-Content -Path $LogPath -Value $line -Encoding UTF8
    }
}

function Show-StageProgress {
    param(
        [Parameter(Mandatory)][int]$StageNumber,
        [Parameter(Mandatory)][int]$TotalStages,
        [Parameter(Mandatory)][string]$StageName
    )
    $pct = [int](($StageNumber / $TotalStages) * 100)
    Write-Progress -Activity "Sales ETL Pipeline" `
                   -Status "Stage $StageNumber of ${TotalStages}: $StageName" `
                   -PercentComplete $pct
}

function To-Number {
    param($Value)
    if ($null -eq $Value) { return $null }
    $clean = "$Value" -replace '[\$,\s]', ''
    $n = 0.0
    if ([double]::TryParse($clean, [ref]$n)) { return $n }
    return $null
}

function Find-Column {
    param([string[]]$Candidates, [string[]]$Available)
    foreach ($cand in $Candidates) {
        $hit = $Available | Where-Object { ($_ -replace '\s','') -ieq ($cand -replace '\s','') } | Select-Object -First 1
        if ($hit) { return $hit }
    }
    return $null
}
