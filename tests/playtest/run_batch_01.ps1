param(
    [string]$Godot = 'D:/APP/steam/steamapps/common/Godot Engine/godot.windows.opt.tools.64.exe'
)
$ErrorActionPreference = 'Stop'
$contentProject = (Resolve-Path -LiteralPath (Join-Path $PSScriptRoot '../..')).Path
$contentEvidence = Join-Path $PSScriptRoot 'evidence/batch_01'
New-Item -ItemType Directory -Force -Path $contentEvidence | Out-Null
foreach ($contentStage in @('import','state','runtime')) {
    $contentArgs = @('--path', ('"' + $contentProject + '"'))
    if ($contentStage -eq 'import') { $contentArgs += @('--headless','--editor','--import') }
    else {
        $contentArgs += @('--script', "res://tests/playtest/test_batch_01_$contentStage.gd")
        if ($contentStage -eq 'state') { $contentArgs += '--headless' }
        else { $contentArgs += @('--max-fps','60') }
    }
    $contentOut = Join-Path $contentEvidence "$contentStage.stdout.log"
    $contentErr = Join-Path $contentEvidence "$contentStage.stderr.log"
    $contentProcess = Start-Process -FilePath $Godot -ArgumentList $contentArgs -WindowStyle Hidden -PassThru -RedirectStandardOutput $contentOut -RedirectStandardError $contentErr
    if (-not $contentProcess.WaitForExit(240000)) {
        $contentProcess.Kill()
        $contentProcess.WaitForExit()
        throw "$contentStage exceeded 240 seconds"
    }
    $contentProcess.WaitForExit()
    Get-Content -LiteralPath $contentOut
    $contentErrors = Get-Content -LiteralPath $contentErr -Raw
    if ($contentProcess.ExitCode -ne 0 -or $contentErrors -match 'SCRIPT ERROR:|ERROR:|FAIL:') {
        throw "$contentStage failed: $contentErrors"
    }
}
$contentReport = Get-Content -LiteralPath (Join-Path $contentEvidence 'runtime_report.json') -Raw | ConvertFrom-Json
if ($contentReport.display -eq 'headless' -or $contentReport.failures.Count -ne 0 -or $contentReport.playthroughs.Count -ne 7) {
    throw 'Graphical batch acceptance did not pass.'
}
Write-Output "GAME_CONTENT_BATCH_01_VALIDATED: $contentEvidence"
