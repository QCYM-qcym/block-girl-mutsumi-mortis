extends Node
## Shared routing/persistence only; Owner modules retain their algorithms.
const UI = preload("res://game/feel/ui/game_feel_ui.gd")
const Audio = preload("res://game/feel/audio/audio_director.gd")
const Settings = preload("res://game/shell/settings.gd")
const Shell = preload("res://game/shell/game_shell.gd")
const Tokens = preload("res://game/shell/visual_01/tokens.gd")
const Check = preload("res://game/shell/visual_01/stone_check.gd")
const Row = preload("res://game/shell/visual_02/menu_row.gd")
const Palette = preload("res://game/shell/visual_02/palette.gd")
const Goal = preload("res://foundation/rules/goal_evaluator.gd")
const OPTIONS = {"version":1,"reduced_motion":false,"hint_strength":1,"contrast":false,"input_hints":true}
var shell: Node
var ui
var audio
var options: Dictionary=OPTIONS.duplicate()
var extra_controls: Dictionary={}
var lab_entry
var lab_active := false
var epoch := 0
var runtime: Object
var _event_callback: Callable
var _commit_callback: Callable
var _draft_options: Dictionary={}
var _scope: Dictionary={}
var _updating := false
var _closing := false
var _cue_sequence := 0
var _legacy_level: Node
var _legacy_audio: Node
var _legacy_callback: Callable
var _legacy_reset_callback: Callable
var _goal_scope: Dictionary={}
var _audio_identities: Dictionary={}
var _last_audio_identity: Dictionary={}
var _menu_world := 0
var _presentation_world_last := -1
var _presentation_contrast_last := false
var _presentation_options: Dictionary = {}
var _presentation_settings_last := false

func _read_presentation_world() -> int:
	if not is_instance_valid(shell): return _menu_world
	var level: Node = shell.adapter.level
	var value := -1
	if is_instance_valid(level) and level.has_method("get_presentation_world"):
		value = int(level.get_presentation_world())
	elif is_instance_valid(runtime):
		value = int(runtime.get_state().player.location.layer)
	if value in [0,1]: _menu_world = value
	return _menu_world

func _sync_presentation(force: bool = false) -> void:
	if not is_instance_valid(shell) or not is_instance_valid(ui): return
	var layer := _read_presentation_world()
	var contrast: bool = bool(options.get("contrast",false))
	if force or layer != _presentation_world_last or contrast != _presentation_contrast_last:
		_presentation_world_last = layer
		_presentation_contrast_last = contrast
		shell.view.set_world_layer(layer)
		ui.set_presentation(layer,contrast)
		if is_instance_valid(lab_entry): lab_entry.set_palette(Palette.colors(layer,contrast))
	if force or options != _presentation_options:
		_presentation_options = options.duplicate(true)
		shell.view.set_accessibility(options)
		if is_instance_valid(lab_entry): lab_entry.set_reduced_motion(bool(options.get("reduced_motion",false)))
	if force or shell.settings_open != _presentation_settings_last:
		_presentation_settings_last = shell.settings_open
		shell.view.set_settings_overlay(shell.settings_open)

func _select_presentation_world(value: int) -> void:
	# Showcase choice never requests a gameplay action or changes a saved state.
	if shell.adapter.level == null and shell.state in [Shell.State.MAIN_MENU,Shell.State.LEVEL_SELECT]:
		_menu_world = clampi(value,0,1)
	_sync_presentation(true)

func _restore_settings_focus() -> void:
	if is_instance_valid(shell) and shell.view.buttons.has("settings"):
		var button: Control = shell.view.buttons.settings
		if button.is_visible_in_tree(): button.grab_focus()


