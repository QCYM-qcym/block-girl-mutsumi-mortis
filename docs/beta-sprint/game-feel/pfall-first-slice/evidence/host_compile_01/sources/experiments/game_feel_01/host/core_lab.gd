extends Node3D
## Isolated 00 host. Real Facade owns all movement, camera state and Goal.
const Presenter = preload("res://game/feel/cube_presenter.gd")
const Fall = preload("res://game/feel/animation/fall_landing/fall_motion.gd")
const Landing = preload("res://game/feel/animation/fall_landing/landing_motion.gd")
const Geometry = preload("res://foundation/spatial/surface_geometry.gd")
const Orientation = preload("res://foundation/orientation/discrete_orientation.gd")
var runtime: RefCounted
var presenter := Presenter.new()
var actor: Node3D
var camera: Camera3D
var geometry_root: Node3D
var status: Label
var events: Array = []
var host_issues: Array = []
var map_letter := "a"
var paused := false
var _camera_motion: Dictionary = {}
var _view: Script
var _camera_center := Vector3.ZERO

func _ready() -> void:
	actor=Node3D.new()
	actor.name="AuthoritativeCubePose"
	add_child(actor)
	var body:=MeshInstance3D.new()
	body.mesh=BoxMesh.new()
	var material:=StandardMaterial3D.new()
	material.albedo_color=Color(0.45,0.78,0.5)
	body.material_override=material
	actor.add_child(body)
	var front:=MeshInstance3D.new()
	var marker:=BoxMesh.new()
	marker.size=Vector3(0.3,0.3,0.02)
	front.mesh=marker
	front.position.z=0.51
	var front_material:=StandardMaterial3D.new()
	front_material.albedo_color=Color(1.0,0.8,0.3)
	front.material_override=front_material
	actor.add_child(front)
	geometry_root=Node3D.new()
	add_child(geometry_root)
	camera=Camera3D.new()
	camera.projection=Camera3D.PROJECTION_ORTHOGONAL
	camera.size=14.0
	camera.current=true
	add_child(camera)
	var light:=DirectionalLight3D.new()
	light.rotation_degrees=Vector3(-45,-30,0)
	light.light_energy=1.5
	add_child(light)
	var canvas:=CanvasLayer.new()
	add_child(canvas)
	status=Label.new()
	status.position=Vector2(24,20)
	canvas.add_child(status)
	var row:=HBoxContainer.new()
	row.position=Vector2(24,135)
	canvas.add_child(row)
	for choice in ["A","B","Reset"]:
		var button:=Button.new()
		button.text=choice
		row.add_child(button)
		if choice=="Reset": button.pressed.connect(reset_lab)
		else: button.pressed.connect(load_map.bind(choice.to_lower()))
	var facade_path:="res://foundation/game_feel/runtime_facade.gd"
	var view_path:="res://foundation/game_feel/view_contract.gd"
	if not ResourceLoader.exists(facade_path) or not ResourceLoader.exists(view_path):
		_record_issue("01 formal Runtime delivery is not integrated; CORE NOT_READY.")
		return
	_view=load(view_path)
	runtime=load(facade_path).new()
	runtime.game_feel_event.connect(_on_event)
	runtime.committed.connect(_on_committed)
	presenter.bind(actor,Fall.new(),Landing.new(),project_pose,runtime.finish_transition)
	load_map("a")

func load_map(letter: String) -> void:
	if runtime==null: return
	var factory_path:="res://experiments/game_feel_01/maps/map_factory.gd"
	var factory: Script=load(factory_path)
	if not factory.has_method("bake_game_feel"):
		_record_issue("09 formal opt-in map delivery is not integrated; CORE NOT_READY.")
		return
	var baked: Dictionary=factory.bake_game_feel(factory.read_spec(letter))
	if not baked.ok:
		_record_issue(str(baked.issues))
		return
	_camera_motion={}
	presenter.clear()
	paused=false
	presenter.set_paused(false)
	runtime.set_paused(false)
	map_letter=letter
	var loaded: Dictionary=runtime.load_level(baked.level)
	if not loaded.ok:
		_record_issue(str(loaded.issues))
		return
	_build_geometry()
	_on_committed(runtime.get_state())

func project_pose(pose: Dictionary) -> Transform3D:
	var state: Dictionary=runtime.get_state()
	state.player=pose.duplicate(true)
	var resolved: Dictionary=Geometry.snapshot(runtime.get_level(),state)
	if not resolved.ok:
		_record_issue(str(resolved.issues))
		return Transform3D.IDENTITY
	var face: StringName=Geometry.face_id(pose.location.cube_id,pose.location.face)
	for anchor in resolved.value.anchors:
		if anchor.face_id==face and anchor.layer==pose.location.layer:
			var columns: Array=Orientation.columns(pose.orientation)
			return Transform3D(Basis(Vector3(columns[0]),Vector3(columns[1]),Vector3(columns[2])),Vector3(anchor.position2+anchor.frame.normal)*0.5)
	_record_issue("Formal player anchor missing.")
	return Transform3D.IDENTITY

