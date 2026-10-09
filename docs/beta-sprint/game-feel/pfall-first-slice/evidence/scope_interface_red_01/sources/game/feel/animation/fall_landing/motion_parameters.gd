extends Resource
## Experimental feel values, NOT formally accepted art tuning.
@export_range(0.0, 2.0) var anticipation_duration := 0.12
@export_range(0.001, 2.0) var departure_duration := 0.12
@export_range(0.001, 5.0) var fall_duration := 0.56
@export_range(0.0, 0.15) var impact_compression := 0.055
@export_range(0.0, 0.08) var landing_rebound := 0.025
@export_range(0.05, 2.0) var settle_duration := 0.28
@export var fall_curve: Curve
@export_range(0.0, 20.0) var landing_damping := 6.0
@export_range(0.0, 10.0) var anticipation_angle_degrees := 5.0
@export_range(0.0, 5.0) var landing_angle_degrees := 1.8
@export_range(0.01, 0.2) var impact_duration := 0.06
@export_range(0.01, 0.5) var departure_path_fraction := 0.15
@export var reduced_motion := false

func issues() -> Array:
	var result: Array = []
	var ranges := {
		"anticipation_duration": Vector2(0, 2), "departure_duration": Vector2(0.001, 2),
		"fall_duration": Vector2(0.001, 5), "impact_compression": Vector2(0, 0.15),
		"landing_rebound": Vector2(0, 0.08), "settle_duration": Vector2(0.05, 2),
		"landing_damping": Vector2(0, 20), "anticipation_angle_degrees": Vector2(0, 10),
		"landing_angle_degrees": Vector2(0, 5), "impact_duration": Vector2(0.01, 0.2),
		"departure_path_fraction": Vector2(0.01, 0.5)}
	for key in ranges:
		var value: float = get(key)
		if not is_finite(value) or value < ranges[key].x or value > ranges[key].y:
			result.append({"path": "parameters." + key, "message": "Outside finite experimental range."})
	return result

func timing_table() -> Dictionary:
	# Custom curves are frozen into a monotone piecewise-linear timing table.
	# This makes the entire applied easing provably bounded, including intervals
	# between knots; the original cubic Curve is never used after begin().
	var values: PackedFloat64Array = []
	var previous := 0.0
	for i in 257:
		var t := float(i) / 256.0
		var value := t * t if fall_curve == null else fall_curve.sample(t)
		if not is_finite(value) or value < 0.0 or value > 1.0 or (i > 0 and value < previous):
			return {"ok": false, "issues": [{"path": "parameters.fall_curve", "message": "Curve must be finite, monotone and bounded by [0,1]."}]}
		values.append(value)
		previous = value
	if absf(values[0]) > 0.000001 or absf(values[-1] - 1.0) > 0.000001:
		return {"ok": false, "issues": [{"path": "parameters.fall_curve", "message": "Curve endpoints must be 0 and 1."}]}
	values[0] = 0.0
	values[-1] = 1.0
	return {"ok": true, "issues": [], "values": values}
