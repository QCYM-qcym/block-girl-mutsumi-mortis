extends SceneTree
const Fixture = preload("res://tests/beta_sprint/game_feel_owner_10a/fixture.gd")
var checks := 0
var failures: Array[String] = []
var evidence := ""

func _initialize() -> void:
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--evidence-dir="): evidence = arg.trim_prefix("--evidence-dir=")
	call_deferred("run")

func check(ok: bool, label: String) -> void:
	checks += 1
	if not ok:
		failures.append(label)
		printerr("FAIL 10A: ", label)

func run() -> void:
	var paths := ["res://game/feel/animation/fall_landing/fall_motion.gd", "res://game/feel/animation/fall_landing/landing_motion.gd"]
	for path in paths:
		check(ResourceLoader.exists(path), "independent sampler exists: " + path)
	if not failures.is_empty():
		finish()
		return
	var Fall = load(paths[0])
	var Landing = load(paths[1])
	check(Fall.can_instantiate() and Landing.can_instantiate(), "samplers compile")
	if not failures.is_empty():
		finish()
		return
	var motion = Fall.new()
	var landing = Landing.new()
	var Orientation = load("res://foundation/orientation/discrete_orientation.gd")
	# A phase label must not restart path velocity or create an air pause.
	for duration in [0.3, 0.8]:
		for reduced in [false, true]:
			var continuity_event := Fixture.event()
			continuity_event.presentation_duration_seconds = duration
			motion.parameters.reduced_motion = reduced
			var started: Dictionary = motion.begin(continuity_event)
			check(started.ok, "timing continuity starts")
			var join: float = started.cue_schedule.FallMoving
			var step: float = duration * 0.0001
			var center: Vector3 = motion.sample(join).position
			var before_velocity: Vector3 = (center - motion.sample(join - step).position) / step
			var after_velocity: Vector3 = (motion.sample(join + step).position - center) / step
			print("10A_JOIN duration=", duration, " reduced=", reduced, " before=", before_velocity.length(), " after=", after_velocity.length())
			check(before_velocity.length() > 0.1 and after_velocity.length() > 0.1, "no air pause at departure/fall boundary")
			check(before_velocity.distance_to(after_velocity) < maxf(before_velocity.length(), after_velocity.length()) * 0.04, "departure/fall velocity continuous")
			motion.clear()
	motion.parameters.reduced_motion = false
	for higher in [false, true]:
		var event := Fixture.event(higher)
		var original := event.duplicate(true)
		check(motion.begin(event).ok, "accepted Unit starts, height sign=" + str(higher))
		var first: Dictionary = motion.sample(0.0)
		check(first.position == Vector3(event.authorized_path_points2[0]) * 0.5, "exact source center")
		var previous: Vector3 = first.position
		for i in range(1, 241):
			var sampled: Dictionary = motion.sample(event.presentation_duration_seconds * float(i) / 240.0)
			check(sampled.identity == event.presentation_identity and sampled.position.is_finite(), "captured identity and finite path")
			check(sampled.position.distance_to(previous) < 0.2, "continuous path without teleport")
			check(on_path(sampled.position, event.authorized_path_points2), "sampling stays on authorized polyline, no generated control point")
			previous = sampled.position
		var end: Dictionary = motion.sample(event.presentation_duration_seconds)
		check(end.motion_done and end.position == Vector3(event.authorized_path_points2[-1]) * 0.5, "exact authorized target")
		check(end.rotation_offset == Quaternion.IDENTITY and end.scale_multiplier == Vector3.ONE, "fall ends neutral")
		check(event == original, "consumer never changes event/World/player state")
		check(not landing.begin(event).ok, "STARTED cannot play impact")
		check(landing.begin(Fixture.committed(event)).ok, "matching COMMITTED starts landing")
		var impact: Dictionary = landing.sample(0.04)
		check(impact.position == null and impact.scale_multiplier.y < 1.0, "impact compression only, no landing position override")
		var settled: Dictionary = landing.sample(10.0)
		check(settled.motion_done and settled.rotation_offset == Quaternion.IDENTITY and settled.scale_multiplier == Vector3.ONE, "landing exact neutral recovery")
		motion.clear()
		landing.clear()
	# Full identities, snapshots, rejection and elapsed bounds.
	var old := Fixture.event(false, 0, 4)
	check(motion.begin(old).ok, "new presentation after previous completion")
	check(not motion.begin(old).ok, "duplicate begin does not restart")
	var new_event := Fixture.event(false, 0, 5)
	check(not motion.begin(new_event).ok, "active sampler requires host preemption")
	motion.cancel(old.presentation_identity)
	check(not motion.sample(0.3).active and motion.sample(0.3).position == null, "matching cancel synchronous neutral")
	check(motion.begin(new_event).ok, "new launch after cancel")
	motion.cancel(old.presentation_identity)
	check(motion.sample(0.3).identity == new_event.presentation_identity, "late cancel cannot clear new launch")
	var snapshot: Dictionary = motion.sample(0.3)
	snapshot.identity.attempt_id = -1
	new_event.authorized_path_points2[0] = Vector3i(999, 999, 999)
	check(motion.sample(0.0).position == Vector3(0, 3, 0) and motion.sample(0.0).identity.attempt_id == 5, "deep snapshot ownership")
	check(not motion.sample(NAN).active and not motion.sample(INF).active, "nonfinite time fails neutral")
	check(motion.sample(-2.0).position == Vector3(0, 3, 0), "negative time clamps to source")
	motion.clear()
	for field in ["schema_version", "presentation_identity", "target_pose", "authorized_path_points2", "source_frame", "safety_verdict"]:
		var invalid := Fixture.event()
		invalid.erase(field)
		check(not motion.begin(invalid).ok and not motion.sample(0.2).active, "missing field fails closed: " + field)
	for phase in ["FEEDBACK", "REJECTED", "COMMITTED", "INTERRUPTED"]:
		var invalid := Fixture.event()
		invalid.phase = phase
		check(not motion.begin(invalid).ok, "non-STARTED cannot initiate Fall: " + phase)
	# 24 pose IDs; host composes identity offsets onto unchanged authoritative Basis.
	for orientation in 24:
		var event := Fixture.event(false, orientation, orientation + 20)
		var columns: Array = Orientation.columns(orientation)
		var authoritative_basis := Basis(Vector3(columns[0]), Vector3(columns[1]), Vector3(columns[2]))
		check(motion.begin(event).ok, "cube24 begin=" + str(orientation))
		var endpoint: Dictionary = motion.sample(10.0)
		check(endpoint.rotation_offset == Quaternion.IDENTITY and endpoint.scale_multiplier == Vector3.ONE, "cube24 exact endpoint=" + str(orientation))
		check(Basis(endpoint.rotation_offset) * Basis.from_scale(endpoint.scale_multiplier) * authoritative_basis == authoritative_basis, "actual cube24 Fall Basis MATCH=" + str(orientation))
		motion.clear()
		check(landing.begin(Fixture.committed(event)).ok, "cube24 committed=" + str(orientation))
		endpoint = landing.sample(10.0)
		check(endpoint.rotation_offset == Quaternion.IDENTITY and endpoint.scale_multiplier == Vector3.ONE, "cube24 landing endpoint=" + str(orientation))
		check(Basis(endpoint.rotation_offset) * Basis.from_scale(endpoint.scale_multiplier) * authoritative_basis == authoritative_basis, "actual cube24 Landing Basis MATCH=" + str(orientation))
		landing.clear()
	# Pause is caller-clock suspension: repeated absolute-time samples are equal.
	var event := Fixture.event()
	check(motion.begin(event).ok, "pause fixture begins")
	check(motion.sample(0.4) == motion.sample(0.4), "pause unchanged sample and identity")
	var fixed: Dictionary = motion.sample(0.35)
	motion.parameters.anticipation_angle_degrees = 10.0
	check(motion.sample(0.35) == fixed, "config mutation cannot change in-flight sample")
	motion.clear()
	motion.parameters.reduced_motion = true
	check(motion.begin(event).ok, "Reduced Motion Fall begins")
	for i in 101:
		var reduced: Dictionary = motion.sample(float(i) * 0.008)
		check(reduced.rotation_offset == Quaternion.IDENTITY and reduced.scale_multiplier == Vector3.ONE and on_path(reduced.position, event.authorized_path_points2), "Reduced Motion continuous path, no lean")
	motion.clear()
	landing.parameters.reduced_motion = true
	check(landing.begin(Fixture.committed(event)).ok, "Reduced Motion landing begins")
	check(landing.sample(0.04).scale_multiplier == Vector3.ONE and landing.sample(0.12).rotation_offset == Quaternion.IDENTITY, "Reduced Motion neutral landing")
	landing.cancel(event.presentation_identity)
	check(not landing.sample(0.1).active and landing.sample(0.1).position == null, "landing cancelled neutral")
	var minimal_commit := Fixture.committed(event)
	for key in ["source_frame", "orientation_policy", "authorized_path_points2", "presentation_duration_seconds", "safety_verdict", "motion_profile_id", "motion_profile_hash", "connection_id"]: minimal_commit.erase(key)
	check(landing.begin(minimal_commit).ok, "COMMITTED works without STARTED-only path/frame/profile fields")
	landing.clear()
	motion.parameters.reduced_motion = false
	# Malformed authority/classification/profile/timing records fail atomically.
	for field in ["world_id", "camera_quadrant", "authoritative_final_orientation", "reason_category", "motion_profile_hash", "presentation_duration_seconds", "orientation_policy"]:
		var invalid := Fixture.event()
		invalid[field] = -1 if field in ["world_id", "camera_quadrant", "authoritative_final_orientation", "presentation_duration_seconds"] else "INVALID"
		if field == "motion_profile_hash": invalid[field] = ""
		check(not motion.begin(invalid).ok and not motion.sample(0.3).active, "invalid consumer field fails: " + field)
	var unsafe := Fixture.event()
	unsafe.safety_verdict = "UNPROVEN"
	check(not motion.begin(unsafe).ok, "unproven profile rejected by consumer")
	var mismatch := Fixture.event()
	mismatch.transition_identity.generation += 1
	check(not motion.begin(mismatch).ok, "mismatched transaction generation rejected")
	var rejected := Fixture.event()
	rejected.result.status = 1
	check(not motion.begin(rejected).ok, "rejected Runtime result cannot play Fall")
	var degenerate := Fixture.event()
	degenerate.authorized_path_points2 = [Vector3i.ZERO, Vector3i.ZERO]
	check(not motion.begin(degenerate).ok, "zero-length path rejected")
	var cornered := Fixture.event()
	cornered.authorized_path_points2 = [Vector3i(0,6,0), Vector3i(0,6,0), Vector3i(-2,6,2), Vector3i(-2,4,2), Vector3i(-8,2,8)]
	check(motion.begin(cornered).ok, "duplicate knots and author corners retained")
	for i in 241:
		check(on_path(motion.sample(float(i) / 300.0).position, cornered.authorized_path_points2), "corners sampled without cutting author path")
	motion.clear()
	motion.parameters.fall_curve = Curve.new()
	motion.parameters.fall_curve.add_point(Vector2(0,0))
	motion.parameters.fall_curve.add_point(Vector2(0.5,0.8))
	motion.parameters.fall_curve.add_point(Vector2(1,1))
	check(motion.begin(event).ok, "valid authored monotone easing accepted")
	motion.clear()
	motion.parameters.fall_curve = Curve.new()
	motion.parameters.fall_curve.add_point(Vector2(0,0))
	motion.parameters.fall_curve.add_point(Vector2(0.4,0.8))
	motion.parameters.fall_curve.add_point(Vector2(0.6,0.2))
	motion.parameters.fall_curve.add_point(Vector2(1,1))
	check(not motion.begin(event).ok, "nonmonotone easing rejected, no path reversal")
	motion.parameters.fall_curve = null
	motion.parameters.impact_compression = NAN
	check(not motion.begin(event).ok, "nonfinite parameter rejected")
	motion.parameters.impact_compression = 0.055
	# Actual Owner01 motion() DTO shape observed read-only in its WIP.
	# Shape fixture only: this does not import or claim a delivered Runtime port.
	var structured := Fixture.event()
	structured.safety_verdict = {"status": "SAFE", "issues": [], "evidence_ref": {
		"kind": "exact_linear_cube_sweep.v1", "level_hash": "UNIT_LEVEL_HASH",
		"connection_id": structured.connection_id, "profile_hash": structured.motion_profile_hash}}
	check(motion.begin(structured).ok, "Owner01 structured SAFE verdict compatible")
	check(motion.sample(0.8).position == Vector3(structured.authorized_path_points2[-1]) * 0.5, "structured verdict exact target")
	motion.clear()
	var legacy_scalar := Fixture.event()
	legacy_scalar.safety_verdict = "SAFE"
	check(motion.begin(legacy_scalar).ok, "original scalar presentation fixture stays compatible")
	motion.clear()
	for mutation in ["UNPROVEN", "issues", "profile", "connection", "evidence"]:
		var invalid := structured.duplicate(true)
		match mutation:
			"UNPROVEN": invalid.safety_verdict.status = "UNPROVEN"
			"issues": invalid.safety_verdict.issues = [{"message": "unresolved"}]
			"profile": invalid.safety_verdict.evidence_ref.profile_hash = "OTHER_PROFILE"
			"connection": invalid.safety_verdict.evidence_ref.connection_id = "OTHER_CONNECTION"
			"evidence": invalid.safety_verdict.erase("evidence_ref")
		check(not motion.begin(invalid).ok and not motion.sample(0.2).active, "structured attestation rejected: " + mutation)
	# All effect stages are interruptible; caller restores its authoritative base.
	for t in [0.04, 0.17, 0.5, 0.8]:
		check(motion.begin(event).ok, "phase cancellation begins")
		motion.sample(t)
		motion.cancel(event.presentation_identity)
		check(not motion.sample(t + 1.0).active and motion.sample(t).rotation_offset == Quaternion.IDENTITY and motion.sample(t).scale_multiplier == Vector3.ONE, "cancel neutral at each Fall phase")
	for t in [0.03, 0.15, 0.34]:
		check(landing.begin(Fixture.committed(event)).ok, "landing cancellation begins")
		landing.sample(t)
		landing.cancel(event.presentation_identity)
		check(not landing.sample(t + 1.0).active, "cancel neutral at each Landing phase")
	finish()

func on_path(point: Vector3, points: Array) -> bool:
	for i in range(1, points.size()):
		var a := Vector3(points[i - 1]) * 0.5
		var b := Vector3(points[i]) * 0.5
		var delta := b - a
		var amount := 0.0 if delta.length_squared() == 0 else clampf((point - a).dot(delta) / delta.length_squared(), 0, 1)
		if point.distance_to(a.lerp(b, amount)) < 0.00001: return true
	return false

func finish() -> void:
	var report := {"fixture_kind": "PRESENTATION_CONTRACT_UNIT", "authoritative_runtime": false,
		"doubles": ["01 DTO", "Safety attestation", "native commit"], "checks": checks, "failures": failures,
		"pid": OS.get_process_id(), "user_data_dir": OS.get_user_data_dir(), "display": DisplayServer.get_name(),
		"renderer": RenderingServer.get_current_rendering_method(), "input": "direct sampling API, no gameplay input"}
	FileAccess.open(evidence.path_join("report.json"), FileAccess.WRITE).store_string(JSON.stringify(report, "\t"))
	print("10A_PRESENTATION_UNIT checks=", checks, " failures=", failures.size(), " authority=false")
	quit(0 if failures.is_empty() else 1)
