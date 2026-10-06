extends SceneTree
var checks := 0
var failures: Array[String] = []
var phase := "cold"
var path := "user://shell_tests/restart/progress.json"
var shell
const FIXTURES: Array[Dictionary] = [
	{"id": "a", "title": "Fixture A", "scene": "res://tests/shell/fixture_level.tscn", "adapter": "signal"},
	{"id": "b", "title": "Fixture B", "scene": "res://tests/shell/fixture_level.tscn", "adapter": "signal"}]

func _initialize() -> void:
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--phase="):
			phase = arg.trim_prefix("--phase=")
		elif arg.begins_with("--shell-save="):
			path = arg.trim_prefix("--shell-save=")
	call_deferred("run")

func check(ok: bool, label: String) -> void:
	checks += 1
	if not ok:
		failures.append(label)
		printerr("FAIL: ", label)

func run() -> void:
	var main: String = ProjectSettings.get_setting("application/run/main_scene")
	check(main == "res://game/shell/game_shell.tscn", "default project entry is Beta Shell")
	shell = load(main).instantiate()
	shell.save_path = path
	if phase != "cold":
		shell.catalog_entries = FIXTURES
	root.add_child(shell)
	await process_frame
	check(shell.state == shell.State.MAIN_MENU, "every process starts at Main Menu")
	match phase:
		"cold":
			check(not shell.progress.has_progress and shell.view.buttons["continue"].disabled, "isolated no-save startup works")
			shell.new_game()
			await process_frame
			check(shell.current_id == "p01" and shell.adapter.level.mover.cell == Vector2i(0, 5), "cold main entry launches actual P-01")
		"seed":
			shell.new_game()
			await process_frame
			shell.adapter.level.finish()
			shell.start_next_level()
			shell.pause_game()
			shell.open_settings()
			shell.preview_settings = {"master": 0.31, "music": 0.45, "sfx": 0.0, "fullscreen": true}
			shell.save_settings()
			check(shell.progress.recent == "b" and shell.progress.completed == ["a"] and not shell.dirty, "seed process saves latest level and completion")
		"restore":
			check(shell.progress.unlocked == ["a", "b"] and shell.progress.completed == ["a"] and shell.progress.recent == "b", "different process reopens exact progression")
			check(is_equal_approx(shell.progress.settings.master, 0.31) and is_equal_approx(shell.progress.settings.music, 0.45) and shell.progress.settings.sfx == 0.0 and shell.progress.settings.fullscreen, "different process restores all volume/display settings")
			check(AudioServer.is_bus_mute(AudioServer.get_bus_index("SFX")), "restored zero SFX applied to audio bus")
			if DisplayServer.get_name() != "headless":
				check(root.mode == Window.MODE_FULLSCREEN, "separate graphical process restores actual fullscreen mode")
			shell.continue_game()
			await process_frame
			check(shell.current_id == "b" and shell.state == shell.State.PLAYING, "different process Continue enters correct level")
			if DisplayServer.get_name() != "headless":
				check(root.mode == Window.MODE_FULLSCREEN, "fullscreen remains active after Continue")
	shell.queue_free()
	await create_timer(0.2).timeout
	print("SHELL RESTART ", phase, ": ", checks, " checks, failures=", failures)
	quit(0 if failures.is_empty() else 1)
