extends SceneTree
## Real default Runtime admission, with malformed caller input; no replacement port.
const Maps = preload("res://experiments/game_feel_01/maps/map_factory.gd")
const Facade = preload("res://foundation/game_feel/runtime_facade.gd")
const Key = preload("res://foundation/contracts/state_key.gd")
const Codec = preload("res://foundation/level/level_codec.gd")
var checks := 0
var failures: Array[String] = []
var rows: Array = []
var evidence := ""
func _initialize() -> void:
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--evidence="): evidence = arg.trim_prefix("--evidence=")
	call_deferred("run")
func check(ok: bool, label: String) -> void:
	checks += 1
	if not ok: failures.append(label)
func run() -> void:
	for letter in ["a", "b"]:
		var baked := Maps.bake_game_feel(Maps.read_spec(letter))
		check(baked.ok, "real canonical Map " + letter)
		if not baked.ok: continue
		var runtime := Facade.new()
		var events: Array = []
		runtime.game_feel_event.connect(func(event): events.append(event))
		check(runtime.load_level(baked.level).ok, "real default Runtime load")
		for action in [{}, {"kind": 999}, {"kind": 0, "face_axis": 999}]:
			var before := runtime.get_state()
			var before_key: String = Key.build(baked.level, before).key
			var offset := events.size()
			var result := runtime.request_action(action)
			check(events.size() == offset + 1, "exactly one authoritative feedback event")
			if events.size() != offset + 1: continue
			var event: Dictionary = events[-1]
			check(event.semantic == "ACTION_FEEDBACK" and event.reason_category == "INVALID_ACTION" and event.phase == "FEEDBACK", "official invalid action classification")
			check(result.status != 0 and not result.changed and result.next_state == null and result.previous_state == before, "native rejection shape and preserved prior state")
			check(event.result == result and event.presentation_identity == null and event.transition_identity == null, "event preserves native result without motion authority")
			check(runtime.get_state() == before and Key.build(baked.level, runtime.get_state()).key == before_key and runtime.get_commit_count() == 0 and runtime.is_idle(), "actual full state/key unchanged, zero commits")
			rows.append({"map": letter, "action": action, "before": before, "after": runtime.get_state(), "key": before_key, "event": event, "result": result})
		# Same declarative locked-flag fixture fields delivered in 01 test_rules;
		# canonicalization/admission/reason logic all remain production calls.
		var locked: Dictionary = baked.level.duplicate(true)
		locked.flag_definitions = [{"flag_id": &"open", "initial_value": false}]
		locked.perspective_falls[0].required_flags = [&"open"]
		locked.content_hash = Codec.compute_content_hash(locked).content_hash
		check(runtime.load_level(locked).ok, "canonical explicit locked-flag data admitted by real Runtime")
		events.clear()
		var before := runtime.get_state()
		var result := runtime.request_action({"kind": 8, "connection_id": StringName("pfall_" + letter)})
		check(events.size() == 1 and events[0].semantic == "ACTION_FEEDBACK" and events[0].reason_category == "MECHANISM_LOCKED", "actual authored flag lock never classified as EDGE")
		check(result.status == 1 and not result.changed and result.next_state == null and runtime.get_state() == before and runtime.get_commit_count() == 0, "locked rejection preserves entire actual state")
		check(Key.build(locked, before).key == Key.build(locked, runtime.get_state()).key, "locked rejection preserves official versioned StateKey")
		if events.size() == 1:
			rows.append({"map": letter, "action": result.action, "before": before, "after": runtime.get_state(), "event": events[0], "result": result,
				"expected_reason": "MECHANISM_LOCKED", "level_hash": locked.content_hash, "scope": "controlled locked-flag canonical DATA variant; not registered 09 Map A/B artifact"})
	FileAccess.open(evidence.path_join("report.json"), FileAccess.WRITE).store_string(JSON.stringify({"checks": checks, "failures": failures,
		"rows": rows, "doubles": [], "display": DisplayServer.get_name(), "user_data_dir": OS.get_user_data_dir(),
		"authority": "real Map Baker/default Facade/native RuleResult/event; malformed public caller input only; no logical completion, Presenter or graphical replay claim"}, "\t"))
	quit(0 if failures.is_empty() else 1)
