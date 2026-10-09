param(
    [string]$Godot = 'D:/APP/steam/steamapps/common/Godot Engine/godot.windows.opt.tools.64.exe',
    [string]$EvidenceName = ('shell_b02_' + (Get-Date -Format 'yyyyMMdd_HHmmss') + '_' + [guid]::NewGuid().ToString('N').Substring(0,8)),
    [string[]]$Cases = @('catalog','save_compat','menu_capacity','runtime_seed','runtime_restore'),
    [string]$LegacySave = '',
    [string]$LegacyProvenance = '',
    [string]$RuntimeAudioDriver = 'WASAPI',
    [switch]$Import
)
$ErrorActionPreference = 'Stop'
if ($EvidenceName -notmatch '^[a-zA-Z0-9_-]+$') { throw 'Use a fresh simple evidence name.' }
$batch02Project = (Resolve-Path -LiteralPath (Join-Path $PSScriptRoot '../../..')).Path
$batch02Evidence = Join-Path $batch02Project ".godot/beta-sprint/shell-batch-02/$EvidenceName"
if (Test-Path -LiteralPath $batch02Evidence) { throw 'Never overwrite previous evidence.' }
$batch02Scripts = @{catalog='res://tests/beta_sprint/test_beta_catalog.gd'; save_compat='res://tests/beta_sprint/shell_batch_02/test_save_compat.gd'; menu_capacity='res://tests/beta_sprint/shell_batch_02/test_menu_capacity.gd'; runtime_seed='res://tests/beta_sprint/shell_batch_02/test_real_runtime.gd'; runtime_restore='res://tests/beta_sprint/shell_batch_02/test_real_runtime.gd'; legacy_restore='res://tests/beta_sprint/shell_batch_02/test_real_runtime.gd'}
if ('legacy_restore' -in $Cases -and ('save_compat' -notin $Cases -or -not $LegacySave)) { throw 'Legacy Continue requires the earlier save_compat copy stage and explicit inactive legacy source.' }
foreach ($batch02Case in $Cases) { if (-not $batch02Scripts.ContainsKey($batch02Case)) { throw "Unknown case: $batch02Case" } }
New-Item -ItemType Directory -Path $batch02Evidence -Force | Out-Null
$batch02Records = [Collections.Generic.List[object]]::new()
$batch02Sources = @('project.godot','default_bus_layout.tres','tests/playtest/test_batch_01_runtime.gd','tests/beta_sprint/test_beta_catalog.gd','tests/beta_sprint/test_content_shell.gd')
foreach ($batch02SourceDir in @('game/shell','game/levels/mutsumi','game/player','game/polish','prototype/perspective','tests/shell')) {
    $batch02Sources += @(Get-ChildItem -LiteralPath (Join-Path $batch02Project $batch02SourceDir) -File -Recurse | Where-Object { $_.Extension -in @('.gd','.gdshader','.json','.tscn','.tres','.uid') } | ForEach-Object { $_.FullName.Substring($batch02Project.Length + 1).Replace('\','/') })
}
$batch02Sources += @(Get-ChildItem -LiteralPath $PSScriptRoot -File | ForEach-Object { 'tests/beta_sprint/shell_batch_02/' + $_.Name })
$batch02SourceHashes = @($batch02Sources | Sort-Object -Unique | ForEach-Object { [ordered]@{path=$_; sha256=(Get-FileHash -LiteralPath (Join-Path $batch02Project $_)).Hash.ToLowerInvariant()} })
$batch02Summary = [ordered]@{head=(& git -C $batch02Project rev-parse HEAD).Trim(); branch=(& git -C $batch02Project branch --show-current).Trim(); evidence_type='OWNER_HEADLESS_ONLY'; human_acceptance='NOT_RUN'; source_files=$batch02SourceHashes; status='RUNNING'; stages=@(); pending=@(); frozen_import_restored=$false}
function Save-Batch02Summary {
    $batch02Summary.stages = @($batch02Records.ToArray())
    [IO.File]::WriteAllText((Join-Path $batch02Evidence 'run_report.json'), ($batch02Summary | ConvertTo-Json -Depth 12).Replace("`r`n","`n") + "`n", [Text.UTF8Encoding]::new($false))
}
function Invoke-Batch02Stage([string]$Name, [string[]]$StageArgs) {
    $batch02Out = Join-Path $batch02Evidence "$Name.stdout.log"
    $batch02Err = Join-Path $batch02Evidence "$Name.stderr.log"
    $batch02Record = [ordered]@{name=$Name; args=@('--headless') + $StageArgs; exit_code=$null; stdout=$batch02Out; stderr=$batch02Err; status='RUNNING'}
    $batch02Records.Add($batch02Record)
    Save-Batch02Summary
    $batch02Process = Start-Process -FilePath $Godot -ArgumentList (@('--headless','--path',('"' + $batch02Project + '"')) + $StageArgs) -WindowStyle Hidden -PassThru -RedirectStandardOutput $batch02Out -RedirectStandardError $batch02Err
    if (-not $batch02Process.WaitForExit(180000)) { $batch02Process.Kill(); $batch02Process.WaitForExit(); $batch02Record.status='TIMEOUT'; Save-Batch02Summary; throw "$Name timed out (own PID only)" }
    $batch02Process.WaitForExit()
    $batch02Record.exit_code = $batch02Process.ExitCode
    $batch02Error = Get-Content -LiteralPath $batch02Err -Raw
    $batch02Output = Get-Content -LiteralPath $batch02Out -Raw
    $batch02Record.stderr_bytes = (Get-Item -LiteralPath $batch02Err).Length
    $batch02KnownSvg = @("ERROR: ImageLoaderSVG: Couldn't set target on ThorVG canvas, error code 1.","ERROR: Error loading image: 'res://production/ui/beta_shell_01/icons_source.svg'.","ERROR: Error importing 'res://production/ui/beta_shell_01/icons_source.svg'.")
    $batch02ErrorLines = @($batch02Error -split '\r?\n' | Where-Object { $_ -match '^\s*(ERROR:|SCRIPT ERROR:|WARNING:|FAIL:)' })
    if ($Name -eq 'import' -and $batch02Process.ExitCode -eq 0 -and $batch02Output -notmatch 'SCRIPT ERROR:|ERROR:|FAIL:' -and ($batch02ErrorLines -join "`n") -eq ($batch02KnownSvg -join "`n")) {
        $batch02Record.status='P2_KNOWN_FROZEN_DEFS_SVG_INITIAL_IMPORT'
    } elseif ($batch02Process.ExitCode -ne 0 -or -not [string]::IsNullOrWhiteSpace($batch02Error) -or $batch02Output -match 'SCRIPT ERROR:|ERROR:|FAIL:') {
        $batch02Record.status='FAIL'
        Save-Batch02Summary
        throw "$Name failed: $batch02Err"
    } else { $batch02Record.status='PASS' }
    Save-Batch02Summary
    Write-Output "$Name : $($batch02Record.status); exit=$($batch02Record.exit_code); stderr_bytes=$($batch02Record.stderr_bytes)"
}
try {
    if ($Import) {
        $batch02FrozenImport = Join-Path $batch02Project 'production/ui/beta_shell_01/icons_source.svg.import'
        $batch02FrozenBytes = [IO.File]::ReadAllBytes($batch02FrozenImport)
        try { Invoke-Batch02Stage 'import' @('--editor','--import') }
        finally { [IO.File]::WriteAllBytes($batch02FrozenImport,$batch02FrozenBytes); $batch02Summary.frozen_import_restored=$true; Save-Batch02Summary }
    }
    foreach ($batch02Case in $Cases) {
        $batch02CaseEvidence = Join-Path $batch02Evidence $batch02Case
        New-Item -ItemType Directory -Path $batch02CaseEvidence -Force | Out-Null
        $batch02Save = "user://beta_sprint/$EvidenceName/$batch02Case.json"
        $batch02ExtraArgs = @()
        if ($batch02Case -like 'runtime_*') { $batch02Save="user://beta_sprint/$EvidenceName/runtime_progress.json"; $batch02ExtraArgs += ('--phase=' + $batch02Case.Substring(8)) }
        if ($batch02Case -eq 'legacy_restore') { $batch02Save="user://beta_sprint/$EvidenceName/save_compat.actual-copy.json"; $batch02ExtraArgs += '--phase=legacy_restore' }
        if ($batch02Case -eq 'save_compat' -and $LegacySave) { $batch02ExtraArgs += ('--legacy-save="' + $LegacySave + '"'); $batch02ExtraArgs += ('--legacy-provenance="' + $LegacyProvenance + '"') }
        $batch02IsRuntime = $batch02Case -like 'runtime_*' -or $batch02Case -eq 'legacy_restore'
        $batch02EngineArgs = if ($batch02IsRuntime) { @('--audio-driver',$RuntimeAudioDriver) } else { @() }
        Invoke-Batch02Stage $batch02Case ($batch02EngineArgs + @('--script',$batch02Scripts[$batch02Case],'--',"--shell-save=$batch02Save",('--evidence-dir="'+$batch02CaseEvidence+'"'),"--head=$($batch02Summary.head)") + $batch02ExtraArgs)
        if ($batch02Case -eq 'catalog') {
            $batch02JsonLine = @(Get-Content -LiteralPath (Join-Path $batch02Evidence 'catalog.stdout.log') | Where-Object { $_.StartsWith('{') })[-1]
            $batch02CaseReport = $batch02JsonLine | ConvertFrom-Json
        } else { $batch02ReportName = if ($batch02IsRuntime) { 'real_runtime_report.json' } else { $batch02Case + '_report.json' }; $batch02CaseReport = Get-Content -LiteralPath (Join-Path $batch02CaseEvidence $batch02ReportName) -Raw | ConvertFrom-Json }
        if ($batch02CaseReport.checks -le 0 -or $batch02CaseReport.failures.Count -ne 0) { throw "$batch02Case did not report positive passing checks." }
        $batch02Records[$batch02Records.Count - 1].checks=$batch02CaseReport.checks
        $batch02Records[$batch02Records.Count - 1].pending=@($batch02CaseReport.pending)
        $batch02Summary.pending += @($batch02CaseReport.pending | Where-Object { $_ })
        if ($batch02IsRuntime) { $batch02Records[$batch02Records.Count - 1].pid=$batch02CaseReport.pid; $batch02Records[$batch02Records.Count - 1].save_path=$batch02CaseReport.save_path }
        Write-Output "OWNER $batch02Case : $($batch02CaseReport.checks) checks; Human NOT_RUN"
    }
    foreach ($batch02Source in $batch02SourceHashes) { if ((Get-FileHash -LiteralPath (Join-Path $batch02Project $batch02Source.path)).Hash.ToLowerInvariant() -ne $batch02Source.sha256) { throw "Source changed during test: $($batch02Source.path)" } }
    if ('runtime_seed' -in $Cases -and 'runtime_restore' -in $Cases) {
        $batch02Seed = @($batch02Records | Where-Object { $_.name -eq 'runtime_seed' })[0]
        $batch02Restore = @($batch02Records | Where-Object { $_.name -eq 'runtime_restore' })[0]
        if ($batch02Seed.pid -eq $batch02Restore.pid -or $batch02Seed.save_path -ne $batch02Restore.save_path) { throw 'Runtime Continue must use distinct OS processes and the same isolated save.' }
    }
    $batch02Summary.status=if ($batch02Summary.pending.Count) { 'PASS_WITH_PENDING' } else { 'PASS' }
    Save-Batch02Summary
    Write-Output "BATCH02_OWNER_HEADLESS_PASS: $batch02Evidence"
} catch { $batch02Summary.status='FAIL'; $batch02Summary.failure=$_.Exception.Message; Save-Batch02Summary; throw }
