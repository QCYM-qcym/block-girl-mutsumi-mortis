extends SceneTree
## PROPOSAL_ONLY. Real Menu/Host/Runtime, isolated profile; only roof material or explanatory overlay differs.
const MAIN = "res://experiments/spatial_puzzle_batch_01/ui/main.tscn"
const Key = preload("res://foundation/contracts/state_key.gd")
var ui
var host
var evidence := ""
var checks := 0
var failures: Array[String] = []
var captures: Array = []
var actions: Array = []
var overlay: CanvasLayer
var badge: Label
var explanation: PanelContainer
var material_a: ShaderMaterial
var material_b: ShaderMaterial

func _initialize() -> void:
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--evidence="): evidence = arg.trim_prefix("--evidence=")
	call_deferred("run")

func check(ok: bool, message: String) -> void:
	checks += 1
	if not ok:
		failures.append(message)
		printerr("PREVIEW CHECK: ", message)

func settle(frames: int = 8) -> void:
	for frame in frames: await process_frame

func material(path: String) -> ShaderMaterial:
	var shader := Shader.new()
	shader.code = FileAccess.get_file_as_string(path)
	var result := ShaderMaterial.new()
	result.shader = shader
	return result

func geometry() -> Array:
	var result: Array = []
	for node in host.geometry_root.get_children():
		if node is MeshInstance3D:
			result.append({"cube":str(node.get_meta("cube_id")), "transform":str(node.transform),
				"mesh":str(node.mesh.get_rid()), "bounds":str(node.mesh.get_aabb()),
				"vertices_sha256":node.mesh.get_faces().to_byte_array().hex_encode().sha256_text(),
				"visible":node.visible, "cast_shadow":node.cast_shadow})
	return result

func build_overlay() -> void:
	overlay = CanvasLayer.new()
	overlay.layer = 100
	root.add_child(overlay)
	badge = Label.new()
	badge.position = Vector2(24, 114)
	badge.add_theme_font_size_override("font_size", 17)
	badge.add_theme_color_override("font_color", Color("d2d9d6"))
	badge.mouse_filter = Control.MOUSE_FILTER_IGNORE
	overlay.add_child(badge)
	explanation = PanelContainer.new()
	explanation.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var style := StyleBoxFlat.new()
	style.bg_color = Color("273039")
	style.border_color = Color("aebcbf")
	style.set_border_width_all(1)
	style.content_margin_left = 16
	style.content_margin_right = 16
	style.content_margin_top = 12
	style.content_margin_bottom = 12
	explanation.add_theme_stylebox_override("panel", style)
	var text := Label.new()
	text.text = "上方灰蓝色方块：遮光体\n不可站立；它会遮挡光线。\n切换位置仍以“转换点”为准。"
	text.add_theme_font_size_override("font_size", 19)
	text.add_theme_color_override("font_color", Color("e7ece8"))
	explanation.add_child(text)
	overlay.add_child(explanation)
	explanation.hide()

func camera_to(q: int) -> void:
	if host.runtime.get_state().camera_quadrant == q: return
	var before: Dictionary = host.runtime.get_state()
	var result: Dictionary = host.runtime.request_action({"kind":9,"camera_quadrant":q})
	check(result.status == 0, "formal CAMERA accepted Q"+str(q))
	var deadline := Time.get_ticks_msec()+5000
	while (not host.runtime.is_idle() or not host._camera_motion.is_empty()) and Time.get_ticks_msec()<deadline:
		await process_frame
	check(host.runtime.is_idle() and host._camera_motion.is_empty(), "natural Camera completion")
	check(host.runtime.get_state().player == before.player, "Camera preserves player pose")
	actions.append({"action":{"kind":9,"camera_quadrant":q},"status":result.status,
		"statekey":Key.build(host.runtime.get_level(),host.runtime.get_state()).key})
	await settle()

