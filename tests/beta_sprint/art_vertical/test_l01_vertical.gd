extends "res://tests/playtest/test_batch_01_runtime.gd"
## Actual L01/Shell input, observed P01 state; no second gameplay model.
var shell
var evidence := ""
var phase := ""
var save_path := ""
var head := ""
var completion_events := 0
var completed_with_goal := true
var commit_log: Array = []
var parity: Dictionary = {}
var sampled_frames: Array[float] = []
var last_frame_usec := 0
var measuring := false
var roll_samples: Array = []
var shift_samples: Array = []
var faces: Array[String] = []
var current_label := ""
var view_samples: Array = []
var occlusion_trace: Array = []
var last_occlusion_usec := 0

func _initialize() -> void:
	call_deferred("run")

func run() -> void:
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--evidence-dir="): evidence = arg.trim_prefix("--evidence-dir=")
		elif arg.begins_with("--phase="): phase = arg.trim_prefix("--phase=")
		elif arg.begins_with("--shell-save="): save_path = arg.trim_prefix("--shell-save=")
		elif arg.begins_with("--head="): head = arg.trim_prefix("--head=")
	if evidence.is_empty() or phase not in ["seed", "restore"] or not save_path.begins_with("user://beta_sprint/"):
		quit(2)
		return
	DirAccess.make_dir_recursive_absolute(evidence)
	check(DisplayServer.get_name() != "headless", "actual graphical display")
	check(ProjectSettings.get_setting("application/run/main_scene") == "res://game/shell/game_shell.tscn", "actual project F5 entry remains Shell")
	check(FileAccess.file_exists(save_path) == (phase == "restore"), "independent process has expected save generation")
	shell = load("res://game/shell/game_shell.tscn").instantiate()
	root.add_child(shell)
	shell.adapter.completed.connect(on_completion)
	await delay(0.4)
	check(shell.save_path == save_path, "isolated actual Shell save")
	process_frame.connect(sample_frame)
	if not failures.is_empty():
		await finish()
		return
	if phase == "restore":
		await restore_process()
	else:
		await seed_process()
	await finish()

func button(id: String) -> void:
	check(shell.view.buttons.has(id), "Shell button exists: " + id)
	if not shell.view.buttons.has(id): return
	check(not shell.view.buttons[id].disabled, "Shell button enabled: " + id)
	if shell.view.buttons[id].disabled: return
	shell.view.buttons[id].pressed.emit()
	await process_frame
	await delay(0.1)

func bind_game() -> bool:
	game = shell.adapter.level
	check(game != null and shell.current_id == "mutsumi_l01", "actual Shell loads only L01")
	if game == null: return false
	check(game.has_method("display_3d"), "presentation switch is available")
	if not game.has_method("display_3d"): return false
	check(game.presenter != null and game.presenter is Node3D, "real 3D Presenter attached")
	if game.presenter == null: return false
	check(game.presenter.has_method("debug_snapshot"), "Presenter observations available")
	game.mover.committed.connect(on_commit)
	observe_face()
	return true

func on_completion() -> void:
	completion_events += 1
	completed_with_goal = completed_with_goal and shell.current_id == "mutsumi_l01" and game.graph.complete and game.mover.phase == "complete"

func logical_snapshot() -> Dictionary:
	return {"cell":[game.mover.cell.x,game.mover.cell.y],"orientation":game.mover.orientation.key(),"face":str(game.mover.orientation.face_direction()),"world":game.mover.world,"view":game.view.current,"plate":game.graph.plate_pressed,"gate":game.graph.door_open,"goal":game.graph.complete,"moves":game.mover.moves}

func state_digest(value: Dictionary) -> String:
	# Observation digest for the existing P01 state. Never Foundation statekey.v1.
	return JSON.stringify(value).sha256_text()

func on_commit() -> void:
	var value := logical_snapshot()
	value.destination = [game.mover.destination.x,game.mover.destination.y]
	value.direction = [game.mover.direction.x,game.mover.direction.y]
	value.phase = game.mover.phase
	value.view_target = game.view.target
	value.view_busy = game.view.busy
	value.link_active = game.graph.link.active
	commit_log.append({"state":value,"observation_sha256":state_digest(value)})
	observe_face()

func observe_face() -> void:
	var face := str(game.mover.orientation.face_direction())
	if face not in faces: faces.append(face)

