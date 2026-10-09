extends "res://tests/beta_sprint/ui_host_integration/test_host.gd"
var requested:=Vector2i(1280,720)
var captures: Array=[]
var native_inputs: Array=[]
func _initialize() -> void:
	super._initialize()
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--size="):
			var parts=arg.trim_prefix("--size=").split("x")
			requested=Vector2i(int(parts[0]),int(parts[1]))
func key(code: int) -> void:
	for pressed in [true,false]:
		var event:=InputEventKey.new();event.keycode=code;event.physical_keycode=code;event.pressed=pressed
		Input.parse_input_event(event);native_inputs.append({"key":code,"pressed":pressed})
		await process_frame
func click(control: Control) -> void:
	check(control.is_visible_in_tree(),"actual control visible before native click")
	var at:=control.get_global_rect().get_center()
	for pressed in [true,false]:
		var event:=InputEventMouseButton.new();event.position=at;event.button_index=MOUSE_BUTTON_LEFT;event.pressed=pressed
		Input.parse_input_event(event);native_inputs.append({"mouse": [at.x,at.y],"pressed":pressed})
		await process_frame
	await settle(0.15)
func capture(label: String) -> void:
	await RenderingServer.frame_post_draw
	var image:=root.get_texture().get_image()
	check(image.get_size()==requested,"actual rendered PNG dimensions "+label)
	var path:=evidence.path_join(label+".png");check(image.save_png(path)==OK,"real viewport capture "+label)
	captures.append({"path":path,"size":[image.get_width(),image.get_height()]})
func cube_rect(lab: Node) -> Rect2:
	var first:=true;var result:=Rect2()
	for x in [-0.5,0.5]:
		for y in [-0.5,0.5]:
			for z in [-0.5,0.5]:
				var point: Vector2=lab.camera.unproject_position(lab.actor.global_transform*Vector3(x,y,z))
				result=Rect2(point,Vector2.ZERO) if first else result.expand(point);first=false
	return result
