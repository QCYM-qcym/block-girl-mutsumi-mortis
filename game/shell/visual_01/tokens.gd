extends RefCounted
const COLORS := {"face": Color("e0e3db"), "edge": Color("d3d7cf"), "seam": Color("b4b7a9"),
	"water": Color("93bcbe"), "accent": Color("5c919b"), "leaf": Color("becfa8"),
	"ink": Color("162333"), "hover": Color("c3cdc7"), "secondary": Color("344a50"),
	"disabled": Color("4f5d5a"), "light": Color("f0f1e9")}
const ROOT := "res://production/ui/beta_shell_01/"
static var _fonts: Dictionary = {}
static var _icons: Dictionary = {}

static func font(serif: bool = false, weight: int = 400) -> FontVariation:
	var key := "%s:%s" % [serif, weight]
	if _fonts.has(key):
		return _fonts[key]
	var result := FontVariation.new()
	result.base_font = load(ROOT + "fonts/" + ("NotoSerifSC.ttf" if serif else "NotoSansSC.ttf"))
	result.variation_opentype = {"wght": weight}
	_fonts[key] = result
	return result

static func icon(name: String) -> Texture2D:
	if not _icons.has(name):
		_icons[name] = load(ROOT + "icons/" + name + ".svg")
	return _icons[name]

static func label(text: String, pixels: int, serif: bool = false) -> Label:
	var node := Label.new()
	node.text = text
	node.add_theme_font_override("font", font(serif))
	node.add_theme_font_size_override("font_size", pixels)
	node.add_theme_color_override("font_color", COLORS.ink)
	node.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	node.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return node

static func flat(color: Color, bottom: bool = false) -> StyleBoxFlat:
	var box := StyleBoxFlat.new()
	box.bg_color = color
	if bottom:
		box.border_color = COLORS.edge
		box.border_width_bottom = 4
	return box

static func rail(color: Color) -> StyleBoxFlat:
	var box := flat(color)
	box.content_margin_top = 1.0
	box.content_margin_bottom = 1.0
	return box

static func theme() -> Theme:
	var result := Theme.new()
	result.default_font = font()
	result.default_font_size = 22
	for type in ["Label", "Button", "CheckButton"]:
		result.set_color("font_color", type, COLORS.ink)
		result.set_color("font_hover_color", type, COLORS.ink)
		result.set_color("font_focus_color", type, COLORS.ink)
		result.set_color("font_pressed_color", type, COLORS.ink)
		result.set_color("font_disabled_color", type, COLORS.disabled)
	for type in ["Button", "CheckButton"]:
		for state in ["normal", "pressed", "disabled", "focus"]:
			result.set_stylebox(state, type, StyleBoxEmpty.new())
		result.set_stylebox("hover", type, flat(COLORS.hover))
	result.set_stylebox("slider", "HSlider", rail(COLORS.seam))
	result.set_stylebox("grabber_area", "HSlider", rail(COLORS.ink))
	result.set_stylebox("grabber_area_highlight", "HSlider", rail(COLORS.ink))
	result.set_icon("grabber", "HSlider", load(ROOT + "icons/slider_grab.svg"))
	result.set_icon("grabber_highlight", "HSlider", load(ROOT + "icons/slider_grab.svg"))
	result.set_icon("checked", "CheckButton", load(ROOT + "icons/checked.svg"))
	result.set_icon("unchecked", "CheckButton", load(ROOT + "icons/unchecked.svg"))
	return result
