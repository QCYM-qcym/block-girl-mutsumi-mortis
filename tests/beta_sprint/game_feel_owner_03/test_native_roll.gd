extends SceneTree
## Existing production P01 movement/map API only. No search or Runtime replacement.
const Movement = preload("res://prototype/perspective/grid_movement.gd")
const View = preload("res://prototype/perspective/perspective_controller.gd")
const Content = preload("res://game/levels/mutsumi/batch_01/content_state.gd")
const Capture = preload("res://tests/beta_sprint/game_feel_owner_03/capture_identity.gd")
const NAMES = ["l01_another_world", "l02_between_shores", "l03_lines_meet", "l04_borrowed_path", "l05_gate_home"]
var checks := 0
var failures: Array[String] = []
var observations: Array = []
var evidence := ""
var graph
var mover
var view
var commits := 0

func _initialize() -> void:
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--evidence-dir="): evidence = arg.trim_prefix("--evidence-dir=")
	call_deferred("run")

func check(ok: bool, label: String) -> void:
	checks += 1
	if not ok:
		failures.append(label)
		printerr("FAIL: ", label)

func on_commit() -> void:
	commits += 1
	observations.append(snapshot())

func snapshot() -> Dictionary:
	return {"cell": str(mover.cell), "world": mover.world, "view": view.current,
		"orientation": mover.orientation.key(), "moves": mover.moves, "phase": mover.phase}

func reset_level() -> void:
	graph.reset_level()
	commits = 0

func move(direction: Vector2i, count: int = 1) -> void:
	var directions = [Vector2i.UP, Vector2i.RIGHT, Vector2i.DOWN, Vector2i.LEFT]
	for index in count:
		mover.press(1, posmod(directions.find(direction) - view.current, 4))
		mover.release(1)
		mover.tick(0.33)

func rotate(step: int = 1) -> void:
	check(view.request(step), "existing discrete view request")
	view.tick(0.41)
	graph.recalculate(view, mover.world)

func shift() -> void:
	var before = [mover.cell, mover.orientation.key()]
	var previous := commits
	check(mover.shift(), "existing legal Shift accepted")
	mover.tick(0.26)
	check(before == [mover.cell, mover.orientation.key()] and commits == previous + 1,
		"Shift keeps canonical cell/physical orientation and commits once")

