param([string]$ProjectRoot=(Resolve-Path "$PSScriptRoot/../../..").Path)
$ErrorActionPreference='Stop'
$artSourceRoot='E:/Study/方块娘项目/若叶睦/model/art/production/releases/batch_05'
$assetIds=@('BG_CH_WAKABA_CUBE_001','BG_CH_MORTIS_CUBE_001')
foreach($world in @('SURFACE','INNER')) {
  foreach($kind in @('FLOOR','BRIDGE','ARCH','PILLAR')) { $assetIds+="BG_ENV_${world}_${kind}_001" }
  foreach($kind in @('PRESSURE_PLATE','GATE','WORLD_SWITCH','EXIT')) { $assetIds+="BG_MEC_${world}_${kind}_001" }
}
$assetFiles=@('VERTICAL_SLICE_ART_HANDOFF.md','reports/art_gate_approved.json','registry/mechanism_states.json','registry/mechanism_pair_contracts.json','mechanisms/mechanism_visual.gd','mechanisms/mechanism_config.gd','world_shift/reconstruction.gdshader')
foreach($kind in @('pressure_plate','gate','world_switch','exit')) { $assetFiles+="mechanisms/configs/$kind.tres" }
foreach($id in $assetIds) {
 $manifest=Get-Content -LiteralPath "$artSourceRoot/$id/reports/asset_manifest.json" -Raw | ConvertFrom-Json
 if($manifest.acceptance.art -ne 'PASS' -or $manifest.release -ne 'batch_05') { throw "Unapproved asset: $id" }
 $glbHash=(Get-FileHash -LiteralPath "$artSourceRoot/$id/export/$id.glb" -Algorithm SHA256).Hash.ToLowerInvariant()
 if($glbHash -ne $manifest.export.sha256) { throw "GLB mismatch: $id" }
 $assetFiles+="$id/export/$id.glb","$id/godot/$id.tscn","$id/reports/asset_manifest.json"
 foreach($texture in $manifest.texture_dependencies) { $assetFiles+=$texture }
 foreach($embeddedImage in Get-ChildItem -LiteralPath "$artSourceRoot/$id/export" -Filter '*.png' -File) { $assetFiles+="$id/export/$($embeddedImage.Name)" }
}
$bindingRows=foreach($relative in $assetFiles | Sort-Object -Unique) {
 $sourceFile=Join-Path $artSourceRoot $relative
 $destinationRelative="production/art_3d/$relative"
 $destinationFile=Join-Path $ProjectRoot $destinationRelative
 New-Item -ItemType Directory -Path (Split-Path $destinationFile) -Force | Out-Null
 $sourceHash=(Get-FileHash -LiteralPath $sourceFile -Algorithm SHA256).Hash.ToLowerInvariant()
 $adaptation='NONE'
 if([IO.Path]::GetExtension($relative) -in @('.tscn','.tres','.json')) {
  $original=[IO.File]::ReadAllText($sourceFile)
  $namespaced=$original.Replace('res://','res://production/art_3d/')
  if($original -ne $namespaced) { $adaptation='RESOURCE_NAMESPACE_ONLY'; [IO.File]::WriteAllText($destinationFile,$namespaced,[Text.UTF8Encoding]::new($false)) }
  else { Copy-Item -LiteralPath $sourceFile -Destination $destinationFile }
 } else { Copy-Item -LiteralPath $sourceFile -Destination $destinationFile }
 $destinationHash=(Get-FileHash -LiteralPath $destinationFile -Algorithm SHA256).Hash.ToLowerInvariant()
 if((Get-FileHash -LiteralPath $sourceFile -Algorithm SHA256).Hash.ToLowerInvariant() -ne $sourceHash) { throw "Source modified: $sourceFile" }
 $assetId=($relative -split '/')[0]
 $revision=$null; $contractRevision=$null
 if($assetId -in $assetIds) {
  $assetManifest=Get-Content -LiteralPath "$artSourceRoot/$assetId/reports/asset_manifest.json" -Raw | ConvertFrom-Json
  $revision=$assetManifest.revision; $contractRevision=$assetManifest.contract_revision
 }
 [ordered]@{asset_id=$assetId; source_asset=$sourceFile.Replace('\','/'); main_project_destination="E:/godot/若叶睦/方块少女-若叶睦/$destinationRelative"; project_relative=$destinationRelative; release='batch_05'; revision=$revision; contract_revision=$contractRevision; approval_status='APPROVED'; approval_authority='VERTICAL_SLICE_ART_HANDOFF.md section 1 (2026-10-06)'; source_sha256=$sourceHash; destination_sha256=$destinationHash; adaptation=$adaptation}
}
$bindingManifest=[ordered]@{task='PLAYABLE-ART-VERTICAL-SLICE-01'; source_root=$artSourceRoot; target_project='E:/godot/若叶睦/方块少女-若叶睦'; asset_count=$assetIds.Count; source_changes='NONE'; stairs_clearance='PARTIAL_PASS'; stairs_traversal='NOT_RUN'; gallery_runtime_imported=$false; mechanism_runtime_imported=$false; rows=@($bindingRows)}
$manifestPath=Join-Path $ProjectRoot 'docs/beta-sprint/playable-art-vertical-01/ART_ASSET_BINDING_MANIFEST.json'
[IO.File]::WriteAllText($manifestPath,(ConvertTo-Json -InputObject $bindingManifest -Depth 8),[Text.UTF8Encoding]::new($false))
$bindingRows | ForEach-Object { [pscustomobject]$_ } | Select-Object project_relative,source_sha256,destination_sha256,adaptation | Export-Csv -LiteralPath (Join-Path $ProjectRoot 'docs/beta-sprint/playable-art-vertical-01/ART_ASSET_BINDING_MANIFEST.csv') -NoTypeInformation -Encoding utf8
Write-Output "Bound $($assetIds.Count) approved assets; $($bindingRows.Count) files; source unchanged; no gallery/controller imported."
