extends "res://game/levels/mutsumi/p01_board.gd"

func bounds_for(index: int) -> Rect2:
	var bounds = Rect2(view.project(Vector2(graph.definition.spawn),0,0,index), Vector2.ZERO)
	for cell in graph.nodes:
		bounds = bounds.expand(view.project(Vector2(cell),0,graph.nodes[cell],index))
	return bounds

func refresh() -> void:
	super.refresh()
	plate.visible = graph.definition.gate_enabled
	door.visible = graph.definition.gate_enabled
	goal.position = projected(Vector2(graph.definition.goal), graph.nodes[graph.definition.goal])
	for tile in tiles.values():
		tile.modulate = Color.WHITE if graph.definition.quality == "FORMAL" else Color(0.72,0.8,0.84)
	queue_redraw()

func _draw() -> void:
	if graph == null: return
	# Readable greybox/spawn markers, local to this map; no production asset edits.
	var cell: Vector2i = graph.definition.spawn
	if graph.can_stand(cell, mover.world):
		var p = projected(Vector2(cell), graph.nodes[cell])
		draw_polyline(PackedVector2Array([p+Vector2(-9,0),p+Vector2(0,-4),p+Vector2(9,0),p+Vector2(0,4),p+Vector2(-9,0)]), Color(0.7,0.92,0.78,0.8), 1)
	if graph.definition.link_enabled:
		for anchor in [graph.link.a, graph.link.b]:
			if not graph.can_stand(anchor.node, mover.world): continue
			var p = projected(Vector2(anchor.node), anchor.platform)
			var color = Color("c6e6b5") if graph.link.active else Color("9199aa")
			draw_circle(p+Vector2(0,-2),2,color)
