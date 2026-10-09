extends SceneTree
## PRESENTATION_CONTRACT_UNIT. Synthetic events and explicit legacy host sink, no legal Fall claim.
const UI_PATH := "res://game/feel/ui/game_feel_ui.gd"
const Store = preload("res://game/shell/save_store.gd")
const LegacySettings = preload("res://game/shell/settings.gd")
var checks := 0
var failures: Array[String] = []
var evidence := ""
var save_path := ""
var phase := "seed"
var ui
var progress: Dictionary
var preview_calls: Array[Dictionary] = []
var option_calls: Array[Dictionary] = []
var store
var apply_count := 0
var cancel_count := 0
var defer_apply := false

func _initialize() -> void:
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--evidence-dir="): evidence = arg.trim_prefix("--evidence-dir=")
		elif arg.begins_with("--shell-save="): save_path = arg.trim_prefix("--shell-save=")
		elif arg.begins_with("--phase="): phase = arg.trim_prefix("--phase=")
	call_deferred("run")

func check(ok: bool, label: String) -> void:
	checks += 1
	if not ok:
		failures.append(label)
		printerr("FAIL: ",label)

func settle() -> void:
	for frame in 5: await process_frame

func run() -> void:
	check(DisplayServer.get_name() == "headless" and save_path.begins_with("user://beta_sprint/") and ".." not in save_path and not evidence.is_empty(), "fresh isolated Owner headless UI execution")
	check(ResourceLoader.exists(UI_PATH), "lab UI exists in the allocated independent owner namespace")
	if not failures.is_empty():
		await finish()
		return
	store = Store.new(save_path,"mutsumi_l01")
	progress = store.load_save()
	if phase == "seed": check(not FileAccess.file_exists(save_path), "Unit host sink cannot overwrite prior progress")
	LegacySettings.apply(progress.settings,root)
	ui = load(UI_PATH).new()
	root.add_child(ui)
	ui.settings_preview.connect(func(values: Dictionary):
		preview_calls.append(values.duplicate(true))
		LegacySettings.apply(values,root))
	ui.settings_apply.connect(host_apply)
	ui.settings_cancel.connect(func(): cancel_count += 1)
	ui.accessibility_changed.connect(func(values: Dictionary): option_calls.append(values.duplicate(true)))
	await settle()
	if phase == "seed":
		await settings_case()
		await event_case()
	else: await restore_case()
	await finish()

func host_apply(values: Dictionary) -> void:
	# Explicit Unit integration sink. Production00 owns this callback, not the UI.
	if defer_apply: return
	var candidate := progress.duplicate(true)
	candidate.settings = values.duplicate(true)
	if store.save(candidate):
		progress = candidate
		apply_count += 1
		ui.settings_applied(values)
	else: ui.settings_failed(store.last_error)

func settings_case() -> void:
	var original: Dictionary = progress.settings.duplicate(true)
	ui.open_settings(original)
	await settle()
	check(ui.sliders.keys().size() == 4 and ui.buttons.has("reduced_motion"), "lab Settings reuses three audio sliders plus Hint Strength and Reduced Motion")
	ui.sliders.master.value = 37
	ui.sliders.music.value = 21
	ui.sliders.sfx.value = 63
	ui.buttons.muted.button_pressed = true
	ui.buttons.reduced_motion.button_pressed = true
	ui.sliders.hint_strength.value = 2
	await settle()
	check(preview_calls.back().master == 0.37 and preview_calls.back().music == 0.21 and preview_calls.back().sfx == 0.63 and preview_calls.back().muted, "preview sends existing audio keys with actual control values")
	check(AudioServer.is_bus_mute(AudioServer.get_bus_index("Master")), "explicit legacy Unit sink proves requested Mute reaches real Master bus")
	check(is_equal_approx(AudioServer.get_bus_volume_db(AudioServer.get_bus_index("Master")),linear_to_db(0.37)), "explicit legacy Unit sink proves real Master gain preview")
	check(is_equal_approx(AudioServer.get_bus_volume_db(AudioServer.get_bus_index("Ambience")),linear_to_db(0.21)-12.0) and is_equal_approx(AudioServer.get_bus_volume_db(AudioServer.get_bus_index("SFX")),linear_to_db(0.63)-6.0), "explicit legacy sink applies actual Music and SFX gain with existing calibration")
	check(option_calls.back().reduced_motion and option_calls.back().hint_strength == 2, "Reduced Motion and Hint Strength notify the external presentation-config port")
	check(not preview_calls.back().has("reduced_motion") and not preview_calls.back().has("hint_strength"), "UI config does not invent a conflicting Settings save contract")
	ui.buttons.cancel.pressed.emit()
	await settle()
	check(cancel_count == 1 and preview_calls.back() == original and not ui.settings_open, "Cancel restores saved audio preview and returns")
	check(not option_calls.back().reduced_motion and option_calls.back().hint_strength == 1, "Cancel also restores presentation configuration")
	check(not FileAccess.file_exists(save_path), "cancelled UI has no independent Save write")
	ui.open_settings(original)
	await settle()
	ui.sliders.master.value = 37
	ui.sliders.music.value = 21
	ui.sliders.sfx.value = 63
	ui.buttons.muted.button_pressed = true
	ui.buttons.apply.pressed.emit()
	await settle()
	check(apply_count == 1 and not ui.settings_open, "Apply closes only after explicit host persistence acknowledgement")
	var saved: Dictionary = Store.new(save_path,"mutsumi_l01").load_save()
	check(saved.settings.master == 0.37 and saved.settings.music == 0.21 and saved.settings.sfx == 0.63 and saved.settings.muted and Store.VERSION == 1, "existing version1 storage retains actual requested audio settings")
	check(not saved.has_progress and saved.unlocked == ["mutsumi_l01"] and saved.completed.is_empty(), "UI settings never alter progression")
	ui.open_settings(saved.settings)
	await settle()
	ui.settings_failed("Unit injected host write failure")
	check(ui.settings_open and not ui.error_label.text.is_empty(), "host failure stays open and reports its real failure")
	ui.buttons.cancel.pressed.emit()
	await settle()
	ui.open_settings(saved.settings)
	await settle()
	defer_apply = true
	ui.buttons.apply.pressed.emit()
	await settle()
	check(ui.settings_open and ui.buttons.apply.disabled, "async Apply cannot close or repeat before the real host acknowledges persistence")
	check(not ui.sliders.master.editable and ui.buttons.muted.disabled and ui.buttons.cancel.disabled, "pending persistence freezes controls so displayed values cannot diverge from submitted draft")
	ui.sliders.master.value = 80 # Explicit external/programmatic fault; not natural player input.
	ui.settings_failed("Unit delayed host failure")
	check(ui.sliders.master.value == 37 and ui.sliders.master.editable and not ui.buttons.cancel.disabled, "failure restores exact submitted display and re-enables retry/cancel")
	ui.buttons.cancel.pressed.emit()
	defer_apply = false
	await settle()

