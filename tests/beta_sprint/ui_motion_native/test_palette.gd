extends SceneTree
var failures: Array[String] = []
var checks := 0
func check(value: bool, name: String) -> void:
 checks += 1
 if not value: failures.append(name)
func _initialize() -> void:
 call_deferred("run")
func run() -> void:
 var path := "res://game/shell/visual_02/palette.gd"
 check(ResourceLoader.exists(path), "native palette is delivered")
 if ResourceLoader.exists(path):
  var palette = load(path)
  var surface: Dictionary = palette.colors(0)
  var inner: Dictionary = palette.colors(1)
  check(surface.ink != inner.ink and surface.face != inner.face and surface.accent != inner.accent, "world changes all palette roles")
  var contrast: Dictionary = palette.colors(1, true)
  check(contrast.ink == Color.WHITE, "high contrast uses readable light ink on dark drawer")
  check(surface == palette.colors(0), "palette has no shared mutable cross-world state")
  check(palette.has_method("control_icon"), "filled controls retain foreground/background contrast")
  if palette.has_method("control_icon"):
   var tokens = load("res://game/shell/visual_01/tokens.gd")
   var checked: Image = palette.control_icon(tokens.icon("checked"),surface).get_image()
   var unchecked: Image = palette.control_icon(tokens.icon("unchecked"),surface).get_image()
   check(absf(checked.get_pixel(13,21).get_luminance()-unchecked.get_pixel(13,21).get_luminance()) > 0.2,"real check mark remains distinguishable from empty box")
 print(JSON.stringify({"checks":checks,"failures":failures,"scope":"NATIVE_UI_PALETTE"}))
 quit(0 if failures.is_empty() else 1)
