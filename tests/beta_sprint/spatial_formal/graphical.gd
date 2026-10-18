extends "res://tests/beta_sprint/spatial_formal/shell_lifecycle.gd"
## Same real progression, now with actual rendering; never Human QA.
var captures: Array[Dictionary] = []
var input_trace: Array[Dictionary] = []

func key(code: int, pressed: bool) -> void:
	var row := {"key":code,"pressed":pressed,"time_us":Time.get_ticks_usec(),"shell_state":shell.state}
	if is_instance_valid(game):
		row.before = {"cell":str(game.mover.cell),"phase":game.mover.phase,"view":game.view.current}
	await super.key(code,pressed)
	if is_instance_valid(game):
		row.after = {"cell":str(game.mover.cell),"phase":game.mover.phase,"view":game.view.current}
	input_trace.append(row)

func tap(code: int, count: int = 1) -> void:
	for index in count:
		await super.tap(code,1)
		# Rendering can stall a frame. Wait on the real motion before the next
		# sequential route input; explicit in-flight rejection cases use key().
		var deadline := Time.get_ticks_msec() + 5000
		while is_instance_valid(game) and (game.mover.phase not in ["idle", "complete"] or game.view.busy) and Time.get_ticks_msec() < deadline:
			await process_frame
		check(not is_instance_valid(game) or (game.mover.phase in ["idle", "complete"] and not game.view.busy), "native motion settled before next sequential input")

func shot(label: String) -> void:
	await RenderingServer.frame_post_draw
	var image: Image = root.get_texture().get_image()
	var path := evidence.path_join("%03d_%s.png" % [captures.size(), label.validate_filename()])
	DirAccess.make_dir_recursive_absolute(evidence)
	check(image != null and not image.is_empty(), "real graphical frame: " + label)
	if image == null or image.is_empty(): return
	check(image.save_png(path) == OK, "save graphical frame: " + label)
	captures.append({"label":label,"path":path,"viewport":[image.get_width(),image.get_height()]})

func spatial_route() -> void:
	await shot("start_" + shell.current_id)
	await super.spatial_route()
	await shot("complete_" + shell.current_id)

func spatial_pause_reset() -> void:
	await super.spatial_pause_reset()
	var level = shell.adapter.level
	for size in [Vector2i(1920,1080),Vector2i(1280,720),Vector2i(960,720)]:
		root.size = size
		for frame in 6: await process_frame
		for label in [level.hud.title_label,level.hud.world_label,level.hud.objective_label,level.hud.footer]:
			check(root.get_visible_rect().encloses(label.get_global_rect()), "spatial HUD within actual viewport: " + str(size))
		check(not level.hud.footer.get_global_rect().intersects(level.hud.feedback_label.get_global_rect()), "feedback does not overlap controls")
		check(not level.hud._strip.get_global_rect().intersects(level.hud.feedback_label.get_global_rect()), "hint does not overlap feedback")
		await shot("hud_%dx%d" % [size.x,size.y])
		shell.pause_game()
		check(not level.hud.visible, "paused Shell owns foreground UI")
		await shot("pause_%dx%d" % [size.x,size.y])
		shell.resume_game()
		check(level.hud.visible, "resume restores gameplay HUD")

func menu_capacity() -> void:
	await super.menu_capacity()
	for size in [Vector2i(1920,1080),Vector2i(1280,720),Vector2i(960,720)]:
		root.size = size
		shell.show_level_select()
		for frame in 4: await process_frame
		shell.view.buttons["level:" + expected[-1]].grab_focus()
		for frame in 6: await process_frame
		check(shell.view.buttons["level:" + expected[-1]].has_focus(), "last-level capture has actual requested focus")
		await shot("last_level_focus_%dx%d" % [size.x,size.y])

func finish() -> void:
	DirAccess.make_dir_recursive_absolute(evidence)
	FileAccess.open(evidence.path_join("input_trace.json"),FileAccess.WRITE).store_string(JSON.stringify(input_trace,"\t"))
	FileAccess.open(evidence.path_join("graphical_captures.json"),FileAccess.WRITE).store_string(JSON.stringify({"captures":captures,"display":DisplayServer.get_name(),"human_qa":"NOT_RUN"},"\t"))
	await super.finish()
