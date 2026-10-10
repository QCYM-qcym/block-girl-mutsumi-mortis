extends RefCounted
## UNIT ONLY: stops at a chosen public-call boundary. Never replaces algorithms.
var stop_stage: String
var occurrence: int
var stop_reason: String
var calls: Array[String] = []
var _seen := 0
var _stopped := false

func _init(stage_id: String, at_occurrence: int, reason_value: String = "CANCELLED") -> void:
	stop_stage = stage_id
	occurrence = at_occurrence
	stop_reason = reason_value

func stop_requested() -> bool:
	return _stopped

func reason() -> String:
	return stop_reason if _stopped else ""

func checkpoint(stage_id: String) -> bool:
	calls.append(stage_id)
	if stage_id == stop_stage:
		_seen += 1
		if _seen >= occurrence: _stopped = true
	return not _stopped
