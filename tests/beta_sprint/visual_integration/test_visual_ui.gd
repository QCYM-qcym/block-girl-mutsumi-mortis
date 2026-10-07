extends "res://tests/playtest/test_batch_01_runtime.gd"
## Real Godot controls and the existing Save/Shell/Content APIs only.
const SIZES := [Vector2i(1920,1080),Vector2i(1280,720),Vector2i(960,720)]
const LONG_TITLE := "L-01《另一个世界：若叶睦在石拱之间寻找两个世界相接的视线与返回之路》"
const LONG_ERROR := "无法写入临时存档，原存档未修改。请检查磁盘剩余空间、目标目录权限以及存档文件是否被其它程序占用；完成状态仍然保留，可稍后重试保存。"
var shell
var evidence := ""
var phase := ""
var save_path := ""
var head := ""
var completion_events := 0
var cases: Array = []
var contract_cases: Array = []
var navigation: Array = []
var hints: Array = []
var fixture_index := 0
var input_audit: Dictionary = {}
var geometry: Array = []
var mouse_targets: Array = []

func run() -> void:
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--evidence-dir="): evidence = arg.trim_prefix("--evidence-dir=")
		elif arg.begins_with("--phase="): phase = arg.trim_prefix("--phase=")
		elif arg.begins_with("--ui-save="): save_path = arg.trim_prefix("--ui-save=")
		elif arg.begins_with("--head="): head = arg.trim_prefix("--head=")
	if evidence.is_empty() or phase not in ["seed","restore"] or not save_path.begins_with("user://beta_sprint/"):
		quit(2)
		return
	DirAccess.make_dir_recursive_absolute(evidence)
	check(DisplayServer.get_name() != "headless","real graphical UI execution")
	check(ProjectSettings.get_setting("application/run/main_scene") == "res://game/shell/game_shell.tscn","actual project F5 enters existing Shell")
	input_audit = inspect_input()
	if phase == "seed":
		await save_state_fixtures()
		await completion_contract_matrix()
	shell = load("res://game/shell/game_shell.tscn").instantiate()
	shell.save_path = save_path
	root.add_child(shell)
	shell.adapter.completed.connect(func():completion_events += 1)
	await delay(0.3)
	check(shell.view.get_script().resource_path == "res://game/shell/visual_01/approved_shell_view.gd","actual Shell consumes approved visual layer")
	check(shell.save_path == save_path,"actual Shell uses isolated save fixture")
	check(root.content_scale_mode == Window.CONTENT_SCALE_MODE_DISABLED and root.get_visible_rect().size.is_equal_approx(Vector2(root.size)),"actual Shell preserves native pixel text sizing and viewport dimensions")
	if phase == "seed": await seed_process()
	else: await restore_process()
	await finish()

func inspect_input() -> Dictionary:
	var actions: Dictionary = {}
	for action in InputMap.get_actions():
		var events: Array = []
		for event in InputMap.action_get_events(action):
			events.append({"class":event.get_class(),"description":event.as_text()})
		actions[action] = events
	return {"actions":actions,"controller":"NOT_SUPPORTED: current gameplay and Shell adapters accept keyboard/mouse only; built-in GUI joy events do not supply formal gameplay/controller glyphs","settings_M":"NOT_SUPPORTED: Shell M shortcut is PLAYING-only; no new binding added"}

func ui_key(code: int, shift: bool = false) -> void:
	var event := InputEventKey.new()
	event.keycode = code
	event.physical_keycode = code
	event.shift_pressed = shift
	event.pressed = true
	Input.parse_input_event(event)
	await process_frame
	event.pressed = false
	Input.parse_input_event(event)
	await process_frame
	await delay(0.1)

func mouse_click(control: Control) -> void:
	check(control.is_visible_in_tree(),"actual mouse target visible")
	var viewport_transform: Transform2D = control.get_viewport().get_final_transform()
	var canvas_point: Vector2 = control.get_global_transform_with_canvas() * (control.size / 2.0)
	var point: Vector2 = viewport_transform * canvas_point
	mouse_targets.append({"target":str(control.get_path()),"canvas_point":str(canvas_point),"window_point":str(point),"viewport":viewport_metrics()})
	var motion := InputEventMouseMotion.new()
	motion.position = point
	motion.global_position = point
	Input.parse_input_event(motion)
	await process_frame
	var event := InputEventMouseButton.new()
	event.button_index = MOUSE_BUTTON_LEFT
	event.position = point
	event.global_position = point
	event.pressed = true
	Input.parse_input_event(event)
	await process_frame
	event.pressed = false
	Input.parse_input_event(event)
	await process_frame
	await delay(0.2)

