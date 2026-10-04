# FOUNDATION-4 D_PROTOCOL Stage Storage Registration

Status: D_PROTOCOL_STAGE_STORAGE_RECEIPT_READY
Contract mismatch: NONE
Recorded: 2026-10-04 (Asia/Shanghai)

## Authority and controlled history

Previous D_PROTOCOL: 814a1d7264140eec44a6b32752166832beb8ce75
Registered D_PROTOCOL: 8f7fb52f029053bda10b965da840c6763fc13bf0
Latest formal D_SAVED receipt before this registration: dd3cc6db6a27b7d843bc87ca5d70dbef550656f2
Pre-merge Integration: dd3cc6db6a27b7d843bc87ca5d70dbef550656f2
Canonical approval and common ancestor: 8fbf7743231c28400ec95c4069e23317ef0785d3
Controlled merge: 95b51533306638c7a0a6a902cd17235c6cbe3336
Clarification SHA-256: D87239EFA0FA0ED36BA80A4E5B072E8269B1969CF03B32FA50AD663E998657E8
Approval binding: CANONICAL_APPROVAL / DIRECT_GIT_ANCESTRY

The Integration worktree was clean at the latest D_SAVED receipt. ff-only was unavailable due to normal history divergence. Integration had no changes to the three incoming Owner paths since the common ancestor. The authorized normal merge preserved both histories and completed without conflicts. No reset, rebase, squash, cherry-pick or manual production copying was used. Approval and clarification bytes match the exact approved hash.

Only D_PROTOCOL's commit and three changed hashes are updated in dependency_receipts.json. Its complete ten-path inventory is retained and verified; all other slot records are unchanged. The candidate's three modified blobs exactly match the integrated files:

| Owner path | SHA-256 |
| --- | --- |
| tools/foundation/authoring_acceptance/wire_schemas.gd | 55ff3a3183f40152d70dd865e0e9535f1060b33e0d04c98becbcad72f411fbb0 |
| tools/foundation/authoring_acceptance/tool_wire.gd | a0f078ba1194293cc8430af373dd2f884c9e1c8ebd96572a801c3835abddd924 |
| tests/foundation/authoring_acceptance/test_tool_wire.gd | a431ef57d69fca97a9cde3e26a027ee2c4cf2b696787983993280fb2fddd88e2 |

## Registered protocol profile

Required stages: 10 / REGISTERED
Non-BAKE branches: 9 / REGISTERED
AUTHORING, BAKE, INTENT_BIND, INTENT_VALIDATE, ORIGINAL_GRAPH, SOFTLOCK, ABLATION, TRACE_SEMANTICS, MILESTONES, GRAPHICAL_REPLAY.
MANUAL_RUNTIME and D6 ARCHIVE remain UNDEFINED / OUT_OF_SCOPE; no storage branch is registered for them.

The sole closed top-level result remains foundationtoolwire.v1 / record_kind=stage_result. STAGE_RESULT WorkerMessage remains ArtifactRef-only. No stage_result FAILED enum or alternate result protocol was added.

BAKE: SUCCESS_REGRESSION_PASS / SUCCESS_BRANCH_UNCHANGED / ERROR_STORAGE_REGISTERED. Failure storage preserves actual non-null native returns, including Validator INCOMPLETE, and forbids successful canonical and graph attachments. Existing canonical.level, canonical ArtifactRef, content_hash and successful BAKE hash semantics are preserved.

Failure semantics: TASK_FAILED != WORKER_ERROR != STAGE_EXECUTION_ERROR != VALIDATOR_INCOMPLETE. IPC ERROR retains its closed code/message payload and is rejected as stage evidence. Storage performs structural validation without executing or replacing Owner algorithms.

| Helper record_kind | ArtifactRef format_version | Registry identity |
| --- | --- | --- |
| intent | puzzleintent.v1 | puzzleintent.v1 |
| trace | solutiontrace.v1 | solutiontrace.v1 |
| graph_archive | foundationtoolwire.v1 | stategraph.v1 |

intent is the formal bound intent and remains distinct from Track A source_intent; no source digest reconstruction or alternate canonicalization is introduced. ORIGINAL_GRAPH uses the approved graph archive mechanism. ABLATION uses only native_result.baseline.graph_archive_ref with the exact evidence mirror. SOFTLOCK and non-graph stages cannot attach graphs.

