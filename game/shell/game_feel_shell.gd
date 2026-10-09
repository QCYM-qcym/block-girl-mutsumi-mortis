extends "res://game/shell/game_shell.gd"
## 00 wiring only; approved Shell remains the lifecycle/progress owner.
const FeelHost = preload("res://game/shell/game_feel_host.gd")
var game_feel
var _quit_requested := false
func _ready() -> void:
	super._ready()
	game_feel=FeelHost.new();add_child(game_feel);game_feel.bind_shell(self)
func start_level(id: String) -> void:
	# Legacy standalone levels resize their Window in _ready; shared Host owns its viewport.
	var window:=get_window()
	var previous_size:=window.size
	var previous_min:=window.min_size
	super.start_level(id)
	window.min_size=previous_min
	if window.mode==Window.MODE_WINDOWED: window.size=previous_size
func open_settings() -> void:
	if game_feel: game_feel.open_settings()
	else: super.open_settings()
func save_settings() -> void:
	if game_feel: game_feel.ui.buttons.apply.pressed.emit()
	else: super.save_settings()
func cancel_settings() -> void:
	if game_feel: game_feel.ui.cancel_settings()
	else: super.cancel_settings()
func reset_current() -> void:
	if state not in [State.PAUSED,State.LEVEL_COMPLETE]: return
	if game_feel: game_feel.prepare_reset()
	super.reset_current()
func request_quit() -> void:
	if _quit_requested: return
	if settings_open: cancel_settings()
	if dirty and not _save_progress(): return
	_quit_requested=true
	# Run the same scene-unload boundary before quitting, including native interruption/audio cleanup.
	_leave_level()
	# Let queued scene destruction and the audio mixer retire their WAV playbacks
	# before the engine tears down ObjectDB. No SaveStore semantics change.
	await get_tree().process_frame
	await get_tree().create_timer(0.12).timeout
	get_tree().quit()
func _on_setting_preview(key: String,value: Variant) -> void:
	if game_feel and game_feel.ui.settings_open:
		if game_feel.ui.sliders.has(key): game_feel.ui.sliders[key].value=float(value)*100.0
		elif game_feel.ui.buttons.has(key): game_feel.ui.buttons[key].button_pressed=value
	else: super._on_setting_preview(key,value)
func _leave_level() -> void:
	if game_feel: game_feel.leave_level()
	super._leave_level()
func _set_state(value: State) -> void:
	super._set_state(value)
	if game_feel: game_feel.shell_state_changed()
func _render_state() -> void:
	if game_feel and game_feel.lab_active:
		if state==State.PAUSED: view.show_screen("pause",{"title":"错视实验"})
		else: view.show_screen("playing")
	else: super._render_state()
func _on_action(action: String,id: String) -> void:
	if game_feel and settings_open:
		if action=="quit": request_quit()
		return
	if game_feel and game_feel.lab_active and action=="reset":
		reset_current();game_feel.shell_state_changed()
	else: super._on_action(action,id)