func sample_frame() -> void:
	var now := Time.get_ticks_usec()
	if measuring and last_frame_usec != 0:
		sampled_frames.append(float(now-last_frame_usec)/1000.0)
	last_frame_usec = now
	if current_label == "3d" and is_instance_valid(game) and game.mover.cell.x >= 9 and now-last_occlusion_usec >= 50000:
		last_occlusion_usec = now
		occlusion_trace.append({"logic":logical_snapshot(),"visual":game.presenter.debug_snapshot(),"actor_center":str(game.presenter.actor.position),"materials":occlusion_materials(true)})

func occlusion_materials(assert_authority: bool) -> Array:
	var result: Array = []
	for row in game.presenter.materials:
		var kind := "gate" if "_GATE_" in row.slot else "exit" if "_EXIT_" in row.slot else ""
		if kind.is_empty() or row.world != game.mover.world: continue
		var obscured: bool = game.presenter.occlusion.get("%s:%s" % [row.world,kind],false)
		var actual: Material = row.mesh.get_active_material(row.surface)
		var expected: Material = row.fade if obscured else row.shader if game.presenter.shift_active else row.original
		var authority_matches: bool = actual == expected
		var actual_conceal: Variant = actual.get_shader_parameter("conceal") if actual is ShaderMaterial else null
		var conceal_matches: bool = not obscured or (actual_conceal != null and is_equal_approx(float(actual_conceal),0.84))
		var shadow_matches: bool = not obscured or row.mesh.cast_shadow == GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		if assert_authority:
			check(authority_matches and conceal_matches and shadow_matches,"actual moving foreground material and shadow follow current occlusion/VFX authority")
		result.append({"kind":kind,"world":row.world,"obscured":obscured,"reconstruction_active":actual == row.shader,"fade_active":actual == row.fade,"conceal":actual_conceal,"shadow_cast":row.mesh.cast_shadow,"authority_matches":authority_matches,"conceal_matches":conceal_matches,"shadow_matches":shadow_matches})
	return result

func reset_and_check(label: String) -> void:
	await tap(KEY_R)
	await process_frame
	check(game.mover.cell == game.content.spawn and game.mover.destination == game.content.spawn and game.mover.world == 0 and game.view.current == 0 and game.mover.phase == "idle" and game.mover.moves == 0 and not game.view.busy and game.mover.order.is_empty() and not game.graph.complete and not game.graph.door_open, label + " resets existing gameplay")
	check(game.mover.orientation.as_basis().is_equal_approx(Basis.IDENTITY), label + " resets physical orientation")
	await visual_settle(label)
	var seen: Dictionary = game.presenter.debug_snapshot()
	check(not game.presenter.shift_active and not seen.shift_committed and is_equal_approx(game.presenter.transition_progress,1.0), label + " clears VFX transient state into stable completion")

func visual_settle(label: String) -> void:
	await process_frame
	await process_frame
	var seen: Dictionary = game.presenter.debug_snapshot()
	check(game.presenter.actor.basis.is_equal_approx(game.mover.orientation.as_basis()), label + " 3D physical basis agrees with existing Cube orientation")
	check(seen.world == game.mover.world and seen.view == game.view.current, label + " visual world and view consume existing state")
	check(seen.gate_state == ("open" if game.graph.door_open else "closed"), label + " gate visual consumes actual mechanism state")
	check(seen.plate_state == ("pressed" if game.graph.plate_pressed else "inactive"), label + " approved plate state consumes actual mechanism state")

