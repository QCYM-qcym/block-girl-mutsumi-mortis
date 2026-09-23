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
	if not native_result.get("issues") is Array:
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

static func not_run(stage_id: String, reason: String, inputs: Dictionary) -> Dictionary:
	if not MODULES.has(stage_id): return {}
	var stage := RunRecords.make_stage_record(stage_id,"3A" if stage_id in ["ORIGINAL_GRAPH","TRACE_SEMANTICS"] else ("3B" if stage_id == "SOFTLOCK" else "3C"),MODULES[stage_id])
	stage.reason = reason
	stage.input_refs = inputs.duplicate(true)
	return stage
