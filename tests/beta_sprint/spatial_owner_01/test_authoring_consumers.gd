extends SceneTree
## Selected public consumers of the actual saved resources, not a second level factory.
const Maps = preload("res://experiments/spatial_puzzle_batch_01/maps/map_factory.gd")
const Records = preload("res://foundation/contracts/contract_records.gd")
const Key = preload("res://foundation/contracts/state_key.gd")
const Codec = preload("res://foundation/level/level_codec.gd")
const Safety = preload("res://foundation/validation/safety_queries.gd")
const Explorer = preload("res://foundation/solver/state_explorer.gd")
const Search = preload("res://foundation/solver/search_records.gd")
const Trace = preload("res://foundation/solver/solution_trace.gd")
const Replayer = preload("res://foundation/parity/trace_replayer.gd")
var checks := 0
var failures: Array[String] = []
var rows: Array[Dictionary] = []

func check(ok: bool, label: String) -> void:
	checks += 1
	if not ok: failures.append(label)

func _initialize() -> void:
	create_timer(60).timeout.connect(func(): printerr("AUTHORING_CONSUMERS_TIMEOUT"); quit(2))
	call_deferred("run")

func run() -> void:
	for id in Maps.ids():
		var baked: Dictionary = Maps.bake(id)
		check(baked.ok, String(id) + " saved Projector/Assembler/Adapter/Reader/Baker")
		if not baked.ok: continue
		var level: Dictionary = baked.level
		var golden: Dictionary = str_to_var(FileAccess.get_file_as_string("res://tests/beta_sprint/spatial_owner_09/migration_baseline/" + String(id) + ".gdvar"))
		check(level == golden.level, String(id) + " immutable complete canonical and hash")
		var encoded: Dictionary = Codec.encode(level)
		check(encoded.ok, String(id) + " formal Codec accepts saved canonical")
		var initial: Dictionary = Records.initial_state(level)
		var safe: Dictionary = Safety.validate_state(level, initial)
		check(safe.status == 0, String(id) + " formal initial Safety")
		var row := {"level_id":id, "schema_version":level.schema_version, "contract_version":level.contract_version,
			"rule_version":level.rule_version, "content_hash":level.content_hash,
			"initial_statekey":Key.build(level, initial).key, "initial_safety":safe,
			"canonical_equal":level == golden.level}
		rows.append(row)
		if id in [&"world_shift_gate_lab", &"perspective_fork_lab"]:
			await _consumers(level, initial, row)
	FileAccess.open(OS.get_environment("FOUNDATION_TEST_EVIDENCE").path_join("report.json"), FileAccess.WRITE).store_string(JSON.stringify({"checks":checks,"failures":failures,"doubles":[],"rows":rows}, "\t"))
	print("AUTHORING_CONSUMERS checks=",checks," failures=",failures," doubles=[]")
	quit(0 if failures.is_empty() else 1)

func _consumers(level: Dictionary, initial: Dictionary, row: Dictionary) -> void:
	var budget: Dictionary = Search.default_budget()
	budget.max_runtime_ms = 20000
	var result: Dictionary = Explorer.explore(level, initial, Search.default_policy(0), budget)
	check(result.status == 0 and result.solution_trace != null, String(level.level_id) + " real FIRST_SHORTEST Solver")
	row["search_status"] = result.status
	row["search_metrics"] = result.metrics
	if result.status != 0 or result.solution_trace == null: return
	var trace: Dictionary = result.solution_trace
	var semantics: Dictionary = Trace.validate_semantics(level, trace)
	check(semantics.ok, String(level.level_id) + " real trace Kernel semantic validation")
	row["trace"] = trace
	row["trace_semantics"] = semantics.ok
	if not semantics.ok: return
	var state: Dictionary = initial
	var safety_rows: Array[Dictionary] = []
	for transition in semantics.transitions:
		var safe: Dictionary = Safety.validate_state(level, transition.next_state)
		check(safe.status == 0, String(level.level_id) + " formal trace endpoint Safety")
		if level.level_id == &"world_shift_gate_lab" and transition.action.kind == 1:
			var shift: Dictionary = Safety.validate_motion(level, state, transition.next_state, transition.action)
			check(shift.status == 0, "saved Gate real World Shift Safety")
			safety_rows.append({"kind":"SHIFT", "result":shift})
		if level.level_id == &"perspective_fork_lab" and transition.action.kind == 0 and transition.next_state.player.orientation == state.player.orientation:
			for connection in level.perspective_falls:
				if connection.source_face_id == StringName(String(state.player.location.cube_id) + "/TOP") and connection.target_face_id == StringName(String(transition.next_state.player.location.cube_id) + "/TOP"):
					var fall: Dictionary = Safety.validate_perspective_motion(level, state, transition.next_state, connection.connection_id)
					check(fall.status == 0, "saved Fork real directed cubic sweep Safety")
					safety_rows.append({"kind":"FALL", "connection_id":connection.connection_id, "result":fall})
		state = transition.next_state
	check(not safety_rows.is_empty(), String(level.level_id) + " selected actual motion Safety invoked")
	row["motion_safety"] = safety_rows
	var driver := Replayer.new()
	root.add_child(driver)
	var first: Dictionary = await driver.replay(level, trace, {"mode":0, "max_runtime_ms":20000})
	var second: Dictionary = await driver.replay(level, trace, {"mode":0, "max_runtime_ms":20000})
	check(first.status == 0 and first.matched_steps == trace.total_actions and first.actual_statekey == trace.goal_statekey, String(level.level_id) + " real logical Session Replay MATCH")
	check(second.status == 0 and second.matched_steps == trace.total_actions and second.actual_statekey == first.actual_statekey, String(level.level_id) + " repeat Replay canonical determinism")
	row["replays"] = [first, second]
	driver.free()
