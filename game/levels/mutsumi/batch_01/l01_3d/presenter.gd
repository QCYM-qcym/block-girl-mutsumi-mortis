extends Node3D
## Reads the Content runtime; transforms and VFX never feed rule decisions.
const ART := "res://production/art_3d/"
const RECONSTRUCTION = preload("res://production/art_3d/world_shift/reconstruction.gdshader")
const WALK := 0.24
const DISPLAY_ORIGIN := Vector3(-6.5, 0, -2.5)
const SHIFT_COMMIT := 0.60
const SHIFT_SECONDS := 0.25 / SHIFT_COMMIT
var graph
var mover
var view
var definition: Resource
var camera: Camera3D
var actor: Node3D
var world_roots: Array[Node3D] = []
var actor_visuals: Array[Node3D] = []
var assets: Array[Dictionary] = []
var materials: Array[Dictionary] = []
var mechanisms: Array[Dictionary] = []
var environment: Environment
var key_light: DirectionalLight3D
var transition_progress := 1.0
var shift_active := false
var shift_committed := false
var source_world := 0
var target_world := 1
var camera_angle := 0.0
var occlusion: Dictionary = {}
var _last_phase := "idle"
var _occlusion_age: Dictionary = {}
var _fade_shader: Shader

func bind(state, movement, perspective, data: Resource) -> void:
	graph = state
	mover = movement
	view = perspective
	definition = data
	_build_lighting()
	_build_assets()
	reset_visuals()

func _build_lighting() -> void:
	var world_environment := WorldEnvironment.new()
	environment = Environment.new()
	environment.background_mode = Environment.BG_COLOR
	environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	environment.ambient_light_color = Color(0.76, 0.83, 0.92)
	environment.ambient_light_energy = 0.52
	environment.tonemap_mode = Environment.TONE_MAPPER_ACES
	world_environment.environment = environment
	add_child(world_environment)
	key_light = DirectionalLight3D.new()
	key_light.rotation_degrees = Vector3(-48, -32, 0)
	key_light.light_energy = 0.52
	key_light.light_angular_distance = 3
	key_light.shadow_enabled = true
	add_child(key_light)
	var fill := DirectionalLight3D.new()
	fill.rotation_degrees = Vector3(-28, 145, 0)
	fill.light_energy = 0.22
	add_child(fill)
	camera = Camera3D.new()
	camera.name = "FourViewCamera"
	camera.projection = Camera3D.PROJECTION_ORTHOGONAL
	camera.near = 0.01
	camera.far = 100
	camera.current = true
	add_child(camera)

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
			# A real two-cell bridge replaces exactly these existing flat cells.
			if cell in [Vector2i(1, 0), Vector2i(2, 0), graph.PLATE]:
				continue
			_add_asset("BG_ENV_%s_FLOOR_001" % interpretation, root,
				Vector2(cell), graph.nodes[cell], world, true)
		_add_asset("BG_ENV_%s_BRIDGE_001" % interpretation, root,
			Vector2(1.5, 0), 0, world, true)
		var mapping: Dictionary = {}
		mapping.plate = _add_asset("BG_MEC_%s_PRESSURE_PLATE_001" % interpretation,
			root, Vector2(graph.PLATE), 1, world, true)
		mapping.gate = _add_asset("BG_MEC_%s_GATE_001" % interpretation,
			root, Vector2(11.5, 0), 1, world, false, PI / 2)
		mapping.exit = _add_asset("BG_MEC_%s_EXIT_001" % interpretation,
			root, Vector2(definition.goal), 1, world, false, PI / 2)
		# Space remains the existing global action. This device is a visual cue.
		mapping.world_switch = _add_asset("BG_MEC_%s_WORLD_SWITCH_001" % interpretation,
			root, Vector2(definition.spawn) + Vector2(1.4, 0), 0, world, false)
		mechanisms.append(mapping)
		var character_id := "BG_CH_WAKABA_CUBE_001" if world == 0 else "BG_CH_MORTIS_CUBE_001"
		var character := _instance(character_id)
		actor.add_child(character)
		character.position.y = -0.5
		actor_visuals.append(character)
		_register_materials(character, world, false, "character", true)

