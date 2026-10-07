param(
    [string]$Project = (Join-Path $PSScriptRoot '../../..'),
    [string]$Godot = 'D:/APP/steam/steamapps/common/Godot Engine/godot.windows.opt.tools.64.exe',
    [string]$EvidenceName = ('ui_' + (Get-Date -Format 'yyyyMMdd_HHmmss') + '_' + [guid]::NewGuid().ToString('N').Substring(0,6)),
    [ValidateSet('entry','all')][string]$Mode = 'all',
    [int]$StageTimeoutSeconds = 180
)
$ErrorActionPreference = 'Stop'
if ($EvidenceName -notmatch '^[a-zA-Z0-9_-]+$') { throw 'Use a new short simple evidence name.' }
if ($StageTimeoutSeconds -lt 1 -or $StageTimeoutSeconds -gt 180) { throw 'A phase must have a timeout of 1..180 seconds.' }
$artProject = (Resolve-Path -LiteralPath $Project).Path
$artEvidence = Join-Path $artProject ".godot/beta-sprint/visual-integration/$EvidenceName"
if (Test-Path -LiteralPath $artEvidence) { throw 'Evidence already exists; every earlier run is preserved.' }
New-Item -ItemType Directory -Path $artEvidence -Force | Out-Null
$artHead = (& git -C $artProject rev-parse HEAD).Trim()
if ($LASTEXITCODE -ne 0) { throw 'Project must identify its actual Git HEAD.' }
$artSave = "user://beta_sprint/$EvidenceName/ui_progress.json"
$artStages = [System.Collections.Generic.List[object]]::new()
$artSourcePaths = @('project.godot','default_bus_layout.tres')
$artSourcePaths += @(& git -C $artProject ls-files --cached --others --exclude-standard -- game prototype/perspective production/art_3d production/ui/beta_shell_01 production/audio/p01 tests/playtest/test_batch_01_runtime.gd tests/beta_sprint/visual_integration)
$artSources = @($artSourcePaths | Sort-Object -Unique | Where-Object { Test-Path -LiteralPath (Join-Path $artProject $_) -PathType Leaf } | ForEach-Object {
    [ordered]@{path=$_; sha256=(Get-FileHash -LiteralPath (Join-Path $artProject $_) -Algorithm SHA256).Hash.ToLowerInvariant()}
})
$artSummary = [ordered]@{status='RUNNING'; project=$artProject; head=$artHead; working_tree=@(& git -C $artProject status --porcelain); engine=$Godot; engine_sha256=(Get-FileHash -LiteralPath $Godot -Algorithm SHA256).Hash.ToLowerInvariant(); save=$artSave; sources=$artSources; stages=@(); started_utc=[DateTime]::UtcNow.ToString('o')}
function Save-ArtSummary {
    $artSummary.stages = @($artStages.ToArray())
    $artSummary | ConvertTo-Json -Depth 12 | Set-Content -LiteralPath (Join-Path $artEvidence 'run_report.json') -Encoding utf8
}
function Invoke-ArtStage([string]$Name, [string[]]$StageArguments, [string]$CaseEvidence = '') {
    $stageOut = Join-Path $artEvidence "$Name.stdout.log"
    $stageErr = Join-Path $artEvidence "$Name.stderr.log"
    $stage = [ordered]@{name=$Name; pid=$null; exit_code=$null; started_utc=[DateTime]::UtcNow.ToString('o'); stdout=$stageOut; stderr=$stageErr; timed_out=$false}
    $artStages.Add($stage)
    Save-ArtSummary
    $stageProcess = Start-Process -FilePath $Godot -ArgumentList (@('--path', ('"' + $artProject + '"')) + $StageArguments) -WindowStyle Hidden -PassThru -RedirectStandardOutput $stageOut -RedirectStandardError $stageErr
    $stage.pid = $stageProcess.Id
    Save-ArtSummary
    if (-not $stageProcess.WaitForExit($StageTimeoutSeconds * 1000)) {
        $stage.timed_out = $true
        # Only this launch's own returned PID is stopped on timeout.
        $stageProcess.Kill()
        $stageProcess.WaitForExit()
    }
    $stageProcess.WaitForExit()
    $stage.exit_code = $stageProcess.ExitCode
    $stage.finished_utc = [DateTime]::UtcNow.ToString('o')
    $stage.stderr_empty = (Get-Item -LiteralPath $stageErr).Length -eq 0
    $stage.stdout_clean = (Get-Content -LiteralPath $stageOut -Raw) -notmatch 'SCRIPT ERROR:|ERROR:|WARNING:|FAIL:'
    if ($CaseEvidence) {
        $reportPath = Join-Path $CaseEvidence 'report.json'
        $stage.report = $reportPath
        if (Test-Path -LiteralPath $reportPath) {
            $report = Get-Content -LiteralPath $reportPath -Raw | ConvertFrom-Json
            $stage.checks = $report.checks
            $stage.failures = @($report.failures)
            $stage.actual_project = $report.project
            if ($Name -in @('seed','restore')) { $stage.actual_display = $report.display }
        } else { $stage.checks = 0; $stage.failures = @('Missing actual report.json') }
    }
    Save-ArtSummary
    if ($stage.timed_out -or $stage.exit_code -ne 0 -or -not $stage.stderr_empty -or -not $stage.stdout_clean -or ($CaseEvidence -and ($stage.checks -le 0 -or $stage.failures.Count -gt 0)) -or ($Name -in @('seed','restore') -and $stage.actual_display -eq 'headless')) {
        throw "$Name failed; PID=$($stage.pid), exit=$($stage.exit_code); see $artEvidence"
    }
    Get-Content -LiteralPath $stageOut
    $stageProcess.Dispose()
}
try {
    Invoke-ArtStage 'import' @('--headless','--editor','--import')
    $entryEvidence = Join-Path $artEvidence 'entry'
    $entryPrevious = $env:VISUAL_UI_EVIDENCE
    try {
        $env:VISUAL_UI_EVIDENCE = $entryEvidence
        Invoke-ArtStage 'entry' @('--headless','--script','res://tests/beta_sprint/visual_integration/test_ui_entry.gd','--',"--shell-save=user://beta_sprint/$EvidenceName/entry.json") $entryEvidence
    } finally { $env:VISUAL_UI_EVIDENCE = $entryPrevious }
    if ($Mode -eq 'all') {
        foreach ($artPhase in @('seed','restore')) {
            $phaseEvidence = Join-Path $artEvidence $artPhase
            Invoke-ArtStage $artPhase @('--max-fps','60','--script','res://tests/beta_sprint/visual_integration/test_visual_ui.gd','--',"--phase=$artPhase",('--evidence-dir="' + $phaseEvidence + '"'),"--ui-save=$artSave","--head=$artHead") $phaseEvidence
        }
        $seed = Get-Content -LiteralPath (Join-Path $artEvidence 'seed/report.json') -Raw | ConvertFrom-Json
        $restore = Get-Content -LiteralPath (Join-Path $artEvidence 'restore/report.json') -Raw | ConvertFrom-Json
        if ($seed.pid -eq $restore.pid -or $seed.save_absolute -ne $restore.save_absolute) { throw 'Continue requires independent OS processes and the same actual isolated Save.' }
        $artSummary.seed_pid = $seed.pid
        $artSummary.restore_pid = $restore.pid
    }
    foreach ($source in $artSources) {
        if ((Get-FileHash -LiteralPath (Join-Path $artProject $source.path) -Algorithm SHA256).Hash.ToLowerInvariant() -ne $source.sha256) { throw "Source changed during validation: $($source.path)" }
    }
    $artSummary.status = 'PASS'
    $artSummary.finished_utc = [DateTime]::UtcNow.ToString('o')
    Save-ArtSummary
    Write-Output "MAIN PROJECT VISUAL UI PASS: $artEvidence"
} catch {
    $artSummary.status = 'FAIL'
    $artSummary.failure = $_.Exception.Message
    $artSummary.finished_utc = [DateTime]::UtcNow.ToString('o')
    Save-ArtSummary
    throw
}
