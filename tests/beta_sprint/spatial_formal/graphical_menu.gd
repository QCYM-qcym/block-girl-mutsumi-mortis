extends "res://tests/beta_sprint/spatial_formal/graphical.gd"
## Read-only copy of a naturally earned test save. Not new unlock evidence.
func run() -> void:
	var earned := ""
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--earned-save="): earned = arg.trim_prefix("--earned-save=")
		elif arg.begins_with("--evidence-dir="): evidence = arg.trim_prefix("--evidence-dir=")
		elif arg.begins_with("--shell-save="): save_path = arg.trim_prefix("--shell-save=")
	check(FileAccess.file_exists(earned) and save_path.begins_with("user://beta_sprint/spatial_formal/"), "explicit earned save and isolated destination")
	if not failures.is_empty(): quit(1); return
	check(not FileAccess.file_exists(save_path), "fresh isolated profile")
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(save_path).get_base_dir())
	check(DirAccess.copy_absolute(earned, ProjectSettings.globalize_path(save_path)) == OK, "copy existing earned save without alteration")
	check(FileAccess.get_sha256(earned) == FileAccess.get_sha256(save_path), "earned save copy is byte-identical")
	for id in Factory.ids(): expected.append("spatial_" + str(id))
	shell = load("res://game/shell/game_feel_shell.tscn").instantiate()
	shell.save_path = save_path
	root.add_child(shell)
	await process_frame
	check(shell.progress.completed == expected, "source is actual completed ten-level test save")
	await menu_capacity()
	shell.start_level(expected[5])
	await process_frame
	var level = shell.adapter.level
	check(RenderingServer.get_default_clear_color() == load("res://game/shell/visual_01/tokens.gd").COLORS.water, "direct spatial entry restores approved readable backdrop")
	level.apply_accessibility({"input_hints":true,"contrast":false,"hint_strength":1})
	for size in [Vector2i(1920,1080),Vector2i(1280,720),Vector2i(960,720)]:
		root.size = size
		for frame in 6: await process_frame
		check(level.hud.footer.visible and root.get_visible_rect().encloses(level.hud.footer.get_global_rect()), "visible controls fit actual viewport")
		await shot("default_hud_%dx%d" % [size.x,size.y])
	var report := {"checks":checks,"failures":failures,"display":DisplayServer.get_name(),"captures":captures,"human_qa":"NOT_RUN","save_fixture":"byte-identical isolated copy of naturally earned run03 save; no new progression claim","source_save_sha256":FileAccess.get_sha256(earned)}
	FileAccess.open(evidence.path_join("menu_report.json"),FileAccess.WRITE).store_string(JSON.stringify(report,"\t"))
	print(JSON.stringify(report))
	if failures.is_empty(): shell.call_deferred("request_quit")
	else: quit(1)
