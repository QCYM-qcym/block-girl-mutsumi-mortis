extends "res://tests/beta_sprint/spatial_formal_state_cont02/graph.gd"
## Test-only queue/checkpoint orchestration. Every transition is the formal Kernel.
## Reconstituted graphs are not live Explorer provenance and remain incomplete.
const Actions = preload("res://foundation/solver/action_generator.gd")
const Kernel = preload("res://foundation/rules/puzzle_rule_kernel.gd")
const Rules = preload("res://foundation/rules/rule_records.gd")
const Replayer = preload("res://foundation/parity/trace_replayer.gd")
const Graph = preload("res://foundation/solver/state_graph.gd")
var graph: Dictionary = {}
var queue: Array = []
var initial_frontiers: Array = []
var outcomes: Array = []
var attempts: Array = []
var clock_start: int
var restored := 0
var cursor := 0
var checkpoint_serial := 0
var action_cache: Dictionary = {}
var level_data: Dictionary = {}

func candidates(key: String) -> Array:
	if not action_cache.has(key):
		var generated: Dictionary = Actions.generate(level_data,graph.nodes[key].state)
		check(generated.ok, "formal action generation")
		action_cache[key] = generated.actions
	return action_cache[key]

func canonical_action(key: String, wire: Dictionary) -> Dictionary:
	for candidate in candidates(key):
		if JSON.parse_string(JSON.stringify(candidate)) == wire: return candidate.duplicate(true)
	check(false, "saved action exists in formal generator")
	return {}

func checkpoint(label: String) -> void:
	checkpoint_serial += 1
	var pending: Array = queue.slice(cursor)
	var snapshot := {"schema":"cont04.checkpoint.v1","provenance":"TEST_ORCHESTRATED_FORMAL_KERNEL","graph":graph,"queue":pending,"initial_frontiers":initial_frontiers,"outcomes":outcomes,"restored":restored,"elapsed_ms":Time.get_ticks_msec()-clock_start}
	var name := "checkpoint_%03d_%s" % [checkpoint_serial,label]
	FileAccess.open(evidence.path_join(name+".bin"),FileAccess.WRITE).store_var(snapshot)
	save(name+".json",snapshot)
	save("progress.json",{"checkpoint":name,"states":graph.nodes.size(),"edges":graph.edges.size(),"expanded":outcomes.size(),"remaining":pending.size(),"restored":restored,"elapsed_ms":snapshot.elapsed_ms})
	print(JSON.stringify({"checkpoint":name,"states":graph.nodes.size(),"edges":graph.edges.size(),"expanded":outcomes.size(),"remaining":pending.size()}))

func recover(raw: Dictionary) -> bool:
	var descriptor: Dictionary = Search.default_policy(1)
	descriptor.erase("transition_filter")
	check(JSON.parse_string(JSON.stringify(descriptor))==raw.policy_descriptor, "saved public policy unchanged")
	graph = {"graph_version":"stategraph.v1","level_hash":level_data.content_hash,"rule_version":level_data.rule_version,"initial_key":raw.initial_key,"policy_descriptor":descriptor,"nodes":{},"edges":[],"forward":{},"reverse":{},"complete":false,"stop_reason":2}
	var keys: Array = raw.nodes.keys()
	keys.sort_custom(func(a,b): return int(raw.nodes[a].depth)<int(raw.nodes[b].depth) if raw.nodes[a].depth!=raw.nodes[b].depth else int(raw.nodes[a].get("predecessor_edge",-1))<int(raw.nodes[b].get("predecessor_edge",-1)))
	for key in keys:
		var old: Dictionary = raw.nodes[key]
		var state: Dictionary
		if key==raw.initial_key: state=Records.initial_state(level_data)
		else:
			var edge: Dictionary = raw.edges[int(old.predecessor_edge)]
			var action: Dictionary = canonical_action(edge.from_key,edge.action)
			var result: Dictionary = Kernel.evaluate_action(level_data,graph.nodes[edge.from_key].state,action,Rules.idle_context())
			check(result.status==0 and result.changed and result.global_kind==int(edge.global_kind), "predecessor replay applies saved formal transition")
			if result.status!=0: return false
			state=result.next_state
		var identity: Dictionary = Key.build(level_data,state)
		check(identity.ok and identity.key==key and JSON.parse_string(JSON.stringify(state))==old.state, "restored typed full state and StateKey match saved node")
		var goal: Dictionary = Goal.is_goal(level_data,state)
		check(goal.ok and goal.is_goal==old.is_goal, "restored formal Goal marker")
		if not failures.is_empty(): return false
		graph.nodes[key]={"state_key":key,"state":state,"depth":int(old.depth),"is_goal":old.is_goal,"expanded":old.expanded,"predecessor_edge":null if old.predecessor_edge==null else int(old.predecessor_edge)}
		graph.forward[key]=[]
		graph.reverse[key]=[]
		restored+=1
		if not old.expanded and not old.is_goal: initial_frontiers.append(key)
	for old in raw.edges:
		var edge := {"edge_id":int(old.edge_id),"from_key":old.from_key,"to_key":old.to_key,"action":canonical_action(old.from_key,old.action),"global_kind":int(old.global_kind)}
		graph.edges.append(edge)
		graph.forward[edge.from_key].append(edge.edge_id)
		graph.reverse[edge.to_key].append(edge.edge_id)
	queue=initial_frontiers.duplicate()
	check(graph.nodes.size()==785 and graph.edges.size()==3328 and queue.size()==17, "verified exact continuation03 native certification counts")
	var validation: Dictionary = Graph.validate(level_data,graph)
	save("restored_structural_validation.json",validation)
	check(validation.ok, "public Graph validates restored typed structure only")
	checkpoint("restored")
	return failures.is_empty()

