extends RefCounted
## Explicit opt-in ABI. Old v1 fields, tags and enum values stay frozen.
const CONTRACT = "foundation.game_feel.v1"
const RULE = "foundation.rules.game_feel.v1"
const KEY = "statekey.game_feel.v1"
const TRACE = "solutiontrace.game_feel.v1"
const CURVE_CONTRACT = "foundation.game_feel.v2"
const CURVE_RULE = "foundation.rules.game_feel.v2"
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
	return kind != 0 and typeof(level.get("rule_version")) == TYPE_STRING and level.rule_version == (CURVE_RULE if kind == 3 else RULE)
static func level_kind(level: Dictionary) -> int:
	if typeof(level.get("schema_version")) != TYPE_INT or typeof(level.get("contract_version")) != TYPE_STRING: return 0
	if level.schema_version == 2 and level.contract_version == CONTRACT: return 2
	if level.schema_version == 3 and level.contract_version == CURVE_CONTRACT: return 3
	return 0
static func curved(level: Dictionary) -> bool:
	return level_kind(level) == 3 and enabled(level)
static func connection_descriptor(level: Dictionary) -> String:
	return "fall_connection_curve" if curved(level) else "fall_connection"
