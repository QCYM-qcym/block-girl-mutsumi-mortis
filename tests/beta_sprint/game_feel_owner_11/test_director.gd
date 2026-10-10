extends SceneTree
const Director = preload("res://game/feel/audio/audio_director.gd")
const Fixtures = preload("res://tests/beta_sprint/game_feel_owner_11/test_policy.gd")
var checks := 0
var failures: Array[String] = []
var output := ""
var heard: Array[String] = []
var pcm := PackedVector2Array()
var capture: AudioEffectCapture
var capture_bus := -1
var initial_buses: Array[Dictionary] = []
var peak := 0.0
var energy := 0.0
var meter: Timer

func _initialize() -> void:
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--evidence-dir="): output = arg.trim_prefix("--evidence-dir=")
	call_deferred("run")

func check(value: bool, label: String) -> void:
	checks += 1
	if not value:
		failures.append(label)
		print("FAIL: ", label)

func count(cue: String) -> int:
	return heard.count(cue)

func wait(seconds: float) -> void:
	await create_timer(seconds).timeout

func measure() -> void:
	if capture == null: return
	var block := capture.get_buffer(capture.get_frames_available())
	for sample in block:
		peak = maxf(peak, maxf(absf(sample.x), absf(sample.y)))
		energy += sample.x * sample.x + sample.y * sample.y
	pcm.append_array(block)

