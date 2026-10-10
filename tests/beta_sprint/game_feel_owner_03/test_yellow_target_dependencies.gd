extends SceneTree
const Gate = preload("res://tests/beta_sprint/game_feel_owner_03/yellow_target_gate.gd")
func _initialize() -> void:
	var evidence := ""
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--evidence="): evidence = arg.trim_prefix("--evidence=")
	var report := Gate.probe()
	FileAccess.open(evidence.path_join("report.json"), FileAccess.WRITE).store_string(JSON.stringify(report, "\t"))
	quit(3) # Even available APIs do not authorize unbound Real execution.
