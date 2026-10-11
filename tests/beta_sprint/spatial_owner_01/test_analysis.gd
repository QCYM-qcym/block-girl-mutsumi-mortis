extends SceneTree
const F = preload("res://tests/beta_sprint/spatial_owner_01/fixtures.gd")
const CurveFixture = preload("res://tests/beta_sprint/game_feel_owner_01/curve_fixtures.gd")
const Baker = preload("res://foundation/level/level_baker.gd")
const Records = preload("res://foundation/contracts/contract_records.gd")
const Key = preload("res://foundation/contracts/state_key.gd")
const Kernel = preload("res://foundation/rules/puzzle_rule_kernel.gd")
const Rules = preload("res://foundation/rules/rule_records.gd")
const Classifier = preload("res://foundation/quality/intent/mechanic_classifier.gd")
const Explorer = preload("res://foundation/solver/state_explorer.gd")
const Search = preload("res://foundation/solver/search_records.gd")
const Trace = preload("res://foundation/solver/solution_trace.gd")
const Softlock = preload("res://foundation/quality/softlock/softlock_analyzer.gd")
const Ablation = preload("res://foundation/quality/intent/ablation_analyzer.gd")
const Replayer = preload("res://foundation/parity/trace_replayer.gd")
var checks := 0
var failures: Array[String] = []
var evidence := {}
func check(ok: bool, label: String) -> void:
	checks += 1
	if not ok: failures.append(label)
func _initialize() -> void:
	create_timer(30).timeout.connect(func():printerr("TEST_TIMEOUT");quit(2))
	call_deferred("run")
func run() -> void:
	var author := F.level(true)
	author.erase("content_hash")
	var baked := Baker.bake(author,{"max_configurations":4096,"max_checks":100000})
	check(baked.ok,"formal Solver input baked")
	if baked.ok: await _graph(baked.level)
	_loop()
	_curve()
	FileAccess.open(OS.get_environment("FOUNDATION_TEST_EVIDENCE").path_join("results.json"),FileAccess.WRITE).store_string(JSON.stringify({"checks":checks,"failures":failures,"doubles":[],"evidence":evidence}))
	print("SPATIAL_ANALYSIS checks=",checks," failures=",failures," doubles=[]")
	quit(0 if failures.is_empty() else 1)
func _graph(level: Dictionary) -> void:
	var initial := Records.initial_state(level)
	var search := Explorer.explore(level,initial,Search.default_policy(1),Search.default_budget())
	check(search.status == 0 and search.graph != null and search.graph.complete,"real full state graph completed")
	check(search.solution_trace != null,"real BFS finds authored unlock route")
	if search.solution_trace == null: evidence["search_failure"]=search;return
	var trace: Dictionary = search.solution_trace
	check(trace.total_actions == 4,"no unintended shortcut: latch, return, gate, goal")
	check(trace.steps[0].expected_state.mechanism_states.face_lock == &"latched" and trace.steps[2].action.kind == 1,"trace includes real latch and gate")
	check(Trace.validate_semantics(level,trace).ok,"formal trace semantic verification")
	var unlocked_nodes := 0
	var locked_nodes := 0
	for node in search.graph.nodes.values():
		if node.state.mechanism_states.face_lock == &"latched": unlocked_nodes+=1
		else: locked_nodes+=1
	check(unlocked_nodes>0 and locked_nodes>0,"graph identity separates both mechanism states")
	var shift_edges := 0
	for edge in search.graph.edges:
		if edge.action.kind == 1:
			shift_edges+=1
			check(search.graph.nodes[edge.from_key].state.mechanism_states.face_lock == &"latched","graph never bypasses locked gate")
	check(shift_edges>0,"actual Shift graph edges present")
	var softlock := Softlock.analyze(level,search.graph,{"max_nodes":10000,"max_edges":100000,"max_runtime_ms":0})
	check(softlock.status == 0 and softlock.softlock_count == 0,"formal complete graph has no irrecoverable softlock")
	var replay := Replayer.new()
	root.add_child(replay)
	var first: Dictionary = await replay.replay(level,trace,{"mode":0})
	var second: Dictionary = await replay.replay(level,trace,{"mode":0})
	check(first.status == 0 and first.matched_steps == 4,"real logical Session parity")
	check(second.status == 0 and second.actual_statekey == first.actual_statekey,"Replay deterministic full StateKey")
	replay.free()
	var intent := {"intent_version":"puzzleintent.v1","intent_id":&"spatial_required","level_hash":level.content_hash,"rule_version":level.rule_version,"required_mechanics":[1,7],"optional_mechanics":[],"expected_milestones":[],"forbidden_bypasses":[]}
	var ablated := Ablation.analyze(level,initial,intent,Search.default_policy(1),Search.default_budget())
	check(ablated.status == 0 and ablated.issues.is_empty(),"real mechanism-aware ablation completes")
	if ablated.status == 0:
		check(ablated.ablations.size() == 2,"Shift and latch have separate quality proofs")
		for item in ablated.ablations: check(item.essential == true and item.bypass_detected == false,"required mechanic cannot be bypassed")
	evidence["level_hash"]=level.content_hash
	evidence["initial_statekey"]=Key.build(level,initial).key
	evidence["final_statekey"]=first.actual_statekey
	evidence["solution_trace"]=trace
	evidence["graph_nodes"]=search.graph.nodes.size()
	evidence["graph_edges"]=search.graph.edges.size()
	evidence["softlock"]=softlock
	evidence["replays"]=[first,second]
	evidence["ablation"]=ablated