func _instance(id: String) -> Node3D:
	var scene: PackedScene = load(ART + id + "/godot/" + id + ".tscn")
	var instance: Node3D = scene.instantiate()
	instance.set_meta("approved_asset_id", id)
	_disable_asset_physics(instance)
	return instance

func _disable_asset_physics(node: Node) -> void:
	# Existing discrete occupancy owns collision, just as the retained Pixel board.
	if node is CollisionObject3D:
		node.collision_layer = 0
		node.collision_mask = 0
	if node is Area3D:
		node.monitoring = false
		node.monitorable = false
	for child in node.get_children():
		_disable_asset_physics(child)

func _add_asset(id: String, root: Node3D, cell: Vector2, platform: int,
		world: int, walkable: bool, yaw: float = 0.0) -> Node3D:
	var instance := _instance(id)
	root.add_child(instance)
	instance.rotation.y = yaw
	var manifest: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(
		ART + id + "/reports/asset_manifest.json"))
	var height: float = float(manifest.logical.height_contract.get("walk_surface", 0.0))
	var row := {"node": instance, "cell": cell, "platform": platform,
		"world": world, "walkable": walkable, "height_offset": WALK - height}
	assets.append(row)
	_register_materials(instance, world, walkable, id, false)
	return instance

func _register_materials(instance: Node3D, world: int, walkable: bool,
		slot: String, character: bool) -> void:
	if _fade_shader == null:
		# The approved Runtime uses alpha for occluders; reconstruction stays intact.
		_fade_shader = Shader.new()
		_fade_shader.code = RECONSTRUCTION.code.replace(
			"if(conceal>0.0 && stipple<conceal) discard;", "ALPHA=1.0-conceal;")
	for mesh in instance.find_children("*", "MeshInstance3D", true, false):
		if mesh.mesh == null:
			continue
		for surface in mesh.mesh.get_surface_count():
			var original: Material = mesh.get_active_material(surface)
			var shader := ShaderMaterial.new()
			shader.shader = RECONSTRUCTION
			if original is BaseMaterial3D:
				shader.set_shader_parameter("base_color", original.albedo_color)
				shader.set_shader_parameter("color_tex", original.albedo_texture)
				shader.set_shader_parameter("use_tex", original.albedo_texture != null)
				shader.set_shader_parameter("roughness_value", original.roughness)
				shader.set_shader_parameter("metallic_value", original.metallic)
				var glow := Vector3.ZERO
				if original.emission_enabled:
					glow = Vector3(original.emission.r, original.emission.g, original.emission.b) * original.emission_energy_multiplier
				shader.set_shader_parameter("glow_color", glow)
			shader.set_shader_parameter("character", 1.0 if character else 0.0)
			var fade: ShaderMaterial = shader.duplicate()
			fade.shader = _fade_shader
			materials.append({"mesh": mesh, "surface": surface, "original": original,
				"shader": shader, "fade": fade, "world": world, "floor": walkable, "slot": slot})

func platform_offset(platform: int) -> Vector2:
	if platform == 0:
		return Vector2.ZERO
	var offset: Vector2 = view.platform_b_offsets[view.current]
	if view.busy:
		var other: int = posmod(view.current + view.rotation_step, 4)
		offset = offset.lerp(view.platform_b_offsets[other], view.progress)
	return offset

func displayed_position(cell: Vector2, platform: int) -> Vector3:
	var point := cell + platform_offset(platform)
	return Vector3(point.x, WALK, point.y) + DISPLAY_ORIGIN

