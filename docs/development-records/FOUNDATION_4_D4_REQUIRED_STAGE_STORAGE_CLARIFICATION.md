# FOUNDATION-4 D4 Required Stage Storage Clarification

Status: REVIEW_REQUIRED
Approval: NOT_APPROVED
Classification: REQUIRED_STAGE_RESULT_STORAGE_CONTRACT_MISSING
D_JOBS_DELIVERY_READY: NOT_ISSUED

## 1. Authority and audited baseline

Integration receipt: 67c0e21e5e1df86dd984d4d71d027e6ad2a12bc6. D_PROTOCOL: 814a1d7264140eec44a6b32752166832beb8ce75. C_QUALITY: bb27f8c7cd6e2d9d94fbe3b8d3f98b99f86484d1. D_HOST: b9bf7d4a02398cd354fab6a18948babaa22c531e. I1: 14936504ae4245cc1822786937f021afce4a7fd9 / FROZEN_PASS.

This is a proposed storage contract, not approval or implementation. The gap is not a D_JOBS regression or a Worker lifecycle contract error. wire_schemas.gd::_stage_result rejects every non-BAKE stage with DEPENDENCY_PENDING; enumeration is not implementation. The approved lifecycle clarification §8 explicitly requires native storage branches before Real quality/replay delivery.

Authorities reread: Design Spec §§2,6–10,12; Tool Contracts §§2,5.2,6–9; 4D Runtime Plan 4D-4/4D-6; 4C Quality Plan public interfaces and 4C-1/2/3; Integration Plan public records/stage registry/I2; approved Stage Result clarification §§2–10 and approval; approved D4 lifecycle clarification §8. Frozen historical REVIEW wording does not revoke separate approvals. Source hashes at the end pin this audit.

Chosen representation: separate closed stage branches referencing the existing formal result types. Only graph fields are replaced with archival refs, as already required. Supplemental exact intent/trace attachments support controlled process inputs. Rejected: generic quality/replay result bags, stdout JSON, custom sidecars, BAKE reuse, a second algorithm or quality orchestrator.

## 2. Actual stage set and current registry matrix

Integration Plan's registry and current STAGES contain twelve IDs. ACCEPT_STAGES contains eleven, excluding MANUAL_RUNTIME; ANALYZE_CURRENT defaults to AUTHORING/BAKE/MANUAL_RUNTIME. These policy lists remain unchanged. Design §8 puts authoring/Bake/quality in headless execution and real graphical replay in a subsequent controlled graphical process. Runtime Plan 4D-4 delivers task execution/transport; 4D-6 delivers final report/archive.

The D_JOBS quality/replay route requires ten prerequisite/algorithm stages: AUTHORING, BAKE, INTENT_BIND, INTENT_VALIDATE, ORIGINAL_GRAPH, SOFTLOCK, ABLATION, TRACE_SEMANTICS, MILESTONES, GRAPHICAL_REPLAY. Nine storage branches other than BAKE are proposed below. Actual invocation depends on inputs and previous results; NOT_RUN/NOT_APPLICABLE never fabricate calls or STAGE_RESULT.

| stage_id | Formal Owner / producer | Existing native output | Current storage status |
| --- | --- | --- | --- |
| AUTHORING | 4A authoring_schema.validate_authoring | {ok,issues}, ToolIssue[] | DEPENDENCY_PENDING |
| BAKE | 4A authoring_adapter -> 2C Reader/Baker/Codec | six-field A_BAKE wrapper | PARTIALLY_REGISTERED |
| INTENT_BIND | 4A intent_binder.bind_intent; approved, A_EDIT not delivered | {ok,bound_intent,source_intent_digest,issues} | DEPENDENCY_PENDING |
| INTENT_VALIDATE | 3C intent_validation.validate via 4C | {ok,issues}, AnalysisIssue[] | DEPENDENCY_PENDING |
| ORIGINAL_GRAPH | 3A state_explorer.explore via 4C | seven-field SolverResult/SearchResult | DEPENDENCY_PENDING |
| SOFTLOCK | 3B softlock_analyzer.analyze via 4C | thirteen-field SoftlockAnalysisResult | DEPENDENCY_PENDING |
| ABLATION | 3C ablation_analyzer.analyze via 4C | seven-field IntentAnalysisResult; baseline embeds SolverResult | DEPENDENCY_PENDING |
| TRACE_SEMANTICS | 3A solution_trace.validate_semantics via 4C | {ok,transitions,issues} | DEPENDENCY_PENDING |
| MILESTONES | 3C milestone_analyzer.analyze_trace via 4C | seven-field MilestoneAnalysisResult | DEPENDENCY_PENDING |
| GRAPHICAL_REPLAY | 3D trace_replayer.replay invoked by 4D | eight-field RuntimeParityResult | DEPENDENCY_PENDING |
| MANUAL_RUNTIME | 4D WhiteboxHost over 2D Session/Presenter | ongoing capabilities/load/action observations; no terminal native stage contract | UNDEFINED |
| ARCHIVE | 4D-6 report_aggregator/archive_store, not delivered | planned report/publication, no exact implemented terminal native branch | UNDEFINED |

BAKE success/no-return storage is currently REGISTERED, but actual failed/incomplete native returns remain BAKE_FAILURE_STORAGE_SCHEMA pending. Therefore BAKE=UPDATE_REQUIRED under this revised proposal: success representation is unchanged, while the required failure branch is added in §5. The approved Stage Result §3/§4 and current _bake_storage do NOT authorize FAILED/null for an actual failure return. FAILED is not a stage execution value; null means no return, never discarded failure. The earlier A5F249B851CEA9E839D018CEDB7AEB9CF19F8CDA8C716ED5ADB989DE8AD02C09 draft did not meet approval conditions and is superseded for review, not approved.

Final proposed contract-readiness classification (not implementation/delivery status): the current registry matrix above is historical implementation evidence only. Its DEPENDENCY_PENDING/PARTIALLY_REGISTERED labels are not open choices in the following proposed contract. All ten contract classifications below are closed; implementation is still pending approval and Owner delivery.

