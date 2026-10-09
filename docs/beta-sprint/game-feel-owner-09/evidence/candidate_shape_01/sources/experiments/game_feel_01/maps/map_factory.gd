extends RefCounted
## Throwaway authoring fixture. Candidate metadata is NOT added to frozen schemas.
const Base = preload("res://tests/foundation/level/baker_fixture.gd")
const Geometry = preload("res://foundation/spatial/surface_geometry.gd")
const Records = preload("res://foundation/contracts/contract_records.gd")
const Baker = preload("res://foundation/level/level_baker.gd")

static func spec(path: String) -> Dictionary:
	return JSON.parse_string(FileAccess.get_file_as_string(path))

static func vector(value: Array) -> Vector3i:
	return Vector3i(value[0], value[1], value[2])

static func authoring(data: Dictionary) -> Dictionary:
	var level := Base.make_golden_level()
	level.erase("content_hash")
	level.level_id = StringName(data.id)
	level.cubes = [Base.cube(&"source", int(data.source_layer), vector(data.source_center2)), Base.cube(&"target", int(data.target_layer), vector(data.target_center2))]
	if data.has("exit_center2"):
		level.cubes.append(Base.cube(&"exit",int(data.target_layer),vector(data.exit_center2)))
	level.faces = []
	for cube in level.cubes:
		for face in Geometry.make_face_nodes(cube.cube_id):
			face.walkable = face.face == 4
			level.faces.append(face)
	level.spawn = Records.make_player_state(Records.make_player_location(int(data.source_layer), &"source", 4), 0)
	level.goal.face_id = &"exit/TOP" if data.has("exit_center2") else &"target/TOP"
	return level

static func bake(data: Dictionary) -> Dictionary:
	return Baker.bake(authoring(data), {"max_configurations":4096,"max_checks":100000})

static func read_spec(letter: String) -> Dictionary:
	return spec("res://experiments/game_feel_01/maps/map_"+letter+".json")

static func opt_in_authoring_candidate(data: Dictionary) -> Dictionary:
	# Explicit opt-in only. Baseline authoring/bake never activate the WIP ABI.
	# Caller must validate with delivered Owner01 DATA/Baker/Safety before use.
	var level := authoring(data)
	var candidate: Dictionary = data.opt_in_candidate
	level.schema_version = int(candidate.schema_version)
	level.contract_version = String(candidate.contract_version)
	level.rule_version = String(candidate.rule_version)
	level["camera_initial_quadrant"] = int(candidate.camera_initial_quadrant)
	var raw: Dictionary = candidate.connection
	var points: Array[Vector3i] = []
	for p in raw.path_points2: points.append(vector(p))
	var quadrants: Array[int] = []
	for q in raw.allowed_camera_quadrants: quadrants.append(int(q))
	var orientations: Array[int] = []
	for o in raw.allowed_world_orientations: orientations.append(int(o))
	var flags: Array[StringName] = []
	for flag in raw.required_flags: flags.append(StringName(flag))
	level["perspective_falls"] = [{"connection_id":StringName(raw.connection_id),"source_face_id":StringName(raw.source_face_id),"source_edge":int(raw.source_edge),"target_face_id":StringName(raw.target_face_id),"allowed_camera_quadrants":quadrants,"allowed_world_orientations":orientations,"required_flags":flags,"path_points2":points,"orientation_policy":StringName(raw.orientation_policy),"motion_profile_id":StringName(raw.motion_profile_id),"presentation_duration_ms":int(raw.presentation_duration_ms)}]
	return level