func _build_geometry() -> void:
	for child in geometry_root.get_children():
		geometry_root.remove_child(child)
		child.queue_free()
	var state: Dictionary=runtime.get_state()
	var resolved: Dictionary=Geometry.snapshot(runtime.get_level(),state)
	if not resolved.ok:
		_record_issue(str(resolved.issues))
		return
	var bounds:=AABB()
	var first:=true
	for cube in resolved.value.cubes:
		var block:=MeshInstance3D.new()
		block.name=String(cube.cube_id)
		block.mesh=BoxMesh.new()
		var columns: Array=Orientation.columns(cube.orientation)
		block.transform=Transform3D(Basis(Vector3(columns[0]),Vector3(columns[1]),Vector3(columns[2])),Vector3(cube.center2)*0.5)
		var material:=StandardMaterial3D.new()
		material.albedo_color=Color(0.25,0.4,0.65) if cube.layer==0 else Color(0.45,0.3,0.55)
		if cube.cube_id==&"exit": material.albedo_color=Color(0.8,0.7,0.25)
		block.material_override=material
		geometry_root.add_child(block)
		bounds=AABB(block.position,Vector3.ZERO) if first else bounds.expand(block.position)
		first=false
	_camera_center=bounds.get_center()+Vector3.UP

func _on_event(event: Dictionary) -> void:
	events.append(event.duplicate(true))
	var result: Dictionary=presenter.consume_event(event)
	if not result.ok: _record_issue(str(result.issues))
	if event.semantic=="ACTION_FEEDBACK" and event.result.status==0 and event.result.changed and event.result.action.kind==9:
		_camera_motion={"token":event.transition_identity.duplicate(true),"source":camera.basis,"target":_view.basis(event.result.next_state.camera_quadrant),"elapsed":0.0}
	_update_status(event.reason_category)

func _on_committed(state: Dictionary) -> void:
	presenter.sync_pose(state.player)
	if _camera_motion.is_empty(): _place_camera(_view.basis(state.camera_quadrant))
	_update_status("NONE")

func _place_camera(basis: Basis) -> void:
	camera.transform=Transform3D(basis,_camera_center+basis.z*25.0)

func _process(delta: float) -> void:
	if runtime==null or not runtime.is_loaded() or paused: return
	presenter.tick(delta)
	if _camera_motion.is_empty(): return
	_camera_motion.elapsed+=delta
	var progress:=smoothstep(0.0,0.24,_camera_motion.elapsed)
	_place_camera(_camera_motion.source.slerp(_camera_motion.target,progress))
	if progress>=1.0:
		var token: Dictionary=_camera_motion.token.duplicate(true)
		_camera_motion={}
		runtime.finish_transition(token)

func reset_lab() -> void:
	if runtime==null or not runtime.is_loaded(): return
	_camera_motion={}
	presenter.clear()
	runtime.reset()
	_on_committed(runtime.get_state())

func _unhandled_key_input(event: InputEvent) -> void:
	if runtime==null or not runtime.is_loaded() or not event is InputEventKey or not event.pressed or event.echo: return
	match event.physical_keycode:
		KEY_ESCAPE:
			paused=not paused
			runtime.set_paused(paused)
			presenter.set_paused(paused)
			_update_status("PAUSED" if paused else "NONE")
		KEY_R: reset_lab()
		KEY_F:
			var state: Dictionary=runtime.get_state()
			var source: StringName=Geometry.face_id(state.player.location.cube_id,state.player.location.face)
			for connection in runtime.get_level().perspective_falls:
				if connection.source_face_id==source:
					runtime.request_action({"kind":8,"connection_id":connection.connection_id})
					break
		KEY_Q,KEY_E:
			var change:=1 if event.physical_keycode==KEY_E else -1
			runtime.request_action({"kind":9,"camera_quadrant":posmod(runtime.get_state().camera_quadrant+change,4)})
		KEY_SPACE: runtime.request_action({"kind":1})
		KEY_A,KEY_LEFT: runtime.request_move(Vector2.LEFT)
		KEY_D,KEY_RIGHT: runtime.request_move(Vector2.RIGHT)
		KEY_W,KEY_UP: runtime.request_move(Vector2.UP)
		KEY_S,KEY_DOWN: runtime.request_move(Vector2.DOWN)

func _notification(what: int) -> void:
	if what==NOTIFICATION_WM_CLOSE_REQUEST and runtime!=null:
		_camera_motion={}
		presenter.clear()
		runtime.interrupt("QUIT")

func _update_status(reason: String) -> void:
	if runtime==null or not runtime.is_loaded(): return
	var state: Dictionary=runtime.get_state()
	status.text="CORE laboratory / temporary isolated visuals / Art Audio UI integration pending\nMAP %s | camera %d | %s/%s | orientation %d | Goal %s\nWASD/arrows: Roll   F: authored Fall   Q/E: Camera   R: Reset   Esc: Pause\n%s"%[map_letter.to_upper(),state.camera_quadrant,state.player.location.layer,state.player.location.cube_id,state.player.orientation,state.goal_reached,reason]

func _record_issue(message: String) -> void:
	host_issues.append(message)
	if is_instance_valid(status): status.text=message
	push_error(message)