func seed_process() -> void:
	check(shell.state == shell.State.MAIN_MENU and shell.view.buttons["continue"].disabled, "cold Main Menu disables Continue")
	await shot("01_main_menu")
	await button("select")
	await shot("02_select_l01")
	await button("level:mutsumi_l01")
	if not bind_game(): return
	check(not game.board.visible, "default main-project L01 presents 3D and retains hidden Pixel reference")
	await delay(0.5)
	await shot("03_l01_3d_spawn")
	await visual_settle("spawn")
	measuring = true
	await camera_checks()
	await interruption_checks()
	await roll_and_shift_checks()
	await reset_and_check("before parity")
	measuring = false
	# The same scene, exact authored route and input helper run twice through Shell.
	game.display_3d(false)
	await delay(0.15)
	check(game.board.visible, "retained Pixel Presenter can be selected")
	commit_log.clear()
	current_label = "pixel"
	await route_l01("normal")
	await delay(0.3)
	parity.pixel = commit_log.duplicate(true)
	parity.pixel_final = logical_snapshot()
	check(shell.state == shell.State.LEVEL_COMPLETE and completion_events == 1 and completed_with_goal, "Pixel reference reaches real Goal and exactly one Shell completion")
	await shot("pixel_complete")
	await button("select")
	game = null
	await delay(0.15)
	await button("level:mutsumi_l01")
	if not bind_game(): return
	await delay(0.35)
	check(not game.board.visible, "new L01 entry defaults to 3D again")
	commit_log.clear()
	current_label = "3d"
	measuring = true
	await route_l01("normal")
	await delay(0.3)
	measuring = false
	parity.art3d = commit_log.duplicate(true)
	parity.art3d_final = logical_snapshot()
	check(parity.pixel == parity.art3d and parity.pixel_final == parity.art3d_final and not parity.art3d.is_empty(), "Pixel and 3D same-route per-commit observation digests and Goal/mechanism outcomes match exactly")
	check(completion_events == 2 and completed_with_goal and shell.state == shell.State.LEVEL_COMPLETE, "each actual L01 playthrough emits exactly one Goal completion")
	check(faces.size() == 6, "real route visits all six physical marked-face directions")
	check(shell.progress.completed == ["mutsumi_l01"] and shell.progress.unlocked == ["mutsumi_l01","mutsumi_l02"] and not shell.dirty, "actual completion persisted and unlocks L02 without entering it")
	var persisted: Dictionary = shell.store.load_save()
	check(persisted.recent == "mutsumi_l01" and persisted.completed == ["mutsumi_l01"], "real disk Save retains L01 progression")
	await shot("13_goal_shell_complete")
	await button("select")
	game = null
	check(shell.state == shell.State.LEVEL_SELECT and shell.view.buttons["level:mutsumi_l01"].text.ends_with("已通关"), "return to selection reflects completed L01")
	await shot("14_return_select")
	await button("main")
	check(shell.state == shell.State.MAIN_MENU and shell.adapter.level == null and not shell.view.buttons["continue"].disabled, "Shell return unloads L01 and enables Continue")
	await shot("15_return_menu")

func restore_process() -> void:
	check(shell.state == shell.State.MAIN_MENU and not shell.view.buttons["continue"].disabled, "independent OS process restores Continue")
	check(shell.progress.recent == "mutsumi_l01" and shell.progress.completed == ["mutsumi_l01"], "progress reload uses actual Save")
	await button("continue")
	if not bind_game(): return
	check(game.mover.cell == game.content.spawn and game.mover.world == 0 and game.view.current == 0 and game.mover.moves == 0, "actual Shell Continue semantics starts L01 at Spawn, not a fabricated Puzzle Save")
	check(not game.board.visible, "Continue enters default 3D presentation")
	await visual_settle("Continue")
	await shot("16_continue_restart")

func camera_checks() -> void:
	var pose: String = game.mover.orientation.key()
	for window_size in [Vector2i(1280,900),Vector2i(900,700)]:
		root.size = window_size
		await delay(0.2)
		if game.mover.world != 0:
			await tap(KEY_SPACE)
		for world_index in 2:
			if world_index == 1:
				await tap(KEY_SPACE)
				await delay(0.2)
			for view_index in 4:
				var value: Dictionary = game.presenter.debug_snapshot()
				check(game.view.current == view_index and not game.view.busy, "actual four-view discrete camera index")
				check(absf(wrapf(float(value.camera_angle)-(PI/4.0-float(view_index)*PI/2.0),-PI,PI)) < 0.001, "real orbit uses exact 90 degree steps about its initial isometric yaw")
				check(game.mover.orientation.key() == pose, "camera and World Shift do not reset orientation")
				framing_checks(window_size)
				view_samples.append({"window":[window_size.x,window_size.y],"world":world_index,"view":view_index,"snapshot":value})
				await shot("view_%dx%d_w%d_v%d" % [window_size.x,window_size.y,world_index,view_index])
				await tap(KEY_E)
			check(game.view.current == 0, "forward orbit closes after four steps")
	root.size = Vector2i(1280,900)
	await delay(0.2)
	await tap(KEY_Q,4)
	check(game.view.current == 0, "reverse four-view orbit closes")
	await mouse_drag()
	check(game.view.current == 1, "actual existing mouse drag rotates one discrete view")
	await reset_and_check("after four-view and mouse")

