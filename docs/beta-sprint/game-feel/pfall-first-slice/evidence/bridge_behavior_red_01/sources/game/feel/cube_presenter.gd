extends RefCounted
## 00 owns the single visual writer; implementation follows lifecycle RED.
func bind(_actor: Node3D, _fall: RefCounted, _landing: RefCounted, _projection: Callable, _finish: Callable) -> void:
	pass
func sync_pose(_pose: Dictionary) -> void:
	pass
func consume_event(_event: Dictionary) -> Dictionary:
	return {"ok":false,"issues":["native completion bridge not implemented"]}
func tick(_delta: float) -> void:
	pass
func set_paused(_paused: bool) -> void:
	pass
func clear() -> void:
	pass
func snapshot() -> Dictionary:
	return {"presentation_identity":null}
