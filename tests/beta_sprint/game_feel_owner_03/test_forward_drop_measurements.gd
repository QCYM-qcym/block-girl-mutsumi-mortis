extends SceneTree
## Unit measurement checks on hand-derived points; no Gameplay or Real PASS.
const Observe = preload("res://tests/beta_sprint/game_feel_owner_03/forward_drop_observations.gd")
var evidence := ""
var checks := 0
var failures: Array[String] = []
func _initialize() -> void:
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--evidence="): evidence = arg.trim_prefix("--evidence=")
	call_deferred("run")
func check(ok: bool, label: String) -> void:
	checks += 1
	if not ok: failures.append(label)
func run() -> void:
	var trajectory := {"trajectory_version": "pfall.departure_cubic.v1",
		"departure_points2": [Vector3i(0,6,0), Vector3i(-2,6,0)],
		"descent_control_points2": [Vector3i(-2,6,0), Vector3i(-4,6,0), Vector3i(-6,4,8), Vector3i(-6,2,8)]}
	var parameter := Observe.observed_parameter(trajectory, Vector3(-53.0/27,73.0/27,28.0/27), 1)
	check(parameter.ok and absf(parameter.parameter - 0.5) < 0.000001, "hand-derived rational point resolves actual geometry parameter")
	check(not Observe.observed_parameter(trajectory, Vector3(900,0,0), 1).ok, "off-path observation cannot qualify timing")
	var positions := [
		{"elapsed":0.0, "position":Vector3(-1,3,0)},
		{"elapsed":1.0, "position":Vector3(-53.0/27,73.0/27,28.0/27)},
		{"elapsed":2.0, "position":Vector3(-73.0/27,53.0/27,80.0/27)},
		{"elapsed":3.0, "position":Vector3(-3,1,4)}]
	var uniform := Observe.cadence(trajectory, positions, 1)
	check(uniform.ok and not uniform.accelerates, "uniform geometry timing cannot pass accelerated cadence")
	positions[3].elapsed = 2.5
	var accelerated := Observe.cadence(trajectory, positions, 1)
	check(accelerated.ok and accelerated.accelerates, "actual elapsed normalization detects twice-faster late band")
	var stationary := Observe.measure([{"elapsed":0.0,"position":Vector3.ZERO}, {"elapsed":0.1,"position":Vector3.ZERO}, {"elapsed":0.2,"position":Vector3(-0.2,0,0)}], Vector3.ZERO, Vector3.LEFT, Vector3.UP, Vector3.LEFT)
	check(not stationary.first_timed_forward and stationary.stationary_intervals == 1, "stationary anticipation is observable failure")
	var early_drop := Observe.measure([{"elapsed":0.0,"position":Vector3.ZERO}, {"elapsed":0.1,"position":Vector3(-0.2,-0.1,0)}, {"elapsed":0.2,"position":Vector3(-1,-1,1)}], Vector3.ZERO, Vector3.LEFT, Vector3.UP, Vector3.LEFT)
	check(not early_drop.source_edge_before_descent, "COM still supported cannot descend")
	var after_edge := Observe.measure([{"elapsed":0.0,"position":Vector3.ZERO}, {"elapsed":0.1,"position":Vector3(-0.6,0,0)}, {"elapsed":0.2,"position":Vector3(-1,-0.1,1)}], Vector3.ZERO, Vector3.LEFT, Vector3.UP, Vector3.LEFT)
	check(after_edge.first_timed_forward and after_edge.source_edge_before_descent, "forward clearance before leaving support plane")
	var duplicate_clock := Observe.measure([{"elapsed":0.0,"position":Vector3.ZERO}, {"elapsed":0.0,"position":Vector3.ZERO}, {"elapsed":0.1,"position":Vector3(-0.2,0,0)}], Vector3.ZERO, Vector3.LEFT, Vector3.UP, Vector3.LEFT)
	check(duplicate_clock.first_timed_forward and duplicate_clock.stationary_intervals == 0, "same-clock renderer observation is not a motion pause")
	FileAccess.open(evidence.path_join("report.json"),FileAccess.WRITE).store_string(JSON.stringify({"checks":checks,"failures":failures,"scope":"UNIT_MEASUREMENT_ONLY","fixture_kind":"HAND_DERIVED_POINT_AND_TIME_DATA","authoritative_runtime":false,"real_pass":false,"doubles":[]},"\t"))
	quit(0 if failures.is_empty() else 1)