Mandatory VersionsRecord.schemas keys:
stage_storage=foundationstagestorage.v1
graph_archive=stategraph.v1
intent=puzzleintent.v1
trace=solutiontrace.v1

Missing, wrong, unsupported newer and unknown registrations reject under the closed schema. No defaults, silent migration or old-registry fallback. Existing registry keys, source_intent and foundationworkeripc.v1 remain unchanged.

## Fresh Integration evidence

Standard wrapper: tests/foundation/authoring_integration/run_module.ps1.

| Module / Case / Mode | EvidenceName | Checks | Failures | Exit |
| --- | --- | ---: | ---: | ---: |
| Integration / I0 / Unit | stage_storage_receipt_i0_20261004_01 | 15 | 0 | 0 |
| 4D / 4D-1 / Unit | stage_storage_receipt_d1_20261004_01 | 3698 | 0 | 0 |
| Boundary | stage_storage_receipt_boundary_20261004_01 | 28 | 0 | 0 |

D1 import/run/engine stderr are empty. D1 includes the original contract coverage, source_intent, seven inline Worker payload kinds, sequence/stage_id, ArtifactRef-only STAGE_RESULT, BAKE success and new stage/helper/mandatory-registry tests. It uses only the permitted in-memory BoundaryControl status provider; no algorithm double. I0 uses isolated result/exit fault-injection children and intentionally verifies rejected stderr/failing outputs.

Boundary reuses the already registered test-only phase adapter for the exact 8289 canonical_loader blob, because formal D_HOST's historical hash intentionally remains unchanged. No new adapter, shared wrapper change or gate relaxation was introduced. Existing adapter SHA-256: add94703b0ecfeefaf00761c0d5351e102ee9e2220f2926f0a4549c5499165be. Its boundary script is .godot/dsaved-source-intent-registration-20261004/verify_phase_boundaries.ps1. Boundary checks.json has 28 passing entries; the printed FAIL is the intentional aggregation-negative probe. Boundary's future-case probe executes zero D_JOBS checks; D2 dependency-resolution probes do not run D2 behavior. Evidence is under E:/godot/foundation-4-stage-result-registration-20260927/stage_storage_receipt_boundary_20261004_01/.

Owner RED/GREEN evidence was read from the original delivery worktree: baseline1583/1583; behavioral RED2527 checks/218 failures; supplemental RED3698/10; GREEN3698/3698, exit0, stderr empty. Fresh Integration D1 independently confirms the final count.

## Current dependency state and next handoff

D_SAVED: 8289d804c3b5b42a2e6c2cf76e965679a0f83af8
D_SAVED latest formal receipt: dd3cc6db6a27b7d843bc87ca5d70dbef550656f2
D_SAVED status: REGISTRY_FOLLOWUP_REQUIRED / EXPECTED_DEPENDENCY_UPDATE

8289 generated VersionsRecord against 814a; the four new mandatory keys require a follow-up from this latest formally registered D_SAVED lineage. This is not D_SAVED FAILED or a protocol regression. No D2 production edits or competing fork from old7cbdae. D2 Unit/Real, D3 Graphical and I1 Graphical were NOT_RUN this turn through the superseded registry.

D_HOST formal: b9bf7d4a02398cd354fab6a18948babaa22c531e
D_HOST compatibility candidate: 8289d804c3b5b42a2e6c2cf76e965679a0f83af8
canonical_loader SHA-256: 4f9b0785ae42fa726cd6053b1b1e475bab5c2216fd04011d0ca25d7922cfc904
D_HOST compatibility: D_HOST_COMPATIBILITY_VALIDATION_WAITING_FOR_CURRENT_D_SAVED_REGISTRY
Candidate retained; no formal D_HOST PASS or redelivery is registered.

D_JOBS implementation: READY_TO_RESUME / IMPLEMENTATION_READY
D_JOBS Real/end-to-end: WAITING_FOR_CURRENT_D_SAVED_IF_REQUIRED
Required Stage Storage is now registered; it no longer blocks D_JOBS implementation. No D_JOBS Real acceptance was run.
4A-4: WAITING_FOR_D_SAVED_REGISTRY_FOLLOWUP
I1: 14936504ae4245cc1822786937f021afce4a7fd9 / FROZEN_PASS
I2: NOT_STARTED
Next: D_SAVED_STAGE_STORAGE_REGISTRY_FOLLOWUP
Owner worktrees: unmodified by Coordinator
Push: NOT_RUN