| Required stage | Revised contract status |
| --- | --- |
| AUTHORING | CONTRACT_READY_FOR_PROTOCOL_IMPLEMENTATION |
| BAKE | CONTRACT_READY_FOR_PROTOCOL_IMPLEMENTATION |
| INTENT_BIND | CONTRACT_READY_FOR_PROTOCOL_IMPLEMENTATION |
| INTENT_VALIDATE | CONTRACT_READY_FOR_PROTOCOL_IMPLEMENTATION |
| ORIGINAL_GRAPH | CONTRACT_READY_FOR_PROTOCOL_IMPLEMENTATION |
| SOFTLOCK | CONTRACT_READY_FOR_PROTOCOL_IMPLEMENTATION |
| ABLATION | CONTRACT_READY_FOR_PROTOCOL_IMPLEMENTATION |
| TRACE_SEMANTICS | CONTRACT_READY_FOR_PROTOCOL_IMPLEMENTATION |
| MILESTONES | CONTRACT_READY_FOR_PROTOCOL_IMPLEMENTATION |
| GRAPHICAL_REPLAY | CONTRACT_READY_FOR_PROTOCOL_IMPLEMENTATION |

All ten use §§3–9 together for exact types, terminal/null behavior, input binding, output root, attachment formats and path rejection. Nine non-BAKE branches plus the BAKE failure extension are proposed; no extra stage is created. Approval remains required.

MANUAL_RUNTIME remains a real exclusive-slot interactive host; HELLO/HEARTBEAT/EXIT/ERROR lifecycle is not an algorithm STAGE_RESULT. This proposal does not invent a manual terminal verdict. Persisting one requires its own producer contract. ARCHIVE/report belongs to D6, not the D4 Real quality/replay demonstration. Unavailable ARCHIVE still prevents full ACCEPT_SAVED PASS; do not truncate its policy requirement. Parent records its missing evidence. D_JOBS is not D_FULL.

## 3. Unchanged envelope and common rules

Envelope remains ["foundationtoolwire.v1","stage_result",typed_value], exactly {run_identity:RunIdentity,stage_record:StoredStageRecord}. StoredStageRecord retains fourteen fields: stage_id,owner,module_ref,applicability,execution,reason,input_refs,actual_policy,actual_budget,native_result,evidence_refs,warnings,started_at,finished_at. WorkerMessage STAGE_RESULT remains ArtifactRef-only; foundationworkeripc.v1 unchanged.

Notation: S=String, N=StringName, I=int, B=bool, T?=T|null; [] is Array with native order preserved. All record fields below are mandatory and closed. Unknown/missing fields, unlisted nulls, aliases and implicit conversions reject. Explicit Map types allow only their stated key/value types; {} is exactly empty. UUID/digest/UTC/path domains use D_PROTOCOL. R=unchanged ArtifactRef {relative_path:S,byte_length:I>=0,sha256:lowercase64hex,format_version:S}.

Each executed new branch has applicability=APPLICABLE. NOT_RUN/NOT_APPLICABLE stay in parent RunEvidence/C memory output and produce no worker result. Stored execution remains COMPLETED/INCOMPLETE/ERROR/CANCELLED. FAILED is a task lifecycle name, not a wire execution enum; stage failure uses ERROR. RUNNING/FAILED reject.

COMPLETED requires non-null complete native return and reason="". Other terminal states require a nonempty actual tool reason. A returned result MUST be preserved, including after cancellation/deadline; only absence of return permits null. Null is allowed only after stage start for INCOMPLETE/ERROR/CANCELLED, with output refs null/empty. Pre-start cancellation and process crash do not justify a fabricated worker result. Malformed/unsupported actual returns cause explicit storage failure, never invented null. Cancellation cannot alter native status/counters/findings. Existing native ERROR outranks cancellation; completion never means PASS.

Timestamps remain actual UTC millisecond strings, ordered and bound to accepted STAGE_STARTED. D4 must preserve actual boundary observations; C's second-resolution strings do not justify invented precision or retrospective IPC. No C callback/API is added here; inability to prove existing lifecycle binding is a separate fail-closed implementation problem.

New branches' warnings are Array[ToolIssue] containing actual tool diagnostics, including matching-stage C output issues. Native warnings/findings stay native. Unassociated run diagnostics remain parent evidence for D6. No new warning/verdict algorithm is introduced; empty warnings means none actually returned. BAKE's existing warnings=[] restriction is unchanged.

### 3.1 Failure layers and lifecycle binding (existing authority, no enum change)

There are FOUR distinct objects, not three interchangeable status strings:

| Object | Field / value | Meaning and authority |
| --- | --- | --- |
| TaskService job | lifecycle=FAILED | Exceptional task termination after cleanup; Tool Contracts §6 and approved Lifecycle §§3,5–7 |
| Worker IPC notification | kind=ERROR | Tool/transport/stage-call error diagnostic; approved Lifecycle §3 |
| Stored stage evidence | stage_record.execution=ERROR | Stage execution/storage terminal classification; Stage Result §3 and this document §9 |
| Formal native algorithm result | e.g. validation.status=INCOMPLETE(2) | Original Validator/Quality domain semantics; Tool Contracts §7 |

“Stage wire ERROR” in this document means StoredStageRecord.execution=ERROR; it does NOT mean WorkerMessage.kind=ERROR. An ERROR message is not a stage_result, and stage_result has no top-level status=FAILED field. FAILED stage-result execution rejects. This proposal does not add that enum or relabel an actual native return to satisfy that spelling.

Task FAILED: actual execution/handshake/identity/protocol/storage/resource-release errors or stage scheduling TIMEOUT establish the exceptional failure path. Lifecycle ERROR codes remain EXECUTION_IDENTITY_MISMATCH, IPC_PROTOCOL_ERROR, STAGE_CALL_ERROR, STORAGE_ERROR, RESOURCE_RELEASE_ERROR. Native domain negative findings, native INCOMPLETE, or a stored ERROR classification alone are not a license for the storage adapter to invent an infrastructure failure or emit an IPC ERROR. Parent TaskService applies the approved lifecycle and summary rules to actual evidence, not a storage-layer verdict algorithm. Errors revoke PASS and prohibit later stage scheduling. An error observation does not imply an already-started synchronous call has stopped; let it return naturally and retain its result. Final lifecycle FAILED is published only after cleanup/release confirmation, not while that call/process/resources remain active.

Release gate remains process exited AND file handles closed AND callbacks disconnected AND preview/resources released, covering worker and parent ownership. In a cooperative normal error shutdown the worker publishes the existing EXIT(reason=FAILED, exit_code=1, all three cleanup booleans=true) after its local release. EXIT alone is insufficient. Confirmed crash or poisoned IPC can prevent a trusted EXIT; parent must reconcile actual process exit and independent resource cleanup evidence, never fabricate EXIT. Unknown release keeps the slot occupied; neither receipt of ERROR nor elapsed deadline frees it. No forced kill or bounded reclamation promise.