func click(id: String) -> void:
	check(shell.view.buttons.has(id),"actual action button exists: " + id)
	if not shell.view.buttons.has(id): return
	check(not shell.view.buttons[id].disabled,"actual action enabled: " + id)
	if shell.view.buttons[id].disabled: return
	await mouse_click(shell.view.buttons[id])

func focus_to(control: Control) -> void:
	for index in shell.view.focus_order.size()+2:
		if root.gui_get_focus_owner() == control: break
		await ui_key(KEY_TAB)
	check(root.gui_get_focus_owner() == control,"Tab reaches actual intended enabled control")

func navigation_cycle(label: String) -> void:
	var order: Array = shell.view.focus_order
	check(not order.is_empty(),label + " has keyboard focus targets")
	if order.is_empty(): return
	await focus_to(order[0])
	for index in order.size():
		check(root.gui_get_focus_owner() == order[index],label + " Tab follows reading order and skips disabled")
		if order[index] is Button:
			check(not order[index].disabled,label + " focused Button is enabled")
			check(order[index].get("bracket_visible") == true,label + " actual focus bracket is drawn")
		await ui_key(KEY_TAB)
	check(root.gui_get_focus_owner() == order[0],label + " complete Tab orbit returns to first target")
	await ui_key(KEY_TAB,true)
	check(root.gui_get_focus_owner() == order.back(),label + " Shift+Tab reverses reading order")
	await ui_key(KEY_DOWN)
	check(root.gui_get_focus_owner() == order[0],label + " Down uses same navigation order")
	await ui_key(KEY_UP)
	check(root.gui_get_focus_owner() == order.back(),label + " Up reverses navigation order")
	navigation.append({"case":label,"focus":shell.view.debug_snapshot()})

func layout_checks(label: String, long_error: bool = false) -> void:
	for size in SIZES:
		root.size = size
		await delay(0.2)
		if long_error:
			shell.view.set_status(LONG_ERROR)
			await delay(0.16)
		check(root.size == size,"actual gameplay Window reaches requested resolution")
		check(root.content_scale_mode == Window.CONTENT_SCALE_MODE_DISABLED and root.get_visible_rect().size.is_equal_approx(Vector2(root.size)),label + " native pixel sizing remains correct after actual resize")
		control_bounds(shell.view.root,label)
		font_coverage(shell.view.heading,label)
		if is_instance_valid(game) and shell.current_id == "mutsumi_l01" and shell.state == shell.State.PLAYING:
			control_bounds(game.approved_hud,label + " actual Hint/HUD")
			font_coverage(game.approved_hud.title_label,label + " actual Hint/HUD")
		await shot(label + "_%dx%d" % [size.x,size.y])
	if long_error: shell.view.set_status("")

func control_bounds(node: Node, label: String) -> void:
	var viewport: Rect2 = root.get_visible_rect().grow(1)
	var physical_window := Rect2(Vector2.ZERO,Vector2(root.size)).grow(1)
	if node is Control and node.is_visible_in_tree():
		var rect: Rect2 = node.get_global_rect()
		if node is Button or node is Slider or node is Label:
			var physical_transform: Transform2D = node.get_viewport().get_final_transform() * node.get_global_transform_with_canvas()
			var physical_rect: Rect2 = physical_transform * Rect2(Vector2.ZERO,node.size)
			geometry.append({"case":label,"control":str(node.get_path()),"canvas_rect":str(rect),"physical_rect":str(physical_rect),"viewport":viewport_metrics(),"font_size":node.get_theme_font_size("font_size"),"physical_font_size":node.get_theme_font_size("font_size") * physical_transform.y.length()})
			check(viewport.encloses(rect) and physical_window.encloses(physical_rect),label + " interactive/text bounds stay inside actual viewport: " + node.name)
			if node is Label and not node.text.is_empty():
				var owning_button: Node = node.get_parent()
				while owning_button != null and not owning_button is Button:
					owning_button = owning_button.get_parent()
				if owning_button is Button:
					var owning_rect: Rect2 = owning_button.get_global_rect()
					geometry.back()["owning_button"] = str(owning_button.get_path())
					geometry.back()["owning_button_rect"] = str(owning_rect)
					check(owning_rect.grow(1).encloses(rect),label + " action label fits its own actual Button row: " + node.name)
				check(node.get_visible_line_count() >= node.get_line_count(),label + " label lines are not clipped: " + node.name)
				check(node.get_theme_font_size("font_size") * physical_transform.y.length() >= 15.999,label + " readable text keeps approved 16 actual-pixel lower bound")
			if node is Button:
				check(physical_rect.size.y >= 40.0 - 0.01,label + " actual action target remains operable")
	for child in node.get_children(): control_bounds(child,label)

