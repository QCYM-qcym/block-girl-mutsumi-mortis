extends SceneTree
var shell
var checks := 0
var failures: Array[String] = []
var path := "user://shell_tests/mute_" + str(Time.get_ticks_usec()) + "/progress.json"

func _initialize() -> void:
	call_deferred("run")

func check(ok: bool, label: String) -> void:
	checks += 1
	if not ok:
		failures.append(label)
		printerr("FAIL: ", label)

func boot() -> void:
	shell = load("res://game/shell/game_shell.tscn").instantiate()
	shell.save_path = path
	root.add_child(shell)
	await process_frame

func tap_m() -> void:
	for pressed in [true, false]:
		var event := InputEventKey.new()
		event.keycode = KEY_M
		event.physical_keycode = KEY_M
		event.pressed = pressed
		Input.parse_input_event(event)
		await process_frame

func run() -> void:
	await boot()
	shell.open_settings()
	shell.preview_settings.master = 0.4
	shell.save_settings()
	shell.new_game()
	await tap_m()
	check(AudioServer.is_bus_mute(0), "M mutes actual audio bus")
	check(is_equal_approx(shell.progress.settings.master, 0.4), "mute preserves chosen gain")
	shell.queue_free()
	await create_timer(0.15).timeout
	await boot()
	check(AudioServer.is_bus_mute(0), "mute survives saved Shell restart")
	shell.continue_game()
	await tap_m()
	check(not AudioServer.is_bus_mute(0) and is_equal_approx(shell.progress.settings.master, 0.4), "unmute after restart restores chosen 40 percent")
	shell.queue_free()
	await create_timer(0.15).timeout
	print("SHELL MUTE RESTART: ", checks, " checks, failures=", failures)
	quit(0 if failures.is_empty() else 1)