func sync(delta: float) -> void:
	if mover == null:
		return
	_update_shift(delta)
	for row in assets:
		row.node.position = displayed_position(row.cell, row.platform)
		row.node.position.y = row.height_offset
		row.node.visible = (shift_active or row.world == mover.world)
		if row.walkable and shift_active and not shift_committed and row.world == target_world:
			row.node.visible = false
	for world in 2:
		world_roots[world].visible = shift_active or world == mover.world
		actor_visuals[world].visible = shift_active or world == mover.world
	_update_actor()
	_update_mechanisms()
	_update_camera()
	_update_occlusion(delta)
	_apply_materials()
	var palette: float = float(mover.world)
	if shift_active:
		var blend := smoothstep(0.16, 0.95, transition_progress)
		palette = blend if target_world == 1 else 1.0 - blend
	environment.background_color = Color(0.61, 0.70, 0.72).lerp(Color(0.18, 0.23, 0.29), palette)
	key_light.light_color = Color(1, 0.98, 0.91).lerp(Color(0.86, 0.93, 1), palette)
	_last_phase = mover.phase

func _update_actor() -> void:
	var position_3d := displayed_position(Vector2(mover.cell), graph.nodes[mover.cell])
	var pose: Basis = mover.orientation.as_basis()
	var lift := 0.0
	if mover.moving:
		var fraction: float = mover.fraction
		position_3d = position_3d.lerp(displayed_position(Vector2(mover.destination),
			graph.nodes[mover.destination]), fraction)
		var angle := fraction * PI / 2
		pose = Basis(Vector3(mover.direction.y, 0, -mover.direction.x), angle) * pose
		lift = 0.5 * (sin(angle) + cos(angle) - 1.0)
	actor.transform = Transform3D(pose, position_3d + Vector3(0, 0.5 + lift, 0))

func _update_shift(delta: float) -> void:
	if mover.phase == "shift" and _last_phase != "shift":
		source_world = mover.world
		target_world = 1 - source_world
		shift_active = true
		shift_committed = false
		transition_progress = 0.0
	if not shift_active:
		return
	if mover.world != source_world:
		if not shift_committed:
			shift_committed = true
			transition_progress = SHIFT_COMMIT
		else:
			transition_progress = minf(1.0, transition_progress + delta / SHIFT_SECONDS)
	elif mover.phase == "shift":
		transition_progress = minf(SHIFT_COMMIT, mover.elapsed / SHIFT_SECONDS)
	else:
		# Reset/cancellation observed through the inherited state, never by callbacks.
		shift_active = false
		transition_progress = 1.0
	if transition_progress >= 1.0:
		shift_active = false

func _update_mechanisms() -> void:
	var gate_open: bool = graph.door_open
	if mover.moving and mover.cell == graph.PLATE and mover.destination == graph.BEYOND_GATE:
		gate_open = true
	for world in 2:
		var pair := mechanisms[world]
		pair.plate.set_visual_state("pressed" if graph.plate_pressed else "inactive")
		pair.gate.set_visual_state("open" if gate_open else "closed")
		pair.exit.set_visual_state("complete" if graph.complete else "available" if mover.world == 0 else "locked")
		pair.world_switch.set_visual_state("switching" if mover.phase == "shift" else "completed" if shift_active and shift_committed else "available", transition_progress)

func _update_camera() -> void:
	# CubeVisual uses +Y observation rotation; a real orbit uses its inverse.
	camera_angle = PI / 4 - view.displayed_angle()
	var target := Vector3.ZERO
	camera.position = target + Vector3(sin(camera_angle), 0.8 / sqrt(2.0), cos(camera_angle)) * 20
	camera.look_at(target)
	var bounds := Rect2()
	var first := true
	for row in assets:
		for mesh in row.node.find_children("*", "MeshInstance3D", true, false):
			if mesh.mesh == null:
				continue
			var box: AABB = mesh.get_aabb()
			for corner in 8:
				var point: Vector3 = camera.global_basis.inverse() * (mesh.global_transform * box.get_endpoint(corner))
				var projected := Vector2(point.x, point.y)
				if first:
					bounds = Rect2(projected, Vector2.ZERO)
					first = false
				else:
					bounds = bounds.expand(projected)
	# One fixed cube envelope keeps framing steady during rolls.
	for cell in graph.nodes:
		for offset in [Vector3(-0.75, 0, -0.75), Vector3(0.75, 1.5, 0.75)]:
			var point: Vector3 = camera.global_basis.inverse() * (displayed_position(Vector2(cell), graph.nodes[cell]) + offset)
			bounds = bounds.expand(Vector2(point.x, point.y))
	var viewport_size: Vector2 = get_viewport().get_visible_rect().size
	var aspect := viewport_size.x / maxf(1.0, viewport_size.y)
	camera.size = maxf(bounds.size.y + 1.1, (bounds.size.x + 1.1) / aspect)
	var middle := bounds.get_center()
	target = camera.global_basis.x * middle.x + camera.global_basis.y * middle.y
	camera.position = target + Vector3(sin(camera_angle), 0.8 / sqrt(2.0), cos(camera_angle)) * 20
	camera.look_at(target)

