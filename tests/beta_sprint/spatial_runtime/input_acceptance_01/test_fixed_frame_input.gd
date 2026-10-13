extends SceneTree
const Facade = preload("res://foundation/game_feel/runtime_facade.gd")
const Mapper = preload("res://foundation/runtime/input_mapper.gd")
const View = preload("res://foundation/game_feel/view_contract.gd")
const Math = preload("res://foundation/orientation/discrete_orientation.gd")
const Geometry = preload("res://foundation/spatial/surface_geometry.gd")
const DIRECTIONS = [Vector2.RIGHT,Vector2.UP,Vector2.LEFT,Vector2.DOWN]
var checks := 0
var failures: Array[String] = []
var rows: Array[Dictionary] = []
func check(ok: bool, label: String) -> void:
	checks += 1
	if not ok: failures.append(label)
func _initialize() -> void:
	for orientation in 24:
		var columns: Array[Vector3i] = Math.columns(orientation)
		var frame := {"u":columns[0],"v":columns[1],"normal":columns[2]}
		for quadrant in 4: _frame(frame,orientation,quadrant)
	var frame: Dictionary = Geometry.face_frame(4)
	for direction in [Vector2.ZERO,Vector2(0,0.00000001),Vector2(INF,0),Vector2(0,NAN),Vector2(NAN,1)]:
		check(Facade._map_fixed_move(frame,0,direction) == Mapper.map_move(frame,View.basis(0),direction), "invalid direction keeps formal rejection")
	for invalid in [{},{"u":Vector3.RIGHT,"v":Vector3i.FORWARD,"normal":Vector3i.UP},{"u":Vector3i.RIGHT,"v":Vector3i.RIGHT,"normal":Vector3i.UP}]:
		check(Facade._map_fixed_move(invalid,0,Vector2.DOWN) == Mapper.map_move(invalid,View.basis(0),Vector2.DOWN), "invalid frame keeps formal rejection")
	FileAccess.open(OS.get_environment("FOUNDATION_TEST_EVIDENCE").path_join("report.json"),FileAccess.WRITE).store_string(JSON.stringify({"checks":checks,"failures":failures,"doubles":[],"frames":rows},"\t"))
	print("FIXED_FRAME_INPUT checks=",checks," failures=",failures)
	quit(0 if failures.is_empty() else 1)
func _frame(frame: Dictionary, orientation: int, quadrant: int) -> void:
	var original := frame.duplicate(true)
	var selected: Array[int] = []
	var axes: Array = [frame.u,frame.v,-frame.u,-frame.v]
	for index in 4:
		var mapped: Dictionary = Facade._map_fixed_move(frame,quadrant,DIRECTIONS[index])
		check(mapped.ok and mapped.issues.is_empty(), "valid fixed frame/cardinal maps")
		if not mapped.ok: return
		selected.append(mapped.action.face_axis)
		check(Facade._map_fixed_move(frame,quadrant,DIRECTIONS[index]*10).action == mapped.action, "cardinal magnitude independent")
		var projection: Vector2i = View.project(axes[mapped.action.face_axis],quadrant)
		check(projection.x * int(DIRECTIONS[index].x) + projection.y * int(DIRECTIONS[index].y) > 0, "chosen axis has correct screen sign")
	check(selected.has(0) and selected.has(1) and selected.has(2) and selected.has(3), "24 frames x4 cameras expose four independent axes")
	check((selected[0]+2)%4 == selected[2] and (selected[1]+2)%4 == selected[3], "opposite keys always opposite")
	for direction in [Vector2.RIGHT,Vector2.LEFT,Vector2(1,1),Vector2(1,-1),Vector2(-1,1),Vector2(-1,-1),Vector2(0.1,-1)]:
		check(Facade._map_fixed_move(frame,quadrant,direction) == Mapper.map_move(frame,View.basis(quadrant),direction), "horizontal and analog/diagonal results unchanged")
	var right: Dictionary = Mapper.map_move(frame,View.basis(quadrant),Vector2.RIGHT)
	var down: Dictionary = Mapper.map_move(frame,View.basis(quadrant),Vector2.DOWN)
	if right.action.face_axis%2 != down.action.face_axis%2:
		check(Facade._map_fixed_move(frame,quadrant,Vector2.DOWN) == down and Facade._map_fixed_move(frame,quadrant,Vector2.UP) == Mapper.map_move(frame,View.basis(quadrant),Vector2.UP), "already independent vertical mappings unchanged")
	check(frame == original, "mapping does not mutate frame")
	rows.append({"orientation":orientation,"quadrant":quadrant,"right_up_left_down":selected})
