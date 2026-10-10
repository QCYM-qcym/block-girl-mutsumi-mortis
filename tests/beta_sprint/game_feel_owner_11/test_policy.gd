extends SceneTree
const Policy = preload("res://game/feel/audio/event_policy.gd")
var checks := 0
var failures: Array[String] = []
var output := ""

func _initialize() -> void:
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--evidence-dir="): output = arg.trim_prefix("--evidence-dir=")
	call_deferred("run")

func check(value: bool, label: String) -> void:
	checks += 1
	if not value:
		failures.append(label)
		print("FAIL: ", label)

func identity(attempt: int = 1, generation: int = 0, run_id: String = "run-A") -> Dictionary:
	return {"session_id": "session-A", "level_run_id": run_id, "generation": generation, "attempt_id": attempt}

func event(semantic: String, phase: String, number: int, attempt: int = 1, generation: int = 0, run_id: String = "run-A") -> Dictionary:
	var pose := {"location": {"layer": 0, "cube_id": "cube-A", "face": 0}, "orientation": 0}
	var target := {"location": {"layer": 0, "cube_id": "cube-B", "face": 0}, "orientation": 0}
	var rejected := semantic == "MOVE_REJECTED_EDGE" or semantic == "ACTION_FEEDBACK"
	var result := {"status": 1 if rejected else 0, "previous_state": {"player": pose}, "next_state": {"player": pose if rejected else target}, "action": {"kind": 0}, "changed": not rejected, "rejection_code": 2000 if rejected else 0, "issues": [], "global_kind": 0}
	return {"schema_version": 1, "contract_version": "game_feel.event.v1", "semantic": semantic, "phase": phase,
		"event_id": number, "session_id": "session-A", "level_run_id": run_id, "attempt_id": attempt,
		"presentation_identity": identity(attempt, generation, run_id),
		"transition_identity": null if rejected else {"session_id": "session-A", "level_run_id": run_id, "generation": generation, "transaction_id": attempt, "is_global": false},
		"result": result, "reason_category": "EDGE" if semantic == "MOVE_REJECTED_EDGE" else ("BUSY" if rejected else "NONE"),
		"source_pose": pose, "target_pose": null if rejected else target, "source_face": pose.location.duplicate(true), "target_face": null if rejected else target.location.duplicate(true),
		"world_id": 0, "camera_quadrant": 0, "authoritative_final_orientation": null if rejected else 0, "intended_move_direction": 0,
		"interruption_reason": null, "source_frame": {"fixture": true}, "connection_id": "connection-A", "authorized_path_points2": [Vector3i(0, 2, 0), Vector3i(2, 0, 0)],
		"motion_profile_id": "fixture-safe", "motion_profile_hash": "unit-hash", "safety_verdict": "SAFE", "orientation_policy": "PRESERVE", "presentation_duration_seconds": 0.8}

