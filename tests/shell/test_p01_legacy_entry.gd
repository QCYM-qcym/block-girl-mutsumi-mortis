extends "res://tests/gameplay/test_p01_runtime.gd"
## Run unchanged legacy gameplay assertions in their original direct-level context.
## The real project entry is separately checked by test_restart.gd.
func _initialize() -> void:
	ProjectSettings.set_setting("application/run/main_scene", "res://game/levels/mutsumi/p01_another_world.tscn")
	super._initialize()
