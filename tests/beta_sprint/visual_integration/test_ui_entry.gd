extends SceneTree
var checks := 0
var failures: Array[String] = []
func _initialize() -> void: call_deferred("run")
func check(value: bool, label: String) -> void:
	checks += 1
	if not value: failures.append(label)
func run() -> void:
	var evidence := OS.get_environment("VISUAL_UI_EVIDENCE")
	if evidence.is_empty(): quit(2); return
	DirAccess.make_dir_recursive_absolute(evidence)
	var shell = load("res://game/shell/game_shell.tscn").instantiate()
	root.add_child(shell)
	await process_frame
	await process_frame
	check(shell.state == shell.State.MAIN_MENU, "existing Shell state remains Main Menu")
	check(shell.view.buttons.has("new") and shell.view.buttons.has("continue"), "existing actions retain public button IDs")
	check(not shell.view.buttons["new"].disabled and shell.view.buttons["continue"].disabled, "actual no-save availability remains unchanged")
	check(shell.view.get_script().resource_path == "res://game/shell/visual_01/approved_shell_view.gd", "main-project Shell consumes the approved UI implementation")
	check(shell.view.buttons["new"].get_theme_color("font_color").is_equal_approx(Color("162333")), "frozen token ink replaces the previous pale-on-dark menu")
	check(root.content_scale_mode == Window.CONTENT_SCALE_MODE_DISABLED, "approved Shell uses native Window pixels for readable 720-height text")
	check(root.get_visible_rect().size.is_equal_approx(Vector2(root.size)), "approved Shell logical viewport matches the actual Window dimensions")
	root.remove_child(shell)
	shell.free()
	shell = null
	await create_timer(0.12).timeout
	var file := FileAccess.open(evidence.path_join("report.json"),FileAccess.WRITE)
	file.store_string(JSON.stringify({"checks":checks,"failures":failures,"pid":OS.get_process_id(),"project":ProjectSettings.globalize_path("res://"),"window_size":str(root.size),"viewport_rect":str(root.get_visible_rect()),"content_scale_mode":root.content_scale_mode,"content_scale_size":str(root.content_scale_size),"final_transform":str(root.get_final_transform())},"\t"))
	file.close()
	print("VISUAL UI ENTRY: ",checks," checks; failures=",failures)
	quit(0 if failures.is_empty() else 1)
