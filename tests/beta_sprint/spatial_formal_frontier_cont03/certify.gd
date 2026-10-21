extends "res://tests/beta_sprint/spatial_formal_state_cont02/graph.gd"
## One separate live-Explorer certification attempt after actual continuation.
## No restored/assembled graph is passed off as Explorer output.
func run() -> void:
	begin("S05_LIVE_EXPLORER_CERTIFICATION","PUBLIC_EXPLORER_AND_SOFTLOCK")
	check(DisplayServer.get_name()=="headless","headless only")
	var baked: Dictionary=Maps.bake(&"rubik_spatial_puzzle_01")
	check(baked.ok,"same official S05 bake")
	if not baked.ok: finish(); return
	var level: Dictionary=baked.level
	var budget := {"max_states":2500,"max_edges":15000,"max_depth":-1,"max_runtime_ms":580000,"max_action_evaluations":30000}
	var explored: Dictionary=Explorer.explore(level,Records.initial_state(level),Search.default_policy(1),budget)
	save("explorer.json",explored)
	check(explored.status!=3,"public live Explorer no ERROR")
	if explored.graph==null: dependency_pending.append("NO_LIVE_GRAPH"); finish(); return
	var original: Dictionary=explored.graph.duplicate(true)
	var soft: Dictionary=Softlock.analyze(level,explored.graph,{"max_nodes":2500,"max_edges":15000,"max_runtime_ms":60000})
	save("softlock.json",soft)
	check(original==explored.graph,"same unchanged live graph supplied to public Analyzer")
	var census: Dictionary=inspect(level,explored.graph)
	check(census.violations.is_empty() and census.goal_island_nonfall_entries==0,"live graph permission/shortcut invariants")
	if explored.graph.complete and soft.status==0: check(soft.softlock_count==0,"complete live Goal-terminal graph has zero Goal softlocks")
	else: dependency_pending.append("LIVE_EXPLORER_OR_ANALYZER_INCOMPLETE")
	save("summary.json",{"level_hash":level.content_hash,"state_graph":"PASS" if explored.graph.complete and soft.status==0 and failures.is_empty() else "PARTIAL","scope":"LIVE_EXPLORER_GOAL_TERMINAL_STABLE_PUBLIC_ACTIONS","budget":budget,"solver_status":explored.status,"budget_reason":explored.budget_reason,"metrics":explored.metrics,"census":census,"graph_complete":explored.graph.complete,"softlock_status":soft.status,"softlock_count":soft.softlock_count,"goal_reachable_count":soft.goal_reachable_states.size(),"unknown_states":soft.unknown_states.size(),"reset_recoverable_count":soft.reset_recoverable_count})
	finish()
