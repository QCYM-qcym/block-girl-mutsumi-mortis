extends "res://experiments/game_feel_01/host/core_lab.gd"
## Isolated spatial experiment. Runtime owns every permission and result.
signal menu_requested
signal goal_reached(level_id: StringName)
signal native_motion_completed(identity: Dictionary, evidence: Dictionary)
signal native_motion_cancelled(identity: Dictionary, reason: String)
var lab_id: StringName = &"orientation_loop_lab"
var _description: Dictionary = {}
var _hint_visible := false
var _goal_announced := false
var _reduced_motion := false
var _shift_tween: Tween
var _shift_identity: Dictionary = {}
var _shift_target := Transform3D.IDENTITY
var _shift_completed_count := 0

func _ready() -> void:
	super._ready()
	# Replace only the old lab's A/B controls; the parent supplies real rendering.
	for child in get_children():
		if child is CanvasLayer:
			for control in child.get_children():
				if control is HBoxContainer: control.queue_free()
	status.position=Vector2(24,20)
	status.custom_minimum_size=Vector2(680,110)
	status.add_theme_color_override("font_shadow_color",Color.BLACK)
	status.add_theme_constant_override("shadow_offset_x",1)
	status.add_theme_constant_override("shadow_offset_y",1)
	_add_face_marks()
	_update_status("NONE")

func load_map(id: String) -> void:
	if runtime==null or _closed or external_runtime: return
	if id not in ["a","b"]: lab_id=StringName(id)
	var path:="res://experiments/spatial_puzzle_batch_01/maps/map_factory.gd"
	if not ResourceLoader.exists(path):
		_record_issue("Spatial Map Owner delivery is not integrated.")
		return
	var factory:Script=load(path)
	var baked:Dictionary=factory.bake(lab_id)
	if not baked.get("ok",false):
		_record_issue(str(baked.get("issues",["Map bake failed"])))
		return
	_cancel_shift("RELOAD")
	_camera_motion={};_scope={}
	presenter.clear("RELOAD");presenter.bind_scope({})
	set_lab_paused(false)
	_description=factory.describe(lab_id)
	_goal_announced=false
	var loaded:Dictionary=runtime.load_level(baked.level)
	if not loaded.ok:
		_record_issue(str(loaded.issues))
		return
	_build_geometry()
	_on_committed(runtime.get_state())

func _add_face_marks() -> void:
	var marks:=Node3D.new()
	marks.name="LocalFaceMarks"
	actor.add_child(marks)
	var normals:=[Vector3.FORWARD*-1,Vector3.FORWARD,Vector3.LEFT,Vector3.RIGHT,Vector3.UP,Vector3.DOWN]
	var colors:=[Color("ed7474"),Color("80b7ff"),Color("edce65"),Color("b48be6"),Color("f3f3df"),Color("76d2a4")]
	for index in 6:
		var mark:=MeshInstance3D.new()
		mark.name="LocalFace%d"%index
		mark.set_meta("local_face",index)
		var mesh:=BoxMesh.new()
		mesh.size=Vector3(0.55,0.55,0.015)
		mark.mesh=mesh
		var normal:Vector3=normals[index]
		mark.position=normal*0.512
		mark.basis=Basis.looking_at(normal,Vector3.FORWARD if abs(normal.y)>0.9 else Vector3.UP)
		var material:=StandardMaterial3D.new()
		material.albedo_color=colors[index]
		mark.material_override=material
		marks.add_child(mark)
		var label:=Label3D.new()
		label.text=str(index+1)
		label.font_size=64;label.pixel_size=0.006
		label.modulate=Color("172234")
		label.position.z=-0.02
		label.rotation.y=PI
		mark.add_child(label)

func _build_geometry() -> void:
	super._build_geometry()
	if runtime==null or not runtime.is_loaded(): return
	var level:Dictionary=runtime.get_level()
	var state:Dictionary=runtime.get_state()
	var targets:Array=[]
	for connection in level.get("perspective_falls",[]): targets.append(connection.target_face_id)
	var bounds:=AABB()
	var first:=true
	for block in geometry_root.get_children():
		if not block is MeshInstance3D: continue
		var id=block.get_meta("cube_id")
		var face=block.get_meta("top_face_id")
		for cube in level.get("cubes",[]):
			if cube.cube_id==id: block.visible=cube.layer==state.player.location.layer
		if targets.has(face):
			block.material_override.albedo_color=Color("ebcb4d")
			block.set_meta("presentation_role","FALL_TARGET_SUPPORT")
		elif face==level.goal.face_id:
			block.material_override.albedo_color=Color("69cc9b")
			block.set_meta("presentation_role","EXIT_GOAL")
		if block.visible:
			bounds=AABB(block.position,Vector3.ZERO) if first else bounds.expand(block.position)
			first=false
	if not first:
		_camera_center=bounds.get_center()+Vector3.UP
		camera.size=clampf(maxf(bounds.size.x,bounds.size.z)*1.5+6.0,10.0,40.0)

