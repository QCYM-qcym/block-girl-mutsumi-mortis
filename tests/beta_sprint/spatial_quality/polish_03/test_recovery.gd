extends "res://tests/beta_sprint/spatial_quality/continuation_02/test_post_goal.gd"
## Reuse recording helpers only; run overrides old post-Goal suite entirely.
const Solver = preload("res://foundation/solver/bfs_solver.gd")
const Classifier = preload("res://foundation/quality/intent/mechanic_classifier.gd")
const Geometry = preload("res://foundation/spatial/surface_geometry.gd")
const Math = preload("res://foundation/orientation/discrete_orientation.gd")
const BUDGET = {"max_states":512,"max_edges":5000,"max_depth":32,"max_runtime_ms":120000,"max_action_evaluations":10000}
var scenarios: Array = []
var searches: Array = []
var rejected: Array = []
var classified: Array = []
var reset_same_instance: Dictionary = {}

func route(actions: Array) -> bool:
	for action in actions:
		var result := act(action)
		if result.status != 0 or not result.changed:
			check(false,"planned setup route must apply a changed action")
			return false
	return true

func reject(action: Dictionary, code: int, label: String) -> void:
	var before: Dictionary = runtime.get_state()
	var scope: Dictionary = runtime.get_presentation_scope()
	var count: int = runtime.get_commit_count()
	var result := act(action)
	check(result.status == 1 and result.rejection_code == code and result.next_state == null and not result.changed,label+" exact real rejection with null next state")
	check(runtime.get_state() == before and runtime.get_presentation_scope() == scope and runtime.get_commit_count() == count and runtime.is_idle(),label+" does not consume identity/count or block next request")
	rejected.append({"label":label,"action":action,"result":result,"before":before,"after":runtime.get_state(),"scope":scope,"commit_count":count})

func actual_contact(state: Dictionary) -> Vector3i:
	for record in level.face_locks:
		if record.mechanism_id == &"contact_lock":
			return Math.apply(state.player.orientation,Geometry.face_frame(record.required_local_face).normal)
	return Vector3i.ZERO

func follow_recovery(actions: Array, label: String) -> void:
	for index in actions.size():
		begin(label+"_native_"+str(index),"REAL_RUNTIME")
		var before: Dictionary = runtime.get_state()
		var result := act(actions[index])
		check(result.status == 0 and result.changed,label+" changed recovery action really applies")
		if result.status != 0 or not result.changed: return
		var after: Dictionary = runtime.get_state()
		var tags: Dictionary = Classifier.classify_transition(level,result)
		check(tags.ok,"formal classifier consumes actual atomic RuleResult")
		if before.mechanism_states.contact_lock != after.mechanism_states.contact_lock:
			check(result.action.kind == 0 and after.mechanism_states.contact_lock == &"latched" and after.player.location.cube_id == &"corner" and actual_contact(after) == -Geometry.face_frame(after.player.location.face).normal,"actual recovery latch is post-Roll physical contact in one proposal")
			check(tags.ok and 7 in tags.tags and tags.mechanism_ids == [&"contact_lock"],"real recovery has exact ENTER mechanism semantic")
		if result.action.kind == 1:
			check(before.player.orientation == after.player.orientation and before.camera_quadrant == after.camera_quadrant and before.player.location.layer != after.player.location.layer,"actual Gate Shift preserves physical Orientation/Camera and changes World")
		classified.append({"scenario":label,"step":index+1,"actual_transition":result,"classification":tags})
		begin(label+"_safety_"+str(index),"SAFETY")
		if result.action.kind == 9:
			var safe: Dictionary = Safety.validate_state(level,after)
			check(safe.status == 0 and safe.issues.is_empty(),"independent Safety state query on actual Camera recovery")
			safety_queries.append({"sample":label,"query":"Safety.validate_state (Camera)","before":before,"after":after,"action":result.action,"result":safe})
		else: safety(before,after,result.action,label+"_step_"+str(index+1))

func replay_capture(label: String) -> Dictionary:
	begin(label+"_captured_trace","LOGICAL_REPLAY")
	witness.total_actions = witness.steps.size()
	witness.goal_statekey = Key.build(level,runtime.get_state()).key
	var trace: Dictionary = witness.duplicate(true)
	check(trace.shortest == false and trace.total_actions <= 64,"captured canonicalspawn witness is bounded and not shortest/Solver provenance")
	var structure: Dictionary = Trace.validate(level,trace)
	var semantics: Dictionary = Trace.validate_semantics(level,trace)
	check(structure.ok and semantics.ok,"both formal trace validations precede replay/quality conclusion")
	var driver := Replayer.new()
	root.add_child(driver)
	var result: Dictionary = await driver.replay(level,trace,{"mode":0,"max_steps":64,"max_runtime_ms":60000,"step_timeout_ms":5000})
	check(result.status == 0 and result.issues.is_empty() and result.matched_steps == trace.total_actions and result.actual_statekey == trace.goal_statekey,"formal LOGICAL_SESSION matches combined current prefix/recovery witness")
	driver.free()
	var record := {"scenario":label,"provenance":"CURRENT_RUNTIME_CAPTURED_VALIDATED_WITNESS; not original/local Solver trace","trace":trace,"structure":structure,"semantics":semantics,"result":result}
	replays.append(record)
	return record

