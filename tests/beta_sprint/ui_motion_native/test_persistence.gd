extends SceneTree
## Real Host/UI/SaveStore transactions, with a filesystem failure and a cold reader.
## Never seeds progress, unlocks, completions, or a replacement SaveStore.
const VALUES := {"master":0.36,"music":0.44,"sfx":0.52,"fullscreen":false,"muted":true}
const OPTIONS := {"version":1,"reduced_motion":true,"hint_strength":2,"contrast":true,"input_hints":false}
var shell
var bridge
var phase := ""
var save_path := ""
var evidence := ""
var checks := 0
var failures: Array[String] = []
var observations: Dictionary = {}

func _initialize() -> void:
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--phase="): phase = arg.trim_prefix("--phase=")
		elif arg.begins_with("--shell-save="): save_path = arg.trim_prefix("--shell-save=")
		elif arg.begins_with("--evidence-dir="): evidence = arg.trim_prefix("--evidence-dir=")
	call_deferred("run")

func check(value: bool, label: String) -> void:
	checks += 1
	if not value: failures.append(label)

func frames(count: int = 6) -> void:
	for frame in count: await process_frame

func run() -> void:
	create_timer(60).timeout.connect(func(): print("NATIVE_PERSISTENCE_TIMEOUT"); quit(2))
	check(phase in ["write","restore"] and save_path.begins_with("user://native_menu/persistence/") and not evidence.is_empty(), "explicit isolated phase/save/evidence")
	if not failures.is_empty(): finish(); return
	check(FileAccess.file_exists(save_path) == (phase == "restore"), "writer is fresh and cold reader reuses saved slot")
	shell = load("res://game/shell/game_feel_shell.tscn").instantiate()
	shell.save_path = save_path
	root.add_child(shell)
	bridge = shell.game_feel
	await frames()
	check(shell.state == shell.State.MAIN_MENU and shell.adapter.level == null, "real Shell starts in main menu")
	check(not shell.progress.has_progress and shell.progress.recent == "" and shell.progress.completed.is_empty() and shell.progress.unlocked == [shell.catalog.first_id()], "settings tests leave natural fresh progress untouched")
	check(shell.view.buttons.continue.disabled, "settings never create Continue progress")
	if phase == "write": await write_checks()
	else: await restore_checks()
	observations["settings"] = shell.progress.settings.duplicate(true)
	observations["buses"] = bus_snapshot()
	observations["actor_reduced_motion"] = shell.view.backdrop.debug_state().reduced_motion
	observations["menu_world"] = shell.view.debug_snapshot().world_layer
	check(not shell.progress.has_progress and shell.progress.completed.is_empty() and shell.progress.unlocked == [shell.catalog.first_id()], "all transactions preserve actual fresh progress and locks")
	shell.queue_free()
	await frames()
	await create_timer(0.2).timeout
	finish()

func choose_values() -> void:
	for key in ["master","music","sfx"]: bridge.ui.sliders[key].value = VALUES[key] * 100.0
	bridge.ui.buttons.muted.button_pressed = VALUES.muted
	bridge.ui.buttons.reduced_motion.button_pressed = OPTIONS.reduced_motion
	bridge.ui.sliders.hint_strength.value = OPTIONS.hint_strength
	bridge.extra_controls.contrast.button_pressed = OPTIONS.contrast
	bridge.extra_controls.input_hints.button_pressed = OPTIONS.input_hints

func check_values(settings: Dictionary, label: String) -> void:
	for key in ["master","music","sfx"]: check(is_equal_approx(float(settings[key]),VALUES[key]), label + " " + key)
	for key in ["fullscreen","muted"]: check(settings[key] == VALUES[key], label + " " + key)
	check(options_match(settings.get("game_feel",{})), label + " all versioned accessibility options")

func options_match(options: Dictionary) -> bool:
	var matches := options.size() == 5
	for key in ["reduced_motion","contrast","input_hints"]:
		matches = matches and options.get(key) is bool and options[key] == OPTIONS[key]
	for key in ["version","hint_strength"]:
		var value: Variant = options.get(key)
		matches = matches and (value is int or value is float) and is_finite(float(value)) and float(value) == float(OPTIONS[key])
	return matches

