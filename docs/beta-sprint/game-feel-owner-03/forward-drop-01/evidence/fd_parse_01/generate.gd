extends SceneTree
func _initialize() -> void:
	FileAccess.open("res://tests/beta_sprint/game_feel_owner_03/forward_drop_observations.gd.uid",FileAccess.WRITE).store_string(ResourceUID.id_to_text(ResourceUID.create_id()) + "\n")
	FileAccess.open("res://tests/beta_sprint/game_feel_owner_03/test_forward_drop_sampler.gd.uid",FileAccess.WRITE).store_string(ResourceUID.id_to_text(ResourceUID.create_id()) + "\n")
	FileAccess.open("res://tests/beta_sprint/game_feel_owner_03/test_forward_drop_graphical.gd.uid",FileAccess.WRITE).store_string(ResourceUID.id_to_text(ResourceUID.create_id()) + "\n")
	quit(0)
