extends RefCounted
## Exact translating unit-cube proof, not render-frame sampling or permissions.
const Data = preload("res://foundation/contracts/contract_validation.gd")
const Types = preload("res://foundation/contracts/foundation_types.gd")
const Geometry = preload("res://foundation/spatial/surface_geometry.gd")
const Status = preload("res://foundation/validation/validation_types.gd").SafetyStatus
const SCALE: int = 1 << 36
const MAX_DEPTH = 12
const MAX_TESTS = 100000
static func prove(trajectory: Dictionary, cubes: Array, layer: int) -> Dictionary:
	var issues := Data.validate_trajectory_shape(trajectory)
	if not issues.is_empty(): return _result(Status.ERROR,issues)
	if layer not in [0,1]: return _fail(Status.ERROR,Types.ValidationCode.INVALID_TYPE,&"","Expected a formal World layer.")
	var all_points: Array = trajectory.departure_points2 + trajectory.descent_control_points2
	var near: Array = []
	var tests := 0
	# Far int32 obstacles are separated in unscaled integers. Any retained
	# center lies within root bounds ±2, hence within ±1000002; scaled bounds
	# are <6.9e16. Never multiply a far int32 coordinate by SCALE.
	for cube in cubes:
		if not cube is Dictionary or not cube.get("cube_id") is StringName or typeof(cube.get("layer")) != TYPE_INT or not cube.get("center2") is Vector3i:
			return _fail(Status.ERROR,Types.ValidationCode.INVALID_TYPE,&"","Expected validated formal Cube snapshots.")
		if cube.layer != layer: continue
		tests += 1
		if tests > MAX_TESTS: return _fail(Status.UNPROVEN,Types.ValidationCode.VALIDATION_INCOMPLETE,cube.cube_id,"Curve proof budget exhausted.")
		if _root_separated(all_points,cube.center2): continue
		var low: Array = []
		var high: Array = []
		for axis in 3:
			low.append((int(cube.center2[axis])-2)*SCALE)
			high.append((int(cube.center2[axis])+2)*SCALE)
		near.append({"id":cube.cube_id,"low":low,"high":high})
	var pending: Array = []
	for field in ["departure_points2","descent_control_points2"]:
		var controls: Array = []
		for point in trajectory[field]: controls.append([int(point.x)*SCALE,int(point.y)*SCALE,int(point.z)*SCALE])
		pending.append({"controls":controls,"depth":0,"obstacles":near})
	while not pending.is_empty():
		var node: Dictionary = pending.pop_back()
		var unresolved: Array = []
		for obstacle in node.obstacles:
			tests += 1
			if tests > MAX_TESTS: return _fail(Status.UNPROVEN,Types.ValidationCode.VALIDATION_INCOMPLETE,obstacle.id,"Curve proof budget exhausted.")
			if _hull_separated(node.controls,obstacle): continue
			# Endpoints of every dyadic child are exact points on the original
			# curve. Interior membership is a collision witness, never a SAFE test.
			if _inside(node.controls[0],obstacle) or _inside(node.controls[-1],obstacle):
				return _fail(Status.UNSAFE,Types.ValidationCode.PLAYER_UNSAFE,obstacle.id,"Exact curve interior witness penetrates a physical Cube.")
			unresolved.append(obstacle)
		if unresolved.is_empty(): continue
		if node.depth >= MAX_DEPTH: return _fail(Status.UNPROVEN,Types.ValidationCode.VALIDATION_INCOMPLETE,unresolved[0].id,"Continuous curve enclosure is unresolved at the depth limit.")
		# At depth11, all half operations are still exact on the 2^36 grid.
		# Do not compute a rounded depth13 midpoint from a depth12 node.
		var halves := _half(node.controls)
		pending.append({"controls":halves[1],"depth":node.depth+1,"obstacles":unresolved})
		pending.append({"controls":halves[0],"depth":node.depth+1,"obstacles":unresolved})
	return _result(Status.SAFE,[])
static func _root_separated(points: Array, center: Vector3i) -> bool:
	for axis in 3:
		var low: int = points[0][axis]
		var high := low
		for point in points:
			low = mini(low,int(point[axis]))
			high = maxi(high,int(point[axis]))
		if high <= int(center[axis])-2 or low >= int(center[axis])+2: return true
	return false
static func _hull_separated(controls: Array, obstacle: Dictionary) -> bool:
	for axis in 3:
		var low: int = controls[0][axis]
		var high := low
		for point in controls:
			low = mini(low,int(point[axis]))
			high = maxi(high,int(point[axis]))
		if high <= obstacle.low[axis] or low >= obstacle.high[axis]: return true
	return false
static func _inside(point: Array, obstacle: Dictionary) -> bool:
	for axis in 3:
		if point[axis] <= obstacle.low[axis] or point[axis] >= obstacle.high[axis]: return false
	return true
static func _half(controls: Array) -> Array:
	var rows: Array = [controls]
	while rows[-1].size() > 1:
		var next: Array = []
		for i in rows[-1].size()-1:
			var point: Array = []
			for axis in 3:
				# Bounded sum <1.4e17; exact integer division, no float arithmetic.
				@warning_ignore("integer_division")
				point.append((int(rows[-1][i][axis])+int(rows[-1][i+1][axis]))/2)
			next.append(point)
		rows.append(next)
	var left: Array = []
	var right: Array = []
	for row in rows: left.append(row[0])
	rows.reverse()
	for row in rows: right.append(row[-1])
	return [left,right]
static func _fail(status: int, code: int, id: StringName, message: String) -> Dictionary:
	var issues: Array[Dictionary] = []
	var ids: Array[StringName] = []
	if id != &"": ids.append(id)
	Geometry._add(issues,code,"fall.trajectory",ids,message)
	return _result(status,issues)
static func _result(status: int, issues: Array) -> Dictionary:
	var owned: Array[Dictionary] = []
	owned.assign(issues)
	return {"status":status,"issues":Geometry._sorted(owned)}