func check_controls(label: String) -> void:
	for key in ["master","music","sfx"]: check(is_equal_approx(bridge.ui.sliders[key].value,VALUES[key] * 100.0), label + " " + key)
	check(bridge.ui.buttons.muted.button_pressed and not bridge.ui.buttons.fullscreen.button_pressed, label + " mute/fullscreen")
	check(bridge.ui.buttons.reduced_motion.button_pressed and bridge.ui.sliders.hint_strength.value == 2, label + " reduced motion and hint strength")
	check(bridge.extra_controls.contrast.button_pressed and not bridge.extra_controls.input_hints.button_pressed, label + " contrast and input hints")

func bus_snapshot() -> Dictionary:
	var result := {}
	for key in ["Master","Ambience","SFX"]:
		var index := AudioServer.get_bus_index(key)
		result[key] = {"db":AudioServer.get_bus_volume_db(index),"muted":AudioServer.is_bus_mute(index)}
	return result

func check_buses(values: Dictionary, label: String) -> void:
	for entry in [["master","Master",0.0],["music","Ambience",-12.0],["sfx","SFX",-6.0]]:
		var index := AudioServer.get_bus_index(entry[1])
		check(index >= 0, label + " configured " + entry[1])
		if index < 0: continue
		check(is_equal_approx(AudioServer.get_bus_volume_db(index),linear_to_db(float(values[entry[0]])) + entry[2]), label + " gain " + entry[1])
		check(AudioServer.is_bus_mute(index) == (entry[0] == "master" and values.muted), label + " mute " + entry[1])

func fail_save(blocked_path: String, baseline: Dictionary, baseline_hash: String, label: String) -> void:
	shell.store.path = blocked_path
	shell.save_settings()
	await frames()
	check(shell.settings_open and bridge.ui.settings_open, label + " keeps real drawer open")
	check(not shell.store.last_error.is_empty() and bridge.ui.error_label.visible and not bridge.ui.error_label.text.is_empty(), label + " displays actual SaveStore failure")
	check(not bridge.ui.buttons.apply.disabled and not bridge.ui.buttons.cancel.disabled and bridge.ui.sliders.master.editable, label + " permits retry or cancel")
	check(root.gui_get_focus_owner() == bridge.ui.buttons.apply, label + " focuses retry action")
	check_controls(label + " retains visible draft")
	check(shell.progress == baseline and FileAccess.get_sha256(save_path) == baseline_hash, label + " preserves memory and original save bytes")
	check_buses(baseline.settings,label + " restores saved audio")
	check(not bridge.options.reduced_motion and not bridge.options.contrast and bridge.options.input_hints, label + " restores saved accessibility effect")
	check(not shell.view.backdrop.debug_state().reduced_motion, label + " restores menu actor motion")
	check(not FileAccess.file_exists(blocked_path), label + " creates no impossible child save")