func framing_checks(window_size: Vector2i) -> void:
	var container: Control = game.visual_container
	var bottom: Vector2 = container.position + container.size
	check(container.position.x >= 0 and container.position.y >= 175 and bottom.x <= window_size.x+1 and bottom.y <= window_size.y-140+1,"actual 3D viewport fits between objective HUD and lower hints at both gameplay window sizes")
	var camera: Camera3D = game.presenter.camera
	var bounds: Rect2 = camera.get_viewport().get_visible_rect().grow(1.0)
	check(bounds.has_point(camera.unproject_position(game.presenter.actor.global_position)) and not camera.is_position_behind(game.presenter.actor.global_position),"physical cube center remains inside the real orthographic viewport")
	for row in game.presenter.assets:
		if not row.walkable or row.world != game.mover.world: continue
		var complete_mesh_fits := true
		for mesh in row.node.find_children("*","MeshInstance3D",true,false):
			if mesh.mesh == null: continue
			var box: AABB = mesh.get_aabb()
			for corner in 8:
				var point: Vector3 = mesh.global_transform * box.get_endpoint(corner)
				if camera.is_position_behind(point) or not bounds.has_point(camera.unproject_position(point)):
					complete_mesh_fits = false
		check(complete_mesh_fits,"entire approved walk-surface mesh fits the real camera: world%d cell%s" % [row.world,row.cell])

func interruption_checks() -> void:
	# Reset during the three existing natural transition types.
	await key(KEY_W,true)
	await key(KEY_W,false)
	await delay(0.1)
	check(game.mover.moving, "real roll is active before interruption")
	await reset_and_check("reset during roll")
	await key(KEY_E,true)
	await key(KEY_E,false)
	await delay(0.1)
	check(game.view.busy, "real camera rotation is active before interruption")
	await reset_and_check("reset during camera")
	await key(KEY_SPACE,true)
	await key(KEY_SPACE,false)
	await delay(0.07)
	check(game.mover.phase == "shift", "real Shift active before interruption")
	await reset_and_check("reset during Shift")
	await key(KEY_W,true)
	await delay(0.09)
	await key(KEY_ESCAPE,true)
	await key(KEY_ESCAPE,false)
	var cell: Vector2i = game.mover.cell
	var elapsed: float = game.mover.elapsed
	var transform: Transform3D = game.presenter.actor.transform
	await key(KEY_W,false)
	await delay(0.3)
	check(shell.state == shell.State.PAUSED and game.mover.cell == cell and game.mover.elapsed == elapsed and game.presenter.actor.transform.is_equal_approx(transform) and game.mover.order.is_empty(), "Pause freezes actual roll and visual pose and clears held inputs")
	await shot("pause_midroll")
	await button("resume")
	await delay(0.4)
	check(game.mover.moves == 1 and game.mover.phase == "idle", "Resume naturally finishes the accepted roll once")
	await reset_and_check("after Pause")
	# Existing window focus-notification route clears held input, no state assignment.
	await key(KEY_W,true)
	game.controls.notification(Node.NOTIFICATION_WM_WINDOW_FOCUS_OUT)
	await key(KEY_W,false)
	await delay(0.4)
	check(game.mover.order.is_empty() and game.mover.moves <= 1, "focus loss clears held movement")
	await reset_and_check("after focus")
	await key(KEY_W,true)
	await key(KEY_W,false)
	await key(KEY_SPACE,true)
	await key(KEY_SPACE,false)
	await key(KEY_E,true)
	await key(KEY_E,false)
	await delay(0.4)
	check(game.mover.moves == 1 and game.mover.world == 0 and game.view.current == 0, "rapid competing Shift/camera input cannot replace an accepted roll")
	await reset_and_check("after input competition")

