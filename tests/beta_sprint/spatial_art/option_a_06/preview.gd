extends SceneTree
## Isolated visual review. Official scene and Runtime; no OS input injection.
const Key = preload("res://foundation/contracts/state_key.gd")
const NAMES = ["NORTH", "EAST", "SOUTH", "WEST"]
var shell
var level
var host
var evidence := ""
var checks := 0
var failures: Array[String] = []
var captures: Array = []
var actions: Array = []
var overlay: CanvasLayer
var badge: Label
var study: MeshInstance3D
var materials: Dictionary = {}

func _initialize() -> void:
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--evidence="): evidence = arg.trim_prefix("--evidence=")
	call_deferred("run")

func check(ok: bool, message: String) -> void:
	checks += 1
	if not ok:
		failures.append(message)
		printerr("A06 CHECK: ", message)

func settle(frames: int = 8) -> void:
	for frame in frames: await process_frame

func block_external_input(node: Node) -> void:
	# Only this copied test tree is affected; process/animation callbacks stay live.
	node.set_process_input(false)
	node.set_process_unhandled_input(false)
	node.set_process_unhandled_key_input(false)
	for child in node.get_children(): block_external_input(child)

func shader_material(path: String) -> ShaderMaterial:
	var shader := Shader.new()
	shader.code = FileAccess.get_file_as_string(path)
	var result := ShaderMaterial.new()
	result.shader = shader
	return result

func roof_node() -> MeshInstance3D:
	return host.geometry_root.get_node("roof") as MeshInstance3D

func geometry() -> Array:
	var result: Array = []
	for node in host.geometry_root.get_children():
		if node is MeshInstance3D:
			result.append({"cube":str(node.get_meta("cube_id")), "transform":str(node.transform),
				"mesh_rid":str(node.mesh.get_rid()), "bounds":str(node.mesh.get_aabb()),
				"faces_sha256":node.mesh.get_faces().to_byte_array().hex_encode().sha256_text(),
				"visible":node.visible, "cast_shadow":node.cast_shadow})
	return result

func lighting() -> Array:
	var result: Array = []
	for child in host.get_children():
		if child is Light3D:
			result.append({"class":child.get_class(),"transform":str(child.transform),
				"color":str(child.light_color),"energy":child.light_energy,"shadow":child.shadow_enabled})
	return result

func action(value: Dictionary) -> void:
	var before: Dictionary = host.runtime.get_state().duplicate(true)
	var result: Dictionary = host.runtime.request_action(value)
	check(result.status == 0, "formal action accepted: "+str(value))
	var deadline := Time.get_ticks_msec()+6000
	while (not host.runtime.is_idle() or host.presenter.snapshot().phase != "IDLE" or not host._camera_motion.is_empty() or not host._shift_identity.is_empty()) and Time.get_ticks_msec()<deadline:
		await process_frame
	check(host.runtime.is_idle() and host.presenter.snapshot().phase == "IDLE" and host._camera_motion.is_empty() and host._shift_identity.is_empty(), "natural formal completion")
	var after: Dictionary = host.runtime.get_state().duplicate(true)
	actions.append({"action":value,"status":result.status,"before":before,"after":after,
		"statekey":Key.build(host.runtime.get_level(),after).key,"commit_count":host.runtime.get_commit_count()})
	if value.kind == 9: check(before.player == after.player, "Camera preserves pose and orientation")
	await settle()

func camera_to(q: int) -> void:
	if host.runtime.get_state().camera_quadrant != q:
		await action({"kind":9,"camera_quadrant":q})

func make_badge() -> void:
	overlay = CanvasLayer.new()
	overlay.layer = 100
	root.add_child(overlay)
	badge = Label.new()
	badge.position = Vector2(24,146)
	badge.add_theme_font_size_override("font_size",16)
	badge.add_theme_color_override("font_color",Color("182c34"))
	badge.add_theme_color_override("font_outline_color",Color("d9e8e5"))
	badge.add_theme_constant_override("outline_size",2)
	badge.mouse_filter = Control.MOUSE_FILTER_IGNORE
	overlay.add_child(badge)