func write_checks() -> void:
	# Establish the primary through the real UI, without a progress fixture.
	shell.open_settings()
	shell.save_settings()
	await frames()
	check(not shell.settings_open and FileAccess.file_exists(save_path), "unchanged native settings create a real baseline save")
	var baseline: Dictionary = shell.progress.duplicate(true)
	var baseline_hash := FileAccess.get_sha256(save_path)
	var blocker := save_path.get_base_dir().path_join("not_a_directory")
	var file := FileAccess.open(blocker,FileAccess.WRITE)
	check(file != null, "owned filesystem failure fixture can be created")
	if file == null: return
	file.store_string("An ordinary file prevents SaveStore from creating a child directory.")
	file.close()
	var blocked_path := blocker.path_join("progress.json")
	observations["failure_seam"] = "Actual SaveStore path has an ordinary file as parent; no doubles."
	shell.open_settings()
	choose_values()
	await frames()
	check_buses(VALUES,"real preview")
	check(options_match(bridge.options) and shell.view.backdrop.debug_state().reduced_motion, "real preview routes accessibility and menu reduced motion")
	check(shell.progress == baseline and FileAccess.get_sha256(save_path) == baseline_hash, "preview does not write settings or progress")
	await fail_save(blocked_path,baseline,baseline_hash,"failed save before cancel")
	shell.store.path = save_path
	shell.cancel_settings()
	await frames()
	check(not shell.settings_open and not bridge.ui.settings_open and not shell.view.debug_snapshot().settings_overlay, "cancel after real failure restores native menu")
	check(shell.progress == baseline and FileAccess.get_sha256(save_path) == baseline_hash, "cancel after failure preserves original save")
	check_buses(baseline.settings,"cancel after failure")
	check(not shell.view.backdrop.debug_state().reduced_motion and not bridge.options.contrast and bridge.options.input_hints, "cancel restores saved menu/accessibility effect")
	shell.open_settings()
	choose_values()
	await fail_save(blocked_path,baseline,baseline_hash,"failed save before retry")
	shell.store.path = save_path
	# No field edits between failure and retry: the retained draft must be reapplied.
	shell.save_settings()
	await frames()
	check(not shell.settings_open and not bridge.ui.settings_open and shell.store.last_error.is_empty(), "retry without edits completes actual native transaction")
	check_values(shell.progress.settings,"retry stores original draft")
	check_values(shell.store.load_save().settings,"retry persists original draft")
	check_buses(VALUES,"retry reapplies original draft audio")
	check(options_match(bridge.options) and shell.view.backdrop.debug_state().active and shell.view.backdrop.debug_state().reduced_motion, "retry reapplies accessibility and active menu actor")
	check(FileAccess.get_sha256(save_path) != baseline_hash, "successful retry replaces the baseline save")
	observations["baseline_sha256"] = baseline_hash

func restore_checks() -> void:
	check_values(shell.progress.settings,"cold process restores saved settings")
	check_buses(VALUES,"cold process restores real audio")
	check(options_match(bridge.options), "cold process restores effective auxiliary options")
	check(shell.view.backdrop.debug_state().active and shell.view.backdrop.debug_state().reduced_motion, "cold menu actor is active with saved reduced motion")
	var pose: Transform3D = shell.view.backdrop.debug_state().pose
	await create_timer(0.15).timeout
	check(shell.view.backdrop.debug_state().pose.is_equal_approx(pose), "cold reduced-motion actor remains still")
	# A real local selector also verifies the restored contrast consumes Inner ink.
	shell.view.world_buttons[1].pressed.emit()
	shell.open_settings()
	await frames()
	check_controls("cold native controls")
	check(bridge.ui._presentation_world == 1 and bridge.ui.error_label.get_theme_color("font_color") == Color.WHITE, "cold contrast routes white ink into Inner native drawer")
	check(shell.view.backdrop.debug_state().world_layer == 1 and shell.adapter.level == null, "cold menu selector remains presentation only")
	var saved_hash := FileAccess.get_sha256(save_path)
	shell.cancel_settings()
	await frames()
	check(FileAccess.get_sha256(save_path) == saved_hash and options_match(bridge.options), "cold open/cancel preserves persisted options and bytes")

func finish() -> void:
	var report := {"phase":phase,"checks":checks,"failures":failures,"pid":OS.get_process_id(),"display":DisplayServer.get_name(),"user_data_dir":OS.get_user_data_dir(),"save_path":ProjectSettings.globalize_path(save_path),"save_sha256":FileAccess.get_sha256(save_path) if FileAccess.file_exists(save_path) else "","observations":observations,"doubles":[],"scope":"HEADLESS_REAL_NATIVE_SETTINGS_FAILURE_RETRY_CANCEL_COLD_RESTORE","human_qa":"NOT_RUN","progress_fixture":"none; ordinary settings transaction keeps fresh progress and locks"}
	if not evidence.is_empty():
		var file := FileAccess.open(evidence.path_join("persistence_" + phase + ".json"),FileAccess.WRITE)
		if file: file.store_string(JSON.stringify(report,"\t")); file.close()
	print(JSON.stringify(report))
	quit(0 if failures.is_empty() else 1)
