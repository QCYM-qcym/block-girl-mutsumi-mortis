param([string]$Session = 'matrix')
$ErrorActionPreference = 'Stop'
$focusLaunchRoot = $PSScriptRoot
$focusLaunchAppdata = $env:APPDATA
try {
    $env:APPDATA = Join-Path $focusLaunchRoot 'profile/Roaming'
    $focusLaunchArgs = @('--path','"E:/godot/beta-sprint-builds/beta_3d02_20261009_01/project"','--windowed','--position','50,70','--script',('"'+$focusLaunchRoot+'/window_matrix.gd"'),'--log-file',('"'+$focusLaunchRoot+'/'+$Session+'_runtime.log"'),'--','--shell-save=user://beta_sprint/beta_3d02_focused_qa_20261009_01/qa_progress.json')
    $focusLaunchProc = Start-Process -FilePath 'D:/APP/steam/steamapps/common/Godot Engine/godot.windows.opt.tools.64.exe' -ArgumentList $focusLaunchArgs -WindowStyle Normal -PassThru -RedirectStandardOutput (Join-Path $focusLaunchRoot ($Session+'_stdout.log')) -RedirectStandardError (Join-Path $focusLaunchRoot ($Session+'_stderr.log'))
    $focusLaunchRecord = [ordered]@{ session=$Session; pid=$focusLaunchProc.Id; start_time=$focusLaunchProc.StartTime.ToUniversalTime().ToString('o'); launched_at=(Get-Date).ToUniversalTime().ToString('o'); executable=$focusLaunchProc.Path; args=$focusLaunchArgs; appdata=$env:APPDATA }
    $focusLaunchRecord | ConvertTo-Json -Depth 6 | Set-Content -LiteralPath (Join-Path $focusLaunchRoot ($Session+'_process.json')) -Encoding UTF8
    $focusLaunchRecord | ConvertTo-Json -Depth 6
} finally { $env:APPDATA = $focusLaunchAppdata }
