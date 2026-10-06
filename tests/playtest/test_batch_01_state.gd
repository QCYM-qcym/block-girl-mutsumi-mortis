extends SceneTree

const Movement = preload("res://prototype/perspective/grid_movement.gd")
const View = preload("res://prototype/perspective/perspective_controller.gd")
const ROOT = "res://game/levels/mutsumi/batch_01/"
const NAMES = ["l01_another_world", "l02_between_shores", "l03_lines_meet"]
var failures: Array[String] = []
var checks := 0
var summaries: Array = []
var graph
var mover
var view

func check(ok: bool, label: String) -> void:
	checks += 1
	if not ok:
		failures.append(label)
		printerr("FAIL: ", label)

func _initialize() -> void:
	for name in NAMES:
		check(ResourceLoader.exists(ROOT + name + ".tscn"), "independent scene exists: " + name)
	if not failures.is_empty():
		quit(1)
		return
	for name in NAMES:
		var data = load(ROOT + name + ".tres")
		graph = load(ROOT + "content_state.gd").new()
		graph.configure(data)
		view = View.new()
		mover = Movement.new(graph, view)
		graph.bind(mover)
		graph.reset_level()
		check(mover.cell == data.spawn and mover.world == 0 and view.current == 0, name + " spawn")
		if name == NAMES[0]:
			move(Vector2i.UP, 3)
			check(mover.cell == Vector2i(0,2), "L01 Surface shore")
			move(Vector2i.UP)
			check(mover.cell == Vector2i(0,2), "L01 missing Surface bridge blocks")
			shift()
			move(Vector2i.UP)
			check(not mover.shift(), "L01 unsafe bridge shift rejected")
			move(Vector2i.UP)
			move(Vector2i.RIGHT, 3)
			rotate()
			check(graph.link.active, "L01 Inner EAST connection")
			move(Vector2i.RIGHT)
			check(mover.cell == Vector2i(9,0), "L01 actual link crossing")
			move(Vector2i.RIGHT, 2)
			move(Vector2i.RIGHT)
			check(mover.cell == Vector2i(11,0), "L01 Inner gate cannot bypass plate")
			shift()
			check(graph.door_open, "L01 Surface plate opens")
			move(Vector2i.RIGHT, 2)
		elif name == NAMES[1]:
			move(Vector2i.UP, 2)
			for i in 4:
				move(Vector2i.UP)
				check(mover.cell == Vector2i(0,3), "L02 view cannot bridge missing floor")
				rotate()
			shift()
			move(Vector2i.UP)
			check(not mover.shift(), "L02 Inner-only floor refuses shift")
			move(Vector2i.UP)
			move(Vector2i.RIGHT)
			move(Vector2i.RIGHT)
			check(mover.cell == Vector2i(1,1), "L02 Inner cannot bypass second shift")
			shift()
			move(Vector2i.RIGHT, 3)
		else:
			move(Vector2i.RIGHT, 3)
			move(Vector2i.RIGHT)
			check(mover.cell == Vector2i(3,2), "L03 real gap blocks NORTH")
			shift()
			rotate()
			check(not graph.link.active, "L03 Inner cannot use Surface link")
			shift()
			check(graph.link.active, "L03 EAST activates authored pair")
			move(Vector2i.RIGHT, 3)
		check(graph.complete and mover.cell == data.goal and mover.phase == "complete", name + " reaches Goal")
		graph.reset_level()
		check(not graph.complete and not graph.door_open and mover.moves == 0 and mover.order.is_empty(), name + " Reset clears progress")
		explore(name)
	print("BATCH01 STATE: ", checks, " checks, failures=", failures, ", topology=", summaries)
	var report = {"checks":checks, "failures":failures, "levels":summaries}
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path("res://tests/playtest/evidence/batch_01"))
	var file = FileAccess.open("res://tests/playtest/evidence/batch_01/state_report.json", FileAccess.WRITE)
	file.store_string(JSON.stringify(report, "\t"))
	quit(0 if failures.is_empty() else 1)

func move(direction: Vector2i, count: int = 1) -> void:
	var directions = [Vector2i.UP, Vector2i.RIGHT, Vector2i.DOWN, Vector2i.LEFT]
	for i in count:
		var screen = posmod(directions.find(direction) - view.current, 4)
		mover.press(1, screen)
		mover.release(1)
		mover.tick(0.33)

func shift() -> void:
	var cell = mover.cell
	var pose = mover.orientation.key()
	check(mover.shift(), "legal World Shift starts")
	mover.tick(0.26)
	check(mover.cell == cell and mover.orientation.key() == pose, "Shift preserves cell and orientation")

func rotate() -> void:
	view.request_rotate_right()
	view.tick(0.41)
	graph.recalculate(view, mover.world)

func explore(name: String) -> void:
	# All mechanics on these maps depend only on cell/world/view; orientation never gates actions.
	var pending: Array = [[graph.definition.spawn, 0, 0]]
	var states: Dictionary = {}
	var reverse: Dictionary = {}
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
		graph.recalculate(view, mover.world)
		if graph.complete:
			goals.append(id)
			continue
		var nexts: Array = []
		for direction in [Vector2i.UP,Vector2i.RIGHT,Vector2i.DOWN,Vector2i.LEFT]:
			var target: Vector2i = graph.neighbor(mover.cell, direction, view)
			if target != mover.cell: nexts.append([target, mover.world, view.current])
		if graph.can_stand(mover.cell, 1-mover.world): nexts.append([mover.cell,1-mover.world,view.current])
		for v in [posmod(view.current-1,4), posmod(view.current+1,4)]: nexts.append([mover.cell,mover.world,v])
		for next in nexts:
			var nid = str(next)
			if not reverse.has(nid): reverse[nid] = []
			reverse[nid].append(id)
			if not states.has(nid): pending.append(next)
	var solvable: Dictionary = {}
	while not goals.is_empty():
		var id: String = goals.pop_back()
		if solvable.has(id): continue
		solvable[id] = true
		goals.append_array(reverse.get(id, []))
	check(solvable.size() == states.size(), name + " every reachable state can finish without Reset")
	summaries.append({"id":graph.definition.level_id,"reachable_states":states.size(),"solvable_states":solvable.size()})
	graph.reset_level()