CANCELLED differs from FAILED: user/unload/shutdown cancellation first enters CANCELLING and revokes PASS; only release confirmation permits terminal CANCELLED. Preserve first cancellation provenance. Independent actual errors retain the approved completion priority ERROR > CANCELLED > INCOMPLETE > COMPLETE; cancellation cannot erase an error, nor does sending CANCEL acknowledge stop. Lease loss and TIMEOUT retain the already-approved lifecycle handling. This section creates no new lifecycle state or queue behavior.

Worker ERROR is a Worker→Parent foundationworkeripc.v1 message in the existing foundationtoolwire.v1 worker_message envelope. payload_ref_or_inline is exactly inline {code:String,message:String}, all fields required, no extra/null fields or ArtifactRef branch. code is exactly one of the five codes above; message is nonempty diagnostic text. Full identity/sequence/direction/HELLO validation applies. stage_id is the current active formal stage or exactly "" when none, never IPC/NONE/null. Receiving a valid ERROR stops subsequent formal stage calls and revokes PASS while preserving real evidence; it proves neither stage completion nor resource release. Current in-flight evidence/cleanup follow approved Lifecycle §6; an ERROR message is never a substitute for a non-null returned native result or its STAGE_RESULT ArtifactRef.

Validator INCOMPLETE is preserved in native validation.status with its actual issues/counters, and the BAKE incomplete branch uses execution=INCOMPLETE. It is not Worker IPC ERROR and does not automatically make the task infrastructure FAILED. Quality INCOMPLETE/budget/safety-unknown results keep their respective native values and §9 stage mapping. Final summary remains the existing Tool Contracts §7 / D6 responsibility: completion and verdict are separate, missing safety evidence prevents full PASS, and a determinate negative result is not universally an infrastructure failure. Storage supplies exact evidence only; no new task-final/verdict mapping is implemented here.

## 4. Existing formal types referenced by storage

These aliases reference existing Core and Solver/Quality contracts plus pinned producer source, not replacement algorithm semantics. D storage checks closed shape and binding; formal consumers still validate semantics. Unknown record fields reject.

- ValidationIssue={code:I,severity:I,path:S,message:S,details:DiagnosticMap,entity_ids:Array[N]}.
- AnalysisIssue={code:I,severity:I,path:S,message:S,details:DiagnosticMap,upstream:Array[ValidationIssue]}.
- ToolIssue={code:S,stage:S,path:S,message:S,source_refs:Array[SourceMap.Entry],upstream:Array[ValidationIssue|AnalysisIssue]}.
- DiagnosticMap is the existing formal details map, not an extension of native_result. Preserve originating diagnostics and their types; recursively no Object/Callable/live graph or machine absolute path. Existing formally dynamic diagnostic keys are not replaced with guessed fields. This does not permit arbitrary fields outside formal map-valued positions.
- StaticValidationResult={status:I,issues:Array[ValidationIssue],configurations_checked:I,checks_performed:I}; actual VALID/INVALID/INCOMPLETE and counters unchanged.
- SearchMetrics={explored_states:I,visited_states:I,generated_edges:I,duplicate_states:I,goal_states:I,max_depth_reached:I,solution_length:I?,action_evaluations:I,rejected_actions:I,no_op_actions:I,filtered_edges:I,safety_unproven_rejections:I,elapsed_ms:I,shortest_solution_count:I?,shortest_solution_count_complete:B}; preserve 3A nonnegative count/null rules.
- PolicyDescriptor={strategy:N,mode:I,validation_options:BakeBudget,filter_descriptor:{filter_id:N,filter_version:S,disabled_mechanics:Array[I]}}. Values follow search_records. The only SearchPolicy member excluded is the non-wire transition_filter Callable, not a native result field.
- BakeBudget={max_configurations:I>0,max_checks:I>0}; SearchBudget={max_states:I>0,max_edges:I>=0,max_depth:I>=-1,max_runtime_ms:I>=0,max_action_evaluations:I>0}; SoftlockBudget={max_nodes:I>0,max_edges:I>=0,max_runtime_ms:I>=0}; ReplayOptions={mode:I,max_steps:I>=0,max_runtime_ms:I>=0,step_timeout_ms:I>0}. Existing defaults/limits unchanged.
- PuzzleIntent={intent_version:S,intent_id:N,level_hash:S,rule_version:S,required_mechanics:Array[I],optional_mechanics:Array[I],expected_milestones:Array[MilestoneDefinition],forbidden_bypasses:Array[BypassConstraint]}. MilestoneDefinition={milestone_id:N,required:B,predicate:Predicate}; BypassConstraint={bypass_id:N,disabled_mechanics:Array[I]}; Predicate remains kind plus its exclusive formal branch payload from intent_validation. No source/provenance fields added.
- SolutionTrace={trace_version:S,level_hash:S,rule_version:S,policy_descriptor:PolicyDescriptor,initial_state:PuzzleState,initial_statekey:S,steps:Array[TraceStep],goal_statekey:S,total_actions:I,shortest:B}. TraceStep={index:I,action:PuzzleAction,expected_state:PuzzleState,resulting_statekey:S,global_kind:I}. Core PuzzleState/PuzzleAction closed unions and trace domains unchanged; zero-step trace legal.
- TransitionResult={status:I,previous_state:PuzzleState,next_state:PuzzleState?,action:PuzzleAction,changed:B,rejection_code:I,issues:Array[ValidationIssue],global_kind:I}; Kernel owns semantics.
- QualityFinding={code:I,severity:I,subject_ids:Array[N],scope:N,trace:SolutionTrace?,details:DiagnosticMap}. Existing details branches remain: MECHANIC_BYPASS {disabled_mechanics,required_mechanics,bypass_ids}; MILESTONE_BYPASS {sample_indices}; UNUSED_MECHANISM {mechanism_id,required_mechanics,optional_mechanics,observed_used}. No top-level verdict inferred.
- GraphPath={target_key:S,edge_ids:Array[I]}, not a replayable SolutionTrace.

Enum values/severity/version and cross-field rules remain with their original Owners. Named types are references, not new result classes. Native nested values remain inline except graph replacement. No generic quality_result/replay_result protocol is introduced.

For clarity, the referenced Predicate union is exactly: {kind:0,face_id:N}, {kind:1,layer:I}, {kind:2,light_state:I}, {kind:3,mechanic:I}, or {kind:4}; payload domains remain formal Face/Layer/LightState/MechanicTag, not authoring resource_ref. Core state/action nested fields and SourceMap.Entry are the existing closed contracts, not Dictionary escape hatches. The graph and trace archive wire validators may invoke existing shape helpers but must not rerun searches, recalculate verdicts or mutate results to establish storage validity.

## 5. Nine non-BAKE branches and required BAKE failure extension

### AUTHORING

