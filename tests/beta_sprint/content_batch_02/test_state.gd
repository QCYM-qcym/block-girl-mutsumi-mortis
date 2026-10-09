extends SceneTree
const ROOT = "res://game/levels/mutsumi/batch_02/"
const NAMES = ["l04_borrowed_path", "l05_gate_home"]
const State = preload("res://game/levels/mutsumi/batch_01/content_state.gd")
const Movement = preload("res://prototype/perspective/grid_movement.gd")
const Perspective = preload("res://prototype/perspective/perspective_controller.gd")
var evidence := ""
var checks := 0
var failures: Array[String] = []
var routes: Array = []
var topology: Array = []
var graph
var mover
var view

func _initialize() -> void:
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--evidence-dir="): evidence = arg.trim_prefix("--evidence-dir=")
	for name in NAMES: check(ResourceLoader.exists(ROOT+name+".tscn"), "independent scene exists: "+name)
	if not failures.is_empty():
		finish()
		return
	for index in 2:
		var data = load(ROOT+NAMES[index]+".tres")
		if data.gate_enabled:
			# The frozen L01 gate Presenter paints a two-cell bridge in both worlds.
			# Painted walkable geometry must have corresponding native support.
			for cells in [data.surface_cells,data.inner_cells]:
				for bridge in [Vector2i(1,0),Vector2i(2,0)]:
					check(bridge in cells,"L05 displayed inherited bridge has real support: "+str(bridge))
		graph = State.new()
		graph.configure(data)
		view = Perspective.new()
		mover = Movement.new(graph,view)
		graph.bind(mover)
		graph.reset_level()
		check(mover.cell == data.spawn and mover.world == 0 and view.current == 0,"real configured Spawn")
		if index == 0: route_l04()
		else: route_l05()
		check(graph.complete and mover.cell == data.goal and mover.phase == "complete",data.level_id+" actual timed-move Goal")
		routes.append({"id":data.level_id,"complete":graph.complete,"moves":mover.moves,"cell":str(mover.cell),"world":mover.world})
		graph.reset_level()
		check(mover.cell == data.spawn and mover.destination == data.spawn and mover.moves == 0 and mover.order.is_empty() and not graph.complete and not graph.door_open,"Reset clears content and input")
		explore()
	finish()

func check(value: bool,label: String) -> void:
	checks += 1
	if not value:
		failures.append(label)
		printerr("FAIL: ",label)

func move(direction: Vector2i,count: int=1) -> void:
	var dirs = [Vector2i.UP,Vector2i.RIGHT,Vector2i.DOWN,Vector2i.LEFT]
	for i in count:
		mover.press(1,posmod(dirs.find(direction)-view.current,4))
		mover.release(1)
		mover.tick(0.33)

func shift() -> void:
	var before = [mover.cell,view.current,mover.orientation.key()]
	check(mover.shift(),"safe Shift starts")
	mover.tick(0.26)
	check(before == [mover.cell,view.current,mover.orientation.key()],"Shift preserves physical pose/grid/view")

func rotate() -> void:
	view.request_rotate_right()
	view.tick(0.41)
	graph.recalculate(view,mover.world)

func route_l04() -> void:
	move(Vector2i.UP)
	check(not mover.shift(),"L04 early Surface-only floor refuses Shift")
	move(Vector2i.LEFT)
	move(Vector2i.UP)
	check(mover.cell == Vector2i(0,4),"L04 first bridge requires Inner")
	shift()
	move(Vector2i.UP,2)
	move(Vector2i.RIGHT,3)
	move(Vector2i.RIGHT)
	check(mover.cell == Vector2i(3,2),"L04 connection requires alignment")
	rotate()
	check(graph.link.active,"L04 Inner EAST connection activates")
	shift()
	move(Vector2i.RIGHT)
	check(mover.cell == Vector2i(3,2) and not graph.link.active,"L04 Surface EAST cannot replace Inner link permission")
	shift()
	move(Vector2i.RIGHT,2)
	move(Vector2i.RIGHT)
	check(mover.cell == Vector2i(10,2),"L04 exit branch requires return Surface")
	shift()
	move(Vector2i.RIGHT)
	move(Vector2i.UP)

