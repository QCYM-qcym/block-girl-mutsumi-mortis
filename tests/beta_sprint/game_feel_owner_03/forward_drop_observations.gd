extends RefCounted
## Tests-only measurement of observed positions, never a motion/path implementation.
const Profile = preload("res://foundation/game_feel/trajectory_profile.gd")
const View = preload("res://foundation/game_feel/view_contract.gd")

static func observed_parameter(trajectory: Dictionary, position: Vector3, quadrant: int) -> Dictionary:
	# Invert the strictly descending projection of the actual approved A/B
	# profiles by querying Owner01. No test-side cubic/path evaluator.
	var down := -View.basis(quadrant).y
	var projected := position.dot(down)
	var low := 0.0
	var high := 1.0
	for iteration in 32:
		var middle := (low + high) * 0.5
		var actual: Dictionary = Profile.sample_actor_center(trajectory, middle)
		if not actual.ok: return {"ok": false, "parameter": null}
		if actual.position.dot(down) < projected: low = middle
		else: high = middle
	var parameter := (low + high) * 0.5
	var resolved: Dictionary = Profile.sample_actor_center(trajectory, parameter)
	return {"ok": resolved.ok and resolved.position.distance_to(position) < 0.0001, "parameter": parameter}

static func cadence(trajectory: Dictionary, positions: Array, quadrant: int) -> Dictionary:
	# Four real observations at 15/35/65/85% of the descent's time span.
	# Use the actual elapsed interval when renderer frame times differ.
	var parameters: Array = []
	for observation in positions:
		var result := observed_parameter(trajectory, observation.position, quadrant)
		if not result.ok: return {"ok": false}
		parameters.append(result.parameter)
	var early_dt: float = positions[1].elapsed - positions[0].elapsed
	var late_dt: float = positions[3].elapsed - positions[2].elapsed
	if early_dt <= 0.0 or late_dt <= 0.0: return {"ok": false}
	var early_rate: float = (parameters[1] - parameters[0]) / early_dt
	var late_rate: float = (parameters[3] - parameters[2]) / late_dt
	return {"ok": true, "parameters": parameters, "actual_observation_times": positions.map(func(p): return p.elapsed),
		"early_parameter_rate": early_rate, "late_parameter_rate": late_rate,
		"accelerates": early_rate > 0.0 and late_rate > early_rate * 1.2}

static func measure(samples: Array, source: Vector3, forward: Vector3, normal: Vector3, down: Vector3) -> Dictionary:
	var out := {"first_timed_forward": false, "source_edge_before_descent": true,
		"forward_only": true, "moving_intervals": 0, "stationary_intervals": 0,
		"first_descent_time": -1.0, "early_speed": 0.0, "late_speed": 0.0,
		"early_intervals": 0, "late_intervals": 0, "screen_descending": true}
	if samples.size() < 3: return out
	var first_timed := false
	for sample in samples:
		var displacement: Vector3 = sample.position - source
		var advance := displacement.dot(forward)
		if not first_timed and sample.elapsed > 0.000001:
			out.first_timed_forward = advance > 0.000001
			first_timed = true
		if advance < -0.000001: out.forward_only = false
		if absf(displacement.dot(normal)) > 0.000001:
			# Unit cube support is half a logical unit from its center. This
			# boundary comes from formal cube geometry, not a colored Mesh.
			if advance <= 0.5: out.source_edge_before_descent = false
			if out.first_descent_time < 0.0: out.first_descent_time = sample.elapsed
	var end: float = samples[-1].elapsed
	var early_distance := 0.0
	var early_time := 0.0
	var late_distance := 0.0
	var late_time := 0.0
	for index in range(1, samples.size()):
		var a: Dictionary = samples[index - 1]
		var b: Dictionary = samples[index]
		var dt: float = b.elapsed - a.elapsed
		if dt <= 0.000001: continue # Repeated same-clock renderer observation.
		var delta: Vector3 = b.position - a.position
		if delta.length() <= 0.000001: out.stationary_intervals += 1
		else: out.moving_intervals += 1
		var descent := delta.dot(down)
		if descent < -0.000001: out.screen_descending = false
		if out.first_descent_time < 0.0 or end <= out.first_descent_time: continue
		var fraction: float = ((a.elapsed + b.elapsed) * 0.5 - out.first_descent_time) / (end - out.first_descent_time)
		if fraction >= 0.0 and fraction <= 0.25:
			early_distance += descent
			early_time += dt
			out.early_intervals += 1
		elif fraction >= 0.75 and fraction <= 1.0:
			late_distance += descent
			late_time += dt
			out.late_intervals += 1
	if early_time > 0.0: out.early_speed = early_distance / early_time
	if late_time > 0.0: out.late_speed = late_distance / late_time
	return out
