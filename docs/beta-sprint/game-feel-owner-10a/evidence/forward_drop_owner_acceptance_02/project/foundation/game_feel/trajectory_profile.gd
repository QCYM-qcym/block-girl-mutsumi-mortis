extends RefCounted
## Pure authorized-geometry evaluation. Sampling never grants traversal/Safety.
const Data = preload("res://foundation/contracts/contract_validation.gd")
const Types = preload("res://foundation/contracts/foundation_types.gd")
const View = preload("res://foundation/game_feel/view_contract.gd")
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
static func validate_geometry(trajectory: Dictionary, source_center2: Vector3i, target_center2: Vector3i, source_frame: Dictionary, source_edge: int, quadrant: int) -> Dictionary:
	var issues := Data.validate_trajectory_shape(trajectory)
	if not issues.is_empty(): return {"ok":false,"issues":issues}
	if source_edge not in range(4) or quadrant not in range(4) or not source_frame.has_all(["u","v","normal"]):
		return {"ok":false,"issues":[_issue(Types.ValidationCode.INVALID_TYPE,"trajectory.frame","Invalid formal frame/axis/quadrant.")]}
	for field in ["u","v","normal"]:
		if not source_frame[field] is Vector3i: return {"ok":false,"issues":[_issue(Types.ValidationCode.INVALID_TYPE,"trajectory.frame","Expected canonical integer frame.")]}
	var line: Array = trajectory.departure_points2
	var c: Array = trajectory.descent_control_points2
	var d: Vector3i = [source_frame.u,source_frame.v,-source_frame.u,-source_frame.v][source_edge]
	var departure: Vector3i = line[1]-line[0]
	var distance := _dot(departure,d)
	if line[0] != source_center2 or c[3] != target_center2:
		issues.append(_issue(Types.ValidationCode.INVALID_ACTION,"trajectory.endpoints","Curve endpoints must equal real support actor centers."))
	if distance < 2 or departure != d*distance or _dot(departure,source_frame.normal) != 0:
		issues.append(_issue(Types.ValidationCode.INVALID_ACTION,"trajectory.departure","Departure must clear the declared edge along its support plane."))
	if c[0] != line[1] or c[1]-c[0] != departure:
		issues.append(_issue(Types.ValidationCode.INVALID_ACTION,"trajectory.join","The fixed quarter/three-quarter parameter split requires an exact C1 join."))
	var approach: Vector3i = c[3]-c[2]
	var normal: Vector3i = source_frame.normal
	var approach_distance := _dot(approach,normal)
	if approach_distance >= 0 or approach != normal*approach_distance:
		issues.append(_issue(Types.ValidationCode.INVALID_ACTION,"trajectory.contact","Target must be approached from above along the support normal."))
	if not screen_descends(trajectory,quadrant):
		issues.append(_issue(Types.ValidationCode.INVALID_ACTION,"trajectory.projection","Entire geometry must descend in the fixed authorized view."))
	return {"ok":issues.is_empty(),"issues":issues}
static func screen_descends(trajectory: Dictionary, quadrant: int) -> bool:
	if quadrant not in range(4) or not Data.validate_trajectory_shape(trajectory).is_empty(): return false
	var down: Vector3i = View.DOWN[quadrant]
	var line: Array = trajectory.departure_points2
	var c: Array = trajectory.descent_control_points2
	if _dot(line[1]-line[0],down) < 0 or _dot(c[3]-c[0],down) <= 0: return false
	var q0 := _dot(c[1]-c[0],down)
	var q1 := _dot(c[2]-c[1],down)
	var q2 := _dot(c[3]-c[2],down)
	if q0 < 0 or q2 < 0: return false
	# Cubic derivative /3 is q0(1-t)^2+2q1(1-t)t+q2t^2.
	# Check the exact quadratic vertex; negative Bernstein controls alone are
	# not a reversal. B's q1=-4 still has minimum4/3 >0.
	var a := q0-2*q1+q2
	var b := 2*(q1-q0)
	# DATA bounds all controls to 1e6; these products are <7e15, within int64.
	return not (a > 0 and b < 0 and -b < 2*a and 4*a*q0-b*b < 0)
static func _dot(a: Vector3i, b: Vector3i) -> int:
	return int(a.x)*int(b.x)+int(a.y)*int(b.y)+int(a.z)*int(b.z)
static func _issue(code: int, path: String, message: String) -> Dictionary:
	return {"code":code,"severity":0,"path":path,"entity_ids":[],"message":message,"details":{}}
