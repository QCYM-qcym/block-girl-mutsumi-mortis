# FOUNDATION-4 D_SAVED Source Intent Registration

Status: D_SAVED_SOURCE_INTENT_RECEIPT_READY
Contract mismatch: NONE
Recorded: 2026-10-04T18:25:59.416899+08:00

## Owner delivery and controlled integration

Previous D_SAVED: 7cbdae3d0d04ed6b2dc8fc4d05eb6e49472b2664
Registered D_SAVED: 8289d804c3b5b42a2e6c2cf76e965679a0f83af8
D_PROTOCOL: 814a1d7264140eec44a6b32752166832beb8ce75
Pre-merge Integration: 8fbf7743231c28400ec95c4069e23317ef0785d3
Common ancestor: 67c0e21e5e1df86dd984d4d71d027e6ad2a12bc6
Controlled normal merge: 20b2525278ae959af75531436112a31597987afa

ff-only was unavailable due to ordinary documentation-history divergence. Owner paths had no Integration-side changes since the ancestor. Whole Owner commit merged normally with no conflict, history rewriting, copying or commit splitting. Its exact four-file diff matches the Owner delivery inventory. Three files are D2, one is the explicitly authorized D_HOST compatibility candidate. No Stage Storage protocol implementation entered this history.

| Incoming path | SHA-256 |
| --- | --- |
| tests/foundation/authoring_acceptance/test_saved_snapshot.gd | 076772487219ad11a6272f2448d6675c20a2ca88358d56df700c92960077ecbb |
| tools/foundation/authoring_acceptance/canonical_loader.gd | 4f9b0785ae42fa726cd6053b1b1e475bab5c2216fd04011d0ca25d7922cfc904 |
| tools/foundation/authoring_acceptance/execution_project.gd | cae8fe56fdfa4741fd733bb62258d8ee78fb199d83dfdad6c33c475a698f2c25 |
| tools/foundation/authoring_acceptance/snapshot_capture.gd | 82bce8ae48866872e4b22f28da205d86cd4421a57dc0a50a06d7c1f2639fce9b |

Owner evidence: E:/godot/worktrees/block-girl-foundation-runtime-saved-closure/.godot/dsaved-source-intent-delivery/delivery.json. Inventory hashes were checked against committed blobs. Existing GREEN evidence was audited: Unit221, Real250, D1 1583, D3 source-staging88, I1 88; all exit0, failures=[], raw stderr empty. Historical RED evidence is retained.

## Snapshot/source-intent audit

Capture projects the immutable AuthoringPayload through the registered 4D source_intent schema and sole ToolWire.digest; no parallel authoring hash. Missing Intent returns null, explicit empty returns a non-null digest, invalid authoring/closure fails before input publication. verify recomputes from validated sealed authoring and refuses wrong or missing caller digest. snapshot_from_run reconstructs then fully verifies the same sealed identity; no active worktree/ResourceLoader fallback. SnapshotIdentity retains exactly run_id/snapshot_id/source_fingerprint/source_intent_digest. Formal authoring/Reader/Baker/Codec unchanged.

Fresh Real action-capable explicit-empty digest: d7ad650dae8d280831bd3022df051f5b81b738343096516e87497a5e53e42387 (NON_NULL PASS). This digest is source-specific; a different empty Intent closure is not expected to have the same digest. Fresh D2 source-intent evidence covers missing=null, invalid publication rejection, closure changes and wrong-digest rejection. input.ready/source fingerprint/execution closure were genuinely verified. New packages use the current 814a registry, not Stage Storage's unregistered new registry.

## Formal versus phase registration

Only D_SAVED changes in dependency_receipts: commit plus the three modified D2 file hashes within its retained seven-path inventory. All other delivery records are byte-equivalent logical records to the prior receipt.

D_HOST formal slot: b9bf7d4a02398cd354fab6a18948babaa22c531e
D_HOST_SOURCE_INTENT_COMPATIBILITY_CANDIDATE: 8289d804c3b5b42a2e6c2cf76e965679a0f83af8
Registration: PHASE_EVIDENCE_ONLY / TEST_DEPENDENCY_ONLY
Purpose: SOURCE_INTENT_SNAPSHOTREF_LOADER_COMPATIBILITY
Candidate status: NOT_A_D_HOST_PASS

