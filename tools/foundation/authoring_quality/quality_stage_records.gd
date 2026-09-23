extends RefCounted
## Native adapters only. D owns the StageRecord shape and construction.
const RunRecords = preload("res://tools/foundation/authoring_acceptance/run_records.gd")
const SolverTypes = preload("res://foundation/solver/solver_types.gd")
const LockTypes = preload("res://foundation/quality/softlock/softlock_types.gd")
const IntentTypes = preload("res://foundation/quality/intent/intent_types.gd")
const MODULES = {
	"INTENT_VALIDATE":"res://foundation/quality/intent/intent_validation.gd",
	"ORIGINAL_GRAPH":"res://foundation/solver/state_explorer.gd",
	"SOFTLOCK":"res://foundation/quality/softlock/softlock_analyzer.gd",
	"ABLATION":"res://foundation/quality/intent/ablation_analyzer.gd",
	"TRACE_SEMANTICS":"res://foundation/solver/solution_trace.gd",
	"MILESTONES":"res://foundation/quality/intent/milestone_analyzer.gd"}

static func from_native(stage_id: String, native_result: Dictionary, inputs: Dictionary, policy: Dictionary, budget: Dictionary) -> Dictionary:
	var stage := not_run(stage_id,"",inputs)
	if stage.is_empty(): return stage
	stage.native_result = native_result # Same live result, including the original graph.
	stage.actual_policy = policy.duplicate(true)
	stage.actual_budget = budget.duplicate(true)
	stage.execution = "COMPLETED"
	if not _native_envelope(stage_id,native_result):
		stage.execution = "ERROR"
		stage.reason = "NATIVE_RESULT_INVALID"
		return stage
	match stage_id:
		"ORIGINAL_GRAPH":
			match native_result.get("status"):
				SolverTypes.SolverStatus.SOLVED, SolverTypes.SolverStatus.PROVEN_UNSOLVABLE: pass
				SolverTypes.SolverStatus.BUDGET_EXCEEDED: stage.execution = "INCOMPLETE"
				_: stage.execution = "ERROR"
		"SOFTLOCK":
			match native_result.get("status"):
				LockTypes.SoftlockStatus.COMPLETE: pass
				LockTypes.SoftlockStatus.INCOMPLETE: stage.execution = "INCOMPLETE"
				_: stage.execution = "ERROR"
		"ABLATION":
			match native_result.get("status"):
				IntentTypes.AblationStatus.COMPLETE, IntentTypes.AblationStatus.BASELINE_UNSOLVABLE: pass
				IntentTypes.AblationStatus.INCOMPLETE: stage.execution = "INCOMPLETE"
				_: stage.execution = "ERROR"
		"MILESTONES":
			match native_result.get("status"):
				IntentTypes.MilestoneStatus.TRACE_MATCH, IntentTypes.MilestoneStatus.TRACE_BYPASS: pass
				IntentTypes.MilestoneStatus.INCOMPLETE: stage.execution = "INCOMPLETE"
				_: stage.execution = "ERROR"
		_:
			if typeof(native_result.get("ok")) != TYPE_BOOL or not native_result.ok: stage.execution = "ERROR"
	if stage.execution != "COMPLETED": stage.reason = "NATIVE_" + stage.execution
	return stage

## Admission for this adapter's native return types, not a StageRecord schema
## or another graph validator. Nested algorithm evidence stays with its owner.
static func _native_envelope(id: String, value: Dictionary) -> bool:
	var fields := {"issues":[TYPE_ARRAY]}
	match id:
		"ORIGINAL_GRAPH":
			fields.merge({"status":[TYPE_INT],"graph":[TYPE_NIL,TYPE_DICTIONARY],"solution_trace":[TYPE_NIL,TYPE_DICTIONARY],"metrics":[TYPE_DICTIONARY],"budget_reason":[TYPE_INT],"validation":[TYPE_NIL,TYPE_DICTIONARY]})
		"SOFTLOCK":
			fields.merge({"status":[TYPE_INT],"initial_key":[TYPE_STRING],"reachable_states":[TYPE_ARRAY],"goal_reachable_states":[TYPE_ARRAY],"softlock_states":[TYPE_NIL,TYPE_ARRAY],"softlock_count":[TYPE_NIL,TYPE_INT],"unknown_states":[TYPE_ARRAY],"reset_classification":[TYPE_INT],"reset_recoverable_count":[TYPE_NIL,TYPE_INT],"witnesses":[TYPE_ARRAY],"metrics":[TYPE_DICTIONARY]})
		"ABLATION":
			fields.merge({"status":[TYPE_INT],"intent":[TYPE_DICTIONARY],"baseline":[TYPE_NIL,TYPE_DICTIONARY],"ablations":[TYPE_ARRAY],"milestone_analysis":[TYPE_NIL,TYPE_DICTIONARY],"advisories":[TYPE_ARRAY]})
		"MILESTONES":
			fields.merge({"status":[TYPE_INT],"scope":[TYPE_STRING],"matched_milestones":[TYPE_ARRAY],"missing_required":[TYPE_ARRAY],"sample_indices":[TYPE_DICTIONARY],"findings":[TYPE_ARRAY]})
		"INTENT_VALIDATE": fields["ok"] = [TYPE_BOOL]
		"TRACE_SEMANTICS": fields.merge({"ok":[TYPE_BOOL],"transitions":[TYPE_ARRAY]})
		_: return false
	if value.size() != fields.size(): return false
	for key in value:
		if typeof(key) != TYPE_STRING or not fields.has(key) or typeof(value[key]) not in fields[key]: return false
	return true

static func not_run(stage_id: String, reason: String, inputs: Dictionary) -> Dictionary:
	if not MODULES.has(stage_id): return {}
	var stage := RunRecords.make_stage_record(stage_id,"3A" if stage_id in ["ORIGINAL_GRAPH","TRACE_SEMANTICS"] else ("3B" if stage_id == "SOFTLOCK" else "3C"),MODULES[stage_id])
	stage.reason = reason
	stage.input_refs = inputs.duplicate(true)
	return stage
