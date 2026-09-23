extends RefCounted
## Process-local boundary guard, never passed into native algorithm options.
## read_status is the owning IPC adapter's validated local observation:
## {identity, cancelled, lease_deadline_msec, stage_deadline_msec}.
## Deadlines use this process's monotonic clock. No timestamp crosses processes.
const Schemas = preload("res://tools/foundation/authoring_acceptance/wire_schemas.gd")
var _identity: Dictionary
var _read_status: Callable
var _reason := ""

func _init(identity: Dictionary = {}, read_status: Callable = Callable()) -> void:
	_identity = identity.duplicate(true)
	_read_status = read_status

func stop_requested() -> bool:
	if not _reason.is_empty(): return true
	if _identity.is_empty() or not _read_status.is_valid():
		_reason = "CONTROL_INVALID"
		return true
	var status: Variant = _read_status.call()
	if not Schemas._fields(status, ["identity","cancelled","lease_deadline_msec","stage_deadline_msec"]):
		_reason = "CONTROL_INVALID"
	elif typeof(status.identity) != TYPE_DICTIONARY or status.identity != _identity:
		_reason = "IDENTITY_MISMATCH"
	elif typeof(status.cancelled) != TYPE_BOOL or typeof(status.lease_deadline_msec) != TYPE_INT or typeof(status.stage_deadline_msec) != TYPE_INT:
		_reason = "CONTROL_INVALID"
	elif status.cancelled:
		_reason = "CANCELLED"
	elif Time.get_ticks_msec() >= status.lease_deadline_msec:
		_reason = "LEASE_EXPIRED"
	elif Time.get_ticks_msec() >= status.stage_deadline_msec:
		_reason = "TIMEOUT"
	return not _reason.is_empty()

func reason() -> String:
	stop_requested()
	return _reason

func checkpoint(stage_id: String) -> bool:
	if not stop_requested() and stage_id not in Schemas.STAGES:
		_reason = "INVALID_STAGE"
	return _reason.is_empty()
