extends RefCounted
## Presentation of formal analysis results only; no reachability algorithm.
static func summarize(graph: Dictionary, softlock: Dictionary) -> Dictionary:
	var frontier: Array = []
	var goals := 0
	for key in graph.nodes:
		if not graph.nodes[key].expanded: frontier.append(key)
		if graph.nodes[key].is_goal: goals += 1
	frontier.sort()
	var closed: bool = graph.complete and graph.stop_reason == 0
	var analyzed: bool = softlock.status == 0
	return {"domain":"GOAL_TERMINAL","status":"COMPLETE" if closed and analyzed else "INCOMPLETE",
		"states":graph.nodes.size(),"edges":graph.edges.size(),"goals":goals,
		"frontier_count":frontier.size(),"frontier_keys":frontier,"graph_complete":closed,
		"goal_reachable_count":softlock.goal_reachable_states.size(),
		"graph_softlock_count":softlock.softlock_count if closed and analyzed else null,
		"possible_state_denominator":"UNKNOWN","post_goal_domain":"NOT_ENUMERATED",
		"reachable_coverage_denominator":graph.nodes.size() if closed else "UNKNOWN",
		"reset_is_graph_action":false,"actual_runtime_reset_classification":"NOT_RUN",
		"analyzer_reset_classification":softlock.reset_classification}
