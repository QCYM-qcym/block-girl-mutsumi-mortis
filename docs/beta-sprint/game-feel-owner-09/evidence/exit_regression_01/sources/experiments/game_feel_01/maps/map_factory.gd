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