func run() -> void:
	check(not evidence.is_empty() and "art_preview_polish03" in evidence, "explicit isolated evidence directory")
	check(DisplayServer.get_name() == "Windows", "actual Windows graphical rendering")
	if not failures.is_empty(): quit(1); return
	root.title = "Roof comparison · PROPOSAL ONLY · Owner 05"
	root.content_scale_size = Vector2i.ZERO
	root.content_scale_mode = Window.CONTENT_SCALE_MODE_DISABLED
	root.size = Vector2i(1280,720)
	ui = load(MAIN).instantiate()
	ui.save_path = "user://spatial_puzzle_batch_01/tests/art_polish03/progress.json"
	root.add_child(ui)
	await settle()
	ui.start_lab(&"world_shift_gate_lab")
	await settle()
	host = ui.lab
	check(is_instance_valid(host) and host.runtime.is_loaded(), "formal Menu starts saved Gate Host")
	if not is_instance_valid(host): await finish(); return
	check(host.host_issues.is_empty(), "Host has no load issue")
	var formal_level: Dictionary = host.runtime.get_level().duplicate(true)
	var spawn: Dictionary = host.runtime.get_state().player.duplicate(true)
	material_a = material("res://tests/beta_sprint/spatial_art/polish_03/roof_coarse.gdshader")
	material_b = material("res://tests/beta_sprint/spatial_art/polish_03/roof_inset.gdshader")
	build_overlay()
	for area in [Vector2i(1280,720), Vector2i(960,720)]:
		root.size = area
		await settle()
		for q in range(4):
			await camera_to(q)
			# The formal Host rebuilds geometry on committed CAMERA actions.
			# Reacquire the new node; compare variants within this stable camera state.
			var roof: MeshInstance3D = host.geometry_root.get_node("roof")
			var original_material: Material = roof.material_override
			var original_geometry: Array = geometry()
			check(roof.get_meta("presentation_role") == "NON_WALKABLE_OCCLUDER", "correct formal roof")
			var reference_state: Dictionary = host.runtime.get_state().duplicate(true)
			var reference_camera: Transform3D = host.camera.transform
			for variant in ["ORIGINAL","A","B","C"]:
				roof.material_override = material_a if variant == "A" else (material_b if variant == "B" else original_material)
				explanation.visible = variant == "C"
				explanation.position = Vector2(area.x-388, 166)
				badge.text = "隔离视觉提案 · %s · %s · Q%d · %dx%d" % [variant, "辅助说明，非盲测" if variant == "C" else "仅供美术评审", q, area.x,area.y]
				await settle(12)
				check(host.runtime.get_state()==reference_state, "visual variant preserves full StateKey "+variant)
				check(host.runtime.get_level()==formal_level and host.runtime.get_state().player==spawn, "no formal data/pose change")
				check(geometry()==original_geometry, "mesh/transform/shadow/visibility unchanged")
				check(host.camera.transform==reference_camera and host.camera.projection==Camera3D.PROJECTION_ORTHOGONAL, "camera unchanged by variant")
				await RenderingServer.frame_post_draw
				var pixels := root.get_texture().get_image()
				check(pixels != null and pixels.get_size()==area, "real Viewport resolution")
				var name := "%s_q%d_%dx%d.png" % [variant,q,area.x,area.y]
				var file := evidence.path_join(name)
				check(not FileAccess.file_exists(file), "never overwrite previous capture")
				check(pixels.save_png(file)==OK, "capture saved")
				captures.append({"file":name,"sha256":FileAccess.get_sha256(file),"variant":variant,
					"quadrant":q,"size":[area.x,area.y],"statekey":Key.build(formal_level,reference_state).key,
					"camera_size":host.camera.size,"keep_aspect":host.camera.keep_aspect,"camera_transform":str(reference_camera),
					"roof_screen_center":str(host.camera.unproject_position(roof.global_position)),
					"geometry":original_geometry,"assisted_explanation":variant=="C"})
			roof.material_override = original_material
	check(captures.size()==32 and host.host_issues.is_empty(), "complete four-view comparison without Host errors")
	await finish()

func finish() -> void:
	var report := {"task":"SPATIAL_PUZZLE_BATCH_01_POLISH_AND_ACCEPTANCE_03","checks":checks,"failures":failures,
		"captures":captures,"camera_actions":actions,"doubles":[],"art_change":"PROPOSAL_ONLY","human_qa":"NOT_RUN",
		"display":DisplayServer.get_name(),"renderer":RenderingServer.get_current_rendering_method(),
		"engine":Engine.get_version_info(),"user_data_dir":OS.get_user_data_dir(),"pid":OS.get_process_id(),
		"authority":"unchanged formal Menu/Host/Runtime in copied project; CAMERA requests naturally completed; only isolated roof materials/annotation differ"}
	FileAccess.open(evidence.path_join("report.json"),FileAccess.WRITE).store_string(JSON.stringify(report,"\t"))
	if is_instance_valid(overlay): overlay.queue_free()
	if is_instance_valid(ui):
		if is_instance_valid(ui.lab): ui.return_to_menu(ui.lab)
		await settle()
		ui.queue_free()
	await settle()
	print("ART_PREVIEW_DONE checks=",checks," captures=",captures.size()," failures=",failures.size())
	quit(0 if failures.is_empty() else 1)
