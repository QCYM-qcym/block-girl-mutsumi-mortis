param([string]$Godot='D:/APP/steam/steamapps/common/Godot Engine/godot.windows.opt.tools.64.exe',[string]$EvidenceName=('polish03_'+(Get-Date -Format 'yyyyMMdd_HHmmss')+'_'+[guid]::NewGuid().ToString('N').Substring(0,8)))
$ErrorActionPreference='Stop'
if($EvidenceName -notmatch '^[a-zA-Z0-9_-]+$'){throw 'Simple fresh evidence name required'}
$polishRoot=(Resolve-Path -LiteralPath (Join-Path $PSScriptRoot '../../../..')).Path
$polishEvidence=Join-Path $polishRoot ".godot/spatial-polish03/$EvidenceName"
if(Test-Path -LiteralPath $polishEvidence){throw 'Evidence is append-only'}
$polishProfile=Join-Path $polishEvidence 'profile'
New-Item -ItemType Directory -Path $polishProfile -Force | Out-Null
$polishPaths=@(git -C $polishRoot ls-files --cached --others --exclude-standard -- project.godot default_bus_layout.tres foundation game/shell game/feel experiments/game_feel_01/host experiments/spatial_puzzle_batch_01 production/ui/beta_shell_01 production/experimental/game_feel_01/audio tests/beta_sprint/spatial_owner_07/polish_03)
$polishSources=@($polishPaths | Sort-Object -Unique | ForEach-Object {[ordered]@{path=$_;sha256=(Get-FileHash -LiteralPath (Join-Path $polishRoot $_)).Hash.ToLowerInvariant()}})
$polishCache=@(Get-ChildItem -LiteralPath (Join-Path $polishRoot '.godot/imported') -File | ForEach-Object {[ordered]@{path=[IO.Path]::GetRelativePath($polishRoot,$_.FullName).Replace('\','/');sha256=(Get-FileHash -LiteralPath $_.FullName).Hash.ToLowerInvariant()}})
$polishReport=[ordered]@{task='SPATIAL_PUZZLE_BATCH_01_POLISH_AND_ACCEPTANCE_03';defect='QA08-C02-UI-RESET-LABEL-01';base='e4fe5365334e93138dc9b8856d09670478789abc';execution_head=(git -C $polishRoot rev-parse HEAD).Trim();execution_dirty=@(git -C $polishRoot status --porcelain);status='RUNNING';source_files=$polishSources;import_cache_files=$polishCache;engine_path=$Godot;engine_sha256=(Get-FileHash -LiteralPath $Godot).Hash.ToLowerInvariant();profile=$polishProfile;pid=$null;exit_code=$null;stderr_bytes=$null;checks=0;failures=@();source_drift=$null;graphical='NOT_RUN';human_qa='NOT_RUN';integration='PENDING_00'}
function Save-PolishReport{[IO.File]::WriteAllText((Join-Path $polishEvidence 'run_report.json'),($polishReport | ConvertTo-Json -Depth 14).Replace("`r`n","`n")+"`n",[Text.UTF8Encoding]::new($false))}
Save-PolishReport
try{
 $polishArgs=@('--headless','--path',('"'+$polishRoot+'"'),'--script','res://tests/beta_sprint/spatial_owner_07/polish_03/test_reset.gd','--',('--evidence-dir="'+$polishEvidence+'"'))
 $polishReport.args=$polishArgs
 $polishStdout=Join-Path $polishEvidence 'stdout.log'; $polishStderr=Join-Path $polishEvidence 'stderr.log'
 $polishProcess=Start-Process -FilePath $Godot -ArgumentList $polishArgs -WindowStyle Hidden -PassThru -Environment @{APPDATA=$polishProfile;LOCALAPPDATA=$polishProfile} -RedirectStandardOutput $polishStdout -RedirectStandardError $polishStderr
 $polishReport.pid=$polishProcess.Id; Save-PolishReport
 if(-not $polishProcess.WaitForExit(60000)){$polishProcess.Kill(); $polishProcess.WaitForExit(); throw 'Own headless PID timeout; raw retained'}
 $polishProcess.WaitForExit()
 $polishReport.exit_code=$polishProcess.ExitCode; $polishReport.stderr_bytes=(Get-Item -LiteralPath $polishStderr).Length
 $polishCasePath=Join-Path $polishEvidence 'report.json'
 if(Test-Path -LiteralPath $polishCasePath){
  $polishCase=Get-Content -LiteralPath $polishCasePath -Raw | ConvertFrom-Json
  if($polishCase.pid -ne $polishProcess.Id -or $polishCase.display -ne 'headless' -or -not $polishCase.user_data_dir.StartsWith($polishProfile.Replace('\','/'),[StringComparison]::OrdinalIgnoreCase)){throw 'Actual PID/profile/display mismatch'}
  $polishReport.checks=[int]$polishCase.checks; $polishReport.failures=@($polishCase.failures)
 }
 foreach($polishFile in @($polishSources)+@($polishCache)){if((Get-FileHash -LiteralPath (Join-Path $polishRoot $polishFile.path)).Hash.ToLowerInvariant() -ne $polishFile.sha256){throw 'Source/cache drift'}}
 $polishReport.source_drift=$false
 $polishReport.status=if($polishReport.exit_code -eq 0 -and $polishReport.stderr_bytes -eq 0 -and $polishReport.checks -gt 0 -and $polishReport.failures.Count -eq 0){'PASS'}else{'FAIL'}
 Save-PolishReport
 Write-Output "POLISH03 $($polishReport.status) checks=$($polishReport.checks) failures=$($polishReport.failures.Count) exit=$($polishReport.exit_code) stderr=$($polishReport.stderr_bytes) $polishEvidence"
 if($polishReport.status -ne 'PASS'){throw 'Actual scoped test failed; raw retained'}
}catch{$polishReport.failure=$_.Exception.Message; if($polishReport.status -eq 'RUNNING'){$polishReport.status='FAIL'}; Save-PolishReport; throw}