func bind_shell(host: Node) -> void:
	shell=host
	ui=UI.new();add_child(ui)
	ui.layer=shell.view.layer+1
	audio=Audio.new();add_child(audio)
	ui.settings_preview.connect(_preview)
	ui.settings_apply.connect(_save)
	ui.settings_cancel.connect(_cancel)
	ui.accessibility_changed.connect(_accessibility)
	shell.ui_cue_requested.connect(_ui_cue)
	shell.view.presentation_world_selected.connect(_select_presentation_world)
	_build_extra_controls()
	options=_saved_options();_draft_options=options.duplicate(true)
	_updating=true;ui.set_accessibility(options);_updating=false
	_apply_values(shell.progress.settings);_route_options(options)
	shell_state_changed()

func _saved_options() -> Dictionary:
	var result: Dictionary=OPTIONS.duplicate()
	var value: Variant=shell.progress.settings.get("game_feel",{})
	if value is Dictionary and _valid_options(value): result.merge(value,true)
	return result

func _valid_options(value: Dictionary) -> bool:
	if value.is_empty(): return true
	if value.get("version")!=1: return false
	for key in ["reduced_motion","contrast","input_hints"]:
		if not value.get(key) is bool: return false
	var strength: Variant=value.get("hint_strength")
	# JSON stores numbers as float; validate semantic integers rather than Array.has type identity.
	return (strength is int or strength is float) and is_finite(float(strength)) and float(strength)>=0 and float(strength)<=2 and float(strength)==floorf(float(strength))

func _build_extra_controls() -> void:
	var fields: Node=ui.settings_scroll.get_child(0)
	for pair in [["contrast","增强文字对比"],["input_hints","键盘 / 鼠标操作提示"]]:
		var control=Check.new();control.text=pair[1];control.custom_minimum_size=Vector2(0,44)
		fields.add_child(control);extra_controls[pair[0]]=control
		ui.focus_order.insert(ui.focus_order.size()-2,control)
		control.toggled.connect(_extra_changed)
	for index in ui.focus_order.size():
		var control: Control=ui.focus_order[index]
		control.focus_next=control.get_path_to(ui.focus_order[(index+1)%ui.focus_order.size()])
		control.focus_previous=control.get_path_to(ui.focus_order[posmod(index-1,ui.focus_order.size())])
		control.focus_neighbor_bottom=control.focus_next;control.focus_neighbor_top=control.focus_previous
	var notice:=Tokens.label("减少动态用于界面、坠落与边缘反馈。\n连接准备提示暂不可用。",16)
	ui.settings_panel.get_child(0).get_child(0).add_child(notice)
	lab_entry=Row.new();lab_entry.display_text="错视实验";lab_entry.configure(0.5)
	lab_entry.theme=Tokens.theme()
	lab_entry.custom_minimum_size=Vector2(220,56)
	ui.add_child(lab_entry)
	lab_entry.pressed.connect(launch_lab.bind("a"))
	get_viewport().size_changed.connect(_layout_entry)
	_layout_entry()

func _layout_entry() -> void:
	var area:=get_viewport().get_visible_rect().size
	lab_entry.position=Vector2(area.x-244,area.y-80)
	lab_entry.size=Vector2(220,56)
	_fit_ui.call_deferred()

func _fit_ui() -> void:
	if _closing: return
	# Reuse07 layout after the shared Window/containers have settled, not during its resize callback.
	ui.call("_layout")

func _apply_values(values: Dictionary) -> void:
	audio.apply_settings(values)
	Settings.apply(values,get_window())
	var level: Node = shell.adapter.level
	if level != null and level.has_method("apply_settings"):
		level.apply_settings(values)

func open_settings() -> void:
	if shell.settings_open: return
	if shell.state==Shell.State.PLAYING: shell.pause_game()
	shell.settings_open=true
	shell.preview_settings=shell.progress.settings.duplicate(true)
	_draft_options=_saved_options()
	_updating=true
	ui.set_accessibility(_draft_options)
	for key in extra_controls: extra_controls[key].button_pressed=_draft_options[key]
	_updating=false
	ui.open_settings(shell.progress.settings)
	ui._root.mouse_filter=Control.MOUSE_FILTER_STOP
	lab_entry.hide();ui.feedback_panel.hide()
	_sync_presentation(true)
	_fit_ui.call_deferred()

