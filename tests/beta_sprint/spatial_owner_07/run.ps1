param(
 [string]$Godot='D:/APP/steam/steamapps/common/Godot Engine/godot.windows.opt.tools.64.exe',
 [string]$EvidenceName=('spatial07_'+(Get-Date -Format 'yyyyMMdd_HHmmss')+'_'+[guid]::NewGuid().ToString('N').Substring(0,8)),
 [string[]]$Cases=@('progress_seed','progress_restore','baseline_save')
)
$ErrorActionPreference='Stop'
if ($Cases.Count -eq 0 -or $EvidenceName -notmatch '^[a-zA-Z0-9_-]+$') { throw 'Select behavioral cases and a fresh simple name' }
$spatialUiRoot=(Resolve-Path -LiteralPath (Join-Path $PSScriptRoot '../../..')).Path
$spatialUiEvidence=Join-Path $spatialUiRoot ".godot/spatial-ui/$EvidenceName"
if (Test-Path -LiteralPath $spatialUiEvidence) { throw 'Evidence is append-only' }
New-Item -ItemType Directory -Path $spatialUiEvidence | Out-Null
$spatialUiProfile=Join-Path $spatialUiEvidence 'profile'
New-Item -ItemType Directory -Path $spatialUiProfile | Out-Null
$spatialUiSources=@(git -C $spatialUiRoot ls-files --cached --others --exclude-standard -- foundation game/shell game/feel experiments/game_feel_01/host experiments/spatial_puzzle_batch_01 production/ui/beta_shell_01 production/experimental/game_feel_01/audio tests/shell/test_save.gd tests/beta_sprint/spatial_owner_07 docs/beta-sprint/spatial-puzzle-batch-01/CONTRACT.md docs/beta-sprint/spatial-puzzle-batch-01/USER_REQUEST.md docs/beta-sprint/spatial-puzzle-batch-01/RUNTIME_INTERFACE.md)
$spatialUiHashes=@($spatialUiSources | Sort-Object -Unique | ForEach-Object { [ordered]@{path=$_;sha256=(Get-FileHash -LiteralPath (Join-Path $spatialUiRoot $_)).Hash.ToLowerInvariant()} })
$spatialUiReport=[ordered]@{head=(git -C $spatialUiRoot rev-parse HEAD).Trim();dirty=@(git -C $spatialUiRoot status --porcelain);source_files=$spatialUiHashes;status='RUNNING';stages=@();engine_path=$Godot;display='headless';profile=$spatialUiProfile;source_drift=$null;human_qa='NOT_RUN';graphical='NOT_RUN'}
$spatialUiStages=[Collections.Generic.List[object]]::new()
function Save-SpatialUiReport { $spatialUiReport.stages=@($spatialUiStages.ToArray()); [IO.File]::WriteAllText((Join-Path $spatialUiEvidence 'run_report.json'),($spatialUiReport | ConvertTo-Json -Depth 12).Replace("`r`n","`n")+"`n",[Text.UTF8Encoding]::new($false)) }
try {
 foreach ($spatialUiCase in $Cases) {
  $spatialUiArgs=@('--headless','--path',('"'+$spatialUiRoot+'"'))
  if ($spatialUiCase -eq 'baseline_save') { $spatialUiArgs+=@('--script','res://tests/shell/test_save.gd') }
  elseif ($spatialUiCase -in @('progress_seed','progress_restore','menu')) { $spatialUiScript=if ($spatialUiCase -eq 'menu') {'test_menu.gd'} else {'test_progress.gd'}; $spatialUiArgs+=@('--script',('res://tests/beta_sprint/spatial_owner_07/'+$spatialUiScript),'--',"--phase=$spatialUiCase",('--evidence-dir="'+(Join-Path $spatialUiEvidence $spatialUiCase)+'"'),"--shell-save=user://spatial_puzzle_batch_01/tests/$EvidenceName/progress.json") }
  else { throw 'Unknown case' }
  $spatialUiOut=Join-Path $spatialUiEvidence "$spatialUiCase.stdout.log"; $spatialUiErr=Join-Path $spatialUiEvidence "$spatialUiCase.stderr.log"
  $spatialUiStage=[ordered]@{name=$spatialUiCase;args=$spatialUiArgs;pid=$null;exit_code=$null;stderr_bytes=$null;checks=0;status='RUNNING'}; $spatialUiStages.Add($spatialUiStage); Save-SpatialUiReport
  $spatialUiProcess=Start-Process -FilePath $Godot -ArgumentList $spatialUiArgs -WindowStyle Hidden -PassThru -Environment @{APPDATA=$spatialUiProfile;LOCALAPPDATA=$spatialUiProfile} -RedirectStandardOutput $spatialUiOut -RedirectStandardError $spatialUiErr
  $spatialUiStage.pid=$spatialUiProcess.Id; Save-SpatialUiReport
  if (-not $spatialUiProcess.WaitForExit(45000)) { $spatialUiProcess.Kill(); $spatialUiProcess.WaitForExit(); throw 'Own headless process timed out' }; $spatialUiProcess.WaitForExit()
  $spatialUiStage.exit_code=$spatialUiProcess.ExitCode; $spatialUiStage.stderr_bytes=(Get-Item -LiteralPath $spatialUiErr).Length
  $spatialUiText=Get-Content -LiteralPath $spatialUiOut -Raw
  if ($spatialUiStage.exit_code -ne 0 -or $spatialUiStage.stderr_bytes -ne 0 -or $spatialUiText -match 'SCRIPT ERROR:|ERROR:|FAIL:') { $spatialUiStage.status='FAIL'; throw 'Case failed; raw output retained' }
  if ($spatialUiCase -eq 'baseline_save') { if ($spatialUiText -notmatch 'SHELL SAVE: (\d+) checks, failures=\[\]') { throw 'Missing original Save report' }; $spatialUiStage.checks=[int]$Matches[1] }
  else { $spatialUiCaseReport=Get-Content -LiteralPath (Join-Path $spatialUiEvidence "$spatialUiCase/report.json") -Raw | ConvertFrom-Json; if ($spatialUiCaseReport.failures.Count -ne 0 -or $spatialUiCaseReport.pid -ne $spatialUiStage.pid -or -not $spatialUiCaseReport.user_data_dir.StartsWith($spatialUiProfile.Replace('\','/'),[StringComparison]::OrdinalIgnoreCase)) { throw 'Process/profile/report mismatch' }; $spatialUiStage.checks=$spatialUiCaseReport.checks }
  if ($spatialUiStage.checks -le 0) { throw 'Zero-check run cannot pass' }; $spatialUiStage.status='PASS'; Save-SpatialUiReport; Write-Output "$spatialUiCase PASS checks=$($spatialUiStage.checks) exit=0 stderr=0"
 }
 foreach ($spatialUiSource in $spatialUiHashes) { if ((Get-FileHash -LiteralPath (Join-Path $spatialUiRoot $spatialUiSource.path)).Hash.ToLowerInvariant() -ne $spatialUiSource.sha256) { throw 'Source drift' } }
 $spatialUiTotal=0; foreach ($spatialUiStage in $spatialUiStages) { $spatialUiTotal+=[int]$spatialUiStage.checks }; if ($spatialUiTotal -le 0) { throw 'No executed assertions' }
 $spatialUiReport.behavioral_checks=$spatialUiTotal; $spatialUiReport.source_drift=$false; $spatialUiReport.status='PASS'; Save-SpatialUiReport; Write-Output "SPATIAL_OWNER07_HEADLESS_PASS $spatialUiEvidence"
} catch { $spatialUiReport.status='FAIL'; $spatialUiReport.failure=$_.Exception.Message; Save-SpatialUiReport; throw }
