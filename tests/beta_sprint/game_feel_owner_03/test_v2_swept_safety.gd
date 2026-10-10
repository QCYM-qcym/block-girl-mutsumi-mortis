extends SceneTree
## Production Safety and Facade, with the delivered 01 data fixture; no safety double.
const F = preload("res://tests/beta_sprint/game_feel_owner_01/fixtures.gd")
const Codec = preload("res://foundation/level/level_codec.gd")
const Records = preload("res://foundation/contracts/contract_records.gd")
const Kernel = preload("res://foundation/rules/puzzle_rule_kernel.gd")
const Rules = preload("res://foundation/rules/rule_records.gd")
const Safety = preload("res://foundation/validation/safety_queries.gd")
const Facade = preload("res://foundation/game_feel/runtime_facade.gd")
const Key = preload("res://foundation/contracts/state_key.gd")
var evidence := ""
var checks := 0
var failures: Array[String] = []
var rows: Array = []
func _initialize() -> void:
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--evidence="): evidence = arg.trim_prefix("--evidence=")
	call_deferred("run")
func check(ok: bool, label: String) -> void:
	checks += 1
	if not ok: failures.append(label)
func run() -> void:
	for higher in [false, true]:
		var level := F.level(higher)
		level.content_hash = Codec.compute_content_hash(level).content_hash
		var before := Records.initial_state(level)
		var action := {"kind": 8, "connection_id": &"edge_a"}
		var legal := Kernel.evaluate_action(level, before, action, Rules.idle_context())
		check(legal.status == 0 and legal.changed, "delivered lower/higher fixture legal Fall")
		if legal.status != 0: continue
		var safe := Safety.validate_perspective_motion(level, before, legal.next_state, &"edge_a")
		check(safe.status == 0 and safe.issues.is_empty(), "production exact full sweep SAFE control")
		var blocked := level.duplicate(true)
		blocked.cubes.append(F.F.cube(&"obstacle", 0, Vector3i(-4, 6, 4)))
		for face in F.Geometry.make_face_nodes(&"obstacle"): blocked.faces.append(face)
		blocked.content_hash = Codec.compute_content_hash(blocked).content_hash
		var unsafe := Safety.validate_perspective_motion(blocked, before, legal.next_state, &"edge_a")
		check(unsafe.status != 0 and not unsafe.issues.is_empty(), "production full swept-body obstacle negative; never SAFE")
		var runtime := Facade.new()
		var events: Array = []
		runtime.game_feel_event.connect(func(event): events.append(event))
		var loaded := runtime.load_level(blocked)
		var native: Variant = null
		var actual_before: Dictionary = {}
		var actual_after: Dictionary = {}
		if loaded.ok:
			actual_before = runtime.get_state()
			native = runtime.request_action(action)
			actual_after = runtime.get_state()
			check(native.status == 1 and not native.changed and native.next_state == null and native.rejection_code == 2103, "real Facade swept Safety rejection")
			check(actual_after == actual_before and Key.build(blocked, actual_after).key == Key.build(blocked, actual_before).key and runtime.get_commit_count() == 0, "swept rejection preserves actual complete state/key")
			check(events.size() == 1 and events[0].semantic == "ACTION_FEEDBACK" and events[0].reason_category == "SAFETY_REJECTED" and events[0].result == native, "native Safety reason preserved without invented EDGE")
		rows.append({"higher": higher, "level_hash": blocked.content_hash, "safe": safe, "unsafe": unsafe,
			"load": loaded, "native": native, "before": actual_before, "after": actual_after, "events": events,
			"runtime_negative": "EXECUTED" if loaded.ok else "STATIC_ADMISSION_REJECTED; runtime row pending"})
	FileAccess.open(evidence.path_join("report.json"), FileAccess.WRITE).store_string(JSON.stringify({"checks": checks, "failures": failures,
		"rows": rows, "doubles": [], "pid": OS.get_process_id(), "display": DisplayServer.get_name(), "user_data_dir": OS.get_user_data_dir(),
		"authority": "formal production Safety/Kernel/Facade; delivered 01 fixture DATA plus explicit obstacle; no Runtime state assignment or copied volume/sweep algorithm"}, "\t"))
	quit(0 if failures.is_empty() else 1)
