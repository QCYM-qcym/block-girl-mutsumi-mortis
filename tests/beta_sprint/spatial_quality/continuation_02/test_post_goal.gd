extends "res://tests/beta_sprint/spatial_quality/suite.gd"
## Bounded public Runtime/Safety/LogicalReplay observations, never a graph explorer.
const Maps = preload("res://experiments/spatial_puzzle_batch_01/maps/map_factory.gd")
const Records = preload("res://foundation/contracts/contract_records.gd")
const Codec = preload("res://foundation/level/level_codec.gd")
const Facade = preload("res://foundation/game_feel/runtime_facade.gd")
const Key = preload("res://foundation/contracts/state_key.gd")
const Goal = preload("res://foundation/rules/goal_evaluator.gd")
const Explorer = preload("res://foundation/solver/state_explorer.gd")
const Search = preload("res://foundation/solver/search_records.gd")
const Safety = preload("res://foundation/validation/safety_queries.gd")
const Fall = preload("res://foundation/game_feel/fall_permission.gd")
const Trace = preload("res://foundation/solver/solution_trace.gd")
const Replayer = preload("res://foundation/parity/trace_replayer.gd")
const REFERENCES = "res://docs/beta-sprint/spatial-puzzle-batch-01/quality/continuation_02/REFERENCE_RECIPES.json"
const TEMPLATE = "res://docs/beta-sprint/spatial-puzzle-batch-01/quality/acceptance_01/evidence/full_graph_03/selected_trace.gdvar"
var level: Dictionary = {}
var template: Dictionary = {}
var witness: Dictionary = {}
var runtime: RefCounted
var native: Array = []
var samples: Array = []
var safety_queries: Array = []
var replays: Array = []
var reset_observations: Array = []
var departure_count := 0
var probe: Dictionary = {}
var previous_replay_key := ""

func write_json(name: String, value: Variant) -> void:
	FileAccess.open(evidence.path_join(name),FileAccess.WRITE).store_string(JSON.stringify(value,"\t"))

func started(_result: Dictionary, token: int, generation: int, global: bool) -> void:
	native.append(runtime.get_pending_identity(token,generation,global))

func fresh() -> bool:
	if runtime != null:
		runtime.transition_started.disconnect(started)
		runtime.interrupt("UNLOAD")
	runtime = Facade.new()
	native.clear()
	runtime.transition_started.connect(started)
	var loaded: Dictionary = runtime.load_level(level)
	check(loaded.ok and runtime.get_state() == Records.initial_state(level),"current public Runtime loads exact canonical spawn")
	witness = template.duplicate(true)
	witness.steps = []
	witness.shortest = false
	return loaded.ok

func typed_action(raw: Dictionary) -> Dictionary:
	var value := {"kind":int(raw.kind)}
	if raw.has("face_axis"): value["face_axis"] = int(raw.face_axis)
	if raw.has("camera_quadrant"): value["camera_quadrant"] = int(raw.camera_quadrant)
	if raw.has("connection_id"): value["connection_id"] = StringName(raw.connection_id)
	return value

