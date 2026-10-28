extends "res://game/feel/ui/motion_row.gd"
## Native Button/focus/press lifecycle inherited from the existing controls.
const Palette = preload("res://game/shell/visual_02/palette.gd")
var presentation_colors: Dictionary = Palette.colors(0)

func set_palette(value: Dictionary) -> void:
 presentation_colors = value.duplicate()
 if is_node_ready(): _layout()

func _layout() -> void:
 if not is_instance_valid(_title): return
 var unit: float = clampf(scale_unit,0.8,1.3)
 _title.text = display_text
 _detail.text = detail
 _number.text = number
 for label in [_title,_detail,_number]:
  label.add_theme_font_override("font",Tokens.font(false))
  label.add_theme_color_override("font_color",presentation_colors.disabled if disabled else presentation_colors.ink)
 _title.add_theme_font_size_override("font_size",maxi(16,roundi(22*unit)))
 _detail.add_theme_font_size_override("font_size",maxi(16,roundi(16*unit)))
 _number.add_theme_font_size_override("font_size",maxi(13,roundi(14*unit)))
 var left: float = 66*unit
 if catalog_row:
  left = 63*unit
  _number.position = Vector2(8,0)*unit
  _number.size = Vector2(38*unit,size.y)
  _number.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
 _title.position = Vector2(left,_press_amount)
 _title.size = Vector2(maxf(1,size.x-left-8),size.y if detail.is_empty() else size.y*.59)
 _title.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
 _title.max_lines_visible = 1
 _title.autowrap_mode = TextServer.AUTOWRAP_OFF
 _detail.position = Vector2(left,size.y*.59+_press_amount)
 _detail.size = Vector2(maxf(1,size.x-left-8),size.y*.38)
 _detail.visible = not detail.is_empty()
 _number.visible = catalog_row
 _canvas.queue_redraw()

func _draw_row() -> void:
 var unit: float = clampf(scale_unit,0.8,1.3)
 var colour: Color = presentation_colors.disabled if disabled else presentation_colors.secondary
 if (is_hovered() or has_focus()) and not disabled:
  _canvas.draw_rect(Rect2(Vector2.ZERO,size),presentation_colors.hover)
 if catalog_row:
  _canvas.draw_line(Vector2(0,size.y),Vector2(size.x,size.y),presentation_colors.seam,1)
 else:
  var centre := Vector2(24*unit,size.y/2+_press_amount)
  var radius: float = 19*unit
  _canvas.draw_circle(centre,radius,presentation_colors.edge)
  _canvas.draw_arc(centre,radius,0,TAU,48,presentation_colors.accent if has_focus() and not disabled else presentation_colors.seam,1.2,true)
  if glyph:
   _canvas.draw_texture_rect(Palette.white_icon(glyph),Rect2(centre-Vector2.ONE*12*unit,Vector2.ONE*24*unit),false,colour)
 if has_focus() and not disabled:
  _canvas.draw_line(Vector2(1,size.y-1),Vector2(size.x-1,size.y-1),presentation_colors.accent,1.5)
