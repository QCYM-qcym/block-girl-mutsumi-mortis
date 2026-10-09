param(
    [string]$BuildName = 'beta_five_level_3d_20261009_01',
    [string]$EvidenceName = 'five3d_int_01',
    [string]$Godot = 'D:/APP/steam/steamapps/common/Godot Engine/godot.windows.opt.tools.64.exe'
)
$ErrorActionPreference = 'Stop'
if ($BuildName -notmatch '^beta_five_level_3d_[A-Za-z0-9_-]+$' -or $EvidenceName -notmatch '^[A-Za-z0-9_-]+$') { throw 'Use fresh, simple Phase3 names.' }
$fiveSource = (Resolve-Path -LiteralPath (Join-Path $PSScriptRoot '../../..')).Path
$fiveBuildRoot = [IO.Path]::GetFullPath('E:/godot/beta-sprint-builds')
$fiveBuild = [IO.Path]::GetFullPath((Join-Path $fiveBuildRoot $BuildName))
$fiveCache = [IO.Path]::GetFullPath((Join-Path $fiveSource ".godot/beta-sprint/$BuildName"))
$fiveZip = $fiveBuild + '.zip'
if (-not $fiveBuild.StartsWith($fiveBuildRoot + [IO.Path]::DirectorySeparatorChar, [StringComparison]::OrdinalIgnoreCase)) { throw 'Build escaped the named output directory.' }
if ((Test-Path -LiteralPath $fiveBuild) -or (Test-Path -LiteralPath $fiveZip) -or (Test-Path -LiteralPath $fiveCache)) { throw 'Preserve all previous candidates and evidence.' }
if (@(& git -C $fiveSource status --porcelain).Count) { throw 'Build requires clean committed source.' }
$fiveFocused = Get-Content -LiteralPath (Join-Path $fiveSource 'docs/beta-sprint/five-level-3d-slice/FOCUSED_VERIFICATION.json') -Raw | ConvertFrom-Json
if ($fiveFocused.status -ne 'PASS' -or $fiveFocused.L04 -ne '3D_FORMAL_PLAYABLE' -or $fiveFocused.L05 -ne '3D_FORMAL_PLAYABLE') { throw 'Phase3 focused evidence is not ready.' }
foreach ($fiveFile in $fiveFocused.verified_sources) {
    if ((Get-FileHash -LiteralPath (Join-Path $fiveSource $fiveFile.path) -Algorithm SHA256).Hash.ToLowerInvariant() -ne $fiveFile.sha256) { throw "Evidence source drift: $($fiveFile.path)" }
}
$fiveBaseline = Get-Content -LiteralPath (Join-Path $fiveSource 'docs/beta-sprint/five-level-3d-slice/BASELINE.json') -Raw | ConvertFrom-Json
foreach ($fiveFile in $fiveBaseline.protected_sources) {
    if ((Get-FileHash -LiteralPath (Join-Path $fiveSource $fiveFile.path) -Algorithm SHA256).Hash.ToLowerInvariant() -ne $fiveFile.sha256) { throw "Frozen source drift: $($fiveFile.path)" }
}
& (Join-Path $fiveSource 'tests/beta_sprint/three_d_02/build_qa.ps1') -QaProfile CONTENT02 -BuildName $BuildName -EvidenceName $EvidenceName -Godot $Godot
$fiveBaseExit = $LASTEXITCODE
if ($fiveBaseExit -ne 0) { throw 'Existing source/CONTENT02 QA builder did not pass.' }
$fiveManifest = Get-Content -LiteralPath (Join-Path $fiveBuild 'build-manifest.json') -Raw | ConvertFrom-Json
$fiveExpectedIDs = @('mutsumi_l01','mutsumi_l02','mutsumi_l03','mutsumi_l04','mutsumi_l05')
if ((@($fiveManifest.game_catalog.levels.id) -join ',') -ne ($fiveExpectedIDs -join ',')) { throw 'The formal five-level catalog changed.' }
foreach ($fiveRelative in @('game/levels/mutsumi/batch_02/l04_borrowed_path.tscn','game/levels/mutsumi/batch_02/l05_gate_home.tscn')) {
    $fiveScene = Get-Content -LiteralPath (Join-Path ($fiveBuild + '/project') $fiveRelative) -Raw
    if (-not $fiveScene.Contains('res://game/levels/mutsumi/batch_02/levels_3d/presented_level.gd')) { throw "Copied scene is not the approved new attachment: $fiveRelative" }
}
# Preserve the unpublished CONTENT02 wrapper output before adding the Phase3 identity.
$fivePriorZip = [IO.Path]::GetFullPath((Join-Path $fiveCache 'content02_qa_archive_before_phase3.zip'))
if (-not $fivePriorZip.StartsWith($fiveCache + [IO.Path]::DirectorySeparatorChar, [StringComparison]::OrdinalIgnoreCase)) { throw 'Archive retention escaped fresh evidence.' }
if (Test-Path -LiteralPath $fivePriorZip) { throw 'Never replace retained archive evidence.' }
Copy-Item -LiteralPath (Join-Path $fiveBuild 'README.md') -Destination (Join-Path $fiveCache 'content02_README_original.md')
Move-Item -LiteralPath (Join-Path $fiveCache 'qa_archive.json') -Destination (Join-Path $fiveCache 'content02_qa_archive_original.json')
Move-Item -LiteralPath $fiveZip -Destination $fivePriorZip
$fiveKnown = (Get-Content -LiteralPath (Join-Path $fiveBuild 'QA_BUILD_VERIFICATION.json') -Raw | ConvertFrom-Json).known_baseline_notes
$fiveReadme = @"
# Beta Phase3 — Five-Level 3D Unification