func local_recovery(label: String) -> bool:
	begin(label+"_local_solver","SOLVER")
	var initial: Dictionary = runtime.get_state()
	var initial_key: String = Key.build(level,initial).key
	var policy := Search.default_policy(0)
	var solved: Dictionary = Solver.solve(level,initial,policy,BUDGET)
	check(solved.status in [0,1,2],"formal local Solver returns bounded analysis, no ERROR")
	check(runtime.get_state() == initial and Key.build(level,runtime.get_state()).key == initial_key,"analysis cannot mutate live Runtime")
	var record := {"scenario":label,"budget":BUDGET,"policy_descriptor":policy.duplicate(true),"initial_actual_state":initial,"initial_actual_key":initial_key,
		"status":solved.status,"budget_reason":solved.budget_reason,"metrics":solved.metrics,"local_graph_complete":solved.graph.complete if solved.graph != null else null,
		"scope":"LOCAL_FIRST_SHORTEST_ONLY; no domain completeness/softlock conclusion","trace":solved.solution_trace}
	record.policy_descriptor.erase("transition_filter")
	searches.append(record)
	write_json(label+"_local_search.json",record)
	if solved.status == 2:
		dependency_pending.append(label+"_LOCAL_SEARCH_BUDGET_INCOMPLETE")
		return false
	check(solved.status == 0 and solved.solution_trace != null,"formal bounded query proves an actual Goal recovery witness")
	if solved.status != 0 or solved.solution_trace == null: return false
	var trace: Dictionary = solved.solution_trace
	var structure: Dictionary = Trace.validate(level,trace)
	var semantics: Dictionary = Trace.validate_semantics(level,trace)
	check(structure.ok and semantics.ok and trace.initial_state == initial and trace.initial_statekey == initial_key,"formal local witness hard validation binds exact rejected Runtime state")
	if not structure.ok or not semantics.ok: return false
	var actions: Array = trace.steps.map(func(step): return step.action)
	follow_recovery(actions,label)
	begin(label+"_recovered_goal","REAL_RUNTIME")
	check(Goal.is_goal(level,runtime.get_state()).is_goal and Key.build(level,runtime.get_state()).key == trace.goal_statekey,"same real Runtime recovers to official local witness Goal without Reset")
	return Goal.is_goal(level,runtime.get_state()).is_goal

func mark_scenario(label: String, first_failure: int, first_pending: int, scope_before: Dictionary, before_error: Dictionary) -> void:
	scenarios.append({"id":label,"status":"FAIL" if failures.size() > first_failure else ("PENDING" if dependency_pending.size() > first_pending else "PASS"),
		"error_state":before_error,"final_state":runtime.get_state(),"final_key":Key.build(level,runtime.get_state()).key,
		"scope_before_error":scope_before,"scope_after_recovery":runtime.get_presentation_scope(),"same_runtime_instance":true})

