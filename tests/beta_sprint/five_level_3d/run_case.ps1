param(
    [ValidateSet('import','entry','gameplay','continue')][string]$Mode = 'entry',
    [string]$Case = ('r' + (Get-Date -Format 'HHmmss') + '_' + [guid]::NewGuid().ToString('N').Substring(0,5)),
    [string]$Save = '',
    [int]$Timeout = 240,
    [switch]$VerboseEngine,
    [switch]$BaselineLayout,
    [ValidateSet('default','forward_plus','gl_compatibility')][string]$Renderer = 'default'
)
$ErrorActionPreference = 'Stop'
if ($Case -notmatch '^[a-zA-Z0-9_-]{1,30}$') { throw 'Use a short unique case name.' }
$ownerRoot = (Resolve-Path -LiteralPath (Join-Path $PSScriptRoot '../../..')).Path
$caseRoot = Join-Path $ownerRoot "docs/beta-sprint/five-level-3d-owner/evidence/$Case"
if (Test-Path -LiteralPath $caseRoot) { throw 'Case exists: evidence must never be overwritten.' }
New-Item -ItemType Directory -Path $caseRoot | Out-Null
$engine = 'D:/APP/steam/steamapps/common/Godot Engine/godot.windows.opt.tools.64.exe'
$args = @('--path', ('"'+$ownerRoot+'"'))
if ($VerboseEngine) { $args += '--verbose' }
if ($Mode -eq 'import') { $args += @('--headless','--editor','--import') }
elseif ($Mode -eq 'entry') { $args += @('--headless','--script','res://tests/beta_sprint/five_level_3d/test_entry.gd','--',('--evidence-dir='+$caseRoot)) }
else {
    if ($Renderer -ne 'default') { $args += @('--rendering-method',$Renderer) }
    if ($Mode -eq 'gameplay' -and [string]::IsNullOrEmpty($Save)) { $Save = 'user://beta_sprint/five_level_3d_owner/'+$Case+'_'+[guid]::NewGuid().ToString('N')+'/progress.json' }
    $args += @('--script','res://tests/beta_sprint/five_level_3d/test_gameplay.gd','--',('--evidence-dir='+$caseRoot),('--shell-save='+$Save),('--head='+(& git -C $ownerRoot rev-parse HEAD).Trim()))
    if ($Mode -eq 'continue') { $args += @('--cold-continue',('--shell-save='+$Save)) }
}
if ($BaselineLayout) { $args += '--baseline-layout' }
$files = @(& git -C $ownerRoot ls-files --cached --others --exclude-standard -- game prototype/perspective production/art_3d production/ui/beta_shell_01 tests/beta_sprint/five_level_3d project.godot)
$sources = @($files | Sort-Object -Unique | ForEach-Object { if (Test-Path -LiteralPath (Join-Path $ownerRoot $_) -PathType Leaf) { @{path=$_;sha256=(Get-FileHash -LiteralPath (Join-Path $ownerRoot $_)).Hash.ToLowerInvariant()} } })
$record = [ordered]@{mode=$Mode;case=$Case;head=(& git -C $ownerRoot rev-parse HEAD).Trim();project=$ownerRoot;arguments=$args;renderer_request=$Renderer;save_path=$Save;engine_sha256=(Get-FileHash -LiteralPath $engine).Hash.ToLowerInvariant();sources=$sources;started=(Get-Date -Format o);pid=$null;exit_code=$null;status='RUNNING'}
function Save-Record { $record | ConvertTo-Json -Depth 12 | Set-Content -LiteralPath (Join-Path $caseRoot 'process.json') -Encoding utf8 }
Save-Record
$proc = Start-Process -FilePath $engine -ArgumentList $args -WindowStyle Hidden -RedirectStandardOutput (Join-Path $caseRoot 'stdout.log') -RedirectStandardError (Join-Path $caseRoot 'stderr.log') -PassThru
$record.pid = $proc.Id
Save-Record
if (-not $proc.WaitForExit($Timeout*1000)) { $proc.Kill(); $record.status='TIMEOUT' }
$proc.WaitForExit()
$record.exit_code = $proc.ExitCode
$record.finished = (Get-Date -Format o)
$record.stderr = Get-Content -LiteralPath (Join-Path $caseRoot 'stderr.log') -Raw
if ($Mode -eq 'import') { $record.status = if ($record.exit_code -eq 0) { 'IMPORTED_WITH_RECORDED_DIAGNOSTICS' } else { 'FAILED' } }
else {
    $record.checks = 0
    $record.failures = @('missing report')
    if (Test-Path -LiteralPath (Join-Path $caseRoot 'report.json')) {
        $report = Get-Content -LiteralPath (Join-Path $caseRoot 'report.json') -Raw | ConvertFrom-Json
        $record.checks=$report.checks
        $record.failures=@($report.failures)
    }
    $record.status=if($record.exit_code -eq 0 -and $record.checks -gt 0 -and $record.failures.Count -eq 0 -and [string]::IsNullOrEmpty($record.stderr)){'PASS'}else{'FAILED'}
}
$changed = @($sources | Where-Object { -not (Test-Path -LiteralPath (Join-Path $ownerRoot $_.path) -PathType Leaf) -or (Get-FileHash -LiteralPath (Join-Path $ownerRoot $_.path)).Hash.ToLowerInvariant() -ne $_.sha256 })
$record.source_changes_during_run = $changed
if ($changed.Count -gt 0) { $record.status='FAILED_SOURCE_DRIFT' }
Save-Record
Write-Output "$Mode $Case PID=$($record.pid) exit=$($record.exit_code) status=$($record.status) checks=$($record.checks)"
Get-Content -LiteralPath (Join-Path $caseRoot 'stdout.log') -Tail 3
if ($record.stderr) { Write-Output $record.stderr }
if ($Mode -ne 'import' -and $record.status -ne 'PASS') { exit 1 }
exit $record.exit_code