func _preview(values: Dictionary) -> void:
	if _closing or not shell.settings_open: return
	for key in values: shell.preview_settings[key]=values[key]
	_apply_values(values)
	_fit_ui.call_deferred()

func _accessibility(value: Dictionary) -> void:
	if _updating or _closing or not shell.settings_open: return
	for key in ["reduced_motion","hint_strength"]: _draft_options[key]=value[key]
	_route_options(_draft_options)

func _extra_changed(_value: bool) -> void:
	if _updating or not shell.settings_open: return
	for key in extra_controls: _draft_options[key]=extra_controls[key].button_pressed
	_route_options(_draft_options)

func _save(values: Dictionary) -> void:
	if _closing or not shell.settings_open: return
	var prior: Variant=shell.progress.settings.get("game_feel",{})
	if not prior is Dictionary or not _valid_options(prior):
		_apply_values(shell.progress.settings);_route_options(_saved_options())
		ui.settings_failed("辅助设置来自更新版本或无效，原配置已保留。")
		return
	var candidate: Dictionary=shell.progress.duplicate(true)
	for key in values: candidate.settings[key]=values[key]
	candidate.settings.game_feel=_draft_options.duplicate(true)
	if not shell.store.save(candidate):
		_apply_values(shell.progress.settings);_route_options(_saved_options())
		ui.settings_failed(shell.store.last_error)
		return
	shell.progress=candidate;shell.dirty=false
	_apply_values(candidate.settings);_route_options(_draft_options)
	ui.settings_applied(values)
	shell.settings_open=false
	ui._root.mouse_filter=Control.MOUSE_FILTER_IGNORE
	shell._render_state();shell_state_changed()
	_restore_settings_focus.call_deferred()

func _cancel() -> void:
	if _closing: return
	_apply_values(shell.progress.settings);_route_options(_saved_options())
	shell.settings_open=false
	ui._root.mouse_filter=Control.MOUSE_FILTER_IGNORE
	shell._render_state();shell_state_changed()
	_restore_settings_focus.call_deferred()

func _route_options(value: Dictionary) -> void:
	options=value.duplicate(true)
	var level: Node=shell.adapter.level
	if level != null and level.has_method("apply_accessibility"):
		level.apply_accessibility(options)
	if level!=null and level.has_method("get_game_feel_runtime"):
		level.presenter.set_reduced_motion(options.reduced_motion)
	_sync_presentation(true)
	ui.input_label.visible=options.input_hints and options.hint_strength>0 and not ui.input_label.text.is_empty()

func launch_lab(letter: String) -> void:
	if shell.settings_open: return
	shell._leave_level()
	lab_active=true
	shell.adapter.enter({"scene":"res://game/shell/game_feel_lab.tscn","adapter":""})
	if letter!="a": shell.adapter.level.load_map(letter)
	shell.current_id=""
	shell._set_state(Shell.State.PLAYING);shell._render_state();shell_state_changed()

func leave_level() -> void:
	if ui and ui.settings_open: ui.cancel_settings()
	_bind_runtime(null)
	_bind_legacy(null)
	lab_active=false
	if audio: audio.clear()

func shell_state_changed() -> void:
	if _closing: return
	var level: Node=shell.adapter.level
	var source: Object=level.get_game_feel_runtime() if level!=null and level.has_method("get_game_feel_runtime") else null
	if level != null and level.has_method("apply_settings"):
		level.apply_settings(shell.progress.settings)
	if level != null and level.has_method("apply_accessibility"):
		level.apply_accessibility(options)
	_bind_runtime(source)
	_bind_legacy(level if source==null else null)
	var paused: bool=shell.state==Shell.State.PAUSED
	if source: level.set_host_paused(paused)
	audio.set_paused(paused)
	if source:
		if _goal_scope!=_scope: audio.set_music("exploration",source.get_state().player.location.layer)
		_route_options(options)
	elif shell.state in [Shell.State.MAIN_MENU,Shell.State.LEVEL_SELECT]: audio.set_music("menu")
	elif _legacy_level!=null: _sync_legacy_music()
	else: audio.set_music("none")
	lab_entry.visible=shell.state==Shell.State.MAIN_MENU and not shell.settings_open
	ui.feedback_panel.visible=not paused and not shell.settings_open and not ui.status_label.text.is_empty()
	_sync_presentation(true)

