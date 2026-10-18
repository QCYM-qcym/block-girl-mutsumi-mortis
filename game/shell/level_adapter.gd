extends Node
## Adapts existing level lifecycle without changing its rules or content.
signal completed
signal pause_requested
var level: Node
var kind := ""
var reported := false

func enter(entry: Dictionary) -> void:
	unload()
	kind = entry.get("adapter", "")
	level = load(entry.scene).instantiate()
	add_child(level)
	if kind == "signal":
		level.completed.connect(_report_completion)
		if level.has_signal("pause_requested"):
			level.pause_requested.connect(func(): pause_requested.emit())
	elif kind == "p01":
		# graph.bind() connected settle during _ready, before this observer.
		# Record the achieved Goal in that same commit; R/navigation cannot erase it.
		level.mover.committed.connect(_on_p01_committed)
	reported = false

func _process(_delta: float) -> void:
	if level == null or reported or level.process_mode == Node.PROCESS_MODE_DISABLED:
		return
	if kind == "p01" and level.graph.complete:
		_report_completion()

func _on_p01_committed() -> void:
	if level.graph.complete:
		_report_completion()

func _report_completion() -> void:
	if reported:
		return
	reported = true
	completed.emit()

func suspend(value: bool) -> void:
	if level == null:
		return
	if level.has_method("set_level_paused"):
		level.set_level_paused(value)
	if value and kind == "p01":
		# Reuse the level's existing focus-loss input cleanup, including drag rebound.
		level.controls.notification(Node.NOTIFICATION_WM_WINDOW_FOCUS_OUT)
	level.process_mode = Node.PROCESS_MODE_DISABLED if value else Node.PROCESS_MODE_INHERIT
	for player in level.find_children("*", "AudioStreamPlayer", true, false):
		player.stream_paused = value

func reset() -> void:
	if level == null:
		return
	level.reset_level()
	reported = false
	suspend(false)

func unload() -> void:
	if is_instance_valid(level):
		remove_child(level)
		level.queue_free()
	level = null
	reported = false
