extends "res://tests/beta_sprint/spatial_owner_07/test_menu.gd"
## A new process, same isolated profile, actual Menu/Continue and actual Host.
func run() -> void:
	case_scope = "cold process reload of actual menu_progress.json produced by the prior actual Host Goal"
	input_scope = "native Input.parse_input_event mouse/Tab/Enter; no witness or injected Goal in this process"
	check(DisplayServer.get_name()=="headless" and save_path.begins_with("user://spatial_puzzle_batch_01/tests/") and ".." not in save_path, "fresh isolated cold menu process")
	check(ResourceLoader.exists(MAIN) and FileAccess.file_exists(save_path), "prior actual Menu progress exists")
	if not failures.is_empty():
		await finish();return
	var Factory: Script=load(FACTORY)
	var disk: Dictionary=Store.new(save_path,"world_shift_gate_lab").load_save()
	var bytes:=FileAccess.get_file_as_bytes(save_path)
	check(disk.recent=="orientation_loop_lab" and disk.completed==["orientation_loop_lab"], "cold disk restores actual prior Host Goal and recent lab")
	root.content_scale_size=Vector2i.ZERO
	root.content_scale_mode=Window.CONTENT_SCALE_MODE_DISABLED
	root.size=Vector2i(960,720)
	ui=load(MAIN).instantiate()
	ui.save_path=save_path
	root.add_child(ui)
	await settle()
	check(ui.lab==null and not ui.continue_button.disabled and ui.continue_button.has_focus(), "cold Menu exposes focused Continue without starting gameplay")
	check(ui.progress.snapshot()==disk and FileAccess.get_file_as_bytes(save_path)==bytes, "cold Menu restores original SaveStore data without a boot write")
	check(not FileAccess.file_exists(Store.DEFAULT_PATH), "cold Menu leaves legacy slot absent")
	await key(KEY_ENTER)
	check(is_instance_valid(ui.lab) and ui.lab.runtime.is_loaded() and ui.lab.lab_id==&"orientation_loop_lab", "cold keyboard Continue starts actual recent Host")
	if not is_instance_valid(ui.lab):
		await finish();return
	check(ui.lab.runtime.get_commit_count()==0 and ui.lab.runtime.get_state().player==Factory.bake(&"orientation_loop_lab").level.spawn, "cold Continue restores formal spawn with zero commits")
	check(not ui.goal_seen and ui.progress.snapshot().completed==disk.completed, "cold Continue cannot manufacture or duplicate Goal")
	await click(ui.return_button)
	check(ui.lab==null and ui.menu_panel.visible and ui.progress.snapshot().completed==disk.completed, "cold Continue returns through actual Shell flow")
	check(not FileAccess.file_exists(Store.DEFAULT_PATH), "legacy save remains untouched after cold lifecycle")
	await finish()
