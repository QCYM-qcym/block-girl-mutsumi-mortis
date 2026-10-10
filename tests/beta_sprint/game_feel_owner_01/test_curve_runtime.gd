extends SceneTree
const F = preload("res://tests/beta_sprint/game_feel_owner_01/curve_fixtures.gd")
const Baker = preload("res://foundation/level/level_baker.gd")
const Facade = preload("res://foundation/game_feel/runtime_facade.gd")
const R = preload("res://foundation/contracts/contract_records.gd")
const Key = preload("res://foundation/contracts/state_key.gd")
const Goal = preload("res://foundation/rules/goal_evaluator.gd")
const Explorer = preload("res://foundation/solver/state_explorer.gd")
const Search = preload("res://foundation/solver/search_records.gd")
const Trace = preload("res://foundation/solver/solution_trace.gd")
const Softlock = preload("res://foundation/quality/softlock/softlock_analyzer.gd")
const Replayer = preload("res://foundation/parity/trace_replayer.gd")
var checks := 0
var failures: Array[String] = []
var observations: Array = []
func check(ok: bool, name: String) -> void:
	checks += 1
	if not ok: failures.append(name)
func _initialize() -> void:
	create_timer(40).timeout.connect(func(): printerr("TEST_TIMEOUT"); quit(2))
	call_deferred("run")