func capture_variant(context: String, variant: String, q: int, roof: MeshInstance3D, reference_material: Material) -> void:
	var official_state: Dictionary = host.runtime.get_state().duplicate(true)
	var official_level: Dictionary = host.runtime.get_level().duplicate(true)
	var official_geometry := geometry()
	var official_camera: Transform3D = host.camera.transform
	var official_light := lighting()
	var official_actor: Transform3D = host.actor.transform
	var original_commits: int = host.runtime.get_commit_count()
	var selected: Material = reference_material if variant == "CURRENT" else materials[variant]
	if context == "INNER_MATERIAL_STUDY": study.material_override = selected
	else: roof.material_override = selected
	badge.text = "隔离预览 · %s · %s · %s" % [context,variant,NAMES[q]]
	if context == "INNER_MATERIAL_STUDY": badge.text += "\n人工材质样张（非 Gameplay）；原关卡 Inner 没有该遮光体"
	elif not roof.visible: badge.text += "\n正式 Inner：Surface 遮光体按原规则隐藏，材质不在画面中"
	await settle(10)
	check(host.runtime.get_state()==official_state and host.runtime.get_level()==official_level, "variant preserves official state and level")
	check(host.runtime.get_commit_count()==original_commits, "material produces no commit")
	check(geometry()==official_geometry, "variant preserves mesh, transform, visibility, shadow")
	check(host.camera.transform==official_camera and lighting()==official_light, "same camera and light within comparison")
	check(host.actor.transform==official_actor, "variant preserves actor pose")
	await RenderingServer.frame_post_draw
	var pixels: Image = root.get_texture().get_image()
	check(pixels != null and pixels.get_size()==Vector2i(1280,720), "native 1280x720 frame")
	var filename := "%s_%s_q%d.png" % [context,variant,q]
	var path := evidence.path_join(filename)
	check(not FileAccess.file_exists(path), "fresh capture path")
	check(pixels.save_png(path)==OK, "save actual pixels")
	captures.append({"file":filename,"sha256":FileAccess.get_sha256(path),"context":context,"variant":variant,
		"quadrant":q,"camera_name":NAMES[q],"world":official_state.player.location.layer,
		"statekey":Key.build(official_level,official_state).key,"state":official_state,
		"camera_transform":str(official_camera),"camera_size":host.camera.size,"keep_aspect":host.camera.keep_aspect,
		"roof_visible_in_gameplay":roof.visible,"roof_transform":str(roof.transform),"actor_transform":str(official_actor),
		"roof_screen_center":str(host.camera.unproject_position(roof.global_position)),"geometry":official_geometry,
		"lighting":official_light,"size":[1280,720],"artificial_study":context=="INNER_MATERIAL_STUDY",
		"study_transform":str(study.transform) if is_instance_valid(study) else "NONE"})
	roof.material_override = reference_material

