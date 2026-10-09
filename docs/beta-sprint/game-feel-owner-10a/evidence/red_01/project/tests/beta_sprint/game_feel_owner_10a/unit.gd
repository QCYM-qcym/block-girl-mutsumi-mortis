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
		check(motion.begin(event).ok, "cube24 begin=" + str(orientation))
		var endpoint: Dictionary = motion.sample(10.0)
		check(endpoint.rotation_offset == Quaternion.IDENTITY and endpoint.scale_multiplier == Vector3.ONE, "cube24 exact endpoint=" + str(orientation))
		motion.clear()
		check(landing.begin(Fixture.committed(event)).ok, "cube24 committed=" + str(orientation))
		endpoint = landing.sample(10.0)
		check(endpoint.rotation_offset == Quaternion.IDENTITY and endpoint.scale_multiplier == Vector3.ONE, "cube24 landing endpoint=" + str(orientation))
		landing.clear()
	finish()

func finish() -> void:
	var report := {"fixture_kind": "PRESENTATION_CONTRACT_UNIT", "authoritative_runtime": false,
		"doubles": ["01 DTO", "Safety attestation", "native commit"], "checks": checks, "failures": failures,
		"pid": OS.get_process_id(), "user_data_dir": OS.get_user_data_dir(), "display": DisplayServer.get_name(),
		"renderer": RenderingServer.get_current_rendering_method(), "input": "direct sampling API, no gameplay input"}
	FileAccess.open(evidence.path_join("report.json"), FileAccess.WRITE).store_string(JSON.stringify(report, "\t"))
	print("10A_PRESENTATION_UNIT checks=", checks, " failures=", failures.size(), " authority=false")
	quit(0 if failures.is_empty() else 1)
