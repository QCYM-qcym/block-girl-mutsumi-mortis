param(
    [ValidateSet('Unit', 'Baseline', 'Candidate', 'Real', 'Graphical')][string]$Mode = 'Unit',
    [string]$Case = '*',
    [string]$Bindings = 'res://docs/beta-sprint/game-feel/CORE_PLAYABLE_QUALITY_BINDINGS.json',
    [string]$Godot = 'D:/APP/steam/steamapps/common/Godot Engine/godot.windows.opt.tools.64.exe',
    [string]$Python = 'python',
    [string]$EvidenceName = ('quality_' + (Get-Date -Format 'yyyyMMdd_HHmmss'))
)
$ErrorActionPreference = 'Stop'
if ($EvidenceName -notmatch '^[a-zA-Z0-9_-]+$') { throw 'Use a simple, fresh evidence name.' }
$qualityProject = (Resolve-Path -LiteralPath (Join-Path $PSScriptRoot '../../..')).Path
$qualityEvidence = Join-Path $qualityProject ".godot/game-feel-quality/$EvidenceName"
if (Test-Path -LiteralPath $qualityEvidence) { throw 'Prior evidence is preserved; choose another name.' }
New-Item -ItemType Directory -Path $qualityEvidence | Out-Null
$qualityProfile = Join-Path $qualityEvidence 'profile'
$qualityRoaming = Join-Path $qualityProfile 'AppData/Roaming'
$qualityLocal = Join-Path $qualityProfile 'AppData/Local'
New-Item -ItemType Directory -Path $qualityRoaming, $qualityLocal | Out-Null
$qualityPython = (Get-Command $Python -ErrorAction Stop).Source
$qualityReport = [ordered]@{
    task = 'GAME_FEEL_INTEGRATION_QUALITY_01'; mode = $Mode
    head = (& git -C $qualityProject rev-parse HEAD)
    branch = (& git -C $qualityProject branch --show-current)
    dirty = @(& git -C $qualityProject status --porcelain=v1)
    contract_commit = '2938d6e534f5b596bb320ce79d72b69f5923f3cd'
    contract_sha256 = '6224f8cd364f98da41822eabe7ba2973fa2db01d030373e7b3e94d69f35f23de'
    started_utc = [DateTime]::UtcNow.ToString('o'); checks = 0; runs = @(); failures = @()
    matrix_cases = 0; integration_status = 'NOT_RUN'; graphical_status = 'NOT_RUN'
    cases = @(); profile = $qualityProfile
    not_run = @('Perspective Fall Real', 'Landing Real', 'Edge Recoil Real', 'all new graphical input stress',
        'new GLB/shader/VFX', '30-minute soak', 'animation phase frame time', 'contact audio/pause audio',
        'Reduced Motion', 'HUD resolutions', 'Fall-specific Solver/Replay/Safety',
        'L01-L05 graphical focused regression', 'L06 conditional integration')
    baseline_scope = 'Owner-local headless production API Unit; no game-feel Real/Graphical capability result'
    sources = @(); passed = $false
    doubles = @{synthetic_observations = 'PRESENTATION_CONTRACT_UNIT only'; baseline_algorithm_doubles = @()}
    known_failures = @()
    historical_known_issues = @(@{id = 'UI-08-001'; severity = 'P2'; status = 'OLD_13177BB_RECEIPT_NOT_RECHECKED'
        description = 'L02 Pause text invisible; mouse entry still operates'
        source = 'docs/beta-sprint/visual-integration-01/QA_HANDOFF_07_PAUSE_TEXT_2026-10-09.md'})
    owner_delivery_references = @{ '09' = @{ commit = '54ea24cd50c4bd45b083dc26487ff2b7afd2a703'; kind = 'AUTHOR_DATA_ONLY'; consumed_in_this_worktree = $false } }
}
function Save-QualityReport {
    $qualityReport | ConvertTo-Json -Depth 12 |
        Set-Content -LiteralPath (Join-Path $qualityEvidence 'execution.json') -Encoding utf8
}
function Invoke-QualityProcess([string]$Name, [string]$Executable, [string[]]$Arguments, [string]$Marker, [bool]$Unit = $false, [string]$Kind = 'LEGACY_PRODUCTION_MODULE_UNIT', [string[]]$Doubles = @(), [bool]$Observation = $false) {
    $stdout = Join-Path $qualityEvidence "$Name.stdout.log"
    $stderr = Join-Path $qualityEvidence "$Name.stderr.log"
    $process = $null
    try {
        $process = Start-Process -FilePath $Executable -ArgumentList $Arguments -WorkingDirectory $qualityProject `
            -WindowStyle Hidden -PassThru -RedirectStandardOutput $stdout -RedirectStandardError $stderr `
            -Environment @{ APPDATA = $qualityRoaming; LOCALAPPDATA = $qualityLocal }
        $timer = [Diagnostics.Stopwatch]::StartNew()
        while (-not $process.WaitForExit(1000)) {
            if ($timer.Elapsed.TotalSeconds -gt 120) { throw "$Name timed out" }
        }
        $process.WaitForExit()
        $outText = [string](Get-Content -LiteralPath $stdout -Raw)
        $errText = [string](Get-Content -LiteralPath $stderr -Raw)
        $text = if ($Unit) { $errText } else { $outText }
        $matched = [regex]::Match($text, $Marker)
        $checks = if ($matched.Success) { [int]$matched.Groups[1].Value } else { 0 }
        $passed = $process.ExitCode -eq 0 -and ($checks -gt 0 -or ($Observation -and $matched.Success))
        if ($Unit) { $passed = $passed -and $errText -match '(?m)^OK\r?$' -and $errText -notmatch 'FAILED|Traceback' }
        else { $passed = $passed -and [string]::IsNullOrWhiteSpace($errText) -and ($outText + $errText) -notmatch 'SCRIPT ERROR:|ERROR:|FAIL:' }
        if ($Unit) { $Kind = 'PRESENTATION_CONTRACT_UNIT'; $Doubles = @('synthetic_observations', 'synthetic_event_snapshot', 'synthetic_motion_sample') }
        $qualityReport.runs += [ordered]@{name = $Name; kind = $Kind
            authoritative_runtime = $(if ($Observation) { $null } else { $false }); doubles = $Doubles
            checks = $checks; passed = $(if ($Observation) { $null } else { $passed }); completed_without_error = $passed
            exit_code = $process.ExitCode; pid = $process.Id
            executable = $Executable; arguments = $Arguments; stdout = $stdout; stderr = $stderr}
        $qualityReport.checks += $checks
        Save-QualityReport
        if ($Observation) { Write-Output "$Name checks=$checks completed_without_error=$passed formal_result=NOT_RUN" }
        else { Write-Output "$Name checks=$checks passed=$passed" }
        if (-not $passed) { throw "$Name failed; inspect $stdout and $stderr" }
    } finally {
        if ($null -ne $process -and -not $process.HasExited) { $process.Kill(); $process.WaitForExit() }
    }
}
function Invoke-QualityGodot([string]$Name, [string]$Script, [string]$Marker, [string[]]$UserArguments = @(), [string]$Kind = 'LEGACY_PRODUCTION_MODULE_UNIT', [string[]]$Doubles = @()) {
    $arguments = @('--headless', '--path', ('"' + $qualityProject + '"'), '--script', $Script,
        '--', ('--evidence-dir="' + $qualityEvidence + '"'), ("--execution-head=" + $qualityReport.head)) + $UserArguments
    Invoke-QualityProcess $Name $Godot $arguments $Marker $false $Kind $Doubles
}
try {
    $contractPath = Join-Path $qualityProject 'docs/beta-sprint/game-feel/GAME_FEEL_CONTRACT.md'
    if ((Get-FileHash -LiteralPath $contractPath -Algorithm SHA256).Hash.ToLowerInvariant() -ne $qualityReport.contract_sha256) {
        throw 'CONTRACT_MISMATCH: shared contract differs from registered SHA'
    }
    & git -C $qualityProject merge-base --is-ancestor $qualityReport.contract_commit HEAD
    if ($LASTEXITCODE -ne 0) { throw 'Shared contract baseline is not an ancestor of actual HEAD' }
    $sourceRoots = @('foundation', 'prototype/perspective', 'game/levels/mutsumi/batch_01',
        'game/levels/mutsumi/batch_02', 'production/audio/p01', 'tests/beta_sprint/game_feel', 'tests/beta_sprint/game_feel_owner_03', 'tests/foundation/solver',
        'tests/foundation/parity', 'tests/foundation/kernel_safety', 'tests/foundation/rules', 'tests/foundation/validation',
        'game/polish/p01_audio.gd', 'game/shell/settings.gd', 'game/shell/save_store.gd', 'project.godot', 'default_bus_layout.tres',
        'docs/beta-sprint/game-feel', 'docs/beta-sprint/game-feel-owner-03', 'game/feel', 'experiments/game_feel_01')
    foreach ($relative in $sourceRoots) {
        if (-not (Test-Path -LiteralPath (Join-Path $qualityProject $relative))) { continue }
        Get-ChildItem -LiteralPath (Join-Path $qualityProject $relative) -Recurse -File |
            Where-Object { $_.FullName -notmatch '[\\/]__pycache__[\\/]' } | Sort-Object FullName | ForEach-Object {
                $qualityReport.sources += [ordered]@{path = $_.FullName.Substring($qualityProject.Length + 1).Replace('\', '/')
                    sha256 = (Get-FileHash -LiteralPath $_.FullName -Algorithm SHA256).Hash.ToLowerInvariant()}
            }
    }
    if ($Mode -in @('Unit', 'Baseline')) {
        Invoke-QualityProcess 'prepared_assertions' $qualityPython @('-m', 'unittest', 'discover', '-s', 'tests/beta_sprint/game_feel', '-p', 'test_*.py') '(?m)^Ran ([1-9][0-9]*) tests? ' $true
    }
    & $qualityPython (Join-Path $PSScriptRoot 'matrix.py') --output (Join-Path $qualityEvidence 'matrix.json')
    if ($LASTEXITCODE -ne 0) { throw 'Matrix generation failed' }
    $matrix = Get-Content -LiteralPath (Join-Path $qualityEvidence 'matrix.json') -Raw | ConvertFrom-Json
    $qualityReport.matrix_cases = @($matrix.cases).Count
    if ($qualityReport.matrix_cases -eq 0 -or @($matrix.cases | Where-Object status -ne 'case_pending').Count -gt 0) {
        throw 'Prepared cases cannot claim a real integration result'
    }
    # Only cases with missing actual deliveries stay pending. No aggregate
    # dependency barrier prevents the independent Unit/API work above/below.
    $selected = @($matrix.cases | Where-Object { $_.id -like $Case })
    if ($selected.Count -eq 0) { throw "Unknown case selection: $Case" }
    foreach ($row in $selected) {
        $qualityReport.cases += [ordered]@{id = $row.id; area = $row.area; mode = $row.mode
            status = 'case_pending'; checks = 0; failures = @(); execution_head = $null
            source_sha = $null; delivery_sha = $null; doubles = @(); authoritative_runtime = $null
            missing = $row.dependencies; reason = 'Formal case dependency receipts/capture binding not delivered'
            natural_success = $null}
    }
    if ($Mode -eq 'Candidate') {
        if ($selected.Count -ne 1 -or $selected[0].scope -ne 'CORE_PLAYABLE') { throw 'Candidate mode requires one exact CORE case.' }
        if (-not (Test-Path -LiteralPath $Godot)) { throw 'Godot executable not found' }
        $candidateArguments = @('--path', ('"' + $qualityProject + '"'), '--script',
            'res://tests/beta_sprint/game_feel_owner_03/test_core_playable.gd', '--max-fps', '60', '--',
            ('--evidence-dir="' + $qualityEvidence + '"'), ('--execution-head=' + $qualityReport.head),
            ('--case=' + $selected[0].id), ('--bindings=' + $Bindings))
        Invoke-QualityProcess 'core_candidate' $Godot $candidateArguments 'GAME_FEEL_CORE_CASE status=(?:OBSERVATIONS_RECORDED|case_pending) checks=([0-9]+) failures=\[\]' $false 'REAL_CORE_CANDIDATE_OBSERVATIONS' @() $true
        $observed = Get-Content -LiteralPath (Join-Path $qualityEvidence ($selected[0].id + '.json')) -Raw | ConvertFrom-Json
        if ($observed.capture.display -eq 'headless' -and $observed.checks -gt 0) { throw 'Candidate cannot use a headless presenter loop' }
        if (-not $observed.capture.user_data_dir.StartsWith($qualityProfile.Replace('\', '/'), [StringComparison]::OrdinalIgnoreCase)) { throw 'Candidate escaped isolated profile' }
        $qualityReport.cases[0] = $observed
        $qualityReport.candidate_status = $observed.status
        $qualityReport.evidence_role = 'PHASE_EVIDENCE_ONLY'
    }
    if ($Mode -eq 'Baseline') {
        if (-not (Test-Path -LiteralPath $Godot)) { throw 'Godot executable not found' }
        $solverCommit = 'f34dd271adabcc4b724eb55b5fff1cb35f532e59'
        $solverPaths = @(& git -C $qualityProject ls-tree -r --name-only $solverCommit -- foundation/solver)
        $solverReady = $LASTEXITCODE -eq 0 -and $solverPaths.Count -eq 14
        $solverDifferences = @()
        foreach ($solverPath in $solverPaths) {
            $expectedBlob = & git -C $qualityProject rev-parse ($solverCommit + ':' + $solverPath)
            if ($LASTEXITCODE -ne 0) { $solverReady = $false; $solverDifferences += $solverPath; continue }
            $actualBlob = & git -C $qualityProject hash-object --path=$solverPath (Join-Path $qualityProject $solverPath)
            if ($LASTEXITCODE -ne 0 -or $actualBlob -ne $expectedBlob) { $solverReady = $false; $solverDifferences += $solverPath }
        }
        $qualityReport.solver_dependency = @{commit = $solverCommit; status = $(if ($solverReady) { 'VERIFIED' } else { 'case_pending' })
            verified_blobs = $(if ($solverReady) { $solverPaths.Count } else { 0 }); differing_paths = $solverDifferences}
        # Fresh import is an explicit prerequisite; the runner does not silently
        # rewrite source/import settings or accept importer errors as test success.
        Invoke-QualityGodot 'core_assertions' 'res://tests/beta_sprint/game_feel_owner_03/test_core_assertions.gd' 'GAME_FEEL_CORE_ASSERTIONS checks=([1-9][0-9]*) failures=\[\]' @() 'PRESENTATION_CONTRACT_UNIT' @('synthetic_trajectory', 'synthetic_native_refusal_snapshot')
        Invoke-QualityGodot 'native_roll' 'res://tests/beta_sprint/game_feel_owner_03/test_native_roll.gd' 'GAME_FEEL_NATIVE_ROLL checks=([1-9][0-9]*) failures=\[\]'
        Invoke-QualityGodot 'audio_baseline' 'res://tests/beta_sprint/game_feel_owner_03/test_audio_baseline.gd' 'GAME_FEEL_AUDIO_BASELINE checks=([1-9][0-9]*) failures=\[\]'
        $save = "--shell-save=user://game_feel_quality/$EvidenceName/settings.json"
        foreach ($phase in @('seed', 'restore')) {
            Invoke-QualityGodot "settings_$phase" 'res://tests/beta_sprint/game_feel_owner_03/test_settings_process.gd' "GAME_FEEL_SETTINGS_$($phase.ToUpperInvariant()) checks=([1-9][0-9]*) failures=\[\]" @("--phase=$phase", $save)
        }
        $seed = Get-Content -LiteralPath (Join-Path $qualityEvidence 'settings_seed.json') -Raw | ConvertFrom-Json
        $restore = Get-Content -LiteralPath (Join-Path $qualityEvidence 'settings_restore.json') -Raw | ConvertFrom-Json
        if ($seed.pid -eq $restore.pid -or $seed.save_absolute -ne $restore.save_absolute -or $seed.save_sha256 -ne $restore.save_sha256) {
            throw 'Settings restoration must use separate processes and the same unchanged isolated save'
        }
        $qualityReport.settings_processes = [ordered]@{seed_pid = $seed.pid; restore_pid = $restore.pid; save = $seed.save_absolute; sha256 = $seed.save_sha256}
        foreach ($captureFile in @('native_roll.json', 'audio_baseline.json', 'settings_seed.json', 'settings_restore.json')) {
            $capture = (Get-Content -LiteralPath (Join-Path $qualityEvidence $captureFile) -Raw | ConvertFrom-Json).capture
            if (-not $capture.user_data_dir.StartsWith($qualityProfile.Replace('\', '/'), [StringComparison]::OrdinalIgnoreCase)) {
                throw "OS user data escaped isolated profile: $captureFile"
            }
        }
        Invoke-QualityGodot 'kernel_safety' 'res://tests/foundation/kernel_safety/test_kernel_safety.gd' 'KERNEL_SAFETY_INTEGRATION checks=([1-9][0-9]*) failures=\[\]'
        # This script directly calls formal BFSSolver.solve, validate_semantics,
        # TraceReplayer.replay and RuntimeSession. Do not substitute the older
        # test_trace_replayer.gd: it contains a tests-only Trace double.
        if ($solverReady) {
            Invoke-QualityGodot 'formal_solver_replay' 'res://tests/foundation/parity/test_solver_trace_integration.gd' 'FOUNDATION_PARITY_REAL_TRACE_LOGICAL_PASS checks=([1-9][0-9]*)'
            $trace = Get-Content -LiteralPath (Join-Path $qualityEvidence 'real_trace_logical.json') -Raw | ConvertFrom-Json
            if ($trace.checks -le 0 -or @($trace.failures).Count -ne 0 -or
                $trace.trace_source -ne 'formal BFSSolver.solve' -or $trace.trace_semantics -ne 'formal SolutionTrace.validate_semantics') {
                throw 'Missing formal Solver / semantic validation / Runtime replay evidence'
            }
        } else {
            # Only this exact legacy control waits for its verified version.
            # A different source is never relabelled as the old Solver delivery.
            $qualityReport.runs += @{name='formal_solver_replay';status='case_pending';checks=0;passed=$null
                source_sha=$null;delivery_sha=$null;doubles=@();authoritative_runtime=$null;missing=@('EXACT_FORMAL_LEGACY_SOLVER_VERSION')}
        }
    }
    foreach ($source in $qualityReport.sources) {
        if ((Get-FileHash -LiteralPath (Join-Path $qualityProject $source.path) -Algorithm SHA256).Hash.ToLowerInvariant() -ne $source.sha256) {
            throw "Source changed during validation: $($source.path)"
        }
    }
    $qualityReport.passed = $Mode -in @('Unit', 'Baseline')
    $qualityReport.finished_utc = [DateTime]::UtcNow.ToString('o')
    Save-QualityReport
    if ($qualityReport.passed) {
        Write-Output "GAME_FEEL_TEST_PREPARATION_CHECKS_PASS mode=$Mode checks=$($qualityReport.checks) matrix=$($qualityReport.matrix_cases) evidence=$qualityEvidence"
    } elseif ($Mode -eq 'Candidate') { Write-Output "GAME_FEEL_CANDIDATE status=$($qualityReport.candidate_status) checks=$($qualityReport.checks) evidence=$qualityEvidence" }
    else { Write-Output "GAME_FEEL_CASE_PENDING mode=$Mode checks=0 cases=$($selected.Count) evidence=$qualityEvidence" }
    Write-Output 'REAL_GAME_FEEL_INTEGRATION: NOT_RUN'
} catch {
    $qualityReport.failures += $_.Exception.Message
    $qualityReport.finished_utc = [DateTime]::UtcNow.ToString('o')
    Save-QualityReport
    throw
}
