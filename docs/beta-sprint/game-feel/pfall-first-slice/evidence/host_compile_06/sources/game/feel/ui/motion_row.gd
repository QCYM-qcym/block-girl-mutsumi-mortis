extends "res://game/shell/visual_01/stone_row.gd"
## Approved row drawing; experimental UI motion can be removed without editing its source.
var reduced_motion := false

func set_reduced_motion(value: bool) -> void:
	reduced_motion = value
	if value:
		if _focus_tween and _focus_tween.is_valid(): _focus_tween.kill()
		if _press_tween and _press_tween.is_valid(): _press_tween.kill()
		_press_amount = 0.0
		_animate_focus()
		_layout()

func _animate_focus() -> void:
	if not reduced_motion:
		super._animate_focus()
		return
	_focus_amount = 1.0 if has_focus() and not disabled else 0.0
	_canvas.queue_redraw()

func _animate_press(value: float, seconds: float) -> void:
	if not reduced_motion: super._animate_press(value, seconds)
