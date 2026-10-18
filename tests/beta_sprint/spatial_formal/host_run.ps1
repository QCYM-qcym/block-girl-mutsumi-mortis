param(
 [string]$Godot='D:/APP/steam/steamapps/common/Godot Engine/godot.windows.opt.tools.64.exe',
 [string]$EvidenceRoot='E:/godot/qa/spatial-formal-host'
)
$ErrorActionPreference='Stop'
$sourceRoot=(Resolve-Path -LiteralPath (Join-Path $PSScriptRoot '../../..')).Path
$runRoot=Join-Path $EvidenceRoot ((Get-Date -Format 'yyyyMMdd_HHmmss')+'_'+[guid]::NewGuid().ToString('N').Substring(0,8))
$projectRoot=Join-Path $runRoot 'project'
$profileRoot=Join-Path $runRoot 'profile'
New-Item -ItemType Directory -Path $projectRoot,$profileRoot | Out-Null
$paths=@('foundation','game/feel','game/levels/mutsumi/spatial_chapter','game/shell/visual_01','experiments/game_feel_01/host','experiments/spatial_puzzle_batch_01/host','experiments/spatial_puzzle_batch_01/maps','production/experimental/game_feel_01/audio','production/ui/beta_shell_01/fonts','production/ui/beta_shell_01/icons','tests/beta_sprint/spatial_formal','default_bus_layout.tres')
$files=@(git -C $sourceRoot ls-files --cached --others --exclude-standard -- $paths)
$hashes=@()
foreach ($relative in $files) {
 $destination=Join-Path $projectRoot $relative
 New-Item -ItemType Directory -Force -Path (Split-Path -Parent $destination) | Out-Null
 Copy-Item -LiteralPath (Join-Path $sourceRoot $relative) -Destination $destination
 $hashes+=@{path=$relative;sha256=(Get-FileHash -LiteralPath $destination).Hash.ToLowerInvariant()}
}
@{head=(git -C $sourceRoot rev-parse HEAD);files=$hashes} | ConvertTo-Json -Depth 6 | Set-Content -Encoding utf8 (Join-Path $runRoot 'source_manifest.json')
@'
config_version=5
[application]
config/name="Spatial Formal Host Isolated Tests"
[rendering]
renderer/rendering_method="gl_compatibility"
'@ | Set-Content -Encoding utf8 (Join-Path $projectRoot 'project.godot')
$stages=@(
 @{name='import';args=@('--headless','--editor','--path',('"'+$projectRoot+'"'),'--import')},
 @{name='host_lifecycle';args=@('--headless','--verbose','--path',('"'+$projectRoot+'"'),'--script','res://tests/beta_sprint/spatial_formal/host_lifecycle.gd')}
)
foreach ($stage in $stages) {
 $stdout=Join-Path $runRoot ($stage.name+'.stdout.log')
 $stderr=Join-Path $runRoot ($stage.name+'.stderr.log')
 $process=Start-Process -FilePath $Godot -ArgumentList $stage.args -WindowStyle Hidden -PassThru -Environment @{APPDATA=$profileRoot;LOCALAPPDATA=$profileRoot;FOUNDATION_TEST_EVIDENCE=$runRoot} -RedirectStandardOutput $stdout -RedirectStandardError $stderr
 if (-not $process.WaitForExit(60000)) { $process.Kill(); $process.WaitForExit(); throw "Own hidden headless process timeout: $runRoot" }
 $process.WaitForExit()
 $outText=Get-Content -LiteralPath $stdout -Raw
 $errText=Get-Content -LiteralPath $stderr -Raw
 Write-Output "$($stage.name) exit=$($process.ExitCode) evidence=$runRoot"
 if ($process.ExitCode -ne 0 -or $errText -match 'SCRIPT ERROR:|ERROR:' -or $outText -match 'FAIL:') { Write-Output $outText; Write-Output $errText; exit 1 }
}
Write-Output (Get-Content -LiteralPath (Join-Path $runRoot 'report.json') -Raw)