func run() -> void:
	check(DisplayServer.get_name()!="headless","real Windows graphical renderer")
	var shell: Node=load(ProjectSettings.get_setting("application/run/main_scene")).instantiate();root.add_child(shell)
	await settle(0.5)
	root.mode=Window.MODE_WINDOWED;root.size=requested
	await settle(0.5)
	check(root.size==requested and root.get_visible_rect().size==Vector2(requested),"actual requested viewport")
	var bridge=shell.game_feel
	check(bridge!=null,"actual shared host in delivered Build")
	await capture("01_main")
	await click(shell.view.buttons.settings)
	check(bridge.ui.settings_open,"native official Settings click reaches07")
	if not bridge.ui.settings_open:
		observations={"shell_state":shell.state,"settings_button":str(shell.view.buttons.settings.get_global_rect()),"ui_layer":bridge.ui.layer,"ui_visible":bridge.ui.visible,"entry_visible":bridge.lab_entry.visible,"entry_rect":str(bridge.lab_entry.get_global_rect()),"entry_modulate":str(bridge.lab_entry.modulate),"native_inputs":native_inputs}
		await capture("failed_settings")
		shell.queue_free();await settle(0.2);finish();return
	check(Rect2(Vector2.ZERO,Vector2(requested)).encloses(bridge.ui.settings_panel.get_global_rect()),"Settings panel inside actual viewport")
	check(get_root().gui_get_focus_owner()==bridge.ui.sliders.master,"settings starts with real keyboard focus")
	var initial: Dictionary=shell.progress.settings.duplicate(true)
	var original_gain:=AudioServer.get_bus_volume_db(0)
	await key(KEY_LEFT);await key(KEY_LEFT)
	check(AudioServer.get_bus_volume_db(0)<original_gain,"native keyboard preview changes actual Master gain")
	await key(KEY_TAB)
	check(root.gui_get_focus_owner()==bridge.ui.sliders.music,"native Tab reaches Music")
	var music_gain:=AudioServer.get_bus_volume_db(AudioServer.get_bus_index("Ambience"))
	await key(KEY_LEFT)
	check(AudioServer.get_bus_volume_db(AudioServer.get_bus_index("Ambience"))<music_gain,"native music slider actual Ambience bus")
	await key(KEY_TAB)
	var sfx_gain:=AudioServer.get_bus_volume_db(AudioServer.get_bus_index("SFX"))
	await key(KEY_LEFT)
	check(AudioServer.get_bus_volume_db(AudioServer.get_bus_index("SFX"))<sfx_gain,"native SFX slider actual bus")
	await capture("02_settings_preview")
	await click(shell.view.buttons.new)
	check(shell.state==shell.State.MAIN_MENU and shell.settings_open and bridge.ui.settings_open,"native underlying New Game is blocked by actual modal Settings")
	bridge.ui.sliders.sfx.grab_focus()
	await key(KEY_ESCAPE);await settle(0.15)
	check(not bridge.ui.settings_open and shell.progress.settings==initial,"native cancel keeps saved values")
	check(is_equal_approx(AudioServer.get_bus_volume_db(0),original_gain),"native cancel restores live audio")
	await click(shell.view.buttons.settings)
	for index in 4: await key(KEY_TAB)
	check(root.gui_get_focus_owner()==bridge.ui.buttons.muted,"real focus traverses to Mute")
	await key(KEY_SPACE)
	check(AudioServer.is_bus_mute(0),"native Mute toggles real bus")
	await key(KEY_SPACE)
	for index in 2: await key(KEY_TAB)
	check(root.gui_get_focus_owner()==bridge.ui.buttons.reduced_motion,"real focus reaches Reduced Motion")
	await key(KEY_SPACE)
	check(bridge.ui.buttons.reduced_motion.button_pressed,"native checkbox changes real draft")
	await key(KEY_TAB);await key(KEY_SPACE)
	check(bridge.extra_controls.contrast.button_pressed,"native contrast control changes real draft")
	await key(KEY_TAB);await key(KEY_SPACE)
	check(not bridge.extra_controls.input_hints.button_pressed,"native keyboard/mouse hint control changes real draft")
	await key(KEY_TAB)
	check(root.gui_get_focus_owner()==bridge.ui.buttons.apply,"keyboard focus includes extra accessibility controls")
	await capture("03_settings_accessibility")
	await click(bridge.ui.buttons.apply)
	check(not shell.settings_open and shell.progress.settings.game_feel.reduced_motion,"native Apply writes real shared SaveStore")
	check(shell.progress.settings.game_feel.contrast and not shell.progress.settings.game_feel.input_hints,"same store persists Contrast and input hints")
	await click(bridge.lab_entry)
	var lab: Node=shell.adapter.level
	check(lab!=null and lab.runtime.is_loaded(),"native experiment entry starts formal Runtime")
	if lab==null:
		observations={"shell_state":shell.state,"settings_open":bridge.ui.settings_open,"entry_visible":bridge.lab_entry.visible,"entry_rect":str(bridge.lab_entry.get_global_rect()),"panel_rect":str(bridge.ui.settings_panel.get_global_rect()),"panel_min":str(bridge.ui.settings_panel.get_combined_minimum_size()),"ui_root_rect":str(bridge.ui._root.get_global_rect()),"layer_visible":bridge.ui.visible,"layer_transform":str(bridge.ui.transform),"viewport_rect":str(root.get_visible_rect()),"focus_rect":str(root.gui_get_focus_owner().get_global_rect()),"native_inputs":native_inputs}
		shell.queue_free();await settle(0.2);finish();return
	check(lab.presenter.reduced_motion_enabled(),"real10A receives saved reduced motion")
	await key(KEY_F)
	check(bridge.ui.feedback_panel.visible and not bridge.ui.status_label.text.is_empty(),"actual Fall STARTED drives HUD")
	check(not bridge.ui.input_label.visible,"saved hint setting controls actual HUD hints")
	check(not cube_rect(lab).intersects(bridge.ui.feedback_panel.get_global_rect()),"Fall HUD does not cover projected cube")
	await capture("04_fall_hud")
	await key(KEY_ESCAPE)
	check(shell.state==shell.State.PAUSED and lab.runtime.is_paused(),"native Pause freezes actual host Runtime")
	var paused_pose: Transform3D=lab.actor.transform
	await settle(0.2)
	check(lab.actor.transform.is_equal_approx(paused_pose) and lab.runtime.get_commit_count()==0,"paused motion and native commit remain frozen")
	check(not bridge.ui.feedback_panel.visible,"HUD hidden beneath official Pause overlay")
	await capture("05_pause")
	await key(KEY_ESCAPE);await settle(1.6)
	check(lab.runtime.get_commit_count()==1 and not bridge.ui.feedback_panel.visible,"native Resume completes same Fall and clears HUD")
	check(lab.runtime.get_state().player.location.cube_id==&"target","Reduced Motion official target parity")
	check(int(bridge.audio.snapshot().cue_counts.get("landing_impact",0))==1,"natural COMMITTED plays one actual landing cue")
	await key(KEY_D);await settle(0.5)
	check(lab.runtime.get_state().player.location.cube_id==&"exit","native post-landing ordinary Roll retained")
	await capture("06_landed_goal")
	await key(KEY_ESCAPE)
	await click(shell.view.buttons.main)
	check(shell.state==shell.State.MAIN_MENU and shell.adapter.level==null,"native return to official Main Menu")
	await click(shell.view.buttons.new)
	check(shell.adapter.level!=null and shell.current_id==shell.catalog.first_id(),"native New Game starts existing real first3D level")
	await key(KEY_ESCAPE)
	check(shell.state==shell.State.PAUSED,"legacy native Pause retained")
	await click(shell.view.buttons.settings)
	check(bridge.ui.settings_open,"legacy Pause Settings reaches shared UI")
	await click(shell.view.buttons.reset)
	check(shell.state==shell.State.PAUSED and shell.settings_open,"native underlying Reset cannot resume gameplay beneath Settings")
	await capture("07_legacy_settings")
	await key(KEY_ESCAPE)
	await click(shell.view.buttons.main)
	check(shell.progress.has_progress and shell.progress.recent==shell.catalog.first_id(),"actual recent progress recorded through normal flow")
	await click(shell.view.buttons.continue)
	check(shell.current_id==shell.catalog.first_id() and shell.adapter.level!=null,"native Continue loads unchanged real recent level start")
	await key(KEY_ESCAPE);await click(shell.view.buttons.main)
	await click(shell.view.buttons.select)
	check(shell.state==shell.State.LEVEL_SELECT,"native Level Select retained")
	await capture("08_select")
	await key(KEY_ESCAPE)
	observations={"captures":captures,"native_inputs":native_inputs,"actual_viewport":[root.size.x,root.size.y],"renderer":RenderingServer.get_current_rendering_method(),"settings":shell.progress.settings,"audio":bridge.audio.snapshot(),"runtime_readiness":"PENDING_RUNTIME_INTERFACE","Human_QA":"NOT_RUN"}
	shell.queue_free();await settle(0.2);finish()