func run() -> void:
	check_v2_lifecycle()
	check_runtime_shapes()
	var p = Policy.new()
	var start := event("PERSPECTIVE_FALL_APPLIED", "STARTED", 1)
	var before := start.duplicate(true)
	var answer: Dictionary = p.consume(start, 0.0)
	check(answer.cues == ["fall_start", "fall_whoosh"], "fall acceptance starts scoped whoosh without impact")
	check(start == before, "immutable event snapshot")
	check(p.consume(start, 0.1).cues.is_empty(), "duplicate event ignored")
	var feedback := event("ACTION_FEEDBACK", "FEEDBACK", 2)
	feedback.result.status = 0
	check(p.consume(feedback, 0.2).cues.is_empty(), "APPLIED feedback never lands")
	var wrong := event("PERSPECTIVE_FALL_APPLIED", "COMMITTED", 3, 2)
	check(p.consume(wrong, 0.3).cues.is_empty(), "unmatched commit cannot land")
	var commit := event("PERSPECTIVE_FALL_APPLIED", "COMMITTED", 4)
	answer = p.consume(commit, 0.8)
	check(answer.cues == ["landing_impact"], "matching COMMITTED alone lands")
	check(answer.stop_identity == identity(), "landing stops matching fall loop")
	commit.event_id = 5
	check(p.consume(commit, 0.9).cues.is_empty(), "duplicate commit with new event id ignored")

	p = Policy.new()
	answer = p.consume(event("MOVE_APPLIED_NORMAL", "STARTED", 1), 0.0)
	check(answer.cues == ["cube_roll"], "ordinary accepted move rolls")
	answer = p.consume(event("MOVE_APPLIED_NORMAL", "COMMITTED", 2), 0.32)
	check(answer.cues == ["cube_contact"], "normal committed move contacts")
	check(not answer.cues.has("landing_impact"), "ordinary contact is quieter than fall impact")

	for reason in ["BUSY", "MECHANISM_LOCKED", "INVALID_FACE", "SAFETY_REJECTED", "INVALID_ACTION", "CAMERA_NOT_ALLOWED", "WORLD_NOT_ALLOWED", "FALL_NOT_AVAILABLE", "UNCLASSIFIED_REJECTION", "ERROR"]:
		p = Policy.new()
		var bad := event("MOVE_REJECTED_EDGE", "REJECTED", 1)
		bad.reason_category = reason
		check(p.consume(bad, 0.0).cues.is_empty(), "non-edge never sounds EDGE: " + reason)
	p = Policy.new()
	check(p.consume(event("MOVE_REJECTED_EDGE", "REJECTED", 1), 0.0).cues == ["edge_recoil"], "explicit edge sounds once")
	for i in range(2, 12):
		check(p.consume(event("MOVE_REJECTED_EDGE", "REJECTED", i, i), float(i) * 0.01).cues.is_empty(), "held edge throttled " + str(i))
	check(p.consume(event("MOVE_REJECTED_EDGE", "REJECTED", 12, 12), 0.5).cues == ["edge_recoil"], "new edge allowed after cooldown")

	p = Policy.new()
	p.consume(event("PERSPECTIVE_FALL_APPLIED", "STARTED", 1), 0.0)
	p.cancel(identity())
	check(p.consume(event("PERSPECTIVE_FALL_APPLIED", "COMMITTED", 2), 1.0).cues.is_empty(), "canceled fall cannot land")
	p.consume(event("PERSPECTIVE_FALL_APPLIED", "STARTED", 3, 2), 1.0)
	p.cancel(identity())
	check(p.consume(event("PERSPECTIVE_FALL_APPLIED", "COMMITTED", 4, 2), 2.0).cues == ["landing_impact"], "old cancel leaves newly started fall")
	p = Policy.new()
	p.consume(event("PERSPECTIVE_FALL_APPLIED", "STARTED", 1), 0.0)
	var interrupted := event("ANIMATION_INTERRUPTED", "INTERRUPTED", 2)
	interrupted.interruption_reason = "RESET"
	answer = p.consume(interrupted, 0.1)
	check(answer.stop_identity == identity() and answer.cues.is_empty(), "interrupt synchronously stops with no landing")
	check(p.consume(event("PERSPECTIVE_FALL_APPLIED", "COMMITTED", 3), 0.8).cues.is_empty(), "late completion after interruption silent")
	p = Policy.new()
	p.consume(event("PERSPECTIVE_FALL_APPLIED", "STARTED", 1), 0.0)
	answer = p.consume(event("MOVE_APPLIED_NORMAL", "STARTED", 2, 2, 1), 0.2)
	check(answer.stop_identity == identity(), "generation advance cancels old identity")
	check(p.consume(event("PERSPECTIVE_FALL_APPLIED", "COMMITTED", 3), 0.8).cues.is_empty(), "old generation rejected")
	check(p.consume(event("MOVE_APPLIED_NORMAL", "COMMITTED", 4, 2, 1), 1.0).cues == ["cube_contact"], "new generation can commit")
	p.clear()
	check(p.consume(event("MOVE_APPLIED_NORMAL", "STARTED", 5, 3, 1), 1.1).cues.is_empty(), "clear retires old run against late start")
	check(p.consume(event("MOVE_APPLIED_NORMAL", "STARTED", 1, 1, 0, "run-B"), 1.2).cues == ["cube_roll"], "new level run may bind after clear")

	for field in ["schema_version", "contract_version", "event_id", "presentation_identity", "result", "source_pose", "target_pose", "transition_identity"]:
		p = Policy.new()
		var bad := event("MOVE_APPLIED_NORMAL", "STARTED", 1)
		bad.erase(field)
		check(p.consume(bad, 0.0).cues.is_empty(), "missing field fails silent: " + field)
	for field in ["safety_verdict", "authorized_path_points2", "orientation_policy", "motion_profile_hash", "presentation_duration_seconds"]:
		p = Policy.new()
		var bad := event("PERSPECTIVE_FALL_APPLIED", "STARTED", 1)
		bad.erase(field)
		check(p.consume(bad, 0.0).cues.is_empty(), "missing Fall authority silent: " + field)
	p = Policy.new()
	var mismatch := event("MOVE_APPLIED_NORMAL", "STARTED", 1)
	mismatch.presentation_identity.session_id = "other-session"
	check(p.consume(mismatch, 0.0).cues.is_empty(), "envelope identity mismatch rejected")
	p = Policy.new()
	p.consume(event("PERSPECTIVE_FALL_APPLIED", "STARTED", 1), 0.0)
	var changed_target := event("PERSPECTIVE_FALL_APPLIED", "COMMITTED", 2)
	changed_target.target_pose.location.cube_id = "unaccepted-target"
	changed_target.target_face = changed_target.target_pose.location.duplicate(true)
	changed_target.result.next_state.player = changed_target.target_pose.duplicate(true)
	check(p.consume(changed_target, 0.8).cues.is_empty(), "same token cannot commit a different accepted target")
	var changed_token := event("PERSPECTIVE_FALL_APPLIED", "COMMITTED", 3)
	changed_token.transition_identity.is_global = true
	check(p.consume(changed_token, 0.8).cues.is_empty(), "local/global token distinction preserved")
	check(p.consume(event("PERSPECTIVE_FALL_APPLIED", "COMMITTED", 4), 0.8).cues == ["landing_impact"], "original accepted endpoint still commits once")
	for status in [0, 2]:
		p = Policy.new()
		var false_edge := event("MOVE_REJECTED_EDGE", "REJECTED", 1)
		false_edge.result.status = status
		check(p.consume(false_edge, 0.0).cues.is_empty(), "edge rejects non-REJECTED native status " + str(status))
	p = Policy.new()
	var unsafe := event("PERSPECTIVE_FALL_APPLIED", "STARTED", 1)
	unsafe.safety_verdict = "UNPROVEN"
	check(p.consume(unsafe, 0.0).cues.is_empty(), "unproven Fall cannot sound accepted")
	p = Policy.new()
	var foreign_world := event("PERSPECTIVE_FALL_APPLIED", "STARTED", 1)
	foreign_world.target_pose.location.layer = 1
	foreign_world.target_face = foreign_world.target_pose.location.duplicate(true)
	foreign_world.result.next_state.player = foreign_world.target_pose.duplicate(true)
	check(p.consume(foreign_world, 0.0).cues.is_empty(), "cross-world Fall cannot sound accepted")
	var report := {"fixture_kind": "PRESENTATION_CONTRACT_UNIT", "authoritative_runtime": false, "doubles": ["synthetic game_feel.event.v1/v2 snapshots; no Safety proof"], "checks": checks, "failures": failures, "pid": OS.get_process_id(), "engine": Engine.get_version_info(), "user_data_dir": OS.get_user_data_dir(), "display": DisplayServer.get_name(), "input": "direct immutable unit fixtures"}
	if not output.is_empty():
		var file := FileAccess.open(output.path_join("policy.json"), FileAccess.WRITE)
		file.store_string(JSON.stringify(report, "\t"))
	print("AUDIO_POLICY checks=", checks, " failures=", failures.size())
	quit(0 if failures.is_empty() else 1)

