param(
    [string]$Godot = 'D:/APP/steam/steamapps/common/Godot Engine/godot.windows.opt.tools.64.exe',
    [string]$EvidenceName = ('pause_text_' + (Get-Date -Format 'yyyyMMdd_HHmmss')),
    [switch]$Import,
    [switch]$LabelOnly
)
$ErrorActionPreference = 'Stop'
if ($EvidenceName -notmatch '^[a-zA-Z0-9_-]+$') { throw 'Use a fresh simple evidence name.' }
$pauseProject = (Resolve-Path -LiteralPath (Join-Path $PSScriptRoot '../../..')).Path
$pauseEvidence = Join-Path $pauseProject ".godot/ui-08-001/$EvidenceName"
if (Test-Path -LiteralPath $pauseEvidence) { throw 'Preserve old evidence; choose a fresh name.' }
New-Item -ItemType Directory -Path $pauseEvidence -Force | Out-Null
function Invoke-PauseStage([string]$Stage, [string[]]$StageArguments) {
    $pauseOut = Join-Path $pauseEvidence "$Stage.stdout.log"
    $pauseErr = Join-Path $pauseEvidence "$Stage.stderr.log"
    $pauseProcess = Start-Process -FilePath $Godot -ArgumentList (@('--path', ('"' + $pauseProject + '"')) + $StageArguments) -WindowStyle Hidden -PassThru -RedirectStandardOutput $pauseOut -RedirectStandardError $pauseErr
    if (-not $pauseProcess.WaitForExit(180000)) { $pauseProcess.Kill(); $pauseProcess.WaitForExit(); throw "$Stage timed out: $pauseErr" }
    $pauseProcess.WaitForExit()
    Get-Content -LiteralPath $pauseOut -Tail 8
    $pauseErrorText = Get-Content -LiteralPath $pauseErr -Raw
    if ($pauseProcess.ExitCode -ne 0 -or $pauseErrorText -match 'SCRIPT ERROR:|ERROR:|FAIL:') { throw "$Stage failed ($($pauseProcess.ExitCode)): $pauseErrorText" }
}
if ($Import) { Invoke-PauseStage 'import' @('--headless','--editor','--import') }
$pauseCheckArguments = @('--max-fps','60','--script','res://tests/shell/pause_text/test_pause_text.gd','--',('--evidence-dir="' + $pauseEvidence + '"'))
if ($LabelOnly) { $pauseCheckArguments += '--label-only' }
Invoke-PauseStage 'pause_label' $pauseCheckArguments
Write-Output "UI_08_001_OWNER_CHECK_PASS: $pauseEvidence; Human NOT_RUN; issue remains OPEN pending 08"
