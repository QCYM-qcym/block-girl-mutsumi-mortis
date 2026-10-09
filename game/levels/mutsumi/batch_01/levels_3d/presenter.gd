extends "res://game/levels/mutsumi/batch_01/l01_3d/presenter.gd"
## Layout varies; accepted roll, camera, shift and materials remain inherited.
const Tokens = preload("res://game/shell/visual_01/tokens.gd")
var link_markers: Array[Dictionary] = []

func _build_assets() -> void:
	actor = Node3D.new()
	actor.name = "PhysicalCubePose"
	add_child(actor)
	for world in 2:
		var root := Node3D.new()
		root.name = "Surface" if world == 0 else "Inner"
		add_child(root)
		world_roots.append(root)
		var interpretation := "SURFACE" if world == 0 else "INNER"
		var cells = definition.surface_cells if world == 0 else definition.inner_cells
		for cell in cells:
			_add_asset("BG_ENV_%s_FLOOR_001" % interpretation, root,
				Vector2(cell), int(graph.nodes[cell]), world, true)
		var mapping: Dictionary = {}
		# An Exit never adds support to a world that lacks the native Goal cell.
		if definition.goal in cells:
			mapping.exit = _add_asset("BG_MEC_%s_EXIT_001" % interpretation,
				root, Vector2(definition.goal), int(graph.nodes[definition.goal]),
				world, false, PI / 2)
		# Space remains the existing global action; this device is only its cue.
		mapping.world_switch = _add_asset("BG_MEC_%s_WORLD_SWITCH_001" % interpretation,
			root, Vector2(definition.spawn) + Vector2(1.4, 0),
			int(graph.nodes[definition.spawn]), world, false)
		mechanisms.append(mapping)
		var character_id := "BG_CH_WAKABA_CUBE_001" if world == 0 else "BG_CH_MORTIS_CUBE_001"
		var character := _instance(character_id)
		actor.add_child(character)
		character.position.y = -0.5
		actor_visuals.append(character)
		_register_materials(character, world, false, "character", true)
	if definition.link_enabled:
		for anchor in [graph.link.a, graph.link.b]:
			var label := Label3D.new()
			label.name = "ConnectionEndpoint" + str(link_markers.size())
			label.font = Tokens.font(false, 600)
			label.font_size = 40
			label.pixel_size = 0.007
			label.outline_size = 12
			label.outline_modulate = Tokens.COLORS.ink
			label.modulate = Tokens.COLORS.light
			label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
			add_child(label)
			# The EAST edge positions coincide; stagger only the readout height.
			link_markers.append({"anchor": anchor, "node": label,
				"lift": 1.4 + 0.5 * link_markers.size()})

func _update_mechanisms() -> void:
	for world in 2:
		var pair := mechanisms[world]
		if pair.has("exit"):
			pair.exit.set_visual_state("complete" if graph.complete else "available" if mover.world == 0 else "locked")
		pair.world_switch.set_visual_state("switching" if mover.phase == "shift" else "completed" if shift_active and shift_committed else "available", transition_progress)
	var connected: bool = graph.link.active and not view.busy
	for row in link_markers:
		var label: Label3D = row.node
		label.position = displayed_position(row.anchor.position(), row.anchor.platform) + Vector3(0, row.lift, 0)
		label.visible = graph.can_stand(row.anchor.node, mover.world)
		label.text = "连接成立" if connected else "未连接"

func _mechanism_state(kind: String) -> String:
	var pair := mechanisms[mover.world]
	return str(pair[kind].state_id) if pair.has(kind) else "not_authored"

func debug_snapshot() -> Dictionary:
	var connected: bool = graph.link.active and not view.busy
	var marker_states: Array[Dictionary] = []
	for row in link_markers:
		marker_states.append({"anchor_id": row.anchor.id, "text": row.node.text,
			"visible": row.node.visible, "position": row.node.position})
	return {"world": mover.world, "phase": mover.phase, "fraction": mover.fraction,
		"view": view.current, "camera_angle": camera_angle, "physical_basis": mover.orientation.as_basis(),
		"actor_basis": actor.basis, "displayed_worlds": [world_roots[0].visible, world_roots[1].visible],
		"gate_state": _mechanism_state("gate"), "plate_state": _mechanism_state("plate"),
		"exit_state": _mechanism_state("exit"),
		"shift_progress": transition_progress if shift_active else 0.0, "shift_committed": shift_committed,
		"incoming_walk_surface_reveal": smoothstep(SHIFT_COMMIT, 0.93, transition_progress) if shift_active and shift_committed else 0.0,
		"occlusion": occlusion.duplicate(), "camera_size": camera.size,
		"link_active": connected, "link_runtime_active": graph.link.active,
		"link_status": "not_authored" if not definition.link_enabled else "active" if connected else "inactive",
		"link_markers": marker_states}