Candidate authority is the companion FOUNDATION_4_D_HOST_SOURCE_INTENT_COMPATIBILITY_REGISTRATION.md, reusing the earlier documentary D3 phase registration mechanism. No new formal candidate slot/system is introduced. D_HOST final91 compatibility remains NOT_RUN; D3 source-staging and frozen I1 regression are not a final D_HOST redelivery.

## Fresh Integration verification

Standard command for I0/D1/D2:
`pwsh -NoProfile -File tests/foundation/authoring_integration/run_module.ps1 -Module <module> -Case <case> -Mode <mode> -EvidenceName <name>`

| Module / Case / Mode | EvidenceName | Checks | Failures | Exit |
| --- | --- | ---: | ---: | ---: |
| Integration / I0 / Unit | dsaved_source_intent_i0_20261004_01 | 15 | 0 | 0 |
| 4D / 4D-1 / Unit | dsaved_source_intent_d1_20261004_01 | 1583 | 0 | 0 |
| 4D / 4D-2 / Unit | dsaved_source_intent_d2unit_20261004_01 | 221 | 0 | 0 |
| 4D / 4D-2 / Real | dsaved_source_intent_d2real_20261004_01 | 250 | 0 | 0 |
| 4D / 4D-3 / Graphical | dsaved_source_intent_d3_20261004_01 | 88 | 0 | 0 |
| Integration / I1 / Graphical | dsaved_source_intent_i1_20261004_01 | 88 | 0 | 0 |

All product import/run stderr empty. D3/I1 use Windows display and doubles=[]. D1 retains only its permitted BoundaryControl value-provider port. I0 intentionally injects stderr/failing child cases and validates rejection; this does not waive product stderr gates. D3 uses D3_SOURCE_STAGING_REGRESSION=1, not the historical final run. All five product source-copy inventories were checked against all four 8289 blobs.

The unmodified Harness strictly compares D_HOST's historical loader hash, so it cannot represent this authorized phase test dependency itself. A test-only adapter under .godot/dsaved-source-intent-registration-20261004/run_phase_compatibility.ps1 invokes the same Harness code with only a guarded checkout-hash exception for the exact approved candidate. It first retains the formal D_HOST committed-blob check; then verifies candidate ancestry/blob/checkout and companion registration. No slot, case dependencies, test gates or shared wrapper bytes were changed. The adapter logs the substitution as phase-test-dependency.json in I1 evidence. D3 has no D_HOST required slot; its original case classification remains unchanged.

D3/I1 command: `pwsh -NoProfile -File .godot/dsaved-source-intent-registration-20261004/run_phase_compatibility.ps1 -Module <module> -Case <case> -Mode Graphical -EvidenceName <name>`.
Adapter SHA-256: add94703b0ecfeefaf00761c0d5351e102ee9e2220f2926f0a4549c5499165be.
Its exact positive/negative gate checks: 5/5 PASS (authorized candidate; reject wrong slot, formal commit, path, SHA).

Original Boundary evidence: dsaved_source_intent_boundary_20261004_01, 27/28; registered_future_case failed because the strict D_HOST checkout lock rejected the loader candidate, not an Owner algorithm failure. All failed evidence is retained.
Phase-adapted Boundary: dsaved_source_intent_phase_boundary_20261004_01, 28/28 PASS, exit0. The same boundary suite changes only its test wrapper path to the exact candidate adapter. Its printed FAIL is the original intentional aggregation-negative probe; checks.json entries all passed. Evidence under E:/godot/foundation-4-stage-result-registration-20260927/. No production stderr failure was waived.

## Retained state and next handoff

I1: 14936504ae4245cc1822786937f021afce4a7fd9 / FROZEN_PASS; all six I1 test/fixture blobs unchanged.
Next protocol candidate: 8f7fb52f029053bda10b965da840c6763fc13bf0 / READY_TO_REGISTER_AFTER_THIS_RECEIPT; not merged or registered now.
Future registry follow-up must proceed from this new formally registered D_SAVED and any later formally registered successor. No second lineage from old7cbdae.
D_HOST final compatibility PASS: NOT_YET
A_EDIT / D_JOBS / B_EDITOR / D_FULL: NOT_DELIVERED
I2: NOT_STARTED
Owner worktrees: unmodified by Coordinator
Push: NOT_RUN
