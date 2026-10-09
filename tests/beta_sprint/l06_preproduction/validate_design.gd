extends SceneTree
## Design spike only. No scene, input fixture, Presenter, catalog, or save writes.
const Data = preload("res://game/levels/mutsumi/batch_01/content_level_data.gd")
const State = preload("res://game/levels/mutsumi/batch_01/content_state.gd")
const Movement = preload("res://prototype/perspective/grid_movement.gd")
const Perspective = preload("res://prototype/perspective/perspective_controller.gd")
const CANDIDATE = "res://docs/beta-sprint/l06-preproduction/CANDIDATE.json"
var graph
var mover
var view
var candidate: Dictionary
var checks := 0
var failures: Array[String] = []
var traces: Array = []
var routes: Array = []
var commits := 0
var evidence := ""

func _initialize() -> void:
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--evidence-dir="):
			evidence = arg.trim_prefix("--evidence-dir=")
	if evidence.is_empty():
		printerr("Explicit evidence directory required")
		quit(2)
		return
	candidate = JSON.parse_string(FileAccess.get_file_as_string(CANDIDATE))
	var data = Data.new()
	for field in candidate.data:
		var value = candidate.data[field]
		if field in ["spawn", "goal", "link_a", "link_b"]:
			data.set(field, Vector2i(value[0], value[1]))
		elif field in ["surface_cells", "inner_cells", "platform_b_cells"]:
			var cells: Array[Vector2i] = []
			for cell in value: cells.append(Vector2i(cell[0], cell[1]))
			data.set(field, cells)
		elif field == "link_worlds":
			var worlds: Array[int] = []
			for world in value: worlds.append(int(world))
			data.set(field, worlds)
		else:
			data.set(field, value)
	graph = State.new()
	graph.configure(data)
	view = Perspective.new()
	mover = Movement.new(graph, view)
	graph.bind(mover)
	mover.committed.connect(func(): commits += 1)
	for cells in [data.surface_cells, data.inner_cells]:
		for required in [Vector2i(1,0), Vector2i(2,0), graph.PLATE, data.goal]:
			check(required in cells, "existing gate Presenter painted support: " + str(required))
	for name in ["normal", "reset_replay", "alternate_camera", "spawn_inner"]:
		graph.reset_level()
		commits = 0
		check(mover.cell == data.spawn and mover.world == 0 and view.current == 0 and mover.phase == "idle", name + " authored reset")
		var trace_start := traces.size()
		if name == "alternate_camera": rotate(-1)
		var route: Array = candidate.normal_route.duplicate(true)
		if name == "spawn_inner":
			route = candidate.spawn_inner_prefix.duplicate(true) + route.slice(2)
		for row in route:
			match row.action:
				"move":
					for step in int(row.count): move(Vector2i(row.direction[0], row.direction[1]))
				"shift": shift()
				"align_east":
					# Ordinary right snaps; alternate starts WEST and visits NORTH.
					while view.current != 1: rotate(1)
			if name == "alternate_camera" and row.landmark == "Link B: (9,0)": rotate(1)
		check(graph.complete and mover.phase == "complete" and mover.world == 0 and mover.cell == data.goal, name + " native completion predicate")
		check(mover.moves == (23 if name == "spawn_inner" else 21), name + " roll count")
		check(commits == mover.moves + 6, name + " six Shift commits plus rolls")
		routes.append({"name":name, "kind":"original_timed_movement_api_not_human_or_presenter", "rolls":mover.moves, "commits":commits, "goal":graph.complete, "trace_start":trace_start, "trace_end":traces.size(), "after":snapshot()})
	reset_during_actions()
	var topology := explore()
	var report := {"status":"DESIGN_NATIVE_RULE_VALIDATION", "pid":OS.get_process_id(), "engine":Engine.get_version_info(), "display":DisplayServer.get_name(), "checks":checks, "failures":failures, "candidate_sha256":FileAccess.get_sha256(CANDIDATE), "routes":routes, "trace":traces, "topology":topology, "production_l06_registered":false, "human_qa":"NOT_RUN", "presenter":"NOT_RUN", "save_io":"NONE"}
	FileAccess.open(evidence.path_join("report.json"), FileAccess.WRITE).store_string(JSON.stringify(report, "\t") + "\n")
	print("L06 DESIGN: ", checks, " checks; failures=", failures, "; topology=", topology)
	quit(0 if failures.is_empty() else 1)

