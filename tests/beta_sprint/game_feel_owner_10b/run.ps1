param(
    [ValidateSet('unit','graphical','mapper','runtime','import')][string]$Mode='unit',
    [string]$Case=('run_'+(Get-Date -Format 'yyyyMMdd_HHmmss')+'_'+[guid]::NewGuid().ToString('N').Substring(0,5)),
    [int]$Timeout=90
)
$ErrorActionPreference='Stop'
if($Case -notmatch '^[a-zA-Z0-9_-]+$'){throw 'Use a simple unique case.'}
$edgeRoot=(Resolve-Path -LiteralPath (Join-Path $PSScriptRoot '../../..')).Path
$caseRoot=Join-Path $edgeRoot "docs/beta-sprint/game-feel-owner-10b/evidence/$Case"
if(Test-Path -LiteralPath $caseRoot){throw 'Evidence exists; choose a new case.'}
New-Item -ItemType Directory -Path $caseRoot | Out-Null
$edgeEngine='D:/APP/steam/steamapps/common/Godot Engine/godot.windows.opt.tools.64.exe'
$edgeArgs=@('--path',('"'+$edgeRoot+'"'),'--max-fps','120')
$edgeScript=switch($Mode){'unit'{'res://tests/beta_sprint/game_feel_owner_10b/test_unit.gd'} 'graphical'{'res://tests/beta_sprint/game_feel_owner_10b/test_graphical.gd'} 'mapper'{'res://tests/foundation/runtime/test_input_mapper.gd'} 'runtime'{'res://tests/foundation/runtime/test_runtime_session.gd'}}
if($Mode -eq 'import'){$edgeArgs+=@('--headless','--editor','--import')}
else{
    if($Mode -ne 'graphical'){$edgeArgs+='--headless'}
    $edgeArgs+=@('--script',$edgeScript,'--',('--evidence-dir='+$caseRoot))
}
$edgeFiles=@(& git -C $edgeRoot ls-files --cached --others --exclude-standard -- game/feel/animation/edge_recoil tests/beta_sprint/game_feel_owner_10b foundation prototype/foundation/runtime production/art_3d/BG_CH_WAKABA_CUBE_001 production/art_3d/BG_CH_MORTIS_CUBE_001 docs/beta-sprint/game-feel/GAME_FEEL_CONTRACT.md)
$edgeSources=@($edgeFiles | Sort-Object -Unique | ForEach-Object {if(Test-Path -LiteralPath (Join-Path $edgeRoot $_) -PathType Leaf){@{path=$_;sha256=(Get-FileHash -LiteralPath (Join-Path $edgeRoot $_)).Hash.ToLowerInvariant()}}})
$edgeRecord=[ordered]@{mode=$Mode;case=$Case;head=(& git -C $edgeRoot rev-parse HEAD).Trim();dirty=@(& git -C $edgeRoot status --porcelain);arguments=$edgeArgs;script=$edgeScript;sources=$edgeSources;engine_path=$edgeEngine;engine_sha256=(Get-FileHash -LiteralPath $edgeEngine).Hash.ToLowerInvariant();input='DTO sampling (Unit); graphical native mapper with synthetic classified event';started=(Get-Date -Format o);pid=$null;status='RUNNING'}
$edgeEnvironment=@{}
foreach($edgeVar in @('APPDATA','LOCALAPPDATA','USERPROFILE','HOME','XDG_DATA_HOME','XDG_CONFIG_HOME','XDG_CACHE_HOME')){$edgeEnvironment[$edgeVar]=Join-Path $caseRoot ('profile/'+$edgeVar.ToLowerInvariant());New-Item -ItemType Directory -Path $edgeEnvironment[$edgeVar] -Force | Out-Null}
$edgeRecord.profile_environment=$edgeEnvironment
function Save-EdgeRecord {$edgeRecord | ConvertTo-Json -Depth 14 | Set-Content -LiteralPath (Join-Path $caseRoot 'process.json') -Encoding utf8}
Save-EdgeRecord
$edgeProcess=Start-Process -FilePath $edgeEngine -ArgumentList $edgeArgs -Environment $edgeEnvironment -WindowStyle Hidden -RedirectStandardOutput (Join-Path $caseRoot 'stdout.log') -RedirectStandardError (Join-Path $caseRoot 'stderr.log') -PassThru
$edgeRecord.pid=$edgeProcess.Id; Save-EdgeRecord
if(-not $edgeProcess.WaitForExit($Timeout*1000)){$edgeProcess.Kill();$edgeRecord.status='TIMEOUT'}
$edgeProcess.WaitForExit();$edgeRecord.exit_code=$edgeProcess.ExitCode
$edgeRecord.finished=(Get-Date -Format o)
$edgeRecord.stderr=Get-Content -LiteralPath (Join-Path $caseRoot 'stderr.log') -Raw
$edgeRecord.stdout_tail=@(Get-Content -LiteralPath (Join-Path $caseRoot 'stdout.log') -Tail 8)
if(Test-Path -LiteralPath (Join-Path $caseRoot 'report.json')){$edgeRecord.report=Get-Content -LiteralPath (Join-Path $caseRoot 'report.json') -Raw | ConvertFrom-Json}
$edgeOutput=Get-Content -LiteralPath (Join-Path $caseRoot 'stdout.log') -Raw
$edgeValidResult=if($Mode -in @('unit','graphical')){$edgeRecord.Contains('report') -and $edgeRecord.report.checks -gt 0 -and @($edgeRecord.report.failures).Count -eq 0 -and $edgeRecord.report.user_data_dir.StartsWith($caseRoot.Replace('\','/'),[StringComparison]::OrdinalIgnoreCase)}elseif($Mode -eq 'import'){$true}else{$edgeOutput -match 'FOUNDATION_(INPUT_MAPPER|RUNTIME_SESSION)_PASS'}
if($Mode -eq 'graphical' -and $edgeValidResult){$edgeValidResult=$edgeRecord.report.display -ne 'headless' -and @($edgeRecord.report.shots).Count -gt 0 -and @($edgeRecord.report.natural_samples).Count -gt 0}
$edgeRecord.source_drift=@($edgeSources | Where-Object { -not(Test-Path -LiteralPath (Join-Path $edgeRoot $_.path)) -or (Get-FileHash -LiteralPath (Join-Path $edgeRoot $_.path)).Hash.ToLowerInvariant() -ne $_.sha256})
$edgeRecord.status=if($edgeRecord.status -eq 'TIMEOUT'){'TIMEOUT'}elseif($edgeRecord.exit_code -eq 0 -and [string]::IsNullOrEmpty($edgeRecord.stderr) -and $edgeRecord.source_drift.Count -eq 0 -and $edgeValidResult -and $edgeOutput -notmatch 'SCRIPT ERROR:|ERROR:|FAIL:'){'PASS'}else{'FAILED'}
Save-EdgeRecord
Write-Output "$Mode $Case PID=$($edgeRecord.pid) exit=$($edgeRecord.exit_code) status=$($edgeRecord.status)"
$edgeRecord.stdout_tail | Write-Output
if($edgeRecord.stderr){Write-Output $edgeRecord.stderr}
if($edgeRecord.status -ne 'PASS'){exit 1}
