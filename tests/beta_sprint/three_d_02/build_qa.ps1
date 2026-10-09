param(
    [string]$BuildName = ('beta_3d02_' + (Get-Date -Format 'yyyyMMdd_HHmmss')),
    [string]$EvidenceName = 'b3d02_final',
    [ValidateSet('3D02','CONTENT02')][string]$QaProfile = '3D02',
    [string]$Godot = 'D:/APP/steam/steamapps/common/Godot Engine/godot.windows.opt.tools.64.exe'
)
$ErrorActionPreference = 'Stop'
if ($BuildName -notmatch '^[a-zA-Z0-9_-]+$' -or $EvidenceName -notmatch '^[a-zA-Z0-9_-]+$') { throw 'Use fresh simple names.' }
$qaSource = (Resolve-Path -LiteralPath (Join-Path $PSScriptRoot '../../..')).Path
$qaBuildRoot = [IO.Path]::GetFullPath('E:/godot/beta-sprint-builds')
$qaBuild = [IO.Path]::GetFullPath((Join-Path $qaBuildRoot $BuildName))
if (-not $qaBuild.StartsWith($qaBuildRoot + [IO.Path]::DirectorySeparatorChar, [StringComparison]::OrdinalIgnoreCase)) { throw 'Build escaped output root.' }
if (Test-Path -LiteralPath $qaBuild) { throw 'Never replace an earlier QA build.' }
if (@(& git -C $qaSource status --porcelain).Count) { throw 'Build requires clean committed source.' }
& (Join-Path $qaSource 'tests/beta_sprint/build_source_daily.ps1') -Godot $Godot -BuildName $BuildName -SmokeEvidenceName $EvidenceName
$qaBaseExit = $LASTEXITCODE
$qaManifestPath = Join-Path $qaBuild 'build-manifest.json'
if (-not (Test-Path -LiteralPath $qaManifestPath)) { throw 'Base source builder did not produce a manifest.' }
$qaManifest = Get-Content -LiteralPath $qaManifestPath -Raw | ConvertFrom-Json
if ($QaProfile -eq 'CONTENT02' -and 'mutsumi_l04' -notin @($qaManifest.game_catalog.levels.id)) { throw 'Content Batch02 build requires the delivered playable L04 in the formal catalog.' }
$qaEvidence = Join-Path $qaSource ".godot/beta-sprint/$BuildName"
$qaKnown = [Collections.Generic.List[string]]::new()
foreach ($qaStage in $qaManifest.verification) {
    $qaErr = (Get-Content -LiteralPath $qaStage.stderr -Raw)
    $qaOut = (Get-Content -LiteralPath $qaStage.stdout -Raw)
    if ($qaStage.exit_code -ne 0 -or $qaStage.timed_out -or $qaOut -match 'SCRIPT ERROR:|ERROR:|FAIL:') { throw "Real copied-project failure: $($qaStage.stage)" }
    if ($qaStage.status -eq 'FAIL') {
        # Preserve the original FAIL. Only the exact pre-existing unused defs-only SVG import may be classified P2.
        $qaErrorLines = @($qaErr -split '\r?\n' | Where-Object { $_ -match '^\s*(ERROR:|SCRIPT ERROR:|WARNING:|FAIL:)' })
        $qaExpected = @("ERROR: ImageLoaderSVG: Couldn't set target on ThorVG canvas, error code 1.", "ERROR: Error loading image: 'res://production/ui/beta_shell_01/icons_source.svg'.", "ERROR: Error importing 'res://production/ui/beta_shell_01/icons_source.svg'.")
        if ($qaStage.stage -ne 'import' -or ($qaErrorLines -join "`n") -ne ($qaExpected -join "`n")) { throw "Unexpected import or boot failure: $($qaStage.stage)" }
        $qaKnown.Add('P2: frozen unused SVG symbol definitions cannot be raster-imported on the initial scan; real game uses separate approved icons.')
    } elseif ($qaStage.status -ne 'PASS') { throw "Unverified copied-project stage: $($qaStage.stage)" }
    elseif ($qaErr) {
        $qaKnownWarningSha = 'bf8149e7a4c220bbef9c5eac13cd97f17ae895e5fff5a7befa152e30319f4d9d'
        if ((Get-FileHash -LiteralPath $qaStage.stderr -Algorithm SHA256).Hash.ToLowerInvariant() -ne $qaKnownWarningSha) { throw "Unexpected boot stderr: $($qaStage.stage)" }
        $qaKnown.Add("Existing standalone --quit-after ObjectDB exit warning: $($qaStage.stage)")
    }
}
$qaProject = Join-Path $qaBuild 'project'
$qaRestored = [Collections.Generic.List[string]]::new()
foreach ($qaFile in $qaManifest.files) {
    $qaFrom = Join-Path $qaSource $qaFile.path
    $qaTo = Join-Path $qaProject $qaFile.path
    if ((Get-FileHash -LiteralPath $qaFrom -Algorithm SHA256).Hash.ToLowerInvariant() -ne $qaFile.sha256) { throw "Source changed during build: $($qaFile.path)" }
    if ((Get-FileHash -LiteralPath $qaTo -Algorithm SHA256).Hash.ToLowerInvariant() -ne $qaFile.sha256) {
        if ($qaFile.path -ne 'production/ui/beta_shell_01/icons_source.svg.import') { throw "Unexpected copied-source mutation: $($qaFile.path)" }
        Copy-Item -LiteralPath $qaFrom -Destination $qaTo
        $qaRestored.Add($qaFile.path)
    }
    if ((Get-FileHash -LiteralPath $qaTo -Algorithm SHA256).Hash.ToLowerInvariant() -ne $qaFile.sha256) { throw "Copied source does not match: $($qaFile.path)" }
}
$qaPlay = @'
param([string]$Godot = 'D:/APP/steam/steamapps/common/Godot Engine/godot.windows.opt.tools.64.exe')
$ErrorActionPreference = 'Stop'
if (-not (Test-Path -LiteralPath $Godot)) { throw 'Pass -Godot with a Godot 4.7.2 executable.' }
$qaPlayProject = Join-Path $PSScriptRoot 'project'
$qaImport = Start-Process -FilePath $Godot -ArgumentList @('--headless','--editor','--import','--path',('"'+$qaPlayProject+'"')) -WindowStyle Hidden -PassThru -Wait
if ($qaImport.ExitCode -ne 0) { throw 'Godot import failed; preserve evidence.' }
$qaGame = Start-Process -FilePath $Godot -ArgumentList @('--path',('"'+$qaPlayProject+'"'),'--','--shell-save=user://beta_sprint/BUILD_PLACEHOLDER/qa_progress.json') -WindowStyle Normal -PassThru -Wait
exit $qaGame.ExitCode
'@
$qaPlay.Replace('BUILD_PLACEHOLDER', $BuildName) | Set-Content -LiteralPath (Join-Path $qaBuild 'play.ps1') -Encoding utf8
$qaReadme = @"
# BETA-3D-INTEGRATION-02 QA candidate

