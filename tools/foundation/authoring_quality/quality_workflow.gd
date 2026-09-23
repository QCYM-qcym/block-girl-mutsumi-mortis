extends RefCounted
## Sole quality orchestration. No graph import, worker, rule or acceptance verdict.
const Stages = preload("res://tools/foundation/authoring_quality/quality_stage_records.gd")
const Schemas = preload("res://tools/foundation/authoring_acceptance/wire_schemas.gd")
const Wire = preload("res://tools/foundation/authoring_acceptance/tool_wire.gd")
const Records = preload("res://foundation/contracts/contract_records.gd")
const Data = preload("res://foundation/contracts/contract_validation.gd")
const Key = preload("res://foundation/contracts/state_key.gd")
const Search = preload("res://foundation/solver/search_records.gd")
const SolverTypes = preload("res://foundation/solver/solver_types.gd")
const Explorer = preload("res://foundation/solver/state_explorer.gd")
const Softlock = preload("res://foundation/quality/softlock/softlock_analyzer.gd")

static func run_quality(level: Dictionary, _bound_intent: Dictionary, policy: Dictionary, identity: Dictionary, boundary_control: RefCounted) -> Dictionary:
	var output := {"run_identity":identity.duplicate(true),"selected_trace_ref":null,"stages":[],"issues":[]}
	var checked := Schemas.validate("policy",policy)
	if not checked.ok:
		output.issues = checked.issues
		return output
	if not Schemas.identity_shape(identity) or identity.level_ref.level_id != level.get("level_id"):
		output.issues.append(issue("IDENTITY_MISMATCH","ORIGINAL_GRAPH","Invalid run identity or level binding"))
		return output
	if Wire.digest("policy",policy).value != identity.policy_digest or Wire.digest("versions",identity.versions).value != identity.execution_digest:
		output.issues.append(issue("IDENTITY_MISMATCH","ORIGINAL_GRAPH","Policy/execution digest does not match run"))
		return output
	var shape := Data.validate_level_shape(level)
	if not shape.is_empty():
		output.issues.append(issue("INVALID_LEVEL","ORIGINAL_GRAPH","Cannot construct Spawn",shape))
		return output
	if boundary_control == null or not boundary_control.has_method("checkpoint") or not boundary_control.has_method("stop_requested") or not boundary_control.has_method("reason"):
		output.issues.append(issue("CONTROL_INVALID","ORIGINAL_GRAPH","BoundaryControl methods required"))
		return output
	var initial := Records.initial_state(level)
	var inputs := {"level_hash":level.content_hash,"rule_version":level.rule_version,"initial_statekey":Key.build(level,initial).key}
	var search_policy := Search.default_policy(policy.search_mode)
	search_policy.validation_options = policy.bake_options.duplicate(true)
	var original: Variant = null
	if "ORIGINAL_GRAPH" in policy.stages and _before(output,"ORIGINAL_GRAPH",inputs,boundary_control):
		var started := Time.get_datetime_string_from_system(true)
		original = Explorer.explore(level,initial,search_policy,policy.search_budget)
		_after(output,"ORIGINAL_GRAPH",original,inputs,search_policy,policy.search_budget,started,boundary_control)
		if original.solution_trace is Dictionary:
			output.selected_trace_ref = {"trace":original.solution_trace,"origin":"ORIGINAL_GRAPH"}
	if "SOFTLOCK" in policy.stages and _before(output,"SOFTLOCK",inputs,boundary_control):
		if original == null or original.status == SolverTypes.SolverStatus.ERROR or not original.graph is Dictionary:
			output.stages.append(Stages.not_run("SOFTLOCK","ORIGINAL_GRAPH_UNAVAILABLE",inputs))
		else:
			var started := Time.get_datetime_string_from_system(true)
			# The very graph returned above, in this process. Never clone or restore it.
			var locks := Softlock.analyze(level,original.graph,policy.softlock_budget)
			_after(output,"SOFTLOCK",locks,inputs,search_policy,policy.softlock_budget,started,boundary_control)
	return output

static func issue(code: String, stage_id: String, message: String, upstream: Array = []) -> Dictionary:
	return {"code":code,"stage":stage_id,"path":"","message":message,"source_refs":[],"upstream":upstream}

static func _before(output: Dictionary, id: String, inputs: Dictionary, control: RefCounted) -> bool:
	if control.checkpoint(id): return true
	var stage := Stages.not_run(id,control.reason(),inputs)
	stage.execution = "CANCELLED" if stage.reason == "CANCELLED" else "ERROR"
	output.stages.append(stage)
	output.issues.append(issue(stage.reason,id,"Stopped at formal call boundary"))
	return false

static func _after(output: Dictionary, id: String, native: Dictionary, inputs: Dictionary, policy: Dictionary, budget: Dictionary, started: String, control: RefCounted) -> void:
	var stage := Stages.from_native(id,native,inputs,policy,budget)
	stage.started_at = started
	stage.finished_at = Time.get_datetime_string_from_system(true)
	if not control.checkpoint(id):
		stage.reason = control.reason()
		if stage.execution != "ERROR": stage.execution = "CANCELLED" if stage.reason == "CANCELLED" else "ERROR"
		output.issues.append(issue(stage.reason,id,"Stopped after native result returned"))
	output.stages.append(stage)
