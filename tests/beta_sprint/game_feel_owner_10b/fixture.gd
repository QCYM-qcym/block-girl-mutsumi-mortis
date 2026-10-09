extends RefCounted
## Synthetic complete cue DTO, never a Runtime classification or permission.
const META := {"fixture_kind": "PRESENTATION_CONTRACT_UNIT", "authoritative_runtime": false,
	"doubles": ["synthetic_game_feel_event"]}

static func edge(attempt: int = 1, axis: int = 0, world: int = 0, camera: int = 0, orientation: int = 0) -> Dictionary:
	var pose := {"location": {"layer": world, "cube_id": &"fixture_support", "face": 4}, "orientation": orientation}
	var state := {"player": pose.duplicate(true)}
	return {"schema_version": 1, "contract_version": "game_feel.event.v1",
		"semantic": "MOVE_REJECTED_EDGE", "phase": "REJECTED", "event_id": attempt,
		"session_id": "unit-session", "level_run_id": "unit-run", "attempt_id": attempt,
		"presentation_identity": {"session_id": "unit-session", "level_run_id": "unit-run", "generation": 1, "attempt_id": attempt},
		"transition_identity": null, "result": {"status": 1, "previous_state": state,
			"next_state": null, "action": {"kind": 0, "face_axis": axis}, "changed": false,
			"rejection_code": 2000, "issues": [], "global_kind": 0},
		"reason_category": "EDGE", "source_pose": pose, "target_pose": null,
		"source_face": pose.location.duplicate(true), "target_face": null,
		"world_id": world, "camera_quadrant": camera, "authoritative_final_orientation": null,
		"intended_move_direction": axis, "interruption_reason": null,
		"source_frame": {"u": Vector3i.RIGHT, "v": Vector3i.FORWARD, "normal": Vector3i.UP}}