func act(action: Dictionary, expected_key: String = "", record_trace: bool = true) -> Dictionary:
	var before: Dictionary = runtime.get_state()
	var count: int = runtime.get_commit_count()
	var starts := native.size()
	var result: Dictionary = runtime.request_action(action)
	check(result.status in [0,1],"real public request is applied/rejected, no Runtime ERROR")
	var identity := {}
	if result.status == 0 and result.changed:
		check(native.size() == starts+1 and runtime.get_state() == before,"native proposal preserves authoritative state until LOGICAL completion")
		if native.size() != starts+1: return result
		identity = native[-1]
		check(identity.size() == 5 and identity.has_all(["session_id","level_run_id","generation","transaction_id","is_global"]),"complete native transition identity captured")
		var committed: Dictionary = runtime.finish_transition(identity)
		check(not committed.get("ignored",true) and runtime.get_commit_count() == count+1,"one exact-identity LOGICAL commit")
		check(runtime.get_state() == result.next_state and runtime.is_idle(),"actual full state equals native authorized proposal")
		var repeated: Dictionary = runtime.finish_transition(identity)
		check(repeated.get("ignored",false) and runtime.get_commit_count() == count+1 and runtime.get_state() == result.next_state,"duplicate identity cannot commit again")
		if record_trace:
			witness.steps.append({"index":witness.steps.size()+1,"action":action.duplicate(true),
				"expected_state":runtime.get_state(),"resulting_statekey":Key.build(level,runtime.get_state()).key,"global_kind":result.global_kind})
	else:
		check(not result.changed and runtime.get_state() == before and runtime.get_commit_count() == count and native.size() == starts,"actual rejection/noop preserves complete state/count/identity")
	var key: Dictionary = Key.build(level,runtime.get_state())
	check(key.ok,"actual state has formal StateKey")
	if not expected_key.is_empty(): check(key.key == expected_key,"current Runtime key equals historical reference recipe target")
	rows.append({"phase":"NATIVE_LOGICAL_ACTION","action":action,"before":before,"after":runtime.get_state(),
		"result":result,"identity":identity,"statekey":key.key,"commit_count":runtime.get_commit_count()})
	return result

func follow(reference: Dictionary, record_trace: bool = true) -> bool:
	if not fresh(): return false
	check(reference.recipe.size() <= 32,"reference prefix respects finite bound")
	for step in reference.recipe:
		var result := act(typed_action(step.action),step.expected_key,record_trace)
		if result.status != 0 or not result.changed:
			check(false,"historical predecessor action must actually apply on current Runtime")
			return false
	var state: Dictionary = runtime.get_state()
	check(Goal.is_goal(level,state).is_goal and Key.build(level,state).key == reference.reference_goal_key,"actual current Goal reached via public requests, no state injection")
	check(state.camera_quadrant == int(reference.camera) and state.player.orientation == int(reference.orientation),"exact representative Camera and Orientation reached")
	return true

func safety(before: Dictionary, after: Dictionary, action: Dictionary, sample: String) -> void:
	var query := "Safety.validate_motion"
	var motion: Dictionary = Fall.motion(level,before,after,action) if action.kind in [0,8] else {}
	var verdict: Dictionary
	if not motion.is_empty():
		query = "Safety.validate_perspective_motion"
		verdict = Safety.validate_perspective_motion(level,before,after,motion.connection_id)
	else: verdict = Safety.validate_motion(level,before,after,action)
	check(verdict.status == 0 and verdict.issues.is_empty(),"independent formal Safety query on actual accepted post-Goal motion")
	safety_queries.append({"sample":sample,"query":query,"action":action,"before":before,"after":after,"result":verdict})

func verify_reset(label: String, stale: Dictionary = {}) -> void:
	var before: Dictionary = runtime.get_state()
	var scope: Dictionary = runtime.get_presentation_scope()
	runtime.reset()
	var after: Dictionary = runtime.get_state()
	var initial: Dictionary = Records.initial_state(level)
	check(after == initial and Key.build(level,after).key == Key.build(level,initial).key,"Reset restores exact full spawn/key/Orientation/World/Camera/mechanism")
	check(runtime.get_commit_count() == 0 and runtime.is_idle() and runtime.get_generation() == scope.generation+1,"Reset count0/idle and new generation")
	var next_scope: Dictionary = runtime.get_presentation_scope()
	check(next_scope.session_id == scope.session_id and next_scope.level_run_id == scope.level_run_id,"Reset preserves session/run identity")
	var ignored := {}
	if not stale.is_empty():
		ignored = runtime.finish_transition(stale)
		check(ignored.get("ignored",false) and runtime.get_state() == initial and runtime.get_commit_count() == 0,"cancelled post-Goal identity cannot mutate Reset spawn")
	begin(label+"_reset_endpoint_safety","SAFETY")
	var safe: Dictionary = Safety.validate_state(level,after)
	check(safe.status == 0 and safe.issues.is_empty(),"independent formal Safety validates actual Reset endpoint")
	safety_queries.append({"sample":label,"query":"Safety.validate_state","state":after,"result":safe})
	reset_observations.append({"label":label,"before":before,"after":after,"scope_before":scope,"scope_after":next_scope,"stale_identity":stale,"stale_completion":ignored})

