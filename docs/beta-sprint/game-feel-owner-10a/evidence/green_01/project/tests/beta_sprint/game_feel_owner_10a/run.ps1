param(
    [ValidateSet('unit','preview')][string]$Mode = 'unit',
    [Parameter(Mandatory)][ValidatePattern('^[a-zA-Z0-9_-]+$')][string]$Case,
    [string]$Godot = 'D:/APP/steam/steamapps/common/Godot Engine/godot.windows.opt.tools.64.exe'
)
$ErrorActionPreference = 'Stop'
$motionRoot = (Resolve-Path -LiteralPath (Join-Path $PSScriptRoot '../../..')).Path
$motionOut = Join-Path $motionRoot "docs/beta-sprint/game-feel-owner-10a/evidence/$Case"
if (Test-Path -LiteralPath $motionOut) { throw 'Append-only evidence: choose a fresh Case.' }
$motionProject = Join-Path $motionOut 'project'
New-Item -ItemType Directory -Path $motionProject | Out-Null
$motionPaths = @(& git -C $motionRoot ls-files --cached --others --exclude-standard -- game/feel/animation/fall_landing tests/beta_sprint/game_feel_owner_10a foundation/orientation/discrete_orientation.gd)
$motionSources = @($motionPaths | Sort-Object -Unique | ForEach-Object {
    $motionSource = Join-Path $motionRoot $_
    $motionDestination = Join-Path $motionProject $_
    New-Item -ItemType Directory -Force -Path (Split-Path -Parent $motionDestination) | Out-Null
    Copy-Item -LiteralPath $motionSource -Destination $motionDestination
    @{path=$_;sha256=(Get-FileHash -LiteralPath $motionSource).Hash.ToLowerInvariant()}
})
$motionName = 'PFALL_10A_' + [guid]::NewGuid().ToString('N')
$motionConfig = "config_version=5`n[application]`nconfig/name=`"$motionName`"`nconfig/use_custom_user_dir=true`nconfig/custom_user_dir_name=`"$motionName`"`n[display]`nwindow/size/viewport_width=1280`nwindow/size/viewport_height=800`n[rendering]`nrenderer/rendering_method=`"gl_compatibility`"`n"
[IO.File]::WriteAllText((Join-Path $motionProject 'project.godot'), $motionConfig, [Text.UTF8Encoding]::new($false))
$motionArgs = @('--path',('"'+$motionProject+'"'),'--script',"res://tests/beta_sprint/game_feel_owner_10a/$Mode.gd")
if ($Mode -eq 'unit') { $motionArgs += '--headless' }
$motionArgs += @('--',('--evidence-dir='+$motionOut))
$motionRecord = [ordered]@{head=(& git -C $motionRoot rev-parse HEAD).Trim();dirty=@(& git -C $motionRoot status --short);case=$Case;mode=$Mode;fixture_kind='PRESENTATION_CONTRACT_UNIT';authoritative_runtime=$false;doubles=@('01 DTO','Safety attestation','native commit');sources=$motionSources;project_name=$motionName;arguments=$motionArgs;engine_sha256=(Get-FileHash -LiteralPath $Godot).Hash.ToLowerInvariant();started=(Get-Date -Format o);status='RUNNING'}
function Save-MotionRecord { $motionRecord | ConvertTo-Json -Depth 12 | Set-Content -LiteralPath (Join-Path $motionOut 'process.json') -Encoding utf8 }
Save-MotionRecord
$motionProc = Start-Process -FilePath $Godot -ArgumentList $motionArgs -WindowStyle Hidden -RedirectStandardOutput (Join-Path $motionOut 'stdout.log') -RedirectStandardError (Join-Path $motionOut 'stderr.log') -PassThru
$motionRecord.pid = $motionProc.Id
Save-MotionRecord
if (-not $motionProc.WaitForExit(55000)) { $motionProc.Kill(); $motionRecord.status='TIMEOUT' }
$motionProc.WaitForExit()
$motionRecord.exit_code=$motionProc.ExitCode
$motionRecord.finished=Get-Date -Format o
$motionRecord.stderr=Get-Content -LiteralPath (Join-Path $motionOut 'stderr.log') -Raw
$motionRecord.source_changes=@($motionSources | Where-Object { (Get-FileHash -LiteralPath (Join-Path $motionRoot $_.path)).Hash.ToLowerInvariant() -ne $_.sha256 })
$motionReportPath=Join-Path $motionOut 'report.json'
$motionRecord.checks=0
$motionRecord.failures=@('missing report')
if (Test-Path -LiteralPath $motionReportPath) {
    $motionReport=Get-Content -LiteralPath $motionReportPath -Raw | ConvertFrom-Json
    $motionRecord.checks=$motionReport.checks
    $motionRecord.failures=@($motionReport.failures)
    $motionRecord.user_data_dir=$motionReport.user_data_dir
    $motionRecord.profile_isolated=$motionReport.user_data_dir.EndsWith($motionName)
}
$motionRecord.status=if($motionRecord.exit_code -eq 0 -and $motionRecord.checks -gt 0 -and -not $motionRecord.stderr -and $motionRecord.failures.Count -eq 0 -and $motionRecord.source_changes.Count -eq 0 -and $motionRecord.profile_isolated){'PASS'}else{'FAILED'}
Save-MotionRecord
Get-Content -LiteralPath (Join-Path $motionOut 'stdout.log')
if($motionRecord.stderr){Write-Output $motionRecord.stderr}
Write-Output "10A $Mode $Case status=$($motionRecord.status) checks=$($motionRecord.checks) exit=$($motionRecord.exit_code)"
if($motionRecord.status -ne 'PASS'){exit 1}
