extends "res://tests/beta_sprint/spatial_quality/suite.gd"
## Literal expectations protect the six physical face identities and four-view input boundary.
const Math = preload("res://foundation/orientation/discrete_orientation.gd")
const Geometry = preload("res://foundation/spatial/surface_geometry.gd")
const Mapper = preload("res://foundation/runtime/input_mapper.gd")
const View = preload("res://foundation/game_feel/view_contract.gd")

func run() -> void:
	begin("loop.unit.local_faces","UNIT")
	var normals := [Vector3i(0,0,1),Vector3i(0,0,-1),Vector3i(-1,0,0),
		Vector3i(1,0,0),Vector3i(0,1,0),Vector3i(0,-1,0)]
	for face in 6:
		check(Geometry.face_frame(face).normal == normals[face],"canonical physical normal " + str(face))
		check(Math.apply(0,normals[face]) == normals[face],"initial local face remains distinct " + str(face))
	# +X rotation: FRONT points DOWN, TOP points FRONT. Screen directions are irrelevant.
	check(Math.apply(2,normals[0]) == Vector3i(0,-1,0),"FRONT is down after actual +X quarter turn")
	check(Math.apply(2,normals[4]) == Vector3i(0,0,1),"TOP is forward after actual +X quarter turn")
	begin("loop.unit.camera_mapping","UNIT")
	# Hand-derived TOP frame u=+X,v=-Z. RIGHT / UP / LEFT / DOWN, tie order frozen.
	var expected := [[0,2,2,0],[0,0,2,2],[2,3,0,1],[1,2,3,0]]
	var directions := [Vector2.RIGHT,Vector2.UP,Vector2.LEFT,Vector2.DOWN]
	for q in 4:
		var actions: Array = []
		for d in 4:
			var mapped := Mapper.map_move(Geometry.face_frame(4),View.basis(q),directions[d])
			check(mapped.ok and mapped.action == {"kind":0,"face_axis":expected[q][d]},"view " + str(q) + " input " + str(d))
			actions.append(mapped)
		rows.append({"quadrant":q,"actual_mapping":actions})
	begin("loop.unit.invalid_input","UNIT")
	for direction in [Vector2.ZERO,Vector2(INF,0),Vector2(NAN,0)]:
		check(not Mapper.map_move(Geometry.face_frame(4),View.basis(0),direction).ok,"invalid observation never becomes MOVE")
	finish()
