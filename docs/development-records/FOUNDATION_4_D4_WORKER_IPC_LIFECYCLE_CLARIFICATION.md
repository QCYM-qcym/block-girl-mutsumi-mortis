# FOUNDATION-4 D4 Worker IPC Lifecycle Clarification

Status: D4_WORKER_IPC_LIFECYCLE_CLARIFICATION_REVIEW_READY
Approval: NOT_APPROVED
Scope: proposed completion of previously deferred D4 transport/lifecycle contract only.
Baseline: Integration14936504ae4245cc1822786937f021afce4a7fd9; I1 is FROZEN_PASS.

## 1. Audit: authority and current capability

| Classification | Source | Finding |
| --- | --- | --- |
| APPROVED | Tool Contracts §6, 2026-09-22-foundation-authoring-tool-contracts.md | Six-field WorkerMessage; worker kinds HELLO/STAGE_STARTED/STAGE_RESULT/HEARTBEAT/EXIT/ERROR, parent CANCEL/LEASE; each direction single writer; immutable files, close/hash/rename; complete identity/order validation. Duplicate/gap/late messages are protocol problems. Single heavy slot, BUSY without queue, cooperative cancel and release confirmation. |
| APPROVED | Same §6, approved G5 details | Renewal1000ms, expiry30000ms, tool stage deadline300000ms; deadline is not a process reclamation guarantee. Original module budgets and128MiB/depth64 limits remain unchanged. |
| APPROVED | Worker protocol version clarification + independent approval879a5b07c4f878fc51b64f3728a1b80f6be267b8 | foundationworkeripc.v1 uniquely registered in wire_schemas.gd; common envelope unchanged; no permissive Dictionary or protocol-version fallback. |
| APPROVED | Stage Result clarification + approval74892ba39c283e24efbd0755e85e552b5a685784 | STAGE_RESULT uses ArtifactRef only; exact stage_result/BAKE branch, full identity/stage/hash binding, same-run paths and publication order, graph archive boundary. |
| PLAN_ONLY | 4D Runtime Plan4D-4; Integration Plan I2/I3 | task_service/process_transport/worker_entry/graphical_entry, real replay, plugin unload, cancel/late-result tests; functions and tests are planned, not proof of D_JOBS delivery. |
| IMPLEMENTED | D_PROTOCOL ef1b0b8a3a16b04037eb5ac49faaa55e296b31e8: wire_schemas.gd::_worker_message, tool_wire.gd::verify_stage_result | Strict protocol/common fields and STAGE_RESULT ArtifactRef; stateless length/hash/schema/identity checks. Other seven kinds return DEPENDENCY_PENDING. No stream cursor or lifecycle implementation demonstrated. |
| UNDEFINED before this draft | Cross-check above sources | Seven non-result payload shapes; first sequence, gaps/duplicates, restart/launch scope; non-stage stage_id. This document proposes exact rules below, not retroactive discoveries. |

Current D_SAVED=7cbdae3d0d04ed6b2dc8fc4d05eb6e49472b2664, D_HOST=b9bf7d4a02398cd354fab6a18948babaa22c531e. No I1 dependency slot is created. I1's six files and assertion semantics remain frozen; only future regression runs may consume them.

## 2. Unchanged envelope and shared scalar types

WorkerMessage remains exactly:
`{protocol_version:String, identity:RunIdentity, sequence:int, kind:String, stage_id:String, payload_ref_or_inline:KindPayload}`.

protocol_version is exactly the approved foundationworkeripc.v1 constant; canonical outer wire remains foundationtoolwire.v1 / record_kind=worker_message. RunIdentity/VersionsRecord/ArtifactRef/StoredStageRecord shapes are not extended. D4 must not add launch_id to RunIdentity or content identity.

All inline payloads below are exact closed dictionaries. All fields required; no unknown fields, duplicate dictionary keys, null, numeric coercion, StringName-to-String coercion or optional fields. int means wire integer, not JSON float. String enums are case-sensitive with no trimming. UTC means existing YYYY-MM-DDTHH:mm:ss.sssZ validation. UUID means existing canonical UUID validation. EngineIdentity means existing exact `{version:String, executable_sha256:String}` and approved engine/hash validation. Nonempty text means String with at least one non-whitespace character; bounded by existing wire limits, not an extra unapproved budget. No executable path enters EngineIdentity.

