extends Node
## Presentation-only consumer. Native commits, never elapsed time, authorize cues.
const Director = preload("res://game/feel/audio/audio_director.gd")
var director: Node
var _runtime
var _scope: Dictionary = {}
var _last_event := -1
var _neutral: Dictionary = {}
var _shift: Dictionary = {}
var _motions: Dictionary = {}
var _identities: Dictionary = {}

func bind_runtime(facade) -> void:
	if _runtime == facade: return
	close()
	# A closed Director permanently retires its old run. A new binding gets a
	# new consumer lifetime; hosts reapply settings after binding, as on entry.
	if director != null: director.free()
	director = Director.new()
	add_child(director)
	_runtime = facade
	if _runtime == null: return
	_runtime.game_feel_event.connect(_on_event)
	_runtime.transition_started.connect(_on_native_started)
	_runtime.committed.connect(_on_committed)
	_sync_scope()
	_update_music()

func snapshot() -> Dictionary:
	return director.snapshot() if director != null else {}

func set_paused(value: bool) -> void:
	if director != null: director.set_paused(value)

func close() -> void:
	if _runtime != null:
		_runtime.game_feel_event.disconnect(_on_event)
		_runtime.transition_started.disconnect(_on_native_started)
		_runtime.committed.disconnect(_on_committed)
	_runtime = null
	_scope = {}
	_last_event = -1
	_neutral = {}; _shift = {}; _motions.clear(); _identities.clear()
	if director != null: director.clear()

func _exit_tree() -> void: close()
func _process(_delta: float) -> void:
	if _runtime != null: _sync_scope()

func _sync_scope() -> void:
	if _runtime == null: return
	var current: Dictionary = _runtime.get_presentation_scope() if _runtime.is_loaded() else {}
	if current == _scope: return
	for identity in _identities.values(): director.cancel(identity)
	var new_run: bool = current.get("session_id") != _scope.get("session_id") or current.get("level_run_id") != _scope.get("level_run_id")
	if new_run or current.is_empty():
		director.clear()
		_last_event = -1
	_scope = current.duplicate(true)
	_neutral = {}; _shift = {}; _motions.clear(); _identities.clear()
	_update_music()

func _update_music() -> void:
	if _runtime != null and _runtime.is_loaded():
		director.set_music("exploration", _runtime.get_state().player.location.layer)

func _current(identity: Dictionary) -> bool:
	if _runtime == null or not _runtime.is_loaded(): return false
	var current: Dictionary = _runtime.get_presentation_scope()
	for field in ["session_id", "level_run_id", "generation"]:
		if identity.get(field) != current.get(field): return false
	return true

func _key(identity: Dictionary) -> String:
	return JSON.stringify([identity.get("session_id"), identity.get("level_run_id"), identity.get("generation"), identity.get("attempt_id")])

func _on_event(event: Dictionary) -> void:
	if _runtime == null: return
	_sync_scope()
	if event.get("session_id") != _scope.get("session_id") or event.get("level_run_id") != _scope.get("level_run_id"): return
	if event.get("event_id", -1) <= _last_event: return
	_last_event = event.event_id
	var identity: Dictionary = event.presentation_identity if event.get("presentation_identity") is Dictionary else {}
	if not identity.is_empty() and not _current(identity): return
	if event.get("semantic") == "ACTION_FEEDBACK":
		_neutral = {"event": event.duplicate(true), "scope": _scope.duplicate(true)}
		return
	if identity.is_empty(): return
	var key := _key(identity)
	_identities[key] = identity.duplicate(true)
	var started: Dictionary = _motions.get(key, {})
	if event.phase == "STARTED": _motions[key] = event.duplicate(true)
	if event.phase in ["COMMITTED", "INTERRUPTED"]: _motions.erase(key)
	director.consume_event(event)
	# Audio observers may synchronously Reset; recheck the authoritative scope.
	if not _current(identity) or event.phase != "COMMITTED" or started.is_empty(): return
	if started.transition_identity != event.transition_identity or started.result != event.result: return
	if _runtime.get_state() != event.result.next_state: return
	var previous: Dictionary = event.result.previous_state.get("mechanism_states", {})
	var next: Dictionary = event.result.next_state.get("mechanism_states", {})
	for lock in _runtime.get_level().get("face_locks", []):
		if previous.get(lock.mechanism_id) != lock.latched_state and next.get(lock.mechanism_id) == lock.latched_state:
			director.play_ui("perspective_connect", identity)
			break

func _on_native_started(result: Dictionary, token: int, generation: int, is_global: bool) -> void:
	if _runtime == null: return
	_sync_scope()
	var captured := _neutral
	_neutral = {}
	if captured.is_empty() or captured.scope != _scope or result.get("action", {}).get("kind") != 1: return
	if captured.event.result != result or result.get("status") != 0 or not result.get("changed", false): return
	var native: Dictionary = _runtime.get_pending_identity(token, generation, is_global)
	if native.is_empty() or not _current(native): return
	# Reuse the actual attempt ID and generation captured from the native start.
	var audio_identity := {"session_id": native.session_id, "level_run_id": native.level_run_id, "generation": native.generation, "attempt_id": captured.event.attempt_id}
	_identities[_key(audio_identity)] = audio_identity
	_shift = {"native": native, "audio": audio_identity, "next_state": result.next_state.duplicate(true), "commits": _runtime.get_commit_count()}

func _on_committed(state: Dictionary) -> void:
	if _runtime == null: return
	_sync_scope()
	var pending := _shift
	_shift = {}
	if pending.is_empty() or not _current(pending.native): return
	if _runtime.get_state() != state or state != pending.next_state or _runtime.get_commit_count() != pending.commits + 1: return
	director.play_ui("world_shift", pending.audio)
	if _current(pending.native): _update_music()
