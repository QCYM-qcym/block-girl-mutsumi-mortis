extends SceneTree
var evidence := ""
var phase := "unit"
var checks := 0
var failures: Array[String] = []
var observations: Dictionary = {}
func _initialize() -> void:
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--evidence="): evidence=arg.trim_prefix("--evidence=")
		elif arg.begins_with("--phase="): phase=arg.trim_prefix("--phase=")
	call_deferred("run")
func check(ok: bool, label: String) -> void:
	checks+=1
	if not ok: failures.append(label)
func finish() -> void:
	FileAccess.open(evidence.path_join(phase+".json"),FileAccess.WRITE).store_string(JSON.stringify({"checks":checks,"failures":failures,"doubles":[],"pid":OS.get_process_id(),"display":DisplayServer.get_name(),"user_dir":OS.get_user_data_dir(),"scope":"Actual shared Shell/SaveStore/Audio/Runtime API; no Human result","observations":observations},"\t"))
	print("UI_HOST checks=",checks," failures=",failures)
	quit(0 if failures.is_empty() else 1)
func settle(seconds: float) -> void: await create_timer(seconds).timeout
func run() -> void:
	var shell: Node=load(ProjectSettings.get_setting("application/run/main_scene")).instantiate()
	root.add_child(shell)
	await settle(0.2)
	var bridge: Variant=null
	for property in shell.get_property_list():
		if property.name=="game_feel": bridge=shell.get("game_feel")
	check(bridge!=null,"actual Main has shared07/11 host bridge")
	if bridge==null:
		shell.queue_free();await process_frame;finish();return
	check(bridge.ui.get_script().resource_path=="res://game/feel/ui/game_feel_ui.gd","consumes exact07 production entry")
	check(bridge.audio.get_script().resource_path=="res://game/feel/audio/audio_director.gd","consumes exact11 production entry")
	if phase=="restore":
		check(is_equal_approx(shell.progress.settings.master,0.36),"separate process restores saved Master")
		check(shell.progress.settings.game_feel.reduced_motion,"separate process restores accessibility in same SaveStore")
		check(bridge.options.reduced_motion,"restored real presentation option")
		check(is_equal_approx(AudioServer.get_bus_volume_db(0),linear_to_db(0.36)),"cold real bus gain restored")
		check(shell.progress.has_progress and shell.progress.recent==shell.catalog.first_id(),"cold Continue retains actual recent level identity")
		shell.continue_game();await settle(0.2)
		check(shell.adapter.level!=null and shell.current_id==shell.catalog.first_id(),"cold Continue loads actual recent start")
	else:
		shell.open_settings();await process_frame
		check(bridge.ui.settings_open and shell.settings_open,"official Settings action opens07")
		var before: Dictionary=shell.progress.duplicate(true)
		bridge.ui.sliders.master.value=25
		check(is_equal_approx(AudioServer.get_bus_volume_db(0),linear_to_db(0.25)),"preview changes actual Master bus")
		check(shell.progress==before,"preview does not mutate stored progress")
		shell.cancel_settings();await process_frame
		check(not bridge.ui.settings_open and not shell.settings_open,"cancel closes both host and UI")
		check(is_equal_approx(AudioServer.get_bus_volume_db(0),linear_to_db(float(before.settings.master))),"cancel restores actual bus gain")
		shell.open_settings();await process_frame
		bridge.ui.sliders.master.value=36
		bridge.ui.sliders.music.value=44
		bridge.ui.sliders.sfx.value=52
		bridge.ui.buttons.muted.button_pressed=true
		check(AudioServer.is_bus_mute(0),"Mute affects actual AudioServer")
		bridge.ui.buttons.muted.button_pressed=false
		bridge.ui.buttons.reduced_motion.button_pressed=true
		bridge.ui.sliders.hint_strength.value=2
		bridge.extra_controls.contrast.button_pressed=true
		bridge.extra_controls.input_hints.button_pressed=false
		var original_path: String=shell.store.path
		var blocked: String="user://ui_host/not_a_directory"
		DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(blocked.get_base_dir()))
		var file=FileAccess.open(blocked,FileAccess.WRITE);file.store_string("fixture to produce real filesystem failure");file.close()
		shell.store.path=blocked+"/progress.json"
		shell.save_settings();await process_frame
		check(bridge.ui.settings_open and not bridge.ui.buttons.apply.disabled,"actual save failure remains retryable")
		check(shell.progress==before,"save failure preserves current progress")
		check(is_equal_approx(AudioServer.get_bus_volume_db(0),linear_to_db(float(before.settings.master))),"save failure rolls back actual bus")
		shell.store.path=original_path
		shell.save_settings();await process_frame
		check(not shell.settings_open and not bridge.ui.settings_open,"retry without editing closes after real save")
		check(is_equal_approx(shell.progress.settings.master,0.36),"retry stores draft")
		check(is_equal_approx(AudioServer.get_bus_volume_db(0),linear_to_db(0.36)),"retry reapplies draft after prior rollback")
		check(shell.progress.settings.game_feel.version==1 and shell.progress.settings.game_feel.reduced_motion,"explicit versioned accessibility saved in existing slot")
		check(shell.store.load_save()==JSON.parse_string(JSON.stringify(shell.progress)),"same actual SaveStore restores full wire payload")
		if phase=="seed":
			shell.new_game();await settle(0.2)
			check(shell.adapter.level!=null,"seed actual first level through ordinary New Game")
		else:
			bridge.launch_lab("a");await settle(0.2)
			var lab: Node=shell.adapter.level
			check(lab.runtime!=null and lab.presenter.snapshot().phase=="IDLE","real lab with formal Runtime and Presenter")
			check(lab.presenter.reduced_motion_enabled(),"saved Reduced Motion reaches actual10A config")
			var state: Dictionary=lab.runtime.get_state()
			lab.runtime.request_action({"kind":8,"connection_id":&"pfall_a"})
			check(bridge.ui.feedback_panel.visible and not bridge.ui.status_label.text.is_empty(),"real authorized Fall event displays actual07 status")
			check(lab.runtime.get_state()==state,"Fall feedback never commits authoritative state early")
			var counts: Dictionary=bridge.audio.snapshot().cue_counts
			check(int(counts.get("fall_start",0))==1,"actual AudioDirector consumes real Fall once")
			var captured: Dictionary=lab.events[-1].duplicate(true)
			bridge.forward_event(captured,lab.runtime,bridge.epoch)
			check(bridge.audio.snapshot().cue_counts==counts,"duplicate real event does not replay audio")
			await settle(1.8)
			check(lab.runtime.get_commit_count()==1 and not bridge.ui.feedback_panel.visible,"natural matching COMMITTED clears UI once")
			check(lab.runtime.get_state().player.location.cube_id==&"target","Reduced Motion leaves formal target unchanged")
			var Key=load("res://foundation/contracts/state_key.gd")
			var reduced_state: Dictionary=lab.runtime.get_state()
			var reduced_key: String=Key.build(lab.runtime.get_level(),reduced_state).key
			shell.open_settings();await process_frame
			bridge.ui.buttons.reduced_motion.button_pressed=false
			shell.save_settings();shell.resume_game();await process_frame
			lab.reset_level();await process_frame
			check(not bridge.ui.feedback_panel.visible and lab.runtime.get_commit_count()==0,"actual Reset clears matching HUD and Runtime")
			check(not lab.presenter.reduced_motion_enabled(),"saved Normal motion reaches formal Presenter")
			lab.runtime.request_action({"kind":8,"connection_id":&"pfall_a"})
			await settle(1.8)
			check(Key.build(lab.runtime.get_level(),lab.runtime.get_state()).key==reduced_key,"real Normal and Reduced Motion target StateKey parity")
			check(lab.runtime.get_state().player.orientation==reduced_state.player.orientation,"real Normal and Reduced Motion authoritative orientation parity")
			var old_runtime: Object=lab.runtime
			var old_epoch: int=bridge.epoch
			bridge.launch_lab("b");await settle(0.2)
			bridge.forward_event(captured,old_runtime,old_epoch)
			check(not bridge.ui.feedback_panel.visible,"old runtime callback cannot affect new scene")
			lab=shell.adapter.level
			lab.runtime.request_action({"kind":8,"connection_id":&"pfall_b"})
			check(bridge.ui.feedback_panel.visible,"real second-map Fall enters active HUD")
			var interrupted_start: Dictionary=lab.events[-1].duplicate(true)
			lab.reset_level();await process_frame
			check(not bridge.ui.feedback_panel.visible and bridge.ui.status_label.text.is_empty(),"in-flight native Reset closes captured Fall HUD")
			check(not "fall_start" in bridge.audio.snapshot().playing and not "fall_whoosh" in bridge.audio.snapshot().playing,"in-flight native Reset cancels captured Fall audio")
			bridge.forward_event(interrupted_start,lab.runtime,bridge.epoch)
			check(not bridge.ui.feedback_panel.visible,"old-generation STARTED cannot reopen HUD")
			shell.show_main_menu();await settle(0.2)
			check(shell.adapter.level==null and bridge.audio.snapshot().context=="menu","return uses official Main Menu and set_music API")
			check(shell.progress.recent==before.recent and shell.progress.completed==before.completed,"experimental route never writes fake progress")
	observations={"audio":bridge.audio.snapshot(),"settings":shell.progress.settings.duplicate(true),"state":shell.state,"runtime_readiness":"PENDING_RUNTIME_INTERFACE"}
	shell.queue_free();await settle(0.2);finish()