Registered StageId remains AUTHORING, BAKE, INTENT_BIND, INTENT_VALIDATE, ORIGINAL_GRAPH, SOFTLOCK, ABLATION, TRACE_SEMANTICS, MILESTONES, GRAPHICAL_REPLAY, MANUAL_RUNTIME, ARCHIVE. Enumeration does not register missing storage/native schemas.

## 3. Proposed closed payloads and direction

| Kind | Direction | Exact payload | stage_id |
| --- | --- | --- | --- |
| HELLO | Worker→Parent | `{launch_id:String(UUID), worker_role:String, engine:EngineIdentity}` | exactly empty String `""` |
| STAGE_STARTED | Worker→Parent | `{started_at:String(UTC)}` | registered StageId, the stage entering execution |
| HEARTBEAT | Worker→Parent | `{observed_at:String(UTC), phase:String}` | current active StageId, or `""` when none |
| EXIT | Worker→Parent | `{reason:String, exit_code:int, file_handles_closed:bool, callbacks_disconnected:bool, preview_resources_released:bool}` | exactly `""` |
| ERROR | Worker→Parent | `{code:String, message:String}` | current active StageId if any; otherwise `""` |
| CANCEL | Parent→Worker | `{reason:String}` | exactly `""`; cancellation is run-wide |
| LEASE | Parent→Worker | `{issued_at:String(UTC), valid_for_ms:int}` | exactly `""`; lease is launch-wide |

worker_role closed enum: HEADLESS / GRAPHICAL. HELLO.engine must equal identity.versions.engine AND the actual running executable version/hash. Before HELLO, worker recomputes actual execution VersionsRecord wire digest from the sealed project and compares identity.execution_digest. Parent compares full identity/expected role/launch nonce and engine; protocol-version equality alone is not compatibility.

HEARTBEAT.phase closed enum: IDLE / CALLING / CANCELLING / FINALIZING. CALLING requires active stage; IDLE requires no active stage. CANCELLING uses active stage until its terminal result is accounted for, then empty; FINALIZING requires no active stage. It reports boundary-observed state, not internal percentages. No periodic heartbeat promise during blocking synchronous calls; absence alone is not crash/lease proof. emitted observed_at cannot move backward within the worker stream; it is diagnostic, not lease renewal.

EXIT.reason closed enum: FINISHED / CANCELLED / FAILED / LEASE_EXPIRED. exit_code exactly0 for FINISHED/CANCELLED, exactly1 for FAILED/LEASE_EXPIRED. All three cleanup booleans must be true; otherwise do not issue EXIT yet. These attest only that worker's local owned resources (excluding the final message handle, closed by atomic publication) have been released. FINISHED means requested worker work returned and finalized; never acceptance PASS. EXIT does not by itself prove process termination or parent preview cleanup. Parent records actual process exit code separately and rejects a conflicting claim as execution error.

ERROR.code closed enum: EXECUTION_IDENTITY_MISMATCH / IPC_PROTOCOL_ERROR / STAGE_CALL_ERROR / STORAGE_ERROR / RESOURCE_RELEASE_ERROR. message is nonempty diagnostic text. This is a tool diagnostic, not replacement for a native status or for stage_result. No nested freeform dictionary or native-result injection. Protocol/state-machine violations use IPC_PROTOCOL_ERROR; storage failure uses STORAGE_ERROR. Receiving ERROR revokes PASS eligibility and stops later stages, while preserving real stage results. Multiple distinct diagnostics may be recorded, with unique valid sequence values.

CANCEL.reason closed enum: USER_CANCEL / PLUGIN_UNLOAD / EDITOR_SHUTDOWN / STAGE_TIMEOUT / PROTOCOL_ERROR. Parent always latches cancellation before publishing the command. USER_CANCEL and shutdown/unload preserve cancellation origin; STAGE_TIMEOUT records TIMEOUT/completion ERROR, PROTOCOL_ERROR records protocol execution error. Later causes may add diagnostics but cannot erase first cancellation provenance; final completion priority remains approved ERROR > CANCELLED > INCOMPLETE > COMPLETE. CANCEL is not a stop acknowledgment.

LEASE.valid_for_ms is exactly30000, not caller-configurable. issued_at is actual parent renewal publication time. Parent renewal cadence remains1000ms. No payload sets different budgets or deadlines.

## 4. Launch ownership and single-writer sequence domains

