extends SceneTree
func _initialize() -> void:
	var directory := "res://tests/beta_sprint/spatial_quality/polish_03"
	for file in DirAccess.get_files_at(directory):
		if file.ends_with(".gd") and not FileAccess.file_exists(directory.path_join(file+".uid")):
			FileAccess.open(directory.path_join(file+".uid"),FileAccess.WRITE).store_string(ResourceUID.id_to_text(ResourceUID.create_id())+"\n")
	quit()
