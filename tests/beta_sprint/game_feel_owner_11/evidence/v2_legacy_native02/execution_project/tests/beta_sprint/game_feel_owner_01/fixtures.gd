extends RefCounted
const F = preload("res://tests/foundation/level/baker_fixture.gd")
const Geometry = preload("res://foundation/spatial/surface_geometry.gd")

static func level(higher: bool = false) -> Dictionary:
	var level := F.make_golden_level()
	level.level_id = &"pfall_b" if higher else &"pfall_a"
	level.cubes[0].center2 = Vector3i(0,4,0)
	level.cubes.append(F.cube(&"target",0,Vector3i(-8,8 if higher else 0,8)))
	for face in Geometry.make_face_nodes(&"target"):
		face.walkable = face.face == 4
		level.faces.append(face)
	level.goal.face_id = &"target/TOP"
	level.schema_version = 2
	level.contract_version = "foundation.game_feel.v1"
	level.rule_version = "foundation.rules.game_feel.v1"
	level["camera_initial_quadrant"] = 1
	level["perspective_falls"] = [{"connection_id":&"edge_a","source_face_id":&"floor/TOP","source_edge":2,"target_face_id":&"target/TOP","allowed_camera_quadrants":[1],"allowed_world_orientations":[0],"required_flags":[],"path_points2":[Vector3i(0,6,0),Vector3i(-2,6,2),Vector3i(-6,10 if higher else 6,6),Vector3i(-8,10 if higher else 2,8)],"orientation_policy":&"PRESERVE","motion_profile_id":&"pfall_path","presentation_duration_ms":300}]
	level.faces.sort_custom(func(a,b):return String(a.face_id) < String(b.face_id))
	return level

static func map_level(data: Dictionary) -> Dictionary:
	# Immutable Owner09 author DATA only; all algorithms remain real modules.
	var result := level(data.target_center2[1] > data.source_center2[1])
	result.level_id = StringName(data.id)
	result.cubes[0].cube_id = &"source"
	result.cubes[0].layer = int(data.source_layer)
	result.cubes[0].center2 = _vector(data.source_center2)
	result.cubes[1].layer = int(data.target_layer)
	result.cubes[1].center2 = _vector(data.target_center2)
	result.cubes.append(F.cube(&"exit",int(data.target_layer),_vector(data.exit_center2)))
	result.faces = []
	for cube in result.cubes:
		for face in Geometry.make_face_nodes(cube.cube_id):
			face.walkable = face.face == 4
			result.faces.append(face)
	result.spawn.location.cube_id = &"source"
	result.spawn.location.layer = int(data.source_layer)
	result.camera_initial_quadrant = int(data.candidate_camera)
	result.goal.face_id = &"exit/TOP"
	result.perspective_falls[0].connection_id = StringName(data.connection.connection_id)
	result.perspective_falls[0].source_face_id = &"source/TOP"
	result.perspective_falls[0].allowed_camera_quadrants = []
	for quadrant in data.connection.allowed_camera_quadrants:
		result.perspective_falls[0].allowed_camera_quadrants.append(int(quadrant))
	return result

static func _vector(a: Array) -> Vector3i:
	return Vector3i(int(a[0]),int(a[1]),int(a[2]))