func viewport_metrics() -> Dictionary:
	return {"window_size":str(root.size),"viewport_rect":str(root.get_visible_rect()),"content_scale_mode":root.content_scale_mode,"content_scale_size":str(root.content_scale_size),"final_transform":str(root.get_final_transform())}

func font_coverage(label: Label, context: String) -> void:
	if label == null: return
	var font: Font = label.get_theme_font("font")
	var source: Font = font.base_font if font is FontVariation else font
	check(not source is SystemFont and source.resource_path.begins_with("res://production/ui/beta_shell_01/fonts/"),context + " font is packaged rather than relying on installed Windows font")
	for ch in "若叶睦方块少女另一个世界两岸之间视线相接存档无法写入磁盘设置暂停返回确定重试 ABCDE123%→":
		check(font.has_char(ch.unicode_at(0)),context + " actual bundled font covers character " + ch)

func observation() -> Dictionary:
	return {"cell":str(game.mover.cell),"orientation":game.mover.orientation.key(),"world":game.mover.world,"view":game.view.current,"moves":game.mover.moves,"phase":game.mover.phase,"plate":game.graph.plate_pressed,"gate":game.graph.door_open,"goal":game.graph.complete}

func hint_check(label: String) -> void:
	var hud = game.approved_hud
	check(hud != null,label + " actual L01 owns approved HUD")
	if hud == null: return
	check(hud.hint_label.text == game.hints.text and is_equal_approx(hud.hint_label.modulate.a,game.hints.alpha),label + " Hint consumes existing text and alpha without a second timer")
	check(hud.world_label.text.contains("里" if game.mover.world == 1 else "表"),label + " HUD world label shares actual mover world")
	check(hud.hint_label.focus_mode == Control.FOCUS_NONE and hud.hint_label.mouse_filter == Control.MOUSE_FILTER_IGNORE,label + " Hint neither takes focus nor intercepts gameplay mouse")
	hints.append({"label":label,"text":game.hints.text,"alpha":game.hints.alpha,"flags":{"moved":game.hints.moved,"shifted":game.hints.shifted,"rotated":game.hints.rotated,"rotation_hint_seen":game.hints.rotation_hint_seen},"state":observation(),"hud_world":hud.world_label.text})

