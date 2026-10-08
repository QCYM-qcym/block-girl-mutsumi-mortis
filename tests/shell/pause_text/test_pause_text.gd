extends SceneTree
## Owner automated render inspection. Not Computer Use or Human QA acceptance.
const SIZES := [Vector2i(1920, 1080), Vector2i(1280, 720), Vector2i(960, 720)]
var shell
var checks := 0
var failures: Array[String] = []
var observations: Array[Dictionary] = []
var evidence := ""
var label_only := false

func _initialize() -> void:
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--evidence-dir="):
			evidence = arg.trim_prefix("--evidence-dir=")
		elif arg == "--label-only":
			label_only = true
	if evidence.is_empty():
		quit(2)
		return
	call_deferred("run")

func check(ok: bool, label: String) -> void:
	checks += 1
	if not ok:
		failures.append(label)
		printerr("FAIL: ", label)

func linear_channel(value: float) -> float:
	return value / 12.92 if value <= 0.04045 else pow((value + 0.055) / 1.055, 2.4)

func luminance(color: Color) -> float:
	return 0.2126 * linear_channel(color.r) + 0.7152 * linear_channel(color.g) + 0.0722 * linear_channel(color.b)

func contrast(first: Color, second: Color) -> float:
	var a := luminance(first)
	var b := luminance(second)
	return (maxf(a, b) + 0.05) / (minf(a, b) + 0.05)

func key(code: int) -> void:
	for pressed in [true, false]:
		var event := InputEventKey.new()
		event.keycode = code
		event.physical_keycode = code
		event.pressed = pressed
		Input.parse_input_event(event)
		await process_frame
	await create_timer(0.2).timeout

func move_mouse(at: Vector2) -> void:
	var event := InputEventMouseMotion.new()
	event.position = at
	event.global_position = at
	Input.parse_input_event(event)
	await process_frame

func click(at: Vector2) -> void:
	await move_mouse(at)
	for pressed in [true, false]:
		var event := InputEventMouseButton.new()
		event.button_index = MOUSE_BUTTON_LEFT
		event.position = at
		event.global_position = at
		event.pressed = pressed
		Input.parse_input_event(event)
		await process_frame
	await create_timer(0.2).timeout

func inspect_label(requested: Vector2i, suffix: String) -> void:
	await RenderingServer.frame_post_draw
	var frame := root.get_texture().get_image()
	var button: Button = shell.view.pause_button
	var title: Label = button.get("_title")
	var rect := button.get_global_rect()
	var title_rect := title.get_global_rect()
	var foreground := title.get_theme_color("font_color")
	var sample := Vector2i(rect.position + Vector2(rect.size.x - 3, 3))
	var backing := frame.get_pixelv(sample)
	var ratio := contrast(foreground, backing)
	var drawn_ink := 0
	var title_area := Rect2i(title_rect).intersection(Rect2i(Vector2i.ZERO, frame.get_size()))
	for y in range(title_area.position.y, title_area.end.y):
		for x in range(title_area.position.x, title_area.end.x):
			var pixel := frame.get_pixel(x, y)
			# Approved thin fonts use antialiasing: detect visible rendered strokes,
			# not only pixels exactly equal to the nominal ink color.
			if contrast(pixel, backing) >= 3.0:
				drawn_ink += 1
	var ancestors: Array[Dictionary] = []
	var ancestor: Node = title
	while ancestor != null:
		var row := {"name": str(ancestor.name), "class": ancestor.get_class()}
		if ancestor is CanvasItem:
			row.visible = ancestor.visible
			row.modulate = str(ancestor.modulate)
			row.self_modulate = str(ancestor.self_modulate)
			row.z_index = ancestor.z_index
		elif ancestor is CanvasLayer:
			row.layer = ancestor.layer
		ancestors.append(row)
		ancestor = ancestor.get_parent()
	var name := "%sx%s_%s" % [requested.x, requested.y, suffix]
	frame.save_png(evidence.path_join(name + ".png"))
	var metrics := {"requested": str(requested), "window": str(root.size), "viewport": str(root.get_visible_rect().size),
		"render_target": str(frame.get_size()), "level": shell.current_id, "state": shell.state, "screen": shell.view.screen,
		"text": button.text, "display_text": button.get("display_text"), "label_text": title.text,
		"visible_in_tree": title.is_visible_in_tree(), "button_rect": str(rect), "label_rect": str(title_rect),
		"font_color": foreground.to_html(), "backing_color": backing.to_html(), "contrast": ratio,
		"font_size": title.get_theme_font_size("font_size"), "font_resource": title.get_theme_font("font").resource_path,
		"drawn_ink_pixels": drawn_ink, "ancestors": ancestors, "screenshot": name + ".png"}
	observations.append(metrics)
	print("PAUSE_LABEL_OBSERVATION ", JSON.stringify(metrics))
	check(root.size == requested and frame.get_size() == requested and root.get_visible_rect().size == Vector2(requested), "Owner render dimensions measured " + name)
	check(shell.state == shell.State.PLAYING and shell.current_id == "mutsumi_l02", "actual L-02 PLAYING state " + name)
	check(title.is_visible_in_tree() and button.text == "暂停  [Esc]" and not title.text.is_empty(), "pause label visibility/text binding " + name)
	check(rect.encloses(title_rect) and root.get_visible_rect().encloses(rect), "pause label remains in its entry and viewport " + name)
	check(drawn_ink > 40 and ratio >= 4.5, "pause entry has drawn readable text (contrast >= 4.5) " + name)

