extends SceneTree
func _initialize() -> void:
	FileAccess.open("res://tests/beta_sprint/game_feel_owner_03/test_forward_drop_measurements.gd.uid", FileAccess.WRITE).store_string(ResourceUID.id_to_text(ResourceUID.create_id()) + "\n")
	quit(0)
