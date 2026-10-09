extends RefCounted
## Quality recording helper only; no Runtime state, event, permission or motion writes.
static func snapshot(input_profile: String) -> Dictionary:
	var execution_head := ""
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--execution-head="): execution_head = arg.trim_prefix("--execution-head=")
	return {"execution_head": execution_head, "pid": OS.get_process_id(),
		"engine": Engine.get_version_info(), "display": DisplayServer.get_name(),
		"renderer": RenderingServer.get_current_rendering_method(),
		"user_data_dir": OS.get_user_data_dir(), "input_profile": input_profile,
		"fixture_kind": "LEGACY_PRODUCTION_MODULE_UNIT", "authoritative_runtime": false,
		"doubles": []}