func _bind_legacy(level: Node) -> void:
	if level==_legacy_level: return
	if is_instance_valid(_legacy_level):
		if _legacy_reset_callback.is_valid() and _legacy_level.controls.reset_requested.is_connected(_legacy_reset_callback):
			_legacy_level.controls.reset_requested.disconnect(_legacy_reset_callback)
		audio.clear()
	if is_instance_valid(_legacy_audio):
		if _legacy_callback.is_valid() and _legacy_audio.cue_played.is_connected(_legacy_callback):
			_legacy_audio.cue_played.disconnect(_legacy_callback)
		for player in _legacy_audio.ambience: player.stream_paused=false
	_legacy_level=null;_legacy_audio=null;_legacy_callback=Callable();_legacy_reset_callback=Callable()
	if level==null: return
	var has_polish:=false
	for property in level.get_property_list():
		if property.name=="polish": has_polish=true
	if not has_polish: return
	var local_audio: Node=level.polish.audio
	if local_audio.get_script().resource_path!="res://game/polish/p01_audio.gd": return
	_legacy_level=level;_legacy_audio=local_audio
	_legacy_callback=_legacy_cue.bind(level,epoch)
	local_audio.cue_played.connect(_legacy_callback)
	_legacy_reset_callback=prepare_reset
	level.controls.reset_requested.connect(_legacy_reset_callback)
	_sync_legacy_music()

func _sync_legacy_music() -> void:
	if not is_instance_valid(_legacy_level): return
	# Existing native Movement/Graph remain authoritative; no eligibility inference.
	if not _legacy_level.graph.complete: audio.set_music("exploration",_legacy_level.mover.world)
	# The accepted ambience remains loaded; only11 owns exploration music playback.
	for player in _legacy_audio.ambience: player.stream_paused=true

func _legacy_cue(cue: String, level: Node, captured_epoch: int) -> void:
	if _closing or level!=_legacy_level or captured_epoch!=epoch: return
	# Shell completion is already the single Goal audio authority for these levels.
	if cue=="complete":
		_legacy_audio.players[cue].stop()
		return
	var translated: String={"roll":"cube_roll","land":"cube_contact","shift_inner":"world_shift","shift_surface":"world_shift","link_on":"perspective_connect","link_off":"perspective_disconnect"}.get(cue,"")
	if translated.is_empty(): return
	_cue_sequence+=1
	audio.play_ui(translated,"legacy:%d:%d"%[epoch,_cue_sequence])
	# Route one voice for these cues; other accepted local mechanism sounds stay intact.
	_legacy_audio.players[cue].stop()

func prepare_reset() -> void:
	if runtime!=null:
		_cancel_runtime_audio()
		audio.set_music("exploration",runtime.get_state().player.location.layer)
	else: audio.clear()
	_goal_scope={}

func _cancel_runtime_audio() -> void:
	# Owner clear() retires a complete run. Reset advances generation within that
	# same run, so cancel captured identities rather than retire future events.
	for identity in _audio_identities.values(): audio.cancel(identity)
	_audio_identities.clear()
	_last_audio_identity={}

func _bind_runtime(source: Object) -> void:
	if source==runtime:
		_sync_scope();return
	if runtime!=null and _event_callback.is_valid() and runtime.game_feel_event.is_connected(_event_callback): runtime.game_feel_event.disconnect(_event_callback)
	if runtime!=null and _commit_callback.is_valid() and runtime.committed.is_connected(_commit_callback): runtime.committed.disconnect(_commit_callback)
	_event_callback=Callable()
	_commit_callback=Callable()
	_cancel_runtime_audio()
	epoch+=1;runtime=source;_scope={};_goal_scope={};ui.bind_context("","")
	if source:
		_event_callback=forward_event.bind(source,epoch)
		source.game_feel_event.connect(_event_callback)
		_commit_callback=_runtime_committed.bind(source,epoch)
		source.committed.connect(_commit_callback)
		_sync_scope()