func check(value: bool, label: String) -> void:
	checks += 1
	if not value:
		failures.append(label)
		printerr("FAIL: ", label)

func snapshot() -> Dictionary:
	return {"cell":[mover.cell.x,mover.cell.y], "world":mover.world, "view":view.current, "orientation":mover.orientation.key(), "phase":mover.phase, "moves":mover.moves, "commits":commits, "plate":graph.plate_pressed, "door":graph.door_open, "complete":graph.complete}

func move(direction: Vector2i) -> void:
	var before := snapshot()
	var dirs := [Vector2i.UP, Vector2i.RIGHT, Vector2i.DOWN, Vector2i.LEFT]
	var screen := posmod(dirs.find(direction) - view.current, 4)
	var expected: Vector2i = graph.neighbor(mover.cell, direction, view)
	check(expected != mover.cell, "route move has native successor")
	mover.press(41, screen)
	mover.release(41)
	check(mover.phase == "roll", "route move starts native roll")
	mover.tick(0.16)
	check(mover.cell == Vector2i(before.cell[0], before.cell[1]), "native roll waits before landing")
	if Vector2i(before.cell[0],before.cell[1]) == graph.PLATE and expected == graph.BEYOND_GATE:
		check(before.world == 0 and graph.door_open, "accepted gate roll stays open before landing")
	mover.tick(0.17)
	check(mover.cell == expected and mover.orientation.valid(), "native roll commits valid pose at expected cell")
	if expected == graph.BEYOND_GATE:
		check(not graph.door_open, "existing gate closes after accepted landing")
	traces.append({"action":"move", "screen_direction":screen, "world_direction":[direction.x,direction.y], "before":before, "after":snapshot()})

func shift() -> void:
	var before := snapshot()
	check(mover.shift(), "route Shift accepted by existing support predicate")
	mover.tick(0.12)
	check(mover.world == before.world and mover.phase == "shift", "Shift waits before native world commit")
	mover.tick(0.14)
	check(mover.world == 1 - before.world and mover.cell == Vector2i(before.cell[0],before.cell[1]) and mover.orientation.key() == before.orientation and view.current == before.view, "Shift preserves cell/orientation/view")
	traces.append({"action":"shift", "before":before, "after":snapshot()})

func rotate(step: int) -> void:
	var before := snapshot()
	check(view.request(step), "single 90 degree snap accepted")
	view.tick(0.2)
	check(view.busy and view.current == before.view, "view waits before snap commit")
	view.tick(0.21)
	graph.recalculate(view, mover.world)
	check(not view.busy and view.current == posmod(int(before.view)+step,4) and mover.orientation.key() == before.orientation and mover.cell == Vector2i(before.cell[0],before.cell[1]), "view commit preserves physical pose")
	traces.append({"action":"rotate", "step":step, "before":before, "after":snapshot()})

func reset_during_actions() -> void:
	for action in ["roll", "shift", "view", "held"]:
		graph.reset_level()
		match action:
			"roll", "held": mover.press(42,0)
			"shift": check(mover.shift(), "spawn allows safe Shift for Reset probe")
			"view": check(view.request(1), "view starts for Reset probe")
		graph.reset_level()
		mover.tick(1.0)
		view.tick(1.0)
		check(mover.cell == graph.definition.spawn and mover.destination == graph.definition.spawn and mover.world == 0 and mover.phase == "idle" and mover.moves == 0 and mover.held.is_empty() and mover.order.is_empty() and view.current == 0 and not view.busy and not graph.complete and not graph.door_open and mover.orientation.valid(), "Reset during " + action + " cancels pending input/action")