func seed_process() -> void:
	check(shell.state == shell.State.MAIN_MENU and shell.view.buttons["continue"].disabled,"CASE A cold Menu reflects actual no-progress Save")
	await layout_checks("main",true)
	await navigation_cycle("main")
	await focus_to(shell.view.buttons["select"])
	await ui_key(KEY_ENTER)
	check(shell.state == shell.State.LEVEL_SELECT,"Enter activates focused real Level Select once")
	await layout_checks("select")
	await navigation_cycle("select")
	await click("level:mutsumi_l01")
	game = shell.adapter.level
	check(shell.current_id == "mutsumi_l01" and game != null and game.presenter != null and not game.board.visible,"CASE A real mouse selects L01 with formal 3D default")
	if game == null: return
	await delay(0.3)
	hint_check("spawn")
	await layout_checks("hint_spawn")
	await move(Vector2i.UP)
	await tap(KEY_E)
	await tap(KEY_SPACE)
	hint_check("after real roll camera and Shift")
	await tap(KEY_R)
	check(game.mover.cell == game.content.spawn and game.mover.world == 0 and game.view.current == 0 and not game.hints.moved and not game.hints.shifted and not game.hints.rotated,"CASE B Reset restores original Runtime and Hint flags")
	hint_check("reset")
	await key(KEY_W,true)
	await delay(0.08)
	await ui_key(KEY_ESCAPE)
	await key(KEY_W,false)
	check(shell.state == shell.State.PAUSED and game.mover.order.is_empty(),"Pause clears actually held gameplay input")
	var frozen := observation()
	await layout_checks("pause")
	await navigation_cycle("pause")
	check(observation() == frozen,"menu keyboard navigation does not leak into paused gameplay")
	await click("settings")
	check(shell.settings_open and shell.state == shell.State.PAUSED,"CASE E Settings retains real paused game context")
	check(root.gui_get_focus_owner() == shell.view.sliders["master"],"Settings default focus starts at Master in approved reading order")
	await layout_checks("settings")
	await settings_flow(frozen)
	await click("resume")
	await delay(0.4)
	check(shell.state == shell.State.PLAYING and game.mover.moves == 1 and root.gui_get_focus_owner() == null,"CASE E resume releases menu focus and finishes prior accepted roll once")
	await tap(KEY_R)
	hint_check("reset before goal route")
	await route_l01("normal")
	await delay(0.25)
	check(shell.state == shell.State.LEVEL_COMPLETE and game.graph.complete and completion_events == 1,"CASE C actual Goal emits one completion and opens approved complete page")
	hint_check("actual Goal")
	check(shell.progress.completed == ["mutsumi_l01"] and shell.progress.unlocked == ["mutsumi_l01","mutsumi_l02"],"CASE C real Save completion unlocks L02 once")
	await layout_checks("complete")
	await navigation_cycle("complete")
	await click("next")
	game = shell.adapter.level
	check(shell.current_id == "mutsumi_l02" and game.content.quality == "GREYBOX" and game.mover.cell == game.content.spawn,"CASE C actual Next enters L02 greybox at Spawn, no 3D migration")
	await shot("l02_real_next_entry")
	cases.append("A/B/C/E/F actual flow and six pages")
	await ui_key(KEY_ESCAPE)
	await click("select")
	game = null
	await click("level:mutsumi_l01")
	game = shell.adapter.level
	check(shell.current_id == "mutsumi_l01" and game.presenter != null and not game.board.visible,"actual selection returns to formal L01 for persisted 3D Continue")
	await tap(KEY_SPACE)
	check(game.mover.world == 1,"actual final L01 Shift supplies an Inner-world exit case")
	await ui_key(KEY_ESCAPE)
	check(shell.state == shell.State.PAUSED and shell.view.get("_world_label").text.contains("里"),"actual Pause identifies current Inner world before leaving the level")
	await click("main")
	game = null
	check(shell.state == shell.State.MAIN_MENU and not shell.view.buttons["continue"].disabled and shell.progress.recent == "mutsumi_l01","saved recent L01 supports cold-process formal 3D Continue")
	var main_world_text: String = shell.view.get("_world_label").text.to_lower()
	check((main_world_text.contains("surface") or main_world_text.contains("表")) and not main_world_text.contains("mortis") and not main_world_text.contains("里"),"Main Menu restores its Surface identity after actual Inner-world level exit")
	await shot("saved_main")