func _runtime_committed(_state: Dictionary, source: Object, captured_epoch: int) -> void:
	if _closing or source!=runtime or captured_epoch!=epoch: return
	_sync_scope()
	_sync_goal()

func _sync_scope() -> void:
	if runtime==null: return
	var next: Dictionary=runtime.get_presentation_scope()
	if next!=_scope:
		_scope=next.duplicate(true)
		_goal_scope={}
		_cancel_runtime_audio()
		audio.set_music("exploration",runtime.get_state().player.location.layer)
		ui.bind_context("","") #07 scopes session/run;00 additionally owns generation changes.
		ui.bind_context(str(next.session_id),str(next.level_run_id))
		ui.set_authored_hint("WASD / 方向键：移动   F：尝试坠落\nQ / E：视角   R：重置   Esc：暂停","")
		_route_options(options)

func forward_event(event: Dictionary,source: Object,captured_epoch: int) -> void:
	if _closing or source!=runtime or captured_epoch!=epoch: return
	# Native Reset advances generation before emitting interruption of the captured old motion.
	# Consume only the matching bound old scope, then sync the new authoritative scope.
	var interrupted: Variant=event.get("presentation_identity")
	if event.get("semantic")=="ANIMATION_INTERRUPTED" and interrupted is Dictionary:
		if interrupted.get("session_id")==_scope.get("session_id") and interrupted.get("level_run_id")==_scope.get("level_run_id") and interrupted.get("generation")==_scope.get("generation"):
			ui.consume_event(event);audio.consume_event(event)
		_sync_scope();return
	_sync_scope()
	if event.get("session_id")!=_scope.get("session_id") or event.get("level_run_id")!=_scope.get("level_run_id"): return
	var identity: Variant=event.get("presentation_identity")
	if identity is Dictionary and identity.get("generation")!=_scope.get("generation"): return
	if identity is Dictionary and event.get("semantic") in ["MOVE_APPLIED_NORMAL","PERSPECTIVE_FALL_APPLIED","MOVE_REJECTED_EDGE"]:
		_audio_identities[JSON.stringify(identity)]=identity.duplicate(true)
		if event.get("semantic")=="MOVE_APPLIED_NORMAL": _last_audio_identity=identity.duplicate(true)
	ui.consume_event(event);audio.consume_event(event);_route_options(options)
	if ui.settings_open: ui.feedback_panel.hide()

func _ui_cue(cue: String) -> void:
	_cue_sequence+=1;audio.play_ui(cue,"shell:%d:%d"%[epoch,_cue_sequence])

func _process(_delta: float) -> void:
	_sync_presentation()
	if runtime!=null:
		_sync_scope()
		_sync_goal()
	if _legacy_level!=null: _sync_legacy_music()

func _sync_goal() -> void:
	if _goal_scope==_scope or shell.state!=Shell.State.PLAYING or _last_audio_identity.is_empty(): return
	var goal: Dictionary=Goal.is_goal(runtime.get_level(),runtime.get_state())
	if not goal.ok or not goal.is_goal: return
	_goal_scope=_scope.duplicate(true)
	audio.play_ui("goal",_last_audio_identity.duplicate(true))
	ui.set_authored_hint("实验完成：按 R 重置，或用 A / B 切换实验地图。","")
	_route_options(options)

func _exit_tree() -> void:
	_closing=true
	_bind_legacy(null)
	if runtime!=null and _event_callback.is_valid() and runtime.game_feel_event.is_connected(_event_callback): runtime.game_feel_event.disconnect(_event_callback)
	if runtime!=null and _commit_callback.is_valid() and runtime.committed.is_connected(_commit_callback): runtime.committed.disconnect(_commit_callback)
	_commit_callback=Callable()
	_event_callback=Callable();runtime=null
	epoch+=1
	if audio: audio.clear()
