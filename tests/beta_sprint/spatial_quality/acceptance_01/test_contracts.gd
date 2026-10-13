extends "res://tests/beta_sprint/spatial_quality/suite.gd"
const Maps = preload("res://experiments/spatial_puzzle_batch_01/maps/map_factory.gd")
const Records = preload("res://foundation/contracts/contract_records.gd")
const Explorer = preload("res://foundation/solver/state_explorer.gd")
const Search = preload("res://foundation/solver/search_records.gd")
const Softlock = preload("res://foundation/quality/softlock/softlock_analyzer.gd")
const ReportView = preload("res://tests/beta_sprint/spatial_quality/acceptance_01/report_projection.gd")

func run() -> void:
	begin("incomplete_reporting","UNIT")
	var baked := Maps.bake(&"rubik_spatial_puzzle_01")
	check(baked.ok,"actual current saved combined map bakes")
	if not baked.ok: finish(); return
	var budget := Search.default_budget()
	budget.max_states = 1
	budget.max_runtime_ms = 30000
	var actual := Explorer.explore(baked.level,Records.initial_state(baked.level),Search.default_policy(1),budget)
	check(actual.status == 2 and actual.graph != null and not actual.graph.complete,"actual production max_states1 stops before complete closure")
	if actual.graph == null: finish(); return
	var analyzer := Softlock.analyze(baked.level,actual.graph,{"max_nodes":5000,"max_edges":30000,"max_runtime_ms":30000})
	check(analyzer.status == 1 and analyzer.softlock_count == null,"formal partial graph cannot prove a softlock count")
	var summary := ReportView.summarize(actual.graph,analyzer)
	check(summary.get("domain") == "GOAL_TERMINAL","projection declares the production goal-terminal domain")
	check(summary.get("status") == "INCOMPLETE","partial projection remains incomplete")
	check(summary.has("graph_softlock_count") and summary.graph_softlock_count == null,"partial does not invent zero softlocks")
	check(summary.get("possible_state_denominator") == "UNKNOWN","absolute possible state denominator stays unknown")
	check(summary.get("frontier_count",0) > 0,"real unexpanded frontier survives reporting")
	check(summary.get("reset_is_graph_action",true) == false,"Reset is separate from graph actions")
	rows.append({"budget":budget,"solver_status":actual.status,"solver_metrics":actual.metrics,"analyzer":analyzer,"projection":summary})
	finish()