func _loop() -> void:
	var author := F.level()
	author.erase("content_hash")
	author.cubes=[F.F.cube(&"floor",0,Vector3i.ZERO),F.F.cube(&"east",0,Vector3i(2,0,0)),F.F.cube(&"corner",0,Vector3i(2,0,-2)),F.F.cube(&"north",0,Vector3i(0,0,-2))]
	author.faces=[]
	for cube in author.cubes:
		for face in F.Geometry.make_face_nodes(cube.cube_id):
			face.walkable=face.face==4;author.faces.append(face)
	author.shift_gates=[];author.goal.face_id=&"corner/TOP"
	var baked := Baker.bake(author,{"max_configurations":4096,"max_checks":100000})
	check(baked.ok,"orientation loop real Baker")
	if not baked.ok: return
	var initial := Records.initial_state(baked.level)
	var state := initial.duplicate(true)
	for axis in [0,1,2,3]:
		var result := Kernel.evaluate_action(baked.level,state,{"kind":0,"face_axis":axis},Rules.idle_context())
		check(result.status == 0,"ordinary closed loop Roll applied")
		if result.status != 0: return
		state=result.next_state
	check(state.player.location == initial.player.location and state.player.orientation != 0,"same cell different real orientation")
	check(Key.build(baked.level,state).key != Key.build(baked.level,initial).key,"orientation loop changes canonical identity")
	evidence["orientation_loop"]={"initial":initial.player,"final":state.player}
func _curve() -> void:
	for higher in [false,true]:
		var author := CurveFixture.authoring(higher)
		author.schema_version=4;author.contract_version="foundation.spatial_puzzle.v1";author.rule_version="foundation.rules.spatial_puzzle.v1"
		author["shift_gates"]=[];author["face_locks"]=[]
		var baked := Baker.bake(author,{"max_configurations":4096,"max_checks":100000})
		check(baked.ok,"schema4 inherits cubic profile " + str(higher))
		if not baked.ok: continue
		var initial := Records.initial_state(baked.level)
		var fall := Kernel.evaluate_action(baked.level,initial,{"kind":0,"face_axis":2},Rules.idle_context())
		check(fall.status == 0 and fall.next_state.player.location.cube_id == &"target" and fall.next_state.player.orientation == 0,"same formal MOVE inherits directed safe Fall " + str(higher))
		if fall.status==0: check(Classifier.classify_transition(baked.level,fall).ok,"quality accepts real Fall through actual Kernel")
		var camera := Kernel.evaluate_action(baked.level,initial,{"kind":9,"camera_quadrant":0},Rules.idle_context())
		check(camera.status==0 and camera.next_state.player==initial.player and Classifier.classify_transition(baked.level,camera).ok,"camera changes no physical orientation and classification")