func settings_flow(frozen: Dictionary) -> void:
	var persisted: Dictionary = shell.progress.settings.duplicate(true)
	await navigation_cycle("settings")
	await focus_to(shell.view.sliders["master"])
	var original: float = shell.view.sliders["master"].value
	await ui_key(KEY_LEFT)
	check(shell.view.sliders["master"].value == original-1 and is_equal_approx(shell.preview_settings.master,(original-1)/100.0),"real left arrow adjusts original slider and live preview exactly one step")
	check(observation() == frozen,"Settings arrow input never becomes gameplay movement/camera")
	for key_name in ["music","sfx"]:
		await focus_to(shell.view.sliders[key_name])
		var slider_before: float = shell.view.sliders[key_name].value
		await ui_key(KEY_LEFT)
		check(shell.view.sliders[key_name].value == slider_before-1 and is_equal_approx(float(shell.preview_settings[key_name]),(slider_before-1)/100.0),"real keyboard changes correct live settings field: " + key_name)
		var bus_name: String = "Ambience" if key_name == "music" else "SFX"
		var base_gain: float = -12.0 if key_name == "music" else -6.0
		check(is_equal_approx(AudioServer.get_bus_volume_db(AudioServer.get_bus_index(bus_name)),linear_to_db((slider_before-1)/100.0)+base_gain),"actual audio bus consumes preview through original Settings.apply: " + bus_name)
		await ui_key(KEY_RIGHT)
		check(shell.view.sliders[key_name].value == slider_before,"real keyboard restores original slider value")
	await click("muted")
	check(shell.preview_settings.muted != persisted.get("muted",false) and shell.view.sliders["master"].value == original-1,"mute does not zero any slider")
	var window_before: Vector2i = root.size
	await click("fullscreen")
	await delay(0.2)
	check(shell.preview_settings.fullscreen and root.mode == Window.MODE_FULLSCREEN,"actual checkbox previews fullscreen through original Settings.apply")
	check(observation() == frozen,"fullscreen preview retains actual paused gameplay")
	await ui_key(KEY_ESCAPE)
	await delay(0.2)
	check(root.mode == Window.MODE_WINDOWED and not shell.progress.settings.fullscreen,"Escape Cancel restores persisted windowed mode after actual fullscreen preview")
	root.size = window_before
	await delay(0.2)
	check(not shell.settings_open and shell.progress.settings == persisted and shell.view.screen == "pause","Escape Cancel restores original persisted settings and Pause context")
	check(root.gui_get_focus_owner() == shell.view.buttons["settings"],"Cancel restores Settings source-entry focus")
	await click("settings")
	await focus_to(shell.view.sliders["master"])
	await ui_key(KEY_LEFT)
	var draft: Dictionary = shell.preview_settings.duplicate(true)
	var original_bytes := FileAccess.get_file_as_string(save_path)
	var blocker := save_path + ".bak"
	if FileAccess.file_exists(blocker): DirAccess.remove_absolute(blocker)
	check(DirAccess.make_dir_absolute(blocker) == OK,"isolated real filesystem backup replacement blocker created")
	await click("apply")
	check(shell.settings_open and shell.view.screen == "settings" and not shell.view.status.text.is_empty() and shell.preview_settings == draft,"real Save failure keeps Settings draft and visible reason")
	check(FileAccess.get_file_as_string(save_path) == original_bytes and shell.progress.settings == persisted,"failed Apply preserves actual primary Save bytes and persisted values")
	await shot("settings_actual_save_failure")
	check(DirAccess.remove_absolute(blocker) == OK,"only own empty test blocker removed")
	await click("apply")
	check(not shell.settings_open and shell.progress.settings == draft and shell.store.load_save().settings == draft,"Apply success consumes same draft and persists through actual SaveStore")
	check(root.gui_get_focus_owner() == shell.view.buttons["settings"],"successful Apply restores source-entry focus")

func restore_process() -> void:
	check(FileAccess.file_exists(save_path) and shell.progress.recent == "mutsumi_l01" and shell.progress.completed == ["mutsumi_l01"],"CASE D distinct process loads real prior Save progression")
	check(not shell.view.buttons["continue"].disabled,"Continue enabled only by actual available saved recent")
	await focus_to(shell.view.buttons["continue"])
	await ui_key(KEY_ENTER)
	game = shell.adapter.level
	check(shell.state == shell.State.PLAYING and shell.current_id == "mutsumi_l01" and game.mover.cell == game.content.spawn and game.mover.moves == 0 and game.presenter != null and not game.board.visible,"CASE D Continue starts recent formal 3D L01 at actual Spawn in new OS process")
	await shot("cold_restart_continue")
	cases.append("D actual cold restart Continue")

func save_state_fixtures() -> void:
	var Store: Script = load("res://game/shell/save_store.gd")
	var Catalog: Script = load("res://game/shell/level_catalog.gd")
	for variant in ["none","available","unavailable","readonly"]:
		fixture_index += 1
		var path := save_path.get_base_dir().path_join("fixture_" + variant + ".json")
		var store = Store.new(path,"mutsumi_l01")
		if variant in ["available","unavailable"]:
			var data: Dictionary = store.defaults()
			data.has_progress = true
			data.recent = "mutsumi_l01"
			check(store.save(data),"fixture progression produced by real SaveStore")
		elif variant == "readonly":
			DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(path.get_base_dir()))
			var file := FileAccess.open(path,FileAccess.WRITE)
			file.store_string(JSON.stringify({"version":99,"payload":"future","checksum":"future"}))
			file.close()
		var fixture = load("res://game/shell/game_shell.tscn").instantiate()
		fixture.save_path = path
		if variant == "unavailable":
			fixture.catalog_entries.assign(Catalog.new().entries)
			fixture.catalog_entries[0].scene = "res://tests/beta_sprint/visual_integration/absent_level.tscn"
		root.add_child(fixture)
		await delay(0.2)
		check(fixture.view.buttons["continue"].disabled == (variant != "available"),"actual save-dependent Continue UI: " + variant)
		check(fixture.view.buttons["new"].disabled == (variant == "readonly"),"actual writable-dependent New UI: " + variant)
		if variant == "readonly": check(fixture.store.read_only and not fixture.view.status.text.is_empty(),"future Save protection supplies visible readonly reason")
		contract_cases.append({"case":"real Save fixture " + variant,"continue_disabled":fixture.view.buttons["continue"].disabled,"new_disabled":fixture.view.buttons["new"].disabled,"status":fixture.view.status.text})
		root.remove_child(fixture)
		fixture.free()
		fixture = null
		await delay(0.1)

