extends Node
## Local audio consumer; all gameplay authority and persistence stay with the host.
signal cue_played(cue: String, identity: Variant)
signal diagnostic(issue: String)
const Policy = preload("res://game/feel/audio/event_policy.gd")
const MUSIC_CUES := ["menu", "surface", "inner", "discovery", "complete"]
const SFX_CUES := ["cube_roll", "cube_contact", "edge_lean", "edge_recoil", "fall_start", "fall_whoosh", "landing_impact", "perspective_connect", "perspective_disconnect", "world_shift", "goal", "ui_select", "ui_back"]
const BASE_DB := {"Master": 0.0, "Ambience": -12.0, "SFX": -6.0}
const SETTING_BUSES := {"master": "Master", "music": "Ambience", "sfx": "SFX"}
var manifest_path := "res://production/experimental/game_feel_01/audio/manifest.json"
var _policy = Policy.new()
var _players: Dictionary = {}
var _trims: Dictionary = {}
var _tags: Dictionary = {}
var _issues: Array[String] = []
var _counts: Dictionary = {}
var _ui_seen: Dictionary = {}
var _clock := 0.0
var _paused := false
var _context := "none"
var _world := 0
var _blend := 0.0
var _menu_gain := 0.0
var _exploration_gain := 0.0
var _epoch := 0
var _queued: Array[Dictionary] = []
var _settings := {"master": 1.0, "music": 1.0, "sfx": 1.0, "muted": false}

func _ready() -> void:
	if not FileAccess.file_exists(manifest_path):
		_note("missing audio manifest: " + manifest_path)
		return
	var manifest = JSON.parse_string(FileAccess.get_file_as_string(manifest_path))
	if not manifest is Dictionary or manifest.get("schema_version") != 1:
		_note("unsupported audio manifest")
		return
	for category in ["music", "sfx"]:
		var entries = manifest.get(category, {})
		if not entries is Dictionary:
			_note("invalid manifest category: " + category)
			continue
		for cue in MUSIC_CUES if category == "music" else SFX_CUES:
			var key: String = category + ":" + cue
			var player := AudioStreamPlayer.new()
			player.name = category + "_" + cue
			player.max_polyphony = 1
			player.bus = "Ambience" if category == "music" else "SFX"
			add_child(player)
			_players[key] = player
			_trims[key] = 0.0
			var entry = entries.get(cue)
			if not entry is Dictionary:
				_note("missing manifest entry: " + key)
				continue
			var path = entry.get("path", "")
			if not path is String or not FileAccess.file_exists(path):
				_note("missing audio resource: " + str(path))
				continue
			# Raw PCM loader keeps this local service independent of import registry edits.
			var stream := AudioStreamWAV.load_from_file(path)
			if stream == null:
				_note("unreadable WAV: " + path)
				continue
			if entry.get("loop", false):
				stream.loop_mode = AudioStreamWAV.LOOP_FORWARD
				stream.loop_begin = int(entry.get("loop_start_frame", 0))
				stream.loop_end = int(entry.get("loop_end_frame", entry.get("frame_count", 0)))
			player.stream = stream
			_trims[key] = float(entry.get("gain_db", -6.0))
			player.volume_db = _trims[key]
	_update_music()

func _process(delta: float) -> void:
	if _paused: return
	_clock += delta
	_blend = move_toward(_blend, float(_world), delta / 0.65)
	_menu_gain = move_toward(_menu_gain, 1.0 if _context == "menu" else 0.0, delta / 0.6)
	_exploration_gain = move_toward(_exploration_gain, 1.0 if _context == "exploration" else 0.0, delta / 0.6)
	_update_music()
	if _context != "menu" and is_zero_approx(_menu_gain): _stop("music:menu")
	if _context != "exploration" and is_zero_approx(_exploration_gain):
		_stop("music:surface")
		_stop("music:inner")

