extends Node3D
## Formal Shell lifecycle around the existing spatial Host and authoritative Runtime.
const SpatialHost = preload("res://experiments/spatial_puzzle_batch_01/host/spatial_lab.gd")
const Maps = preload("res://experiments/spatial_puzzle_batch_01/maps/map_factory.gd")
const Goal = preload("res://foundation/rules/goal_evaluator.gd")
const Hud = preload("res://game/shell/visual_01/hud.gd")
const UITokens = preload("res://game/shell/visual_01/tokens.gd")
signal completed
signal pause_requested
@export var map_id: StringName = &"orientation_loop_lab"
var host: Node3D
var hud: CanvasLayer
var _paused := false
var _resetting := false
var _closed := false
var _completed := false
var _epoch := 0
var _last_commit := 0
var _pending_goal: Dictionary = {}
var _options := {"reduced_motion":false,"hint_strength":1,"contrast":false,"input_hints":true}

func _ready() -> void:
	# Cold Continue must use the same approved backdrop as entry after L05.
	RenderingServer.set_default_clear_color(UITokens.COLORS.water)
	host = SpatialHost.new()
	host.lab_id = map_id
	add_child(host)
	# The wrapper owns input routing; the Shell alone handles Escape.
	host.set_process_input(false)
	host.set_process_unhandled_key_input(false)
	host.status.hide()
	host.menu_requested.connect(_on_menu_requested)
	host.runtime.committed.connect(_on_committed)
	_last_commit = host.runtime.get_commit_count()
	hud = Hud.new()
	add_child(hud)
	hud.bind(self)

func _process(_delta: float) -> void:
	if not _closed and is_instance_valid(hud): hud.sync()
	if not _pending_goal.is_empty(): _complete_if_current()

func _on_committed(state: Dictionary) -> void:
	if _closed or _resetting or _completed or not host.runtime.is_loaded(): return
	if state != host.runtime.get_state(): return
	var count: int = host.runtime.get_commit_count()
	if count <= _last_commit: return
	_last_commit = count
	var scope: Dictionary = host.runtime.get_presentation_scope()
	var result: Dictionary = Goal.is_goal(host.runtime.get_level(), state)
	if result.ok and result.is_goal:
		# Let native Tween/Presenter completion unwind before Shell suspends us.
		_pending_goal = {"epoch":_epoch,"scope":scope,"count":count,"state":state.duplicate(true)}
		_complete_if_current.call_deferred()

func _complete_if_current() -> void:
	if _closed or not is_inside_tree() or _resetting or _completed or _pending_goal.is_empty(): return
	# Shell accepts completion while PLAYING. Keep the real committed Goal until
	# resume; a reset/unload or changed Runtime scope still retires this callback.
	if _paused: return
	var pending := _pending_goal
	if pending.epoch != _epoch or not host.runtime.is_loaded() or host.runtime.get_presentation_scope() != pending.scope or host.runtime.get_commit_count() != pending.count or host.runtime.get_state() != pending.state:
		_pending_goal = {}
		return
	# Commit may precede decorative landing. Observe the existing native motions;
	# Shell suspension must not freeze a still-active Presenter or Tween.
	if not host.runtime.is_idle() or host.presenter.snapshot().phase != "IDLE": return
	if not host._camera_motion.is_empty() or not host._shift_identity.is_empty(): return
	_pending_goal = {}
	_completed = true
	completed.emit()

func reset_level() -> void:
	if _closed or not is_instance_valid(host): return
	_resetting = true
	_epoch += 1
	_completed = false
	_pending_goal = {}
	host.presenter.release_edge_intent()
	host.reset_lab()
	_last_commit = host.runtime.get_commit_count()
	_resetting = false
	set_level_paused(false)
	if is_instance_valid(hud): hud.sync()

func set_level_paused(value: bool) -> void:
	_paused = value
	# The Shell owns foreground UI while paused or showing level completion.
	if is_instance_valid(hud): hud.set_active(not value)
	if _closed or not is_instance_valid(host): return
	if value: host.presenter.release_edge_intent()
	host.set_lab_paused(value)
	if not value and not _pending_goal.is_empty(): _complete_if_current.call_deferred()

func _on_menu_requested() -> void:
	if _closed or _resetting or _paused: return
	set_level_paused(true)
	pause_requested.emit()

func _unhandled_key_input(event: InputEvent) -> void:
	if _closed or _resetting or _paused or _completed or not is_instance_valid(host): return
	if not event is InputEventKey or not event.pressed or event.echo: return
	var key: int = event.physical_keycode if event.physical_keycode != 0 else event.keycode
	if key == KEY_ESCAPE: return
	if key == KEY_R:
		reset_level()
		get_viewport().set_input_as_handled()
		return
	if not _pending_goal.is_empty(): return
	host._unhandled_key_input(event)

func _input(event: InputEvent) -> void:
	if _closed or _resetting or _paused or not is_instance_valid(host): return
	host._input(event)

func apply_settings(values: Dictionary) -> void:
	if not _closed and is_instance_valid(host) and is_instance_valid(host.audio_bridge):
		host.audio_bridge.director.apply_settings(values)

func set_reduced_motion(value: bool) -> void:
	_options.reduced_motion = value
	if not _closed and is_instance_valid(host): host.set_reduced_motion(value)

func apply_accessibility(options: Dictionary) -> void:
	for key in _options:
		if options.has(key): _options[key] = options[key]
	set_reduced_motion(_options.reduced_motion)
	if is_instance_valid(hud): hud.sync()

func get_world_label() -> String:
	if not is_instance_valid(host) or not host.runtime.is_loaded(): return ""
	return "表世界" if host.runtime.get_state().player.location.layer == 0 else "里世界"

func get_hint_presentation() -> Dictionary:
	var description: Dictionary = Maps.describe(map_id)
	var state: Dictionary = host.runtime.get_state() if is_instance_valid(host) and host.runtime.is_loaded() else {}
	var lines: PackedStringArray = host.status.text.split("\n") if is_instance_valid(host) else PackedStringArray()
	return {"title":description.get("title", ""),"objective":description.get("objective", ""),
		"hint":description.get("hint", ""),"hint_visible":is_instance_valid(host) and host._hint_visible and _options.hint_strength > 0,
		"camera_quadrant":state.get("camera_quadrant", 0),"feedback":lines[3] if lines.size() > 3 else "",
		"controls":"WASD / 方向键：翻滚   F：向标记边缘前进   Q/E：视角   Space：转换   R：重置   Esc：暂停   H：提示",
		"hint_strength":_options.hint_strength,"input_hints":_options.input_hints,"contrast":_options.contrast}

func _exit_tree() -> void:
	_closed = true
	_epoch += 1
	_pending_goal = {}
	if is_instance_valid(host):
		host.set_process_input(false)
		host.set_process_unhandled_key_input(false)
		if host.runtime.committed.is_connected(_on_committed): host.runtime.committed.disconnect(_on_committed)
		host._close("UNLOAD")

# Read-only UI facade, separate from the game-feel Runtime/Presenter contract.
func get_presentation_world() -> int:
	if _closed or not is_instance_valid(host) or not host.runtime.is_loaded(): return -1
	return int(host.runtime.get_state().player.location.layer)
