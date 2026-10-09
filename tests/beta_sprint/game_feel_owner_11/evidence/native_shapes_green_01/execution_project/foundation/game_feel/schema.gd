extends RefCounted
## Explicit opt-in ABI. Old v1 fields, tags and enum values stay frozen.
const CONTRACT = "foundation.game_feel.v1"
const RULE = "foundation.rules.game_feel.v1"
const KEY = "statekey.game_feel.v1"
const TRACE = "solutiontrace.game_feel.v1"
const LEVEL_FIELDS = {"camera_initial_quadrant":"quadrant","perspective_falls":"array:fall_connection"}
const STATE_FIELDS = {"camera_quadrant":"quadrant"}
const CONNECTION_DATA = {"connection_id":"id","source_face_id":"face_id","source_edge":"axis","target_face_id":"face_id","allowed_camera_quadrants":"array:quadrant","allowed_world_orientations":"array:orientation","required_flags":"array:id","path_points2":"array:coordinate","orientation_policy":"preserve","motion_profile_id":"id","presentation_duration_ms":"duration"}
const LEVEL_WIRE = {"camera_initial_quadrant":"int","perspective_falls":"array:fall_connection"}
const CONNECTION_WIRE = {"connection_id":"name","source_face_id":"name","source_edge":"axis","target_face_id":"name","allowed_camera_quadrants":"array:int","allowed_world_orientations":"array:int","required_flags":"array:name","path_points2":"array:coordinate","orientation_policy":"name","motion_profile_id":"name","presentation_duration_ms":"int"}
const ACTION_FIELDS = {8:{"kind":"game_feel_kind","connection_id":"id"},9:{"kind":"game_feel_kind","camera_quadrant":"quadrant"}}
static func enabled(level: Dictionary) -> bool:
	return typeof(level.get("schema_version")) == TYPE_INT and level.schema_version == 2 and typeof(level.get("contract_version")) == TYPE_STRING and level.contract_version == CONTRACT and typeof(level.get("rule_version")) == TYPE_STRING and level.rule_version == RULE
