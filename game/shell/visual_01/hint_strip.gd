extends Control
## Glyphs adapt only the existing hint text; no trigger or clock lives here.
const Tokens = preload("res://game/shell/visual_01/tokens.gd")
var text := ""
var pixels := 22
var ui_font: Font = Tokens.font()

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE

func _draw() -> void:
	if text.is_empty():
		return
	draw_rect(Rect2(Vector2(0, 4), size), Tokens.COLORS.edge)
	draw_rect(Rect2(Vector2.ZERO, size), Tokens.COLORS.face)
	var keys: Array = ["Space"] if text == "Space" else ["W", "A", "S", "D"] if text.contains("W A S D") else ["Q", "E"]
	var action := "切换世界" if text == "Space" else "翻滚移动" if text.contains("W A S D") else "转动视角 · 鼠标左右拖动"
	var cap_width := 86.0 if text == "Space" else 36.0
	var x := 16.0
	for key in keys:
		var cap := Rect2(x, (size.y - 34) / 2, cap_width, 34)
		draw_rect(Rect2(cap.position + Vector2(0, 3), cap.size), Tokens.COLORS.edge)
		draw_rect(cap, Tokens.COLORS.face)
		draw_rect(cap, Tokens.COLORS.seam, false, 1)
		var width := ui_font.get_string_size(key, HORIZONTAL_ALIGNMENT_LEFT, -1, 16).x
		draw_string(ui_font, cap.position + Vector2((cap_width - width) / 2, 24), key, HORIZONTAL_ALIGNMENT_LEFT, -1, 16, Tokens.COLORS.ink)
		x += cap_width + 6
	draw_string(ui_font, Vector2(x + 18, (size.y + ui_font.get_ascent(pixels)) / 2 - 2), action,
		HORIZONTAL_ALIGNMENT_LEFT, size.x - x - 24, pixels, Tokens.COLORS.ink)
