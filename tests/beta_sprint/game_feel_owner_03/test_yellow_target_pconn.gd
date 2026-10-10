extends "res://tests/gameplay/test_perspective_logic.gd"
const Capture = preload("res://tests/beta_sprint/game_feel_owner_03/capture_identity.gd")
func run() -> void:
	super.run()
	var evidence := ""
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--evidence="): evidence = arg.trim_prefix("--evidence=")
	FileAccess.open(evidence.path_join("report.json"),FileAccess.WRITE).store_string(JSON.stringify({
		"checks":checks,"failures":failures,"doubles":[],"scope":"LEGACY_FOCUSED_REAL","profile":"LEGACY_EXPLICIT",
		"capture":Capture.snapshot("ACTUAL_EXISTING_PERSPECTIVE_CONNECTION"),
		"authority":"Re-run existing production Perspective classes via unchanged66-check test; no new Fall or graphical claim"},"\t"))
