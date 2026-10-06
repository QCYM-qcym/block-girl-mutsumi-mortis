extends "res://game/levels/mutsumi/p01_state.gd"
## Only map declarations and this batch's spawn/goal selection vary.
var definition: Resource

func configure(data: Resource) -> void:
	definition = data
	nodes.clear()
	floors = [{}, {}]
	for w in 2:
		var cells = data.surface_cells if w == 0 else data.inner_cells
		for cell in cells:
			var platform = 1 if cell in data.platform_b_cells else 0
			nodes[cell] = platform
			floors[w][cell] = platform
	link = Link.new(Anchor.new(data.level_id + "_a", data.link_a, Vector2i.RIGHT, 0), Anchor.new(data.level_id + "_b", data.link_b, Vector2i.LEFT, 1))
	link.enabled = data.link_enabled
	link.allowed_world_states = data.link_worlds.duplicate()

func reset_level() -> void:
	mover.view.reset()
	mover.reset()
	mover.cell = definition.spawn
	mover.destination = definition.spawn
	complete = false
	settle()
	recalculate(mover.view, 0)

func settle() -> void:
	world = mover.world
	plate_pressed = definition.gate_enabled and world == 0 and mover.cell == PLATE
	door_open = plate_pressed
	if world == 0 and mover.cell == definition.goal:
		complete = true
		mover.phase = "complete"
		mover.clear_held()