owner="4A"; module_ref="res://foundation/authoring/authoring_schema.gd"; producer validate_authoring on captured immutable payload, not capture itself.
Native={ok:B,issues:Array[ToolIssue]}. ok=true -> COMPLETED; false -> ERROR. Graph archive FORBIDDEN. Extra output attachments none. Capture failure without run identity cannot produce this record.

### BAKE

owner="4A"; module_ref="res://foundation/authoring/authoring_adapter.gd". Producer remains the real A_BAKE adapter -> Reader/Baker/Codec. No producer/API/Level changes.

Success remains the approved six-field storage branch: {ok:true,level:R,issues:[],validation:StaticValidationResult,source_map:SourceMap,bake_provenance:{run_id:S,snapshot_id:S,source_fingerprint:S}}; validation.status=VALID(0), validation.issues=[], counters nonnegative. Provenance matches run_identity; canonical ref and successful SourceMap rules remain unchanged.

New failure branch is exactly {ok:false,level:null,issues:Array[ToolIssue|ValidationIssue],validation:StaticValidationResult?,source_map:FailedSourceMap,bake_provenance:null}. Each issue must match one whole closed formal schema, never a merged optional bag. Schema/identity failures return ToolIssue; Reader/Baker failures return ValidationIssue. Preserve order and actual values; issues is nonempty for the pinned producer failure exits. With validation=null, failure occurred before a valid Validator return. With validation non-null, status is INVALID(1) or INCOMPLETE(2), its nonempty issues equal native.issues and its counters are nonnegative actual values. VALID with ok=false rejects. No failed branch can expose a Level or canonical attachment.

FailedSourceMap is exactly {map_version:S,snapshot_id:S,source_fingerprint:S,level_hash:null,entries:Array[SourceMap.Entry]}; map_version=authoringsourcemap.v1. snapshot_id/source_fingerprint must match run_identity. Entries retain the existing closed eleven-field SourceMap.Entry schema from the approved Stage Result §4, including nullable captured paths/UID/local_face/entity_id; canonical_path is null in every failure entry because Sources.complete was not called. No run_id is added. Empty entries are valid before capture; Reader paths remain captured, not canonical guesses. Invalid identity/entry data which cannot meet wire constraints causes explicit storage rejection; never repair it or manufacture a null native result.

Failure terminology is explicitly separated by layer. BAKE native failure is ok=false. A terminal failed task is named FAILED in the task lifecycle; this is NOT a StoredStageRecord.execution value. A completed BAKE call returning ordinary failure is stored as execution=ERROR, with the non-null failure object above. A Validator budget/incomplete return is execution=INCOMPLETE, not relabeled ERROR or FAILED. Cooperative cancellation remains CANCELLED only under the existing priority/release rules; this document does not make a returned failure sufficient to prove process/resource release. Any requirement to encode literal FAILED in stage_result.execution is NOT satisfied by this proposal and would require separate explicit approval to change the existing envelope enum. No such enum change is proposed here.

Ordinary execution: success -> COMPLETED; failed validation.status=INCOMPLETE(2) -> INCOMPLETE; other failure -> ERROR. Nonempty reason for non-COMPLETED. Actual tool cancellation/deadline overrides follow §3/§9 with native ERROR priority preserved; the returned six-field object is always retained. No-return null follows existing §3 and is not this failure branch. All failures and no-return cases have evidence_refs={canonical:null}; no historical artifact. Success requires canonical equal native.level even when returned after cancellation. Graph/archive output FORBIDDEN. warnings=[] remains unchanged; unsupported actual tool warnings fail storage without discarding them. This is an explicit BAKE wire schema extension requiring approval, not retroactive interpretation of the old success-only contract.

### INTENT_BIND

owner="4A"; module_ref="res://foundation/authoring/intent_binder.gd". Consume approved four-argument binder and same captured resource_table/BakeProvenance. A_EDIT implementation remains independently required.
Signature remains bind_intent(authoring_intent,resource_table,successful_bake,snapshot_identity); storage adds no parameters or authoring fields.
Native={ok:B,bound_intent:PuzzleIntent?,source_intent_digest:S?,issues:Array[ToolIssue]}.
The approved binder result stays inline. Success requires non-null bound intent and captured digest; failure requires null bound_intent/source_intent_digest per approved failure contract. Missing Intent is NOT_RUN/MISSING_INPUT; explicit empty still binds. Graph archive FORBIDDEN. Success additionally writes bound_intent.wire exactly encoding native.bound_intent; failure/non-return writes none. 4A never hashes. Formal validation remains separate.

### INTENT_VALIDATE

owner="3C"; module_ref="res://foundation/quality/intent/intent_validation.gd".
Native={ok:B,issues:Array[AnalysisIssue]}. true -> COMPLETED; false -> ERROR. Graph archive FORBIDDEN. Extra output attachments none.

### ORIGINAL_GRAPH

owner="3A"; module_ref="res://foundation/solver/state_explorer.gd".
StoredSearchResult={status:I,graph_archive_ref:R?,solution_trace:SolutionTrace?,metrics:SearchMetrics,budget_reason:I,issues:Array[AnalysisIssue],validation:StaticValidationResult?}.
Only replacement is graph -> graph_archive_ref. Actual non-null graph makes archive REQUIRED; null graph means null ref and graph file FORBIDDEN. Preserve partial/error prefix, complete/stop flags, native status/budget/safety counters and trace. SOLVED/PROVEN_UNSOLVABLE -> COMPLETED; BUDGET_EXCEEDED -> INCOMPLETE; ERROR -> ERROR. Non-null solution_trace additionally writes selected_trace.wire exactly equal to inline trace; null forbids that file. This remains ORIGINAL_GRAPH's selected trace, never Ablation's witness.

### SOFTLOCK

owner="3B"; module_ref="res://foundation/quality/softlock/softlock_analyzer.gd".
Native={status:I,initial_key:S,reachable_states:Array[S],goal_reachable_states:Array[S],softlock_states:Array[S]?,softlock_count:I?,unknown_states:Array[S],reset_classification:I,reset_recoverable_count:I?,witnesses:Array[GraphPath],metrics:{nodes_checked:I,edges_checked:I,elapsed_ms:I},issues:Array[AnalysisIssue]}.
COMPLETE/INCOMPLETE/ERROR -> COMPLETED/INCOMPLETE/ERROR. Keep native null conclusions; do not subtract reset-recoverable count. No returned graph: graph archive output FORBIDDEN, extra attachments none. A prior graph-result input ref is provenance, never a trusted graph-loading API.

### ABLATION

