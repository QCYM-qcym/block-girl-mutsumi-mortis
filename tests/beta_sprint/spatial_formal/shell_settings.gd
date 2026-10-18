extends "res://tests/beta_sprint/spatial_formal/shell_lifecycle.gd"
## Narrow RED/GREEN seam check using real first spatial scene with an injected one-entry catalog.
## No claimed natural unlock evidence here; shell_lifecycle covers the real ten-entry progression.
func run() -> void:
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--shell-save="): save_path = arg.trim_prefix("--shell-save=")
		elif arg.begins_with("--evidence-dir="): evidence = arg.trim_prefix("--evidence-dir=")
	phase = "settings_seam"
	check(save_path.begins_with("user://beta_sprint/spatial_formal/") and not evidence.is_empty(), "isolated seam save/evidence")
	if not failures.is_empty(): quit(1); return
	check(not FileAccess.file_exists(save_path), "fresh seam save")
	var catalog = load("res://game/shell/level_catalog.gd").new()
	shell = load("res://game/shell/game_feel_shell.tscn").instantiate()
	shell.save_path = save_path
	shell.catalog_entries.assign([catalog.find("spatial_world_shift_gate_lab")])
	root.add_child(shell)
	shell.new_game()
	await process_frame
	await settings_checks()
	await finish()
