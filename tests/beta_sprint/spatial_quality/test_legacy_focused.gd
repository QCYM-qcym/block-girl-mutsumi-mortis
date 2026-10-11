extends "res://tests/beta_sprint/game_feel_owner_03/test_v2_legacy_focused.gd"
## The new isolated experiment owns main_scene. The frozen five-level recipe
## consumes the actual legacy Shell explicitly, in this process only.
func run() -> void:
	ProjectSettings.set_setting("application/run/main_scene", "res://game/shell/game_feel_shell.tscn")
	register_import_ids("res://production")
	await super.run()
	# Preserve the unchanged recipe's raw observations and add measured process
	# metadata required by this Owner's strict admission boundary.
	var path: String = evidence.path_join("report.json")
	var report: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(path))
	report["checks"] = checks
	var head := ""
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--execution-head="): head = arg.trim_prefix("--execution-head=")
	report["scope"] = "LEGACY_FOCUSED_REAL"
	report["profile"] = "LEGACY_EXPLICIT"
	report["legacy_scene"] = "res://game/shell/game_feel_shell.tscn"
	report["capture"] = {"pid":OS.get_process_id(),"execution_head":head,"engine":Engine.get_version_info(),
		"display":DisplayServer.get_name(),"user_data_dir":OS.get_user_data_dir(),"doubles":[]}
	FileAccess.open(path,FileAccess.WRITE).store_string(JSON.stringify(report,"\t"))

func register_import_ids(directory: String) -> void:
	# A script run skips Editor scanning. Register only the existing authored
	# UID/path pairs; resources and imported scene bytes remain untouched.
	for child in DirAccess.get_directories_at(directory):
		register_import_ids(directory.path_join(child))
	for file in DirAccess.get_files_at(directory):
		if not file.ends_with(".import"): continue
		var config := ConfigFile.new()
		if config.load(directory.path_join(file)) != OK: continue
		var uid: int = ResourceUID.text_to_id(config.get_value("remap","uid",""))
		var source: String = config.get_value("deps","source_file","")
		if uid != ResourceUID.INVALID_ID and not source.is_empty():
			if ResourceUID.has_id(uid): ResourceUID.set_id(uid,source)
			else: ResourceUID.add_id(uid,source)