owner="3C"; module_ref="res://foundation/quality/intent/ablation_analyzer.gd".
Native={status:I,intent:PuzzleIntent,baseline:StoredSearchResult?,ablations:Array[AblationItem],milestone_analysis:MilestoneResult?,advisories:Array[QualityFinding],issues:Array[AnalysisIssue]}.
AblationItem={status:I,disabled_mechanics:Array[I],baseline_status:I,ablated_status:I?,essential:B?,bypass_detected:B?,findings:Array[QualityFinding],solution_trace_if_any:SolutionTrace?,metrics:{baseline:SearchMetrics,ablated:SearchMetrics?},issues:Array[AnalysisIssue]}.
The unique location is native_result.baseline.graph_archive_ref: only nested replacement is baseline.graph -> baseline.graph_archive_ref. evidence_refs.baseline_graph_archive is an exact mirror of that same ref, not a second archive or alternate placement. A top-level native graph_archive_ref and an ORIGINAL_GRAPH archive substitution are forbidden. If returned baseline.graph exists, baseline_graph.wire REQUIRED; otherwise FORBIDDEN with null ref/absent baseline. Subitems expose traces/metrics, not graphs: do not rerun searches or invent discarded child graphs. Nested witnesses/findings stay inline. COMPLETE/BASELINE_UNSOLVABLE -> COMPLETED; INCOMPLETE -> INCOMPLETE; ERROR -> ERROR. Hard bypass remains a finding, not PASS. Baseline is Ablation's independent formal search, never substituted original graph. No selected_trace output.

### TRACE_SEMANTICS

owner="3A"; module_ref="res://foundation/solver/solution_trace.gd".
Native={ok:B,transitions:Array[TransitionResult],issues:Array[AnalysisIssue]}.
This is validate_semantics; Trace.validate and Spawn binding remain separate 4C prerequisites. true -> COMPLETED; false -> ERROR with actual native failure transitions=[] preserved. Preserve transition order. Graph archive FORBIDDEN; extra outputs none. These are semantic transitions, not measured Runtime samples.

### MILESTONES

owner="3C"; module_ref="res://foundation/quality/intent/milestone_analyzer.gd".
MilestoneResult={status:I,scope:S,matched_milestones:Array[N],missing_required:Array[N],sample_indices:Map[N,I?],findings:Array[QualityFinding],issues:Array[AnalysisIssue]}.
scope="SINGLE_TRACE"; map keys are milestone IDs and values actual indices/null. TRACE_MATCH/TRACE_BYPASS -> COMPLETED; INCOMPLETE -> INCOMPLETE; ERROR -> ERROR. Selected original trace remains distinct from Ablation.milestone_analysis. No declared milestones uses existing NOT_APPLICABLE/NOT_RUN, not synthetic MATCH. Graph archive FORBIDDEN; extra outputs none.

### GRAPHICAL_REPLAY

owner="3D"; module_ref="res://foundation/parity/trace_replayer.gd".
Native={status:I,trace_length:I,matched_steps:I,divergence_step:I?,expected_statekey:S,actual_statekey:S,action:PuzzleAction?,issues:Array[AnalysisIssue]}.
MATCH/DIVERGED -> COMPLETED; ERROR -> ERROR; INCOMPLETE -> INCOMPLETE. Native empty keys/null divergence/action remain as actually returned. Graph archive FORBIDDEN; extra outputs none.
actual_policy is exact ReplayOptions with mode=GRAPHICAL(1). LOGICAL_SESSION(0) cannot be labeled this stage; no new SEMANTIC_REPLAY alias. Real display availability, Replayer/Session/Presenter/Tween/finish/commit and actual step-timeout evidence remain mandatory, and mode=1 alone proves nothing. No D4 replay algorithm, fabricated full Runtime step stream or screenshots-as-verdict. Test screenshots/logs are not new product attachments.

## 6. Exact input, policy, budget and evidence branches

These are D4 storage bindings around actual producers, not modifications to C memory records/API. Define L={input_manifest:R,bake_result:R,canonical:R,level_hash:S,rule_version:S,initial_statekey:S}; SI={input_manifest:R,authoring_payload:R}. `L + {...}` means exactly the union of named fields, no optional extension. input_manifest=input.ready; authoring_payload equals its registered input ref. bake_result=BAKE/stage_result.wire; canonical=BAKE/canonical.level. Formal LevelCodec hash/rule and initial StateKey must match.

| Stage | exact input_refs | actual_policy | actual_budget | exact evidence_refs |
| --- | --- | --- | --- | --- |
| AUTHORING | SI | {} | {} | {} |
| BAKE | SI | BakeBudget | BakeBudget, equal actual_policy | {canonical:R?}, non-null iff native.ok=true |
| INTENT_BIND | SI + {bake_result:R,canonical:R,source_intent_digest:S} | {} | {} | {bound_intent:R?} |
| INTENT_VALIDATE | L + {bound_intent:R} | {} | {} | {} |
| ORIGINAL_GRAPH | L | PolicyDescriptor | SearchBudget | {graph_archive:R?,selected_trace_ref:SelectedTraceRef?} |
| SOFTLOCK | L + {original_graph_result:R} | PolicyDescriptor | SoftlockBudget | {} |
| ABLATION | L + {bound_intent:R} | PolicyDescriptor | SearchBudget | {baseline_graph_archive:R?} |
| TRACE_SEMANTICS | L + {selected_trace:R,selected_trace_digest:S} | {} | {} | {} |
| MILESTONES | L + {bound_intent:R,selected_trace:R,selected_trace_digest:S} | {} | {} | {} |
| GRAPHICAL_REPLAY | L + {selected_trace:R,selected_trace_digest:S} | ReplayOptions(mode=1) | {max_steps:I,max_runtime_ms:I,step_timeout_ms:I,validation_options:BakeBudget} | {} |

SelectedTraceRef={trace:R,origin:S}, origin exactly ORIGINAL_GRAPH, matching Integration Plan's existing storage projection. trace equals this stage's selected_trace.wire; ref is null iff solution_trace is null. evidence graph ref equals native graph_archive_ref; baseline_graph_archive equals native.baseline.graph_archive_ref when present, else null. Binder evidence ref is non-null iff native.ok=true, its decoded intent equals native.bound_intent. No-return null native requires output refs null, while {} remains {}. Known input refs remain actual inputs, never historical substitutes.

bound_intent points to INTENT_BIND/bound_intent.wire, equal to successful binder output. source_intent_digest binds the updated D2 captured identity/verified source-intent value. original_graph_result points to ORIGINAL_GRAPH/stage_result.wire. selected_trace points to ORIGINAL_GRAPH/selected_trace.wire; selected_trace_digest equals ref.sha256. Stage-result input refs use foundationtoolwire.v1 and expected stage_result kind; full same-run identity/stage binding is mandatory. Do not republish previous-stage inputs in each consumer directory.

