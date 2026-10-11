extends SceneTree
## Companion metadata only, restricted to this Owner's scripts.
func _initialize() -> void:
	var root := "res://tests/beta_sprint/spatial_quality"
	for file in DirAccess.get_files_at(root):
		if file.ends_with(".gd") and not FileAccess.file_exists(root.path_join(file + ".uid")):
			FileAccess.open(root.path_join(file + ".uid"),FileAccess.WRITE).store_string(ResourceUID.id_to_text(ResourceUID.create_id()) + "\n")
	quit()
