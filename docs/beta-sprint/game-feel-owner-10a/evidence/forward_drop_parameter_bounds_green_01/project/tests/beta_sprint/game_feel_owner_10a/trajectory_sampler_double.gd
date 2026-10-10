extends RefCounted
## TEST DOUBLE ONLY. Installed at the dependency path in an isolated evidence
## project while Owner01 implementation is pending. Never shipped as Foundation.
static func sample_actor_center(trajectory: Dictionary, parameter: float) -> Dictionary:
	var invalid := {"ok": false, "position": null, "issues": [{"path": "trajectory", "message": "Invalid test-double input."}]}
	if not is_finite(parameter) or parameter < 0.0 or parameter > 1.0: return invalid
	if trajectory.size() != 3 or trajectory.get("trajectory_version") != "pfall.departure_cubic.v1": return invalid
	for key in ["departure_points2", "descent_control_points2"]:
		var points: Variant = trajectory.get(key)
		if not points is Array or points.size() != (2 if key == "departure_points2" else 4): return invalid
		for point in points:
			if not point is Vector3i: return invalid
			if absi(point.x) > 1000000 or absi(point.y) > 1000000 or absi(point.z) > 1000000: return invalid
	var departure: Array = trajectory.departure_points2
	var controls: Array = trajectory.descent_control_points2
	if controls[0] != departure[1] or controls[1] - controls[0] != departure[1] - departure[0]: return invalid
	var position: Vector3
	if parameter == 0.0: position = Vector3(departure[0]) * 0.5
	elif parameter == 0.25: position = Vector3(departure[1]) * 0.5
	elif parameter == 1.0: position = Vector3(controls[3]) * 0.5
	elif parameter < 0.25: position = Vector3(departure[0]).lerp(Vector3(departure[1]), parameter * 4.0) * 0.5
	else:
		var t := (4.0 * parameter - 1.0) / 3.0
		var s := 1.0 - t
		position = (Vector3(controls[0]) * s*s*s + Vector3(controls[1]) * 3.0*s*s*t + Vector3(controls[2]) * 3.0*s*t*t + Vector3(controls[3]) * t*t*t) * 0.5
	return {"ok": true, "position": position, "issues": []}
