extends "res://tests/beta_sprint/game_feel_owner_10a/unit.gd"
## Owner-local event.v2 consumption; SAFE/native events are explicit doubles.
func run() -> void:
	var Fall = load("res://game/feel/animation/fall_landing/fall_motion.gd")
	var Landing = load("res://game/feel/animation/fall_landing/landing_motion.gd")
	var motion = Fall.new()
	var landing = Landing.new()
	for higher in [false, true]:
		var event := Fixture.curve_event(higher)
		var started: Dictionary = motion.begin(event)
		check(started.ok, "event.v2 curve begin, height sign=" + str(higher))
		if not started.ok: continue
		var join: float = started.phase_schedule.FALL_MOVING
		check(motion.sample(0.0).position == Vector3(0,3,0), "v2 exact source")
		check(motion.sample(join).position == Vector3(-1,3,0), "v2 departure ends at authorized geometry join")
		var step := 0.00008
		var center: Vector3 = motion.sample(join).position
		var before_velocity: Vector3 = (center - motion.sample(join - step).position) / step
		var after_velocity: Vector3 = (motion.sample(join + step).position - center) / step
		check(before_velocity.length() > 0.1 and before_velocity.distance_to(after_velocity) < before_velocity.length() * 0.04, "v2 spatial and temporal C1 join")
		var end: Dictionary = motion.sample(0.8)
		check(end.motion_done and end.position == Vector3(-3,5 if higher else 1,4), "v2 exact author target, no extra half conversion")
		check(not landing.begin(event).ok, "v2 STARTED cannot trigger impact")
		check(landing.begin(Fixture.committed(event)).ok, "v2 matching COMMITTED accepted without rewrite")
		check(landing.sample(1.0).rotation_offset == Quaternion.IDENTITY and landing.sample(1.0).scale_multiplier == Vector3.ONE, "v2 neutral settled orientation")
		landing.clear()
		motion.clear()
	finish()
