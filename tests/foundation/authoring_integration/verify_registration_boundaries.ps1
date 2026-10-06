#requires -Version 7.4
[CmdletBinding()]
param([Parameter(Mandatory)][string]$EvidenceName)
Set-StrictMode -Version Latest
$ErrorActionPreference='Stop'
$root=[IO.Path]::GetFullPath("$PSScriptRoot/../../..").Replace('\','/')
$baseCommit='bd393303d3a21ae3ddebc6643a94a114437365a3'
$slots=@('BASE','I_HARNESS','A_SCHEMA','A_BAKE','A_EDIT','D_PROTOCOL','D_SAVED','D_HOST','D_JOBS','D_FULL','C_QUALITY','B_EDITOR')
$evidence=$null
if($EvidenceName -cnotmatch '^[A-Za-z0-9][A-Za-z0-9_-]{0,39}$'){throw 'Unsafe boundary evidence name'}
$directory="$root/.godot/foundation-authoring-tests/$EvidenceName"
New-Item -ItemType Directory -Path $directory -ErrorAction Stop | Out-Null
$tokens=$null; $parseErrors=$null
$ast=[Management.Automation.Language.Parser]::ParseFile("$PSScriptRoot/run_module.ps1",[ref]$tokens,[ref]$parseErrors)
if($parseErrors.Count){throw ($parseErrors | Out-String)}
# Load the shared functions; never run the CLI main or a product/I2 case.
foreach($f in $ast.FindAll({param($n) $n -is [Management.Automation.Language.FunctionDefinitionAst]},$false)){
    . ([scriptblock]::Create($f.Extent.Text))
}
$checks=[Collections.Generic.List[object]]::new()
function Verify([string]$Name,[scriptblock]$Probe){
    try{& $Probe; $checks.Add(@{name=$Name;passed=$true})}
    catch{$checks.Add(@{name=$Name;passed=$false;failure=$_.Exception.Message})}
}
function Must([bool]$Condition,[string]$Message){if(-not $Condition){throw $Message}}
function Must-Reject([scriptblock]$Probe){
    $rejected=$false
    try{& $Probe | Out-Null}catch{$rejected=$true}
    Must $rejected 'Invalid input was accepted'
}
$receiptPath="$PSScriptRoot/dependency_receipts.json"
$manifestPath="$PSScriptRoot/case_manifest.json"
$receipts=Read-Json $receiptPath
$manifest=Read-Json $manifestPath
Verify 'closed_manifest' {Assert-Manifest $manifest}
Verify 'closed_receipts' {Assert-Receipts $receipts}
Verify 'unknown_receipt_field_rejected' {$r=Read-Json $receiptPath; $r.bogus=$true; Must-Reject {Assert-Receipts $r}}
Verify 'candidate_is_not_a_delivery_slot' {
    $r=Read-Json $receiptPath
    $r.deliveries+=@{slot='D_JOBS_CORE_CANDIDATE';commit='2c1c4d1b5642c3060a013cabe836fefd9c9ced7e';paths=@(@{path='project.godot';sha256=Get-Sha "$root/project.godot"})}
    Must-Reject {Assert-Receipts $r}
}
Verify 'no_early_formal_slots' {Must (@($receipts.deliveries | Where-Object {$_.slot -cin @('D_JOBS','D_FULL','B_EDITOR')}).Count -eq 0) 'Formal slot was prematurely registered'}
Verify 'original_blob_hashes_still_bound' {
    foreach($d in $receipts.deliveries){
        Must (Is-Ancestor $d.commit) "Unintegrated $($d.slot)"
        foreach($p in $d.paths){Must ((Blob-Sha $d.commit $p.path) -ceq $p.sha256) "Receipt blob mismatch $($p.path)"}
    }
}
Verify 'saved_production_receipt_preserved' {
    $d=@($receipts.deliveries | Where-Object slot -CEQ 'D_SAVED')[0]
    Must ($d.commit -ceq '4f2cfd4cba11677fe3dae6fa3dd66a4148e15e11' -and $d.paths.Count -eq 7) 'D_SAVED changed'
    Must (($d.paths | Where-Object path -CEQ 'tools/foundation/authoring_acceptance/execution_project.gd').sha256 -ceq '743a3b1a70f42e2f8b185847c45ed21bba60211df0d1fbc4a45de53ca6c62cb6') 'Formal production hash was rewritten as Core'
}
Verify 'saved_validation_support_exact' {Assert-PhaseSource 'D_SAVED_VALIDATION_SUPPORT' | Out-Null}
Verify 'host_validation_support_exact' {Assert-PhaseSource 'D_HOST_VALIDATION_SUPPORT' | Out-Null}
Verify 'core_twelve_paths_exact' {$p=Assert-PhaseSource 'D_JOBS_CORE_CANDIDATE'; Must ($p.files.Count -eq 12 -and $p.status -ceq 'NOT_A_FORMAL_DELIVERY') 'Core scope/state changed'}
Verify 'multiple_phase_dependencies_recorded_as_array' {
    $evidence="$directory/phase-recording"
    New-Item -ItemType Directory -Path $evidence -ErrorAction Stop | Out-Null
    $probe=@{module='Integration';case_id='Boundary';required_slots=@('D_SAVED','D_HOST');script='res://tests/foundation/authoring_integration/test_suite.gd';entry='SCENE_TREE'}
    Must (@(Get-Missing $probe).Count -eq 0) 'Multiple phase dependencies did not resolve'
    $used=@(Read-Json "$evidence/phase-test-dependencies.json")
    Must ($used.Count -eq 5) 'Expected three saved and two host overrides'
}
Verify 'unknown_phase_rejected' {Must-Reject {Assert-PhaseSource 'D_JOBS'}}
Verify 'wrong_formal_commit_rejected' {Must-Reject {Resolve-PhaseSource 'D_SAVED' '2c1c4d1b5642c3060a013cabe836fefd9c9ced7e' 'tools/foundation/authoring_acceptance/execution_project.gd' '333c5a5da269b577f690f2d13df6ef429b10e283d697ee5d39f8f841406c7344'}}
Verify 'wrong_phase_hash_rejected' {Must-Reject {Resolve-PhaseSource 'D_SAVED' '4f2cfd4cba11677fe3dae6fa3dd66a4148e15e11' 'tools/foundation/authoring_acceptance/execution_project.gd' ('0'*64)}}
Verify 'unrelated_production_override_rejected' {Must-Reject {Resolve-PhaseSource 'D_PROTOCOL' '8f7fb52f029053bda10b965da840c6763fc13bf0' 'tools/foundation/authoring_acceptance/wire_schemas.gd' ('0'*64)}}
Verify 'obsolete_host_binding_rejected' {Must-Reject {Resolve-PhaseSource 'D_HOST' 'b9bf7d4a02398cd354fab6a18948babaa22c531e' 'tests/foundation/authoring_acceptance/test_whitebox_host.gd' 'ccbe1d7f33a6c00f634df2430d9d0aa0ade3ced47d896d1919704318713ee802'}}
foreach($key in @('4A/4A-4/Real','4D/4D-3/Graphical','4D/4D-4/Unit','4D/4D-4/Real','Integration/I1/Graphical')){
    $parts=$key.Split('/')
    $row=@($manifest.cases | Where-Object {$_.module -ceq $parts[0] -and $_.case_id -ceq $parts[1] -and $_.mode -ceq $parts[2]})[0]
    Verify "registered_dependencies:$key" {Must (@(Get-Missing $row).Count -eq 0) 'Receipt-qualified prerequisites not resolved'}
}
Verify 'a_edit_exact_formal_delivery' {
    $d=@($receipts.deliveries | Where-Object slot -CEQ 'A_EDIT')[0]
    Must ($d.commit -ceq '8a67282ac3022cb3d9b43e553424ed1aa3b2d7d2' -and $d.paths.Count -eq 10) 'A_EDIT scope changed'
    $probe=@{module='Integration';case_id='Boundary';required_slots=@('BASE','A_EDIT');script='res://tests/foundation/authoring/test_intent_binding.gd';entry='SCENE_TREE'}
    Must (@(Get-Missing $probe).Count -eq 0) 'A_EDIT exact checkout not resolved'
}
Verify 'i2_only_formal_djobs_pending' {
    $row=@($manifest.cases | Where-Object {$_.module -ceq 'Integration' -and $_.case_id -ceq 'I2' -and $_.mode -ceq 'Graphical'})[0]
    $missing=@(Get-Missing $row)
    Must ($missing.Count -eq 1 -and $missing[0] -ceq 'slot:D_JOBS') ('Unexpected I2 classification: '+($missing -join ','))
    Write-Json "$directory/i2-classification.json" @{status='DEPENDENCY_PENDING';missing=$missing;executed=$false}
}
Verify 'tampered_formal_blob_rejected_before_phase' {
    $receipts=Read-Json $receiptPath
    $d=@($receipts.deliveries | Where-Object slot -CEQ 'D_SAVED')[0]
    $d.paths[0].sha256='0'*64
    $probe=@{required_slots=@('BASE','D_SAVED');script='res://tests/foundation/authoring_acceptance/test_saved_snapshot.gd';entry='SCENE_TREE'}
    Must-Reject {Get-Missing $probe}
}
Verify 'i1_frozen_files_unchanged' {
    $changed=@(& git -C $root diff --name-only 14936504ae4245cc1822786937f021afce4a7fd9 -- tests/foundation/authoring_integration/test_saved_vertical.gd tests/foundation/authoring_integration/test_saved_vertical.gd.uid tests/foundation/authoring_integration/maps/a_empty)
    Must ($LASTEXITCODE -eq 0 -and $changed.Count -eq 0) 'Frozen I1 changed'
}
Write-Json "$directory/checks.json" $checks.ToArray()
$failed=@($checks | Where-Object passed -EQ $false)
$failed | Format-Table -Wrap
Write-Output "$($checks.Count-$failed.Count)/$($checks.Count) boundary checks passed"
if($failed.Count){exit 1}