Proposed transport routing context: `(complete RunIdentity, launch_id, direction)`. launch_id is a parent-generated fresh UUID for one OS.create_process launch, passed as transport startup context and echoed in HELLO. It is not a new RunIdentity field, new fingerprint or parallel digest. Parent owns the exact returned PID and launch context; it never adopts a PID by name or numeric coincidence.

Each launch has immutable transport directories under its existing run root:
`ipc/<launch_id>/parent_to_worker/<sequence>.wire`
`ipc/<launch_id>/worker_to_parent/<sequence>.wire`.
Sequence filenames are canonical decimal integers (0 or nonzero digit followed by digits, no leading zeros). Decoder cross-checks filename with payload sequence and routing direction. launch_id and all path components are checked for escape/link/case ambiguity. Existing stage artifact paths stay artifacts/stages/<STAGE_ID>/... and remain run-relative; launch routing is not a cross-run ArtifactRef.

Parent task service is sole Parent→Worker writer. The one launched worker transport is sole Worker→Parent writer; computations/callbacks submit messages to that writer, never write files concurrently. Directory routing binds every message to the launch; HELLO nonce verifies the binding. A source-staging arbitrary ipc/test-bake.wire fixture is not a live D4 launch stream. Existing D1 stateless wire tests and archived D3 evidence are not relabeled as D4 handshake evidence.

Single heavy slot covers the entire run, including headless and subsequent graphical launch. A planned switch to another worker requires previous process exit AND local resource-release confirmation before the next OS.create_process. The new launch gets fresh launch_id and fresh pair of streams. This is a planned execution phase handoff under the same immutable run identity, not retry/recovery of failed computation. Existing stage IDs cannot be re-executed or overwritten within that run.

Abnormal restart/retry of a failed worker is prohibited in the same run: allocate new run_id/snapshot_id and capture through approved service; never resume trustworthy live graph from disk. Parent/editor restart creates a new editor_instance_id and new run. Former launches stay immutable evidence and are never attached to a new active stream. A planned handoff must preserve same-run canonical/trace bindings, and cannot reconstruct Softlock/Ablation live graph across processes.

## 5. Exact sequence and malformed-message behavior

For EACH launch and direction: initial expected_sequence=0, last accepted=-1. Parent first message must LEASE sequence0; child first must HELLO sequence0. Parent writes initial LEASE before launching the child. Worker validates initial lease and sealed execution context before HELLO and before any formal stage. Parent can send CANCEL sequence1 before HELLO; worker must observe it at its next boundary. No HELLO_ACK or START command is invented.

Sender increments by exactly1 after successful close/hash/atomic rename. Temporary files are ignored. A failed publication does not consume a sequence number; it can retry that not-yet-published number without overwrite. Rewriting a published file is forbidden. Receiver reads numeric ascending sequence, so filesystem enumeration order is irrelevant. When expected file is absent but a larger completed .wire exists, it is a GAP immediately, not a guessed missing heartbeat. Atomic one-writer publication makes this a real protocol defect; a later expected file does not heal it.

Acceptance requires: safe routing, exact wire/protocol/schema, full expected identity, expected direction, exact sequence, legal lifecycle/stage relation, then artifact integrity where applicable. Advance cursor once only after all pass. sequence is signed64-bit wire int0..9223372036854775807; negative rejected. Exhaustion cannot wrap; record protocol failure and stop. This adds a stream constraint, not a second content identity algorithm.

Duplicate: sequence below next expected, including identical bytes, is a protocol error, never replayed side effect and never treated as benign renewal. A poller does not repeatedly feed already-consumed immutable files to the receiver; it tracks consumed path+byte SHA. Seeing an already-consumed unchanged path in directory enumeration is not delivery again; replacement bytes at that path are tampering/protocol error. A new path with a reused payload sequence is also rejected.

Gap, duplicate delivery, wrong direction, invalid stage relation, bad hash or malformed current-launch message poisons that receive stream: no cursor advance, no further result acceptance, record IPC_PROTOCOL_ERROR, revoke PASS eligibility and stop-chain cooperatively. Parent requests cancel over its still-valid outbound stream; worker detecting corrupt parent stream stops itself at next boundary without requiring a valid CANCEL. Do not reinterpret malformed payload as a command. Subsequent bytes remain forensic evidence only; they cannot restore the poisoned stream or produce acceptance evidence. Cleanup/process observation continues independently; lack of trusted EXIT never authorizes early release.