Original policy is actual UNFILTERED/FULL_GRAPH for acceptance; Softlock records that same provenance. Ablation records actual UNFILTERED FIRST_SHORTEST baseline descriptor; filtered descriptors remain in native nested witnesses. Its SearchBudget applies independently to each internal search, not a fabricated summed total. Graphical actual_budget.validation_options is fixed {max_configurations:4096,max_checks:100000}; other budget values equal replay options. Empty maps mean the native API takes no options, not unlimited tool runtime. Existing sealed policy limits remain unchanged.

## 7. Attachment whitelist and publication

Every result path is artifacts/stages/<STAGE_ID>/stage_result.wire, format foundationtoolwire.v1, expected kind stage_result. Extra output files are exactly:

| Producer | relative_path | ArtifactRef.format_version | wire kind / payload |
| --- | --- | --- | --- |
| BAKE | artifacts/stages/BAKE/canonical.level | levelcanonical.v1 | existing Codec bytes, unchanged |
| INTENT_BIND | artifacts/stages/INTENT_BIND/bound_intent.wire | puzzleintent.v1 | intent / PuzzleIntent |
| ORIGINAL_GRAPH | artifacts/stages/ORIGINAL_GRAPH/graph.wire | foundationtoolwire.v1 | graph_archive / StateGraph archive |
| ORIGINAL_GRAPH | artifacts/stages/ORIGINAL_GRAPH/selected_trace.wire | solutiontrace.v1 | trace / SolutionTrace |
| ABLATION | artifacts/stages/ABLATION/baseline_graph.wire | foundationtoolwire.v1 | graph_archive / baseline StateGraph archive |

Other new branches have NO extra outputs. Conditional cardinality is 0/1 exactly per §5; presence is mandatory when native value exists, not implementer preference. StoredStageRecord has no new attachments field: refs are exactly in the native/evidence schemas above. Any enclosing archive attachment collection is unique and sorted by relative_path UTF-8; native arrays stay native order. No self-hash or result-to-own-manifest cycle.

Graph requirement is conditional REQUIRED/FORBIDDEN, never discretionary OPTIONAL: ORIGINAL_GRAPH iff native graph exists; ABLATION iff native baseline graph exists. All remaining stages in this proposal forbid graph output. Every producing directory is exactly artifacts/stages/<its stage_id>/, including stages with only stage_result.wire and no attachments.

Each non-null R requires exact full-byte length/SHA, expected format/kind/schema, same-run containment, no absolute/.. paths, duplicate/case ambiguity or symlink/junction escape. The sole ToolWire codec decodes and re-encodes canonical bytes; no second JSON/digest. Existing size/depth limits remain; overflow fails storage, never truncates graph/trace or drops evidence.

Order unchanged: all attachments -> close/readback/hash/final atomic rename -> stage_result -> close/readback/hash/final atomic rename -> WorkerMessage ArtifactRef. No overwrite of final files or sealed input/execution, no staging consumption or active worktree fallback. Run manifest remains last under D6; no new stage manifest/report. Partial files after failure are forensic, not successfully published records.

Machine absolute paths FORBIDDEN throughout the entire nested payload, diagnostics/text, graph/trace, warning and module fields. Existing approved logical res:// source/module references retain their rules. Reject nonrepresentable/path-bearing native output; do not sanitize then claim lossless preservation.

## 8. Auxiliary kinds and graph boundary

Current formal returns contain graphs only at ORIGINAL_GRAPH.native.graph and ABLATION.native.baseline.graph. Replace only those with graph_archive_ref. SOFTLOCK consumes but does not return a graph. Ablation subitems return no graph. All non-graph branches forbid added graph/live_graph/graph_handle/graph_archive_ref fields.

graph_archive payload is the existing StateGraph value, no invented metadata envelope:

```text
{graph_version:S,level_hash:S,rule_version:S,initial_key:S,
 policy_descriptor:PolicyDescriptor,nodes:Map[S,GraphNode],edges:Array[GraphEdge],
 forward:Map[S,Array[I]],reverse:Map[S,Array[I]],complete:B,stop_reason:I}
GraphNode={state_key:S,state:PuzzleState,depth:I,is_goal:B,expanded:B,predecessor_edge:I?}
GraphEdge={edge_id:I,from_key:S,to_key:S,action:PuzzleAction,global_kind:I}
```

graph_version=stategraph.v1; scalar/enum domains follow state_graph and Core. Canonical typed-map ordering does not reorder edges/adjacency arrays. Preserve partial/error prefixes and actual complete/stop flags; do not require complete=true or rewrite them to archive. A malformed unencodable result explicitly fails storage, never silently repaired. Structural/semantic inconsistency is not a certificate to resume analysis.

Decoded graph data is archive/read-only inspection only. Inspect displayed PuzzleState and full StateKey against canonical Level. complete=true on disk grants no trusted completeness. Softlock consumes the original Explorer graph directly in the SAME process; no serialization/reconstruction before its call. Ablation still performs independent formal baseline/subsearches; archive is not an input. C's live objects remain alive for required calls; storage projection never replaces them.

intent wire kind is exactly PuzzleIntent; trace wire kind is exactly SolutionTrace. Both kinds are enumerated but currently return DEPENDENCY_PENDING: this proposal includes their CLOSED registration, alongside graph_archive. Consumers still call Intent.validate, Trace.validate/validate_semantics and Spawn binding; disk bytes are not semantic certificates. Selected trace exists inline and as an equal attachment; neither may independently change. Ablation witnesses stay inline and never substitute for selected original trace.

Auxiliary registration is uniquely fixed as follows. All use the canonical foundationtoolwire.v1 typed envelope with the named record_kind; ArtifactRef.format_version is separately fixed below and is not an alternate codec.

| record_kind | ArtifactRef.format_version | Exact closed payload | Only stage producers | Stage consumers |
| --- | --- | --- | --- | --- |
| intent | puzzleintent.v1 | §4 PuzzleIntent, intent_version=puzzleintent.v1 | INTENT_BIND | INTENT_VALIDATE, ABLATION, MILESTONES |
| trace | solutiontrace.v1 | §4 SolutionTrace, trace_version=solutiontrace.v1 | ORIGINAL_GRAPH | TRACE_SEMANTICS, MILESTONES, GRAPHICAL_REPLAY |
| graph_archive | foundationtoolwire.v1 | §8 StateGraph/GraphNode/GraphEdge, graph_version=stategraph.v1 | ORIGINAL_GRAPH, ABLATION | No algorithm stage; read-only archival inspection only |