func sampled_roll(direction: Vector2i, label: String) -> void:
	var before: Dictionary = logical_snapshot()
	var initial_basis: Basis = game.mover.orientation.as_basis()
	var start_center: Vector3 = game.presenter.actor.position
	var code := direction_key(direction)
	await key(code,true)
	await key(code,false)
	check(game.mover.moving and game.mover.direction == direction, label + " accepted actual cardinal roll")
	if not game.mover.moving: return
	var end_center: Vector3 = game.presenter.displayed_position(Vector2(game.mover.destination),game.graph.nodes[game.mover.destination]) + Vector3(0,0.5,0)
	for fraction in [0.08,0.42,0.80]:
		while game.mover.moving and game.mover.fraction < fraction:
			await process_frame
		await key(KEY_SPACE,true)
		await key(KEY_SPACE,false)
		check(game.mover.phase == "roll" and game.mover.world == before.world, label + " early/mid/late Shift input is rejected while formal roll is active")
		var value: Dictionary = game.presenter.debug_snapshot()
		check(game.mover.moving and logical_snapshot() == before, label + " position/orientation/mechanism remain uncommitted at " + str(fraction))
		check(game.presenter.actor.basis.is_finite() and is_equal_approx(game.presenter.actor.basis.determinant(),1.0), label + " natural physical roll basis remains a proper rotation")
		var expected_pose := Basis(Vector3(direction.y,0,-direction.x),game.mover.fraction*PI/2.0)*initial_basis
		check(game.presenter.actor.basis.is_equal_approx(expected_pose), label + " visual roll follows actual direction and Runtime fraction without reverse rotation")
		var center: Vector3 = game.presenter.actor.position
		var horizontal := Vector2(center.x,center.z)
		var horizontal_start := Vector2(start_center.x,start_center.z)
		var horizontal_end := Vector2(end_center.x,end_center.z)
		check(horizontal.distance_to(horizontal_start) > 0.005 and horizontal.distance_to(horizontal_end) > 0.005, label + " natural rolling cube advances between endpoints instead of staying static or teleporting")
		check(center.y > start_center.y and center.y < start_center.y+0.25, label + " physical cube center has a bounded natural roll lift")
		roll_samples.append({"direction":str(direction),"fraction":game.mover.fraction,"logic":logical_snapshot(),"visual":value})
		if fraction == 0.42: await shot("roll_mid_" + label)
	while game.mover.moving: await process_frame
	await visual_settle(label + " committed")
	check(game.presenter.actor.position.is_equal_approx(end_center), label + " visual settles exactly at the accepted destination center")
	check(game.mover.moves == int(before.moves)+1, label + " commits exactly one roll")

func sampled_shift(label: String) -> void:
	var before: Dictionary = logical_snapshot()
	var old_world: int = game.mover.world
	var commits_before := commit_log.size()
	await key(KEY_SPACE,true)
	await key(KEY_SPACE,false)
	check(game.mover.phase == "shift", label + " accepted actual Shift")
	if game.mover.phase != "shift": return
	while game.mover.phase == "shift":
		var seen: Dictionary = game.presenter.debug_snapshot()
		check(game.mover.world == old_world and logical_snapshot() == before, label + " logical world and physical pose remain before 0.25-second commit")
		var incoming_walkable := 0
		for row in game.presenter.assets:
			if row.walkable and row.world == 1-old_world:
				incoming_walkable += 1
				check(not row.node.visible, label + " incoming walk surface stays hidden before formal commit")
			if row.walkable and row.world == old_world:
				check(row.node.visible, label + " old walk surface remains present before formal commit")
		check(incoming_walkable > 0 and is_zero_approx(float(seen.incoming_walk_surface_reveal)), label + " no early changed-path floor reveal despite approved structural VFX overlap")
		shift_samples.append({"elapsed":game.mover.elapsed,"logic":logical_snapshot(),"visual":seen})
		if game.mover.elapsed > 0.1 and game.mover.elapsed < 0.14: await shot("shift_precommit_" + label)
		await process_frame
	check(game.mover.world == 1-old_world and commit_log.size() == commits_before+1, label + " formal world commits once")
	check(game.mover.cell == Vector2i(before.cell[0],before.cell[1]) and game.mover.orientation.key() == before.orientation and game.view.current == before.view, label + " Shift preserves cell, orientation and camera direction")
	await delay(0.45)
	await visual_settle(label + " settle")
	await shot("shift_after_" + label)

