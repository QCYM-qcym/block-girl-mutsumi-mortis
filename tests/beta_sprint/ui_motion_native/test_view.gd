extends SceneTree
var failures: Array[String] = []
func check(value: bool, message: String) -> void:
	if not value: failures.append(message)
func _initialize() -> void:
	call_deferred("run")
func run() -> void:
	var path := "res://game/shell/visual_02/menu_view.gd"
	if not ResourceLoader.exists(path):
		printerr("FAIL: native menu view missing")
		quit(1)
		return
	root.size = Vector2i(1280, 720)
	var view = load(path).new()
	root.add_child(view)
	await process_frame
	check(not view.backdrop.visible, "initial backdrop hidden")
	view.show_screen("main", {"can_continue":false,"writable":false})
	await process_frame
	check(view.buttons.has("continue") and view.buttons.continue.disabled, "Continue retains real unavailable state")
	check(view.buttons.new.disabled, "read-only save disables New")
	check(view.backdrop.visible, "main has native avatar")
	check(not view._panel.visible, "main has no opaque drawer")
	check(view._menu_veil.texture is GradientTexture2D, "native gradient veil provides text contrast")
	check(view._identity.text == "方块少女" and view.heading.text == "若叶睦", "main V4 identity hierarchy")
	check(view.buttons.quit.get_global_rect().end.y < view.get_viewport().get_visible_rect().size.y - 80, "five main actions fit above toolbar")
	check(not view._background.visible, "old static image hidden")
	check(view.world_buttons[0] in view.focus_order and view.world_buttons[1] in view.focus_order, "keyboard loop includes world controls")
	check(view.world_buttons[0].get_theme_stylebox("focus").border_width_left == 2, "toolbar focus is visibly outlined")
	view.set_world_layer(1)
	check(view.debug_snapshot().world_layer == 1, "integer world palette")
	var entries: Array = []
	for i in 10:
		entries.append({"id":"l%d"%i,"title":"测试关卡%d"%i,"available":true})
	view.show_screen("select", {"entries":entries,"unlocked":["l0"],"completed":[]})
	await process_frame
	check(view.buttons["level:l1"].disabled, "locked catalog entry disabled")
	check(view._select_scroll.visible and view._select_scroll.follow_focus, "catalog scroll follows focus")
	check(view.buttons.main.get_parent() == view.body and view.buttons.settings.get_parent() == view.body, "narrow catalog footer uses legible full-width rows")
	view.show_screen("confirm_new")
	check(view.buttons.has("cancel_new") and view.buttons.has("confirm_new"), "confirm keeps both actions")
	view.set_settings_overlay(true)
	check(not view._content.visible and view.backdrop.visible, "settings hides menu but retains avatar")
	view.set_settings_overlay(false)
	view.set_accessibility({"contrast":true,"reduced_motion":true})
	check(view._contrast, "actual contrast setting consumed")
	view.show_screen("pause")
	check(not view.backdrop.visible, "pause preserves gameplay instead of avatar")
	check(view.world_buttons[0].disabled and view.world_buttons[1].disabled, "runtime palette selector inert")
	view.show_screen("complete", {"saved":true})
	check(not view.backdrop.visible, "complete preserves gameplay instead of avatar")
	view.show_screen("playing")
	check(not view.backdrop.visible, "playing disables avatar")
	check(view.pause_button.visible, "playing retains pause entry")
	view.queue_free()
	await process_frame
	for failure in failures: printerr("FAIL: " + failure)
	print("NATIVE_VIEW_PASS" if failures.is_empty() else "NATIVE_VIEW_FAIL")
	quit(0 if failures.is_empty() else 1)