Source snapshot: $($qaManifest.head). SOURCE_PLAYABLE_NOT_EXE; Godot 4.7.2 required.
Run ./play.ps1. Its new save is user://beta_sprint/$BuildName/qa_progress.json; earlier08 build and QA profile are not used.

Presentation: L01 unchanged approved3D; L02 and L03 new formal approved3D presentation, retained Pixel Runtime reference.
Content declarations remain the original06 quality values and map bytes. This is a presentation upgrade, not a new puzzle or Foundation migration.
Game Shell, level IDs, actions, Save/Continue implementation and solutions remain unchanged.
WASD roll; Q/E four90-degree views; Space world; R Reset; Esc Pause/Resume.
L02 first, then L03 Perspective Connection (Surface EAST only). Human/08 QA for this new candidate is pending.

Known baseline import/exit notes: $($qaKnown -join '; ')
STAIR_CLEARANCE=PARTIAL_PASS; STAIR_TRAVERSAL=NOT_RUN. L03 hint P2 stays with06.
The original base builder stage records remain in build-manifest.json; QA_BUILD_VERIFICATION.json classifies only named baseline issues and verifies all copied sources.
"@
if ($QaProfile -eq 'CONTENT02') {
    $qaLevelList = ($qaManifest.game_catalog.levels | ForEach-Object { '- ' + $_.id + ': ' + $_.title + ' (' + $_.quality + ')' }) -join [Environment]::NewLine
    $qaReadme = @"
# Beta Sprint Phase2 — Content Batch02 Daily Build

Source snapshot: $($qaManifest.head). SOURCE_PLAYABLE_NOT_EXE; Godot 4.7.2 required.
Run ./play.ps1. Isolated save: user://beta_sprint/$BuildName/qa_progress.json.
All registered levels enter through the formal Main Menu / Level Select, using normal completion to unlock the next level:
$qaLevelList

L01/L02/L03 reuse approved3D presentation; delivered Batch02 levels use greybox presentation and the original Content/P01 Runtime.
Continue restores the most recently entered unlocked level at its authored spawn. Save/Continue algorithms are unchanged.
WASD move; Q/E four90-degree views; Space world; R Reset; Esc Pause/Resume.

Copied-source, catalog and boot checks are recorded in build-manifest.json and QA_BUILD_VERIFICATION.json.
Smoke evidence reference: $EvidenceName (see the separate Integration receipt for actual route results).
Independent Human QA for this new Daily Build: NOT_RUN. Previous fixed3D02 matrix/Cold Continue evidence belongs to that earlier Build only.
Known baseline import/exit notes: $($qaKnown -join '; ')
STAIR_CLEARANCE=PARTIAL_PASS; STAIR_TRAVERSAL=NOT_RUN. Frozen Art and Foundation remain unchanged.
"@
}
$qaReadme | Set-Content -LiteralPath (Join-Path $qaBuild 'README.md') -Encoding utf8
$qaResult = [ordered]@{status=$(if ($qaKnown.Count) {'PASS_WITH_KNOWN_BASELINE_P2'} else {'PASS'});profile=$QaProfile;base_builder_exit=$qaBaseExit;head=$qaManifest.head;source=$qaSource;build=$qaBuild;copied_files=$qaManifest.files.Count;copied_hash_mismatches=@();known_baseline_notes=@($qaKnown.ToArray());restored_generated_import_metadata=@($qaRestored.ToArray());save="user://beta_sprint/$BuildName/qa_progress.json";human_qa='NOT_RUN';stairs_clearance='PARTIAL_PASS';stairs_traversal='NOT_RUN';finished_utc=[DateTime]::UtcNow.ToString('o')}
$qaResult | ConvertTo-Json -Depth 8 | Set-Content -LiteralPath (Join-Path $qaBuild 'QA_BUILD_VERIFICATION.json') -Encoding utf8
$qaResult | ConvertTo-Json -Depth 8 | Set-Content -LiteralPath (Join-Path $qaEvidence 'QA_BUILD_VERIFICATION.json') -Encoding utf8
$qaZip = $qaBuild + '.zip'
if (-not (Test-Path -LiteralPath $qaZip)) { throw 'Missing base snapshot archive.' }
$qaOriginalZip = Join-Path $qaEvidence 'pre_handoff_source_archive.zip'
if (Test-Path -LiteralPath $qaOriginalZip) { throw 'Preserve earlier archive evidence.' }
Move-Item -LiteralPath $qaZip -Destination $qaOriginalZip
Add-Type -AssemblyName System.IO.Compression.FileSystem
[IO.Compression.ZipFile]::CreateFromDirectory($qaBuild, $qaZip, [IO.Compression.CompressionLevel]::Optimal, $true)
[ordered]@{zip=$qaZip;sha256=(Get-FileHash -LiteralPath $qaZip -Algorithm SHA256).Hash.ToLowerInvariant();bytes=(Get-Item -LiteralPath $qaZip).Length} | ConvertTo-Json | Set-Content -LiteralPath (Join-Path $qaEvidence 'qa_archive.json') -Encoding utf8
Write-Output "NEW_ISOLATED_QA_BUILD: $qaBuild"
