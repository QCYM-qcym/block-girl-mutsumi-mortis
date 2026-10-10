extends "res://tests/beta_sprint/game_feel_owner_03/test_v2_replay_lifecycle.gd"
## Existing native lifecycle recipes execute again on the new original witness.
const Gate = preload("res://tests/beta_sprint/game_feel_owner_03/yellow_target_gate.gd")
func run() -> void:
	if Gate.blocked(self,evidence): return
	check(DisplayServer.get_name() == "Windows", "actual new-profile graphical lifecycle")
	for letter in ["a","b"]:
		var baked: Dictionary = Maps.bake_game_feel(Maps.read_spec(letter))
		check(baked.ok, letter + " new public Baker")
		if not baked.ok: continue
		var level: Dictionary = baked.level
		check(level.schema_version == 3 and level.contract_version == "foundation.game_feel.v2", letter + " new profile only")
		var solved := Solver.solve(level,Records.initial_state(level),Search.default_policy(1),Search.default_budget())
		check(solved.status == 0 and solved.graph != null and solved.graph.complete and solved.solution_trace != null, letter + " actual complete graph original witness")
		if solved.solution_trace == null: continue
		var witness: Dictionary = solved.solution_trace
		check(witness.total_actions == 2 and Trace.validate(level,witness).ok and Trace.validate_semantics(level,witness).ok, letter + " validated two-action original witness")
		for phase in ["FALL","LANDING"]:
			for operation in ["reset","remove_readd","exit","free_active"]:
				await scenario(letter,level,witness,phase,operation)
		await expiry(letter,level,witness)
	FileAccess.open(evidence.path_join("report.json"),FileAccess.WRITE).store_string(JSON.stringify({
		"checks":checks,"failures":failures,"doubles":[],"rows":rows,"scope":"NEW_PROFILE_REAL",
		"profile":"foundation.game_feel.v2","capture":Gate.real_capture("NEW_PROFILE_REAL_RESET_CANCEL_LIFECYCLE"),
		"uncovered_predicates":["new-profile held native WASD and Busy spam require actual integrated input delivery"],
		"authority":"Native R / actual Node lifecycle / real expiry; no simulated completed signal"},"\t"))
	quit(0 if failures.is_empty() else 1)