func run() -> void:
	check(not evidence.is_empty(), "explicit evidence directory")
	for name in NAMES:
		var batch := "batch_02" if name in [NAMES[3], NAMES[4]] else "batch_01"
		var data = load("res://game/levels/mutsumi/" + batch + "/" + name + ".tres")
		graph = Content.new()
		graph.configure(data)
		view = View.new()
		mover = Movement.new(graph, view)
		graph.bind(mover)
		mover.committed.connect(on_commit)
		reset_level()
		var initial := snapshot()
		for step in [1, -1]:
			for turn in 4: rotate(step)
		check(snapshot() == initial, name + " four-view orbits preserve physical pose")
		# Public request starts a full Roll; no direct assignment of gameplay state.
		var direction := Vector2i.RIGHT if name == NAMES[2] else Vector2i.UP
		var screen := 1 if direction == Vector2i.RIGHT else 0
		mover.press(1, screen)
		mover.press(1, screen)
		check(mover.order.size() == 1, name + " repeated held key does not duplicate input")
		mover.tick(0.10)
		check(mover.cell == data.spawn and commits == 0 and mover.moving, name + " mid-Roll has no early commit")
		check(not mover.shift(), name + " Roll rejects concurrent Shift")
		mover.release(1)
		mover.tick(0.23)
		check(mover.cell == data.spawn + direction and commits == 1 and mover.phase == "idle", name + " release completes exactly one full Roll")
		reset_level()
		mover.press(1, screen)
		mover.release(1)
		mover.tick(0.10)
		reset_level()
		mover.tick(2.0)
		check(snapshot() == initial and commits == 0 and mover.order.is_empty(), name + " Reset cancels unfinished Roll without a stale commit")
		if name == NAMES[0]:
			mover.press(1, 0)
			mover.tick(0.33)
			mover.tick(0.33)
			check(mover.moves == 2 and mover.moving, "L01 held W starts successive full rolls")
			mover.release(1)
			mover.tick(0.33)
			check(mover.moves == 3 and commits == 3 and mover.phase == "idle", "L01 held release stops after current roll")
			var edge := snapshot()
			for repeat in 30: move(Vector2i.UP)
			check(snapshot() == edge and commits == 3, "L01 repeated blocked edge input preserves pose and commit count")
			shift()
			move(Vector2i.UP, 2)
			move(Vector2i.RIGHT, 3)
			rotate()
			check(graph.link.active and mover.world == 1, "L01 authored EAST Inner connection remains active")
			move(Vector2i.RIGHT)
			check(mover.cell == Vector2i(9, 0), "L01 actual authored connection arrival")
			shift()
			move(Vector2i.RIGHT, 4)
			check(mover.orientation.as_basis() == Basis(Vector3.RIGHT, Vector3.FORWARD, Vector3.UP), "L01 physical final orientation from original Roll route")
		elif name == NAMES[1]:
			move(Vector2i.UP, 2)
			var shore := snapshot()
			move(Vector2i.UP)
			check(snapshot() == shore, "L02 missing Surface bridge remains rejected")
			shift()
			move(Vector2i.UP)
			check(not mover.shift(), "L02 Inner-only cell rejects Shift")
			move(Vector2i.UP)
			move(Vector2i.RIGHT)
			shift()
			move(Vector2i.RIGHT, 3)
			check(mover.orientation.as_basis() == Basis.IDENTITY, "L02 original eight rolls preserve expected final orientation")
		elif name == NAMES[2]:
			move(Vector2i.RIGHT, 3)
			var shore := snapshot()
			move(Vector2i.RIGHT)
			check(snapshot() == shore, "L03 NORTH cannot cross actual gap")
			shift()
			rotate()
			check(not graph.link.active, "L03 Surface connection cannot be borrowed by Inner")
			shift()
			check(graph.link.active, "L03 Surface EAST uses authored connection")
			move(Vector2i.RIGHT, 3)
			check(mover.orientation.as_basis() == Basis(Vector3.LEFT, Vector3.DOWN, Vector3(0, 0, 1)), "L03 original six-roll physical final orientation")
		elif name == NAMES[3]:
			shift()
			move(Vector2i.LEFT)
			check(mover.cell == Vector2i(0, 5), "L04 actual Inner spawn neighbor")
			move(Vector2i.UP, 3)
			move(Vector2i.RIGHT, 3)
			rotate()
			check(graph.link.active, "L04 real Inner EAST connection")
			shift()
			var shore := snapshot()
			move(Vector2i.RIGHT)
			check(snapshot() == shore and not graph.link.active, "L04 Surface cannot borrow Inner connection")
			shift()
			move(Vector2i.RIGHT, 2)
			shore = snapshot()
			move(Vector2i.RIGHT)
			check(snapshot() == shore, "L04 Inner cannot take Surface Goal branch")
			shift()
			move(Vector2i.RIGHT)
			move(Vector2i.UP)
		else:
			move(Vector2i.UP, 2)
			var shore := snapshot()
			move(Vector2i.UP)
			check(snapshot() == shore, "L05 Surface missing bridge blocks")
			shift()
			move(Vector2i.UP)
			move(Vector2i.RIGHT)
			move(Vector2i.UP)
			shift()
			move(Vector2i.UP, 2)
			move(Vector2i.RIGHT, 2)
			rotate()
			shore = snapshot()
			move(Vector2i.RIGHT)
			check(snapshot() == shore and not graph.link.active, "L05 Surface cannot use Inner connection")
			shift()
			move(Vector2i.RIGHT, 2)
			move(Vector2i.RIGHT)
			shore = snapshot()
			move(Vector2i.RIGHT)
			check(snapshot() == shore and not graph.door_open, "L05 Inner plate does not open Gate")
			shift()
			check(graph.door_open and graph.plate_pressed, "L05 Surface plate opens existing Gate")
			mover.press(1, 0)
			mover.release(1)
			mover.tick(0.16)
			check(mover.cell == graph.PLATE and graph.door_open, "L05 accepted Gate Roll retains support until commit")
			mover.tick(0.17)
			check(mover.cell == graph.BEYOND_GATE and not graph.door_open, "L05 Gate closes after actual Roll commit")
			move(Vector2i.RIGHT)
		check(graph.complete and mover.cell == data.goal and mover.world == 0 and mover.phase == "complete", name + " original route reaches committed Goal")
		check(mover.orientation.valid(), name + " physical integer orientation remains valid")
		var completed := snapshot()
		move(Vector2i.DOWN)
		check(not mover.shift() and snapshot() == completed, name + " completed Runtime rejects further movement/Shift")
		reset_level()
		check(snapshot() == initial, name + " Reset restores exact initial observation")
	var report := {"execution_kind": "PRODUCTION_HEADLESS_BASELINE", "checks": checks,
		"capture": Capture.snapshot("P01_PUBLIC_API_PRESS_RELEASE_TICK"),
		"failures": failures, "levels": ["L01", "L02", "L03", "L04", "L05"], "observations": observations,
		"not_run": ["native keyboard", "graphical", "L06", "Perspective Fall", "Landing", "Edge Recoil"]}
	FileAccess.open(evidence.path_join("native_roll.json"), FileAccess.WRITE).store_string(JSON.stringify(report, "\t"))
	print("GAME_FEEL_NATIVE_ROLL checks=", checks, " failures=", failures)
	quit(0 if failures.is_empty() else 1)
