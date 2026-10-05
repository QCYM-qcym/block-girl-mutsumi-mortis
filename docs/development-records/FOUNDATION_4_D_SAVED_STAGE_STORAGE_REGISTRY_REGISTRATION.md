# FOUNDATION-4 D_SAVED Stage Storage Registry Registration

Status: D_SAVED_STAGE_STORAGE_REGISTRY_RECEIPT_READY
Production D_SAVED: 4f2cfd4cba11677fe3dae6fa3dd66a4148e15e11
Previous D_SAVED: 8289d804c3b5b42a2e6c2cf76e965679a0f83af8
Previous receipt: dd3cc6db6a27b7d843bc87ca5d70dbef550656f2
D_PROTOCOL: 8f7fb52f029053bda10b965da840c6763fc13bf0
Protocol receipt: 342a51f463697caf8953a56591ee1a16ecd1e02f
Closure approval: 536faf950cedd30a04172ae5744ecfde09fbdf97
Validation support: 5749b932f947c44b35f21c62478bd76720e32969
Validation support registration: TEST_DEPENDENCY_ONLY
Validation support is not a new D_SAVED production delivery.

## Git and ownership

4f2 is an ancestor of 5749. The three-file validation commit changes only the D2 test, archived historical input.ready and its provenance README. It modifies no production or frozen specification/plan. Common ancestor with Integration was 6b7597ae2a6f77a882717581a63775f26cc1381e; differences were disjoint. ff-only could not proceed, so an authorized normal merge produced ac3ae7f58020505d114976a5772fc3ae21dc7f34.

Production hashes are preserved:
- execution_project.gd: 743a3b1a70f42e2f8b185847c45ed21bba60211df0d1fbc4a45de53ca6c62cb6
- canonical_loader.gd: 4f9b0785ae42fa726cd6053b1b1e475bab5c2216fd04011d0ca25d7922cfc904

The D_SAVED delivery keeps all seven paths and their 4f2 blob hashes. In particular its historical test hash remains 6285a49ee40f8e40156bf68a74bd4f1ab24710d5ca9e741b6fa77713265a421a. The current test checkout is explicitly supplied by validation support:
- tests/foundation/authoring_acceptance/test_saved_snapshot.gd: be6b8e6040cbfdb5d1b9201ba54d7bdc5477e1c79685e138ba459b69f7d2167e
- tests/foundation/authoring_acceptance/fixtures/legacy_814a/input.ready: 134c9495d5d38345c8b9ddf9f7b5cc06d84c5825fca07e22408ec354589cb2ed
- tests/foundation/authoring_acceptance/fixtures/legacy_814a/README.md: 85d6e068f6127407f925ef5b3fceb0527792b6feffad3e77b68045facd599839

This reuses the existing exact-commit/blob/checkout documentary test-dependency mechanism. No new slot, candidate receipt schema or generic hash bypass is introduced. A test-only adapter verifies the original delivery blob and the exact authorized support commit, all three support blobs and checkout hashes. The public Harness, I_HARNESS version binding and case_manifest remain unchanged. Consumers testing this supported checkout must use the exact validation adapter for D_SAVED's revised test and the previously registered D_HOST loader candidate; the ordinary unadapted Harness remains strict.

## Contract behavior

Closure is BASE_PROTOCOL_STRICT (seven unconditional dependencies) + AUTHORING + BAKE + MANUAL_RUNTIME. INTENT_BIND is NOT_REQUESTED. Real Binder source presence is allowed; neither Binder nor UID enters sealed files, execution manifest/project or execution versions digest. Registry producer identity remains registered. Requested/current missing dependency negatives still reject.

Current VersionsRecord retains the complete 8f7 registry, including stage_storage=foundationstagestorage.v1, graph_archive=stategraph.v1, intent=puzzleintent.v1 and trace=solutiontrace.v1.

Source Intent:
- Explicit Empty: nonnull d7ad650dae8d280831bd3022df051f5b81b738343096516e87497a5e53e42387
- Missing: null
- Invalid: publication rejected
- SnapshotIdentity: unchanged four fields

The exact historical 814a input.ready is retained. Env override and archived fixture both undergo the same pinned hash, missing registry key, formal schema rejection and immutable-byte checks; absence/corruption cannot pass automatically.

