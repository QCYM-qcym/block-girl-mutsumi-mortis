param(
    [ValidateSet('unit','real','graphical','import')][string]$Case = 'unit',
    [string]$RunId = ('run_' + (Get-Date -Format 'yyyyMMdd_HHmmss')),
    [string]$Godot = 'D:/APP/steam/steamapps/common/Godot Engine/godot.windows.opt.tools.64.exe'
)
$ErrorActionPreference = 'Stop'
if ($RunId -notmatch '^[A-Za-z0-9_-]+$') { throw 'RunId must be a simple unique folder name' }
$batchProject = (Resolve-Path -LiteralPath (Join-Path $PSScriptRoot '../../..')).Path
$batchEvidence = Join-Path $PSScriptRoot "evidence/$RunId"
if (Test-Path -LiteralPath $batchEvidence) { throw 'Preserving previous evidence: choose another RunId' }
New-Item -ItemType Directory -Path $batchEvidence | Out-Null
$batchArgs = @('--path',('"'+$batchProject+'"'))
if ($Case -eq 'import') { $batchArgs += @('--headless','--editor','--import') }
else {
    if ($Case -ne 'graphical') { $batchArgs += '--headless' }
    $batchScript = if ($Case -eq 'unit') { 'test_state.gd' } else { 'test_playthrough.gd' }
    $batchArgs += @('--max-fps','60','--script',"res://tests/beta_sprint/content_batch_02/$batchScript",'--',('--evidence-dir="'+$batchEvidence+'"'))
    if ($Case -eq 'graphical') { $batchArgs += '--graphical' }
}
$batchProtected = 'production/ui/beta_shell_01/icons_source.svg.import'
$batchOriginalMetadata = [IO.File]::ReadAllBytes((Join-Path $batchProject $batchProtected))
$batchStart = [DateTime]::UtcNow
$batchOut = Join-Path $batchEvidence 'stdout.log'
$batchErr = Join-Path $batchEvidence 'stderr.log'
$batchProcess = Start-Process -FilePath $Godot -ArgumentList $batchArgs -WindowStyle Hidden -PassThru -RedirectStandardOutput $batchOut -RedirectStandardError $batchErr
Write-Output "START case=$Case PID=$($batchProcess.Id)"
$batchTimedOut = -not $batchProcess.WaitForExit(180000)
if ($batchTimedOut) { $batchProcess.Kill() }
$batchProcess.WaitForExit()
if ($Case -eq 'import') { [IO.File]::WriteAllBytes((Join-Path $batchProject $batchProtected),$batchOriginalMetadata) }
$batchReport = [ordered]@{
    case=$Case; pid=$batchProcess.Id; exit_code=$batchProcess.ExitCode; timed_out=$batchTimedOut;
    start_utc=$batchStart.ToString('o'); end_utc=[DateTime]::UtcNow.ToString('o');
    project=$batchProject; head=(git -C $batchProject rev-parse HEAD); args=$batchArgs;
    stdout_sha256=(Get-FileHash -LiteralPath $batchOut -Algorithm SHA256).Hash.ToLowerInvariant();
    stderr_sha256=(Get-FileHash -LiteralPath $batchErr -Algorithm SHA256).Hash.ToLowerInvariant();
    graphical=($Case -eq 'graphical'); frozen_import_metadata_restored=($Case -eq 'import')
}
$batchReport | ConvertTo-Json -Depth 6 | Set-Content -LiteralPath (Join-Path $batchEvidence 'process.json') -Encoding utf8
Get-Content -LiteralPath $batchOut -Tail 6
$batchErrors = Get-Content -LiteralPath $batchErr -Raw
if ($batchErrors) { Write-Output $batchErrors }
Write-Output "CONTENT_BATCH02 case=$Case PID=$($batchProcess.Id) exit=$($batchProcess.ExitCode) evidence=$batchEvidence"
if ($batchTimedOut -or $batchProcess.ExitCode -ne 0 -or $batchErrors -match 'SCRIPT ERROR:|ERROR:|FAIL:') { throw "$Case failed; preserved actual process/log evidence" }
