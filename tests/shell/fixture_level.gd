extends Node2D
## Minimal owner-local two-level fixture; never registered in production catalog.
signal completed
var ticks := 0
var inputs := 0
var resets := 0
var complete := false

func _process(_delta: float) -> void:
	ticks += 1

func _input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and event.keycode == KEY_W:
		inputs += 1

func finish() -> void:
	complete = true
	completed.emit()

func reset_level() -> void:
	complete = false
	inputs = 0
	resets += 1