func _on_native_started(result: Dictionary, transaction_id: int, generation: int, is_global: bool) -> void:
	if result.get("action",{}).get("kind")!=1:
		super._on_native_started(result,transaction_id,generation,is_global)
		return
	if _closed or result.get("status")!=0 or not result.get("changed",false): return
	var identity:Dictionary=runtime.get_pending_identity(transaction_id,generation,is_global)
	if identity.is_empty() or not _identity_is_current(identity): return
	var projected:Dictionary=project_pose(result.next_state.player)
	if not projected.ok:
		_record_issue(str(projected.issues))
		return
	_cancel_shift("REPLACED")
	presenter.clear("WORLD_SHIFT")
	_shift_identity=identity.duplicate(true)
	_shift_target=projected.transform
	var source:=actor.transform
	_shift_tween=create_tween()
	_shift_tween.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	_shift_tween.tween_method(_sample_shift.bind(source,_shift_target),0.0,1.0,0.12 if _reduced_motion else 0.32)
	_shift_tween.finished.connect(_finish_shift.bind(identity.duplicate(true)))
	if paused: _shift_tween.pause()

func _identity_is_current(identity:Dictionary) -> bool:
	if runtime==null or not runtime.is_loaded(): return false
	var current:Dictionary=runtime.get_presentation_scope()
	for key in ["session_id","level_run_id","generation"]:
		if identity.get(key)!=current.get(key): return false
	return true

func _sample_shift(progress:float,source:Transform3D,target:Transform3D) -> void:
	if _shift_identity.is_empty() or not _identity_is_current(_shift_identity): return
	actor.transform=source.interpolate_with(target,progress)
	# Visual-only pulse remains within the single native Shift lifecycle.
	if not _reduced_motion: actor.scale*=1.0-0.08*sin(progress*PI)

func _finish_shift(identity:Dictionary) -> void:
	if _closed or paused or identity!=_shift_identity or not _identity_is_current(identity): return
	actor.transform=_shift_target
	_shift_identity={};_shift_tween=null
	var outcome:Dictionary=runtime.finish_transition(identity)
	if outcome.get("ignored",true): return
	_shift_completed_count+=1
	native_motion_completed.emit(identity,{"kind":"SHIFT_WORLD","visual_transform":actor.transform,"state":runtime.get_state(),"completion":"Tween.finished"})

func _cancel_shift(reason:String) -> void:
	if _shift_tween!=null and _shift_tween.is_valid(): _shift_tween.kill()
	_shift_tween=null
	var old:=_shift_identity
	_shift_identity={}
	if not old.is_empty(): native_motion_cancelled.emit(old,reason)

func _process(delta:float) -> void:
	if not _shift_identity.is_empty() and not _identity_is_current(_shift_identity): _cancel_shift("LIFECYCLE")
	super._process(delta)

func _on_committed(state:Dictionary) -> void:
	super._on_committed(state)
	if _closed or runtime==null or not runtime.is_loaded(): return
	_build_geometry()
	if _camera_motion.is_empty(): _place_camera(_view.basis(state.camera_quadrant))
	var result:Dictionary=Goal.is_goal(runtime.get_level(),state)
	if result.ok and result.is_goal and not _goal_announced:
		_goal_announced=true
		goal_reached.emit(lab_id)

func reset_lab() -> void:
	_cancel_shift("RESET")
	_goal_announced=false
	super.reset_lab()

func set_lab_paused(value:bool) -> void:
	paused=value
	if runtime!=null: runtime.set_paused(value)
	presenter.set_paused(value)
	if _shift_tween!=null and _shift_tween.is_valid():
		if value: _shift_tween.pause()
		else: _shift_tween.play()
	_update_status("PAUSED" if value else "NONE")

func set_reduced_motion(value:bool) -> void:
	_reduced_motion=value
	presenter.set_reduced_motion(value)

func toggle_hint() -> void:
	_hint_visible=not _hint_visible
	_update_status("NONE")

func _unhandled_key_input(event:InputEvent) -> void:
	if not event is InputEventKey or not event.pressed or event.echo: return
	if event.physical_keycode==KEY_H:
		toggle_hint();get_viewport().set_input_as_handled();return
	if event.physical_keycode==KEY_ESCAPE:
		set_lab_paused(not paused);get_viewport().set_input_as_handled();return
	if runtime==null or not runtime.is_loaded(): return
	if event.physical_keycode==KEY_F:
		runtime.request_action({"kind":0,"face_axis":2})
		get_viewport().set_input_as_handled()
		return
	super._unhandled_key_input(event)

func _input(event:InputEvent) -> void:
	super._input(event)
	if event is InputEventKey and not event.pressed and event.physical_keycode==KEY_F: presenter.release_edge_intent()

func _update_status(reason:String) -> void:
	if not is_instance_valid(status) or runtime==null or not runtime.is_loaded(): return
	var state:Dictionary=runtime.get_state()
	var result:Dictionary=Goal.is_goal(runtime.get_level(),state)
	status.text="%s  |  %s  |  视角 %s\n%s\nWASD / 方向键：翻滚   F：向标记边缘前进   Q/E：视角   Space：转换   R：重置   Esc：暂停   H：提示\n%s"%[_description.get("title",String(lab_id)),"表世界" if state.player.location.layer==0 else "里世界",["北","东","南","西"][state.camera_quadrant],_description.get("objective","观察实体六面与正式路线"),"已抵达目标" if result.ok and result.is_goal else ("暂停" if paused else ("" if reason=="NONE" else reason))]
	if _hint_visible: status.text+="\n提示："+str(_description.get("hint","观察落脚面、转换标记与相机方向。"))

func _close(reason:String) -> void:
	_cancel_shift(reason)
	super._close(reason)
