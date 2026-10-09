param(
    [ValidateSet('probe','controls','playthrough','import','unit_regression')][string]$Case = 'probe',
    [ValidateSet('shell','standalone')][string]$Entry = 'shell',
    [switch]$Graphical,
    [string]$RunId = ('run_' + (Get-Date -Format 'yyyyMMdd_HHmmss')),
    [string]$Godot = 'D:/APP/steam/steamapps/common/Godot Engine/godot.windows.opt.tools.64.exe'
)
$ErrorActionPreference = 'Stop'
if ($Entry -eq 'standalone' -and $Case -ne 'probe') { throw 'standalone is only valid for probe; controls and playthrough require the actual Shell catalog' }
if ($RunId -notmatch '^[A-Za-z0-9_-]+$') { throw 'Use a fresh simple RunId' }
$l04Project = (Resolve-Path -LiteralPath (Join-Path $PSScriptRoot '../../..')).Path
$l04Evidence = Join-Path $PSScriptRoot "evidence/$RunId"
if (Test-Path -LiteralPath $l04Evidence) { throw 'Preserving historical evidence; select another RunId' }
New-Item -ItemType Directory -Path $l04Evidence | Out-Null
$l04Args = @('--path',('"'+$l04Project+'"'))
if (-not $Graphical) { $l04Args += '--headless' }
if ($Case -eq 'import') { $l04Args += @('--editor','--import') }
else {
    $l04Script = if ($Case -eq 'unit_regression') { 'res://tests/beta_sprint/content_batch_02/test_state.gd' } elseif ($Case -eq 'playthrough') { 'res://tests/beta_sprint/l04_inner_movement_p1/test_playthrough.gd' } else { 'res://tests/beta_sprint/l04_inner_movement_p1/test_l04.gd' }
    $l04Args += @('--max-fps','60','--script',$l04Script,'--',('--evidence-dir="'+$l04Evidence+'"'),('--case='+$Case),('--entry='+$Entry))
    if ($Graphical) { $l04Args += '--graphical' }
}
$l04Source = [ordered]@{}
$l04Paths = @('project.godot','game/shell/game_shell.tscn','game/shell/game_shell.gd','game/shell/level_adapter.gd','game/shell/level_catalog.gd','game/shell/save_store.gd','game/player/grid_input.gd','prototype/perspective/grid_movement.gd','prototype/perspective/cube_orientation.gd','prototype/perspective/perspective_controller.gd','prototype/perspective/perspective_link.gd','prototype/perspective/connectivity.gd','game/levels/mutsumi/p01_state.gd','game/levels/mutsumi/p01_another_world.gd','game/levels/mutsumi/batch_01/content_level.gd','game/levels/mutsumi/batch_01/content_level_data.gd','game/levels/mutsumi/batch_01/content_state.gd','game/levels/mutsumi/batch_01/l01_3d/l01_presented.gd','game/levels/mutsumi/batch_01/l01_3d/presenter.gd','game/levels/mutsumi/batch_01/levels_3d/presenter.gd','game/levels/mutsumi/batch_01/level_order.json','game/levels/mutsumi/batch_01/l01_another_world.tres','game/levels/mutsumi/batch_01/l02_between_shores.tres','game/levels/mutsumi/batch_01/l03_lines_meet.tres','game/levels/mutsumi/batch_02/batch_02_level.gd','game/levels/mutsumi/batch_02/batch_02_hints.gd','game/levels/mutsumi/batch_02/l04_borrowed_path.tres','game/levels/mutsumi/batch_02/l04_borrowed_path.tscn','game/levels/mutsumi/batch_02/l05_gate_home.tres','tests/beta_sprint/l04_inner_movement_p1/test_l04.gd','tests/beta_sprint/l04_inner_movement_p1/run.ps1','tests/beta_sprint/content_batch_02/test_state.gd')
foreach ($l04Path in $l04Paths) { $l04Source[$l04Path] = (Get-FileHash -LiteralPath (Join-Path $l04Project $l04Path) -Algorithm SHA256).Hash.ToLowerInvariant() }
$l04PlaySource = 'tests/beta_sprint/l04_inner_movement_p1/test_playthrough.gd'
$l04Source[$l04PlaySource] = (Get-FileHash -LiteralPath (Join-Path $l04Project $l04PlaySource) -Algorithm SHA256).Hash.ToLowerInvariant()
$l04ImportBytes = @{}
if ($Case -eq 'import') {
    foreach ($l04Import in @(git -C $l04Project ls-files -- '*.import')) { $l04ImportBytes[$l04Import] = [IO.File]::ReadAllBytes((Join-Path $l04Project $l04Import)) }
}
$l04Out = Join-Path $l04Evidence 'stdout.log'
$l04Err = Join-Path $l04Evidence 'stderr.log'
$l04Start = [DateTime]::UtcNow
$l04Process = Start-Process -FilePath $Godot -ArgumentList $l04Args -WindowStyle Hidden -PassThru -RedirectStandardOutput $l04Out -RedirectStandardError $l04Err
Write-Output "START L04-P1 case=$Case entry=$Entry graphical=$Graphical PID=$($l04Process.Id)"
$l04TimedOut = -not $l04Process.WaitForExit(240000)
if ($l04TimedOut) { $l04Process.Kill() }
$l04Process.WaitForExit()
$l04Restored = @()
foreach ($l04Import in $l04ImportBytes.Keys) {
    $l04Path = Join-Path $l04Project $l04Import
    $l04CurrentBytes = [IO.File]::ReadAllBytes($l04Path)
    if ([Convert]::ToBase64String($l04CurrentBytes) -ne [Convert]::ToBase64String($l04ImportBytes[$l04Import])) { [IO.File]::WriteAllBytes($l04Path,$l04ImportBytes[$l04Import]); $l04Restored += $l04Import }
}
$l04SourceChanged = @()
foreach ($l04Path in $l04Source.Keys) { if ((Get-FileHash -LiteralPath (Join-Path $l04Project $l04Path) -Algorithm SHA256).Hash.ToLowerInvariant() -ne $l04Source[$l04Path]) { $l04SourceChanged += $l04Path } }
$l04ProcInfo = [ordered]@{case=$Case;entry=$Entry;graphical=[bool]$Graphical;pid=$l04Process.Id;exit_code=$l04Process.ExitCode;timed_out=$l04TimedOut;start_utc=$l04Start.ToString('o');end_utc=[DateTime]::UtcNow.ToString('o');project=$l04Project;head=(git -C $l04Project rev-parse HEAD);args=$l04Args;source_sha256=$l04Source;source_changed=$l04SourceChanged;restored_import_metadata=$l04Restored;stdout_sha256=(Get-FileHash -LiteralPath $l04Out -Algorithm SHA256).Hash.ToLowerInvariant();stderr_sha256=(Get-FileHash -LiteralPath $l04Err -Algorithm SHA256).Hash.ToLowerInvariant()}
[IO.File]::WriteAllText((Join-Path $l04Evidence 'process.json'),(($l04ProcInfo | ConvertTo-Json -Depth 8).Replace("`r`n","`n")+"`n"),[Text.UTF8Encoding]::new($false))
Get-Content -LiteralPath $l04Out -Tail 12
$l04Errors = Get-Content -LiteralPath $l04Err -Raw
if ($l04Errors) { Write-Output $l04Errors }
Write-Output "L04-P1 case=$Case PID=$($l04Process.Id) exit=$($l04Process.ExitCode) evidence=$l04Evidence"
if ($l04TimedOut -or $l04Process.ExitCode -ne 0 -or $l04SourceChanged.Count -ne 0 -or $l04Errors -match 'SCRIPT ERROR:|ERROR:|FAIL') { throw 'Run failed; actual evidence preserved' }
