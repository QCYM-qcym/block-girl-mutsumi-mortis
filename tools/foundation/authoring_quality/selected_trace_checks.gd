extends RefCounted
const Trace = preload("res://foundation/solver/solution_trace.gd")
const Key = preload("res://foundation/contracts/state_key.gd")
const Data = preload("res://foundation/contracts/contract_validation.gd")
const Records = preload("res://foundation/contracts/contract_records.gd")
const Milestones = preload("res://foundation/quality/intent/milestone_analyzer.gd")

static func check_selected(level: Dictionary, intent: Dictionary, trace: Dictionary, initial: Dictionary) -> Dictionary:
	var result := _binding(level,trace,initial)
	if not result.trace_validation.ok or not result.spawn_matches: return result
	result.semantics = Trace.validate_semantics(level,trace)
	if not result.semantics.ok:
		result.issues.append(_issue("TRACE_SEMANTICS_INVALID",result.semantics.issues))
		return result
	result.milestones = Milestones.analyze_trace(level,intent,trace)
	if not result.milestones.issues.is_empty(): result.issues.append(_issue("MILESTONES_INVALID",result.milestones.issues))
	return result

## Shared C-owned binding step; workflow puts a BoundaryControl checkpoint
## around each subsequent public native call, rather than adding native options.
static func _binding(level: Dictionary, trace: Dictionary, initial: Dictionary) -> Dictionary:
	var result := {"trace_validation":Trace.validate(level,trace),"spawn_matches":false,"semantics":null,"milestones":null,"issues":[]}
	if not result.trace_validation.ok:
		result.issues.append(_issue("TRACE_STRUCTURE_INVALID",result.trace_validation.issues))
		return result
	var shape := Data.validate_level_shape(level)
	if not shape.is_empty():
		result.issues.append(_issue("INVALID_LEVEL",shape))
		return result
	var spawn := Key.build(level,Records.initial_state(level))
	var supplied := Key.build(level,initial)
	result.spawn_matches = spawn.ok and supplied.ok and supplied.key == spawn.key and trace.initial_statekey == spawn.key
	if not result.spawn_matches: result.issues.append(_issue("TRACE_SPAWN_MISMATCH",supplied.issues))
	return result

static func _issue(code: String, upstream: Array) -> Dictionary:
	return {"code":code,"stage":"TRACE_SEMANTICS","path":"trace","message":code,"source_refs":[],"upstream":upstream}
