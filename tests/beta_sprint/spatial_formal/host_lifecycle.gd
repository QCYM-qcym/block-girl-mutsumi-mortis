extends SceneTree
## Real Host/Runtime/Presenter integration; no replacement runtime or injected finishes.
const WRAPPER := "res://game/levels/mutsumi/spatial_chapter/spatial_level.gd"
const Maps = preload("res://experiments/spatial_puzzle_batch_01/maps/map_factory.gd")
var checks := 0
var failures: Array = []
var completions := 0
var pauses := 0

func _initialize() -> void:
	call_deferred("run")

func check(ok: bool, label: String) -> void:
	checks += 1
	if not ok:
		failures.append(label)
		print("FAIL: ", label)

func settle(level: Node) -> void:
	var deadline := Time.get_ticks_msec() + 4000
	while (not level.host.runtime.is_idle() or level.host.presenter.snapshot().phase != "IDLE") and Time.get_ticks_msec() < deadline:
		await process_frame
	await process_frame
	check(level.host.runtime.is_idle(), "natural Host animation commits before deadline")

func key(level: Node, code: int) -> void:
	var event := InputEventKey.new()
	event.keycode = code
	event.physical_keycode = code
	event.pressed = true
	level._unhandled_key_input(event)

func make_level(id: StringName) -> Node:
	var level: Node = load(WRAPPER).new()
	level.map_id = id
	level.completed.connect(func(): completions += 1)
	level.completed.connect(func(): check(level.host.runtime.is_idle() and level.host.presenter.snapshot().phase == "IDLE" and level.host._camera_motion.is_empty() and level.host._shift_identity.is_empty(), "Shell completion follows natural Presenter and native motion settling"))
	level.pause_requested.connect(func(): pauses += 1)
	root.add_child(level)
	return level

func play(level: Node, actions: Array) -> void:
	for action in actions:
		var result: Dictionary = level.host.runtime.request_action(action)
		check(result.status == 0, "authored witness action accepted by actual Runtime: %s %s" % [level.map_id, action])
		await settle(level)

