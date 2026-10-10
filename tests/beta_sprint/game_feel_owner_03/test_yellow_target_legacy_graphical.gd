extends "res://tests/beta_sprint/game_feel_owner_03/test_v2_legacy_focused.gd"
const Capture = preload("res://tests/beta_sprint/game_feel_owner_03/capture_identity.gd")
func run() -> void:
	await super.run()
	var path := evidence.path_join("report.json")
	var report: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(path))
	report.scope = "LEGACY_FOCUSED_REAL"
	report.profile = "LEGACY_EXPLICIT"
	report.capture = Capture.snapshot("ACTUAL_L01_L05_AFFECTED_GRAPHICAL_REGRESSION")
	FileAccess.open(path,FileAccess.WRITE).store_string(JSON.stringify(report,"\t"))