## Verification

Owner support version: Unit 361/361 and Real 390/390, exit 0, failures=[], stderr empty, doubles=[].
Fresh Integration checks are recorded below after completion.
D1 code is unchanged; reuse Owner 3698/3698 and fresh Integration dsr_d1_20261005_01 (3698/3698, exit 0, stderr 0). No additional D1 run in this registration.

## Scope and downstream handoff

Only D_SAVED is updated. BASE, I_HARNESS, A_SCHEMA, A_BAKE, C_QUALITY, D_PROTOCOL and formal D_HOST retain their prior facts. No A_EDIT, D_JOBS, B_EDITOR or D_FULL slot is registered.

D_HOST formal slot: b9bf7d4a02398cd354fab6a18948babaa22c531e
Existing D_HOST loader candidate remains PHASE_EVIDENCE_ONLY / TEST_DEPENDENCY_ONLY on the latest D_SAVED lineage, not a D_HOST PASS.
After GREEN registration:
- D_HOST: READY_FOR_FINAL_COMPATIBILITY_GRAPHICAL
- 4A-4: READY_FOR_REAL_CURRENT_D_SAVED
- D_JOBS: READY_FOR_CURRENT_D_SAVED_EXECUTION where actual selected dependencies exist
- I1: FROZEN_PASS; test/fixture unchanged and not run
- I2: not started
- Push: NOT_RUN
## Fresh Integration evidence (2026-10-05T22:29:31.6067513+08:00)

- I0: dr_i005, 15/15, exit 0. Its existing isolated result/exit fault-injection children are Harness Unit instrumentation, not product algorithm doubles.
- Boundary: E:/godot/foundation-4-stage-result-registration-20260927/dr_bound05/checks.json, 32/32, exit 0. Includes actual D_SAVED + D_HOST receipt resolution, exact support acceptance and rejection of wrong production commit/production file overrides. Expected negative CLI outputs remain in raw evidence.
- D2 Unit: dr_u05, 361/361, failures=[], exit 0, stderr 0 bytes, doubles=[]; env unset, committed exact historical fixture used.
- D2 Real: dr_r05, 390/390, failures=[], exit 0, stderr 0 bytes, doubles=[]; explicit FOUNDATION_D2_LEGACY_RUN uses original historical evidence.
- D1: prior unchanged-code Integration dsr_d1_20261005_01 3698/3698 reused; not rerun.
- Legacy registry: REJECTED; archived and original input.ready hashes unchanged.
- Current registry, source-intent empty/missing/invalid, actual missing dependencies, real Binder source/exclusion and formal A_BAKE/controlled Host checks remain GREEN.
- Independent read-only review: no Important/Critical findings.
- I1 files/maps equal frozen commit 14936504ae4245cc1822786937f021afce4a7fd9. No I1 or D_HOST Graphical run.

Reproducible test-only validation adapter:
.godot/dsaved-source-intent-registration-20261004/run_registry_validation.ps1
SHA-256: 148d05845825db7acdec8223a7f299b5b7a05ae6e716b053a1365ce44c6ee3ff
Boundary:
.godot/dsaved-source-intent-registration-20261004/verify_final_registry_boundaries.ps1
SHA-256: 0117557dcc7e952a950be6a1d2658f8c00652a90d41eae5ef7b39b752057ed1c

Copies and receipt evidence are archived in E:/godot/foundation-4-dsaved-registry-registration-20261005/. These are test infrastructure/evidence only and are not product ArtifactRef paths.

Commands:
pwsh -NoProfile -File tests/foundation/authoring_integration/run_module.ps1 -Module Integration -Case I0 -Mode Unit -EvidenceName dr_i005
pwsh -NoProfile -File .godot/dsaved-source-intent-registration-20261004/verify_final_registry_boundaries.ps1 -RunName dr_bound05
pwsh -NoProfile -File .godot/dsaved-source-intent-registration-20261004/run_registry_validation.ps1 -Module 4D -Case 4D-2 -Mode Unit -EvidenceName dr_u05
pwsh -NoProfile -File .godot/dsaved-source-intent-registration-20261004/run_registry_validation.ps1 -Module 4D -Case 4D-2 -Mode Real -EvidenceName dr_r05