func consume_event(event: Dictionary) -> void:
	if _paused and not event.get("phase") in ["COMMITTED", "INTERRUPTED"]: return
	var action: Dictionary = _policy.consume(event, _clock)
	for issue in action.issues: _note(issue)
	if action.stop_identity is Dictionary and _has_live_identity(action.stop_identity): _epoch += 1
	if action.stop_identity is Dictionary: _stop_identity(action.stop_identity)
	if not action.accepted: return
	if event.get("phase") == "INTERRUPTED":
		_drop_queued(event.presentation_identity)
		return
	if _paused:
		if not action.cues.is_empty(): _queued.append({"action": action, "event": event.duplicate(true)})
		return
	_deliver(action, event)

func _deliver(action: Dictionary, event: Dictionary) -> void:
	if action.cues.is_empty(): return
	_epoch += 1
	if action.world_id is int: set_music("exploration", action.world_id)
	var epoch := _epoch
	for cue in action.cues:
		# A synchronous observer may clear/cancel/start something new during emit.
		if epoch != _epoch: break
		_play("sfx:" + cue, event.presentation_identity)

func play_ui(cue: String, cue_identity: Variant) -> void:
	if _paused: return
	if not ((cue_identity is String and not cue_identity.is_empty()) or (cue_identity is Dictionary and not cue_identity.is_empty())):
		_note("UI cue requires a stable identity")
		return
	if cue_identity is Dictionary and not _policy.allows_external_identity(cue_identity): return
	var alias: String = {"select": "ui_select", "back": "ui_back", "complete": "goal"}.get(cue, cue)
	if not alias in SFX_CUES and alias != "discovery":
		_note("unknown UI/presentation cue: " + cue)
		return
	var key := _ui_key(alias, cue_identity)
	if _ui_seen.has(key): return
	_ui_seen[key] = true
	if _ui_seen.size() > 4096: _ui_seen.erase(_ui_seen.keys()[0])
	_epoch += 1
	var epoch := _epoch
	if alias == "goal":
		set_music("none")
		_play("sfx:goal", cue_identity)
		if epoch == _epoch: _play("music:complete", cue_identity)
	elif alias == "discovery":
		_play("music:discovery", cue_identity)
	else:
		_play("sfx:" + alias, cue_identity)

func apply_settings(values: Dictionary) -> void:
	# Same keys and base gains as game/shell/settings.gd; no Save/Window writes.
	for key in SETTING_BUSES:
		if not values.has(key): continue
		var value = values[key]
		if not (value is int or value is float) or not is_finite(float(value)):
			_note("invalid volume: " + key)
			continue
		_settings[key] = clampf(float(value), 0.0, 1.0)
	if values.get("muted") is bool: _settings.muted = values.muted
	for key in SETTING_BUSES:
		var bus: String = SETTING_BUSES[key]
		var index := AudioServer.get_bus_index(bus)
		if index < 0:
			_note("missing existing audio bus: " + bus)
			continue
		var amount: float = _settings[key]
		AudioServer.set_bus_volume_db(index, linear_to_db(maxf(amount, 0.0001)) + BASE_DB[bus])
		AudioServer.set_bus_mute(index, amount <= 0 or (key == "master" and _settings.muted))

func set_paused(value: bool) -> void:
	if value == _paused: return
	_paused = value
	for player: AudioStreamPlayer in _players.values(): player.stream_paused = value
	if not value:
		var pending := _queued.duplicate(true)
		_queued.clear()
		for item in pending:
			if _policy.allows_external_identity(item.event.presentation_identity): _deliver(item.action, item.event)

func cancel(identity: Dictionary) -> void:
	if _policy.is_active(identity) or _has_live_identity(identity): _epoch += 1
	_policy.cancel(identity)
	_stop_identity(identity)
	_drop_queued(identity)

func clear() -> void:
	_epoch += 1
	_policy.clear()
	for key in _players: _stop(key)
	_tags.clear()
	_queued.clear()
	_context = "none"
	_menu_gain = 0.0
	_exploration_gain = 0.0
	_update_music()

