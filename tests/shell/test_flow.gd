extends SceneTree
var checks := 0
var failures: Array[String] = []
var shell
var path := "user://shell_tests/flow_" + str(Time.get_ticks_usec()) + "/progress.json"
const FIXTURES: Array[Dictionary] = [
	{"id": "a", "title": "Fixture A", "scene": "res://tests/shell/fixture_level.tscn", "adapter": "signal"},
	{"id": "b", "title": "Fixture B", "scene": "res://tests/shell/fixture_level.tscn", "adapter": "signal"}]

func _initialize() -> void:
	if not ResourceLoader.exists("res://game/shell/game_shell.tscn"):
		printerr("FAIL: Beta Shell flow scene is missing")
		quit(1)
		return
	call_deferred("run")

func check(ok: bool, label: String) -> void:
	checks += 1
	if not ok:
		failures.append(label)
		printerr("FAIL: ", label)

func make_shell() -> void:
	shell = load("res://game/shell/game_shell.tscn").instantiate()
	shell.save_path = path
	shell.catalog_entries = FIXTURES
	root.add_child(shell)
	await process_frame

func run() -> void:
	await make_shell()
	check(shell.state == shell.State.MAIN_MENU and shell.view.buttons["continue"].disabled, "cold menu hides Continue without progress")
	shell.start_level("b")
	check(shell.state == shell.State.MAIN_MENU and shell.adapter.level == null, "locked level cannot be entered")
	shell.start_level("unknown")
	check(shell.adapter.level == null, "unregistered scene rejected")
	shell.new_game()
	await process_frame
	check(shell.state == shell.State.PLAYING and shell.current_id == "a", "New Game enters first authored level")
	shell.pause_game()
	var tick: int = shell.adapter.level.ticks
	var event := InputEventKey.new()
	event.keycode = KEY_W
	event.pressed = true
	Input.parse_input_event(event)
	await process_frame
	await process_frame
	check(shell.adapter.level.ticks == tick and shell.adapter.level.inputs == 0, "Pause freezes ticks and gameplay input")
	shell.open_settings()
	shell.preview_settings.master = 0.25
	shell.preview_settings.music = 0.0
	shell.save_settings()
	check(shell.state == shell.State.PAUSED and shell.view.screen == "pause", "settings returns to paused menu")
	check(AudioServer.is_bus_mute(AudioServer.get_bus_index("Ambience")), "zero Music mutes real Ambience bus")
	shell.open_settings()
	shell.preview_settings.master = 0.9
	shell.cancel_settings()
	check(is_equal_approx(shell.progress.settings.master, 0.25), "Cancel keeps previously saved volume")
	shell.reset_current()
	await process_frame
	check(shell.state == shell.State.PLAYING and shell.adapter.level.resets == 1, "Pause Reset calls level's reset and resumes")
	shell.adapter.level.finish()
	await process_frame
	check(shell.state == shell.State.LEVEL_COMPLETE and shell.progress.completed == ["a"] and shell.progress.unlocked == ["a", "b"], "completion records clear and unlocks next level")
	shell.start_next_level()
	await process_frame
	check(shell.current_id == "b" and shell.state == shell.State.PLAYING, "Next actually enters unlocked second fixture")
	shell.adapter.level.finish()
	await process_frame
	check(shell.view.buttons["next"].disabled and shell.progress.completed == ["a", "b"], "last level has safe end-of-catalog navigation")
	shell.show_level_select()
	check(shell.state == shell.State.LEVEL_SELECT and not shell.view.buttons["level:b"].disabled, "unlocked completed level is selectable")
	shell.show_main_menu()
	shell.request_new_game()
	check(shell.view.screen == "confirm_new", "existing progress requires explicit New Game confirmation")
	shell.cancel_new_game()
	check(shell.progress.completed == ["a", "b"] and shell.view.screen == "main", "cancel New Game preserves progress")
	shell.queue_free()
	await process_frame
	await make_shell()
	check(shell.progress.recent == "b" and shell.progress.completed == ["a", "b"], "fresh Shell reloads exact completed progress")
	check(is_equal_approx(shell.progress.settings.master, 0.25) and shell.progress.settings.music == 0, "fresh Shell reloads settings")
	shell.continue_game()
	await process_frame
	check(shell.current_id == "b" and shell.state == shell.State.PLAYING, "Continue resumes correct unlocked recent level")
	shell.pause_game()
	shell.show_level_select()
	shell.open_settings()
	shell.cancel_settings()
	check(shell.state == shell.State.LEVEL_SELECT and shell.view.screen == "select", "select/settings/back has no dead end")
	shell.new_game()
	await process_frame
	check(shell.progress.unlocked == ["a"] and shell.progress.completed.is_empty() and is_equal_approx(shell.progress.settings.master, 0.25), "confirmed New Game resets progression but preserves settings")
	shell.queue_free()
	await process_frame
	print("SHELL FLOW: ", checks, " checks, failures=", failures)
	quit(0 if failures.is_empty() else 1)
