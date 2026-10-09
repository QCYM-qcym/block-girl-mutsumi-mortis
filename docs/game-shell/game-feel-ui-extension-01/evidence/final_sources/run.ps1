param(
    [string]$Godot = 'D:/APP/steam/steamapps/common/Godot Engine/godot.windows.opt.tools.64.exe',
    [string]$EvidenceName = ('owner07_' + (Get-Date -Format 'yyyyMMdd_HHmmss') + '_' + [guid]::NewGuid().ToString('N').Substring(0,8)),
    [string[]]$Cases = @('baseline_save','baseline_flow','seed','restore','layout'),
    [switch]$Import
)
$ErrorActionPreference = 'Stop'
if ($Cases.Count -eq 0) { throw 'Select at least one behavioral case; an import-only run cannot be PASS' }
if ($EvidenceName -notmatch '^[a-zA-Z0-9_-]+$') { throw 'Use a fresh simple evidence name' }
$uiOwnerRoot = (Resolve-Path -LiteralPath (Join-Path $PSScriptRoot '../../..')).Path
$uiOwnerEvidence = Join-Path $uiOwnerRoot ".godot/game-feel-ui/$EvidenceName"
if (Test-Path -LiteralPath $uiOwnerEvidence) { throw 'Evidence is append-only; use a fresh name' }
New-Item -ItemType Directory -Path $uiOwnerEvidence | Out-Null
$uiOwnerProfile = Join-Path $uiOwnerEvidence 'profile'
New-Item -ItemType Directory -Path $uiOwnerProfile | Out-Null
$uiOwnerFiles = @(git -C $uiOwnerRoot ls-files --cached --others --exclude-standard -- game/feel/ui game/shell production/ui/beta_shell_01 tests/shell tests/beta_sprint/game_feel_owner_07 docs/beta-sprint/game-feel/GAME_FEEL_CONTRACT.md)
$uiOwnerHashes = @($uiOwnerFiles | Sort-Object -Unique | ForEach-Object { [ordered]@{path=$_;sha256=(Get-FileHash -LiteralPath (Join-Path $uiOwnerRoot $_)).Hash.ToLowerInvariant()} })
$uiOwnerStages = [Collections.Generic.List[object]]::new()
$uiOwnerSummary = [ordered]@{head=(git -C $uiOwnerRoot rev-parse HEAD).Trim();dirty=@(git -C $uiOwnerRoot status --porcelain);status='RUNNING';source_files=$uiOwnerHashes;source_drift=$null;profile=$uiOwnerProfile;engine_path=$Godot;display='headless';evidence_type='OWNER_HEADLESS_ONLY';formal_audio='PENDING_11';formal_runtime='PENDING_01';fresh_integrated_build_graphical='PENDING_00';human_acceptance='NOT_RUN';stages=@();frozen_imports_restored=$false}
function Save-UiOwnerReport {
    $uiOwnerSummary.stages = @($uiOwnerStages.ToArray())
    [IO.File]::WriteAllText((Join-Path $uiOwnerEvidence 'run_report.json'), ($uiOwnerSummary | ConvertTo-Json -Depth 12).Replace("`r`n","`n") + "`n", [Text.UTF8Encoding]::new($false))
}
function Invoke-UiOwnerStage([string]$Name,[string[]]$StageArgs) {
    $uiOwnerOut = Join-Path $uiOwnerEvidence "$Name.stdout.log"
    $uiOwnerErr = Join-Path $uiOwnerEvidence "$Name.stderr.log"
    $uiOwnerArgs = @('--headless','--path',('"'+$uiOwnerRoot+'"')) + $StageArgs
    $uiOwnerStage = [ordered]@{name=$Name;args=$uiOwnerArgs;status='RUNNING';pid=$null;exit_code=$null;checks=0;stderr_bytes=$null}
    $uiOwnerStages.Add($uiOwnerStage)
    Save-UiOwnerReport
    $uiOwnerProcess = Start-Process -FilePath $Godot -ArgumentList $uiOwnerArgs -WindowStyle Hidden -PassThru -Environment @{APPDATA=$uiOwnerProfile;LOCALAPPDATA=$uiOwnerProfile} -RedirectStandardOutput $uiOwnerOut -RedirectStandardError $uiOwnerErr
    $uiOwnerStage.pid = $uiOwnerProcess.Id
    Save-UiOwnerReport
    if (-not $uiOwnerProcess.WaitForExit(45000)) { $uiOwnerProcess.Kill(); $uiOwnerProcess.WaitForExit(); throw "$Name timeout; only own PID stopped" }
    $uiOwnerProcess.WaitForExit()
    $uiOwnerStage.exit_code = $uiOwnerProcess.ExitCode
    $uiOwnerStage.stderr_bytes = (Get-Item -LiteralPath $uiOwnerErr).Length
    $uiOwnerOutput = Get-Content -LiteralPath $uiOwnerOut -Raw
    if ($uiOwnerStage.exit_code -ne 0 -or $uiOwnerStage.stderr_bytes -ne 0 -or $uiOwnerOutput -match 'SCRIPT ERROR:|ERROR:|FAIL:') {
        $uiOwnerStage.status = 'FAIL'; Save-UiOwnerReport; throw "$Name failed; retained raw stdout/stderr"
    }
    if ($Name -like 'baseline_*') {
        $uiOwnerLabel = $Name.Substring(9).ToUpperInvariant()
        if ($uiOwnerOutput -notmatch ("SHELL " + $uiOwnerLabel + ": (\d+) checks, failures=\[\]")) { throw "$Name missing passing report" }
        $uiOwnerStage.checks = [int]$Matches[1]
    } elseif ($Name -ne 'import') {
        $uiOwnerCaseReport = Get-Content -LiteralPath (Join-Path $uiOwnerEvidence "$Name/report.json") -Raw | ConvertFrom-Json
        $uiOwnerStage.checks = $uiOwnerCaseReport.checks
        if ($uiOwnerCaseReport.failures.Count -ne 0 -or $uiOwnerCaseReport.pid -ne $uiOwnerStage.pid -or -not $uiOwnerCaseReport.user_data_dir.StartsWith($uiOwnerProfile.Replace('\','/'),[StringComparison]::OrdinalIgnoreCase)) { throw "$Name report/profile/process mismatch" }
    }
    if ($Name -ne 'import' -and $uiOwnerStage.checks -le 0) { throw "$Name has no positive checks" }
    $uiOwnerStage.status = 'PASS'
    Save-UiOwnerReport
    Write-Output "$Name PASS checks=$($uiOwnerStage.checks) exit=$($uiOwnerStage.exit_code) stderr=$($uiOwnerStage.stderr_bytes)"
}
try {
    if ($Import) {
        $uiOwnerOriginalImports = @{}
        foreach ($uiOwnerRel in @(git -C $uiOwnerRoot ls-files '*.import')) {
            $uiOwnerOriginalImports[$uiOwnerRel] = [IO.File]::ReadAllBytes((Join-Path $uiOwnerRoot $uiOwnerRel))
        }
        try { Invoke-UiOwnerStage 'import' @('--editor','--import') }
        finally {
            foreach ($uiOwnerRel in $uiOwnerOriginalImports.Keys) { [IO.File]::WriteAllBytes((Join-Path $uiOwnerRoot $uiOwnerRel),$uiOwnerOriginalImports[$uiOwnerRel]) }
            $uiOwnerSummary.frozen_imports_restored = $true
            Save-UiOwnerReport
        }
    }
    foreach ($uiOwnerCase in $Cases) {
        if ($uiOwnerCase -in @('baseline_save','baseline_flow')) {
            Invoke-UiOwnerStage $uiOwnerCase @('--script',('res://tests/shell/test_'+$uiOwnerCase.Substring(9)+'.gd'))
        } elseif ($uiOwnerCase -in @('seed','restore','layout')) {
            $uiOwnerScript = if ($uiOwnerCase -eq 'layout') { 'test_layout.gd' } else { 'test_ui.gd' }
            Invoke-UiOwnerStage $uiOwnerCase @('--script',('res://tests/beta_sprint/game_feel_owner_07/'+$uiOwnerScript),'--',"--phase=$uiOwnerCase",('--evidence-dir="'+(Join-Path $uiOwnerEvidence $uiOwnerCase)+'"'),"--shell-save=user://beta_sprint/$EvidenceName/settings.json")
        } else { throw "Unknown case $uiOwnerCase" }
    }
    foreach ($uiOwnerSource in $uiOwnerHashes) {
        if ((Get-FileHash -LiteralPath (Join-Path $uiOwnerRoot $uiOwnerSource.path)).Hash.ToLowerInvariant() -ne $uiOwnerSource.sha256) { throw "Source drift: $($uiOwnerSource.path)" }
    }
    $uiOwnerCheckTotal = 0
    foreach ($uiOwnerStage in $uiOwnerStages) { $uiOwnerCheckTotal += [int]$uiOwnerStage.checks }
    if ($uiOwnerCheckTotal -le 0) { throw 'No positive behavioral checks; cannot declare PASS' }
    $uiOwnerSummary.behavioral_checks = $uiOwnerCheckTotal
    $uiOwnerSummary.source_drift = $false
    $uiOwnerSummary.status = 'PASS'
    Save-UiOwnerReport
    Write-Output "OWNER07_HEADLESS_PASS $uiOwnerEvidence"
} catch {
    $uiOwnerSummary.status = 'FAIL'
    $uiOwnerSummary.failure = $_.Exception.Message
    Save-UiOwnerReport
    throw
}
