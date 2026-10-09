extends SceneTree
## Synthetic observation records only; does not instantiate or exercise a Runtime/Host.
const Observer = preload("res://tests/beta_sprint/game_feel_owner_03/test_core_playable.gd")
const Capture = preload("res://tests/beta_sprint/game_feel_owner_03/capture_identity.gd")
var checks := 0
var failures: Array[String] = []

func check(ok: bool, label: String) -> void:
	checks += 1
	if not ok:
		failures.append(label)
		printerr("FAIL: ", label)

func frame(time: float, x: float, screen_y: float) -> Dictionary:
	return {"time_ms": time, "canonical_position": [x, 0.0, 0.0], "screen_position": [100.0, screen_y]}

func _initialize() -> void:
	var trajectory := [frame(0, 0, 10), frame(1, 1, 20), frame(2, 2, 30), frame(3, 3, 40)]
	check(Observer.flight_failures(trajectory, 0, 3).is_empty(), "actual moving and descending observations")
	check(not Observer.flight_failures([], 0, 3).is_empty(), "missing flight observations rejected")
	check(not Observer.flight_failures([trajectory[0], trajectory[3]], 0, 3).is_empty(), "endpoints alone are not continuous motion")
	var static_screen := [frame(0, 0, 10), frame(1, 1, 10), frame(2, 2, 10), frame(3, 3, 10), frame(4, 4, 80)]
	check(not Observer.flight_failures(static_screen, 0, 3).is_empty(), "later ordinary Roll cannot prove screen-static Fall descended")
	check(not Observer.flight_failures([frame(0, 0, 10), frame(1, 0, 20), frame(2, 0, 30)], 0, 2).is_empty(), "static physical actor rejected")
	check(not Observer.flight_failures([frame(0, 0, 10), frame(1, 2, 20), frame(2, 2, 30)], 0, 2).is_empty(), "teleport without intermediate physical position rejected")
	check(not Observer.flight_failures([frame(0, 0, 10), frame(1, 1, 5), frame(2, 2, 30)], 0, 2).is_empty(), "upward screen jump rejected")
	check(Observer.flight_failures([frame(0, 0, 10), frame(1, 1, 9.9), frame(2, 2, 30)], 0, 2).is_empty(), "declared subpixel measurement noise allowed")
	var refusal := {"result": {"status": 1, "changed": false, "previous_state": {"player": 7, "camera": 1}, "next_state": null},
		"transition_identity": null, "target_pose": null, "target_face": null, "authoritative_final_orientation": null}
	var before: Dictionary = refusal.result.previous_state.duplicate(true)
	check(Observer.refusal_failures(refusal, before, before.duplicate(true)).is_empty(), "native null-next-state refusal with actual preservation")
	check(not Observer.refusal_failures(refusal).is_empty(), "null cannot prove missing Runtime after state")
	var bad := refusal.duplicate(true)
	var after := before.duplicate(true)
	after.camera = 2
	check(not Observer.refusal_failures(bad, before, after).is_empty(), "actual non-player state mutation rejected")
	bad.result.next_state = before.duplicate(true)
	check(not Observer.refusal_failures(bad, before, before.duplicate(true)).is_empty(), "fake duplicated next-state rejected")
	bad = refusal.duplicate(true)
	bad.result.status = 0
	bad.result.changed = true
	check(not Observer.refusal_failures(bad, before, before.duplicate(true)).is_empty(), "APPLIED cannot prove refusal")
	bad = refusal.duplicate(true)
	bad.authorized_path_points2 = [Vector3i.ZERO, Vector3i.ONE]
	check(not Observer.refusal_failures(bad, before, before.duplicate(true)).is_empty(), "refusal cannot carry accepted path")
	var evidence := ""
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--evidence-dir="): evidence = arg.trim_prefix("--evidence-dir=")
	var capture := Capture.snapshot("SYNTHETIC_CORE_OBSERVATIONS")
	capture.fixture_kind = "PRESENTATION_CONTRACT_UNIT"
	capture.authoritative_runtime = false
	capture.doubles = ["synthetic_trajectory", "synthetic_native_refusal_snapshot"]
	FileAccess.open(evidence.path_join("core_assertions.json"), FileAccess.WRITE).store_string(JSON.stringify({"checks": checks, "failures": failures, "capture": capture}, "\t"))
	print("GAME_FEEL_CORE_ASSERTIONS checks=", checks, " failures=", failures)
	quit(0 if failures.is_empty() else 1)
