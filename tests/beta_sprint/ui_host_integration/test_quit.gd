extends "res://tests/beta_sprint/ui_host_integration/test_host.gd"
func run() -> void:
	var shell: Node=load(ProjectSettings.get_setting("application/run/main_scene")).instantiate()
	root.add_child(shell);await settle(0.2)
	var bridge=shell.game_feel
	if phase=="seed":
		shell.new_game();await settle(0.2)
		var saved: Dictionary=shell.progress.settings.duplicate(true)
		shell.open_settings();await process_frame
		bridge.ui.sliders.master.value=19
		bridge.ui.buttons.reduced_motion.button_pressed=true
		check(not is_equal_approx(AudioServer.get_bus_volume_db(0),0),"actual unsaved preview before quit")
		# Return from this awaited test coroutine before the actual SceneTree quit.
		_quit_case.call_deferred(shell,saved)
		return
	else:
		check(is_equal_approx(shell.progress.settings.master,1) and not bridge.options.reduced_motion,"new OS process after Quit restores saved options")
		shell.continue_game();await settle(0.2)
		check(shell.current_id==shell.catalog.first_id() and shell.adapter.level!=null,"Quit retains real cold Continue")
	observations={"actual_quit":phase=="seed","settings":shell.progress.settings,"process_id":OS.get_process_id()}
	shell.queue_free();await settle(0.2)
	finish()
func _quit_case(shell: Node,saved: Dictionary) -> void:
	var bridge=shell.game_feel
	shell.request_quit()
	check(not shell.settings_open and not bridge.ui.settings_open,"real Quit cancels open settings")
	check(shell.progress.settings==saved and is_equal_approx(AudioServer.get_bus_volume_db(0),0),"real Quit restores saved settings and audio")
	check(shell.store.load_save().settings==JSON.parse_string(JSON.stringify(saved)),"real Quit never persists unsaved draft")
	observations={"actual_quit":true,"settings":shell.progress.settings,"process_id":OS.get_process_id()}
	finish()
