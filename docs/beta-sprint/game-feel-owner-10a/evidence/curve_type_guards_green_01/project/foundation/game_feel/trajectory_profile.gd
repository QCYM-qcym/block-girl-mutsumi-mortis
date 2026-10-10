extends RefCounted
## Pure authorized-geometry evaluation. Sampling never grants traversal/Safety.
const Data = preload("res://foundation/contracts/contract_validation.gd")
const Types = preload("res://foundation/contracts/foundation_types.gd")
static func sample_actor_center(trajectory: Dictionary, parameter: float) -> Dictionary:
	var issues := Data.validate_trajectory_shape(trajectory)
	if not is_finite(parameter) or parameter < 0.0 or parameter > 1.0:
		issues.append(_issue(Types.ValidationCode.INVALID_TYPE,"parameter","Expected a finite geometry parameter in [0,1]."))
	if not issues.is_empty(): return {"ok":false,"position":null,"issues":issues}
	var line: Array = trajectory.departure_points2
	var controls: Array = trajectory.descent_control_points2
	if parameter == 0.0: return _sample(Vector3(line[0])*0.5)
	if parameter == 0.25: return _sample(Vector3(line[1])*0.5)
	if parameter == 1.0: return _sample(Vector3(controls[3])*0.5)
	if parameter < 0.25: return _sample(Vector3(line[0]).lerp(Vector3(line[1]),parameter*4.0)*0.5)
	var t := (4.0*parameter-1.0)/3.0
	# De Casteljau evaluates the same Bernstein geometry used by exact Safety.
	var a := Vector3(controls[0]).lerp(Vector3(controls[1]),t)
	var b := Vector3(controls[1]).lerp(Vector3(controls[2]),t)
	var c := Vector3(controls[2]).lerp(Vector3(controls[3]),t)
	return _sample(a.lerp(b,t).lerp(b.lerp(c,t),t)*0.5)
static func _sample(position: Vector3) -> Dictionary:
	return {"ok":true,"position":position,"issues":[]}
static func _issue(code: int, path: String, message: String) -> Dictionary:
	return {"code":code,"severity":0,"path":path,"entity_ids":[],"message":message,"details":{}}
