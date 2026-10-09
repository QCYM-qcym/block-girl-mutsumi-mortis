extends "res://tests/beta_sprint/ui_host_integration/test_host.gd"

func native_key(code: int, pressed: bool) -> void:
	var event:=InputEventKey.new()
	event.keycode=code;event.physical_keycode=code;event.pressed=pressed
	Input.parse_input_event(event)

func run() -> void:
	var shell: Node=load(ProjectSettings.get_setting("application/run/main_scene")).instantiate()
	root.add_child(shell);await settle(0.2)
	shell.new_game();await settle(0.5)
	var level: Node=shell.adapter.level
	var audio: Node=shell.game_feel.audio
	check(audio.snapshot().context=="exploration" and audio.snapshot().target_world==0,"11 Surface music consumes actual legacy World")
	native_key(KEY_SPACE,true);await process_frame;native_key(KEY_SPACE,false)
	await settle(1.5)
	check(level.mover.world==1,"native World Shift actually commits to Inner")
	check(audio.snapshot().target_world==1 and audio.snapshot().world_blend>0.99,"11 Inner BGM follows actual committed world")
	check(audio.snapshot().cue_counts.get("world_shift",0)==1,"11 World Shift cue from actual accepted native signal")
	shell.show_main_menu();await settle(0.2)
	observations={"audio":audio.snapshot()}
	shell.queue_free();await settle(0.2);finish()
