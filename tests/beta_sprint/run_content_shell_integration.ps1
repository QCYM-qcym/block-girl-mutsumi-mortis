param(
    [string]$Godot = 'D:/APP/steam/steamapps/common/Godot Engine/godot.windows.opt.tools.64.exe',
    [string]$EvidenceName = ('content_shell_' + (Get-Date -Format 'yyyyMMdd_HHmmss') + '_' + [guid]::NewGuid().ToString('N').Substring(0,8)),
    [int]$StageTimeoutSeconds = 180,
    [switch]$VerboseEngine
)
$ErrorActionPreference = 'Stop'
if ($EvidenceName -notmatch '^[a-zA-Z0-9_-]+$') { throw 'Use a simple fresh evidence directory name.' }
$integrationProject = (Resolve-Path -LiteralPath (Join-Path $PSScriptRoot '../..')).Path
$integrationEvidence = Join-Path $integrationProject ".godot/beta-sprint/content-shell/$EvidenceName"
if (Test-Path -LiteralPath $integrationEvidence) { throw 'Evidence already exists; failures and prior runs are preserved.' }
New-Item -ItemType Directory -Path $integrationEvidence -Force | Out-Null
$integrationHead = (& git -C $integrationProject rev-parse HEAD).Trim()
$integrationBranch = (& git -C $integrationProject branch --show-current).Trim()
$integrationContentSha = (& git -C $integrationProject rev-parse 608a18a).Trim()
$integrationShellSha = (& git -C $integrationProject rev-parse 7abf98d).Trim()
$integrationEngineSha = (Get-FileHash -LiteralPath $Godot -Algorithm SHA256).Hash.ToLowerInvariant()
$integrationSourcePaths = @('project.godot','default_bus_layout.tres','game/shell/level_catalog.gd','game/shell/game_shell.gd','game/shell/game_shell.tscn','game/shell/level_adapter.gd','game/shell/save_store.gd','game/shell/settings.gd','game/shell/shell_view.gd','game/shell/shell_input.gd','game/levels/mutsumi/p01_another_world.gd','game/levels/mutsumi/p01_state.gd','game/levels/mutsumi/p01_board.gd','game/player/grid_input.gd','prototype/perspective/grid_movement.gd','prototype/perspective/perspective_controller.gd','tests/playtest/test_batch_01_runtime.gd','tests/shell/test_save.gd','tests/shell/test_flow.gd','tests/shell/test_p01_legacy_entry.gd','tests/gameplay/test_p01_runtime.gd','tests/beta_sprint/test_content_shell.gd','tests/beta_sprint/test_content_shell.gd.uid','tests/beta_sprint/run_content_shell_integration.ps1')
$integrationSourcePaths += @(Get-ChildItem -LiteralPath (Join-Path $integrationProject 'game/levels/mutsumi/batch_01') -File | ForEach-Object { 'game/levels/mutsumi/batch_01/' + $_.Name })
$integrationSources = @($integrationSourcePaths | Sort-Object -Unique | ForEach-Object {
    $sourceAbsolute = Join-Path $integrationProject $_
    [ordered]@{path=$_; bytes=(Get-Item -LiteralPath $sourceAbsolute).Length; sha256=(Get-FileHash -LiteralPath $sourceAbsolute -Algorithm SHA256).Hash.ToLowerInvariant()}
})
$integrationSave = "user://beta_sprint/$EvidenceName/content_shell_progress.json"
$integrationStages = [System.Collections.Generic.List[object]]::new()
$integrationSummary = [ordered]@{ head=$integrationHead; branch=$integrationBranch; content_sha=$integrationContentSha; shell_sha=$integrationShellSha; evidence=$integrationEvidence; isolated_save=$integrationSave; engine_executable=$Godot; engine_sha256=$integrationEngineSha; source_files=$integrationSources; started_utc=[DateTime]::UtcNow.ToString('o'); status='RUNNING'; stages=@() }
function Save-IntegrationSummary {
    $integrationSummary.stages = @($integrationStages.ToArray())
    $integrationSummary | ConvertTo-Json -Depth 10 | Set-Content -LiteralPath (Join-Path $integrationEvidence 'run_report.json') -Encoding utf8
}
function Invoke-IntegrationStage([string]$Name, [string[]]$StageArgs) {
    $stageOut = Join-Path $integrationEvidence "$Name.stdout.log"
    $stageErr = Join-Path $integrationEvidence "$Name.stderr.log"
    $stageRecord = [ordered]@{name=$Name; started_utc=[DateTime]::UtcNow.ToString('o'); pid=$null; exit_code=$null; timed_out=$false; stderr_clean=$false; stdout=$stageOut; stderr=$stageErr}
    $integrationStages.Add($stageRecord)
    Save-IntegrationSummary
    $stageArguments = @('--path', ('"' + $integrationProject + '"')) + $StageArgs
    if ($VerboseEngine) { $stageArguments = @('--verbose') + $stageArguments }
    $stageProcess = Start-Process -FilePath $Godot -ArgumentList $stageArguments -WindowStyle Hidden -PassThru -RedirectStandardOutput $stageOut -RedirectStandardError $stageErr
    $stageRecord.pid = $stageProcess.Id
    Save-IntegrationSummary
    if (-not $stageProcess.WaitForExit($StageTimeoutSeconds * 1000)) {
        $stageRecord.timed_out = $true
        $stageProcess.Kill()
        $stageProcess.WaitForExit()
    }
    $stageProcess.WaitForExit()
    $stageRecord.exit_code = $stageProcess.ExitCode
    $stageRecord.finished_utc = [DateTime]::UtcNow.ToString('o')
    $stageErrors = Get-Content -LiteralPath $stageErr -Raw
    $stageRecord.stderr_clean = [string]::IsNullOrWhiteSpace($stageErrors)
    $stageRecord.engine_banner = @(Get-Content -LiteralPath $stageOut | Select-String '^Godot Engine' | ForEach-Object { $_.Line })
    $stageOutput = Get-Content -LiteralPath $stageOut -Raw
    $stageRecord.stdout_error_free = $stageOutput -notmatch 'SCRIPT ERROR:|ERROR:|FAIL:'
    if ($Name -in @('save','flow')) {
        $countMatch = [regex]::Match($stageOutput, 'SHELL (?:SAVE|FLOW): (\d+) checks, failures=\[\]')
        $stageRecord.checks = if ($countMatch.Success) { [int]$countMatch.Groups[1].Value } else { 0 }
    }
    Save-IntegrationSummary
    Get-Content -LiteralPath $stageOut
    if ($stageRecord.timed_out -or $stageProcess.ExitCode -ne 0 -or -not $stageRecord.stderr_clean -or -not $stageRecord.stdout_error_free -or ($Name -in @('save','flow') -and $stageRecord.checks -le 0)) {
        throw "$Name failed or timed out; PID=$($stageRecord.pid); exit=$($stageRecord.exit_code); see $stageErr"
    }
}
try {
    Invoke-IntegrationStage 'import' @('--headless','--editor','--import')
    foreach ($caseName in @('save','flow')) {
        Invoke-IntegrationStage $caseName @('--headless','--script',"res://tests/shell/test_$caseName.gd",'--',"--shell-save=user://beta_sprint/$EvidenceName/$caseName.json")
    }
    foreach ($phaseName in @('seed','restore')) {
        $phaseEvidence = Join-Path $integrationEvidence $phaseName
        Invoke-IntegrationStage $phaseName @('--max-fps','60','--script','res://tests/beta_sprint/test_content_shell.gd','--',"--phase=$phaseName", ('--evidence-dir="'+$phaseEvidence+'"'),"--shell-save=$integrationSave","--head=$integrationHead","--branch=$integrationBranch","--content-sha=$integrationContentSha","--shell-sha=$integrationShellSha")
        $phaseReport = Get-Content -LiteralPath (Join-Path $phaseEvidence 'report.json') -Raw | ConvertFrom-Json
        if ($phaseReport.display -eq 'headless' -or $phaseReport.failures.Count -ne 0) { throw "$phaseName report did not pass" }
    }
    $seedReport = Get-Content -LiteralPath (Join-Path $integrationEvidence 'seed/report.json') -Raw | ConvertFrom-Json
    $restoreReport = Get-Content -LiteralPath (Join-Path $integrationEvidence 'restore/report.json') -Raw | ConvertFrom-Json
    if ($seedReport.pid -eq $restoreReport.pid -or -not $seedReport.shell_quit_requested) { throw 'Restart must follow actual Shell quit in a distinct OS process.' }
    if ($seedReport.save_absolute -ne $restoreReport.save_absolute) { throw 'Restart used different save paths.' }
    $legacyEvidence = Join-Path $integrationEvidence 'p01_legacy'
    Invoke-IntegrationStage 'p01_legacy' @('--max-fps','60','--script','res://tests/shell/test_p01_legacy_entry.gd','--',('--evidence-dir="'+$legacyEvidence+'"'),"--shell-save=user://beta_sprint/$EvidenceName/p01_legacy.json")
    $legacyReport = Get-Content -LiteralPath (Join-Path $legacyEvidence 'runtime_report.json') -Raw | ConvertFrom-Json
    if ($legacyReport.failures.Count -ne 0 -or $legacyReport.display -eq 'headless') { throw 'Legacy P01 focused regression did not pass.' }
    foreach ($sourceEntry in $integrationSources) {
        $currentSourceSha = (Get-FileHash -LiteralPath (Join-Path $integrationProject $sourceEntry.path) -Algorithm SHA256).Hash.ToLowerInvariant()
        if ($currentSourceSha -ne $sourceEntry.sha256) { throw "Runtime source changed during test: $($sourceEntry.path)" }
    }
    $integrationSummary.status = 'PASS'
    $integrationSummary.finished_utc = [DateTime]::UtcNow.ToString('o')
    $integrationSummary.seed_pid = $seedReport.pid
    $integrationSummary.restore_pid = $restoreReport.pid
    $integrationSummary.engine = $seedReport.engine
    $integrationSummary.checks = @{ seed=$seedReport.checks; restore=$restoreReport.checks; p01_legacy=$legacyReport.checks }
    Save-IntegrationSummary
    Write-Output "CONTENT SHELL INTEGRATION PASS: $integrationEvidence"
} catch {
    $integrationSummary.status = 'FAIL'
    $integrationSummary.finished_utc = [DateTime]::UtcNow.ToString('o')
    $integrationSummary.failure = $_.Exception.Message
    Save-IntegrationSummary
    throw
}
