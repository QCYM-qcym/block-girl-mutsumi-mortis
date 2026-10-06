param(
    [string]$Godot = 'D:/APP/steam/steamapps/common/Godot Engine/godot.windows.opt.tools.64.exe',
    [string]$EvidenceName = ('daily_' + (Get-Date -Format 'yyyyMMdd_HHmmss')),
    [ValidateRange(10,300)][int]$TimeoutSeconds = 120
)
$ErrorActionPreference = 'Stop'
if ($EvidenceName -notmatch '^[a-zA-Z0-9_-]+$') { throw 'Use a simple, fresh evidence name.' }
$betaProject = (Resolve-Path -LiteralPath (Join-Path $PSScriptRoot '../..')).Path
$betaEvidence = Join-Path $betaProject ".godot/beta-sprint/$EvidenceName"
if (Test-Path -LiteralPath $betaEvidence) { throw 'Prior evidence is immutable; choose a fresh EvidenceName.' }
New-Item -ItemType Directory -Path $betaEvidence -Force | Out-Null
$betaStages = [Collections.Generic.List[object]]::new()
function Invoke-BetaStage([string]$Name, [string[]]$Arguments, [string]$Marker = '', [string]$RequiredFile = '') {
    $betaOut = Join-Path $betaEvidence "$Name.stdout.log"
    $betaErr = Join-Path $betaEvidence "$Name.stderr.log"
    $betaRow = [ordered]@{ name=$Name; status='PENDING'; pid=$null; exit_code=$null; timed_out=$false; stdout=$betaOut; stderr=$betaErr; reason=''; command_arguments=$Arguments }
    if (-not (Test-Path -LiteralPath $Godot)) { $betaRow.reason='Godot executable missing'; $betaStages.Add([pscustomobject]$betaRow); return }
    if ($RequiredFile -and -not (Test-Path -LiteralPath (Join-Path $betaProject $RequiredFile))) { $betaRow.reason="Required dependency missing: $RequiredFile"; $betaStages.Add([pscustomobject]$betaRow); return }
    $betaChild = $null
    try {
        $betaChild = Start-Process -FilePath $Godot -ArgumentList (@('--path',('"'+$betaProject+'"')) + $Arguments) -WindowStyle Hidden -PassThru -RedirectStandardOutput $betaOut -RedirectStandardError $betaErr
        $betaRow.pid=$betaChild.Id
        if (-not $betaChild.WaitForExit($TimeoutSeconds * 1000)) { $betaRow.timed_out=$true; $betaChild.Kill(); $betaChild.WaitForExit() }
        $betaChild.WaitForExit()
        $betaRow.exit_code=$betaChild.ExitCode
        $betaText = (Get-Content -LiteralPath $betaOut -Raw) + (Get-Content -LiteralPath $betaErr -Raw)
        $betaRow.status = if (-not $betaRow.timed_out -and $betaChild.ExitCode -eq 0 -and $betaText -notmatch 'SCRIPT ERROR:|ERROR:|FAIL:' -and (-not $Marker -or $betaText -match $Marker)) { 'PASS' } else { 'FAIL' }
        if ($betaRow.status -eq 'FAIL') { $betaRow.reason='Timeout, nonzero exit, logged error, or required success marker absent; inspect preserved logs.' }
    } catch { $betaRow.status='FAIL'; $betaRow.reason=$_.Exception.Message }
    finally { if ($null -ne $betaChild -and -not $betaChild.HasExited) { $betaChild.Kill(); $betaChild.WaitForExit() } }
    $betaStages.Add([pscustomobject]$betaRow)
    Write-Output "$Name $($betaRow.status) exit=$($betaRow.exit_code)"
}
Invoke-BetaStage 'import' @('--headless','--editor','--import')
Invoke-BetaStage 'boot' @('--max-fps','60','--quit-after','120') '' 'game/levels/mutsumi/p01_another_world.tscn'
Invoke-BetaStage 'p01_state' @('--headless','--script','res://tests/gameplay/test_p01_state.gd') 'P01 STATE: [1-9][0-9]* checks' 'tests/gameplay/test_p01_state.gd'
$betaRuntime = Join-Path $betaEvidence 'p01_runtime'
New-Item -ItemType Directory -Path $betaRuntime | Out-Null
Invoke-BetaStage 'p01_runtime' @('--max-fps','60','--script','res://tests/gameplay/test_p01_runtime.gd','--',('--evidence-dir="'+$betaRuntime+'"')) 'P01 RUNTIME: [1-9][0-9]* checks' 'tests/gameplay/test_p01_runtime.gd'
$betaRestart = Join-Path $betaEvidence 'p01_restart'
New-Item -ItemType Directory -Path $betaRestart | Out-Null
Invoke-BetaStage 'p01_restart' @('--max-fps','60','--script','res://tests/gameplay/test_p01_runtime.gd','--',('--evidence-dir="'+$betaRestart+'"')) 'P01 RUNTIME: [1-9][0-9]* checks' 'tests/gameplay/test_p01_runtime.gd'
$betaIntegrated = Join-Path $betaEvidence 'foundation_runtime'
New-Item -ItemType Directory -Path $betaIntegrated | Out-Null
Invoke-BetaStage 'foundation_runtime' @('--max-fps','60','--script','res://tests/foundation/full_integration/test_full_integration.gd','--',('--evidence-dir="'+$betaIntegrated+'"')) 'FOUNDATION_2_E2E_PASS checks=[1-9][0-9]*' 'tests/foundation/full_integration/test_full_integration.gd'
foreach ($betaPair in @(@('p01_runtime',(Join-Path $betaRuntime 'runtime_report.json')),@('p01_restart',(Join-Path $betaRestart 'runtime_report.json')),@('foundation_runtime',(Join-Path $betaIntegrated 'results.json')))) {
    $betaStage = $betaStages | Where-Object name -EQ $betaPair[0]
    if ($betaStage.status -eq 'PASS') {
        try {
            $betaReport = Get-Content -LiteralPath $betaPair[1] -Raw | ConvertFrom-Json
            if ($betaReport.checks -le 0 -or $betaReport.failures.Count -ne 0 -or $betaReport.display -eq 'headless') { throw 'Invalid graphical result report.' }
            $betaStage | Add-Member -NotePropertyName checks -NotePropertyValue $betaReport.checks
            $betaStage | Add-Member -NotePropertyName display -NotePropertyValue $betaReport.display
            if ($betaPair[0] -eq 'p01_restart') {
                $betaInitial = @($betaReport.checkpoints | Where-Object name -EQ '01_start')
                $betaPrior = $betaStages | Where-Object name -EQ 'p01_runtime'
                if ($betaInitial.Count -ne 1 -or $betaInitial[0].cell -ne '(0, 5)' -or $betaInitial[0].world -ne 0 -or $betaInitial[0].view -ne 0 -or $betaInitial[0].complete -or $betaInitial[0].door -or $betaStage.pid -eq $betaPrior.pid) { throw 'Independent process restart did not prove initial spawn/world/view/goal/door state.' }
                $betaStage | Add-Member -NotePropertyName initial_checkpoint -NotePropertyValue $betaInitial[0]
                $betaStage | Add-Member -NotePropertyName previous_pid -NotePropertyValue $betaPrior.pid
            }
        } catch { $betaStage.status='FAIL'; $betaStage.reason=$_.Exception.Message }
    }
}
function Get-BetaCoverageStatus([string[]]$Names) {
    $betaSelected = @($betaStages | Where-Object { $_.name -in $Names })
    if (@($betaSelected | Where-Object status -EQ 'FAIL').Count) { return 'FAIL' }
    if ($betaSelected.Count -ne $Names.Count -or @($betaSelected | Where-Object status -NE 'PASS').Count) { return 'UNVERIFIED' }
    return 'PASS'
}
$betaCoverage = @(
    @{ item='BOOT'; status=(Get-BetaCoverageStatus @('boot')); evidence='Actual default main scene rendered for 120 frames; no application interaction claim.' },
    @{ item='LEVEL LOAD'; status=(Get-BetaCoverageStatus @('p01_runtime','foundation_runtime')); evidence='P01 scene instantiated; real Foundation runtime baked and loaded with default owner dependencies.' },
    @{ item='MOVE'; status=(Get-BetaCoverageStatus @('p01_runtime','foundation_runtime')); evidence='P01 held/tapped movement and real Foundation MOVE physical input / committed StateKey.' },
    @{ item='ROTATE'; status=(Get-BetaCoverageStatus @('p01_runtime','foundation_runtime')); evidence='P01 keyboard/mouse perspective rotation; Foundation real world rotation.' },
    @{ item='WORLD SHIFT'; status=(Get-BetaCoverageStatus @('p01_runtime','foundation_runtime')); evidence='Actual Shift success and rejected Shift in P01 and real Foundation runtime.' },
    @{ item='RESET'; status=(Get-BetaCoverageStatus @('p01_runtime','foundation_runtime')); evidence='R reset after completion and during transitions; Foundation authoritative state reconstructed.' },
    @{ item='GOAL'; status=(Get-BetaCoverageStatus @('p01_state','p01_runtime','foundation_runtime')); evidence='P01 two complete routes; Foundation real Goal evaluator at baked exit.' },
    @{ item='RESTART'; status=(Get-BetaCoverageStatus @('p01_runtime','p01_restart')); evidence='Two sequential independent Godot runtime processes with distinct PIDs. Second initial checkpoint asserts spawn (0,5), world=0, view=0, goal=false and door=false, then completes real keyboard/mouse playthroughs. This proves process restart; no Shell Restart-menu UI claim.' },
    @{ item='ERROR CHECK'; status=(Get-BetaCoverageStatus @('import','boot','p01_state','p01_runtime','p01_restart','foundation_runtime')); evidence='Exit codes, timeouts, stdout/stderr error scan, positive markers and graphical JSON failures checked for this focused run only.' }
)
$betaOverall = if (@($betaStages | Where-Object status -EQ 'FAIL').Count) { 'FAILED' } elseif (@($betaStages | Where-Object status -EQ 'PENDING').Count) { 'PENDING' } else { 'PASS' }
$betaHead = & git -C $betaProject rev-parse HEAD
$betaSummary = [ordered]@{ created_at=(Get-Date -Format o); project=$betaProject; head=$betaHead; source_branch=(& git -C $betaProject branch --show-current); source_status=@(& git -C $betaProject status --porcelain); godot=$Godot; engine_sha256=$(if(Test-Path -LiteralPath $Godot){(Get-FileHash -LiteralPath $Godot -Algorithm SHA256).Hash.ToLowerInvariant()}else{$null}); scope='Focused daily smoke only; no historical full regression; input injected through Godot, not an OS input test. Run graphical smoke/build sequentially to avoid window focus interference.'; overall=$betaOverall; stages=@($betaStages.ToArray()); coverage=$betaCoverage }
$betaSummary | ConvertTo-Json -Depth 8 | Set-Content -LiteralPath (Join-Path $betaEvidence 'smoke-summary.json') -Encoding utf8
$betaCoverage | ForEach-Object { Write-Output "$($_.item): $($_.status)" }
Write-Output "Evidence: $betaEvidence; overall=$betaOverall"
if ($betaOverall -eq 'FAILED') { exit 1 }
if ($betaOverall -eq 'PENDING') { exit 2 }
# Exit zero means every required focused assertion and independent process restart passed.
exit 0