func expand_one(key: String) -> void:
	var node: Dictionary=graph.nodes[key]
	var before_states: int=graph.nodes.size()
	var before_edges: int=graph.edges.size()
	var per: Array=[]
	for action in candidates(key):
		var result: Dictionary=Kernel.evaluate_action(level_data,node.state,action,Rules.idle_context())
		var record := {"action":action,"status":result.status,"changed":result.changed,"rejection_code":result.rejection_code,"issues":result.issues,"global_kind":result.global_kind,"to_key":null,"edge_id":null,"previously_saved":false}
		check(result.status in [0,1], "frontier formal Kernel no ERROR")
		if result.status==0 and result.changed:
			var identity: Dictionary=Key.build(level_data,result.next_state)
			check(identity.ok and identity.key!=key,"successor full StateKey")
			var terminal: Dictionary=Goal.is_goal(level_data,result.next_state)
			check(terminal.ok,"successor formal Goal")
			var found: int=-1
			for edge_id in graph.forward[key]:
				if graph.edges[edge_id].action==action: found=edge_id; break
			if found>=0:
				check(graph.edges[found].to_key==identity.key and graph.edges[found].global_kind==result.global_kind,"partially expanded saved edge exactly replayed")
				record.previously_saved=true
			else:
				found=graph.edges.size()
				if not graph.nodes.has(identity.key):
					graph.nodes[identity.key]={"state_key":identity.key,"state":result.next_state.duplicate(true),"depth":node.depth+1,"is_goal":terminal.is_goal,"expanded":terminal.is_goal,"predecessor_edge":found}
					graph.forward[identity.key]=[]
					graph.reverse[identity.key]=[]
					if not terminal.is_goal: queue.append(identity.key)
				graph.edges.append({"edge_id":found,"from_key":key,"to_key":identity.key,"action":action.duplicate(true),"global_kind":result.global_kind})
				graph.forward[key].append(found)
				graph.reverse[identity.key].append(found)
			record.to_key=identity.key
			record.edge_id=found
		per.append(record)
		if not failures.is_empty(): break
	if failures.is_empty(): node.expanded=true
	outcomes.append({"state_key":key,"initial_frontier":key in initial_frontiers,"expanded":node.expanded,"new_states":graph.nodes.size()-before_states,"new_edges":graph.edges.size()-before_edges,"actions":per,"elapsed_ms":Time.get_ticks_msec()-clock_start})

