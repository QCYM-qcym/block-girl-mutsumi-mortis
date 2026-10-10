extends "res://tests/beta_sprint/game_feel_owner_10a/curve_unit.gd"
## New task diagnostics; real committed geometry sampler, explicit authority doubles.
var diagnostics: Array = []

func run() -> void:
	var Fall = load("res://game/feel/animation/fall_landing/fall_motion.gd")
	var Trajectory = load("res://foundation/game_feel/trajectory_profile.gd")
	var View = load("res://foundation/game_feel/view_contract.gd")
	for higher in [false, true]:
		var event := Fixture.curve_event(higher)
		event.presentation_duration_seconds = 0.3
		var motion = Fall.new()
		var begun: Dictionary = motion.begin(event)
		check(begun.ok, "new forward/drop task starts " + str(higher))
		if not begun.ok: continue
		var start: Vector3 = motion.sample(0.0).position
		var first: Dictionary = motion.sample(0.015)
		check(first.position.distance_to(start) > 0.01, "forward movement starts with input, no stationary anticipation")
		check(first.rotation_offset.get_angle() > 0.005, "early forward motion already leans toward departure")
		var join: float = begun.phase_schedule.FALL_MOVING
		var edge: Dictionary = motion.sample(join)
		check(edge.position == Vector3(-1,3,0), "departure completes at author D")
		check(edge.rotation_offset.get_angle() > 0.04, "departure keeps lean through cleared edge")
		var early: float = parameter_at(motion.sample(join + (0.3 - join) * 0.2).position, event.authorized_trajectory, Trajectory) - 0.25
		var late: float = 1.0 - parameter_at(motion.sample(join + (0.3 - join) * 0.8).position, event.authorized_trajectory, Trajectory)
		check(late > early * 1.2, "late descent accelerates along authorized geometry rather than uniform floating")
		var previous := start
		var previous_parameter := 0.0
		var down: Vector3 = -View.basis(event.camera_quadrant).y
		var rows: Array = []
		for i in range(1, 121):
			var time := 0.3 * float(i) / 120.0
			var sampled: Dictionary = motion.sample(time)
			var parameter := parameter_at(sampled.position, event.authorized_trajectory, Trajectory)
			check(parameter > previous_parameter, "every pre-contact sample advances, no air pause")
			check(sampled.position.distance_to(previous) < 0.25, "continuous forward/drop motion without teleport")
			check(sampled.position.dot(down) + 0.00001 >= previous.dot(down), "fixed formal view descends even with rising world Y")
			if sampled.position.x >= -0.5:
				check(sampled.position.y == 3.0, "no normal drop while COM remains over source support")
			rows.append({"time":time,"position":[sampled.position.x,sampled.position.y,sampled.position.z],"parameter":parameter,"lean_radians":sampled.rotation_offset.get_angle(),"phase":sampled.phase})
			previous = sampled.position
			previous_parameter = parameter
		diagnostics.append({"higher_target":higher,"initial_advance":first.position.distance_to(start),"initial_lean":first.rotation_offset.get_angle(),"join_time":join,"join_lean":edge.rotation_offset.get_angle(),"early_parameter_advance":early,"late_parameter_advance":late,"rows":rows})
		print("FORWARD_DROP_DIAGNOSTIC higher=", higher, " initial_advance=", first.position.distance_to(start), " early=", early, " late=", late, " join_lean=", edge.rotation_offset.get_angle())
		motion.clear()
	finish()

func parameter_at(position: Vector3, trajectory: Dictionary, sampler: Script) -> float:
	if position == sampler.sample_actor_center(trajectory, 0.0).position: return 0.0
	if position == sampler.sample_actor_center(trajectory, 1.0).position: return 1.0
	# Independent diagnostic inversion of the A/B monotone x coordinate, using
	# the actual formal sampler. No duplicate Bezier evaluator, no production use.
	var lo := 0.0
	var hi := 1.0
	for i in 28:
		var mid := (lo + hi) * 0.5
		if sampler.sample_actor_center(trajectory, mid).position.x > position.x: lo = mid
		else: hi = mid
	return (lo + hi) * 0.5

func finish() -> void:
	FileAccess.open(evidence.path_join("diagnostics.json"), FileAccess.WRITE).store_string(JSON.stringify(diagnostics, "\t"))
	super.finish()