func route_l05() -> void:
	move(Vector2i.UP,2)
	move(Vector2i.UP)
	check(mover.cell == Vector2i(0,3),"L05 first bridge requires Shift")
	shift()
	move(Vector2i.UP)
	move(Vector2i.RIGHT)
	move(Vector2i.UP)
	check(mover.cell == Vector2i(1,2),"L05 bridge entrance requires Surface")
	shift()
	move(Vector2i.UP,2)
	move(Vector2i.RIGHT,2)
	rotate()
	move(Vector2i.RIGHT)
	check(mover.cell == Vector2i(3,0) and not graph.link.active,"L05 Surface EAST cannot traverse Inner connection")
	shift()
	move(Vector2i.RIGHT,3)
	move(Vector2i.RIGHT)
	check(mover.cell == graph.PLATE and not graph.door_open,"L05 Inner plate cannot open Gate")
	shift()
	check(graph.door_open and graph.plate_pressed,"L05 Surface plate activates existing Gate")
	mover.press(1,0)
	mover.release(1)
	mover.tick(0.16)
	check(mover.cell == graph.PLATE and graph.door_open,"Gate stays open until accepted roll lands")
	mover.tick(0.17)
	check(mover.cell == graph.BEYOND_GATE and not graph.door_open,"Gate closes after safe committed landing")
	move(Vector2i.RIGHT)

func explore() -> void:
	# Query-only topology audit, deliberately separate from timed-move route evidence.
	# Orientation does not gate these maps; never used as natural-input proof.
	var pending: Array = [[graph.definition.spawn,0,0]]
	var states: Dictionary = {}
	var reverse: Dictionary = {}
	var forward: Dictionary = {}
	var goals: Array = []
	while not pending.is_empty():
		var state: Array = pending.pop_front()
		var id = str(state)
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
		for d in [Vector2i.UP,Vector2i.RIGHT,Vector2i.DOWN,Vector2i.LEFT]:
			var target: Vector2i = graph.neighbor(mover.cell,d,view)
			if target != mover.cell: nexts.append([target,mover.world,view.current])
		if graph.can_stand(mover.cell,1-mover.world): nexts.append([mover.cell,1-mover.world,view.current])
		for v in [posmod(view.current-1,4),posmod(view.current+1,4)]: nexts.append([mover.cell,mover.world,v])
		for next in nexts:
			var nid = str(next)
			if not forward.has(id): forward[id] = []
			forward[id].append(nid)
			if not reverse.has(nid): reverse[nid] = []
			reverse[nid].append(id)
			if not states.has(nid): pending.append(next)
	var solvable: Dictionary = {}
	while not goals.is_empty():
		var id: String = goals.pop_back()
		if solvable.has(id): continue
		solvable[id] = true
		goals.append_array(reverse.get(id,[]))
	check(solvable.size() == states.size(),graph.definition.level_id+" every reachable state can finish without Reset")
	# Minimum Shift cost over the same native edges proves the world decisions
	# cannot be skipped by a different camera order or the inherited bridge.
	var start_id := str([graph.definition.spawn,0,0])
	var costs: Dictionary = {start_id:0}
	var cost_pending: Array = [start_id]
	while not cost_pending.is_empty():
		var id: String = cost_pending.pop_front()
		for next_id in forward.get(id,[]):
			var cost: int = costs[id]+int(states[id][1] != states[next_id][1])
			if cost < costs.get(next_id,999):
				costs[next_id] = cost
				cost_pending.append(next_id)
	var minimum_shifts := 999
	for id in states:
		if states[id][0] == graph.definition.goal and states[id][1] == 0:
			minimum_shifts = mini(minimum_shifts,costs.get(id,999))
	check(minimum_shifts == (2 if graph.definition.level_id == "mutsumi_l04" else 4),graph.definition.level_id+" required world choices have no camera/bridge bypass")
	topology.append({"id":graph.definition.level_id,"reachable":states.size(),"solvable":solvable.size(),"minimum_shifts_to_goal":minimum_shifts,"kind":"query_only_not_input_playthrough"})
	graph.reset_level()

func finish() -> void:
	var report = {"checks":checks,"failures":failures,"pid":OS.get_process_id(),"display":DisplayServer.get_name(),"engine":Engine.get_version_info(),"routes":routes,"topology":topology}
	if not evidence.is_empty(): FileAccess.open(evidence.path_join("report.json"),FileAccess.WRITE).store_string(JSON.stringify(report,"\t"))
	print("BATCH02 UNIT: ",checks," checks; failures=",failures,"; topology=",topology)
	quit(0 if failures.is_empty() else 1)
