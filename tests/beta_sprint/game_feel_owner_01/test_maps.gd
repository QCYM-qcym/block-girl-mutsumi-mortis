extends SceneTree
const F = preload("res://tests/beta_sprint/game_feel_owner_01/fixtures.gd")
const Baker = preload("res://foundation/level/level_baker.gd")
const Codec = preload("res://foundation/level/level_codec.gd")
const Key = preload("res://foundation/contracts/state_key.gd")
const Facade = preload("res://foundation/game_feel/runtime_facade.gd")
const Goal = preload("res://foundation/rules/goal_evaluator.gd")
const Safety = preload("res://foundation/validation/safety_queries.gd")
const Search = preload("res://foundation/solver/search_records.gd")
const Explorer = preload("res://foundation/solver/state_explorer.gd")
const Trace = preload("res://foundation/solver/solution_trace.gd")
const Softlock = preload("res://foundation/quality/softlock/softlock_analyzer.gd")
const Replayer = preload("res://foundation/parity/trace_replayer.gd")
var checks := 0
var failures: Array[String] = []
var routes: Array = []
func check(ok: bool, label: String) -> void:
	checks += 1
	if not ok: failures.append(label)
func _initialize() -> void:
	create_timer(30).timeout.connect(func():printerr("TEST_TIMEOUT");quit(2))
	call_deferred("run")
func run() -> void:
	var ev := OS.get_environment("FOUNDATION_TEST_EVIDENCE")
	for letter in ["a","b"]:
		var data: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(ev.path_join("map_"+letter+".json")))
		var authoring := F.map_level(data)
		authoring.erase("content_hash")
		var baked := Baker.bake(authoring,{"max_configurations":4096,"max_checks":100000})
		check(baked.ok,"real Baker admits Owner09 exit geometry " + letter)
		if not baked.ok: routes.append(baked); continue
		var level: Dictionary = baked.level
		FileAccess.open(ev.path_join("map_"+letter+".level.json"),FileAccess.WRITE).store_string(Codec.encode(level).text)
		var runtime := Facade.new()
		var events: Array = []
		runtime.game_feel_event.connect(func(e):events.append(e))
		check(runtime.load_level(level).ok,"load exact canonical profile with real Runtime/Safety")
		var initial := runtime.get_state()
		var initial_key: String = Key.build(level,initial).key
		var fall := runtime.request_action({"kind":0,"face_axis":2})
		check(fall.status == 0 and fall.changed and events[-1].semantic == "PERSPECTIVE_FALL_APPLIED","active player MOVE starts the authored Fall")
		check(Safety.validate_perspective_motion(level,initial,fall.next_state,StringName(data.connection.connection_id)).status == 0,"complete Fall sweep includes new exit obstacle")
		var identity: Dictionary = events[-1].transition_identity
		check(not identity.is_global and runtime.get_commit_count() == 0,"Fall is one pending local proposal")
		check(not runtime.finish_transition(identity).ignored and runtime.get_commit_count() == 1,"logical native completion commits Fall once")
		check(not Goal.is_goal(level,runtime.get_state()).is_goal,"landing is not premature Exit Goal")
		check(runtime.finish_transition(identity).ignored and runtime.get_commit_count() == 1,"late Fall callback cannot commit second landing")
		var move := runtime.request_action({"kind":0,"face_axis":0})
		check(move.status == 0 and move.changed and events[-1].semantic == "MOVE_APPLIED_NORMAL","post-landing U_POS is real ordinary Roll")
		check(not runtime.finish_transition(events[-1].transition_identity).ignored and runtime.get_commit_count() == 2 and Goal.is_goal(level,runtime.get_state()).is_goal,"only completed exit Roll reaches Goal")
		var final_key: String = Key.build(level,runtime.get_state()).key
		runtime.reset()
		check(Key.build(level,runtime.get_state()).key == initial_key and runtime.get_commit_count() == 0,"Reset restores A/B spawn exactly")
		var solved := Explorer.explore(level,initial,Search.default_policy(1),Search.default_budget())
		check(solved.status == 0 and solved.graph.complete and solved.solution_trace.total_actions == 2,"real complete graph requires Fall then Roll")
		check(Trace.validate_semantics(level,solved.solution_trace).ok,"trace agrees with real Kernel and current exit geometry")
		var softlock := Softlock.analyze(level,solved.graph,{"max_nodes":10000,"max_edges":100000,"max_runtime_ms":0})
		check(softlock.status == 0 and softlock.softlock_count == 0,"real directed graph has no unrecoverable branch")
		var replay := Replayer.new()
		root.add_child(replay)
		var replayed: Dictionary = await replay.replay(level,solved.solution_trace,{"mode":0})
		check(replayed.status == 0 and replayed.matched_steps == 2 and replayed.actual_statekey == final_key,"real LOGICAL_SESSION Replay matches facade endpoint exactly")
		routes.append({"letter":letter,"level_hash":level.content_hash,"initial_key":initial_key,"final_key":final_key,"events":events,"trace":solved.solution_trace,"softlock":softlock,"replay":replayed})
		replay.free()
	var summary := {"checks":checks,"failures":failures,"doubles":[],"mode":"LOGICAL_SESSION; graphical natural motion pending 00+10A","map_commit":"82a8a7dc85205e9391551f24267f35f5abe53393","routes":routes}
	FileAccess.open(ev.path_join("results.json"),FileAccess.WRITE).store_string(JSON.stringify(summary))
	print("MAP_ROUTES checks=",checks," failures=",failures)
	quit(0 if failures.is_empty() else 1)