func runtime_shape_event(semantic: String, phase: String, number: int) -> Dictionary:
	# Shapes inspected in Runtime candidate 26387d6; synthetic values, not Safety proof.
	var sample := event(semantic, phase, number)
	if semantic == "MOVE_REJECTED_EDGE":
		sample.result.next_state = null
	elif semantic == "PERSPECTIVE_FALL_APPLIED":
		sample.result.action = {"kind": 8, "connection_id": &"connection-A"}
		sample.connection_id = &"connection-A"
		sample.motion_profile_id = &"fixture-safe"
		sample.intended_move_direction = null
		sample.safety_verdict = {"status": "SAFE", "issues": [], "evidence_ref": {"kind": "exact_linear_cube_sweep.v1", "query": "Safety.validate_perspective_motion", "before_statekey": "unit-before", "after_statekey": "unit-after", "level_hash": "unit-level-hash", "connection_id": &"connection-A", "profile_hash": "unit-hash"}}
	return sample

func check_runtime_shapes() -> void:
	var p = Policy.new()
	var fall := runtime_shape_event("PERSPECTIVE_FALL_APPLIED", "STARTED", 1)
	var frozen := fall.duplicate(true)
	check(p.consume(fall, 0.0).cues == ["fall_start", "fall_whoosh"], "formal-shaped SAFE dictionary/StringName/nullable Fall direction accepted")
	check(fall == frozen, "structured safety evidence never rewritten")
	check(p.consume(runtime_shape_event("PERSPECTIVE_FALL_APPLIED", "COMMITTED", 2), 0.8).cues == ["landing_impact"], "formal-shaped Fall matches commit once")
	p = Policy.new()
	var edge := runtime_shape_event("MOVE_REJECTED_EDGE", "REJECTED", 1)
	frozen = edge.duplicate(true)
	check(p.consume(edge, 0.0).cues == ["edge_recoil"], "formal Rules.rejected next_state null accepted for explicit EDGE")
	check(edge == frozen and edge.result.next_state == null and edge.result.size() == 8, "rejected eight-field native result remains null and untouched")
	for reason in ["BUSY", "MECHANISM_LOCKED", "SAFETY_REJECTED"]:
		p = Policy.new()
		var bad := runtime_shape_event("MOVE_REJECTED_EDGE", "REJECTED", 1)
		bad.reason_category = reason
		check(p.consume(bad, 0.0).cues.is_empty(), "null next_state is not evidence of EDGE: " + reason)
	for fault in ["unsafe", "issues", "missing_ref", "empty_level_hash", "wrong_connection", "wrong_profile"]:
		p = Policy.new()
		var bad := runtime_shape_event("PERSPECTIVE_FALL_APPLIED", "STARTED", 1)
		match fault:
			"unsafe": bad.safety_verdict.status = "UNPROVEN"
			"issues": bad.safety_verdict.issues = ["unresolved"]
			"missing_ref": bad.safety_verdict.erase("evidence_ref")
			"empty_level_hash": bad.safety_verdict.evidence_ref.level_hash = ""
			"wrong_connection": bad.safety_verdict.evidence_ref.connection_id = &"other"
			"wrong_profile": bad.safety_verdict.evidence_ref.profile_hash = "other"
		check(p.consume(bad, 0.0).cues.is_empty(), "structured Safety fails silent: " + fault)
	p = Policy.new()
	var bad_edge := runtime_shape_event("MOVE_REJECTED_EDGE", "REJECTED", 1)
	bad_edge.result.changed = true
	check(p.consume(bad_edge, 0.0).cues.is_empty(), "null next_state never permits changed rejection")
	p = Policy.new()
	var bad_move := event("MOVE_APPLIED_NORMAL", "STARTED", 1)
	bad_move.intended_move_direction = null
	check(p.consume(bad_move, 0.0).cues.is_empty(), "ordinary MOVE still requires mapped direction")

