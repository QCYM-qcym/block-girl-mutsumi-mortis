extends "res://tests/beta_sprint/game_feel_owner_10a/unit.gd"
## Owner-local event.v2 consumption; SAFE/native events are explicit doubles.
func _initialize() -> void:
	super._initialize()
	call_deferred("_arm_watchdog")

func _arm_watchdog() -> void:
	await create_timer(3.0).timeout
	check(false, "curve harness watchdog: script error prevented completion")
	finish()

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
		var previous: Vector3 = motion.sample(0.0).position
		var down := Vector3(-2,-3,2) # Registered fixed EAST projection numerator.
		var maximum_y := previous.y
		for i in range(1, 1001):
			var time := float(i) * 0.0008
			var sampled: Dictionary = motion.sample(time)
			check(sampled == motion.sample(time), "v2 deterministic sample/pause")
			check(sampled.position.dot(down) + 0.00001 >= previous.dot(down), "v2 entire profile screen descends")
			check(sampled.position.distance_to(previous) < 0.05, "v2 continuous author geometry, no teleport")
			if sampled.phase == "FALL_MOVING": check(sampled.position.distance_to(previous) > 0.000001, "v2 no cubic interior pause")
			maximum_y = maxf(maximum_y, sampled.position.y)
			previous = sampled.position
		check(maximum_y > 5.0 if higher else maximum_y == 3.0, "v2 true higher/lower geometry retained")
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
	# Every sampled phase cancels synchronously without manufacturing settlement.
	for time in [0.04, 0.17, 0.5, 0.8]:
		var event := Fixture.curve_event()
		check(motion.begin(event).ok, "v2 phase cancel begins")
		motion.sample(time)
		motion.cancel(event.presentation_identity)
		check(not motion.sample(1.0).active and motion.sample(1.0).scale_multiplier == Vector3.ONE, "v2 phase cancel neutral")
	for time in [0.03, 0.15, 0.34]:
		var event := Fixture.committed(Fixture.curve_event())
		check(landing.begin(event).ok, "v2 landing phase cancel begins")
		landing.sample(time)
		landing.cancel(event.presentation_identity)
		check(not landing.sample(1.0).active and not landing.sample(1.0).motion_done, "v2 landing cancel is not settled completion")
	# Unsupported versions and mixed representations fail closed, never fall back.
	for mutation in ["version", "schema", "missing", "mixed", "kind", "scalar", "hash", "count", "type", "extra", "version_type", "kind_type", "contract_type", "schema_type"]:
		var invalid := Fixture.curve_event()
		match mutation:
			"version": invalid.authorized_trajectory.trajectory_version = "pfall.unknown.v9"
			"schema": invalid.schema_version = 3
			"missing": invalid.erase("authorized_trajectory")
			"mixed": invalid.authorized_path_points2 = Fixture.event().authorized_path_points2
			"kind": invalid.safety_verdict.evidence_ref.kind = "exact_linear_cube_sweep.v1"
			"scalar": invalid.safety_verdict = "SAFE"
			"hash": invalid.safety_verdict.evidence_ref.profile_hash = "OTHER"
			"count": invalid.authorized_trajectory.descent_control_points2.pop_back()
			"type": invalid.authorized_trajectory.departure_points2[0] = Vector3.ZERO
			"extra": invalid.authorized_trajectory.extra = true
			"version_type": invalid.authorized_trajectory.trajectory_version = {}
			"kind_type": invalid.safety_verdict.evidence_ref.kind = {}
			"contract_type": invalid.contract_version = {}
			"schema_type": invalid.schema_version = {}
		check(not motion.begin(invalid).ok and not motion.sample(0.5).active, "v2 atomic rejection: " + mutation)
		motion.clear()
	var mixed_legacy := Fixture.event()
	mixed_legacy.authorized_trajectory = Fixture.curve_event().authorized_trajectory
	check(not motion.begin(mixed_legacy).ok, "v1 never reinterprets curve controls")
	motion.clear()
	for reduced in [false, true]:
		motion.parameters.reduced_motion = reduced
		var frozen_event := Fixture.curve_event(true)
		var original := frozen_event.duplicate(true)
		var begun: Dictionary = motion.begin(frozen_event)
		check(begun.ok, "v2 Reduced Motion begins")
		var fixed: Dictionary = motion.sample(0.4)
		check(motion.sample(0.4) == fixed and frozen_event == original, "v2 pause and World/DTO immutability")
		frozen_event.authorized_trajectory.descent_control_points2[-1] = Vector3i(999,999,999)
		check(motion.sample(0.8).position == Vector3(-3,5,4), "v2 private trajectory snapshot")
		if reduced: check(fixed.rotation_offset == Quaternion.IDENTITY, "v2 Reduced Motion neutral rotation")
		motion.cancel(original.presentation_identity)
		check(not motion.sample(0.8).active and not motion.sample(0.8).motion_done, "v2 cancellation is not completion")
		var next := Fixture.curve_event(true, 0, 2)
		check(motion.begin(next).ok, "v2 begins after scoped cancel")
		motion.cancel(original.presentation_identity)
		check(motion.sample(0.4).identity == next.presentation_identity, "v2 stale cancel cannot clear new identity")
		motion.clear()
	for orientation in 24:
		var event := Fixture.curve_event(false, orientation, orientation + 10)
		check(motion.begin(event).ok, "v2 cube24 accepted")
		check(motion.sample(1.0).rotation_offset == Quaternion.IDENTITY and motion.sample(1.0).scale_multiplier == Vector3.ONE, "v2 cube24 exact Fall offsets")
		motion.clear()
		check(landing.begin(Fixture.committed(event)).ok, "v2 cube24 committed")
		check(landing.sample(1.0).rotation_offset == Quaternion.IDENTITY and landing.sample(1.0).scale_multiplier == Vector3.ONE, "v2 cube24 exact Landing offsets")
		landing.clear()
	finish()
