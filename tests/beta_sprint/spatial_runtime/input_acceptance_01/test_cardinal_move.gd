extends SceneTree
const Facade = preload("res://foundation/game_feel/runtime_facade.gd")
const Maps = preload("res://experiments/spatial_puzzle_batch_01/maps/map_factory.gd")
const Key = preload("res://foundation/contracts/state_key.gd")
const Kernel = preload("res://foundation/rules/puzzle_rule_kernel.gd")
const Rules = preload("res://foundation/rules/rule_records.gd")
const Derived = preload("res://foundation/rules/derived_state_resolver.gd")
const Geometry = preload("res://foundation/spatial/surface_geometry.gd")
const View = preload("res://foundation/game_feel/view_contract.gd")
const Mapper = preload("res://foundation/runtime/input_mapper.gd")
const INPUTS = [Vector2.UP, Vector2.LEFT, Vector2.DOWN, Vector2.RIGHT]
var checks := 0
var failures: Array[String] = []
var rows: Array[Dictionary] = []

func check(ok: bool, label: String) -> void:
	checks += 1
	if not ok: failures.append(label)

func _initialize() -> void:
	create_timer(60).timeout.connect(func(): printerr("CARDINAL_TEST_TIMEOUT"); quit(2))
	call_deferred("run")

func run() -> void:
	var baked: Dictionary = Maps.bake(&"world_shift_gate_lab")
	check(baked.ok, "actual saved Gate authoring/Reader/Baker")
	if baked.ok:
		for prefix in [0,1,2,3]:
			for quadrant in 4: _group(baked.level, prefix, quadrant)
	FileAccess.open(OS.get_environment("FOUNDATION_TEST_EVIDENCE").path_join("report.json"), FileAccess.WRITE).store_string(JSON.stringify({"checks":checks,"failures":failures,"rows":rows,"doubles":[],"mode":"LOGICAL_PUBLIC_FACADE"}, "\t"))
	print("CARDINAL_MOVE checks=",checks," failures=",failures)
	quit(0 if failures.is_empty() else 1)

func finish(runtime: RefCounted, result: Dictionary, starts: Array) -> void:
	if result.status == 0 and result.changed:
		var captured: Array = starts[-1]
		var identity: Dictionary = runtime.get_pending_identity(captured[0], captured[1], captured[2])
		check(not runtime.finish_transition(identity).ignored, "official captured identity commits")

func _group(level: Dictionary, prefix: int, quadrant: int) -> void:
	var axes: Array = []
	var accepted := 0
	for direction in INPUTS:
		var runtime := Facade.new()
		var starts: Array = []
		runtime.transition_started.connect(func(_r,t,g,b): starts.append([t,g,b]))
		check(runtime.load_level(level).ok, "formal opt-in Facade load")
		var witness: Array = Maps.witnesses(&"world_shift_gate_lab").solution
		for index in prefix:
			var step: Dictionary = runtime.request_action(witness[index])
			check(step.status == 0, "real action prefix")
			finish(runtime, step, starts)
		var before_camera: Dictionary = runtime.get_state()
		var camera: Dictionary = runtime.request_action({"kind":9,"camera_quadrant":quadrant})
		check(camera.status == 0, "formal camera selection")
		finish(runtime, camera, starts)
		var before: Dictionary = runtime.get_state()
		check(before.player == before_camera.player and before.world_orientations == before_camera.world_orientations, "camera never changes physical orientation")
		var count: int = runtime.get_commit_count()
		var key: String = Key.build(level,before).key
		var result: Dictionary = runtime.request_move(direction)
		check(result.action.get("kind") == 0 and result.action.get("face_axis") in range(4), "cardinal input becomes semantic MOVE")
		if result.action.get("kind") != 0: continue
		axes.append(result.action.face_axis)
		var expected: Dictionary = Kernel.evaluate_action(level, before, result.action, Rules.idle_context())
		check(result == expected, "input retains exact official Kernel result")
		check(Key.build(level,runtime.get_state()).key == key and runtime.get_commit_count() == count, "mapping and proposal do not commit")
		finish(runtime, result, starts)
		if result.status == 0 and result.changed:
			accepted += 1
			check(runtime.get_state() == result.next_state and runtime.get_commit_count() == count+1, "one authoritative commit")
			check(runtime.get_state().player.location.cube_id == [&"gate",&"source",&"goal",&"inner_gate"][prefix], "correct road target")
		else:
			check(result.status == 1 and Key.build(level,runtime.get_state()).key == key and runtime.get_commit_count() == count, "illegal edge rejection preserves StateKey and commit count")
		check(runtime.is_idle(), "formal transition returns to IDLE")
		var snapshot: Dictionary = Derived.snapshot(level,before)
		for anchor in snapshot.value.anchors:
			if anchor.face_id == Geometry.face_id(before.player.location.cube_id,before.player.location.face):
				rows.append({"prefix":prefix,"quadrant":quadrant,"direction":str(direction),"frame":anchor.frame,"generic_axis":Mapper.map_move(anchor.frame,View.basis(quadrant),direction).action.face_axis,"action":result.action,"status":result.status,"before_key":key,"after_key":Key.build(level,runtime.get_state()).key,"commit_delta":runtime.get_commit_count()-count})
	check(axes.size() == 4 and axes.has(0) and axes.has(1) and axes.has(2) and axes.has(3), "four distinct cardinal axes prefix%d camera%d" % [prefix,quadrant])
	check(axes.size() == 4 and (axes[0]+2)%4 == axes[2] and (axes[1]+2)%4 == axes[3], "opposite cardinal keys remain opposite")
	check(accepted == 1, "exactly one legal road is reachable prefix%d camera%d" % [prefix,quadrant])
