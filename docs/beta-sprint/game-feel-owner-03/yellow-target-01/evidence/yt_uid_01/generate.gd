extends SceneTree
func _initialize() -> void:
	FileAccess.open("res://tests/beta_sprint/game_feel_owner_03/yellow_target_gate.gd.uid", FileAccess.WRITE).store_string(ResourceUID.id_to_text(ResourceUID.create_id()) + "\n")
	FileAccess.open("res://tests/beta_sprint/game_feel_owner_03/test_yellow_target_dependencies.gd.uid", FileAccess.WRITE).store_string(ResourceUID.id_to_text(ResourceUID.create_id()) + "\n")
	FileAccess.open("res://tests/beta_sprint/game_feel_owner_03/test_yellow_target_core.gd.uid", FileAccess.WRITE).store_string(ResourceUID.id_to_text(ResourceUID.create_id()) + "\n")
	FileAccess.open("res://tests/beta_sprint/game_feel_owner_03/test_yellow_target_graphical.gd.uid", FileAccess.WRITE).store_string(ResourceUID.id_to_text(ResourceUID.create_id()) + "\n")
	FileAccess.open("res://tests/beta_sprint/game_feel_owner_03/test_yellow_target_lifecycle.gd.uid", FileAccess.WRITE).store_string(ResourceUID.id_to_text(ResourceUID.create_id()) + "\n")
	FileAccess.open("res://tests/beta_sprint/game_feel_owner_03/test_yellow_target_input.gd.uid", FileAccess.WRITE).store_string(ResourceUID.id_to_text(ResourceUID.create_id()) + "\n")
	quit(0)
