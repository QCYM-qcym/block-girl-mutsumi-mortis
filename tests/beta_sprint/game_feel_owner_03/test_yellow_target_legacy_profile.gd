extends "res://tests/beta_sprint/game_feel_owner_03/test_yellow_target_core.gd"
## Explicit preserved 09 DATA, unchanged public version dispatch, no migration.
const OLD_V1 = {"a":"8c2c341aeca6aae2137b95da95752fd43ef95ffbb40623fc8f77e3cd992997f4","b":"a02ae685981ce0d9735111886dc23738485184f6872804140cdf4cada3b168a1"}
const OLD_V2 = {"a":"f4a5e058ba97ec32edf24116b0a91d6e9196e613ed28fc93d3d71902d4357772","b":"ecbc83dc793ffd9dcbf1ed91f7b1aba647453ac3fd42e1e15dd9469f08dddaf4"}
func run() -> void:
	for letter in ["a","b"]:
		var receipt := Maps.spec("res://tests/beta_sprint/game_feel_owner_09/fixtures/legacy_"+letter+".json")
		var data: Dictionary = receipt.spec # Official fixture wraps unchanged author DATA and origin metadata.
		var old := Maps.bake(data)
		check(old.ok,letter + " actual public schema1 legacy Baker")
		if old.ok:
			check(old.level.schema_version == 1 and old.level.content_hash == OLD_V1[letter] and not old.level.has("perspective_falls"),letter + " exact historical schema1 content hash/shape")
		var baked := Maps.bake_game_feel(data)
		check(baked.ok,letter + " explicit public schema2 legacy profile dispatch")
		if not baked.ok: continue
		var level: Dictionary = baked.level
		check(level.schema_version == 2 and level.contract_version == "foundation.game_feel.v1" and level.rule_version == "foundation.rules.game_feel.v1" and level.content_hash == OLD_V2[letter],letter + " exact historical old profile/content hash")
		check(level.perspective_falls[0].has("path_points2") and not level.perspective_falls[0].has("trajectory"),letter + " old representation never migrated")
		var initial := Records.initial_state(level)
		var explored := Explorer.explore(level,initial,Search.default_policy(1),Search.default_budget())
		check(explored.status == 0 and explored.graph != null and explored.graph.complete and explored.solution_trace != null,letter + " affected legacy FULL_GRAPH solved")
		if explored.solution_trace == null: continue
		var witness: Dictionary = explored.solution_trace
		check(witness.total_actions == 2 and Trace.validate(level,witness).ok and Trace.validate_semantics(level,witness).ok,letter + " old two-action original witness remains valid")
		var driver := Replayer.new()
		root.add_child(driver)
		var result: Dictionary = await driver.replay(level,witness,{"mode":0})
		check(result.status == 0 and result.matched_steps == 2 and result.actual_statekey == witness.goal_statekey,letter + " same candidate explicit legacy LOGICAL_SESSION")
		driver.free()
		rows.append({"map":letter,"level":level,"original_trace":witness,"result":result,"profile":"foundation.game_feel.v1"})
	FileAccess.open(evidence.path_join("report.json"),FileAccess.WRITE).store_string(JSON.stringify({
		"checks":checks,"failures":failures,"doubles":[],"rows":rows,"scope":"LEGACY_FOCUSED_REAL",
		"profile":"LEGACY_EXPLICIT","capture":Capture.snapshot("ACTUAL_LEGACY_PROFILE_DISPATCH"),
		"authority":"Actual production Baker/Explorer/Trace/Replay; preserved official09 author DATA, not new-profile graphics"},"\t"))
	quit(0 if failures.is_empty() else 1)
