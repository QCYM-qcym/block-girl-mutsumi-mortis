extends "res://game/levels/mutsumi/batch_01/levels_3d/presenter.gd"
## Generic native topology/endpoint cues, accepted roll/camera/Shift and materials.

func _add_asset(id: String, root: Node3D, cell: Vector2, platform: int,
		world: int, walkable: bool, yaw: float = 0.0) -> Node3D:
	# The approved plate is the sole carrier at this existing native cell.
	if definition.gate_enabled and cell == Vector2(graph.PLATE) and id.ends_with("_FLOOR_001"):
		id = "BG_MEC_%s_PRESSURE_PLATE_001" % ("SURFACE" if world == 0 else "INNER")
	return super._add_asset(id, root, cell, platform, world, walkable, yaw)

func _build_assets() -> void:
	super._build_assets()
	for world in 2:
		var pair := mechanisms[world]
		# L04's final step (11,2)->(11,1) traverses approved local Z passage.
		if definition.level_id == "mutsumi_l04" and pair.has("exit"):
			pair.exit.rotation.y = 0.0
		if not definition.gate_enabled:
			continue
		for row in assets:
			if row.world == world and row.walkable and row.cell == Vector2(graph.PLATE):
				pair.plate = row.node
		# Native PLATE->BEYOND_GATE is the only gate edge, on its actual platform.
		var midpoint := (Vector2(graph.PLATE) + Vector2(graph.BEYOND_GATE)) * 0.5
		pair.gate = _add_asset("BG_MEC_%s_GATE_001" % ("SURFACE" if world == 0 else "INNER"),
			world_roots[world], midpoint, int(graph.nodes[graph.PLATE]), world, false, PI / 2)

func _update_mechanisms() -> void:
	super._update_mechanisms()
	if not definition.gate_enabled:
		return
	# Observe the already-authorized native roll; this display grants no passage.
	var open: bool = graph.door_open
	if mover.moving and mover.cell == graph.PLATE and mover.destination == graph.BEYOND_GATE:
		open = true
	for pair in mechanisms:
		pair.plate.set_visual_state("pressed" if graph.plate_pressed else "inactive")
		pair.gate.set_visual_state("open" if open else "closed")