Foreign/obsolete run or launch messages are quarantined diagnostics, never routed into the active run, never renewing its lease, advancing its cursor or overwriting results. They do not themselves change a different current run's state. Current-launch complete identity mismatch is a protocol failure. Wrong-direction examples: child CANCEL or parent HEARTBEAT are both rejected before effects.

## 6. Stage and message state transitions

HELLO exactly once per launch, first worker message; further worker messages require accepted HELLO. Duplicate HELLO with a fresh sequence is also invalid. If initial identity validation fails before HELLO, worker exits nonzero and parent records handshake failure/process evidence; do not fabricate a valid HELLO or permit ERROR-before-HELLO as bypass.

STAGE_STARTED applies only to a registered stage selected by the frozen run policy and assigned to this worker. No active stage may overlap. Parent tracks active stage and a run-wide set of already-started/terminal stage IDs. started_at is actual UTC time; it establishes the parent's stage deadline observation but never overrides a previously observed timeout/cancel. Parent cancellation immediately stops further parent scheduling and revokes PASS, but independent directional sequences do not establish when the worker observed CANCEL. A valid delayed STAGE_STARTED for already-assigned work may therefore be accepted as in-flight execution evidence while parent remains CANCELLING; it never restores publication eligibility. Worker must not start a new call after observing CANCEL, lease loss or a fatal error at its boundary. Parent must not infer that violation solely from cross-direction arrival order. Unassigned/repeated/out-of-order stages and starts after worker-stream ERROR/EXIT or completed finalization are rejected. A retained in-flight start allows its legitimate returned result to be accounted for under cancellation semantics. Unknown stage is schema error; registered-but-unavailable implementation/storage remains DEPENDENCY_PENDING and cannot be executed optimistically.

STAGE_RESULT is UNCHANGED: ArtifactRef only; complete run identity/stage/length/hash/canonical-wire validation, no inline result. It must correspond to exactly one accepted active STAGE_STARTED; stage_result.started_at must equal that start payload and its finished_at must obey existing rules. Terminal result clears active stage once. NOT_RUN does not generate a result. After cancel, already-started synchronous call may return a complete result; preserve it with correct CANCELLED/ERROR tool semantics and native result, never PASS. Do not suppress a real return to satisfy a null branch. Missing storage branch remains explicit pending; ERROR/storage diagnostics cannot pretend a result was published.

HEARTBEAT uses the currently observed active stage at emission, not an earlier or arbitrary one; stream order resolves a queued start/result before its heartbeat. ERROR stage is always the current active stage when one exists, otherwise empty; this identifies the interrupted execution context even for a transport/storage error, while payload.code identifies the cause. STAGE_CALL_ERROR additionally requires a nonempty active stage. A stage-specific ERROR does not silently clear the stage; publish available legitimate terminal evidence, or parent records missing evidence after actual exit. Cleanup-related EXIT may follow an unresolved stage only for FAILED/CANCELLED/LEASE_EXPIRED; parent records missing terminal evidence. FINISHED requires no unresolved stage and all launch-assigned work accounted for.

After EXIT, no new worker messages or stage work. Parent stops renewal once it accepts EXIT and observes cleanup, but keeps slot until actual process exit and parent cleanup are confirmed. Other direction is not an acknowledgment stream. Parent finalization cannot infer acceptance from exit_code0 or EXIT.reason alone.

## 7. Lease, cancellation and deadlines

Parent's initial lease is written immediately before launch. Worker reads every available command in sequence at each formal-call boundary. It does not renew by repeatedly reading the same file. A lease's expiry is issued_at+30000ms on the same machine UTC timeline, NOT arrival_time+30000 for a stale backlog. issued_at must be strictly later than the previous accepted lease, not in the future relative to receive UTC; rejected timestamps never extend the lease. Parent detects clock rollback and stops renewing/latches failure; worker detects its local UTC rollback at boundaries and fails closed. No cross-machine clock protocol is provided.

At every boundary, including initial startup, worker first drains available completed parent messages in sequence and validates the renewal history before deciding whether renewal was absent. Every CANCEL is processed; never skip intervening commands to take only the newest LEASE. Consecutive valid renewals must form continuous coverage: next issued_at must not exceed previous issued_at+30000ms. An actual gap in this chain permanently latches lease loss even if the latest message is fresh. A historical lease that has expired by receive time does not itself establish a gap when later queued renewals continuously cover that interval. After draining the batch, the latest validated lease must still be unexpired; otherwise latch lease loss. Thus a long synchronous call with uninterrupted parent renewals is not falsely cancelled on return. An already-observed loss is never revived by later messages.