func run() -> void:
	check(ResourceLoader.exists(WRAPPER), "formal level wrapper is available")
	if not ResourceLoader.exists(WRAPPER):
		finish()
		return
	# Missing map binding, early Goal or duplicate completion breaks this test.
	for id in Maps.ids():
		var before := completions
		var level := make_level(id)
		check(level.host.lab_id == id and level.host.runtime.is_loaded(), "exported map ID loads actual authored spatial map")
		check(not level.host.status.visible, "formal Shell owns the screen HUD")
		level.host.goal_reached.emit(id)
		level.host.runtime.committed.emit(level.host.runtime.get_state())
		await process_frame
		check(completions == before, "raw Goal notification and non-action commit cannot complete")
		var witnesses: Dictionary = Maps.witnesses(id)
		var route: Array = witnesses.get("solution", witnesses.get("solution_a", witnesses.get("solution_east", [])))
		await play(level, route)
		check(completions == before + 1, "actual natural committed Goal completes exactly once")
		level.host.goal_reached.emit(id)
		level.host.runtime.committed.emit(level.host.runtime.get_state())
		await process_frame
		check(completions == before + 1, "duplicate Goal and committed notification do not repeat completion")
		check(level.host.host_issues.is_empty(), "actual Host reports no issues")
		level.free()
		await process_frame
	# Reset must retire queued Goal callbacks; a fresh run can still finish.
	var level := make_level(&"orientation_loop_lab")
	level.set_reduced_motion(true)
	var initial: Dictionary = level.host.runtime.get_state()
	var before := completions
	var input_on_goal := func(state: Dictionary):
		if state.player.location.cube_id == &"goal":
			var count: int = level.host.events.size()
			key(level, KEY_A)
			check(level.host.events.size() == count, "pending Goal blocks movement before natural landing finishes")
	level.host.runtime.committed.connect(input_on_goal)
	await play(level, [{"kind":0,"face_axis":0}, {"kind":0,"face_axis":3}, {"kind":0,"face_axis":0}])
	level.host.runtime.committed.disconnect(input_on_goal)
	level.reset_level()
	before = completions
	var pause_on_goal := func(state: Dictionary):
		if state.player.location.cube_id == &"goal": level.set_level_paused(true)
	level.host.runtime.committed.connect(pause_on_goal)
	await play(level, [{"kind":0,"face_axis":0}, {"kind":0,"face_axis":3}, {"kind":0,"face_axis":0}])
	check(completions == before, "Goal committed immediately before pause waits for resume")
	level.host.runtime.committed.disconnect(pause_on_goal)
	level.set_level_paused(false)
	await settle(level)
	check(completions == before + 1, "resume delivers pending authoritative Goal once")
	level.reset_level()
	before = completions
	var reset_on_goal := func(state: Dictionary):
		if state.player.location.cube_id == &"goal": level.reset_level()
	level.host.runtime.committed.connect(reset_on_goal)
	await play(level, [{"kind":0,"face_axis":0}, {"kind":0,"face_axis":3}, {"kind":0,"face_axis":0}])
	check(completions == before and level.host.runtime.get_state() == initial, "same-frame Reset suppresses deferred Goal from retired generation")
	level.host.runtime.committed.disconnect(reset_on_goal)
	await play(level, [{"kind":0,"face_axis":0}, {"kind":0,"face_axis":3}, {"kind":0,"face_axis":0}])
	check(completions == before + 1, "new run completes after reset retired prior Goal")
	level.reset_level()
	# Paused input must never even request actions, hints or keyboard resets.
	level.set_level_paused(true)
	var scope: Dictionary = level.host.runtime.get_presentation_scope()
	var events_before: int = level.host.events.size()
	for code in [KEY_D, KEY_F, KEY_Q, KEY_SPACE, KEY_R, KEY_H, KEY_ESCAPE]: key(level, code)
	check(level.host.runtime.get_state() == initial and level.host.runtime.get_presentation_scope() == scope and level.host.events.size() == events_before, "pause blocks inherited action/reset input before Runtime")
	check(level.host.paused and level.host.audio_bridge.snapshot().paused, "pause reaches real Host and audio")
	level.set_level_paused(false)
	key(level, KEY_ESCAPE)
	check(not level.host.paused and pauses == 0, "Escape remains solely owned by formal Shell")
	key(level, KEY_D)
	check(not level.host.runtime.is_idle(), "active movement input reaches actual Runtime")
	key(level, KEY_R)
	await process_frame
	check(level.host.runtime.get_state() == initial and level.host.runtime.is_idle(), "keyboard Reset cancels pending native movement")
	level.host.menu_requested.emit()
	check(pauses == 1 and level.host.paused, "Host menu request pauses and bridges once to Shell")
	level.set_level_paused(false)
	level.apply_settings({"master":0.6,"music":0.4,"sfx":0.2,"muted":true})
	level.set_reduced_motion(true)
	check(level.host.audio_bridge.snapshot().master_muted, "formal settings use existing audio Director")
	check(level.host._reduced_motion, "reduced motion reaches native Shift as well as Presenter")
	key(level, KEY_H)
	level.apply_accessibility({"hint_strength":0,"input_hints":false})
	check(not level.get_hint_presentation().hint_visible and not level.get_hint_presentation().input_hints, "accessibility disables contextual and input hints")
	var runtime = level.host.runtime
	key(level, KEY_D)
	root.remove_child(level)
	check(not runtime.is_loaded(), "unload retires actual Runtime before queued callbacks")
	key(level, KEY_D)
	level.free()
	await process_frame
	check(completions == before + 1, "unloaded Host cannot complete pending action")
	# Allow the audio server to retire stopped WAV playback references.
	await create_timer(0.1).timeout
	finish()

func finish() -> void:
	print("SPATIAL FORMAL HOST: %d checks, failures=%s" % [checks, failures])
	var evidence := OS.get_environment("FOUNDATION_TEST_EVIDENCE")
	if not evidence.is_empty():
		FileAccess.open(evidence.path_join("report.json"), FileAccess.WRITE).store_string(JSON.stringify({"checks":checks,"failures":failures,"display":DisplayServer.get_name(),"user_data_dir":OS.get_user_data_dir(),"pid":OS.get_process_id(),"doubles":[]}, "\t"))
	quit(0 if failures.is_empty() else 1)