func v2_event(semantic: String, phase: String, number: int, attempt: int = 1) -> Dictionary:
	# Owner01 PROFILE_DELTA_03 literal A shape; synthetic authorization, not Safety proof.
	var sample := runtime_shape_event(semantic, phase, number)
	sample.schema_version = 2
	sample.contract_version = "game_feel.event.v2"
	sample.attempt_id = attempt
	sample.presentation_identity.attempt_id = attempt
	if sample.transition_identity is Dictionary: sample.transition_identity.transaction_id = attempt
	sample.erase("authorized_path_points2")
	var trajectory := {"trajectory_version": "pfall.departure_cubic.v1", "departure_points2": [Vector3i(0, 6, 0), Vector3i(-2, 6, 0)], "descent_control_points2": [Vector3i(-2, 6, 0), Vector3i(-4, 6, 0), Vector3i(-6, 4, 8), Vector3i(-6, 2, 8)]}
	trajectory.departure_points2.make_read_only()
	trajectory.descent_control_points2.make_read_only()
	trajectory.make_read_only()
	sample.authorized_trajectory = trajectory
	if semantic == "PERSPECTIVE_FALL_APPLIED": sample.safety_verdict.evidence_ref.kind = "dyadic_cubic_cube_sweep.v1"
	return sample