For the latest validated lease, worker computes remaining=max(0, issued_at+30000-receive_UTC) and anchors that remaining duration to its monotonic clock at receive. Between drains, expiry checks use the earlier of that monotonic deadline and wall-clock expiry; at a formal-call boundary pending messages are drained before concluding that no renewal arrived. Timestamp rollback/future timestamps remain errors, not renewal. Implementation tests must inject timestamps/clocks through test-only seams, not change production intervals.

1000ms renewal is a scheduling target, not guaranteed execution under a stalled editor. Lease expiration permanently revokes publication eligibility and prevents next formal call; an in-progress synchronous Solver/quality/Replayer call may naturally return. No forced kill, no promise of bounded reclaim. HELLO/HEARTBEAT/EXIT never renew the parent lease. Worker may be unable to emit heartbeats while a synchronous call blocks; parent must not equate this with confirmed process death.

Cancel latches immediately in parent, revokes passing publication and later scheduling, enters CANCELLING. Worker checks durable CANCEL before and after every formal call. A queued cancel is not immediate interruption. Started work may finish and yield retained native evidence. Resource release requires process exit, file handles closed, callbacks disconnected, preview/resources released; every condition must be true, otherwise keep slot and cleanup state. Worker declarations plus OS observation alone do not prove parent-owned resources released. Missing EXIT after confirmed crash requires parent cleanup/evidence reconciliation, not invented worker confirmation. Unknown exit/release remains occupied indefinitely if necessary.

Stage scheduling deadline remains300000ms; on timeout request stop-chain, record TIMEOUT/completion ERROR, await natural call return and release. Do not rewrite Solver BUDGET_EXCEEDED, force-kill or raise limits until green. User-cancel provenance remains even when a later independent error raises completion priority. Plugin unload disconnects UI callbacks and leaves 4D cleanup service under editor root; re-enable reconnects to that same service. BUSY never queues.

## 8. Delivery impact, tests and remaining schema boundaries

D_PROTOCOL: UPDATE_REQUIRED. 4D alone implements these seven branches and scalar checks in the sole registry; process_transport/task_service own stream/direction/launch/lifecycle validation. Stateless codec validity does not authorize accepting a late message. Existing ef1b0b8 slot is not upgraded by this document. Update module hashes/VersionsRecord/execution_digest and deliver a new receipt through normal registration; no parallel version digest.

D_JOBS: BLOCKED_PENDING_APPROVAL; NOT_DELIVERED. This draft neither creates code nor authorizes implementation. D_SAVED execution closure must be reviewed when new entry/transport modules are delivered; this document does not silently extend its whitelist or change input.ready/SnapshotRef.

Non-BAKE stage-specific native storage branches remain separately unregistered under the approved Stage Result contract. This lifecycle draft does not freeze those branches or permit generic dictionaries. D4 can validate transport/BAKE and lifecycle Unit behavior, but Real quality/replay delivery must obtain each required branch's formal schema and actual dependencies before claiming D_JOBS complete. D_PROTOCOL lifecycle update is not D_PROTOCOL_FULL_IPC_READY for all possible stages.

Required future checks: all seven exact payload positive/unknown/missing/null/type/enum negatives; first0 and sequential increments; duplicate/tamper/gap/wrong direction/foreign identity; no side effects/cursor advancement on rejection; two planned sequential worker launches with no overlapping slot or stage replay; restart requires new run; HELLO actual engine/modules; pending storage rejection; CANCEL before start/during blocking call/after returned result; late valid result after cancellation cannot PASS; expiry/continuous renewal backlog after a call longer than30s/actual renewal gap/rollback; delayed STAGE_STARTED racing parent cancellation; EXIT alone insufficient; actual process exit and every resource condition; plugin unload/re-enable; parent death; true Replayer natural return without cancellation API. Tests-only workers/clocks may isolate Unit lifecycle; final Real/Graphical must consume formal modules with no algorithm double.

Test execution this turn: NOT_RUN (documentation only). No production, frozen Spec/Plans, receipt or I1 files changed by this track. No Owner task started. Commit: NOT_RUN. Push: NOT_RUN.
