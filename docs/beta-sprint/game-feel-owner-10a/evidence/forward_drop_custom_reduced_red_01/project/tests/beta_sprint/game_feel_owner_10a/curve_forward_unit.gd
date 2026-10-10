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
		check((Basis(first.rotation_offset) * Vector3.UP).dot(Vector3.LEFT) > 0.0, "initial lean is signed toward actual U_NEG, not backward")
		var join: float = begun.phase_schedule.FALL_MOVING
		check(begun.phase_schedule.get("FORWARD", -1.0) == 0.0, "forward phase starts immediately")
		var boundary: float = begun.phase_schedule.DEPARTURE
		check(motion.sample(boundary - 0.000003).phase == "FORWARD" and motion.sample(boundary + 0.000003).phase == "DEPARTURE", "edge phase brackets formal COM boundary")
		check(absf(motion.sample(boundary).position.x + 0.5) < 0.000001, "edge time derives from real unit support, not a screen waypoint")
		var edge: Dictionary = motion.sample(join)
		check(edge.position == Vector3(-1,3,0), "departure completes at author D")
		check(edge.rotation_offset.get_angle() > 0.04, "departure keeps lean through cleared edge")
		check((Basis(edge.rotation_offset) * Vector3.UP).dot(Vector3.LEFT) > 0.0, "cleared-edge lean remains forward")
		var step := 0.00003
		var velocity_before: Vector3 = (edge.position - motion.sample(join - step).position) / step
		var velocity_after: Vector3 = (motion.sample(join + step).position - edge.position) / step
		check(velocity_before.length() > 0.1 and velocity_before.distance_to(velocity_after) < velocity_before.length() * 0.02, "forward/descent join C1 and positive inertia")
		var early: float = parameter_at(motion.sample(join + (0.3 - join) * 0.2).position, event.authorized_trajectory, Trajectory) - 0.25
		var late: float = 1.0 - parameter_at(motion.sample(join + (0.3 - join) * 0.8).position, event.authorized_trajectory, Trajectory)
		check(late > early * 1.2, "late descent accelerates along authorized geometry rather than uniform floating")
		var previous := start
		var previous_parameter := 0.0
		var down: Vector3 = -View.basis(event.camera_quadrant).y
		var early_position: Vector3 = motion.sample(join + (0.3 - join) * 0.2).position
		var late_position: Vector3 = motion.sample(join + (0.3 - join) * 0.8).position
		var target: Vector3 = motion.sample(0.3).position
		var early_down: float = (early_position - edge.position).dot(down)
		var late_down: float = (target - late_position).dot(down)
		check(late_down > early_down * 1.5, "late actual formal-view descent gains impact force, not merely parameter acceleration")
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
		diagnostics.append({"higher_target":higher,"initial_advance":first.position.distance_to(start),"initial_lean":first.rotation_offset.get_angle(),"edge_time":boundary,"join_time":join,"join_lean":edge.rotation_offset.get_angle(),"join_velocity_before":[velocity_before.x,velocity_before.y,velocity_before.z],"join_velocity_after":[velocity_after.x,velocity_after.y,velocity_after.z],"early_parameter_advance":early,"late_parameter_advance":late,"early_formal_down_distance":early_down,"late_formal_down_distance":late_down,"rows":rows})
		print("FORWARD_DROP_DIAGNOSTIC higher=", higher, " initial_advance=", first.position.distance_to(start), " early=", early, " late=", late, " join_lean=", edge.rotation_offset.get_angle())
		motion.clear()
	# Reduced Motion preserves the physical progression, only lean is omitted.
	for higher in [false, true]:
		for duration in [0.3, 0.8]:
			var event := Fixture.curve_event(higher)
			event.presentation_duration_seconds = duration
			var original := event.duplicate(true)
			var regular = Fall.new()
			var reduced = Fall.new()
			reduced.parameters.reduced_motion = true
			var regular_begin: Dictionary = regular.begin(event)
			var reduced_begin: Dictionary = reduced.begin(event)
			check(regular_begin.ok and reduced_begin.ok, "new task reduced/regular begins")
			check(regular_begin.phase_schedule == reduced_begin.phase_schedule, "Reduced Motion preserves actual phase times")
			for i in 121:
				var time: float = duration * float(i) / 120.0
				var r: Dictionary = reduced.sample(time)
				check(r.position == regular.sample(time).position and r.rotation_offset == Quaternion.IDENTITY and r.scale_multiplier == Vector3.ONE, "Reduced Motion retains trajectory and simplifies decoration")
			check(event == original and regular.sample(duration).rotation_offset == Quaternion.IDENTITY, "new task World/pose DTO immutable and exact standing endpoint")
			check(regular.sample(duration).motion_done and regular.sample(duration).phase == "AWAITING_COMMIT", "visual arrival waits for authority, never manufactures impact")
			var frozen: Dictionary = regular.sample(duration * 0.5)
			regular.parameters.forward_duration_multiplier = 1.0
			regular.parameters.fall_entry_speed_ratio = 0.9
			check(regular.sample(duration * 0.5) == frozen, "new timing tunables frozen per identity")
			regular.cancel(event.presentation_identity)
			reduced.cancel(event.presentation_identity)
			check(not regular.sample(duration).active and not reduced.sample(duration).motion_done, "new task cancel neutral and not completion")
	# Authored timing must survive Reduced Motion too; only decoration changes.
	for higher in [false, true]:
		var event := Fixture.curve_event(higher)
		event.presentation_duration_seconds = 0.3
		var custom := Curve.new()
		custom.add_point(Vector2(0,0), 0, 0, Curve.TANGENT_LINEAR, Curve.TANGENT_LINEAR)
		custom.add_point(Vector2(0.5,0.8), 0, 0, Curve.TANGENT_LINEAR, Curve.TANGENT_LINEAR)
		custom.add_point(Vector2(1,1), 0, 0, Curve.TANGENT_LINEAR, Curve.TANGENT_LINEAR)
		var regular = Fall.new()
		var reduced = Fall.new()
		regular.parameters.fall_curve = custom
		reduced.parameters.fall_curve = custom
		reduced.parameters.reduced_motion = true
		var r_begin: Dictionary = regular.begin(event)
		var s_begin: Dictionary = reduced.begin(event)
		check(r_begin.ok and s_begin.ok, "authored timing begins in both motion modes")
		check(r_begin.phase_schedule == s_begin.phase_schedule, "custom Reduced Motion preserves edge and join timestamps")
		var previous: Vector3 = regular.sample(0).position
		for i in range(1, 121):
			var time := 0.3 * float(i) / 120.0
			var r: Dictionary = regular.sample(time)
			var s: Dictionary = reduced.sample(time)
			check(r.position == s.position and r.phase == s.phase and s.rotation_offset == Quaternion.IDENTITY, "custom Reduced Motion has the same physical timeline")
			check(r.position.distance_to(previous) > 0.0, "custom timing advances every sample")
			previous = r.position
		regular.clear()
		reduced.clear()
	for reduced_mode in [false, true]:
		var flat := Curve.new()
		flat.add_point(Vector2(0,0), 0, 0, Curve.TANGENT_LINEAR, Curve.TANGENT_LINEAR)
		flat.add_point(Vector2(0.4,0), 0, 0, Curve.TANGENT_LINEAR, Curve.TANGENT_LINEAR)
		flat.add_point(Vector2(1,1), 0, 0, Curve.TANGENT_LINEAR, Curve.TANGENT_LINEAR)
		var motion = Fall.new()
		motion.parameters.fall_curve = flat
		motion.parameters.reduced_motion = reduced_mode
		check(not motion.begin(Fixture.curve_event()).ok and not motion.sample(0.1).active, "flat authored v2 timing rejected atomically in both motion modes")
	var invalid := Fixture.curve_event()
	invalid.authorized_trajectory.departure_points2[1] = invalid.authorized_trajectory.departure_points2[0]
	var invalid_motion = Fall.new()
	check(not invalid_motion.begin(invalid).ok and not invalid_motion.sample(0.1).active, "zero-length declaration cannot produce edge timing division")
	var Orientation = load("res://foundation/orientation/discrete_orientation.gd")
	for orientation in 24:
		var event := Fixture.curve_event(false, orientation)
		var columns: Array = Orientation.columns(orientation)
		var base := Basis(Vector3(columns[0]),Vector3(columns[1]),Vector3(columns[2]))
		var local_normal := base.inverse() * Vector3.UP
		var motion = Fall.new()
		check(motion.begin(event).ok, "signed actual basis fixture begins for cube24")
		var visual_basis := Basis(motion.sample(0.015 * 0.8 / 0.3).rotation_offset) * base
		check((visual_basis * local_normal).dot(Vector3.LEFT) > 0.0, "actual composed Basis leans forward for every runtime orientation")
		check(Basis(motion.sample(0.8).rotation_offset) * base == base and event.target_pose.orientation == orientation, "standing basis exactly matches preserved runtime orientation")
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
