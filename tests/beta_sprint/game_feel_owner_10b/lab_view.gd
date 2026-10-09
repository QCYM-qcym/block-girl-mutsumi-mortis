extends Node3D
## PRIVATE rendered Unit lab: native InputEvent/mapper, SYNTHETIC EDGE classification.
const Fixture = preload("res://tests/beta_sprint/game_feel_owner_10b/fixture.gd")
const Edge = preload("res://game/feel/animation/edge_recoil/edge_lean.gd")
const Mapper = preload("res://foundation/runtime/input_mapper.gd")
const Math = preload("res://foundation/orientation/discrete_orientation.gd")
var edge = Edge.new()
var actor: Node3D
var camera: Camera3D
var floor_mesh: MeshInstance3D
var label: Label
var world := 0
var quadrant := 0
var orientation := 0
var attempt := 0
var elapsed := 0.0
var paused := false
var held: Dictionary = {}
var order: Array[int] = []
var cues: Array = []
var samples: Array = []
var inputs: Array = []
var models: Array[Node3D] = []
var last_sample: Dictionary = {}
var base := Transform3D(Basis.IDENTITY, Vector3(0,0.5,0))

func _ready() -> void:
	var env := WorldEnvironment.new()
	env.environment = Environment.new()
	env.environment.background_mode = Environment.BG_COLOR
	env.environment.background_color = Color("1c2533")
	env.environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.environment.ambient_light_color = Color(0.8,0.85,0.95)
	env.environment.ambient_light_energy = 0.65
	add_child(env)
	var light := DirectionalLight3D.new()
	light.rotation_degrees = Vector3(-40,-30,0)
	light.shadow_enabled = true
	add_child(light)
	var fill := DirectionalLight3D.new()
	fill.rotation_degrees = Vector3(-25,145,0)
	fill.light_energy = 0.45
	add_child(fill)
	floor_mesh = MeshInstance3D.new()
	var box := BoxMesh.new()
	box.size = Vector3(1,0.2,1)
	floor_mesh.mesh = box
	floor_mesh.position.y = -0.1
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color("688b88")
	floor_mesh.material_override = mat
	add_child(floor_mesh)
	actor = Node3D.new()
	add_child(actor)
	for id in ["BG_CH_WAKABA_CUBE_001", "BG_CH_MORTIS_CUBE_001"]:
		var packed: PackedScene = load("res://production/art_3d/%s/godot/%s.tscn" % [id,id])
		var model: Node3D = packed.instantiate()
		if model is CollisionObject3D: model.collision_layer = 0; model.collision_mask = 0
		# Approved Art has a bottom origin. Normalize ONCE under centered actor.
		model.position = Vector3(0,-0.5,0)
		actor.add_child(model)
		models.append(model)
	camera = Camera3D.new()
	camera.projection = Camera3D.PROJECTION_ORTHOGONAL
	camera.size = 2.55
	camera.current = true
	add_child(camera)
	var canvas := CanvasLayer.new()
	add_child(canvas)
	label = Label.new()
	label.position = Vector2(20,20)
	label.add_theme_font_size_override("font_size",18)
	canvas.add_child(label)
	edge.cue.connect(func(name: String, identity: Dictionary): cues.append({"cue": name, "identity": identity, "elapsed": elapsed}))
	configure(0,0,0)

func configure(layer: int, view: int, pose: int) -> void:
	edge.clear()
	held.clear(); order.clear()
	world = layer; quadrant = view; orientation = pose; elapsed = 0
	var columns := Math.columns(pose)
	base = Transform3D(Basis(Vector3(columns[0]),Vector3(columns[1]),Vector3(columns[2])),Vector3(0,0.5,0))
	camera.position = Basis(Vector3.UP, view * PI / 2) * Vector3(0,2.8,4.8)
	camera.look_at(Vector3(0,0.5,0))
	for i in range(2): models[i].visible = i == layer
	apply_sample()

func _input(event: InputEvent) -> void:
	if not event is InputEventKey or event.echo: return
	var key: int = event.physical_keycode
	var mapping := {KEY_W: Vector2.UP, KEY_D: Vector2.RIGHT, KEY_S: Vector2.DOWN, KEY_A: Vector2.LEFT}
	if not mapping.has(key): return
	inputs.append({"key": key, "pressed": event.pressed, "quadrant": quadrant, "world": world, "attempt": attempt})
	if event.pressed:
		if held.has(key): return
		held[key] = mapping[key]; order.append(key)
	else:
		held.erase(key); order.erase(key)
	if order.is_empty(): edge.set_intent(null)
	else: try_held()

func try_held() -> void:
	var mapped := Mapper.map_move(Fixture.edge().source_frame, camera.global_basis, held[order.back()])
	if not mapped.ok: return
	edge.set_intent(mapped.action.face_axis)
	attempt += 1
	var event := Fixture.edge(attempt, mapped.action.face_axis, world, quadrant, orientation)
	if edge.begin(event).ok: elapsed = 0.0

func _process(delta: float) -> void:
	if not paused:
		if not order.is_empty(): try_held() # deliberately sends repeated synthetic attempts
		elapsed += delta
	apply_sample()
	if last_sample.active:
		samples.append({"elapsed": elapsed, "phase": last_sample.phase, "angle": last_sample.rotation_offset.get_angle(),
			"world": world, "quadrant": quadrant, "orientation": orientation, "attempt": last_sample.identity.attempt_id})

func apply_sample() -> void:
	last_sample = edge.sample(elapsed)
	var r := Basis(last_sample.rotation_offset)
	var p: Vector3 = edge.support_pivot_offset()
	# Private fixture only. This is the precise requested one-writer formula.
	actor.transform = Transform3D(r * base.basis, base.origin + p - r * p)
	label.text = "10B — PRESENTATION CONTRACT UNIT / SYNTHETIC EDGE\n%s • Camera %d • %s • %.1f°\nNative mapper/input, no Runtime permission/commit" % ["Surface / Wakaba" if world == 0 else "Inner / Mortis",quadrant,last_sample.phase,rad_to_deg(last_sample.rotation_offset.get_angle())]

func preempt() -> void:
	var id: Variant = last_sample.identity
	if id is Dictionary: edge.cancel(id)
	held.clear(); order.clear()
	apply_sample()
