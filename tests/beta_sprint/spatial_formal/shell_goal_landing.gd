extends "res://tests/beta_sprint/spatial_formal/shell_lifecycle.gd"
## Actual Shell completion must let the final landing finish before suspending the level.
func run() -> void:
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--shell-save="): save_path = arg.trim_prefix("--shell-save=")
		elif arg.begins_with("--evidence-dir="): evidence = arg.trim_prefix("--evidence-dir=")
	phase = "landing_seam"
	check(save_path.begins_with("user://beta_sprint/spatial_formal/") and not evidence.is_empty(), "isolated seam save/evidence")
	if not failures.is_empty(): quit(1); return
	check(not FileAccess.file_exists(save_path), "fresh seam save")
	var catalog = load("res://game/shell/level_catalog.gd").new()
	shell = load("res://game/shell/game_feel_shell.tscn").instantiate()
	shell.save_path = save_path
	shell.catalog_entries.assign([catalog.find("spatial_orientation_loop_lab")])
	root.add_child(shell)
	shell.adapter.completed.connect(observe_completion)
	shell.new_game()
	await process_frame
	await settings_checks()
	await spatial_route()
	check(shell.state == shell.State.LEVEL_COMPLETE and completions.size() == 1 and completions[0].real_goal, "real final Goal reports one completion")
	check(shell.adapter.level.host.presenter.snapshot().phase == "IDLE", "Shell suspends final Goal only after natural landing settles")
	await finish()
