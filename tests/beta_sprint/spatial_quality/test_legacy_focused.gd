extends "res://tests/beta_sprint/game_feel_owner_03/test_v2_legacy_focused.gd"
## The new isolated experiment owns main_scene. The frozen five-level recipe
## consumes the actual legacy Shell explicitly, in this process only.
func run() -> void:
	ProjectSettings.set_setting("application/run/main_scene", "res://game/shell/game_shell.tscn")
	await super.run()