func cue(event_id: int, semantic: String, phase_name: String, reason := "NONE", transaction := 5) -> Dictionary:
	var source := {"location":{"layer":0,"cube_id":&"fixture_source","face":0},"orientation":0}
	var target := {"location":{"layer":0,"cube_id":&"fixture_target","face":0},"orientation":0}
	var rejected := phase_name == "REJECTED"
	return {"schema_version":1,"contract_version":"game_feel.event.v1","semantic":semantic,"phase":phase_name,
		"event_id":event_id,"session_id":"unit_session","level_run_id":"unit_run","attempt_id":event_id,
		"presentation_identity":null if rejected else {"session_id":"unit_session","level_run_id":"unit_run","generation":1,"attempt_id":transaction},
		"transition_identity":null if rejected else {"session_id":"unit_session","level_run_id":"unit_run","generation":1,"transaction_id":transaction,"is_global":false},
		"result":{"status":1 if rejected else 0,"previous_state":{"player":source},"next_state":{"player":source if rejected else target},"action":{"kind":0,"args":{}},"changed":not rejected,"rejection_code":2000 if rejected else 0,"issues":[],"global_kind":null},
		"reason_category":reason,"source_pose":source,"target_pose":null if rejected else target,
		"source_face":source.location,"target_face":null if rejected else target.location,"world_id":0,"camera_quadrant":1,
		"authoritative_final_orientation":null if rejected else 0,"intended_move_direction":0,"interruption_reason":null,
		"connection_id":"fixture_connection","authorized_path_points2":[Vector3i(0,1,0),Vector3i(4,-1,0)],
		"motion_profile_id":"fixture_only","motion_profile_hash":"fixture_only","safety_verdict":"SAFE",
		"orientation_policy":"PRESERVE","presentation_duration_seconds":0.6,"source_frame":{}}

