extends "res://tests/beta_sprint/game_feel_owner_03/test_v2_graphical_trace.gd"
## New task assertions against real mode1 frame evidence; old PASS is never reused.
const Observations = preload("res://tests/beta_sprint/game_feel_owner_03/forward_drop_observations.gd")
var forward_measurements: Array = []

func verify_step(level: Dictionary, witness: Dictionary, step: Dictionary, index: int, label: String) -> void:
	super.verify_step(level, witness, step, index, label)
	if index != 0: return
	var completion: Dictionary = step.get("completion_evidence", {})
	var frames: Array = completion.get("frames", []).filter(func(f): return f.get("phase") == "FALL")
	var source_state: Dictionary = witness.initial_state
	var spatial: Dictionary = Geometry.snapshot(level, source_state)
	check(spatial.ok and frames.size() > 8, label + " actual renderer source and enough timed Fall frames")
	if not spatial.ok or frames.size() <= 8: return
	var source_anchor: Dictionary = {}
	for anchor in spatial.value.anchors:
		if anchor.face_id == &"source/TOP" and anchor.layer == source_state.player.location.layer: source_anchor = anchor
	check(not source_anchor.is_empty(), label + " formal source edge geometry")
	if source_anchor.is_empty(): return
	var source := Vector3(source_anchor.position2 + source_anchor.frame.normal) * 0.5
	var forward := -Vector3(source_anchor.frame.u)
	var normal := Vector3(source_anchor.frame.normal)
	var down := -View.basis(source_state.camera_quadrant).y
	var observations: Array = frames.map(func(f): return {"elapsed": f.elapsed, "position": vector(f.pose.origin)})
	var measured: Dictionary = Observations.measure(observations, source, forward, normal, down)
	check(measured.first_timed_forward, label + " CASE01 actual first timed forward displacement")
	check(measured.source_edge_before_descent and measured.first_descent_time > 0.0, label + " CASE02 actual center clears source edge before leaving support plane")
	check(measured.forward_only and measured.screen_descending, label + " actual forward inertia and descending projection")
	check(measured.stationary_intervals == 0, label + " CASE05 actual motion has no positive-time stationary pause")
	check(measured.early_intervals > 0 and measured.late_intervals > 0 and measured.late_speed > measured.early_speed, label + " CASE05 later observed descent faster than early descent")
	var cadence_points: Array = []
	for fraction in [0.15, 0.35, 0.65, 0.85]:
		var wanted_time: float = measured.first_descent_time + (observations[-1].elapsed - measured.first_descent_time) * fraction
		var closest: Dictionary = observations[0]
		for observation in observations:
			if absf(observation.elapsed - wanted_time) < absf(closest.elapsed - wanted_time): closest = observation
		cadence_points.append(closest)
	var cadence: Dictionary = Observations.cadence(level.perspective_falls[0].trajectory, cadence_points, source_state.camera_quadrant)
	check(cadence.ok and cadence.get("accelerates", false), label + " CASE05 actual rendered geometry progress accelerates rather than uniform floating timing")
	check(completion.target_pose.location.cube_id == &"target" and completion.target_pose.location.face == 4, label + " CASE03 formal yellow TOP rather than blue_reference")
	forward_measurements.append({"label": label, "level_hash": level.content_hash,
		"transition_identity": step.transition_identity, "source": source, "forward": forward,
		"source_support_half_extent": 0.5, "measurements": measured, "cadence": cadence, "observations": observations})

func run() -> void:
	await super.run()
	var path := evidence.path_join("report.json")
	var report: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(path))
	report.task = "PFALL_FORWARD_THEN_DROP_TO_YELLOW_FIX_01"
	report.scope = "NEW_PROFILE_REAL"
	report.profile = "foundation.game_feel.v2"
	report.forward_measurements = forward_measurements
	report.capture.fixture_kind = "REAL_FORMAL_FORWARD_DROP_MAP_AB"
	report.natural_six_phase = "Separate new-task00 rendered evidence required; no oldyellow screenshots reused"
	report.human_feel = "NOT_RUN; quantitative speed and frame evidence do not certify human feel"
	FileAccess.open(path, FileAccess.WRITE).store_string(JSON.stringify(report, "\t"))