func run() -> void:
	begin("current_combined_map","UNIT")
	check(DisplayServer.get_name() == "headless","no graphical execution")
	var baked := Maps.bake(&"rubik_spatial_puzzle_01")
	check(baked.ok,"actual current saved author resources through public Baker")
	if not baked.ok: finish();return
	level = baked.level
	template = str_to_var(FileAccess.get_file_as_string(TEMPLATE))
	check(Codec.encode(level).ok and level.content_hash == template.level_hash and Trace.validate(level,template).ok and Trace.validate_semantics(level,template).ok,"unchanged canonical identity and frozen original witness valid")
	write_json("map_identity.json",{"level_hash":level.content_hash,"canonical_text":Codec.encode(level).text,"bake_provenance":baked.get("bake_provenance")})
	var author := Maps.witnesses(&"rubik_spatial_puzzle_01")
	#1: old negatives were tested separately; now recover the same live instance.
	var label := "wrong_face_error_recovery"
	begin(label,"REAL_RUNTIME")
	var first_failure := failures.size()
	var first_pending := dependency_pending.size()
	if fresh() and route(author.wrong_face):
		var wrong: Dictionary = runtime.get_state()
		var scope: Dictionary = runtime.get_presentation_scope()
		check(wrong.player.location.cube_id == &"corner" and wrong.mechanism_states.contact_lock == &"idle" and actual_contact(wrong) != -Geometry.face_frame(wrong.player.location.face).normal,"actual wrong physical contact stays successful MOVE without latch")
		reject({"kind":1},2010,"off-point Gate after wrong face")
		reject({"kind":5,"mechanism_id":&"contact_lock"},1503,"direct USE cannot bypass ENTER lock")
		if local_recovery(label):
			begin(label+"_continuity","REAL_RUNTIME")
			check(runtime.get_presentation_scope() == scope and runtime.get_state().mechanism_states.contact_lock == &"latched","same session/run/generation recovered physical lock without Reset/reload")
			await replay_capture(label)
		mark_scenario(label,first_failure,first_pending,scope,wrong)
	#2: use existing authored Gate route, then actual forbidden Camera/Fall.
	label = "fork_camera_error_recovery"
	begin(label,"REAL_RUNTIME")
	first_failure = failures.size();first_pending = dependency_pending.size()
	if fresh():
		var prefix: Array = author.solution_east.slice(0,5)
		if route(prefix):
			var camera := act({"kind":9,"camera_quadrant":0})
			check(camera.status == 0 and runtime.get_state().player.location.layer == 1,"actual committed Inner Fork with forbidden Camera")
			var wrong: Dictionary = runtime.get_state()
			var scope: Dictionary = runtime.get_presentation_scope()
			reject({"kind":0,"face_axis":2},Fall.CAMERA_NOT_ALLOWED,"forbidden actual Fork view")
			if local_recovery(label):
				begin(label+"_continuity","REAL_RUNTIME")
				check(runtime.get_presentation_scope() == scope,"same rejected Fork Runtime instance/generation reaches Goal")
				await replay_capture(label)
			mark_scenario(label,first_failure,first_pending,scope,wrong)
	#3: exact prior gap: Reset then continue the SAME Runtime, not fresh().
	label = "same_instance_after_reset"
	begin(label,"REAL_RUNTIME")
	first_failure = failures.size();first_pending = dependency_pending.size()
	if fresh() and route(author.solution_east.slice(0,4)):
		var latched: Dictionary = runtime.get_state()
		var scope: Dictionary = runtime.get_presentation_scope()
		check(latched.mechanism_states.contact_lock == &"latched" and latched.player.location == Records.initial_state(level).player.location and latched.player.orientation != Records.initial_state(level).player.orientation,"actual combined OrientationLoop returns to position with changed pose and latched contact")
		verify_reset(label)
		begin(label+"_continued_native_input","REAL_RUNTIME")
		var reset_scope: Dictionary = runtime.get_presentation_scope()
		witness = template.duplicate(true);witness.steps = [];witness.shortest = false
		reject({"kind":1},2011,"same-instance Reset restores locked Gate permission")
		follow_recovery(template.steps.map(func(step):return step.action),label)
		begin(label+"_goal","REAL_RUNTIME")
		check(Goal.is_goal(level,runtime.get_state()).is_goal and reset_scope == runtime.get_presentation_scope() and reset_scope.session_id == scope.session_id and reset_scope.level_run_id == scope.level_run_id and reset_scope.generation == scope.generation+1,"same object accepts new native inputs and reaches Goal after exact Reset")
		reset_same_instance = {"before_reset":latched,"scope_before":scope,"scope_after_reset":reset_scope,"scope_after_goal":runtime.get_presentation_scope(),"actual_goal":runtime.get_state(),"fresh_called_after_reset":false}
		await replay_capture(label)
		mark_scenario(label,first_failure,first_pending,scope,latched)
	if runtime != null:
		runtime.transition_started.disconnect(started)
		runtime.interrupt("UNLOAD")
	write_json("observations.json",{"overall":"PARTIAL","original_goal_terminal":{"states":908,"edges":3916,"goals":96,"softlocks":0,"provenance":"PREVIOUS_FIXED_HASH_REFERENCE_NOT_RERUN"},
		"complete_runtime_denominator":"UNKNOWN","expanded_post_goal_softlocks":"UNKNOWN","new_full_graph":false,"scenarios":scenarios,"local_searches":searches,
		"rejections":rejected,"classifications":classified,"safety_queries":safety_queries,"replays":replays,"same_instance_reset":reset_same_instance,
		"graphical":"NOT_RUN_NO_GUI","human":"NOT_RUN","input_p1":"CLOSED_NOT_REOPENED"})
	finish()