func roll_and_shift_checks() -> void:
	await sampled_roll(Vector2i.UP,"north")
	await sampled_roll(Vector2i.DOWN,"south")
	await move(Vector2i.UP,3)
	check(game.mover.cell == Vector2i(0,2), "actual Surface gap edge reached")
	await sampled_shift("to_inner")
	await move(Vector2i.UP)
	var before := logical_snapshot()
	await tap(KEY_SPACE)
	check(game.mover.world == 1 and logical_snapshot() == before and game.feedback.visible, "Inner-only cell rejects unsafe shift with unchanged state")
	await move(Vector2i.UP)
	await sampled_roll(Vector2i.RIGHT,"east")
	await sampled_roll(Vector2i.LEFT,"west")
	await sampled_shift("to_surface")
	await reset_and_check("after directional roll and changed path")

func shot(label: String) -> void:
	await RenderingServer.frame_post_draw
	var name := (current_label + "_" if not current_label.is_empty() else "") + label
	root.get_texture().get_image().save_png(evidence.path_join(name + ".png"))
	checkpoints.append({"name":name,"state":logical_snapshot() if game != null else {},"visual":game.presenter.debug_snapshot() if game != null else {},"materials":occlusion_materials(false) if game != null else [],"shell_screen":shell.view.screen})
	if game != null and current_label == "3d":
		await visual_settle(label)
	if label == "l01_plate_normal" and current_label in ["pixel","3d"]:
		# Add identical actual camera inputs to both reference routes at the plate.
		# This returns to the original view before the inherited gate-crossing input.
		var before := logical_snapshot()
		for index in 4:
			await tap(KEY_E)
			await RenderingServer.frame_post_draw
			var plate_name := current_label + "_plate_view_" + str(game.view.current)
			root.get_texture().get_image().save_png(evidence.path_join(plate_name + ".png"))
			checkpoints.append({"name":plate_name,"state":logical_snapshot(),"visual":game.presenter.debug_snapshot(),"materials":occlusion_materials(current_label == "3d"),"shell_screen":shell.view.screen})
		check(logical_snapshot() == before,"identical four-view plate orbit preserves actual pose, mechanisms and route continuation in both Presenters")

func finish() -> void:
	measuring = false
	var sorted := sampled_frames.duplicate()
	sorted.sort()
	var performance := {"samples":sorted.size(),"frame_ms_p50":sorted[int(sorted.size()*0.50)] if not sorted.is_empty() else null,"frame_ms_p95":sorted[mini(int(sorted.size()*0.95),sorted.size()-1)] if not sorted.is_empty() else null,"renderer":RenderingServer.get_current_rendering_method(),"adapter":RenderingServer.get_video_adapter_name(),"memory_bytes":OS.get_static_memory_usage(),"scope":"Current device and actual L01 only; frame wall time includes real rendering/input. No universal hardware claim."}
	var report := {"checks":checks,"failures":failures,"phase":phase,"pid":OS.get_process_id(),"project":ProjectSettings.globalize_path("res://"),"head":head,"save_path":save_path,"save_absolute":ProjectSettings.globalize_path(save_path),"display":DisplayServer.get_name(),"engine":Engine.get_version_info(),"completion_events":completion_events,"progress":shell.progress,"parity":parity,"physical_face_directions":faces,"roll_samples":roll_samples,"shift_samples":shift_samples,"four_views":view_samples,"occlusion_trace":occlusion_trace,"screenshots":checkpoints,"performance":performance,"scope":{"runtime":"Existing ContentLevel/P01 GridMovement/PerspectiveController","state_key":"P01 observation SHA256; not Foundation statekey.v1","L02_L03":"NOT_RUN","stairs_clearance":"PARTIAL_PASS preserved","stairs_traversal":"NOT_RUN","carriers_rotation_stairs":"NOT_RUN","death":"NOT_RUN","puzzle_state_save":"NOT_RUN; Shell progression Save/Continue tested","mechanism_semantics":"Existing L01 plate/gate state mapping; Area3D physics not part of this runtime"}}
	shell.show_main_menu()
	game = null
	await delay(0.2) # Allow actual looping-audio teardown to cross its mixer boundary.
	var file := FileAccess.open(evidence.path_join("report.json"),FileAccess.WRITE)
	file.store_string(JSON.stringify(report,"\t"))
	file.close()
	print("L01 ART VERTICAL ",phase,": ",checks," checks; failures=",failures)
	if phase == "seed" and failures.is_empty():
		shell.request_quit()
	else:
		root.remove_child(shell)
		shell.free()
		shell = null
		await process_frame
		await process_frame
		quit(0 if failures.is_empty() else 1)
