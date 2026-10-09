extends SceneTree
## Run only in run_native_shapes.py's isolated execution project with exact 01 sources.
const Policy = preload("res://game/feel/audio/event_policy.gd")
var checks := 0
var failures: Array[String] = []
var events: Array[Dictionary] = []
var commands: Array[Dictionary] = []
var output := ""

func _initialize() -> void:
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--evidence-dir="): output = arg.trim_prefix("--evidence-dir=")
	call_deferred("run")

func check(ok: bool, label: String) -> void:
	checks += 1
	if not ok:
		failures.append(label)
		print("FAIL: ", label)

func run() -> void:
	var fixture = load("res://tests/beta_sprint/game_feel_owner_01/fixtures.gd")
	var codec = load("res://foundation/level/level_codec.gd")
	var facade_script = load("res://foundation/game_feel/runtime_facade.gd")
	var level: Dictionary = fixture.level()
	level.content_hash = codec.compute_content_hash(level).content_hash
	var runtime = facade_script.new()
	var policy = Policy.new()
	runtime.game_feel_event.connect(func(event: Dictionary):
		events.append(event)
		commands.append(policy.consume(event, float(events.size()) * 0.5)))
	check(runtime.load_level(level).ok, "load exact candidate formal Runtime without injected dependencies")
	var edge: Dictionary = runtime.request_action({"kind": 0, "face_axis": 0})
	check(edge.status == 1 and edge.next_state == null and edge.size() == 8, "native Rules.rejected has unchanged eight-field/null-next result")
	check(events.size() == 1 and events[-1].semantic == "MOVE_REJECTED_EDGE", "real Facade classifies EDGE")
	check(commands[-1].issues.is_empty() and commands[-1].cues == ["edge_recoil"], "Audio consumes native EDGE unchanged")
	check(events[-1].result.next_state == null and events[-1].is_read_only(), "immutable rejected event not rewritten by Audio")
	var fall: Dictionary = runtime.request_action({"kind": 8, "connection_id": &"edge_a"})
	check(fall.status == 0 and fall.changed and runtime.get_commit_count() == 0, "formal Fall acceptance is still only a proposal")
	var started: Dictionary = events[-1]
	check(started.semantic == "PERSPECTIVE_FALL_APPLIED" and started.phase == "STARTED", "real Facade publishes accepted Fall start")
	check(started.safety_verdict is Dictionary and started.safety_verdict.status == "SAFE" and started.safety_verdict.issues.is_empty(), "actual structured Safety evidence")
	check(started.connection_id is StringName and started.motion_profile_id is StringName and started.intended_move_direction == null, "actual native StringName ids and nullable explicit Fall direction")
	check(commands[-1].issues.is_empty() and commands[-1].cues == ["fall_start", "fall_whoosh"], "Audio accepts real immutable native Fall STARTED")
	check(not commands.any(func(command): return command.cues.has("landing_impact")), "no impact before native commit")
	var token: Dictionary = started.transition_identity
	# Direct native completion API only: this proves DTO consumption, NOT motion playback.
	var completion: Dictionary = runtime.finish_transition(token)
	check(not completion.ignored and runtime.get_commit_count() == 1, "captured token completes native API exactly once")
	check(events[-1].phase == "COMMITTED" and commands[-1].cues == ["landing_impact"], "matching native COMMITTED reaches Audio policy")
	check(commands[-1].issues.is_empty() and commands[-1].stop_identity == started.presentation_identity, "native landing targets original whoosh identity")
	var duplicate: Dictionary = policy.consume(events[-1], 3.0)
	check(duplicate.cues.is_empty(), "native commit delivery deduplicated")
	var before: int = events.size()
	check(runtime.finish_transition(token).ignored and events.size() == before, "duplicate native completion API stays ignored")
	for connection in runtime.game_feel_event.get_connections():
		runtime.game_feel_event.disconnect(connection.callable)
	runtime.unload()
	var report := {"checks": checks, "failures": failures, "fixture_kind": "NATIVE_RUNTIME_EVENT_API_COMPATIBILITY", "authoritative_runtime": true, "doubles": [], "motion_playback": "NOT_RUN", "graphical_gameplay": "NOT_RUN", "completion_invocation": "direct native finish_transition(captured_token) for DTO/API test; not natural motion evidence", "runtime_commit": "26387d6c34a869ad7035ee13ee77d8d5c24d796a", "pid": OS.get_process_id(), "engine": Engine.get_version_info(), "user_data_dir": OS.get_user_data_dir(), "display": DisplayServer.get_name(), "events": events, "commands": commands}
	var file := FileAccess.open(output.path_join("native_shapes.json"), FileAccess.WRITE)
	file.store_string(JSON.stringify(report, "\t"))
	print("AUDIO_NATIVE_SHAPES checks=", checks, " failures=", failures.size())
	quit(0 if failures.is_empty() else 1)