All refs use the exact §7 path and same-run identity/hash/length checks. intent is the bound formal eight-field PuzzleIntent, not AuthoringIntent, a ResourceTable entry, or the Track A source_intent canonical/digest. No second source-intent encoder/hash is introduced. In-memory native trace/intent consumers remain unchanged; the table governs the new persisted attachments only. SOFTLOCK's original_graph_result ref establishes provenance and does not permit archive reconstruction as trusted input.

## 9. Terminal compatibility and preserved semantics

| Actual native return | ordinary outer execution |
| --- | --- |
| BAKE ok=true / ok=false with validation INCOMPLETE / other ok=false | COMPLETED / INCOMPLETE / ERROR |
| AUTHORING/INTENT_BIND/INTENT_VALIDATE/TRACE_SEMANTICS ok=true / false | COMPLETED / ERROR |
| Search SOLVED or PROVEN_UNSOLVABLE / BUDGET_EXCEEDED / ERROR | COMPLETED / INCOMPLETE / ERROR |
| Softlock COMPLETE / INCOMPLETE / ERROR | COMPLETED / INCOMPLETE / ERROR |
| Ablation COMPLETE or BASELINE_UNSOLVABLE / INCOMPLETE / ERROR | COMPLETED / INCOMPLETE / ERROR |
| Milestone TRACE_MATCH or TRACE_BYPASS / INCOMPLETE / ERROR | COMPLETED / INCOMPLETE / ERROR |
| Replay MATCH or DIVERGED / INCOMPLETE / ERROR | COMPLETED / INCOMPLETE / ERROR |

The six C stage mappings are the existing quality_stage_records.from_native behavior. Tool cancellation/deadline/error overrides ordinary execution with approved priority, never edits native status, safety counters, findings or null conclusions. Native completed negative findings remain negative. C's parent-only NOT_RUN/NOT_APPLICABLE records remain outside stage wire.

Cancellation after a returned result still requires all its real graph/trace/intent attachments. Failed attachment publication is storage failure, not null native success. Parent records crashes/missing evidence without inventing child messages and still confirms actual resource release. Safety1601 and safety_unproven_rejections retain their formal meaning and existing no-complete-PASS gate.

## 10. VersionsRecord impact — proposed explicit registry additions

Current SCHEMA_VERSIONS is closed and exact. It includes stage_result=foundationtoolwire.v1 but no graph_archive/trace/intent wire-capability keys. Stage Result clarification §2 requires formal version registration for schema changes; lifecycle §8 explicitly leaves the branches unsupported. There is no prior authorization to silently treat unchanged registry values as declaring these new capabilities.

This draft PROPOSES four additional mandatory schema keys, requiring approval:

| New key | Exact value | Wire record_kind / ArtifactRef format identity |
| --- | --- | --- |
| stage_storage | foundationstagestorage.v1 | stage_result / foundationtoolwire.v1; this ten-stage storage profile |
| graph_archive | stategraph.v1 | graph_archive / foundationtoolwire.v1; payload graph_version=stategraph.v1 |
| intent | puzzleintent.v1 | intent / puzzleintent.v1 |
| trace | solutiontrace.v1 | trace / solutiontrace.v1 |

stage_storage identifies this exact branch/attachment profile. Existing schemas.stage_result/wire stay foundationtoolwire.v1; schemas.worker_message stays foundationworkeripc.v1; all other existing keys remain. contracts.intent_version/trace_version remain and must agree with new entries. No inner duplicate storage_version or second digest is added. These key/value additions are proposals, not historical facts. Missing/unknown/wrong values reject; later profile changes need formal version review.

All four keys become mandatory together in every new current VersionsRecord after the approved storage update is implemented and formally registered, even when a particular run does not execute all ten stages. Current-profile validation rejects missing keys, unknown keys, wrong or newer unsupported values before execution/publication; no defaults, guessing or downgrade. Historical sealed versions remain immutable evidence, not current-capability inputs. ArtifactRef format checks do not replace the registry checks.

D_PROTOCOL_UPDATE_REQUIRED: nine non-BAKE branches, the explicit BAKE failure extension, three auxiliary kinds and exact registry validation. D_SAVED_REGISTRY_FOLLOWUP_REQUIRED: generate current VersionsRecord with this complete registry and actual execution closure. SnapshotRef and input.ready OUTER SHAPES remain unchanged; current D_SAVED is not retroactively FAILED. Never rewrite old sealed versions or execution_digest. New runs compute the sole ToolWire.digest("versions", versions) with actual new module hashes.

The independent D_SAVED source_intent/loader compatibility delivery/registration at 8289d804c3b5b42a2e6c2cf76e965679a0f83af8 is not modified or registered by this document. After the stage-storage protocol receipt, the registry follow-up MUST start from the then latest formally registered D_SAVED and preserve that history. Do not fork again from old 7cbdae to create a competing D_SAVED lineage. Its registration state must be read at that future handoff, not assumed from this draft.

BAKE success shape/layout/canonical format and STAGE_RESULT envelope remain unchanged; required BAKE failure storage is UPDATE_REQUIRED. Registry identity changes prevent old executions masquerading as newly capable ones; historical I1 PASS stays frozen and future regressions use fresh compatible packages.

## 11. Ownership and D_JOBS unlock

4D alone owns wire/storage/transport/encoding. 4C remains sole run_quality and selected-trace orchestrator; worker_entry must consume its actual six-stage output rather than duplicating quality execution or deriving verdicts. C API/native results remain unchanged. 3D remains Replayer Owner; D4 validates same-run inputs, invokes/awaits it and records exact output. No new Solver/Validator/Softlock/Safety/Intent/Parity semantics. I2 fixture-specific expectations are not public schema fields.

Unlock: exact clarification approval -> D_PROTOCOL storage implementation/delivery -> Integration registration and required regressions -> compatible D_SAVED source-intent/registry/closure receipt -> D_JOBS Real quality/replay implementation with actual A_EDIT/C_QUALITY dependencies. Lifecycle Unit work does not prove full Real delivery. No D_JOBS_DELIVERY_READY before needed storage and real inputs exist.

D_JOBS is not D_FULL: ARCHIVE/report remains outside this scope. BAKE failure storage is explicitly included above and must pass before required storage delivery. A successful formal Bake -> quality -> replay demonstration and fail-closed unsupported publication tests do not claim complete final acceptance. C_QUALITY unchanged; I1 frozen; I2 not started.

## 12. Future checks and this turn

