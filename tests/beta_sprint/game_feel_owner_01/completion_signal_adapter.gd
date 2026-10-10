extends Node3D
## UNIT_COMPLETION_SIGNAL_ADAPTER: no visual motion; never Graphical evidence.
signal motion_completed(identity: Dictionary, evidence: Dictionary)
signal motion_cancelled(identity: Dictionary, reason: String)
var fault := ""
var runtime: RefCounted
var starts: Array = []
var prior: Dictionary = {}
func bind_runtime(facade: RefCounted, _level: Dictionary) -> Dictionary:
	runtime = facade
	if fault == "bind": return {"ok":false,"issues":["controlled Unit bind refusal"]}
	runtime.transition_started.connect(started)
	return {"ok":true,"issues":[]}
func snapshot() -> Dictionary:
	return {"fixture_kind":"UNIT_COMPLETION_SIGNAL_ADAPTER","natural_motion":false,"starts":starts.duplicate(true)}
func started(_result: Dictionary, token: int, generation: int, is_global: bool) -> void:
	var identity: Dictionary = runtime.get_pending_identity(token,generation,is_global)
	starts.append(identity.duplicate(true))
	call_deferred("complete",identity)
func complete(identity: Dictionary) -> void:
	if fault == "never": return
	if fault == "reset": runtime.reset(); motion_cancelled.emit(identity,"RESET"); return
	if fault == "unload": runtime.interrupt("UNLOAD"); motion_cancelled.emit(identity,"UNLOAD"); return
	if fault == "cancel": runtime.interrupt("CANCEL"); motion_cancelled.emit(identity,"CANCEL"); return
	var evidence := {"fixture_kind":"UNIT_COMPLETION_SIGNAL_ADAPTER","natural_motion":false}
	if fault == "early": motion_completed.emit(identity,evidence); return
	var wrong := identity.duplicate(true)
	wrong.session_id = "foreign"
	motion_completed.emit(wrong,evidence)
	wrong = identity.duplicate(true)
	wrong.generation -= 1
	motion_completed.emit(wrong,evidence)
	if not prior.is_empty(): motion_completed.emit(prior,evidence)
	runtime.finish_transition(identity)
	if fault == "commit_only": return
	if fault == "foreign_only":
		wrong = identity.duplicate(true); wrong.session_id = "foreign"
		motion_completed.emit(wrong,evidence); return
	if fault == "generation_only":
		wrong = identity.duplicate(true); wrong.generation -= 1
		motion_completed.emit(wrong,evidence); return
	motion_completed.emit(identity,evidence)
	if fault == "duplicate": motion_completed.emit(identity,evidence)
	prior = identity.duplicate(true)
func _exit_tree() -> void:
	if runtime != null and runtime.transition_started.is_connected(started): runtime.transition_started.disconnect(started)