func run() -> void:
	for higher in [false,true]:
		var baked := Baker.bake(F.authoring(higher),{"max_configurations":4096,"max_checks":100000})
		check(baked.ok,"real Baker admits approved synthetic author geometry")
		if not baked.ok: observations.append(baked); continue
		var level: Dictionary = baked.level
		var events: Array = []
		var starts: Array = []
		var runtime := Facade.new()
		runtime.game_feel_event.connect(func(e): events.append(e))
		runtime.transition_started.connect(func(r,t,g,global): starts.append({"result":r,"token":t,"generation":g,"is_global":global}))
		check(runtime.load_level(level).ok,"real Facade loads schema3 via formal Session")
		var initial: String = Key.build(level,runtime.get_state()).key
		var applied := runtime.request_action({"kind":0,"face_axis":2})
		check(applied.size() == 8 and applied.status == 0 and applied.changed,"normal MOVE dispatch grants one authorized Fall")
		check(runtime.get_commit_count() == 0 and Key.build(level,runtime.get_state()).key == initial,"STARTED cannot move authoritative state")
		check(starts.size() == 1 and not starts[0].is_global,"captured native Fall is a single local transition")
		var started: Dictionary = events[-1]
		check(started.schema_version == 2 and started.contract_version == "game_feel.event.v2","new curve Fall has the approved v2 envelope")
		check(started.semantic == "PERSPECTIVE_FALL_APPLIED" and started.phase == "STARTED","Fall semantics unchanged")
		check(started.has("authorized_trajectory") and not started.has("authorized_path_points2") and started.get("authorized_trajectory") == F.trajectory(higher),"one exact authorized trajectory; no old polyline fallback")
		check(started.is_read_only() and started.authorized_trajectory.is_read_only() and started.authorized_trajectory.descent_control_points2.is_read_only(),"authorized curve event is recursively immutable")
		check(started.transition_identity.size() == 5 and started.transition_identity.transaction_id == starts[0].token and started.transition_identity.generation == starts[0].generation,"full identity comes from actual Session signal")
		check(started.safety_verdict.status == "SAFE" and started.safety_verdict.evidence_ref.kind == "dyadic_cubic_cube_sweep.v1","event carries continuous actual Safety attestation")
		var identity: Dictionary = started.transition_identity
		for action in [{"kind":0,"face_axis":2},{"kind":8,"connection_id":&"yellow_fall"},{"kind":9,"camera_quadrant":0}]:
			var busy := runtime.request_action(action)
			check(busy.status == 1 and events[-1].reason_category == "BUSY" and runtime.get_commit_count() == 0,"repeated/in-flight input cannot create additional landing")
		var done := runtime.finish_transition(identity)
		var landed: String = Key.build(level,runtime.get_state()).key
		check(not done.ignored and runtime.is_idle() and runtime.get_commit_count() == 1 and landed != initial,"captured logical completion commits exactly once")
		check(runtime.get_state().player.location.cube_id == &"target" and runtime.get_state().player.orientation == 0 and runtime.get_state().player.location.layer == 0,"actual higher/lower target reached without orientation/World change")
		check(events[-1].phase == "COMMITTED" and events[-1].schema_version == 2 and events[-1].authorized_trajectory == started.authorized_trajectory,"COMMITTED preserves captured curve envelope")
		check(not Goal.is_goal(level,runtime.get_state()).is_goal,"yellow target is not the distinct exit Goal")
		check(runtime.finish_transition(identity).ignored and runtime.get_commit_count() == 1 and Key.build(level,runtime.get_state()).key == landed,"duplicate completion is ignored")
		var reverse := runtime.request_action({"kind":8,"connection_id":&"yellow_fall"})
		check(reverse.status == 1 and runtime.get_commit_count() == 1,"authored directed Fall has no automatic reverse edge")
		var roll := runtime.request_action({"kind":0,"face_axis":0})
		check(roll.status == 0 and roll.changed and events[-1].semantic == "MOVE_APPLIED_NORMAL" and events[-1].schema_version == 1,"ordinary target-to-exit Roll retains event.v1")
		runtime.finish_transition(events[-1].transition_identity)
		check(runtime.get_commit_count() == 2 and runtime.get_state().player.location.cube_id == &"exit" and Goal.is_goal(level,runtime.get_state()).is_goal,"one actual Roll reaches distinct exit Goal")
		runtime.reset()
		check(runtime.get_commit_count() == 0 and Key.build(level,runtime.get_state()).key == initial,"Reset restores initial full canonical state")
		for reason in ["RESET","CANCEL","UNLOAD","QUIT","RELOAD"]:
			runtime.load_level(level)
			runtime.request_action({"kind":0,"face_axis":2})
			var captured: Dictionary = events[-1]
			var before: String = Key.build(level,runtime.get_state()).key
			match reason:
				"RESET": runtime.reset()
				"RELOAD": runtime.load_level(level)
				_: runtime.interrupt(reason)
			var interruption: Dictionary = events[-1]
			check(interruption.semantic == "ANIMATION_INTERRUPTED" and interruption.interruption_reason == reason and interruption.schema_version == 2 and interruption.contract_version == "game_feel.event.v2","interruption preserves the captured v2 envelope: "+reason)
			check(interruption.presentation_identity == captured.presentation_identity and interruption.transition_identity == captured.transition_identity and interruption.authorized_trajectory == captured.authorized_trajectory and interruption.target_pose == null,"interruption captures original identities/curve without a destination: "+reason)
			check(runtime.finish_transition(captured.transition_identity).ignored and runtime.get_commit_count() == 0,"lifecycle rejects stale native completion: "+reason)
			if runtime.is_loaded(): check(Key.build(level,runtime.get_state()).key == before,"lifecycle never partially lands: "+reason)
		for signal_name in ["game_feel_event","transition_started"]:
			for connection in runtime.get_signal_connection_list(signal_name): runtime.disconnect(signal_name,connection.callable)
		var search := Explorer.explore(level,R.initial_state(level),Search.default_policy(1),Search.default_budget())
		check(search.status == 0 and search.graph != null and search.graph.complete and search.solution_trace != null,"formal complete BFS reaches Goal using current rule version")
		if search.solution_trace == null: observations.append(search); continue
		var trace: Dictionary = search.solution_trace
		check(trace.trace_version == "solutiontrace.game_feel.v1" and trace.rule_version == level.rule_version and trace.total_actions == 2,"existing Trace format binds the new rule; Fall then Roll is shortest")
		check(trace.steps[0].expected_state.player.location.cube_id == &"target" and trace.steps[1].expected_state.player.location.cube_id == &"exit","formal search cannot turn the yellow target into premature Goal")
		check(Trace.validate_semantics(level,trace).ok,"formal Kernel deterministically re-executes the actual trace")
		var softlock := Softlock.analyze(level,search.graph,{"max_nodes":10000,"max_edges":100000,"max_runtime_ms":0})
		check(softlock.status == 0 and softlock.softlock_count == 0,"formal complete reverse graph proves no irreversible softlock")
		var replayer := Replayer.new()
		root.add_child(replayer)
		var replay: Dictionary = await replayer.replay(level,trace,{"mode":0})
		var repeated: Dictionary = await replayer.replay(level,trace,{"mode":0})
		check(replay.status == 0 and replay.matched_steps == 2 and replay.actual_statekey == replay.expected_statekey,"official logical Session Replay matches both complete StateKeys")
		check(repeated.status == 0 and repeated.actual_statekey == replay.actual_statekey,"new Runtime replay is deterministic")
		observations.append({"higher":higher,"initial_key":initial,"landing_key":landed,"events":events,"trace":trace,"softlock":softlock,"replay":replay})
		replayer.free()
	var summary := {"checks":checks,"failures":failures,"doubles":[],"authority":"synthetic approved author DATA; real Baker/Runtime/Kernel/Safety/Explorer/Softlock/Replayer; completion=LOGICAL_SESSION", "new_profile_graphical":"CASE_DEPENDENCY_PENDING: 00/10A event.v2 curve Presenter consumption", "observations":observations}
	FileAccess.open(OS.get_environment("FOUNDATION_TEST_EVIDENCE").path_join("results.json"),FileAccess.WRITE).store_string(JSON.stringify(summary))
	print("CURVE_RUNTIME checks=",checks," failures=",failures)
	quit(0 if failures.is_empty() else 1)