Future checks: all ten required stages, including preserved BAKE success plus new actual failure/INCOMPLETE and no-return cases; missing/unknown/null/type/domain negatives; exact attachment cardinality/path/kind/hash; original and nested baseline graph replacement; graph absence; selected-original trace and bound-intent equality; native array order; partial/error graph non-trust; cancelled complete returns versus discarded-return rejection; absolute path rejection; auxiliary schema and old/new registry rejection; BAKE success regression and failure/null separation; real C and Replayer consumers. These are requirements, not executed tests.

This turn: only this new clarification; production changes NONE; tests NOT_RUN; commit NOT_RUN; push NOT_RUN. Frozen Spec/Plans, approvals, receipts, case_manifest, I1 and Owner worktrees unchanged. No approval or implementation is issued.

## 13. Read-only source manifest

Hashes below pin the audited authority/producer files. They are audit evidence, not new runtime registry values.

| Source | SHA-256 |
| --- | --- |
| `docs/superpowers/specs/2026-09-22-foundation-authoring-editor-design.md` | `a4d9cd7ccfde8e4fdb0eea72746505b995361850e623bef7952d49849ec9a13f` |
| `docs/superpowers/specs/2026-09-22-foundation-authoring-tool-contracts.md` | `c31a03e807a2bf9268d32aa00fa18bcd93c77bad4c53ed00a8d349fed8462a6b` |
| `docs/superpowers/plans/2026-09-23-foundation-authoring-runtime-plan.md` | `5e8293d9ecf5580f48669875fb0324511218c423c582fb888a5cf14bf445315d` |
| `docs/superpowers/plans/2026-09-23-foundation-authoring-quality-plan.md` | `87bddd1ff7a691ad19e0ff5804fd011ec3ca7c57f73689d1bbf83bb7e07cea98` |
| `docs/superpowers/plans/2026-09-23-foundation-authoring-integration-plan.md` | `179d1f2d416b59e3c890c6026d28f57f28f84e1ebe67f233666b4e98f7bd99ff` |
| `docs/development-records/FOUNDATION_4_D4_WORKER_IPC_LIFECYCLE_CLARIFICATION.md` | `c3086988452e6dfb13afce60196c33f9fad69cecf38e4f5c259a08629024583b` |
| `docs/development-records/FOUNDATION_4_STAGE_RESULT_SCHEMA_CLARIFICATION.md` | `dbe2b5b4ea01f91160fd8e9f6d939766e5e0d2f319f84d6f26a80c0d06653ad0` |
| `docs/development-records/FOUNDATION_4_STAGE_RESULT_SCHEMA_CLARIFICATION_APPROVAL_RECORD.md` | `05f483004b7f76b51b62ed6d538d9c3bfc6333dd46dcb62be8d45659056e39a2` |
| `tools/foundation/authoring_acceptance/wire_schemas.gd` | `6d3d9b9a7678eb26b65d2d6bfc574106f2cfc27549fc44def68c061157d1ddd0` |
| `tools/foundation/authoring_acceptance/tool_wire.gd` | `d99af800ae3fdbc0246d69c37ec022032261ebad981996890f6f8e14f4e60d12` |
| `tools/foundation/authoring_acceptance/run_records.gd` | `14eafee84be3da0b334828220abfe5f561c9d45b32eaed68a51bf79d4d7189dc` |
| `tools/foundation/authoring_quality/quality_workflow.gd` | `76eb377e9c7c6dc3497b9ed578c69af3894d268164d69ceff7fe470e82894049` |
| `tools/foundation/authoring_quality/quality_stage_records.gd` | `a3ca5f9f3a7d23348c7b2c67f328d4fc3eb7e24204d25e7bc0a98a1871ab4a7e` |
| `tools/foundation/authoring_quality/selected_trace_checks.gd` | `1914929f829fe687f890b48da3f15ef271fb96e310f9c4ce0202414e4113a4f2` |
| `foundation/authoring/authoring_schema.gd` | `f01d2a7e32b8269e5f9322a15eb60f58440b5f5a13046bb9cac5a08456dd5979` |
| `foundation/solver/search_records.gd` | `6d2a47b0494a598d3730287da435cf79562d98fde05092163beaa38028d7fac0` |
| `foundation/solver/state_graph.gd` | `5747fb5c359ebf10c8bea1bfc159eab4ff8a19aa17dafac7aae5bea26da80b6f` |
| `foundation/solver/state_explorer.gd` | `536badc3a36d47df297e541e742c506f158759f7edd87c2abf0fc18f34b92482` |
| `foundation/solver/solution_trace.gd` | `a45fdbc78e61db5782f298454dc7a9a560b409872973feec57eb99f181060d30` |
| `foundation/quality/softlock/softlock_types.gd` | `c6533c8916a1e99ae7a1538225333c2279efe91862a944add106e7b8307bfa41` |
| `foundation/quality/softlock/softlock_analyzer.gd` | `0a22a5bc8b7901b9d375996e10beea78825ad2770290cf9f55622a6d540a4aee` |
| `foundation/quality/intent/intent_validation.gd` | `3d7b6373f263388462a1bd5727564c0ff376903f4fc2f499c0e2d9c8d7a18e51` |
| `foundation/quality/intent/ablation_analyzer.gd` | `8ec8e876e57ce7260351754811a6f6aff8cb3f920e886591e08d049a3f0e91de` |
| `foundation/quality/intent/milestone_analyzer.gd` | `3acdd52daa1ccd96b75518bd2fd06aa84cd41d59cab181844d1c003f7f03e693` |
| `foundation/parity/trace_replayer.gd` | `39a4eeac753c1fba8c2f5ada215811a6755dd69efb3bf7b56143137a4949e87f` |
| `docs/superpowers/specs/2026-09-16-foundation-solver-quality-contracts.md` | `3b9d2bf47e9596465c88d9e1531d10a123dff6a15e1b37b5628b7b0fab692cb5` |
| `foundation/authoring/authoring_adapter.gd` | `8e24075cc398a2c8e8e3542157d985e316b17ff14e5322f4396ad8b6cba6992b` |
| `foundation/authoring/source_map.gd` | `b8cb5e31172edb5ac5d51fc950ee8882a88bae000ebdbc81a37417d30105af1c` |
| `foundation/level/authoring_reader.gd` | `4718d338e6d0649d810ac9bd57b1bca3542f53e91bd5a9ae13ca3e2499a6f50b` |
| `foundation/level/level_baker.gd` | `4121e9895ea2da55d2a9d7cff46881530b23bf27149c380738cfee25fb368be8` |
| `foundation/validation/validation_types.gd` | `c9e006050d1486c1c1fd342027172cf706a14e40df3c6ad89f73b5e0106321fb` |
