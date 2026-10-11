extends RefCounted
## Explicit opt-in ABI. Old v1 fields, tags and enum values stay frozen.
const CONTRACT = "foundation.game_feel.v1"
const RULE = "foundation.rules.game_feel.v1"
const KEY = "statekey.game_feel.v1"
const TRACE = "solutiontrace.game_feel.v1"
const CURVE_CONTRACT = "foundation.game_feel.v2"
const CURVE_RULE = "foundation.rules.game_feel.v2"
const SPATIAL_CONTRACT = "foundation.spatial_puzzle.v1"
const SPATIAL_RULE = "foundation.rules.spatial_puzzle.v1"
const SPATIAL_LEVEL_FIELDS = {"shift_gates":"array:shift_gate","face_locks":"array:face_lock"}
const GATE_DATA = {"gate_id":"id","source_face_id":"face_id","target_face_id":"face_id","required_flags":"array:id","required_mechanism_states":"array:mechanism_requirement"}
const GATE_WIRE = {"gate_id":"name","source_face_id":"name","target_face_id":"name","required_flags":"array:name","required_mechanism_states":"array:mechanism_requirement"}
const REQUIREMENT_DATA = {"mechanism_id":"id","state":"name"}
const REQUIREMENT_WIRE = {"mechanism_id":"name","state":"name"}
const LOCK_DATA = {"mechanism_id":"id","required_local_face":"face","activation_mode":"latch","latched_state":"name"}
const LOCK_WIRE = {"mechanism_id":"name","required_local_face":"face","activation_mode":"name","latched_state":"name"}
const TRAJECTORY_VERSION = "pfall.departure_cubic.v1"
const LEVEL_FIELDS = {"camera_initial_quadrant":"quadrant","perspective_falls":"array:fall_connection"}
const STATE_FIELDS = {"camera_quadrant":"quadrant"}
const CONNECTION_DATA = {"connection_id":"id","source_face_id":"face_id","source_edge":"axis","target_face_id":"face_id","allowed_camera_quadrants":"array:quadrant","allowed_world_orientations":"array:orientation","required_flags":"array:id","path_points2":"array:coordinate","orientation_policy":"preserve","motion_profile_id":"id","presentation_duration_ms":"duration"}
const LEVEL_WIRE = {"camera_initial_quadrant":"int","perspective_falls":"array:fall_connection"}
const CONNECTION_WIRE = {"connection_id":"name","source_face_id":"name","source_edge":"axis","target_face_id":"name","allowed_camera_quadrants":"array:int","allowed_world_orientations":"array:int","required_flags":"array:name","path_points2":"array:coordinate","orientation_policy":"name","motion_profile_id":"name","presentation_duration_ms":"int"}
const ACTION_FIELDS = {8:{"kind":"game_feel_kind","connection_id":"id"},9:{"kind":"game_feel_kind","camera_quadrant":"quadrant"}}
const CURVE_LEVEL_FIELDS = {"camera_initial_quadrant":"quadrant","perspective_falls":"array:fall_connection_curve"}
const CURVE_LEVEL_WIRE = {"camera_initial_quadrant":"int","perspective_falls":"array:fall_connection_curve"}
const CURVE_CONNECTION_DATA = {"connection_id":"id","source_face_id":"face_id","source_edge":"axis","target_face_id":"face_id","allowed_camera_quadrants":"array:quadrant","allowed_world_orientations":"array:orientation","required_flags":"array:id","trajectory":"trajectory","orientation_policy":"preserve","motion_profile_id":"id","presentation_duration_ms":"duration"}
const CURVE_CONNECTION_WIRE = {"connection_id":"name","source_face_id":"name","source_edge":"axis","target_face_id":"name","allowed_camera_quadrants":"array:int","allowed_world_orientations":"array:int","required_flags":"array:name","trajectory":"trajectory","orientation_policy":"name","motion_profile_id":"name","presentation_duration_ms":"int"}
const TRAJECTORY_DATA = {"trajectory_version":"string","departure_points2":"array:coordinate","descent_control_points2":"array:coordinate"}
static func enabled(level: Dictionary) -> bool:
	var kind := level_kind(level)
	return kind != 0 and typeof(level.get("rule_version")) == TYPE_STRING and level.rule_version == rule_for_kind(kind)
static func level_kind(level: Dictionary) -> int:
	if typeof(level.get("schema_version")) != TYPE_INT or typeof(level.get("contract_version")) != TYPE_STRING: return 0
	if level.schema_version == 2 and level.contract_version == CONTRACT: return 2
	if level.schema_version == 3 and level.contract_version == CURVE_CONTRACT: return 3
	if level.schema_version == 4 and level.contract_version == SPATIAL_CONTRACT: return 4
	return 0
static func curved(level: Dictionary) -> bool:
	return level_kind(level) in [3,4] and enabled(level)
static func connection_descriptor(level: Dictionary) -> String:
	return "fall_connection_curve" if curved(level) else "fall_connection"

static func spatial(level: Dictionary) -> bool:
	return level_kind(level) == 4 and enabled(level)
static func rule_for_kind(kind: int) -> String:
	return SPATIAL_RULE if kind == 4 else (CURVE_RULE if kind == 3 else RULE)
static func contract_for_kind(kind: int) -> String:
	return SPATIAL_CONTRACT if kind == 4 else (CURVE_CONTRACT if kind == 3 else CONTRACT)
static func level_fields(kind: int, wire: bool = false) -> Dictionary:
	var fields: Dictionary = (CURVE_LEVEL_WIRE if wire else CURVE_LEVEL_FIELDS).duplicate() if kind in [3,4] else (LEVEL_WIRE if wire else LEVEL_FIELDS).duplicate()
	if kind == 4: fields.merge(SPATIAL_LEVEL_FIELDS)
	return fields
