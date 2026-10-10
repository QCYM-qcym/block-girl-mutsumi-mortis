extends SceneTree
## Headless real Runtime authorization + real10A sampling; never Graphical PASS.
const Maps = preload("res://experiments/game_feel_01/maps/map_factory.gd")
const Facade = preload("res://foundation/game_feel/runtime_facade.gd")
const Geometry = preload("res://foundation/spatial/surface_geometry.gd")
const View = preload("res://foundation/game_feel/view_contract.gd")
const Key = preload("res://foundation/contracts/state_key.gd")
const Fall = preload("res://game/feel/animation/fall_landing/fall_motion.gd")
const Capture = preload("res://tests/beta_sprint/game_feel_owner_03/capture_identity.gd")
const Observations = preload("res://tests/beta_sprint/game_feel_owner_03/forward_drop_observations.gd")
var checks := 0
var failures: Array[String] = []
var rows: Array = []
var evidence := ""
func _initialize() -> void:
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--evidence="): evidence = arg.trim_prefix("--evidence=")
	call_deferred("run")
func check(ok: bool, label: String) -> void:
	checks += 1
	if not ok: failures.append(label)
func run() -> void:
	for letter in ["a", "b"]:
		var baked: Dictionary = Maps.bake_game_feel(Maps.read_spec(letter))
		check(baked.ok, letter + " public real Baker")
		if not baked.ok: continue
		var level: Dictionary = baked.level
		check(level.schema_version == 3, letter + " actual authorized curve profile")
		var runtime := Facade.new()
		var events: Array = []
		runtime.game_feel_event.connect(func(event): events.append(event.duplicate(true)))
		check(runtime.load_level(level).ok, letter + " real Facade loaded")
		var before: Dictionary = runtime.get_state()
		var before_key: String = Key.build(level, before).key
		var result: Dictionary = runtime.request_action({"kind": 0, "face_axis": 2})
		var starts: Array = events.filter(func(e): return e.phase == "STARTED" and e.semantic == "PERSPECTIVE_FALL_APPLIED")
		check(result.status == 0 and starts.size() == 1, letter + " actual forward MOVE reserves one native Fall")
		if starts.size() != 1:
			runtime.interrupt("UNLOAD")
			continue
		var event: Dictionary = starts[0]
		check(event.target_pose.location.cube_id == &"target" and event.target_pose.location.face == 4, letter + " formal yellow target/TOP")
		var spatial: Dictionary = Geometry.snapshot(level, before)
		check(spatial.ok, letter + " real formal Spatial source")
		if not spatial.ok:
			runtime.interrupt("UNLOAD")
			continue
		var anchor: Dictionary = {}
		for a in spatial.value.anchors:
			if a.face_id == &"source/TOP" and a.layer == before.player.location.layer: anchor = a
		check(not anchor.is_empty(), letter + " unique source support")
		if anchor.is_empty():
			runtime.interrupt("UNLOAD")
			continue
		var source := Vector3(anchor.position2 + anchor.frame.normal) * 0.5
		var forward := -Vector3(anchor.frame.u)
		var normal := Vector3(anchor.frame.normal)
		var down := -View.basis(before.camera_quadrant).y
		for reduced in [false, true]:
			var motion := Fall.new()
			motion.parameters.reduced_motion = reduced
			var started: Dictionary = motion.begin(event)
			var label: String = letter + " reduced=" + str(reduced)
			check(started.ok, label + " actual10A consumes actual native STARTED and SAFE attestation")
			if not started.ok: continue
			var samples: Array = []
			for i in 241:
				var elapsed: float = started.duration_seconds * float(i) / 240.0
				var sample: Dictionary = motion.sample(elapsed)
				check(sample.active and sample.position is Vector3 and sample.identity == event.presentation_identity, label + " actual immutable sample identity")
				if not sample.position is Vector3: continue
				samples.append({"elapsed": elapsed, "position": sample.position, "rotation_offset": sample.rotation_offset, "phase": sample.phase})
			var measured: Dictionary = Observations.measure(samples, source, forward, normal, down)
			check(measured.first_timed_forward, label + " CASE01 first timed sample already moves forward; no stationary anticipation")
			check(measured.source_edge_before_descent and measured.first_descent_time > 0.0, label + " CASE02 source COM clears half-unit edge before leaving support plane")
			check(measured.forward_only and measured.screen_descending, label + " authorized forward inertia and visual descent")
			if not reduced:
				check(measured.stationary_intervals == 0, label + " CASE05 no positive-time stationary interval during motion")
				check(measured.early_intervals > 0 and measured.late_intervals > 0 and measured.late_speed > measured.early_speed, label + " CASE05 later descent faster than early descent; no pre-contact float brake")
			var cadence_points: Array = []
			for fraction in [0.15, 0.35, 0.65, 0.85]:
				var at: float = measured.first_descent_time + (started.duration_seconds - measured.first_descent_time) * fraction
				cadence_points.append({"elapsed": at, "position": motion.sample(at).position})
			var cadence: Dictionary = Observations.cadence(event.authorized_trajectory, cadence_points, before.camera_quadrant)
			check(cadence.ok, label + " observed timing remains on actual authorized geometry")
			if not reduced:
				check(cadence.get("accelerates", false), label + " CASE05 geometry parameter accelerates over equal descent-time bands; uniform floating timing rejected")
			check(samples[0].position == source and samples[-1].position == Vector3(-3, 1 if letter == "a" else 5, 4), label + " exact formal endpoints retained")
			if not reduced:
				var leaving: Array = samples.filter(func(s): return (s.position - source).dot(forward) > 0.5 and absf((s.position - source).dot(normal)) < 0.000001)
				check(not leaving.is_empty() and leaving[0].rotation_offset.get_angle() > 0.000001, label + " forward lean retained at observed edge leave")
			check(runtime.get_state() == before and Key.build(level, runtime.get_state()).key == before_key and runtime.get_commit_count() == 0, label + " sampling never mutates real Runtime or completes transition")
			rows.append({"map": letter, "reduced": reduced, "level_hash": level.content_hash, "started": event, "source": source, "forward": forward, "normal": normal, "support_half_extent": 0.5, "samples": samples, "measurement": measured, "cadence": cadence})
			motion.cancel(event.presentation_identity)
			check(not motion.sample(started.duration_seconds).active, label + " real sampler cancellation clears identity")
		runtime.interrupt("CANCEL")
		check(runtime.get_state() == before and runtime.get_commit_count() == 0, letter + " no manual native completion; real cancellation restores unchanged state")
	var capture := Capture.snapshot("FORWARD_DROP_HEADLESS_REAL_AUTHORIZED_SAMPLER")
	capture.authoritative_runtime = true
	FileAccess.open(evidence.path_join("report.json"), FileAccess.WRITE).store_string(JSON.stringify({"task": "PFALL_FORWARD_THEN_DROP_TO_YELLOW_FIX_01", "checks": checks, "failures": failures, "doubles": [], "scope": "NEW_PROFILE_REAL", "profile": "foundation.game_feel.v2", "analysis_mode": "HEADLESS_REAL_AUTHORIZED_SAMPLER_ONLY", "graphical": "NOT_RUN", "capture": capture, "rows": rows}, "\t"))
	quit(0 if failures.is_empty() else 1)
