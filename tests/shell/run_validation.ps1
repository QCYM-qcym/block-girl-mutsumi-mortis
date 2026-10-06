param(
    [string]$Godot = 'D:/APP/steam/steamapps/common/Godot Engine/godot.windows.opt.tools.64.exe',
    [string]$EvidenceName = ('shell_' + (Get-Date -Format 'yyyyMMdd_HHmmss')),
    [switch]$IncludeRegressions
)
$ErrorActionPreference = 'Stop'
if ($EvidenceName -notmatch '^[a-zA-Z0-9_-]+$') { throw 'Use a simple evidence directory name.' }
$shellProject = (Resolve-Path -LiteralPath (Join-Path $PSScriptRoot '../..')).Path
$shellEvidence = Join-Path $PSScriptRoot "evidence/$EvidenceName"
if (Test-Path -LiteralPath $shellEvidence) { throw 'Choose a fresh evidence name; prior evidence is preserved.' }
New-Item -ItemType Directory -Path $shellEvidence -Force | Out-Null
New-Item -ItemType File -Path (Join-Path $PSScriptRoot 'evidence/.gdignore') -Force | Out-Null
function Invoke-ShellStage([string]$Stage, [string[]]$StageArgs) {
    $shellOut = Join-Path $shellEvidence "$Stage.stdout.log"
    $shellErr = Join-Path $shellEvidence "$Stage.stderr.log"
    $shellArgs = @('--path', ('"' + $shellProject + '"')) + $StageArgs
    $shellProcess = Start-Process -FilePath $Godot -ArgumentList $shellArgs -WindowStyle Hidden -PassThru -RedirectStandardOutput $shellOut -RedirectStandardError $shellErr
    if (-not $shellProcess.WaitForExit(180000)) {
        $shellProcess.Kill()
        $shellProcess.WaitForExit()
        throw "$Stage timed out; see $shellErr"
    }
    $shellProcess.WaitForExit()
    Get-Content -LiteralPath $shellOut
    $shellErrors = Get-Content -LiteralPath $shellErr -Raw
    if ($shellProcess.ExitCode -ne 0 -or $shellErrors -match 'SCRIPT ERROR:|ERROR:|FAIL:') {
        throw "$Stage failed: $shellErrors"
    }
}
Invoke-ShellStage 'import' @('--headless','--editor','--import')
foreach ($shellCase in @('save','flow','goal_boundary','mute_restart')) {
    Invoke-ShellStage $shellCase @('--headless','--script',"res://tests/shell/test_$shellCase.gd")
}
$shellRestartSave = "user://shell_tests/$EvidenceName/restart.json"
Invoke-ShellStage 'cold' @('--headless','--script','res://tests/shell/test_restart.gd','--','--phase=cold',"--shell-save=user://shell_tests/$EvidenceName/cold.json")
foreach ($shellPhase in @('seed','restore')) {
    Invoke-ShellStage $shellPhase @('--headless','--script','res://tests/shell/test_restart.gd','--',"--phase=$shellPhase","--shell-save=$shellRestartSave")
}
Invoke-ShellStage 'restore_graphical' @('--max-fps','60','--script','res://tests/shell/test_restart.gd','--','--phase=restore',"--shell-save=$shellRestartSave")
# Actual configured Main Scene, without a test script or replacing its configuration.
Invoke-ShellStage 'main_scene_boot' @('--headless','--quit-after','10','--',"--shell-save=user://shell_tests/$EvidenceName/boot.json")
Invoke-ShellStage 'graphical' @('--max-fps','60','--script','res://tests/shell/test_playthrough.gd','--',('--evidence-dir="'+(Join-Path $shellEvidence 'graphical')+'"'))
$shellReport = Get-Content -LiteralPath (Join-Path $shellEvidence 'graphical/report.json') -Raw | ConvertFrom-Json
if ($shellReport.display -eq 'headless' -or $shellReport.failures.Count -ne 0) { throw 'Graphical acceptance did not pass.' }
if ($IncludeRegressions) {
    foreach ($shellLogic in @('test_p01_state','test_perspective_logic')) {
        Invoke-ShellStage $shellLogic @('--headless','--script',"res://tests/gameplay/$shellLogic.gd")
    }
    Invoke-ShellStage 'p01_legacy_entry' @('--max-fps','60','--script','res://tests/shell/test_p01_legacy_entry.gd','--',('--evidence-dir="'+(Join-Path $shellEvidence 'p01_legacy')+'"'))
    Invoke-ShellStage 'orientation' @('--max-fps','60','--script','res://tests/gameplay/test_orientation_sprite_runtime.gd','--',('--evidence-dir="'+(Join-Path $shellEvidence 'orientation')+'"'))
    # Existing runner preserves the legacy tileset sample's bytes.
    & (Join-Path $shellProject 'tests/gameplay/run_validation.ps1') -Godot $Godot -EvidenceName ($EvidenceName + '_regression') -IncludeRegressions
}
Write-Output "GAME SHELL VALIDATION PASS: $shellEvidence"
