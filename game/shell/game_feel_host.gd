extends Node
## Shared routing/persistence only; Owner modules retain their algorithms.
const UI = preload("res://game/feel/ui/game_feel_ui.gd")
const Audio = preload("res://game/feel/audio/audio_director.gd")
const Settings = preload("res://game/shell/settings.gd")
const Shell = preload("res://game/shell/game_shell.gd")
const Tokens = preload("res://game/shell/visual_01/tokens.gd")
const Check = preload("res://game/shell/visual_01/stone_check.gd")
const Row = preload("res://game/shell/visual_01/stone_row.gd")
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
var _draft_options: Dictionary={}
var _scope: Dictionary={}
var _updating := false
var _closing := false
var _cue_sequence := 0

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
	var notice:=Tokens.label("减少动态用于界面与下一次坠落。\n边缘反馈尚未启用；连接准备提示暂不可用。",16)
	ui.settings_panel.get_child(0).get_child(0).add_child(notice)
	lab_entry=Row.new();lab_entry.display_text="错视实验";lab_entry.configure(0.5)
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

func _cancel() -> void:
	if _closing: return
	_apply_values(shell.progress.settings);_route_options(_saved_options())
	shell.settings_open=false
	ui._root.mouse_filter=Control.MOUSE_FILTER_IGNORE
	shell._render_state();shell_state_changed()

func _route_options(value: Dictionary) -> void:
	options=value.duplicate(true)
	var level: Node=shell.adapter.level
	if level!=null and level.has_method("get_game_feel_runtime"):
		level.presenter.set_reduced_motion(options.reduced_motion)
	for label in ui.find_children("*","Label",true,false):
		if options.contrast:
			label.add_theme_color_override("font_color",Color.WHITE)
			label.add_theme_color_override("font_outline_color",Color.BLACK)
			label.add_theme_constant_override("outline_size",2)
		else:
			label.remove_theme_color_override("font_color");label.remove_theme_color_override("font_outline_color");label.remove_theme_constant_override("outline_size")
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
	lab_active=false
	if audio: audio.clear()

func shell_state_changed() -> void:
	if _closing: return
	var level: Node=shell.adapter.level
	var source: Object=level.get_game_feel_runtime() if level!=null and level.has_method("get_game_feel_runtime") else null
	_bind_runtime(source)
	var paused: bool=shell.state==Shell.State.PAUSED
	if source: level.set_host_paused(paused)
	audio.set_paused(paused)
	if source:
		audio.set_music("exploration",source.get_state().player.location.layer)
		_route_options(options)
	elif shell.state in [Shell.State.MAIN_MENU,Shell.State.LEVEL_SELECT]: audio.set_music("menu")
	else: audio.set_music("none") # Original scenes retain verified local audio.
	lab_entry.visible=shell.state==Shell.State.MAIN_MENU and not shell.settings_open
	ui.feedback_panel.visible=not paused and not shell.settings_open and not ui.status_label.text.is_empty()

func _bind_runtime(source: Object) -> void:
	if source==runtime:
		_sync_scope();return
	if runtime!=null and _event_callback.is_valid() and runtime.game_feel_event.is_connected(_event_callback): runtime.game_feel_event.disconnect(_event_callback)
	epoch+=1;runtime=source;_scope={};ui.bind_context("","")
	if source:
		_event_callback=forward_event.bind(source,epoch)
		source.game_feel_event.connect(_event_callback)
		_sync_scope()

func _sync_scope() -> void:
	if runtime==null: return
	var next: Dictionary=runtime.get_presentation_scope()
	if next!=_scope:
		_scope=next.duplicate(true)
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
	ui.consume_event(event);audio.consume_event(event);_route_options(options)
	if ui.settings_open: ui.feedback_panel.hide()

func _ui_cue(cue: String) -> void:
	_cue_sequence+=1;audio.play_ui(cue,"shell:%d:%d"%[epoch,_cue_sequence])

func _process(_delta: float) -> void:
	if runtime!=null: _sync_scope()

func _exit_tree() -> void:
	_closing=true
	if runtime!=null and _event_callback.is_valid() and runtime.game_feel_event.is_connected(_event_callback): runtime.game_feel_event.disconnect(_event_callback)
	epoch+=1
	if audio: audio.clear()