Version: $BuildName
Frozen source snapshot: $($fiveManifest.head)
SOURCE_PLAYABLE_NOT_EXE; Godot4.7.2 required. Run ./play.ps1 or pass -Godot with the engine executable.
Isolated save: user://beta_sprint/$BuildName/qa_progress.json

L01-L03 preserve their approved3D presentation. L04/L05 use the new approved3D attachment with the same formal puzzles and Runtime. L04Inner(0,5) is retained. Five stable level IDs enter through Main/LevelSelect and normalcompletion unlocks the next level.
WASD roll; Q/E four90-degree Camera; Space WorldShift; R Reset; Esc Pause/Resume.
Continue returns to the last unlocked level's authored start. Save/Continue logic is unchanged. The package has no prepared progress or test-save files.

New-package Human QA: NOT_RUN.08 should focus L04/L05 full3D routes,Reset,normalprogression,Save/ColdContinue,Camera/WorldShift and necessaryUI interactions. Old fullplaythroughs/UI matrices/ColdContinue are historical evidence only.
ExistingP2: pause auxiliary-text overlap, L03 stalehint, and selected-level preview/caption mismatch. Authored quality declarations were preserved with puzzle resources; the presentation status is recorded separately in the integration receipt.
L03first-time comprehension: RETEST_PENDING unless a genuinely new eligible player supplies evidence.
STAIR_CLEARANCE=PARTIAL_PASS; STAIR_TRAVERSAL=NOT_RUN. Art/Foundation source changes NONE.

Copied-source/catalog/boot results remain in build-manifest.json and QA_BUILD_VERIFICATION.json. Focused evidence: $EvidenceName and the formal00receipt. Known baseline import/exit notes: $($fiveKnown -join '; ')
"@
[IO.File]::WriteAllText((Join-Path $fiveBuild 'README.md'),$fiveReadme,[Text.UTF8Encoding]::new($false))
$fiveIdentity = [ordered]@{version_id=$BuildName;phase='BETA_PHASE_3_FIVE_LEVEL_3D_UNIFICATION';source_commit=$fiveManifest.head;package_kind='SOURCE_PLAYABLE_NOT_EXE';engine=$fiveManifest.godot_version;levels=$fiveExpectedIDs;L04='3D_FORMAL_PLAYABLE';L05='3D_FORMAL_PLAYABLE';isolated_save="user://beta_sprint/$BuildName/qa_progress.json";human_qa='NOT_RUN';first_time_L03='RETEST_PENDING';art_source_changes='NONE';foundation_changes='NONE';old_QA_results_transferred=$false;focused_evidence=$EvidenceName;prior_CONTENT02_archive=$fivePriorZip;prior_CONTENT02_archive_SHA256=(Get-FileHash -LiteralPath $fivePriorZip -Algorithm SHA256).Hash.ToLowerInvariant()}
$fiveIdentityText = $fiveIdentity | ConvertTo-Json -Depth 6
[IO.File]::WriteAllText((Join-Path $fiveBuild 'QA_BUILD_IDENTITY.json'),$fiveIdentityText,[Text.UTF8Encoding]::new($false))
[IO.File]::WriteAllText((Join-Path $fiveCache 'QA_BUILD_IDENTITY.json'),$fiveIdentityText,[Text.UTF8Encoding]::new($false))
Add-Type -AssemblyName System.IO.Compression.FileSystem
[IO.Compression.ZipFile]::CreateFromDirectory($fiveBuild,$fiveZip,[IO.Compression.CompressionLevel]::Optimal,$true)
$fiveArchive = [ordered]@{zip=$fiveZip;sha256=(Get-FileHash -LiteralPath $fiveZip -Algorithm SHA256).Hash.ToLowerInvariant();bytes=(Get-Item -LiteralPath $fiveZip).Length;source_commit=$fiveManifest.head;version_id=$BuildName}
[IO.File]::WriteAllText((Join-Path $fiveCache 'qa_archive.json'),($fiveArchive | ConvertTo-Json),[Text.UTF8Encoding]::new($false))
Write-Output "BETA_FIVE_LEVEL_3D_QA_BUILD: $fiveBuild"
Write-Output "SOURCE: $($fiveManifest.head); ZIP_SHA256: $($fiveArchive.sha256)"