func run() -> void:
	for i in AudioServer.bus_count:
		initial_buses.append({"volume": AudioServer.get_bus_volume_db(i), "mute": AudioServer.is_bus_mute(i)})
	capture_bus = AudioServer.get_bus_index("Master")
	capture = AudioEffectCapture.new()
	capture.buffer_length = 2.0
	AudioServer.add_bus_effect(capture_bus, capture)
	meter = Timer.new()
	meter.wait_time = 0.05
	meter.timeout.connect(measure)
	root.add_child(meter)
	meter.start()
	var d = Director.new()
	root.add_child(d)
	d.cue_played.connect(func(cue: String, _id: Variant): heard.append(cue))
	var f = Fixtures.new()
	d.apply_settings({"master": 1.0, "music": 1.0, "sfx": 1.0, "muted": false, "fullscreen": false})
	check(d.snapshot().voice_count == 18, "fixed 18 local voice players")
	d.set_music("exploration", 0)
	await wait(0.3)
	check(d.snapshot().playing.has("music:surface") and d.snapshot().playing.has("music:inner"), "both exploration layers actually playing")
	var positions: Dictionary = d.snapshot().positions
	check(absf(positions.get("surface", -100.0) - positions.get("inner", 100.0)) < 0.04, "paired layers synchronized")
	var before: float = positions.get("surface", -100.0)
	d.set_music("exploration", 1)
	await wait(0.15)
	check(d.snapshot().positions.get("surface", -100.0) > before, "world shift preserves running position")
	check(d.snapshot().world_blend > 0 and d.snapshot().world_blend < 1, "world shift actually blends")
	d.set_paused(true)
	var paused_position: float = d.snapshot().positions.get("surface", -100.0)
	var paused_blend: float = d.snapshot().world_blend
	await wait(0.25)
	check(absf(d.snapshot().positions.get("surface", -200.0) - paused_position) < 0.04, "pause suspends music playhead")
	check(is_equal_approx(d.snapshot().world_blend, paused_blend), "pause suspends blend clock")
	d.consume_event(f.event("PERSPECTIVE_FALL_APPLIED", "STARTED", 1))
	check(count("fall_start") == 0, "paused event delivery never sounds")
	d.set_paused(false)
	await wait(0.55)
	check(d.snapshot().world_blend > 0.99, "resume finishes same blend")
	d.consume_event(f.event("PERSPECTIVE_FALL_APPLIED", "STARTED", 1))
	check(count("fall_start") == 1 and count("landing_impact") == 0, "fall starts with no early impact")
	check(d.snapshot().playing.has("sfx:fall_whoosh"), "scoped whoosh loop actually playing")
	d.consume_event(f.event("ACTION_FEEDBACK", "FEEDBACK", 2))
	check(count("landing_impact") == 0, "feedback does not land")
	d.consume_event(f.event("PERSPECTIVE_FALL_APPLIED", "COMMITTED", 3))
	check(count("landing_impact") == 1, "matching real-port-shape commit triggers single impact")
	check(not d.snapshot().playing.has("sfx:fall_whoosh"), "commit stops whoosh synchronously")
	d.consume_event(f.event("PERSPECTIVE_FALL_APPLIED", "COMMITTED", 4))
	check(count("landing_impact") == 1, "alternate commit delivery deduplicated")
	d.consume_event(f.event("PERSPECTIVE_FALL_APPLIED", "STARTED", 5, 2))
	d.cancel(f.identity())
	check(d.snapshot().playing.has("sfx:fall_whoosh"), "old cancellation does not stop new loop")
	d.cancel(f.identity(2))
	check(not d.snapshot().playing.has("sfx:fall_whoosh"), "matching cancellation stops loop")
	d.consume_event(f.event("PERSPECTIVE_FALL_APPLIED", "COMMITTED", 6, 2))
	check(count("landing_impact") == 1, "cancel has no late landing")
	for i in range(3, 20):
		d.consume_event(f.event("MOVE_REJECTED_EDGE", "REJECTED", i + 4, i))
	check(count("edge_recoil") == 1, "held input burst plays one recoil")
	check(d.snapshot().voice_count == 18, "repeated actions never allocate extra players")
	d.play_ui("goal", {"session_id": "session-A", "level_run_id": "run-A", "generation": 0, "attempt_id": 20})
	d.play_ui("complete", {"session_id": "session-A", "level_run_id": "run-A", "generation": 0, "attempt_id": 20})
	check(count("goal") == 1 and count("music:complete") == 1, "Goal and UI completion sources deduplicate together")
	d.play_ui("select", "select-1")
	d.play_ui("select", "select-1")
	check(count("ui_select") == 1, "UI event identity deduplicated")
	d.play_ui("back", "back-1")
	check(count("ui_back") == 1, "back maps to original UI sound")
	# Reentrant delivery during the first cue must not revive an obsolete loop.
	var nested = Director.new()
	root.add_child(nested)
	var nested_once := [false]
	nested.cue_played.connect(func(cue: String, _id: Variant):
		if cue == "fall_start" and not nested_once[0]:
			nested_once[0] = true
			nested.consume_event(f.event("MOVE_APPLIED_NORMAL", "STARTED", 2, 2)))
	nested.consume_event(f.event("PERSPECTIVE_FALL_APPLIED", "STARTED", 1))
	check(not nested.snapshot().playing.has("sfx:fall_whoosh"), "reentrant new action cannot revive old Fall loop")
	nested.clear()
	root.remove_child(nested)
	nested.queue_free()
	var old_cancel = Director.new()
	root.add_child(old_cancel)
	old_cancel.cue_played.connect(func(cue: String, _id: Variant):
		if cue == "fall_start": old_cancel.cancel(f.identity(0)))
	old_cancel.consume_event(f.event("PERSPECTIVE_FALL_APPLIED", "STARTED", 1))
	check(old_cancel.snapshot().playing.has("sfx:fall_whoosh"), "reentrant old cancel cannot suppress new Fall loop")
	old_cancel.clear()
	root.remove_child(old_cancel)
	old_cancel.queue_free()
	var lifecycle = Director.new()
	root.add_child(lifecycle)
	var lifecycle_log: Array[String] = []
	lifecycle.cue_played.connect(func(cue: String, _id: Variant): lifecycle_log.append(cue))
	lifecycle.consume_event(f.event("PERSPECTIVE_FALL_APPLIED", "STARTED", 1))
	lifecycle.set_paused(true)
	var interrupt: Dictionary = f.event("ANIMATION_INTERRUPTED", "INTERRUPTED", 2)
	interrupt.interruption_reason = "RESET"
	lifecycle.consume_event(interrupt)
	check(not lifecycle.snapshot().playing.has("sfx:fall_whoosh"), "interruption stops scoped loop even while paused")
	lifecycle.set_paused(false)
	check(not lifecycle.snapshot().playing.has("sfx:fall_whoosh"), "resume cannot resurrect paused interruption")
	lifecycle.play_ui("complete", f.identity())
	check(not lifecycle_log.has("goal"), "canceled identity cannot revive completion via UI")
	lifecycle.consume_event(f.event("PERSPECTIVE_FALL_APPLIED", "STARTED", 3, 2))
	lifecycle.set_paused(true)
	lifecycle.consume_event(f.event("PERSPECTIVE_FALL_APPLIED", "COMMITTED", 4, 2))
	check(not lifecycle.snapshot().playing.has("sfx:fall_whoosh") and not lifecycle_log.has("landing_impact"), "paused commit stops loop and defers impact")
	lifecycle.set_paused(false)
	check(lifecycle_log.count("landing_impact") == 1, "resume plays queued committed impact once")
	lifecycle.set_paused(true)
	lifecycle.consume_event(f.event("PERSPECTIVE_FALL_APPLIED", "COMMITTED", 5, 2))
	lifecycle.set_paused(false)
	check(lifecycle_log.count("landing_impact") == 1, "paused duplicate commit remains deduplicated")
	lifecycle.clear()
	lifecycle.consume_event(f.event("MOVE_APPLIED_NORMAL", "STARTED", 1, 1, 0, "run-B"))
	lifecycle.play_ui("complete", f.identity(99))
	check(not lifecycle_log.has("goal") and lifecycle.snapshot().context == "exploration", "retired UI completion cannot fade new run music")
	lifecycle.consume_event(f.event("MOVE_APPLIED_NORMAL", "STARTED", 2, 2, 1, "run-B"))
	lifecycle.play_ui("complete", f.identity(10, 0, "run-B"))
	check(not lifecycle_log.has("goal"), "old-generation UI completion silent")
	lifecycle.clear()
	lifecycle.consume_event(f.event("PERSPECTIVE_FALL_APPLIED", "STARTED", 1, 1, 0, "run-C"))
	lifecycle.set_paused(true)
	lifecycle.consume_event(f.event("PERSPECTIVE_FALL_APPLIED", "COMMITTED", 2, 1, 0, "run-C"))
	lifecycle.cancel(f.identity(1, 0, "run-C"))
	lifecycle.set_paused(false)
	check(lifecycle_log.count("landing_impact") == 1, "cancel removes deferred paused landing before resume")
	lifecycle.clear()
	root.remove_child(lifecycle)
	lifecycle.queue_free()
	await wait(0.15)
	d.apply_settings({"master": 0.5, "music": 0.0, "sfx": 0.7, "muted": false, "fullscreen": true})
	check(AudioServer.is_bus_mute(AudioServer.get_bus_index("Ambience")), "music zero mutes music bus")
	check(not AudioServer.is_bus_mute(AudioServer.get_bus_index("SFX")), "music slider leaves SFX audible")
	check(absf(AudioServer.get_bus_volume_db(0) - linear_to_db(0.5)) < 0.01, "legacy master gain formula")
	d.apply_settings({"master": 1.0, "music": 0.6, "sfx": 0.0, "muted": false})
	check(AudioServer.is_bus_mute(AudioServer.get_bus_index("SFX")) and not AudioServer.is_bus_mute(AudioServer.get_bus_index("Ambience")), "SFX independently controlled")
	d.apply_settings({"master": 1.0, "music": 1.0, "sfx": 1.0, "muted": true})
	check(AudioServer.is_bus_mute(0), "existing muted key controls Master")
	await wait(0.15)
	d.apply_settings({"master": 1.0, "music": 1.0, "sfx": 1.0, "muted": false})
	check(not AudioServer.is_bus_mute(0) and is_zero_approx(AudioServer.get_bus_volume_db(0)), "caller can restore preview with original settings")
	d.apply_settings({"master": 0.0})
	d.apply_settings({"muted": false})
	check(AudioServer.is_bus_mute(0), "mute-only preview does not unmute zero-volume Master")
	d.apply_settings({"master": 1.0, "muted": false})
	d.set_music("exploration", 0)
	var surface: AudioStreamPlayer = d.get_node_or_null("music_surface")
	var inner: AudioStreamPlayer = d.get_node_or_null("music_inner")
	if surface != null and inner != null:
		surface.play(39.90)
		inner.play(39.90)
		await wait(0.35)
		check(surface.playing and inner.playing and surface.get_playback_position() < 1.0 and inner.get_playback_position() < 1.0, "actual paired WAV loop wraps across exported endpoint")
	else:
		check(false, "actual paired WAV loop wraps across exported endpoint")
	d.clear()
	check(d.snapshot().playing.is_empty(), "clear stops every SFX and music loop synchronously")
	d.play_ui("select", "select-1")
	check(count("ui_select") == 1, "clear retains UI dedup against late callback")
	d.consume_event(f.event("PERSPECTIVE_FALL_APPLIED", "STARTED", 30, 30))
	check(count("fall_start") == 2, "clear rejects late start in retired run")
	var missing = Director.new()
	missing.manifest_path = "res://production/experimental/game_feel_01/audio/not_present.json"
	root.add_child(missing)
	missing.consume_event(f.event("MOVE_APPLIED_NORMAL", "STARTED", 1))
	check(not missing.snapshot().issues.is_empty() and missing.snapshot().playing.is_empty(), "missing audio silently diagnoses and never blocks caller")
	missing.clear()
	root.remove_child(missing)
	missing.queue_free()
	root.remove_child(d)
	d.queue_free()
	# Owner-local v2 port fixtures, actual players; not natural Runtime/trajectory playback.
	var curve = Director.new()
	root.add_child(curve)
	var curve_log: Array[String] = []
	curve.cue_played.connect(func(cue: String, _id: Variant): curve_log.append(cue))
	curve.consume_event(f.v2_event("PERSPECTIVE_FALL_APPLIED", "STARTED", 1))
	check(curve_log == ["fall_start", "fall_whoosh"] and not curve_log.has("landing_impact"), "v2 actual STARTED voices have no early impact")
	check(curve.snapshot().playing.has("sfx:fall_whoosh"), "v2 captured whoosh actually playing")
	curve.consume_event(f.v2_event("PERSPECTIVE_FALL_APPLIED", "STARTED", 1))
	check(curve_log.size() == 2, "v2 duplicate start allocates no extra voice")
	curve.consume_event(f.v2_event("PERSPECTIVE_FALL_APPLIED", "COMMITTED", 2))
	check(curve_log.count("landing_impact") == 1, "v2 actual COMMITTED plays one impact")
	check(not curve.snapshot().playing.has("sfx:fall_whoosh"), "v2 commit synchronously stops scoped whoosh")
	curve.consume_event(f.v2_event("PERSPECTIVE_FALL_APPLIED", "COMMITTED", 3))
	check(curve_log.count("landing_impact") == 1, "v2 duplicate commit has no extra impact")
	curve.consume_event(f.v2_event("PERSPECTIVE_FALL_APPLIED", "STARTED", 4, 2))
	var canceled := f.v2_event("ANIMATION_INTERRUPTED", "INTERRUPTED", 5, 2)
	canceled.interruption_reason = "CANCEL"
	curve.consume_event(canceled)
	check(not curve.snapshot().playing.has("sfx:fall_whoosh"), "v2 native-shaped Cancel stops live loop")
	curve.consume_event(f.v2_event("PERSPECTIVE_FALL_APPLIED", "COMMITTED", 6, 2))
	check(curve_log.count("landing_impact") == 1, "v2 actual late canceled commit produces no ghost sound")
	curve.consume_event(f.v2_event("PERSPECTIVE_FALL_APPLIED", "STARTED", 7, 3))
	curve.set_paused(true)
	curve.consume_event(f.v2_event("PERSPECTIVE_FALL_APPLIED", "COMMITTED", 8, 3))
	var reset := f.v2_event("ANIMATION_INTERRUPTED", "INTERRUPTED", 9, 3)
	reset.interruption_reason = "RESET"
	curve.consume_event(reset)
	curve.set_paused(false)
	check(curve_log.count("landing_impact") == 1, "v2 Reset removes paused deferred impact before resume")
	curve.consume_event(f.v2_event("PERSPECTIVE_FALL_APPLIED", "STARTED", 10, 4))
	curve.consume_event(canceled)
	check(curve.snapshot().playing.has("sfx:fall_whoosh"), "v2 old Cancel cannot stop replacement actual voice")
	curve.consume_event(f.v2_event("PERSPECTIVE_FALL_APPLIED", "COMMITTED", 11, 4))
	check(curve_log.count("landing_impact") == 2, "v2 replacement lands exactly once after old Cancel")
	curve.clear()
	check(curve.snapshot().playing.is_empty(), "v2 teardown stops all actual voices")
	root.remove_child(curve)
	curve.queue_free()
	f.free()
	await wait(0.2)
	measure()
	check(pcm.size() > 20000 and peak > 0.001 and energy > 0.0, "actual Godot mixed PCM is nonzero")
	check(peak < 0.95, "actual Godot mix has headroom")
	meter.stop()
	AudioServer.remove_bus_effect(capture_bus, AudioServer.get_bus_effect_count(capture_bus) - 1)
	for i in initial_buses.size():
		AudioServer.set_bus_volume_db(i, initial_buses[i].volume)
		AudioServer.set_bus_mute(i, initial_buses[i].mute)
	var raw := PackedByteArray()
	raw.resize(pcm.size() * 4)
	for i in pcm.size():
		raw.encode_s16(i * 4, int(clampf(pcm[i].x, -1, 1) * 32767))
		raw.encode_s16(i * 4 + 2, int(clampf(pcm[i].y, -1, 1) * 32767))
	var wav := AudioStreamWAV.new()
	wav.format = AudioStreamWAV.FORMAT_16_BITS
	wav.stereo = true
	wav.mix_rate = int(AudioServer.get_mix_rate())
	wav.data = raw
	wav.save_to_wav(output.path_join("actual_mix.wav"))
	var report := {"fixture_kind": "PRESENTATION_CONTRACT_UNIT", "authoritative_runtime": false, "doubles": ["synthetic game_feel.event.v1/v2 snapshots; no Safety proof"], "checks": checks, "failures": failures,
		"pid": OS.get_process_id(), "engine": Engine.get_version_info(), "user_data_dir": OS.get_user_data_dir(), "display": DisplayServer.get_name(), "renderer": "gl_compatibility/opengl3", "audio_driver": "WASAPI (explicit process argument)", "pcm_frames": pcm.size(), "mix_rate": AudioServer.get_mix_rate(), "peak": peak, "rms": sqrt(energy / maxf(1.0, pcm.size() * 2.0)), "human_listening": "NOT_RUN", "cue_log": heard}
	var file := FileAccess.open(output.path_join("director.json"), FileAccess.WRITE)
	file.store_string(JSON.stringify(report, "\t"))
	root.remove_child(meter)
	meter.queue_free()
	await wait(0.2)
	print("AUDIO_DIRECTOR checks=", checks, " failures=", failures.size(), " peak=", peak)
	quit(0 if failures.is_empty() else 1)