func _world_mesh_bounds(root: Node3D) -> AABB:
	var result := AABB()
	var first := true
	for mesh in root.find_children("*", "MeshInstance3D", true, false):
		if mesh.mesh == null or not mesh.is_visible_in_tree():
			continue
		var box: AABB = mesh.global_transform * mesh.get_aabb()
		result = box if first else result.merge(box)
		first = false
	return result

func _update_occlusion(delta: float) -> void:
	var eye := camera.global_position
	var aim := actor.global_position
	for world in 2:
		for kind in ["gate", "exit"]:
			var key := "%s:%s" % [world, kind]
			var node: Node3D = mechanisms[world][kind]
			var box := _world_mesh_bounds(node)
			var margin := 0.22 if occlusion.get(key, false) else 0.15
			var hit: bool = node.is_visible_in_tree() and box.has_volume() and box.grow(margin).intersects_segment(eye, aim) != null
			if hit:
				occlusion[key] = true
				_occlusion_age[key] = 0.0
			else:
				_occlusion_age[key] = float(_occlusion_age.get(key, 0.0)) + delta
				if _occlusion_age[key] >= 0.10 or not node.is_visible_in_tree():
					occlusion[key] = false

func _apply_materials() -> void:
	var wave := smoothstep(0.08, 0.96, transition_progress)
	for row in materials:
		var kind := "gate" if "_GATE_" in row.slot else "exit" if "_EXIT_" in row.slot else ""
		var obscured: bool = not kind.is_empty() and occlusion.get("%s:%s" % [row.world, kind], false)
		row.mesh.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF if obscured else GeometryInstance3D.SHADOW_CASTING_SETTING_ON
		if not shift_active and not obscured:
			row.mesh.set_surface_override_material(row.surface, row.original)
			continue
		var reveal: float = wave
		if row.floor:
			reveal = smoothstep(SHIFT_COMMIT, 0.93, transition_progress) if shift_committed else 0.0
		var incoming: bool = row.world == target_world if shift_active else row.world == mover.world
		var material: ShaderMaterial = row.fade if obscured else row.shader
		material.set_shader_parameter("incoming", 1.0 if incoming else 0.0)
		material.set_shader_parameter("progress", reveal if shift_active else 1.0)
		material.set_shader_parameter("intensity", sin(transition_progress * PI) if shift_active else 0.0)
		material.set_shader_parameter("conceal", 0.84 if obscured else 0.0)
		row.mesh.set_surface_override_material(row.surface, material)

func reset_visuals() -> void:
	shift_active = false
	shift_committed = false
	transition_progress = 1.0
	occlusion.clear()
	_occlusion_age.clear()
	_last_phase = mover.phase
	sync(0.0)

func debug_snapshot() -> Dictionary:
	return {"world": mover.world, "phase": mover.phase, "fraction": mover.fraction,
		"view": view.current, "camera_angle": camera_angle, "physical_basis": mover.orientation.as_basis(),
		"actor_basis": actor.basis, "displayed_worlds": [world_roots[0].visible, world_roots[1].visible],
		"gate_state": mechanisms[mover.world].gate.state_id,
		"plate_state": mechanisms[mover.world].plate.state_id,
		"exit_state": mechanisms[mover.world].exit.state_id,
		"shift_progress": transition_progress if shift_active else 0.0, "shift_committed": shift_committed,
		"incoming_walk_surface_reveal": smoothstep(SHIFT_COMMIT, 0.93, transition_progress) if shift_active and shift_committed else 0.0,
		"occlusion": occlusion.duplicate(), "camera_size": camera.size}
