# FOUNDATION-4 D4 Required Stage Storage Clarification Approval Record

Status: APPROVED
Clarification path: docs/development-records/FOUNDATION_4_D4_REQUIRED_STAGE_STORAGE_CLARIFICATION.md
Clarification SHA-256: D87239EFA0FA0ED36BA80A4E5B072E8269B1969CF03B32FA50AD663E998657E8
Recorded at (UTC): 2026-09-29T11:20:25.664525+00:00
Authorization: exact-current conditional approval in the user request supplied as attachment 40361648-f9b9-40e7-aef9-2b8db005eedf; final readiness review satisfied.

Approval binds the exact bytes above. The clarification's historical REVIEW_REQUIRED/NOT_APPROVED text remains unchanged; this independent record establishes approval. All earlier review hashes, including A5F249..., 927C684... and 1B76C34..., are SUPERSEDED and are not approval targets.

## Reviewed scope and findings

Required stages: 10 / CONTRACT_READY_FOR_PROTOCOL_IMPLEMENTATION
AUTHORING, BAKE, INTENT_BIND, INTENT_VALIDATE, ORIGINAL_GRAPH, SOFTLOCK, ABLATION, TRACE_SEMANTICS, MILESTONES, GRAPHICAL_REPLAY.

BAKE: SUCCESS_BRANCH_UNCHANGED; FAILURE_OR_ERROR_STORAGE_BRANCH_REQUIRED; overall UPDATE_REQUIRED. Failure keeps its non-null exact native return, forbids canonical and graph attachments, and uses the frozen ERROR/INCOMPLETE/cancellation rules. No FAILED stage-result enum is introduced. Null means no actual return under the approved terminal rules, never discarded failure.

Failure semantics: TASK_FAILED != WORKER_MESSAGE_ERROR != STAGE_RECORD_EXECUTION_ERROR != VALIDATOR_INCOMPLETE. Clarification §§3/3.1/5/9 govern the distinct objects, exact ERROR payload, active-stage binding, stop-chain, natural return, EXIT/crash reconciliation, and full release gate. BUSY remains an occupied-slot rejection, not a FAILED terminal task. No notification releases the slot. Native domain results do not become infrastructure verdicts by storage-layer inference.

Non-BAKE branches: 9 / CONTRACT_READY: AUTHORING, INTENT_BIND, INTENT_VALIDATE, ORIGINAL_GRAPH, SOFTLOCK, ABLATION, TRACE_SEMANTICS, MILESTONES, GRAPHICAL_REPLAY.

Final review: §§3–9 uniquely specify input bindings, exact closed native types and failure rules, cancellation/nullability, terminal compatibility, attachment allowlists/forbidden outputs, output directories, format/length/SHA and whole-payload absolute-path rejection. Worker ERROR is not stage evidence; actual stage evidence must follow the formal stage_result publication chain. No Owner choice of representation remains within these required branches.

ORIGINAL_GRAPH archives its actual graph; ABLATION uses only native_result.baseline.graph_archive_ref with the exact evidence mirror; SOFTLOCK and other non-graph stages produce no graph attachment. Archives are read-only and never trusted live-graph reconstruction inputs.

## Helper wires and registry

| record_kind | ArtifactRef.format_version | Payload identity |
| --- | --- | --- |
| intent | puzzleintent.v1 | formal bound PuzzleIntent; not Track A source_intent |
| trace | solutiontrace.v1 | formal SolutionTrace |
| graph_archive | foundationtoolwire.v1 | StateGraph archive, graph_version=stategraph.v1 |

All use foundationtoolwire.v1 envelopes. Exact producers/consumers, inline equality and ArtifactRef rules are frozen in §§4–8.

| Mandatory VersionsRecord.schemas key | Exact version |
| --- | --- |
| stage_storage | foundationstagestorage.v1 |
| graph_archive | stategraph.v1 |
| intent | puzzleintent.v1 |
| trace | solutiontrace.v1 |

All four become mandatory together for the new formally registered current protocol profile. Missing/unknown/wrong/newer unsupported values reject; no fallback/default or additional digest. Historical sealed evidence remains immutable.

## Delivery boundaries

D_PROTOCOL: STAGE_STORAGE_UPDATE_REQUIRED
D_SAVED: REGISTRY_FOLLOWUP_REQUIRED_AFTER_LATEST_FORMAL_D_SAVED_RECEIPT
D_JOBS: BLOCKED_PENDING_PROTOCOL_UPDATE
C_QUALITY: UNCHANGED
I1: FROZEN_PASS
I2: NOT_STARTED
MANUAL_RUNTIME: UNDEFINED / OUT_OF_SCOPE
D6_ARCHIVE: UNDEFINED / OUT_OF_SCOPE

After the new protocol receipt, D_SAVED follow-up starts from the then latest formally registered D_SAVED. Preserve the 8289d804c3b5b42a2e6c2cf76e965679a0f83af8 source-intent/loader compatibility lineage; no competing fork from old 7cbdae. This approval registers no delivery slot and starts no implementation.

The 31 source hashes were rechecked and are TRACEABILITY ONLY. No Validator/Solver/Softlock/Intent/Trace/Milestone/Graphical algorithm or verdict changes. Real Graphical execution requirements remain unchanged.

Verification: exact clarification SHA matched; ten stage/nine non-BAKE classification checked; 31 source hashes matched; only clarification and this approval record are in commit scope. Production tests NOT_RUN (documentation-only approval). Production, tests, receipts, frozen Spec/Plans and I1 untouched. Push: NOT_RUN.
