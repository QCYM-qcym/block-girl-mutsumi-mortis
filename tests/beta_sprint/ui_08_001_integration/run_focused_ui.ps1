param(
    [string]$Godot = 'D:/APP/steam/steamapps/common/Godot Engine/godot.windows.opt.tools.64.exe',
    [string]$EvidenceName = ('ui08001_' + (Get-Date -Format 'yyyyMMdd_HHmmss')),
    [ValidateSet('all','focused')][string]$Mode = 'all'
)
$ErrorActionPreference = 'Stop'
if($EvidenceName -notmatch '^[a-zA-Z0-9_-]+$'){throw 'Use a fresh simple evidence name.'}
$focusProject = (Resolve-Path -LiteralPath (Join-Path $PSScriptRoot '../../..')).Path
$focusEvidence = Join-Path $focusProject ".godot/ui-08-001/$EvidenceName"
if(Test-Path -LiteralPath $focusEvidence){throw 'Keep prior evidence; choose a new name.'}
New-Item -ItemType Directory -Path $focusEvidence -Force | Out-Null
$focusPaths = @(& git -C $focusProject -c core.quotepath=false ls-files --cached --others --exclude-standard -- game production foundation prototype tools/foundation project.godot default_bus_layout.tres tests/shell/pause_text tests/beta_sprint/ui_08_001_integration)
if($LASTEXITCODE -ne 0){throw 'Cannot record actual source files.'}
$focusSources = @($focusPaths | Sort-Object -Unique | ForEach-Object { [ordered]@{path=$_;sha256=(Get-FileHash -LiteralPath (Join-Path $focusProject $_) -Algorithm SHA256).Hash.ToLowerInvariant()} })
$focusHead = (& git -C $focusProject rev-parse HEAD).Trim()
$focusStages = [Collections.Generic.List[object]]::new()
$focusReport = [ordered]@{status='RUNNING';project=$focusProject;head=$focusHead;fix_commit='81d9470c174bd67a73e7e8fedf4b92240ddfc2fd';engine=$Godot;engine_sha256=(Get-FileHash -LiteralPath $Godot -Algorithm SHA256).Hash.ToLowerInvariant();sources=$focusSources;stages=@();human_qa='NOT_RUN';issue_status='OPEN / READY_FOR_08_RECHECK'}
function Save-FocusReport {
    $focusReport.stages = @($focusStages.ToArray())
    $focusReport | ConvertTo-Json -Depth 10 | Set-Content -LiteralPath (Join-Path $focusEvidence 'run_report.json') -Encoding utf8
}
function Invoke-FocusStage([string]$Name,[string[]]$Arguments,[bool]$HasCase = $false) {
    $focusOut = Join-Path $focusEvidence "$Name.stdout.log"
    $focusErr = Join-Path $focusEvidence "$Name.stderr.log"
    $stage = [ordered]@{name=$Name;pid=$null;exit_code=$null;stdout=$focusOut;stderr=$focusErr;started_utc=[DateTime]::UtcNow.ToString('o');timed_out=$false}
    $focusStages.Add($stage)
    Save-FocusReport
    $process = Start-Process -FilePath $Godot -ArgumentList (@('--path',('"'+$focusProject+'"')) + $Arguments) -WindowStyle Hidden -PassThru -RedirectStandardOutput $focusOut -RedirectStandardError $focusErr
    $stage.pid = $process.Id
    Save-FocusReport
    if(-not $process.WaitForExit(180000)){ $stage.timed_out=$true; $process.Kill(); $process.WaitForExit() }
    $process.WaitForExit()
    $stage.exit_code = $process.ExitCode
    $stage.finished_utc = [DateTime]::UtcNow.ToString('o')
    $stage.stderr_empty = (Get-Item -LiteralPath $focusErr -Force).Length -eq 0
    $stage.stdout_clean = (Get-Content -LiteralPath $focusOut -Raw) -notmatch 'SCRIPT ERROR:|ERROR:|WARNING:|FAIL:'
    if($HasCase){
        $stage.report = Join-Path $focusEvidence "$Name/report.json"
        if(Test-Path -LiteralPath $stage.report){
            $case = Get-Content -LiteralPath $stage.report -Raw | ConvertFrom-Json
            $stage.checks=$case.checks
            $stage.failures=@($case.failures)
        }else{ $stage.checks=0; $stage.failures=@('Missing actual case report') }
    }
    Save-FocusReport
    if($stage.timed_out -or $stage.exit_code -ne 0 -or -not $stage.stderr_empty -or -not $stage.stdout_clean -or ($HasCase -and ($stage.checks -le 0 -or $stage.failures.Count))){throw "Actual focused stage failed: $Name; preserve $focusEvidence"}
}
try {
    Invoke-FocusStage 'import' @('--headless','--editor','--import')
    $casesToRun = if($Mode -eq 'all'){@('owner','focused')}else{@('focused')}
    foreach($name in $casesToRun){
        $caseEvidence = Join-Path $focusEvidence $name
        New-Item -ItemType Directory -Path $caseEvidence -Force | Out-Null
        $script = if($name -eq 'owner'){'res://tests/shell/pause_text/test_pause_text.gd'}else{'res://tests/beta_sprint/ui_08_001_integration/test_focused_ui.gd'}
        Invoke-FocusStage $name @('--max-fps','60','--script',$script,'--',('--evidence-dir="'+$caseEvidence+'"'),("--head=$focusHead")) $true
    }
    $changed = @($focusSources | Where-Object { (Get-FileHash -LiteralPath (Join-Path $focusProject $_.path) -Algorithm SHA256).Hash.ToLowerInvariant() -ne $_.sha256 })
    if($changed.Count){throw 'Captured source changed during focused run.'}
    $focusReport.status='PASS'
}catch{
    $focusReport.status='FAIL'
    $focusReport.error=$_.Exception.Message
    Save-FocusReport
    throw
}
Save-FocusReport
Write-Output "UI_08_001_FOCUSED_PASS: $focusEvidence; Human QA NOT_RUN; OPEN / READY_FOR_08_RECHECK"
