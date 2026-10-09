param([string]$BuildName='', [string[]]$EvidenceNames=@(), [switch]$RequireClean)
$ErrorActionPreference='Stop'
$deliveryRoot=(Resolve-Path -LiteralPath (Join-Path $PSScriptRoot '../../..')).Path
$deliveryBaseline=Get-Content -LiteralPath (Join-Path $PSScriptRoot 'BASELINE_AUDIT.json') -Raw | ConvertFrom-Json
function Get-DeliverySha([string]$Path) { (Get-FileHash -LiteralPath $Path -Algorithm SHA256).Hash.ToLowerInvariant() }
$deliveryProtected=@($deliveryBaseline.protected_files | Where-Object { (Get-DeliverySha (Join-Path $deliveryRoot $_.path)) -ne $_.baseline_sha256 } | ForEach-Object {$_.path})
$deliveryArt=@($deliveryBaseline.approved_art_binding.rows | Where-Object { (Get-DeliverySha (Join-Path $deliveryRoot $_.project_relative)) -ne $_.expected_destination_sha256 } | ForEach-Object {$_.project_relative})
$deliveryOld=$deliveryBaseline.existing_08_source_build
$deliveryOldSources=@($deliveryOld.project_files | Where-Object { (Get-DeliverySha (Join-Path (Join-Path $deliveryOld.root 'project') $_.project_relative)) -ne $_.expected_sha256 } | ForEach-Object {$_.project_relative})
$deliveryQaInventory=@($deliveryBaseline.active_08_qa_inventory.files | Where-Object { (Get-DeliverySha $_.path) -ne $_.sha256 } | ForEach-Object {$_.path})
$deliveryRepos=@($deliveryBaseline.repositories.PSObject.Properties | Where-Object {$_.Name -in @('main','integration','content_06')} | ForEach-Object { [ordered]@{kind=$_.Name;root=$_.Value.root;expected_head=$_.Value.head;actual_head=(& git -C $_.Value.root rev-parse HEAD).Trim()} })
$deliveryFiles=@()
$deliveryList=Join-Path $PSScriptRoot 'FILES_SHA256.json'
if(Test-Path -LiteralPath $deliveryList){$deliveryFiles=@((Get-Content -LiteralPath $deliveryList -Raw | ConvertFrom-Json) | Where-Object {(Get-DeliverySha (Join-Path $deliveryRoot $_.path)) -ne $_.sha256} | ForEach-Object {$_.path})}
$deliveryCases=@()
foreach($deliveryName in $EvidenceNames){
    if($deliveryName -notmatch '^[a-zA-Z0-9_-]+$'){throw 'Invalid evidence name'}
    $deliveryRun=Get-Content -LiteralPath (Join-Path $deliveryRoot ".godot/beta-sprint/three-d-02/$deliveryName/run_report.json") -Raw | ConvertFrom-Json
    $deliveryMismatch=@($deliveryRun.sources | Where-Object {(Get-DeliverySha (Join-Path $deliveryRoot $_.path)) -ne $_.sha256} | ForEach-Object {$_.path})
    # The only allowed historical source delta is the exact importer-generated metadata restored to its frozen Git bytes.
    $deliveryImport=$deliveryBaseline.protected_files | Where-Object {$_.path -eq 'production/ui/beta_shell_01/icons_source.svg.import'}
    $deliveryMetadataRestorations=@($deliveryRun.sources | Where-Object {$_.path -eq $deliveryImport.path -and $_.sha256 -eq $deliveryImport.observed_physical_sha256 -and (Get-DeliverySha (Join-Path $deliveryRoot $_.path)) -eq $deliveryImport.baseline_sha256} | ForEach-Object {$_.path})
    $deliveryMismatch=@($deliveryMismatch | Where-Object {$_ -notin $deliveryMetadataRestorations})
    $deliveryBad=@($deliveryRun.stages | Where-Object {$_.exit_code -ne 0 -or -not $_.stderr_empty -or -not $_.stdout_clean -or ($_.checks -le 0) -or @($_.failures).Count})
    $deliveryCases += [ordered]@{name=$deliveryName;status=$deliveryRun.status;stages=$deliveryRun.stages;source_count=$deliveryRun.sources.Count;source_mismatches=$deliveryMismatch;exact_baseline_import_metadata_restorations=$deliveryMetadataRestorations}
    if($deliveryRun.status -ne 'PASS' -or $deliveryBad.Count -or $deliveryMismatch.Count){throw "Actual formal evidence is not GREEN/current: $deliveryName"}
}
$deliveryBuild=$null
if($BuildName){
    if($BuildName -notmatch '^[a-zA-Z0-9_-]+$'){throw 'Invalid build name'}
    $deliveryBuildRoot=Join-Path 'E:/godot/beta-sprint-builds' $BuildName
    $deliveryManifest=Get-Content -LiteralPath (Join-Path $deliveryBuildRoot 'build-manifest.json') -Raw | ConvertFrom-Json
    $deliveryBuildMismatches=@($deliveryManifest.files | Where-Object {(Get-DeliverySha (Join-Path (Join-Path $deliveryBuildRoot 'project') $_.path)) -ne $_.sha256} | ForEach-Object {$_.path})
    # Final receipt commits may change docs only; every non-doc payload must still be the tested delivery source.
    $deliveryCurrentSourceMismatches=@($deliveryManifest.files | Where-Object {$_.path -notlike 'docs/*' -and (Get-DeliverySha (Join-Path $deliveryRoot $_.path)) -ne $_.sha256} | ForEach-Object {$_.path})
    $deliveryQa=Get-Content -LiteralPath (Join-Path $deliveryBuildRoot 'QA_BUILD_VERIFICATION.json') -Raw | ConvertFrom-Json
    $deliveryBuild=[ordered]@{root=$deliveryBuildRoot;head=$deliveryManifest.head;source_files=$deliveryManifest.files.Count;copied_mismatches=$deliveryBuildMismatches;current_source_mismatches=$deliveryCurrentSourceMismatches;zip=$deliveryBuildRoot+'.zip';zip_sha256=(Get-DeliverySha ($deliveryBuildRoot+'.zip'));qa=$deliveryQa}
    if($deliveryBuildMismatches.Count -or $deliveryCurrentSourceMismatches.Count){throw 'Copied build/current delivery source mismatch'}
    if($deliveryQa.status -notin @('PASS','PASS_WITH_KNOWN_BASELINE_P2') -or $deliveryQa.head -ne $deliveryManifest.head){throw 'Unverified or mismatched new QA build status'}
}
$deliveryStatus=@(& git -C $deliveryRoot status --porcelain)
$deliveryResult=[ordered]@{head=(& git -C $deliveryRoot rev-parse HEAD).Trim();branch=(& git -C $deliveryRoot branch --show-current).Trim();working_tree=$deliveryStatus;protected_count=$deliveryBaseline.protected_file_count;protected_mismatches=$deliveryProtected;approved_art_rows=$deliveryBaseline.approved_art_binding.row_count;approved_art_mismatches=$deliveryArt;old_08_project_files=$deliveryOld.project_file_count;old_08_project_mismatches=$deliveryOldSources;old_08_zip_unchanged=(Get-DeliverySha $deliveryOld.zip.path) -eq $deliveryOld.zip.sha256;old_08_qa_inventory_count=$deliveryBaseline.active_08_qa_inventory.file_count;old_08_qa_inventory_changes=$deliveryQaInventory;old_08_qa_interpretation='Snapshot; only08 may legitimately write. This task never writes old QA evidence/profile.';repositories=$deliveryRepos;delivery_file_mismatches=$deliveryFiles;formal_cases=$deliveryCases;build=$deliveryBuild;human_qa='NOT_RUN_FOR_NEW_BUILD';push='NOT_RUN';stairs_clearance='PARTIAL_PASS';stairs_traversal='NOT_RUN'}
$deliveryResult | ConvertTo-Json -Depth 18
if($deliveryProtected.Count -or $deliveryArt.Count -or $deliveryOldSources.Count -or -not $deliveryResult.old_08_zip_unchanged -or $deliveryFiles.Count -or @($deliveryRepos | Where-Object {$_.kind -in @('main','integration') -and $_.actual_head -ne $_.expected_head}).Count){throw 'Protected delivery baseline mismatch'}
if($RequireClean -and $deliveryStatus.Count){throw 'Feature working tree is not CLEAN'}