func run() -> void:
	DirAccess.make_dir_recursive_absolute(evidence)
	check(DisplayServer.get_name() != "headless", "Owner check uses actual graphical rendering")
	shell = load("res://game/shell/game_shell.tscn").instantiate()
	shell.save_path = "user://beta_sprint/ui_08_001_" + str(Time.get_ticks_usec()) + "/progress.json"
	root.add_child(shell)
	await create_timer(0.3).timeout
	# Explicit already-unlocked fixture: do not repeat actual L-01 Goal/unlock/Cold Continue.
	shell.progress.has_progress = true
	shell.progress.recent = "mutsumi_l01"
	shell.progress.unlocked = ["mutsumi_l01", "mutsumi_l02"]
	shell.progress.completed = ["mutsumi_l01"]
	shell.current_id = "mutsumi_l01"
	shell._set_state(shell.State.LEVEL_COMPLETE)
	shell._render_state()
	shell.start_next_level()
	await create_timer(0.3).timeout
	for requested in ([Vector2i(1280, 720)] if label_only else SIZES):
		root.size = requested
		await create_timer(0.3).timeout
		await move_mouse(Vector2(20, requested.y / 2.0))
		await inspect_label(requested, "l02_next_settled")
		if label_only:
			continue
		await click(shell.view.pause_button.get_global_rect().get_center())
		check(shell.state == shell.State.PAUSED and shell.view.screen == "pause", "mouse pause entry remains operable " + str(requested))
		check(not shell.view.pause_button.is_visible_in_tree(), "pause entry hidden on Pause page " + str(requested))
		await key(KEY_ESCAPE)
		check(shell.state == shell.State.PLAYING, "Escape resumes existing L-02 state " + str(requested))
		await move_mouse(Vector2(20, requested.y / 2.0))
		await inspect_label(requested, "l02_resumed")
	var report := {"issue": "UI-08-001", "checks": checks, "failures": failures, "observations": observations,
		"display": DisplayServer.get_name(), "renderer": RenderingServer.get_current_rendering_method(), "engine": Engine.get_version_info(),
		"evidence_type": "OWNER_AUTOMATED_RENDER_AND_INPUT", "human_acceptance": "NOT_RUN", "scope": "L02 pause label/entry/resume only; unlocked fixture; no full Goal/unlock/Cold Continue regression"}
	var file := FileAccess.open(evidence.path_join("report.json"), FileAccess.WRITE)
	file.store_string(JSON.stringify(report, "\t"))
	file.close()
	shell.queue_free()
	await create_timer(0.25).timeout
	print("UI_08_001_OWNER_CHECK: ", checks, " checks, failures=", failures)
	quit(0 if failures.is_empty() else 1)
