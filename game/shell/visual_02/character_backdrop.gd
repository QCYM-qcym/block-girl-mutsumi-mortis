extends SubViewportContainer
## Presentation only: approved meshes in a private world, never gameplay nodes.
const MODELS := [
 "res://production/art_3d/BG_CH_WAKABA_CUBE_001/export/BG_CH_WAKABA_CUBE_001.glb",
 "res://production/art_3d/BG_CH_MORTIS_CUBE_001/export/BG_CH_MORTIS_CUBE_001.glb"
]
var _viewport: SubViewport
var _stage: Node3D
var _character: Node3D
var _camera: Camera3D
var _environment: Environment
var _floor_material: StandardMaterial3D
var _layer := 0
var _active := true
var _reduced := false
var _focused := true
var _phase := 0.0
var _gesture := 0.0
var _gesture_kind := ""
var _bounds := AABB()

func _ready() -> void:
 mouse_filter = Control.MOUSE_FILTER_IGNORE
 stretch = true
 _viewport = SubViewport.new()
 _viewport.name = "Viewport"
 _viewport.own_world_3d = true
 _viewport.transparent_bg = false
 _viewport.handle_input_locally = false
 _viewport.gui_disable_input = true
 add_child(_viewport)
 _stage = Node3D.new()
 _stage.name = "Stage"
 _viewport.add_child(_stage)
 _environment = Environment.new()
 _environment.background_mode = Environment.BG_COLOR
 _environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
 _environment.ambient_light_color = Color("e1e4d9")
 _environment.ambient_light_energy = 0.8
 _environment.tonemap_mode = Environment.TONE_MAPPER_FILMIC
 var world := WorldEnvironment.new()
 world.environment = _environment
 _stage.add_child(world)
 var light := DirectionalLight3D.new()
 light.rotation_degrees = Vector3(-48, -32, 0)
 light.light_energy = 1.25
 light.shadow_enabled = true
 light.light_angular_distance = 12.0
 light.directional_shadow_max_distance = 30.0
 _stage.add_child(light)
 var fill := DirectionalLight3D.new()
 fill.rotation_degrees = Vector3(-20, 145, 0)
 fill.light_energy = 0.35
 _stage.add_child(fill)
 var ground := MeshInstance3D.new()
 var plane := PlaneMesh.new()
 plane.size = Vector2(200, 200)
 ground.mesh = plane
 _floor_material = StandardMaterial3D.new()
 _floor_material.roughness = 1.0
 _floor_material.metallic = 0.0
 ground.material_override = _floor_material
 _stage.add_child(ground)
 _character = Node3D.new()
 _character.name = "Character"
 _stage.add_child(_character)
 _camera = Camera3D.new()
 _camera.projection = Camera3D.PROJECTION_ORTHOGONAL
 _camera.size = 4.8
 _camera.position = Vector3(0, 3.2, 10)
 _stage.add_child(_camera)
 _camera.look_at(Vector3(0, 1.9, 0))
 _camera.current = true
 resized.connect(_resize)
 visibility_changed.connect(_sync_activity)
 _load_model()
 _resize()
 _sync_activity()

func set_world_layer(layer: int) -> void:
 var next := 1 if layer == 1 else 0
 if _layer == next: return
 _layer = next
 if is_instance_valid(_character): _load_model()

func set_reduced_motion(value: bool) -> void:
 _reduced = value
 if value: _gesture = 0.0
 _sync_activity()

func set_active(value: bool) -> void:
 _active = value
 _sync_activity()

func request_motion(kind: String) -> void:
 if _reduced or not _can_render(): return
 if kind in ["turn", "lean"]:
  _gesture_kind = kind
  _gesture = 1.0

func _load_model() -> void:
 for child in _character.get_children():
  _character.remove_child(child)
  child.free()
 var scene: PackedScene = load(MODELS[_layer])
 var model := scene.instantiate() as Node3D
 model.name = "Model"
 _character.add_child(model)
 _visual_only(model)
 _bounds = _mesh_bounds(model, model)
 var height := maxf(_bounds.size.y, 0.01)
 var factor := 3.6 / height
 model.scale *= factor
 model.position = -_bounds.get_center() * factor
 model.position.y = -_bounds.position.y * factor
 _gesture = 0.0
 _environment.background_color = Color("d9e0d3") if _layer == 0 else Color("191d27")
 _floor_material.albedo_color = Color("bfcab6") if _layer == 0 else Color("30323e")
 _pose()

func _visual_only(node: Node) -> void:
 node.set_script(null)
 node.process_mode = Node.PROCESS_MODE_DISABLED
 for child in node.get_children():
  if child is CollisionObject3D or child is CollisionShape3D or child is AnimationPlayer:
   node.remove_child(child)
   child.free()
  else:
   _visual_only(child)

func _mesh_bounds(node: Node, origin: Node3D) -> AABB:
 var result := AABB()
 if node is MeshInstance3D:
  result = (origin.global_transform.affine_inverse() * node.global_transform) * node.get_aabb()
 for child in node.get_children():
  var next := _mesh_bounds(child, origin)
  if next.size.length_squared() > 0:
   result = next if result.size.length_squared() == 0 else result.merge(next)
 return result

func _resize() -> void:
 if not is_instance_valid(_viewport): return
 _pose()

func _can_render() -> bool:
 return _active and _focused and is_inside_tree() and is_visible_in_tree()

func _sync_activity() -> void:
 if not is_instance_valid(_viewport): return
 var rendering := _can_render()
 _viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS if rendering else SubViewport.UPDATE_DISABLED
 set_process(rendering and not _reduced)

func _notification(what: int) -> void:
 if what == MainLoop.NOTIFICATION_APPLICATION_FOCUS_OUT or what == MainLoop.NOTIFICATION_APPLICATION_PAUSED:
  _focused = false
  _sync_activity()
 elif what == MainLoop.NOTIFICATION_APPLICATION_FOCUS_IN or what == MainLoop.NOTIFICATION_APPLICATION_RESUMED:
  _focused = true
  _sync_activity()

func _process(delta: float) -> void:
 _phase += minf(delta, 0.05)
 _gesture = maxf(0.0, _gesture - delta * 0.7)
 _pose()

func _pose() -> void:
 if not is_instance_valid(_character): return
 var action := sin(_gesture * PI) * 0.065
 var yaw := sin(_phase * 0.45) * 0.035 + (action if _gesture_kind == "turn" else 0.0)
 var lean := sin(_phase * 0.63) * 0.009 + (action if _gesture_kind == "lean" else 0.0)
 _character.rotation = Vector3(0, -0.10 + yaw, lean)
 # Ground the transformed mesh bounds, rather than empty corners of their union.
 var aspect := size.x / maxf(size.y, 1.0)
 _character.position = Vector3(4.8 * aspect * 0.17, 0, 0)
 var transformed := _mesh_bounds(_character, _stage)
 _character.position.y = -transformed.position.y

func debug_state() -> Dictionary:
 return {"world_layer":_layer, "model_path":MODELS[_layer], "active":_active, "reduced_motion":_reduced, "rendering":_can_render(), "pose":_character.transform if is_instance_valid(_character) else Transform3D.IDENTITY}

func _exit_tree() -> void:
 set_process(false)
 if is_instance_valid(_viewport): _viewport.render_target_update_mode = SubViewport.UPDATE_DISABLED
