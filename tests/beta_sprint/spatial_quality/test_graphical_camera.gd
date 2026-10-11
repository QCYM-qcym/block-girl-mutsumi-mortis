extends "res://tests/beta_sprint/spatial_quality/suite.gd"
## Formal GRAPHICAL Replayer only. No subclass, manual finish, state or actor writes.
const Maps = preload("res://experiments/game_feel_01/maps/map_factory.gd")
const Records = preload("res://foundation/contracts/contract_records.gd")
const Explorer = preload("res://foundation/solver/state_explorer.gd")
const Search = preload("res://foundation/solver/search_records.gd")
const Kernel = preload("res://foundation/rules/puzzle_rule_kernel.gd")
const Rules = preload("res://foundation/rules/rule_records.gd")
const Key = preload("res://foundation/contracts/state_key.gd")
const Trace = preload("res://foundation/solver/solution_trace.gd")
const Replayer = preload("res://foundation/parity/trace_replayer.gd")

func run() -> void:
	begin("legacy.camera_formal","FORMAL_GRAPHICAL")
	for letter in ["a","b"]:
		var baked := Maps.bake_game_feel(Maps.read_spec(letter))
		check(baked.ok,"actual legacy " + letter + " Baker")
		if not baked.ok: continue
		var level: Dictionary = baked.level
		var explored := Explorer.explore(level,Records.initial_state(level),Search.default_policy(1),Search.default_budget())
		check(explored.status == 0 and explored.graph != null and explored.graph.complete,"real original FULL_GRAPH solved")
		if explored.solution_trace == null: continue
		var original: Dictionary = explored.solution_trace
		check(Trace.validate(level,original).ok and Trace.validate_semantics(level,original).ok,"original Solver witness checked")
		# This explicit camera-roundtrip extension is separate from the original Solver trace.
		var extended: Dictionary = original.duplicate(true)
		var state: Dictionary = extended.initial_state.duplicate(true)
		var actions: Array = [{"kind":9,"camera_quadrant":2},{"kind":9,"camera_quadrant":1}]
		for step in original.steps: actions.append(step.action)
		extended.steps = []
		for action in actions:
			var result := Kernel.evaluate_action(level,state,action,Rules.idle_context())
			check(result.status == 0 and result.changed,"formal Camera/Fall/Roll semantic action")
			if result.status != 0 or not result.changed: break
			state = result.next_state
			extended.steps.append({"index":extended.steps.size()+1,"action":action,"expected_state":state,
				"resulting_statekey":Key.build(level,state).key,"global_kind":result.global_kind})
		extended.total_actions = extended.steps.size()
		extended.shortest = false
		check(Trace.validate(level,extended).ok and Trace.validate_semantics(level,extended).ok,"camera extension structurally and semantically revalidated")
		var driver := Replayer.new()
		root.add_child(driver)
		var actual: Dictionary = await driver.replay(level,extended,{"mode":1,"step_timeout_ms":5000})
		check(actual.status == 0 and actual.matched_steps == 4 and actual.actual_statekey == extended.goal_statekey,"actual formal GRAPHICAL Camera Camera Fall Roll 4/4")
		var steps := driver.get_step_evidence()
		check(steps.size() == 4,"all four native completions retained")
		for step in steps:
			check(step.completion_received and step.commit_delta == 1 and step.actual_statekey == step.expected_statekey,"natural completion, one commit and authoritative state parity")
			check(step.transition_identity.has_all(["session_id","level_run_id","generation","transaction_id","is_global"]),"full native transition identity")
			var completion: Dictionary = step.completion_evidence
			check(completion.get("delivered",false) and completion.get("final_statekey") == step.expected_statekey,"bridge delivered current completion")
		rows.append({"map":letter,"original_solver_trace":original,"camera_extension_trace":extended,"formal_graphical":actual,"steps":steps})
		driver.free()
	finish()
