param([string]$Godot = 'D:/APP/steam/steamapps/common/Godot Engine/godot.windows.opt.tools.64.exe')
$ErrorActionPreference = 'Stop'
if (-not (Test-Path -LiteralPath $Godot)) { throw 'Pass -Godot with a Godot 4.7.2 executable.' }
$qaPlayProject = Join-Path $PSScriptRoot 'project'
$qaImport = Start-Process -FilePath $Godot -ArgumentList @('--headless','--editor','--import','--path',('"'+$qaPlayProject+'"')) -WindowStyle Hidden -PassThru -Wait
if ($qaImport.ExitCode -ne 0) { throw 'Godot import failed; preserve evidence.' }
$qaGame = Start-Process -FilePath $Godot -ArgumentList @('--path',('"'+$qaPlayProject+'"'),'--','--shell-save=user://beta_sprint/beta_five_level_3d_20261009_01/qa_progress.json') -WindowStyle Normal -PassThru -Wait
exit $qaGame.ExitCode
