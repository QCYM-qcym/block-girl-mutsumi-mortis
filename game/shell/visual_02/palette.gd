extends RefCounted
## Per-view colours only. The frozen legacy Tokens and source assets remain unchanged.
const Tokens = preload("res://game/shell/visual_01/tokens.gd")
static var _white_icons: Dictionary = {}

static func colors(layer: int, contrast: bool = false) -> Dictionary:
 var result: Dictionary
 if layer == 1:
  result = {"ink":Color("eeebfa"),"secondary":Color("c5bfd8"),"accent":Color("c4b7ed"),"face":Color("191c37e8"),"edge":Color("292644c9"),"seam":Color("a69cc280"),"hover":Color("aaa2ce22"),"disabled":Color("8a849e"),"water":Color("28364a"),"light":Color("ffffff"),"leaf":Color("87cdd6")}
 else:
  result = {"ink":Color("f0f5ed"),"secondary":Color("c6d3c9"),"accent":Color("9ce1d7"),"face":Color("203940e8"),"edge":Color("223d4bc9"),"seam":Color("a1bbba70"),"hover":Color("d8e4d41f"),"disabled":Color("91a29c"),"water":Color("b7c8c1"),"light":Color("ffffff"),"leaf":Color("c9ccaa")}
 if contrast:
  result.ink = Color.WHITE
  result.secondary = Color.WHITE
  result.face = Color("101725f7")
  result.seam = Color("e0def1b0")
 return result

static func panel(value: Dictionary) -> StyleBoxFlat:
 var style := StyleBoxFlat.new()
 style.bg_color = value.face
 style.border_color = value.seam
 style.border_width_right = 1
 return style

static func white_icon(texture: Texture2D) -> Texture2D:
 if texture == null: return null
 var key: int = texture.get_instance_id()
 if _white_icons.has(key): return _white_icons[key]
 var image: Image = texture.get_image()
 if image == null or image.is_empty(): return texture
 image = image.duplicate()
 image.convert(Image.FORMAT_RGBA8)
 for y in image.get_height():
  for x in image.get_width():
   var alpha: float = image.get_pixel(x,y).a
   image.set_pixel(x,y,Color(1,1,1,alpha))
 var result := ImageTexture.create_from_image(image)
 _white_icons[key] = result
 return result

static func theme(layer: int, contrast: bool = false) -> Theme:
 var value := colors(layer,contrast)
 var result := Tokens.theme()
 result.default_font = Tokens.font(false)
 result.default_font_size = 18
 for type in ["Label","Button","CheckButton"]:
  for role in ["font_color","font_hover_color","font_focus_color","font_pressed_color"]:
   result.set_color(role,type,value.ink)
  result.set_color("font_disabled_color",type,value.disabled)
 for type in ["Button","CheckButton"]:
  result.set_stylebox("hover",type,Tokens.flat(value.hover))
 result.set_stylebox("slider","HSlider",Tokens.rail(value.seam))
 result.set_stylebox("grabber_area","HSlider",Tokens.rail(value.accent))
 result.set_stylebox("grabber_area_highlight","HSlider",Tokens.rail(value.accent))
 result.set_icon("grabber","HSlider",white_icon(load(Tokens.ROOT+"icons/slider_grab.svg")))
 result.set_icon("grabber_highlight","HSlider",result.get_icon("grabber","HSlider"))
 result.set_icon("checked","CheckButton",control_icon(Tokens.icon("checked"),value))
 result.set_icon("unchecked","CheckButton",control_icon(Tokens.icon("unchecked"),value))
 return result

static func control_icon(texture: Texture2D, value: Dictionary) -> Texture2D:
 # Filled checkbox sources have a light interior and dark mark. Tinting every
 # nontransparent pixel white erases the mark; preserve both visual roles.
 var result: Image = texture.get_image().duplicate()
 result.convert(Image.FORMAT_RGBA8)
 for y in result.get_height():
  for x in result.get_width():
   var original := result.get_pixel(x,y)
   var ink_weight := 1.0-smoothstep(0.25,0.65,original.get_luminance())
   var colour: Color = value.edge.lerp(value.ink,ink_weight)
   colour.a = original.a
   result.set_pixel(x,y,colour)
 return ImageTexture.create_from_image(result)
