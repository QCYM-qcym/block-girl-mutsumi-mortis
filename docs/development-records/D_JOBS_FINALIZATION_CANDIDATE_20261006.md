# D_JOBS Finalization candidate — 2026-10-06

D_JOBS_DELIVERY_READY: NOT_ISSUED
D_JOBS_FINALIZATION_CANDIDATE_READY
CONTRACT_MISMATCH: NONE in production wire/API contracts
HARNESS_REGISTRATION_PENDING: current finalization source authorization

Candidate commit: 7836de52866255dd6f9684214b014d9703e7854d
Core base: 2c1c4d1b5642c3060a013cabe836fefd9c9ced7e
Consumed receipt: 9d23882638d2c491d68d58cbc360c3e60f56a894 (clean ff-only)
Working tree: CLEAN
Push: NOT_RUN

| Validation | checks | failures | exit | evidence |
| --- | ---: | ---: | ---: | --- |
| D_JOBS Unit | 490 | 0 | 0 | djf_uc |
| D_JOBS Real | 395 | 0 | 0 | djf_rz |
| D_JOBS Graphical | 117 | 0 | 0 | djf_cb (committed LF blob) |
| D_PROTOCOL registered Harness | 3698 | 0 | 0 | djf_dc |
| D_SAVED fixed-profile Unit, isolated staging | 361 | 0 | 0 | .godot/djr6/project/.../dfu |
| D_SAVED fixed-profile Real, isolated staging | 390 | 0 | 0 | .godot/djr6/project/.../dfr |

Final validation total: 5451 checks. Real/Graphical doubles=[]; stderr empty. Unit declares only owned_worker_fixture clock/capture/process port; D1 declares process-local BoundaryControl provider. Evidence/logs stay ignored; no product JSON sidecar. Final graphical count and exit to be read before issuing this candidate report.

## Actual chains

HEADLESS Binder: AUTHORING → BAKE → INTENT_BIND, 39 case checks, actual PID33768, COMPLETED; all four release booleans true.
HEADLESS Quality: AUTHORING → BAKE → INTENT_BIND → INTENT_VALIDATE → ORIGINAL_GRAPH → SOFTLOCK → ABLATION → TRACE_SEMANTICS → MILESTONES, 99 case checks, actual PID33236, COMPLETED; all four release booleans true.
Real395 also retains Core81 checks and covers empty constraints/milestones and budget-limited original graph: unexecuted parent records without fabricated IPC; native INCOMPLETE does not invent infrastructure FAILED.
GRAPHICAL adds GRAPHICAL_REPLAY through TaskService.replay_run in the sealed project, formal Replayer, actual Session/Presenter/natural Tween, MATCH, one selected original trace step, exact expected/actual statekey.v1. Selected trace is never Ablation baseline/witness.
BUSY/independent sequence/renewal/expiry/cancel/race/four-condition release/old-launch rejection/stage-scoped closure remain PASS through Core regression.
No algorithm doubles in Real. No copied algorithm/verdict or public schema/spec/other Owner production modifications.

## Review and rulings

Fresh review identified batch-result loss, aggregate deadline, NOT_APPLICABLE infra failure and native-INCOMPLETE-to-FAILED. One fix pass retains one actual native call per accepted start/result, C-owned terminal adapter, original live graph only for Softlock, independent formal Ablation, exact scoped attachments and actual millisecond start.
Superseded ruling: C batch/delayed retrospective IPC is rejected by approved storage§3. Final code does not call the batch workflow. D4 orchestrates public native APIs; original C algorithms and C terminal adapter remain unchanged.
Ruling: parent and worker scheduling eligibility is fixed by approved prerequisites and actual same-run returned records. NOT_APPLICABLE/NOT_RUN stay in parent memory; no manufactured native result or storage envelope. Cost if wrong: missing applicable work could be incorrectly omitted; empty-constraint and budget-limited actual Real chains cover these paths.
Ruling: ANALYZE_CURRENT demo selects the ten current algorithm/prerequisite stages, excluding D6 ARCHIVE; never claims ACCEPT_SAVED/D_FULL. Cost: this delivery cannot substitute for full authoring-tool acceptance.
Ruling: same registered SceneTree entry is used directly for behavioral evidence while shared Harness remains frozen to Core. Cost: these counts cannot claim receipt-qualified D_JOBS formal delivery until Coordinator updates authorization.
Deferred minors: NONE reported by reviewer.

RED evidence includes djf_red2 (462/3), storage real171/3 and graphical52/3, review accounting465/1, timeout-cause478/1, worker deadline490/1, replay API479/1, public replay record112/3. Every cited behavioral RED had genuine assertion failures and clean stderr; compile/gate attempts are excluded.

## Formal Harness blocker

Current official run_module 4D/4D-4/Unit, evidence djf_gate_final: exit1, checks0. Diagnostic:
CONTRACT_MISMATCH: D_SAVED checkout differs: tools/foundation/authoring_acceptance/execution_project.gd (outside exact phase authorization)
This is the old 2c phase-source authorization, not a new wire/API mismatch. No shared manifest/receipt/wrapper modifications. Coordinator must bind final candidate7836 before final unified Unit/Real/Graphical runs. No missing Quality/Replayer production module is invented.

## Files/SHA-256 (physical bytes match committed blobs)

| Path | SHA-256 |
| --- | --- |
| `tests/foundation/authoring_acceptance/test_task_lifecycle.gd` | `21d1cc7d30180f366a090d8df6bea953da8768edfca1e129e3da4eaae542d415` |
| `tools/foundation/authoring_acceptance/execution_project.gd` | `02d160f416a41da4d929d8a650a9e123e85eaa53a1b01755a7e6ded39e3f65ad` |
| `tools/foundation/authoring_acceptance/process_transport.gd` | `860c5cddf74b8842ad8edd2b8ac410ea122d1d3993ef80d2e391758291af452a` |
| `tools/foundation/authoring_acceptance/task_service.gd` | `b849431551b824bbb781cee89f99664e76bb3f09b0a6243b4293085390b9bcd2` |
| `tools/foundation/authoring_acceptance/worker_entry.gd` | `759164017b2b66cd7f9f2721260df12ced01aab06c1c8a4c378150368f39f7cc` |
| `tools/foundation/authoring_acceptance/graphical_entry.gd` | `08472a35fd31e5e635ca85c759c1993efba8a37ab35294a0b0a4aec81e97f835` |
| `tools/foundation/authoring_acceptance/graphical_entry.gd.uid` | `309b21e39a138dedd205eab8436202724f0f40e174a0a93a525da392b83caf22` |

Own diff: seven files, +557/-23; integration history was consumed through ancestry and is outside the candidate commit.
Final committed-blob Graphical djf_cb confirmed117/117, exit0, clean stderr, doubles=[], natural native MATCH. Git status CLEAN, staged/unstaged diff empty. No production contract mismatch; official Harness remains0checks awaiting phase authorization update.
