extends RefCounted
## Synthetic immutable presentation-port fixture, never traversal permission.
static func event(higher: bool = false, orientation: int = 0, attempt: int = 1) -> Dictionary:
	var source := {"location": {"layer": 0, "cube_id": &"source", "face": 4}, "orientation": orientation}
	var target := {"location": {"layer": 0, "cube_id": &"target", "face": 4}, "orientation": orientation}
	return {"schema_version": 1, "contract_version": "game_feel.event.v1",
		"semantic": "PERSPECTIVE_FALL_APPLIED", "phase": "STARTED", "event_id": attempt * 2,
		"session_id": "10a-unit", "level_run_id": "isolated-run", "attempt_id": attempt,
		"presentation_identity": {"session_id": "10a-unit", "level_run_id": "isolated-run", "generation": 1, "attempt_id": attempt},
		"transition_identity": {"session_id": "10a-unit", "level_run_id": "isolated-run", "generation": 1, "transaction_id": attempt, "is_global": false},
		"result": {"status": 0, "changed": true, "previous_state": {"player": source.duplicate(true)}, "next_state": {"player": target.duplicate(true)}, "action": {"kind": "SYNTHETIC_FALL"}, "rejection_code": 0, "issues": [], "global_kind": 0},
		"reason_category": "NONE", "source_pose": source, "target_pose": target,
		"source_face": source.location.duplicate(true), "target_face": target.location.duplicate(true),
		"world_id": 0, "camera_quadrant": 1, "authoritative_final_orientation": orientation,
		"intended_move_direction": 2, "interruption_reason": null,
		"connection_id": "synthetic-10a-A" if not higher else "synthetic-10a-B",
		"authorized_path_points2": [Vector3i(0, 6, 0), Vector3i(-2, 7 if higher else 5, 2), Vector3i(-8, 10 if higher else 2, 8)],
		"motion_profile_id": "UNIT-polyline", "motion_profile_hash": "SYNTHETIC-NOT-SAFETY-PROOF",
		"safety_verdict": "SAFE", "orientation_policy": "PRESERVE", "presentation_duration_seconds": 0.8,
		"source_frame": {"u": Vector3i.RIGHT, "v": Vector3i.FORWARD, "normal": Vector3i.UP},
		"fixture_kind": "PRESENTATION_CONTRACT_UNIT", "authoritative_runtime": false,
		"doubles": ["01 game_feel_event DTO", "Safety path attestation", "native commit"]}

static func committed(start: Dictionary) -> Dictionary:
	var result := start.duplicate(true)
	result.phase = "COMMITTED"
	result.event_id += 1
	return result