func run() -> void:
	clock_start=Time.get_ticks_msec()
	begin("S05_NATIVE17_FRONTIER_CONT04","FORMAL_KERNEL_TEST_ORCHESTRATION")
	check(DisplayServer.get_name()=="headless","headless only")
	var previous: String=""
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--prior="): previous=arg.trim_prefix("--prior=")
	var baked: Dictionary=Maps.bake(&"rubik_spatial_puzzle_01")
	check(baked.ok,"saved S05 bake")
	if not baked.ok: finish(); return
	level_data=baked.level
	var old: Dictionary=JSON.parse_string(FileAccess.get_file_as_string(previous))
	check(old.graph.level_hash==level_data.content_hash,"same saved level hash")
	if not recover(old.graph): finish(); return
	var recovery_ms: int=Time.get_ticks_msec()-clock_start
	# Phase 1 keeps all original frontiers before any new successor. Finish each
	# node atomically; checkpoint every eight nodes and at the phase boundary.
	while cursor<queue.size() and failures.is_empty() and Time.get_ticks_msec()-clock_start<360000:
		expand_one(queue[cursor])
		cursor+=1
		if cursor%8==0: checkpoint("expand")
		if cursor==initial_frontiers.size(): checkpoint("initial_frontiers_done")
		if graph.nodes.size()>=2500 or graph.edges.size()>=15000: break
	checkpoint("search_end")
	var search_ms: int=Time.get_ticks_msec()-clock_start
	var validation: Dictionary=Graph.validate(level_data,graph)
	save("final_structural_validation.json",validation)
	check(validation.ok,"public Graph validates resumed structure only")
	var soft: Dictionary=Softlock.analyze(level_data,graph,{"max_nodes":2500,"max_edges":15000,"max_runtime_ms":30000})
	save("softlock_observation.json",soft)
	var census: Dictionary=inspect(level_data,graph)
	check(census.violations.is_empty() and census.goal_island_nonfall_entries==0,"continued edge permission and shortcut invariants")
	var focused: Dictionary = mechanic_audit()
	save("focused_mechanics.json",focused)
	# A fresh bounded spawn search produces its own legitimate live trace.
	# Its FIRST_SHORTEST stop never certifies full graph closure.
	var live: Dictionary=Explorer.explore(level_data,Records.initial_state(level_data),Search.default_policy(0),{"max_states":2500,"max_edges":15000,"max_depth":-1,"max_runtime_ms":90000,"max_action_evaluations":30000})
	save("live_spawn_explorer.json",live)
	check(live.status!=3,"fresh public spawn Explorer no ERROR")
	var replay_result: Dictionary={"status":"NOT_RUN_NO_LIVE_TRACE"}
	if live.solution_trace!=null:
		var semantic: Dictionary=Trace.validate_semantics(level_data,live.solution_trace)
		save("live_spawn_trace_semantics.json",semantic)
		check(semantic.ok,"fresh spawn live trace formal semantics")
		var driver = Replayer.new()
		root.add_child(driver)
		replay_result=await driver.replay(level_data,live.solution_trace,{"mode":0,"max_steps":64,"max_runtime_ms":20000,"step_timeout_ms":5000})
		save("live_spawn_replay.json",replay_result)
		check(replay_result.status==0,"fresh live spawn trace public LOGICAL_SESSION Replay")
		driver.queue_free()
	# Native Runtime replays the recorded predecessor path for a new deepest
	# state, then Reset proves exact canonical recovery for this sampled state.
	var native_target: String=queue[-1] if not queue.is_empty() else initial_frontiers[-1]
	var path: Array=[]
	var walking: String=native_target
	while walking!=graph.initial_key:
		var edge: Dictionary=graph.edges[graph.nodes[walking].predecessor_edge]
		path.push_front(edge)
		walking=edge.from_key
	runtime=Facade.new()
	runtime.transition_started.connect(started)
	check(runtime.load_level(level_data).ok,"native Runtime load")
	for edge in path: act(level_data,edge.action,edge.to_key)
	runtime.reset()
	check(Key.build(level_data,runtime.get_state()).key==graph.initial_key and runtime.get_commit_count()==0 and runtime.is_idle(),"native new-state Reset restores exact initial state")
	save("native_reset.json",{"target":native_target,"steps":path.size(),"rows":rows,"reset_key":Key.build(level_data,runtime.get_state()).key})
	runtime.interrupt("UNLOAD")
	result_row={"state_graph":"PARTIAL","provenance":"TEST_ORCHESTRATED_FORMAL_KERNEL_NOT_LIVE_EXPLORER","initial_states":785,"initial_edges":3328,"initial_frontiers":17,"new_states":graph.nodes.size()-785,"new_edges":graph.edges.size()-3328,"initial_frontiers_expanded":mini(cursor,17),"expanded_frontiers":cursor,"remaining_frontiers":queue.size()-cursor,"queue_exhausted":cursor==queue.size(),"recovery_ms":recovery_ms,"search_end_ms":search_ms,"elapsed_ms":Time.get_ticks_msec()-clock_start,"search_deadline_ms":360000,"stop_reason":"QUEUE_EXHAUSTED" if cursor==queue.size() else "TIME_OR_CAPACITY_BUDGET","census":census,"softlock_status":soft.status,"goal_reachable_count":soft.goal_reachable_states.size(),"unknown_states":soft.unknown_states.size(),"softlock_count":soft.softlock_count,"native_reset_sample_steps":path.size(),"live_spawn_explorer_status":live.status,"live_spawn_witness":live.solution_trace!=null,"live_replay_status":replay_result.status,"focused_mechanics":focused,"structural_validation":validation.ok,"level_hash":level_data.content_hash}
	save("frontier_outcomes.json",outcomes)
	save("summary.json",result_row)
	dependency_pending.append("RESUMED_TEST_GRAPH_HAS_NO_LIVE_EXPLORER_COMPLETENESS_PROVENANCE")
	finish()

