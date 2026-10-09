param(
    [string]$RunId = 'l04_p1_focused_01',
    [switch]$Graphical,
    [string]$Godot = 'D:/APP/steam/steamapps/common/Godot Engine/godot.windows.opt.tools.64.exe'
)
$ErrorActionPreference = 'Stop'
if ($RunId -notmatch '^[A-Za-z0-9_-]+$') { throw 'Use a fresh simple RunId' }
$hotfixProject = (Resolve-Path -LiteralPath (Join-Path $PSScriptRoot '../../..')).Path
$hotfixEvidence = Join-Path $hotfixProject ".godot/beta-sprint/l04-p1-integration/$RunId"
if (Test-Path -LiteralPath $hotfixEvidence) { throw 'Preserve existing evidence; select another RunId' }
New-Item -ItemType Directory -Path $hotfixEvidence | Out-Null
$hotfixPaths = @(& git -C $hotfixProject -c core.quotepath=false ls-files -- game foundation prototype production project.godot default_bus_layout.tres)
$hotfixPaths += @('tests/beta_sprint/l04_inner_movement_p1/test_l04.gd','tests/beta_sprint/l04_inner_movement_p1/test_playthrough.gd')
$hotfixPaths += @(Get-ChildItem -LiteralPath $PSScriptRoot -File | ForEach-Object { 'tests/beta_sprint/l04_p1_integration/'+$_.Name })
$hotfixSources = @($hotfixPaths | Sort-Object -Unique | ForEach-Object { [ordered]@{path=$_;sha256=(Get-FileHash -LiteralPath (Join-Path $hotfixProject $_) -Algorithm SHA256).Hash.ToLowerInvariant()} })
$hotfixOut = Join-Path $hotfixEvidence 'stdout.log'
$hotfixErr = Join-Path $hotfixEvidence 'stderr.log'
$hotfixArgs = @('--path',('"'+$hotfixProject+'"'),'--max-fps','60','--audio-driver','WASAPI')
if (-not $Graphical) { $hotfixArgs += '--headless' }
$hotfixArgs += @('--script','res://tests/beta_sprint/l04_p1_integration/test_focused.gd','--',('--evidence-dir="'+$hotfixEvidence+'"'),'--case=playthrough','--entry=shell')
if ($Graphical) { $hotfixArgs += '--graphical' }
$hotfixStarted = [DateTime]::UtcNow.ToString('o')
$hotfixProcess = Start-Process -FilePath $Godot -ArgumentList $hotfixArgs -WindowStyle Hidden -PassThru -RedirectStandardOutput $hotfixOut -RedirectStandardError $hotfixErr
Write-Output "START L04-P1 Integration PID=$($hotfixProcess.Id) Graphical=$Graphical"
$hotfixTimeout = -not $hotfixProcess.WaitForExit(180000)
if ($hotfixTimeout) { $hotfixProcess.Kill() }
$hotfixProcess.WaitForExit()
$hotfixChanged = @($hotfixSources | Where-Object { (Get-FileHash -LiteralPath (Join-Path $hotfixProject $_.path) -Algorithm SHA256).Hash -ne $_.sha256 } | ForEach-Object path)
$hotfixReportPath = Join-Path $hotfixEvidence 'report.json'
$hotfixReport = if (Test-Path -LiteralPath $hotfixReportPath) { Get-Content -LiteralPath $hotfixReportPath -Raw | ConvertFrom-Json } else { $null }
$hotfixMeta = [ordered]@{head=(& git -C $hotfixProject rev-parse HEAD).Trim();project=$hotfixProject;pid=$hotfixProcess.Id;exit_code=$hotfixProcess.ExitCode;timed_out=$hotfixTimeout;graphical=[bool]$Graphical;args=$hotfixArgs;started_utc=$hotfixStarted;finished_utc=[DateTime]::UtcNow.ToString('o');checks=$hotfixReport.checks;failures=@($hotfixReport.failures);stderr_bytes=(Get-Item -LiteralPath $hotfixErr).Length;sources=$hotfixSources;changed_sources=$hotfixChanged;stdout_sha256=(Get-FileHash -LiteralPath $hotfixOut).Hash.ToLowerInvariant();stderr_sha256=(Get-FileHash -LiteralPath $hotfixErr).Hash.ToLowerInvariant();human_qa='NOT_RUN'}
$hotfixMeta | ConvertTo-Json -Depth 10 | Set-Content -LiteralPath (Join-Path $hotfixEvidence 'process.json') -Encoding utf8
$hotfixStdout = Get-Content -LiteralPath $hotfixOut -Raw
if ($hotfixTimeout -or $hotfixProcess.ExitCode -ne 0 -or $hotfixMeta.stderr_bytes -ne 0 -or $hotfixStdout -match 'SCRIPT ERROR:|ERROR:|FAIL' -or $hotfixChanged.Count -ne 0 -or -not $hotfixReport -or $hotfixReport.checks -le 0 -or @($hotfixReport.failures).Count -ne 0 -or $hotfixReport.pid -ne $hotfixProcess.Id -or ($Graphical -and $hotfixReport.display -eq 'headless') -or (-not $Graphical -and $hotfixReport.display -ne 'headless')) { throw "Focused case failed; original evidence preserved: $hotfixEvidence" }
Write-Output "FOCUSED PASS: $($hotfixReport.checks) checks; routes=$($hotfixReport.routes.Count); screenshots=$($hotfixReport.screenshots.Count); PID=$($hotfixProcess.Id); exit0/stderr0; evidence=$hotfixEvidence"
