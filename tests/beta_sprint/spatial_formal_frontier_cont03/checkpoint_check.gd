extends "res://tests/beta_sprint/spatial_quality/suite.gd"
## Read-only typed checkpoint round-trip admission check, no state exploration.
const Maps = preload("res://experiments/spatial_puzzle_batch_01/maps/map_factory.gd")
const Graph = preload("res://foundation/solver/state_graph.gd")
func run() -> void:
	begin("TYPED_CHECKPOINT_RECOVERY","PUBLIC_GRAPH_STRUCTURAL_VALIDATION")
	var path := ""
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--checkpoint="): path=arg.trim_prefix("--checkpoint=")
	check(DisplayServer.get_name()=="headless","headless only")
	var typed: Dictionary=FileAccess.open(path,FileAccess.READ).get_var()
	var wire: Dictionary=JSON.parse_string(FileAccess.get_file_as_string(path.trim_suffix(".bin")+".json"))
	var baked: Dictionary=Maps.bake(&"rubik_spatial_puzzle_01")
	check(baked.ok,"same official baked level")
	var admitted: Dictionary=Graph.validate(baked.level,typed.graph)
	var rejected: Dictionary=Graph.validate(baked.level,wire.graph)
	check(admitted.ok,"binary checkpoint preserves public Graph required types")
	check(not rejected.ok,"raw JSON alone is not public Graph admission")
	check(JSON.parse_string(JSON.stringify(typed))==wire,"typed checkpoint and JSON contain identical wire evidence")
	var pending: Array=[]
	for key in typed.graph.nodes:
		var node: Dictionary=typed.graph.nodes[key]
		if not node.expanded and not node.is_goal: pending.append(key)
	check(pending.size()==typed.queue.size(),"persisted queue count matches nonterminal frontier")
	for key in pending: check(key in typed.queue,"persisted frontier identity")
	rows.append({"checkpoint":path,"typed_admission":admitted,"raw_json_admission":rejected,"pending":pending.size(),"provenance":"STRUCTURAL_ONLY_NOT_LIVE_EXPLORER"})
	finish()