func mechanic_audit() -> Dictionary:
	var found := {"correct_lock_arrivals":0,"wrong_lock_arrivals":0,"fall_then_roll_samples":0,"fork_overlap":[],"shift_offpoint_rejections":0,"shift_locked_rejections":0}
	var lock: Dictionary=level_data.face_locks[0]
	var mechanism: Dictionary=level_data.mechanisms.filter(func(m):return m.mechanism_id==lock.mechanism_id)[0]
	var fall_sampled := false
	for edge in graph.edges:
		var a: Dictionary=graph.nodes[edge.from_key].state
		var b: Dictionary=graph.nodes[edge.to_key].state
		if edge.action.kind==0 and a.mechanism_states[lock.mechanism_id]!=lock.latched_state and Geometry.face_id(a.player.location.cube_id,a.player.location.face)!=mechanism.face_id and Geometry.face_id(b.player.location.cube_id,b.player.location.face)==mechanism.face_id:
			var snap: Dictionary=Geometry.snapshot(level_data,b)
			var anchor: Dictionary=snap.value.anchors.filter(func(v):return v.face_id==mechanism.face_id)[0]
			var correct: bool=Orientation.apply(b.player.orientation,Geometry.face_frame(lock.required_local_face).normal)==-anchor.frame.normal
			check((b.mechanism_states[lock.mechanism_id]==lock.latched_state)==correct,"correct/wrong FaceLock arrival orientation exact")
			found["correct_lock_arrivals" if correct else "wrong_lock_arrivals"]+=1
		if not fall_sampled and edge.action.kind in [0,8] and not Fall.motion(level_data,a,b,edge.action).is_empty():
			for next_id in graph.forward[edge.to_key]:
				var roll: Dictionary=graph.edges[next_id]
				var c: Dictionary=graph.nodes[roll.to_key].state
				if roll.action.kind==0 and Fall.motion(level_data,b,c,roll.action).is_empty():
					var actual: Dictionary=Kernel.evaluate_action(level_data,b,roll.action,Rules.idle_context())
					check(actual.status==0 and actual.changed and actual.next_state==c and c.player.orientation!=b.player.orientation,"post-Fall ordinary Roll uses formal target and rotation")
					found.fall_then_roll_samples+=1
					fall_sampled=true
					break
	for i in level_data.perspective_falls.size():
		for j in range(i+1,level_data.perspective_falls.size()):
			var a: Dictionary=level_data.perspective_falls[i]
			var b: Dictionary=level_data.perspective_falls[j]
			if a.source_face_id!=b.source_face_id or a.source_edge!=b.source_edge: continue
			for camera in a.allowed_camera_quadrants:
				for world in a.allowed_world_orientations:
					if camera in b.allowed_camera_quadrants and world in b.allowed_world_orientations: found.fork_overlap.append([a.connection_id,b.connection_id,camera,world])
	for key in graph.nodes:
		if found.shift_offpoint_rejections>0 and found.shift_locked_rejections>0: break
		var state: Dictionary=graph.nodes[key].state
		var source=Geometry.face_id(state.player.location.cube_id,state.player.location.face)
		var gates: Array=level_data.shift_gates.filter(func(g):return g.source_face_id==source)
		var offpoint: bool=gates.is_empty()
		var locked := false
		if not offpoint:
			for requirement in gates[0].required_mechanism_states:
				if state.mechanism_states[requirement.mechanism_id]!=requirement.state: locked=true
		if (offpoint and found.shift_offpoint_rejections==0) or (locked and found.shift_locked_rejections==0):
			var denied: Dictionary=Kernel.evaluate_action(level_data,state,{"kind":1},Rules.idle_context())
			check(denied.status==1 and denied.rejection_code==(2010 if offpoint else 2011),"formal Shift exact offpoint/locked rejection")
			found["shift_offpoint_rejections" if offpoint else "shift_locked_rejections"]+=1
	check(found.correct_lock_arrivals>0 and found.wrong_lock_arrivals>0,"both FaceLock orientations observed")
	check(found.fork_overlap.is_empty(),"Fork authored camera/world permission cells unique")
	check(found.fall_then_roll_samples>0,"Fall target followed by actual Roll sampled")
	check(found.shift_offpoint_rejections>0 and found.shift_locked_rejections>0,"both Shift denial classes observed")
	return found
