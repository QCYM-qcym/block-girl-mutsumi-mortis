param(
    [string]$Project = (Join-Path $PSScriptRoot '../../..'),
    [string]$Godot = 'D:/APP/steam/steamapps/common/Godot Engine/godot.windows.opt.tools.64.exe',
    [string]$EvidenceName = ('b3d02_' + (Get-Date -Format 'yyyyMMdd_HHmmss') + '_' + [guid]::NewGuid().ToString('N').Substring(0,6)),
    [ValidateSet('import','entry','l02','l03','l01','all','focused')][string]$Mode = 'entry',
    [ValidateSet('mutsumi_l01','mutsumi_l02','mutsumi_l03')][string]$Level = 'mutsumi_l02',
    [switch]$TraceProgress,
    [int]$StageTimeoutSeconds = 180
)
$ErrorActionPreference = 'Stop'
if ($EvidenceName -notmatch '^[a-zA-Z0-9_-]{1,80}$') { throw 'Use a fresh short evidence name.' }
if ($StageTimeoutSeconds -lt 1 -or $StageTimeoutSeconds -gt 180) { throw 'Stage timeout must be 1..180 seconds.' }
$b3dProject = (Resolve-Path -LiteralPath $Project).Path
$b3dEvidence = Join-Path $b3dProject ".godot/beta-sprint/three-d-02/$EvidenceName"
if (Test-Path -LiteralPath $b3dEvidence) { throw 'Evidence already exists; earlier runs must be preserved.' }
New-Item -ItemType Directory -Path $b3dEvidence | Out-Null
$b3dHead = (& git -C $b3dProject rev-parse HEAD).Trim()
if ($LASTEXITCODE -ne 0) { throw 'Cannot identify source HEAD.' }
$b3dPaths = @('project.godot','default_bus_layout.tres')
$b3dPaths += @(& git -C $b3dProject ls-files --cached --others --exclude-standard -- game prototype/perspective production/art_3d production/audio/p01 production/ui/beta_shell_01 tests/playtest/test_batch_01_runtime.gd tests/beta_sprint/three_d_02)
$b3dPaths += @(& git -C $b3dProject ls-files --cached --others --exclude-standard -- tests/beta_sprint/content_expansion_02)
$b3dSources = @($b3dPaths | Sort-Object -Unique | Where-Object { Test-Path -LiteralPath (Join-Path $b3dProject $_) -PathType Leaf } | ForEach-Object {
    [ordered]@{path=$_;sha256=(Get-FileHash -LiteralPath (Join-Path $b3dProject $_) -Algorithm SHA256).Hash.ToLowerInvariant()}
})
$b3dStages = [System.Collections.Generic.List[object]]::new()
$b3dSummary = [ordered]@{status='RUNNING';project=$b3dProject;head=$b3dHead;mode=$Mode;level=$Level;trace_progress=[bool]$TraceProgress;working_tree=@(& git -C $b3dProject status --porcelain);engine=$Godot;engine_sha256=(Get-FileHash -LiteralPath $Godot -Algorithm SHA256).Hash.ToLowerInvariant();sources=$b3dSources;stages=@();started_utc=[DateTime]::UtcNow.ToString('o');scope='Native Content/P01 Runtime; observation SHA256 explicitly not Foundation statekey.v1; no Cold Continue or new unlock matrix'}
function Save-B3DReport {
    $b3dSummary.stages = @($b3dStages.ToArray())
    $b3dSummary | ConvertTo-Json -Depth 16 | Set-Content -LiteralPath (Join-Path $b3dEvidence 'run_report.json') -Encoding utf8
}
function Invoke-B3DStage([string]$Name, [string[]]$Arguments, [string]$CaseEvidence = '', [bool]$Graphical = $false) {
    $stageOut = Join-Path $b3dEvidence "$Name.stdout.log"
    $stageErr = Join-Path $b3dEvidence "$Name.stderr.log"
    $stage = [ordered]@{name=$Name;pid=$null;exit_code=$null;stdout=$stageOut;stderr=$stageErr;timed_out=$false;started_utc=[DateTime]::UtcNow.ToString('o')}
    $b3dStages.Add($stage)
    Save-B3DReport
    $stageProcess = Start-Process -FilePath $Godot -ArgumentList (@('--path', ('"' + $b3dProject + '"')) + $Arguments) -WindowStyle Hidden -PassThru -RedirectStandardOutput $stageOut -RedirectStandardError $stageErr
    $stage.pid = $stageProcess.Id
    Save-B3DReport
    try {
        if (-not $stageProcess.WaitForExit($StageTimeoutSeconds * 1000)) {
            $stage.timed_out = $true
            $stageProcess.Kill()
            $stageProcess.WaitForExit()
        }
        $stageProcess.WaitForExit()
        $stage.exit_code = $stageProcess.ExitCode
        $stage.finished_utc = [DateTime]::UtcNow.ToString('o')
        $stage.stderr_empty = (Get-Item -LiteralPath $stageErr).Length -eq 0
        $stage.stdout_clean = (Get-Content -LiteralPath $stageOut -Raw) -notmatch 'SCRIPT ERROR:|ERROR:|WARNING:|FAIL:'
        if ($CaseEvidence) {
            $stage.report = Join-Path $CaseEvidence 'report.json'
            $stage.checks = 0
            $stage.failures = @('Missing actual report.json')
            if (Test-Path -LiteralPath $stage.report) {
                $case = Get-Content -LiteralPath $stage.report -Raw | ConvertFrom-Json
                $stage.checks = $case.checks
                $stage.failures = @($case.failures)
                $stage.actual_pid = $case.pid
                $stage.actual_project = $case.project
                $stage.actual_display = $case.display
                $stage.level_id = $case.level_id
            }
        }
        Save-B3DReport
        if ($stage.timed_out -or $stage.exit_code -ne 0 -or -not $stage.stderr_empty -or -not $stage.stdout_clean -or ($CaseEvidence -and ($stage.checks -le 0 -or $stage.failures.Count -gt 0 -or $stage.actual_pid -ne $stage.pid)) -or ($Graphical -and $stage.actual_display -eq 'headless')) {
            throw "$Name failed: PID=$($stage.pid), exit=$($stage.exit_code). Evidence: $b3dEvidence"
        }
        Get-Content -LiteralPath $stageOut
    } finally { $stageProcess.Dispose() }
}
function Invoke-B3DEntry([string]$Id) {
    $caseEvidence = Join-Path $b3dEvidence "entry_$Id"
    Invoke-B3DStage "entry_$Id" @('--headless','--script','res://tests/beta_sprint/three_d_02/test_entry.gd','--',"--level=$Id",('--evidence-dir="' + $caseEvidence + '"')) $caseEvidence
}
function Invoke-B3DGameplay([string]$Id) {
    $caseEvidence = Join-Path $b3dEvidence "gameplay_$Id"
    $save = "user://beta_sprint/b3d02_$EvidenceName/$Id.json"
    $gameplayScript = if ($TraceProgress) { 'res://tests/beta_sprint/content_expansion_02/trace_3d_regression.gd' } else { 'res://tests/beta_sprint/three_d_02/test_gameplay.gd' }
    Invoke-B3DStage "gameplay_$Id" @('--max-fps','60','--script',$gameplayScript,'--',"--level=$Id",('--evidence-dir="' + $caseEvidence + '"'),"--shell-save=$save","--head=$b3dHead") $caseEvidence $true
}
try {
    if ($Mode -in @('import','all')) { Invoke-B3DStage 'import' @('--headless','--editor','--import') }
    if ($Mode -eq 'entry') { Invoke-B3DEntry $Level }
    elseif ($Mode -eq 'focused') {
        $caseEvidence = Join-Path $b3dEvidence 'old_three_focused'
        Invoke-B3DStage 'old_three_focused' @('--max-fps','60','--script','res://tests/beta_sprint/content_expansion_02/test_old_three_focused.gd','--',('--evidence-dir="'+$caseEvidence+'"'),"--shell-save=user://beta_sprint/b3d02_$EvidenceName/old_three.json","--head=$b3dHead") $caseEvidence $true
    }
    elseif ($Mode -eq 'all') {
        foreach ($id in @('mutsumi_l02','mutsumi_l03','mutsumi_l01')) {
            Invoke-B3DEntry $id
            Invoke-B3DGameplay $id
        }
    } elseif ($Mode -in @('l02','l03','l01')) {
        Invoke-B3DEntry "mutsumi_$Mode"
        Invoke-B3DGameplay "mutsumi_$Mode"
    }
    $b3dSummary.changed_sources = @($b3dSources | Where-Object { (Get-FileHash -LiteralPath (Join-Path $b3dProject $_.path) -Algorithm SHA256).Hash.ToLowerInvariant() -ne $_.sha256 } | ForEach-Object { $_.path })
    if ($Mode -ne 'import' -and $b3dSummary.changed_sources.Count -gt 0) { throw 'Source changed during validation; source identity is not stable.' }
    $b3dSummary.status = 'PASS'
    $b3dSummary.finished_utc = [DateTime]::UtcNow.ToString('o')
    Save-B3DReport
    Write-Output "B3D02 $Mode PASS: $b3dEvidence"
} catch {
    $b3dSummary.status = 'FAIL'
    $b3dSummary.failure = $_.Exception.Message
    $b3dSummary.finished_utc = [DateTime]::UtcNow.ToString('o')
    Save-B3DReport
    throw
}