func check_v2_lifecycle() -> void:
	var p = Policy.new()
	var start := v2_event("PERSPECTIVE_FALL_APPLIED", "STARTED", 1)
	var frozen := start.duplicate(true)
	var answer: Dictionary = p.consume(start, 0.0)
	check(answer.accepted and answer.cues == ["fall_start", "fall_whoosh"], "v2 STARTED sounds scoped Fall without landing")
	check(start == frozen and start.schema_version == 2 and start.contract_version == "game_feel.event.v2", "v2 envelope and authorized trajectory never rewritten to v1")
	check(p.consume(start, 0.1).cues.is_empty(), "v2 duplicate STARTED ignored")
	check(p.consume(runtime_shape_event("PERSPECTIVE_FALL_APPLIED", "COMMITTED", 2), 0.8).cues.is_empty(), "v1 COMMITTED cannot finish captured v2 Fall")
	var commit := v2_event("PERSPECTIVE_FALL_APPLIED", "COMMITTED", 3)
	answer = p.consume(commit, 0.8)
	check(answer.cues == ["landing_impact"] and answer.stop_identity == identity(), "v2 matching COMMITTED lands once and stops captured loop")
	commit.event_id = 4
	check(p.consume(commit, 0.9).cues.is_empty(), "v2 duplicate COMMITTED with fresh event id ignored")
	for reason in ["RESET", "CANCEL", "UNLOAD", "QUIT"]:
		p = Policy.new()
		p.consume(v2_event("PERSPECTIVE_FALL_APPLIED", "STARTED", 1), 0.0)
		var interrupt := v2_event("ANIMATION_INTERRUPTED", "INTERRUPTED", 2)
		interrupt.interruption_reason = reason
		answer = p.consume(interrupt, 0.1)
		check(answer.accepted and answer.stop_identity == identity() and answer.cues.is_empty(), "v2 scoped interruption stops without impact: " + reason)
		check(p.consume(v2_event("PERSPECTIVE_FALL_APPLIED", "COMMITTED", 3), 0.8).cues.is_empty(), "v2 no ghost landing after " + reason)
	p = Policy.new()
	p.consume(v2_event("PERSPECTIVE_FALL_APPLIED", "STARTED", 1), 0.0)
	p.consume(v2_event("PERSPECTIVE_FALL_APPLIED", "STARTED", 2, 2), 0.1)
	var old_interrupt := v2_event("ANIMATION_INTERRUPTED", "INTERRUPTED", 3)
	old_interrupt.interruption_reason = "CANCEL"
	p.consume(old_interrupt, 0.2)
	check(p.is_active(identity(2)), "v2 late old cancel leaves replacement Fall active")
	check(p.consume(v2_event("PERSPECTIVE_FALL_APPLIED", "COMMITTED", 4, 2), 0.8).cues == ["landing_impact"], "v2 replacement commits once after old scoped cancellation")
	for semantic in ["MOVE_APPLIED_NORMAL", "MOVE_REJECTED_EDGE", "ACTION_FEEDBACK"]:
		p = Policy.new()
		var wrong_kind := v2_event(semantic, "STARTED", 1)
		check(not p.consume(wrong_kind, 0.0).accepted, "v2 does not silently expand old semantic: " + semantic)
	for version in [[1, "game_feel.event.v2"], [2, "game_feel.event.v1"], [3, "game_feel.event.v3"]]:
		p = Policy.new()
		var unknown := v2_event("PERSPECTIVE_FALL_APPLIED", "STARTED", 1)
		unknown.schema_version = version[0]
		unknown.contract_version = version[1]
		check(not p.consume(unknown, 0.0).accepted, "unknown/mismatched version pair fails closed: " + str(version))
	for fault in ["missing", "unknown", "extra_field", "short_departure", "short_descent", "noncanonical", "out_of_range", "mutable", "string_safe", "wrong_evidence"]:
		p = Policy.new()
		var bad := v2_event("PERSPECTIVE_FALL_APPLIED", "STARTED", 1)
		var trajectory: Dictionary = bad.authorized_trajectory.duplicate(true)
		match fault:
			"missing": bad.erase("authorized_trajectory")
			"unknown": trajectory.trajectory_version = "pfall.unknown.v9"
			"extra_field": trajectory.extra = true
			"short_departure": trajectory.departure_points2 = [Vector3i.ZERO]
			"short_descent": trajectory.descent_control_points2 = [Vector3i.ZERO]
			"noncanonical": trajectory.departure_points2[0] = Vector3.ZERO
			"out_of_range": trajectory.departure_points2[0] = Vector3i(1000001, 0, 0)
			"string_safe": bad.safety_verdict = "SAFE"
			"wrong_evidence": bad.safety_verdict.evidence_ref.kind = "exact_linear_cube_sweep.v1"
		if fault != "missing":
			if fault != "mutable":
				trajectory.departure_points2.make_read_only()
				trajectory.descent_control_points2.make_read_only()
				trajectory.make_read_only()
			bad.authorized_trajectory = trajectory
		# An old polyline never rescues a missing/unsupported v2 trajectory.
		bad.authorized_path_points2 = [Vector3i.ZERO, Vector3i.ONE]
		check(not p.consume(bad, 0.0).accepted, "v2 curve authority fails closed with no legacy fallback: " + fault)
	p = Policy.new()
	p.consume(v2_event("PERSPECTIVE_FALL_APPLIED", "STARTED", 1), 0.0)
	var changed := v2_event("PERSPECTIVE_FALL_APPLIED", "COMMITTED", 2)
	var changed_trajectory: Dictionary = changed.authorized_trajectory.duplicate(true)
	changed_trajectory.descent_control_points2[1] = Vector3i(-4, 8, 0)
	changed_trajectory.departure_points2.make_read_only()
	changed_trajectory.descent_control_points2.make_read_only()
	changed_trajectory.make_read_only()
	changed.authorized_trajectory = changed_trajectory
	check(p.consume(changed, 0.8).cues.is_empty(), "v2 same token cannot land with a changed authorized curve")
	check(p.consume(v2_event("PERSPECTIVE_FALL_APPLIED", "COMMITTED", 3), 0.8).cues == ["landing_impact"], "v2 original authorized curve remains committable after rejected mismatch")
	p = Policy.new()
	p.consume(v2_event("PERSPECTIVE_FALL_APPLIED", "STARTED", 1), 0.0)
	var wrong_version_interrupt := event("ANIMATION_INTERRUPTED", "INTERRUPTED", 2)
	wrong_version_interrupt.interruption_reason = "CANCEL"
	check(not p.consume(wrong_version_interrupt, 0.1).accepted and p.is_active(identity()), "v1 interruption cannot cancel a live v2 captured identity")
	check(p.consume(v2_event("PERSPECTIVE_FALL_APPLIED", "COMMITTED", 3), 0.8).cues == ["landing_impact"], "v2 Fall remains committable after wrong-version interruption")
	p = Policy.new()
	var numeric_version := v2_event("PERSPECTIVE_FALL_APPLIED", "STARTED", 1)
	numeric_version.schema_version = 2.0
	check(not p.consume(numeric_version, 0.0).accepted, "floating schema value cannot impersonate exact integer version")
