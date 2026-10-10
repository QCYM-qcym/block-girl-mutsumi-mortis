extends "res://tests/beta_sprint/game_feel_owner_03/test_v2_graphical_trace.gd"
## Reuses endpoint/identity assertions only; new witness and all observations are fresh.
const Gate = preload("res://tests/beta_sprint/game_feel_owner_03/yellow_target_gate.gd")
const Key = preload("res://foundation/contracts/state_key.gd")
const Kernel = preload("res://foundation/rules/puzzle_rule_kernel.gd")
const Rules = preload("res://foundation/rules/rule_records.gd")

func run() -> void:
	if Gate.blocked(self,evidence): return
	check(DisplayServer.get_name() == "Windows", "new curve actual graphical renderer")
	for letter in ["a","b"]:
		var baked: Dictionary = Maps.bake_game_feel(Maps.read_spec(letter))
		check(baked.ok, letter + " public new schema3 Baker")
		if not baked.ok: continue
		var level: Dictionary = baked.level
		check(level.schema_version == 3 and level.contract_version == "foundation.game_feel.v2", letter + " no old profile acceptance")
		var solved := Solver.solve(level,Records.initial_state(level),Search.default_policy(1),Search.default_budget())
		check(solved.status == 0 and solved.graph != null and solved.graph.complete and solved.solution_trace != null, letter + " same original production FULL_GRAPH witness")
		if solved.solution_trace == null: continue
		var witness: Dictionary = solved.solution_trace
		check(Trace.validate(level,witness).ok and Trace.validate_semantics(level,witness).ok, letter + " original witness semantic validation")
		check(witness.total_actions == 2 and witness.steps.size() == 2 and witness.steps[0].expected_state.player.location.cube_id == &"target" and witness.steps[1].expected_state.player.location.cube_id == &"exit", letter + " two actual original actions")
		# Formal reference Gameplay only. The legacy Pixel rendering stack does
		# not support schema3 and must never be inferred from mode0 or this query.
		var reference_state: Dictionary = witness.initial_state.duplicate(true)
		var reference_steps: Array = []
		for expected_step in witness.steps:
			var reference: Dictionary = Kernel.evaluate_action(level,reference_state,expected_step.action,Rules.idle_context())
			check(reference.status == 0 and reference.changed and reference.next_state != null, letter + " formal reference Gameplay action applied")
			if reference.next_state == null: break
			reference_state = reference.next_state
			reference_steps.append({"action":expected_step.action,"state":reference_state.duplicate(true),"statekey":Key.build(level,reference_state).key})
		var driver := Replayer.new()
		root.add_child(driver)
		var previous: Array = []
		for repeat in 2:
			var result: Dictionary = await driver.replay(level,witness,{"mode":1})
			check(result.status == 0 and result.matched_steps == 2 and result.actual_statekey == witness.goal_statekey, letter + " new-profile FORMAL_GRAPHICAL MATCH")
			var steps: Array = driver.get_step_evidence()
			check(steps.size() == 2, letter + " actual public original step evidence")
			for index in mini(steps.size(),2):
				verify_step(level,witness,steps[index],index,letter + " curve repeat " + str(repeat))
				check(index < reference_steps.size(), letter + " corresponding actual formal reference step exists")
				if index < reference_steps.size():
					check(steps[index].actual_statekey == reference_steps[index].statekey and steps[index].completion_evidence.get("final_state") == reference_steps[index].state, letter + " full seven-field reference Gameplay versus actual3D state/key")
				if repeat == 1 and index < previous.size():
					check(previous[index].actual_statekey == steps[index].actual_statekey and previous[index].transition_identity != steps[index].transition_identity, letter + " repeat stable state fresh native identity")
			rows.append({"map":letter,"repeat":repeat,"level":level,"level_hash":level.content_hash,"original_trace":witness,"result":result,"steps":steps,"mode":"FORMAL_GRAPHICAL",
				"reference_mode":"FORMAL_KERNEL_GAMEPLAY","reference_steps":reference_steps,"pixel_rendering":"NOT_RUN_UNSUPPORTED_SCHEMA3_PIXEL_STACK"})
			previous = steps
		driver.free()
	FileAccess.open(evidence.path_join("report.json"),FileAccess.WRITE).store_string(JSON.stringify({
		"checks":checks,"failures":failures,"doubles":[],"rows":rows,"scope":"NEW_PROFILE_REAL",
		"profile":"foundation.game_feel.v2","capture":Gate.real_capture("NEW_PROFILE_FORMAL_GRAPHICAL"),
		"natural_six_phase":"PENDING_OWNER00_SEPARATE_EVIDENCE",
		"authority":"Sole production Replayer mode1; no override, fake completion, manual native finish or old receipt"},"\t"))
	quit(0 if failures.is_empty() else 1)