func event_case() -> void:
	ui.bind_context("unit_session","unit_run")
	var start := cue(1,"PERSPECTIVE_FALL_APPLIED","STARTED")
	var before := start.duplicate(true)
	ui.consume_event(start)
	check(ui.feedback_panel.visible and not ui.status_label.text.is_empty(), "authorized Fall fixture gives low-interference real-status presentation")
	check(ui.feedback_panel.mouse_filter == Control.MOUSE_FILTER_IGNORE and ui.status_label.focus_mode == Control.FOCUS_NONE, "status indicators do not capture gameplay input or focus")
	check(start == before, "UI consumes an immutable event without editing poses, Runtime result or authority")
	ui.consume_event(cue(2,"PERSPECTIVE_FALL_APPLIED","COMMITTED"))
	check(not ui.feedback_panel.visible, "matching committed Fall clears the temporary motion indicator")
	ui.consume_event(cue(3,"MOVE_REJECTED_EDGE","REJECTED","EDGE"))
	check(not ui.feedback_panel.visible, "ordinary typed edge rejection produces no blocked-road UI popup")
	ui.consume_event(cue(4,"ACTION_FEEDBACK","REJECTED","BUSY"))
	check(not ui.feedback_panel.visible, "Busy does not become edge, connection permission or a repeated popup")
	ui.set_authored_hint("fixture key hint","existing authored optional explanation")
	ui.set_accessibility({"reduced_motion":true,"hint_strength":2})
	ui.consume_event(cue(5,"ACTION_FEEDBACK","REJECTED","MECHANISM_LOCKED"))
	check(ui.feedback_panel.visible and not ui.detail_label.text.is_empty(), "explicit mechanism reason may show auxiliary explanation at player-selected strong hints")
	ui.set_accessibility({"reduced_motion":false,"hint_strength":0})
	check(not ui.detail_label.visible, "minimal hints hide optional stronger guidance")
	ui.consume_event(cue(6,"PERSPECTIVE_FALL_APPLIED","STARTED","NONE",6))
	var current_text: String = ui.status_label.text
	var stale := cue(7,"ANIMATION_INTERRUPTED","INTERRUPTED","NONE",5)
	stale.interruption_reason = "RESET"
	ui.consume_event(stale)
	check(ui.feedback_panel.visible and ui.status_label.text == current_text, "late old-token cancellation cannot clear a newer active Fall indicator")
	ui.consume_event(cue(8,"PERSPECTIVE_FALL_APPLIED","COMMITTED","NONE",5))
	check(ui.feedback_panel.visible, "late old-token commit cannot clear the current indicator")
	var matching := cue(9,"ANIMATION_INTERRUPTED","INTERRUPTED","NONE",6)
	matching.interruption_reason = "RESET"
	ui.consume_event(matching)
	check(not ui.feedback_panel.visible, "matching Reset interruption clears scoped UI without landing, Save or Runtime writes")
	ui.consume_event(start)
	check(not ui.feedback_panel.visible, "duplicate/stale event delivery cannot resurrect an old indicator")
	var other := cue(10,"PERSPECTIVE_FALL_APPLIED","STARTED")
	other.level_run_id = "different_run"
	ui.consume_event(other)
	check(not ui.feedback_panel.visible, "events from another level run do not affect current feedback")
	var malformed := cue(11,"PERSPECTIVE_FALL_APPLIED","STARTED")
	malformed.presentation_identity.session_id = "different_session"
	ui.consume_event(malformed)
	check(not ui.feedback_panel.visible, "invalid presentation identity cannot authorize feedback")
	ui.consume_event(cue(12,"ACTION_FEEDBACK","REJECTED","SAFETY_REJECTED"))
	check(not ui.feedback_panel.visible, "Safety rejection does not become permission or ordinary Edge popup")
	ui.set_accessibility({"hint_strength":2,"reduced_motion":true})
	ui.consume_event(cue(13,"ACTION_FEEDBACK","REJECTED","MECHANISM_LOCKED"))
	ui.consume_event(cue(14,"MOVE_APPLIED_NORMAL","STARTED"))
	check(not ui.feedback_panel.visible, "successful normal movement dismisses outdated mechanism feedback")
	ui.consume_event(cue(15,"ACTION_FEEDBACK","REJECTED","MECHANISM_LOCKED"))
	ui.set_authored_hint("", "")
	check(not ui.feedback_panel.visible, "removed authored guidance clears its auxiliary mechanism panel")
	ui.bind_context("unit_session","unit_run")
	ui.consume_event(start)
	check(not ui.feedback_panel.visible, "repeated binding to the same run cannot reset deduplication")
	ui.bind_context("unit_session","new_run")
	check(ui.detail_label.text.is_empty() and ui.input_label.text.is_empty(), "new run clears prior authored hints instead of reusing another level's guidance")

func restore_case() -> void:
	check(FileAccess.file_exists(save_path) and AudioServer.is_bus_mute(AudioServer.get_bus_index("Master")), "independent cold process loads actual saved Master mute")
	ui.open_settings(progress.settings)
	await settle()
	check(ui.sliders.master.value == 37 and ui.sliders.music.value == 21 and ui.sliders.sfx.value == 63 and ui.buttons.muted.button_pressed, "cold restart shows persisted audio values in independent lab controls")
	ui.buttons.cancel.pressed.emit()
	await settle()

func finish() -> void:
	var report := {"phase":phase,"pid":OS.get_process_id(),"checks":checks,"failures":failures,"fixture_kind":"PRESENTATION_CONTRACT_UNIT","authoritative_runtime":false,"doubles":["immutable cue DTO fixtures","test-only00 host Save bridge","existing legacy bus Settings sink; formal11 NOT_RUN"],"fault_exercises":["injected host write failure","deferred host acknowledgement","external programmatic slider mutation during deferred host acknowledgement"],"engine":Engine.get_version_info(),"display":DisplayServer.get_name(),"input":"Control interaction signals; actual storage and bus queries","human_acceptance":"NOT_RUN","formal_runtime":"PENDING_01","formal_audio":"PENDING_11","save_path":save_path,"user_data_dir":OS.get_user_data_dir()}
	DirAccess.make_dir_recursive_absolute(evidence)
	var file := FileAccess.open(evidence.path_join("report.json"),FileAccess.WRITE)
	file.store_string(JSON.stringify(report,"\t")); file.close()
	if is_instance_valid(ui): ui.queue_free()
	await settle()
	print(JSON.stringify(report))
	quit(0 if failures.is_empty() else 1)
