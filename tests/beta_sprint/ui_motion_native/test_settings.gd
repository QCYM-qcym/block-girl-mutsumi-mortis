extends SceneTree
var failures: Array[String] = []
var checks := 0
var ui
var previews: Array[Dictionary] = []
var applies: Array[Dictionary] = []
func check(value: bool, label: String) -> void:
 checks += 1
 if not value: failures.append(label)
func _initialize() -> void: call_deferred("run")
func settle() -> void:
 for frame in 6: await process_frame
func run() -> void:
 root.content_scale_size = Vector2i.ZERO
 root.content_scale_mode = Window.CONTENT_SCALE_MODE_DISABLED
 root.size = Vector2i(960,720)
 ui = load("res://game/feel/ui/game_feel_ui.gd").new()
 root.add_child(ui)
 await settle()
 check(ui.has_method("set_presentation"), "settings exposes native presentation API")
 if not ui.has_method("set_presentation"):
  finish()
  return
 ui.settings_preview.connect(func(values): previews.append(values))
 ui.settings_apply.connect(func(values): applies.append(values))
 var fields = ui.settings_scroll.get_child(0)
 var extra = load("res://game/shell/visual_01/stone_check.gd").new()
 extra.text = "高对比度"
 fields.add_child(extra)
 var notice := Label.new()
 notice.text = "只读存档提示"
 ui.settings_panel.get_child(0).get_child(0).add_child(notice)
 ui.set_presentation(1,true)
 ui.open_settings({"master":0.8})
 await settle()
 check(is_equal_approx(ui.settings_panel.size.x,330) and is_equal_approx(ui.settings_panel.size.y,632) and ui.settings_panel.position.x < 40, "960px native drawer is left aligned and reserves toolbar")
 check(ui.buttons.apply.get_parent() is HBoxContainer and ui.buttons.apply.get_parent() == ui.buttons.cancel.get_parent(), "fixed footer uses one horizontal row")
 check(extra.has_method("set_palette") and extra.get_theme_color("font_color") == Color.WHITE and notice.get_theme_color("font_color") == Color.WHITE, "late host controls receive inner high contrast styling")
 check(ui.focus_order[0] == ui.sliders.master and ui.focus_order[7] == ui.buttons.apply and ui.focus_order[8] == ui.buttons.cancel, "focus slots preserved")
 ui.sliders.master.value = 37
 ui.buttons.apply.pressed.emit()
 check(applies.size() == 1 and applies[0].master == 0.37 and not ui.sliders.master.editable and ui.buttons.cancel.disabled, "apply preserves draft and async freeze")
 ui.settings_failed("保存失败：".repeat(1500))
 await settle()
 var bottom: float = ui.buttons.cancel.get_global_rect().end.y
 check(bottom <= ui.settings_panel.get_global_rect().end.y and ui.buttons.cancel.size.y >= 44 and ui.settings_panel.size.y == 632, "long errors never displace fixed footer")
 check(ui.error_label.autowrap_mode != TextServer.AUTOWRAP_OFF and ui.error_label.get_parent() is ScrollContainer, "errors wrap in a bounded scroll region")
 check(ui.settings_open and ui.sliders.master.value == 37 and not ui.buttons.cancel.disabled, "failure restores editability while retaining draft")
 check(root.gui_get_focus_owner() == ui.buttons.apply, "failed save focuses retry")
 var dark_ink: Color = ui.sliders.master.get_theme_stylebox("grabber_area").bg_color
 ui.set_presentation(0,false)
 check(ui.sliders.master.get_theme_stylebox("grabber_area").bg_color != dark_ink and extra.get_theme_color("font_color") != Color.WHITE, "world switch recolors real slider and check controls")
 check(ui.sliders.master.value == 37 and ui.settings_scroll.get_child(0) == fields, "palette changes preserve controls and draft")
 ui.buttons.cancel.pressed.emit()
 check(not ui.settings_open and previews.back().master == 0.8, "cancel restores saved preview")
 for area in [Vector2i(1280,720),Vector2i(1920,1080)]:
  root.size = area
  await settle()
  check(is_equal_approx(ui.settings_panel.size.x,clampf(area.x * 0.30,330,440)) and is_equal_approx(ui.settings_panel.size.y,area.y-88), "drawer dimensions adapt at "+str(area))
 ui.queue_free()
 await process_frame
 finish()
func finish() -> void:
 print(JSON.stringify({"checks":checks,"failures":failures,"scope":"NATIVE_SETTINGS_HEADLESS"}))
 quit(0 if failures.is_empty() else 1)
