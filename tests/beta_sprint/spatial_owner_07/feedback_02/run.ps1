param(
 [string]$Godot='D:/APP/steam/steamapps/common/Godot Engine/godot.windows.opt.tools.64.exe',
 [string]$EvidenceName=('feedback02_'+(Get-Date -Format 'yyyyMMdd_HHmmss')+'_'+[guid]::NewGuid().ToString('N').Substring(0,8))
)
$ErrorActionPreference='Stop'
if ($EvidenceName -notmatch '^[a-zA-Z0-9_-]+$') { throw 'Fresh simple evidence name required' }
$feedbackRoot=(Resolve-Path -LiteralPath (Join-Path $PSScriptRoot '../../../..')).Path
$feedbackEvidence=Join-Path $feedbackRoot ".godot/spatial-ui-feedback-02/$EvidenceName"
if (Test-Path -LiteralPath $feedbackEvidence) { throw 'Evidence is append-only' }
New-Item -ItemType Directory -Path $feedbackEvidence | Out-Null
$feedbackProfile=Join-Path $feedbackEvidence 'profile'
New-Item -ItemType Directory -Path $feedbackProfile | Out-Null
$feedbackSourcePaths=@(git -C $feedbackRoot ls-files --cached --others --exclude-standard -- project.godot default_bus_layout.tres foundation game/shell game/feel experiments/game_feel_01/host experiments/spatial_puzzle_batch_01 production/ui/beta_shell_01 production/experimental/game_feel_01/audio tests/beta_sprint/spatial_owner_07/feedback_02 docs/beta-sprint/spatial-puzzle-batch-01/CONTRACT.md docs/beta-sprint/spatial-puzzle-batch-01/RUNTIME_INTERFACE.md docs/beta-sprint/spatial-puzzle-batch-01/design/SPATIAL_PUZZLE_BATCH_01_DESIGN_SPEC.md docs/beta-sprint/spatial-puzzle-batch-01/design/SPATIAL_PUZZLE_BATCH_01_DESIGN_SOURCES.json)
$feedbackSources=@($feedbackSourcePaths | Sort-Object -Unique | ForEach-Object { [ordered]@{path=$_;sha256=(Get-FileHash -LiteralPath (Join-Path $feedbackRoot $_)).Hash.ToLowerInvariant()} })
$feedbackCache=@(Get-ChildItem -LiteralPath (Join-Path $feedbackRoot '.godot/imported') -File | ForEach-Object { [ordered]@{path=[IO.Path]::GetRelativePath($feedbackRoot,$_.FullName).Replace('\','/');sha256=(Get-FileHash -LiteralPath $_.FullName).Hash.ToLowerInvariant()} })
$feedbackStages=[Collections.Generic.List[object]]::new()
$feedbackReport=[ordered]@{base='088d4ba815884a431f44e73d93cfb6881ff7faa3';execution_head=(git -C $feedbackRoot rev-parse HEAD).Trim();execution_dirty=@(git -C $feedbackRoot status --porcelain);status='RUNNING';source_files=$feedbackSources;import_cache_files=$feedbackCache;engine_path=$Godot;engine_sha256=(Get-FileHash -LiteralPath $Godot).Hash.ToLowerInvariant();profile=$feedbackProfile;display='headless';graphical='NOT_RUN';human_qa='NOT_RUN';migration='PRE_MIGRATION_BASELINE';stages=@();source_drift=$null}
function Save-FeedbackReport { $feedbackReport.stages=@($feedbackStages.ToArray()); [IO.File]::WriteAllText((Join-Path $feedbackEvidence 'run_report.json'),($feedbackReport | ConvertTo-Json -Depth 14).Replace("`r`n","`n")+"`n",[Text.UTF8Encoding]::new($false)) }
try {
 foreach ($feedbackPhase in @('mechanisms','loop_seed','loop_restore')) {
  $feedbackPrior=Join-Path $feedbackEvidence 'loop_seed/report.json'
  $feedbackStage=[ordered]@{phase=$feedbackPhase;pid=$null;exit_code=$null;stderr_bytes=$null;checks=0;failures=@();status='RUNNING'}
  $feedbackStages.Add($feedbackStage); Save-FeedbackReport
  if ($feedbackPhase -eq 'loop_restore' -and (-not (Test-Path -LiteralPath $feedbackPrior) -or ($feedbackStages | Where-Object {$_.phase -eq 'loop_seed'}).status -ne 'PASS')) { $feedbackStage.status='NOT_RUN_DEPENDENCY'; Save-FeedbackReport; continue }
  $feedbackArgs=@('--headless','--path',('"'+$feedbackRoot+'"'),'--script','res://tests/beta_sprint/spatial_owner_07/feedback_02/test_feedback.gd','--',"--phase=$feedbackPhase",('--evidence-dir="'+(Join-Path $feedbackEvidence $feedbackPhase)+'"'),"--save-root=user://spatial_puzzle_batch_01/tests/$EvidenceName/",('--prior-report="'+$feedbackPrior+'"'))
  $feedbackStage.args=$feedbackArgs
  $feedbackStdout=Join-Path $feedbackEvidence "$feedbackPhase.stdout.log"; $feedbackStderr=Join-Path $feedbackEvidence "$feedbackPhase.stderr.log"
  $feedbackProcess=Start-Process -FilePath $Godot -ArgumentList $feedbackArgs -WindowStyle Hidden -PassThru -Environment @{APPDATA=$feedbackProfile;LOCALAPPDATA=$feedbackProfile} -RedirectStandardOutput $feedbackStdout -RedirectStandardError $feedbackStderr
  $feedbackStage.pid=$feedbackProcess.Id; Save-FeedbackReport
  if (-not $feedbackProcess.WaitForExit(60000)) { $feedbackProcess.Kill(); $feedbackProcess.WaitForExit(); throw 'Own headless process timed out; raw retained' }
  $feedbackProcess.WaitForExit()
  $feedbackStage.exit_code=$feedbackProcess.ExitCode; $feedbackStage.stderr_bytes=(Get-Item -LiteralPath $feedbackStderr).Length
  $feedbackCasePath=Join-Path $feedbackEvidence "$feedbackPhase/report.json"
  if (Test-Path -LiteralPath $feedbackCasePath) {
   $feedbackCase=Get-Content -LiteralPath $feedbackCasePath -Raw | ConvertFrom-Json
   if ($feedbackCase.pid -ne $feedbackStage.pid -or $feedbackCase.phase -ne $feedbackPhase -or $feedbackCase.display -ne 'headless' -or -not $feedbackCase.user_data_dir.StartsWith($feedbackProfile.Replace('\','/'),[StringComparison]::OrdinalIgnoreCase)) { throw 'Actual process/profile mismatch' }
   $feedbackStage.checks=$feedbackCase.checks; $feedbackStage.failures=@($feedbackCase.failures)
  }
  $feedbackOutput=Get-Content -LiteralPath $feedbackStdout -Raw
  $feedbackStage.status=if ($feedbackStage.exit_code -eq 0 -and $feedbackStage.stderr_bytes -eq 0 -and $feedbackStage.checks -gt 0 -and $feedbackStage.failures.Count -eq 0 -and $feedbackOutput -notmatch 'SCRIPT ERROR:|ERROR:|FAIL:') {'PASS'} else {'FAIL'}
  Save-FeedbackReport
  Write-Output "$feedbackPhase $($feedbackStage.status) checks=$($feedbackStage.checks) failures=$($feedbackStage.failures.Count) exit=$($feedbackStage.exit_code) stderr=$($feedbackStage.stderr_bytes)"
 }
 foreach ($feedbackFile in @($feedbackSources)+@($feedbackCache)) { if ((Get-FileHash -LiteralPath (Join-Path $feedbackRoot $feedbackFile.path)).Hash.ToLowerInvariant() -ne $feedbackFile.sha256) { throw 'Source/import drift' } }
 $feedbackReport.source_drift=$false
 $feedbackReport.checks=(($feedbackStages.ToArray() | ForEach-Object {[int]$_.checks}) | Measure-Object -Sum).Sum
 $feedbackReport.status=if (@($feedbackStages | Where-Object {$_.status -ne 'PASS'}).Count -eq 0) {'PASS'} else {'PARTIAL'}
 Save-FeedbackReport
 if ($feedbackReport.status -ne 'PASS') { throw 'Some actual cases failed or were not run; raw evidence retained' }
 Write-Output "SPATIAL_UI_FEEDBACK02_HEADLESS_PASS checks=$($feedbackReport.checks) $feedbackEvidence"
} catch { $feedbackReport.failure=$_.Exception.Message; if ($feedbackReport.status -eq 'RUNNING') {$feedbackReport.status='FAIL'}; Save-FeedbackReport; throw }
