extends Node3D
## Private ONE-WRITER demonstration. Synthetic commit, no Runtime finish/state API.
const Fixture = preload("res://tests/beta_sprint/game_feel_owner_10a/fixture.gd")
const Fall = preload("res://game/feel/animation/fall_landing/fall_motion.gd")
const Landing = preload("res://game/feel/animation/fall_landing/landing_motion.gd")
const Orientation = preload("res://foundation/orientation/discrete_orientation.gd")
var higher := false
var curved := false
var event: Dictionary
var motion = Fall.new()
var landing = Landing.new()
var visual := Node3D.new()
var camera := Camera3D.new()
var label := Label.new()
var elapsed := 0.0
var landing_elapsed := 0.0
var paused := false
var running := false
var is_committed := false
var settled := false
var busy_inputs := 0
var reset_inputs := 0
var pause_inputs := 0
var sample_state: Dictionary = {}
var authoritative_basis := Basis.IDENTITY

func _ready() -> void:
	event = Fixture.curve_event(higher) if curved else Fixture.event(higher)
	var columns: Array = Orientation.columns(event.source_pose.orientation)
	authoritative_basis = Basis(Vector3(columns[0]), Vector3(columns[1]), Vector3(columns[2]))
	visual.name = "PrivateVisualRoot"
	add_child(visual)
	var character: Node3D = load("res://production/art_3d/BG_CH_WAKABA_CUBE_001/godot/BG_CH_WAKABA_CUBE_001.tscn").instantiate()
	character.collision_layer = 0
	character.collision_mask = 0
	character.position.y = -0.5
	visual.add_child(character)
	for i in [0, -1]:
		var platform := MeshInstance3D.new()
		var mesh := BoxMesh.new()
		mesh.size = Vector3.ONE
		platform.mesh = mesh
		var material := StandardMaterial3D.new()
		material.albedo_color = Color("93b7b0") if i == 0 else Color("b2ad91")
		platform.material_override = material
		platform.position = endpoint(i == -1) - Vector3.UP
		add_child(platform)
		var text := Label3D.new()
		text.text = "SOURCE A" if i == 0 else "TARGET B"
		text.position = platform.position - Vector3(0,0.7,0)
		text.font_size = 32
		text.billboard = BaseMaterial3D.BILLBOARD_ENABLED
		add_child(text)
	var env := WorldEnvironment.new()
	env.environment = Environment.new()
	env.environment.background_mode = Environment.BG_COLOR
	env.environment.background_color = Color("18252d")
	env.environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.environment.ambient_light_color = Color.WHITE
	env.environment.ambient_light_energy = 0.75
	add_child(env)
	var light := DirectionalLight3D.new()
	light.rotation_degrees = Vector3(-40,-30,0)
	add_child(light)
	add_child(camera)
	camera.projection = Camera3D.PROJECTION_ORTHOGONAL
	camera.size = 8.0
	camera.current = true
	set_quadrant(1)
	var hud := CanvasLayer.new()
	add_child(hud)
	hud.add_child(label)
	label.position = Vector2(26,24)
	label.add_theme_font_size_override("font_size",18)
	restore_source()

func set_quadrant(quadrant: int) -> void:
	var focus := (endpoint(false) + endpoint(true)) * 0.5
	if curved:
		var rights := [Vector3(1,0,-1), Vector3(1,0,1), Vector3(-1,0,1), Vector3(-1,0,-1)]
		var downs := [Vector3(2,-3,2), Vector3(-2,-3,2), Vector3(-2,-3,-2), Vector3(2,-3,-2)]
		var right: Vector3 = rights[quadrant].normalized()
		var up: Vector3 = -downs[quadrant].normalized()
		var view := Basis(right, up, right.cross(up))
		camera.transform = Transform3D(view, focus + view.z * 20.0)
		return
	var yaw := PI / 4.0 - float(quadrant) * PI / 2.0
	camera.position = focus + Vector3(sin(yaw), 0.8 / sqrt(2.0), cos(yaw)) * 20.0
	camera.look_at(focus)

func launch() -> void:
	motion.clear()
	landing.clear()
	assert(motion.begin(event).ok)
	elapsed = 0.0
	landing_elapsed = 0.0
	is_committed = false
	settled = false
	running = true
	paused = false

func _process(delta: float) -> void:
	if running and not paused:
		if not is_committed:
			elapsed += delta
			sample_state = motion.sample(elapsed)
			apply(sample_state, endpoint(false))
			if sample_state.motion_done:
				# EXPLICIT NATIVE-COMMIT DOUBLE. No legal Fall or real commit claimed.
				is_committed = true
				motion.clear()
				assert(landing.begin(Fixture.committed(event)).ok)
		else:
			landing_elapsed += delta
			sample_state = landing.sample(landing_elapsed)
			apply(sample_state, endpoint(true))
			if sample_state.motion_done:
				settled = true
				running = false
				landing.clear()
	label.text = "10A PRIVATE PRESENTATION UNIT — authority=false\nMAP %s: target real %s; EAST fixed view\n%s | t=%.3f | native commit DOUBLE\nApproved Wakaba asset; experimental motion values\nWASD / Shift / Q/E / mouse: scoped input-double; P: Pause; R: Reset" % ["B" if higher else "A", "HIGHER +2" if higher else "LOWER -2", sample_state.get("phase", "IDLE"), elapsed + landing_elapsed]

func apply(value: Dictionary, fallback_position: Vector3) -> void:
	var position: Vector3 = value.position if value.position != null else fallback_position
	visual.transform = Transform3D(Basis(value.rotation_offset) * Basis.from_scale(value.scale_multiplier) * authoritative_basis, position)

func restore_source() -> void:
	running = false
	is_committed = false
	settled = false
	motion.cancel(event.presentation_identity)
	landing.cancel(event.presentation_identity)
	sample_state = {"phase": "CANCELLED_UNIT"}
	visual.transform = Transform3D(authoritative_basis, endpoint(false))

func endpoint(target: bool) -> Vector3:
	if curved:
		return Vector3(event.authorized_trajectory.descent_control_points2[-1] if target else event.authorized_trajectory.departure_points2[0]) * 0.5
	return Vector3(event.authorized_path_points2[-1] if target else event.authorized_path_points2[0]) * 0.5

func _input(input: InputEvent) -> void:
	if input is InputEventKey and input.pressed and not input.echo:
		if input.physical_keycode == KEY_R:
			reset_inputs += 1
			restore_source()
		elif input.physical_keycode == KEY_P:
			pause_inputs += 1
			paused = not paused
		elif running and input.physical_keycode in [KEY_W, KEY_A, KEY_S, KEY_D, KEY_SPACE, KEY_Q, KEY_E]:
			busy_inputs += 1
	elif running and (input is InputEventMouseMotion or input is InputEventMouseButton):
		busy_inputs += 1

func _exit_tree() -> void:
	motion.cancel(event.presentation_identity)
	landing.cancel(event.presentation_identity)
	motion.clear()
	landing.clear()
