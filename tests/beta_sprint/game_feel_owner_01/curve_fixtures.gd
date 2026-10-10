extends RefCounted
## Owner-local synthetic author DATA for the approved four-platform profile.
## No copied 09 factory, permission, Safety, Solver or presentation algorithm.
const Base = preload("res://tests/foundation/level/baker_fixture.gd")
const Geometry = preload("res://foundation/spatial/surface_geometry.gd")
const Records = preload("res://foundation/contracts/contract_records.gd")
static func trajectory(higher: bool = false) -> Dictionary:
	return {"trajectory_version":"pfall.departure_cubic.v1", "departure_points2":[Vector3i(0,6,0),Vector3i(-2,6,0)],
		"descent_control_points2":[Vector3i(-2,6,0),Vector3i(-4,6,0),Vector3i(-6,14 if higher else 4,8),Vector3i(-6,10 if higher else 2,8)]}
static func authoring(higher: bool = false) -> Dictionary:
	var level := Base.make_golden_level()
	level.erase("content_hash")
	level.schema_version = 3
	level.contract_version = "foundation.game_feel.v2"
	level.rule_version = "foundation.rules.game_feel.v2"
	level.level_id = &"curve_b" if higher else &"curve_a"
	var y := 8 if higher else 0
	level.cubes = [Base.cube(&"source",0,Vector3i(0,4,0)),Base.cube(&"target",0,Vector3i(-6,y,8)),Base.cube(&"blue_reference",0,Vector3i(-8,y,8)),Base.cube(&"exit",0,Vector3i(-4,y,8))]
	level.faces = []
	for cube in level.cubes:
		for face in Geometry.make_face_nodes(cube.cube_id):
			face.walkable = cube.cube_id != &"blue_reference" and face.face == 4
			level.faces.append(face)
	level.spawn = Records.make_player_state(Records.make_player_location(0,&"source",4),0)
	level.goal.face_id = &"exit/TOP"
	level["camera_initial_quadrant"] = 1
	level["perspective_falls"] = [{"connection_id":&"yellow_fall","source_face_id":&"source/TOP","source_edge":2,"target_face_id":&"target/TOP","allowed_camera_quadrants":[1],"allowed_world_orientations":[0],"required_flags":[],"trajectory":trajectory(higher),"orientation_policy":&"PRESERVE","motion_profile_id":&"yellow_departure_cubic","presentation_duration_ms":600}]
	return level
