extends SceneTree
const Driver = preload("res://foundation/parity/trace_replayer.gd")
const Adapter = preload("res://tests/beta_sprint/game_feel_owner_01/completion_signal_adapter.gd")
const Factory = preload("res://experiments/game_feel_01/maps/map_factory.gd")
const Explorer = preload("res://foundation/solver/state_explorer.gd")
const Search = preload("res://foundation/solver/search_records.gd")
const Records = preload("res://foundation/contracts/contract_records.gd")
class UnitDriver extends "res://foundation/parity/trace_replayer.gd":
	var fault := ""
	func _make_bridge() -> Variant:
		if fault == "missing": return null
		var value = preload("res://tests/beta_sprint/game_feel_owner_01/completion_signal_adapter.gd").new()
		value.fault = fault
		return value
var checks := 0
var failures: Array[String] = []
var observations: Array = []
func check(ok: bool, label: String) -> void:
	checks += 1
	if not ok: failures.append(label)
func _initialize() -> void:
	create_timer(30).timeout.connect(func():printerr("TEST_TIMEOUT");quit(2))
	call_deferred("run")
func run() -> void:
	var baked: Dictionary = Factory.bake_game_feel(Factory.read_spec("a"))
	check(baked.ok,"real registered A/B Baker entry produces the formal level")
	if baked.ok:
		var level: Dictionary = baked.level
		var solved: Dictionary = Explorer.explore(level,Records.initial_state(level),Search.default_policy(1),Search.default_budget())
		check(solved.status == 0 and solved.solution_trace.total_actions == 2,"real complete Solver supplies Fall then Roll trace")
		if solved.solution_trace != null:
			for fault in ["","duplicate","never","commit_only","foreign_only","generation_only","early","cancel","reset","unload","bind","missing"]:
				var replay := UnitDriver.new()
				replay.fault = fault
				root.add_child(replay)
				var result: Dictionary = await replay.replay(level,solved.solution_trace,{"mode":1,"step_timeout_ms":1000})
				observations.append({"fault":fault,"result":result,"steps":replay._step_evidence.duplicate(true)})
				if fault in ["","duplicate"]:
					var visible: Array = replay.call("get_step_evidence") if replay.has_method("get_step_evidence") else []
					check(visible.size() == 2 and visible.is_read_only() and visible[0].is_read_only() and visible[0].actual_state.is_read_only(),"formal consumer receives immutable full-state step evidence: "+fault)
					check(result.status == 0 and result.matched_steps == 2 and result.actual_statekey == solved.solution_trace.goal_statekey,"matching completion alone admits exact two-step endpoint: "+fault)
					check(replay._step_evidence.size() == 2 and replay._step_evidence.all(func(s):return s.commit_delta == 1 and s.commit_signals == 1),"foreign/old/duplicate completions cannot add a commit: "+fault)
					check(replay._step_evidence.all(func(s):return s.completion_received and s.completion_evidence.fixture_kind == "UNIT_COMPLETION_SIGNAL_ADAPTER" and s.get("bridge_snapshot",{}).get("natural_motion",true) == false),"evidence binds completion signal and actual Bridge snapshot: "+fault)
				elif fault in ["never","commit_only","foreign_only","generation_only"]:
					check(result.status == 3 and result.matched_steps == 0,"missing completion reaches approved timeout as INCOMPLETE")
					if fault != "never": check(replay._step_evidence[0].commit_delta == 1 and not replay._step_evidence[0].completion_received,"a logical commit or foreign callback alone cannot count as graphical completion: "+fault)
				elif fault == "early":
					check(result.status == 1 and result.matched_steps == 0,"completion before actual authoritative commit cannot pass")
				else:
					check(result.status == 2 and result.matched_steps == 0,"cancel/reset/unload/bind/dependency failures never complete a step: "+fault)
					if fault == "missing": check(result.issues[0].message.begins_with("CASE_DEPENDENCY_PENDING:"),"actual absent Bridge remains fail-closed")
				replay.free()
			var closed := UnitDriver.new()
			root.add_child(closed)
			var invalid: Dictionary = await closed.replay(level,solved.solution_trace,{"mode":1,"bridge":"test"})
			check(invalid.status == 2 and invalid.issues[0].path == "options.bridge","public options cannot choose a replacement Bridge")
			closed.free()
	var summary := {"checks":checks,"failures":failures,"doubles":["UNIT_COMPLETION_SIGNAL_ADAPTER"],"authority":"real formal Facade/Kernel/Replay/Solver; controlled signal completion only","observations":observations}
	FileAccess.open(OS.get_environment("FOUNDATION_TEST_EVIDENCE").path_join("results.json"),FileAccess.WRITE).store_string(JSON.stringify(summary))
	print("BRIDGE_UNIT checks=",checks," failures=",failures)
	quit(0 if failures.is_empty() else 1)
