extends RefCounted
## Author DATA for tests; every algorithm is the formal production module.
const F = preload("res://tests/foundation/level/baker_fixture.gd")
const Geometry = preload("res://foundation/spatial/surface_geometry.gd")

static func level(latched: bool = false) -> Dictionary:
	var value := F.make_golden_level()
	value.schema_version = 4
	value.contract_version = "foundation.spatial_puzzle.v1"
	value.rule_version = "foundation.rules.spatial_puzzle.v1"
	value.level_id = &"spatial_owner_fixture"
	value["camera_initial_quadrant"] = 1
	value["perspective_falls"] = []
	value["shift_gates"] = [gate(&"forward", &"floor/TOP", &"mirror/TOP"), gate(&"reverse", &"mirror/TOP", &"floor/TOP")]
	value["face_locks"] = []
	value.cubes = [F.cube(&"floor",0,Vector3i.ZERO), F.cube(&"step",0,Vector3i(2,0,0)), F.cube(&"mirror",1,Vector3i.ZERO), F.cube(&"goal",1,Vector3i(-2,0,0))]
	value.faces = []
	for cube in value.cubes:
		for face in Geometry.make_face_nodes(cube.cube_id):
			face.walkable = face.face == 4
			value.faces.append(face)
	value.goal = {"face_id":&"goal/TOP", "required_flags":[]}
	value.celestial.slots[0].position2 = Vector3i(0,-10,0)
	value.mechanisms = []
	value.face_transitions = []
	value.shift_compatibilities = [0]
	if latched:
		value.mechanisms = [{"mechanism_id":&"face_lock", "face_id":&"step/TOP", "trigger":&"ENTER", "action":{"kind":5,"mechanism_id":&"face_lock"}, "priority":0,"initial_state":&"inactive","allowed_states":[&"inactive",&"latched"]}]
		face(value,&"step/TOP").mechanism_ids = [&"face_lock"]
		value.face_locks = [{"mechanism_id":&"face_lock","required_local_face":3,"activation_mode":&"LATCH_ON_SUCCESS","latched_state":&"latched"}]
		value.shift_gates[0].required_mechanism_states = [{"mechanism_id":&"face_lock","state":&"latched"}]
	return value

static func gate(id: StringName, source: StringName, target: StringName) -> Dictionary:
	return {"gate_id":id,"source_face_id":source,"target_face_id":target,"required_flags":[],"required_mechanism_states":[]}

static func face(value: Dictionary, id: StringName) -> Dictionary:
	for item in value.faces:
		if item.face_id == id: return item
	return {}