func explore() -> Dictionary:
	# Query-only quotient (cell/world/view); pose does not gate this adapter.
	# State assignment is restricted to this audit, never route playback above.
	var pending: Array = [[graph.definition.spawn,0,0]]
	var states: Dictionary = {}
	var forward: Dictionary = {}
	var reverse: Dictionary = {}
	var goals: Array = []
	var spawn_neighbors: Array = []
	var gate_rejections := 0
	while not pending.is_empty():
		var state: Array = pending.pop_front()
		var id := str(state)
		if states.has(id): continue
		states[id] = state
		mover.cell = state[0]
		mover.world = state[1]
		view.current = state[2]
		mover.phase = "idle"
		graph.complete = false
		graph.settle()
		graph.recalculate(view,mover.world)
		if graph.complete:
			goals.append(id)
			continue
		var nexts: Array = []
		var available := 0
		for d in [Vector2i.UP,Vector2i.RIGHT,Vector2i.DOWN,Vector2i.LEFT]:
			var target: Vector2i = graph.neighbor(mover.cell,d,view)
			if target != mover.cell:
				available += 1
				nexts.append([target,mover.world,view.current])
		if mover.cell == graph.definition.spawn:
			check(available > 0, "spawn world/view has legal movement successor")
			spawn_neighbors.append({"world":mover.world,"view":view.current,"legal_moves":available})
		if mover.cell == graph.PLATE and mover.world == 1:
			check(not graph.door_open and graph.neighbor(mover.cell,Vector2i.RIGHT,view) == mover.cell, "Inner gate blocked in all views")
			gate_rejections += 1
		if mover.cell == graph.link.a.node and mover.world == 1 and view.current == 1:
			check(not graph.link.active and graph.neighbor(mover.cell,Vector2i.RIGHT,view) == mover.cell, "Inner EAST cannot substitute Surface connection")
		if mover.cell == graph.link.a.node and view.current != 1:
			check(not graph.link.active and graph.neighbor(mover.cell,Vector2i.RIGHT,view) == mover.cell, "non-EAST view cannot cross connection")
		if graph.can_stand(mover.cell,1-mover.world): nexts.append([mover.cell,1-mover.world,view.current])
		for v in [posmod(view.current-1,4),posmod(view.current+1,4)]: nexts.append([mover.cell,mover.world,v])
		forward[id] = []
		for next in nexts:
			var nid := str(next)
			forward[id].append(nid)
			if not reverse.has(nid): reverse[nid] = []
			reverse[nid].append(id)
			if not states.has(nid): pending.append(next)
	var solvable: Dictionary = {}
	var back: Array = goals.duplicate()
	while not back.is_empty():
		var id: String = back.pop_back()
		if solvable.has(id): continue
		solvable[id] = true
		back.append_array(reverse.get(id,[]))
	var start := str([graph.definition.spawn,0,0])
	var minimum_shifts := cost_to_goal(start,states,forward,goals,"shifts")
	var minimum_actions := cost_to_goal(start,states,forward,goals,"actions")
	var no_shift := cost_to_goal(start,states,forward,goals,"no_shift")
	var no_link := cost_to_goal(start,states,forward,goals,"no_link")
	var no_gate := cost_to_goal(start,states,forward,goals,"no_gate")
	check(solvable.size() == states.size(), "every reachable quotient state can finish without Reset")
	check(minimum_shifts == 6, "six world choices required across all camera routes")
	check(minimum_actions == 28, "shortest formal action route is 28")
	check(no_shift == -1 and no_link == -1, "no World Shift or no connection cannot reach Goal")
	check(no_gate == -1, "no alternative route bypasses the native gate edge")
	check(gate_rejections == 4 and spawn_neighbors.size() == 8, "both spawn worlds and Inner gate checked under all four views")
	graph.reset_level()
	return {"kind":"native_query_only_not_playthrough", "pose_quotient_reason":"orientation is ungated by ContentState", "reachable":states.size(), "solvable":solvable.size(), "minimum_shifts":minimum_shifts, "minimum_actions":minimum_actions, "no_shift_goal_cost":no_shift, "no_link_goal_cost":no_link, "no_gate_goal_cost":no_gate, "spawn_neighbors":spawn_neighbors, "inner_gate_rejections":gate_rejections}

func cost_to_goal(start: String,states: Dictionary,forward: Dictionary,goals: Array,mode: String) -> int:
	var costs: Dictionary = {start:0}
	var pending: Array = [start]
	while not pending.is_empty():
		var id: String = pending.pop_front()
		for nid in forward.get(id,[]):
			var world_change: bool = states[id][1] != states[nid][1]
			var link_cross: bool = (states[id][0]-states[nid][0]).length_squared() > 1
			var gate_cross: bool = (states[id][0] == graph.PLATE and states[nid][0] == graph.BEYOND_GATE) or (states[id][0] == graph.BEYOND_GATE and states[nid][0] == graph.PLATE)
			if (mode == "no_shift" and world_change) or (mode == "no_link" and link_cross): continue
			if mode == "no_gate" and gate_cross: continue
			var cost: int = costs[id] + (int(world_change) if mode == "shifts" else 1)
			if cost < costs.get(nid,99999):
				costs[nid] = cost
				pending.append(nid)
	var best := 99999
	for goal in goals: best = mini(best,costs.get(goal,99999))
	return -1 if best == 99999 else best