func run() -> void:
	begin("current_canonical_map","UNIT")
	check(DisplayServer.get_name() == "headless","no graphical process")
	var references: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(REFERENCES))
	var baked := Maps.bake(&"rubik_spatial_puzzle_01")
	check(baked.ok,"current saved resources through official Baker")
	if not baked.ok: finish();return
	level = baked.level
	# Acceptance01 saves var_to_str text, not FileAccess.store_var binary.
	var parsed: Variant = str_to_var(FileAccess.get_file_as_string(TEMPLATE))
	check(parsed is Dictionary,"original var_to_str record decodes as typed Dictionary")
	if not parsed is Dictionary: finish();return
	template = parsed
	check(Codec.encode(level).ok and level.content_hash == references.level_hash and template.level_hash == level.content_hash,"current canonical level equals immutable original reference identity")
	check(Trace.validate(level,template).ok and Trace.validate_semantics(level,template).ok,"old typed record structurally and semantically valid on current source; template only")
	check(references.representatives.size() == 8,"eight bounded Goal representatives")
	write_json("map_identity.json",{"level_hash":level.content_hash,"canonical_text":Codec.encode(level).text,"bake_provenance":baked.get("bake_provenance")})
	for index in references.representatives.size():
		var reference: Dictionary = references.representatives[index]
		var label := "goal_"+str(index)
		begin(label+"_runtime","REAL_RUNTIME")
		if not follow(reference): continue
		var original_goal: Dictionary = runtime.get_state()
		if index == 0:
			begin("public_goal_terminal_boundary","SOLVER")
			var budget := {"max_states":1,"max_edges":0,"max_depth":0,"max_runtime_ms":20000,"max_action_evaluations":1}
			probe = Explorer.explore(level,original_goal,Search.default_policy(1),budget)
			check(probe.status == 0 and probe.graph != null and probe.graph.complete,"public Explorer initial actual Goal completes")
			check(probe.graph.nodes.size() == 1 and probe.graph.edges.is_empty() and probe.metrics.action_evaluations == 0,"formal initial Goal is terminal without outgoing expansion")
			write_json("goal_boundary_probe.json",{"budget":budget,"result":probe,"purpose":"API boundary only; no broader graph closure"})
			begin(label+"_post_goal","REAL_RUNTIME")
		var accepted_axis := -1
		var movements: Array = []
		for axis in range(4):
			var before: Dictionary = runtime.get_state()
			var action := {"kind":0,"face_axis":axis}
			var result := act(action)
			var after: Dictionary = runtime.get_state()
			movements.append({"action":action,"result":result,"actual_before":before,"actual_after":after})
			if result.status == 0 and result.changed:
				accepted_axis = axis
				departure_count += 1
				check(not Goal.is_goal(level,after).is_goal,"actual post-Goal MOVE departs to non-Goal")
				begin(label+"_safety_departure_"+str(axis),"SAFETY")
				safety(before,after,action,label+"_departure")
				begin(label+"_return_"+str(axis),"REAL_RUNTIME")
				var back := {"kind":0,"face_axis":posmod(axis+2,4)}
				var returned := act(back)
				check(returned.status == 0 and returned.changed and runtime.get_state() == original_goal and Goal.is_goal(level,runtime.get_state()).is_goal,"real inverse MOVE returns to identical Goal full state")
				begin(label+"_safety_return_"+str(axis),"SAFETY")
				safety(after,runtime.get_state(),back,label+"_return")
				begin(label+"_after_return_"+str(axis),"REAL_RUNTIME")
		check(accepted_axis >= 0,"each selected Goal has a real accepted departure and re-Goal witness")
		witness.total_actions = witness.steps.size()
		witness.goal_statekey = Key.build(level,runtime.get_state()).key
		check(witness.total_actions <= 64,"captured witness respects finite step bound")
		var captured: Dictionary = witness.duplicate(true)
		begin(label+"_logical_replay","LOGICAL_REPLAY")
		var structure: Dictionary = Trace.validate(level,captured)
		var semantics: Dictionary = Trace.validate_semantics(level,captured)
		check(structure.ok and semantics.ok,"runtime-captured witness passes both formal validations before quality conclusion")
		var driver := Replayer.new()
		root.add_child(driver)
		var replay: Dictionary = await driver.replay(level,captured,{"mode":0,"max_steps":64,"max_runtime_ms":60000,"step_timeout_ms":5000})
		check(replay.status == 0 and replay.issues.is_empty() and replay.matched_steps == captured.total_actions and replay.actual_statekey == captured.goal_statekey,"formal LOGICAL_SESSION matches every captured step across intermediate Goal/non-Goal/Goal")
		replays.append({"representative":index,"provenance":"CURRENT_RUNTIME_CAPTURED_VALIDATED_WITNESS; not Solver trace/new graph","trace":captured,"structure":structure,"semantics":semantics,"result":replay})
		if index == 0:
			var repeat: Dictionary = await driver.replay(level,captured,{"mode":0,"max_steps":64,"max_runtime_ms":60000,"step_timeout_ms":5000})
			check(repeat.status == 0 and repeat.matched_steps == replay.matched_steps and repeat.actual_statekey == replay.actual_statekey,"repeat formal LogicalReplay preserves semantic endpoint")
			replays.append({"representative":index,"repeat":true,"result":repeat})
		driver.free()
		begin(label+"_reset","REAL_RUNTIME")
		if accepted_axis >= 0:
			var out_result := act({"kind":0,"face_axis":accepted_axis},"",false)
			check(out_result.status == 0 and out_result.changed and not Goal.is_goal(level,runtime.get_state()).is_goal,"Reset source is actual committed post-Goal non-Goal")
			verify_reset(label+"_non_goal")
			begin(label+"_pending_reset_setup","REAL_RUNTIME")
			if follow(reference,false):
				var count := native.size()
				var pending: Dictionary = runtime.request_action({"kind":0,"face_axis":accepted_axis})
				check(pending.status == 0 and pending.changed and native.size() == count+1 and runtime.get_state() == original_goal and not runtime.is_idle(),"actual post-Goal departure remains pending before Reset")
				if native.size() == count+1: verify_reset(label+"_pending",native[-1])
		samples.append({"representative":index,"reference_goal_key":reference.reference_goal_key,"camera":int(reference.camera),"orientation":int(reference.orientation),"prefix_length":reference.recipe.size(),"actual_goal":original_goal,"candidate_moves":movements,"captured_trace_steps":captured.total_actions})
	if runtime != null:
		runtime.transition_started.disconnect(started)
		runtime.interrupt("UNLOAD")
	write_json("observations.json",{"overall":"PARTIAL","post_goal_total_states":"UNKNOWN","post_goal_total_edges":"UNKNOWN",
		"original_goal_terminal":{"states":908,"edges":3916,"goals":96,"softlocks":0,"source":"PREVIOUS_ACCEPTANCE_01_NOT_RERUN"},
		"samples":samples,"accepted_departures_in_four_direction_samples":departure_count,"safety_queries":safety_queries,
		"replays":replays,"resets":reset_observations,"graphical":"NOT_RUN_NO_GUI","softlock_analysis":"NOT_RUN_NO_NEW_LIVE_EXPANDED_GRAPH"})
	finish()
