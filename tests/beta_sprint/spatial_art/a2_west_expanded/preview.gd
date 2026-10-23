extends "res://tests/beta_sprint/spatial_art/option_a_06/preview.gd"
## Reuse only existing read-only invariant/Runtime helpers. No inherited UI/study.

func run() -> void:
	check(not evidence.is_empty() and "floating_cube_expanded" in evidence, "new expanded evidence directory")
	check(DisplayServer.get_name()=="Windows", "actual Windows renderer")
	if not failures.is_empty(): quit(1); return
	var catalog = load("res://game/shell/level_catalog.gd").new()
	shell = load("res://game/shell/game_feel_shell.tscn").instantiate()
	shell.save_path = "user://beta_sprint/floating_cube_expanded/preview.json"
	shell.catalog_entries.assign([catalog.find("spatial_world_shift_gate_lab")])
	check(not FileAccess.file_exists(shell.save_path), "fresh independent profile")
	root.add_child(shell)
	shell.new_game()
	await settle()
	root.title = "Floating Cube expanded isolated material review"
	root.size = Vector2i(1280,720)
	root.content_scale_mode = Window.CONTENT_SCALE_MODE_DISABLED
	root.content_scale_size = Vector2i.ZERO
	level = shell.adapter.level
	host = level.host
	root.gui_disable_input = true
	block_external_input(root)
	check(root.gui_disable_input and host.host_issues.is_empty(), "isolated input and real Host")
	materials.A1 = shader_material("res://tests/beta_sprint/spatial_art/polish_03/roof_coarse.gdshader")
	materials.A2 = shader_material("res://tests/beta_sprint/spatial_art/a2_west_expanded/roof_coarse_a2.gdshader")
	for q in range(4):
		await camera_to(q)
		var roof := roof_node()
		check(roof.visible and roof.get_meta("presentation_role")=="NON_WALKABLE_OCCLUDER", "real Surface occluder")
		var original: Material = roof.material_override
		for variant in ["CURRENT","A1","A2"]:
			var state: Dictionary = host.runtime.get_state().duplicate(true)
			var data: Dictionary = host.runtime.get_level().duplicate(true)
			var geo := geometry()
			var cam: Transform3D = host.camera.transform
			var light := lighting()
			var pose: Transform3D = host.actor.transform
			var commits: int = host.runtime.get_commit_count()
			roof.material_override = original if variant=="CURRENT" else materials[variant]
			await settle(12)
			check(host.runtime.get_state()==state and host.runtime.get_level()==data, "state and level unchanged")
			check(host.runtime.get_commit_count()==commits, "material creates no commit")
			check(geometry()==geo, "mesh vertices, outline, pose, visibility and shadows unchanged")
			check(host.camera.transform==cam and lighting()==light and host.actor.transform==pose, "fixed camera light actor")
			await RenderingServer.frame_post_draw
			var pixels: Image = root.get_texture().get_image()
			check(pixels.get_size()==Vector2i(1280,720), "native output dimensions")
			var name := "%s_q%d.png" % [variant,q]
			var file := evidence.path_join(name)
			check(not FileAccess.file_exists(file), "never replace captures")
			check(pixels.save_png(file)==OK, "save raw render frame")
			captures.append({"file":name,"sha256":FileAccess.get_sha256(file),"variant":variant,"quadrant":q,"camera_name":NAMES[q],
				"size":[1280,720],"state":state,"statekey":Key.build(data,state).key,"geometry":geo,
				"camera_transform":str(cam),"camera_size":host.camera.size,"keep_aspect":host.camera.keep_aspect,
				"actor_transform":str(pose),"lighting":light,"roof_screen_center":str(host.camera.unproject_position(roof.global_position)),
				"material_instance_id":roof.material_override.get_instance_id(),"material_class":roof.material_override.get_class(),
				"native_current_parameters":{"roughness":original.roughness,"metallic":original.metallic,"specular":original.metallic_specular,"albedo_color":str(original.albedo_color)}})
		roof.material_override = original
	check(captures.size()==12 and host.host_issues.is_empty(), "twelve actual frames")
	await finish()

func finish() -> void:
	var report := {"task":"FLOATING_CUBE_A2_WEST_VIEW_READABILITY","checks":checks,"failures":failures,"captures":captures,"actions":actions,
		"engine":Engine.get_version_info(),"display":DisplayServer.get_name(),"renderer":RenderingServer.get_current_rendering_method(),
		"user_data_dir":OS.get_user_data_dir(),"pid":OS.get_process_id(),"doubles":[],"human_qa":"NOT_RUN", "formal_asset_approval":"NOT_GRANTED",
		"game_integration":"NOT_RUN","new_formal_build":"NOT_CREATED","input":"own GUI and Node input callbacks disabled",
		"scene":"copied exact formal S01; one-entry catalog visual seam, no natural progression claim", "extra_ui_added":false,"artificial_geometry_added":false}
	FileAccess.open(evidence.path_join("report.json"),FileAccess.WRITE).store_string(JSON.stringify(report,"\t"))
	if is_instance_valid(shell):
		shell._leave_level()
		await settle()
		shell.queue_free()
	await settle(16)
	print("FLOATING_CUBE_EXPANDED checks=",checks," failures=",failures.size()," captures=",captures.size())
	quit(0 if failures.is_empty() else 1)