func _exit_tree() -> void:
	clear()

func set_music(context: String, world_id: int = 0) -> void:
	if not context in ["none", "menu", "exploration"] or not world_id in [0, 1]:
		_note("invalid music context/world")
		return
	if _context == context:
		_world = world_id
		return
	_context = context
	_world = world_id
	if context == "menu":
		_start_loop("music:menu")
	elif context == "exploration":
		_blend = float(world_id)
		# One main-thread batch reaches the same audio mix tick; neither restarts on Shift.
		_start_loop("music:surface")
		_start_loop("music:inner")
	_update_music()

func _start_loop(key: String) -> void:
	var player: AudioStreamPlayer = _players.get(key)
	if player != null and player.stream != null and not player.playing:
		player.volume_db = -80.0
		player.play()
		player.stream_paused = _paused

func _update_music() -> void:
	_gain("music:menu", sin(_menu_gain * PI * 0.5))
	var common := sin(_exploration_gain * PI * 0.5)
	_gain("music:surface", cos(_blend * PI * 0.5) * common)
	_gain("music:inner", sin(_blend * PI * 0.5) * common)

func _gain(key: String, amount: float) -> void:
	var player: AudioStreamPlayer = _players.get(key)
	if player != null: player.volume_db = linear_to_db(maxf(0.0001, amount)) + _trims[key]

func _play(key: String, identity: Variant) -> void:
	var player: AudioStreamPlayer = _players.get(key)
	if player == null or player.stream == null:
		_note("unavailable cue: " + key)
		return
	_tags[key] = identity.duplicate(true) if identity is Dictionary else identity
	player.play()
	player.stream_paused = _paused
	var cue := key if key.begins_with("music:") else key.trim_prefix("sfx:")
	_counts[cue] = int(_counts.get(cue, 0)) + 1
	cue_played.emit(cue, identity.duplicate(true) if identity is Dictionary else identity)

func _stop(key: String) -> void:
	var player: AudioStreamPlayer = _players.get(key)
	if player != null: player.stop()
	_tags.erase(key)

func _stop_identity(identity: Dictionary) -> void:
	for key in _tags.keys():
		if _tags[key] is Dictionary and _tags[key] == identity: _stop(key)

func _has_live_identity(identity: Dictionary) -> bool:
	for key in _tags:
		if _tags[key] is Dictionary and _tags[key] == identity and _players[key].playing: return true
	return false

func _drop_queued(identity: Dictionary) -> void:
	for i in range(_queued.size() - 1, -1, -1):
		if _queued[i].event.presentation_identity == identity: _queued.remove_at(i)

func _ui_key(cue: String, id: Variant) -> String:
	var normalized: String = Policy.identity_key(id) if id is Dictionary and id.has("session_id") and id.has("level_run_id") and id.has("attempt_id") and id.has("generation") else JSON.stringify(id)
	return cue + ":" + normalized

func _note(issue: String) -> void:
	if _issues.has(issue): return
	if _issues.size() < 128: _issues.append(issue)
	diagnostic.emit(issue)

func snapshot() -> Dictionary:
	var playing: Array[String] = []
	var positions := {}
	for key in _players:
		var player: AudioStreamPlayer = _players[key]
		if player.playing: playing.append(key)
		if key.begins_with("music:"): positions[key.trim_prefix("music:")] = player.get_playback_position()
	var gains := {}
	for bus in BASE_DB:
		var index := AudioServer.get_bus_index(bus)
		if index >= 0: gains[bus] = AudioServer.get_bus_volume_db(index)
	return {"voice_count": _players.size(), "playing": playing, "paused": _paused, "context": _context, "world_blend": _blend, "target_world": _world, "positions": positions, "cue_counts": _counts.duplicate(true), "issues": _issues.duplicate(), "bus_gains": gains, "master_muted": AudioServer.is_bus_mute(0)}