func completion_contract_matrix() -> void:
	var view = load("res://game/shell/visual_01/approved_shell_view.gd").new()
	root.add_child(view)
	await process_frame
	for size in SIZES:
		root.size = size
		await delay(0.1)
		for saved in [true,false]:
			for next in [true,false]:
				view.show_screen("complete",{"title":LONG_TITLE,"saved":saved,"has_next":next})
				view.set_status("" if saved else LONG_ERROR)
				await delay(0.2)
				check(view.buttons["next"].disabled == not next,"UI contract: has_next alone controls Next availability")
				check(view.buttons.has("retry_save") == not saved,"UI contract: save failure independently retains retry, including final level")
				check(root.gui_get_focus_owner() == view.buttons["next" if next else "select"],"UI contract: default focus is first actual available action")
				control_bounds(view.root,"complete matrix")
				await RenderingServer.frame_post_draw
				var name := "contract_complete_%dx%d_%s_%s" % [size.x,size.y,str(saved),str(next)]
				root.get_texture().get_image().save_png(evidence.path_join(name+".png"))
				contract_cases.append({"case":name,"scope":"presentation contract only; actual L01 Goal separately tested","snapshot":view.debug_snapshot()})
	root.remove_child(view)
	view.free()
	view = null
	await delay(0.1)

func shot(label: String) -> void:
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png(evidence.path_join(label+".png"))
	checkpoints.append({"name":label,"window":[root.size.x,root.size.y],"viewport":viewport_metrics(),"screen":shell.view.screen,"focus":shell.view.debug_snapshot(),"state":observation() if is_instance_valid(game) else {},"status":shell.view.status.text,"status_alpha":shell.view.status.modulate.a,"world_label":shell.view.get("_world_label").text})
	if is_instance_valid(game) and shell.current_id == "mutsumi_l01": hint_check(label)

func finish() -> void:
	var report := {"checks":checks,"failures":failures,"phase":phase,"pid":OS.get_process_id(),"head":head,"project":ProjectSettings.globalize_path("res://"),"save_path":save_path,"save_absolute":ProjectSettings.globalize_path(save_path),"display":DisplayServer.get_name(),"renderer":RenderingServer.get_current_rendering_method(),"device":RenderingServer.get_video_adapter_name(),"engine":Engine.get_version_info(),"dpi":DisplayServer.screen_get_dpi(),"progress":shell.progress,"completion_events":completion_events,"cases":cases,"contracts":contract_cases,"navigation":navigation,"hint_lifecycle":hints,"screenshots":checkpoints,"input_map":input_audit,"scope":{"runtime":"Existing P01 Content/GridMovement; no Foundation RuntimeSession/statekey.v1","Pixel3Dparity":"Prior art_vertical suite must separately run against this same source; not inferred from UI suite","L02":"Actual Next greybox entry only; no migration or completion","L03":"NOT_RUN","fullscreen":"Actual checkbox preview/Cancel restoration tested; three target sizes tested windowed, not three fullscreen resolutions"}}
	report["control_geometry"] = geometry
	report["mouse_targets"] = mouse_targets
	shell.show_main_menu()
	game = null
	await delay(0.2)
	var file := FileAccess.open(evidence.path_join("report.json"),FileAccess.WRITE)
	file.store_string(JSON.stringify(report,"\t"))
	file.close()
	print("VISUAL UI ",phase,": ",checks," checks; failures=",failures)
	if phase == "seed" and failures.is_empty(): shell.request_quit()
	else:
		root.remove_child(shell)
		shell.free()
		shell = null
		await delay(0.12)
		quit(0 if failures.is_empty() else 1)