func run() -> void:
	check(not evidence.is_empty() and "floating_cube_a06" in evidence, "explicit isolated evidence directory")
	check(DisplayServer.get_name()=="Windows", "real Windows graphical renderer")
	if not failures.is_empty(): quit(1); return
	var catalog = load("res://game/shell/level_catalog.gd").new()
	shell = load("res://game/shell/game_feel_shell.tscn").instantiate()
	shell.save_path = "user://beta_sprint/floating_cube_a06/preview.json"
	shell.catalog_entries.assign([catalog.find("spatial_world_shift_gate_lab")])
	check(not FileAccess.file_exists(shell.save_path), "fresh isolated preview save")
	root.add_child(shell)
	shell.new_game()
	await settle()
	root.title = "Floating Cube A06 · isolated preview"
	root.min_size = Vector2i(900,700)
	root.size = Vector2i(1280,720)
	root.content_scale_mode = Window.CONTENT_SCALE_MODE_DISABLED
	root.content_scale_size = Vector2i.ZERO
	level = shell.adapter.level
	host = level.host
	root.gui_disable_input = true
	block_external_input(root)
	check(root.gui_disable_input, "own viewport GUI input disabled")
	check(shell.current_id=="spatial_world_shift_gate_lab" and host.runtime.is_loaded(), "actual formal Shell scene")
	check(host.host_issues.is_empty(), "no Host issue")
	materials.A1 = shader_material("res://tests/beta_sprint/spatial_art/polish_03/roof_coarse.gdshader")
	materials.A2 = shader_material("res://tests/beta_sprint/spatial_art/option_a_06/roof_coarse_a2.gdshader")
	make_badge()
	for world in [0,1]:
		if world==1:
			await action({"kind":0,"face_axis":0})
			await action({"kind":1})
		check(host.runtime.get_state().player.location.layer==world, "actual world after formal actions")
		for q in range(4):
			await camera_to(q)
			var roof := roof_node()
			check(roof.get_meta("presentation_role")=="NON_WALKABLE_OCCLUDER", "identified official nonwalkable roof")
			check(roof.visible==(world==0), "official roof is Surface only")
			var reference: Material = roof.material_override
			for variant in ["CURRENT","A1","A2"]:
				await capture_variant("FORMAL_SURFACE" if world==0 else "FORMAL_INNER",variant,q,roof,reference)
			if world==1:
				# Explicit material study only: original roof mesh/pose outside Host
				# geometry. Official hidden roof and all Runtime data stay unchanged.
				# Raise only the study camera to place the whole specimen below HUD.
				# This is NOT the formal world's natural camera framing.
				var natural_camera: Transform3D = host.camera.transform
				host.camera.position += Vector3.UP*2.0
				study = MeshInstance3D.new()
				study.name = "ArtificialInnerMaterialStudy_NotGameplay"
				study.mesh = roof.mesh
				study.transform = roof.global_transform
				study.cast_shadow = roof.cast_shadow
				root.add_child(study)
				for variant in ["CURRENT","A1","A2"]:
					await capture_variant("INNER_MATERIAL_STUDY",variant,q,roof,reference)
				study.queue_free()
				host.camera.transform = natural_camera
				check(host.camera.transform==natural_camera, "restore natural camera after isolated study")
				await settle()
	check(captures.size()==36, "36 actual four-view comparisons")
	check(host.host_issues.is_empty(), "no final Host issues")
	await finish()

func finish() -> void:
	var report := {"task":"FLOATING_CUBE_OPTION_A_06","checks":checks,"failures":failures,"captures":captures,"actions":actions,
		"engine":Engine.get_version_info(),"display":DisplayServer.get_name(),"renderer":RenderingServer.get_current_rendering_method(),
		"user_data_dir":OS.get_user_data_dir(),"pid":OS.get_process_id(),"doubles":[],"human_qa":"NOT_RUN",
		"production_integration":"NOT_RUN","art_change":"ISOLATED_PREVIEW_ONLY",
		"catalog_scope":"one actual S01 entry; visual seam only, not five-level unlock QA",
		"input":"own viewport GUI disabled and Node input callbacks disabled; direct formal Runtime requests only",
		"viewport_gui_input_disabled":root.gui_disable_input}
	FileAccess.open(evidence.path_join("report.json"),FileAccess.WRITE).store_string(JSON.stringify(report,"\t"))
	if is_instance_valid(shell):
		shell._leave_level()
		await settle()
		shell.queue_free()
	if is_instance_valid(overlay): overlay.queue_free()
	await settle(16)
	print("FLOATING_CUBE_A06 checks=",checks," failures=",failures.size()," captures=",captures.size())
	quit(0 if failures.is_empty() else 1)
