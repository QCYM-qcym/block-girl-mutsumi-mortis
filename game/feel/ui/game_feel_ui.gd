extends CanvasLayer
## Independent experimental UI. The 00 host owns persistence, Audio and Presenter routing.
signal settings_preview(values: Dictionary)
signal settings_apply(values: Dictionary)
signal settings_cancel()
signal accessibility_changed(options: Dictionary)

const Tokens = preload("res://game/shell/visual_01/tokens.gd")
const Row = preload("res://game/feel/ui/motion_row.gd")
const StoneSlider = preload("res://game/shell/visual_01/stone_slider.gd")
const Check = preload("res://game/shell/visual_01/stone_check.gd")
const SETTINGS_KEYS := ["master", "music", "sfx", "fullscreen", "muted"]
const DEFAULTS := {"master":1.0,"music":1.0,"sfx":1.0,"fullscreen":false,"muted":false}
var sliders: Dictionary = {}
var buttons: Dictionary = {}
var focus_order: Array[Control] = []
var settings_open := false
var error_label: Label
var feedback_panel: PanelContainer
var status_label: Label
var detail_label: Label
var input_label: Label
var settings_panel: PanelContainer
var settings_scroll: ScrollContainer
var _root: Control
var _draft: Dictionary = DEFAULTS.duplicate()
var _saved: Dictionary = DEFAULTS.duplicate()
var _options := {"reduced_motion":false,"hint_strength":1}
var _saved_options: Dictionary
var _updating := false
var _applying := false
var _return_focus: Control
var _session := ""
var _run := ""
var _last_event := -1
var _active_identity: Dictionary = {}
var _active_contract_version := ""
var _hint := ""
var _key_hint := ""
var _mechanism_hint := false

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	layer = 40
	_root = Control.new()
	_root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_root.theme = Tokens.theme()
	add_child(_root)
	feedback_panel = PanelContainer.new()
	feedback_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	feedback_panel.add_theme_stylebox_override("panel", Tokens.flat(Tokens.COLORS.face, true))
	_root.add_child(feedback_panel)
	var feedback := VBoxContainer.new()
	feedback.mouse_filter = Control.MOUSE_FILTER_IGNORE
	feedback_panel.add_child(feedback)
	status_label = Tokens.label("",22)
	detail_label = Tokens.label("",18)
	input_label = Tokens.label("",18)
	for label in [status_label, detail_label, input_label]: feedback.add_child(label)
	feedback_panel.hide()
	_build_settings()
	get_viewport().size_changed.connect(_layout)
	_layout()

func _build_settings() -> void:
	settings_panel = PanelContainer.new()
	settings_panel.add_theme_stylebox_override("panel", Tokens.flat(Tokens.COLORS.face,true))
	_root.add_child(settings_panel)
	var margin := MarginContainer.new()
	for side in ["left","top","right","bottom"]: margin.add_theme_constant_override("margin_"+side,24)
	settings_panel.add_child(margin)
	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation",12)
	margin.add_child(column)
	var title := Tokens.label("设置",32,true)
	title.autowrap_mode = TextServer.AUTOWRAP_OFF
	column.add_child(title)
	settings_scroll = ScrollContainer.new()
	settings_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	settings_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	settings_scroll.follow_focus = true
	column.add_child(settings_scroll)
	var fields := VBoxContainer.new()
	fields.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	fields.add_theme_constant_override("separation",16)
	settings_scroll.add_child(fields)
	for pair in [["master","总音量"],["music","音乐音量"],["sfx","音效音量"],["hint_strength","提示强度 · 最少 / 情境 / 加强"]]:
		var group := VBoxContainer.new()
		fields.add_child(group)
		var caption := Tokens.label(pair[1],20)
		caption.autowrap_mode = TextServer.AUTOWRAP_OFF
		group.add_child(caption)
		var slider := StoneSlider.new()
		slider.min_value = 0
		slider.max_value = 2 if pair[0] == "hint_strength" else 100
		slider.step = 1
		slider.custom_minimum_size = Vector2(0,32)
		group.add_child(slider)
		sliders[pair[0]] = slider
		focus_order.append(slider)
		slider.focus_entered.connect(func(): settings_scroll.ensure_control_visible(group))
		slider.value_changed.connect(_controls_changed)
	for pair in [["muted","静音"],["fullscreen","全屏"],["reduced_motion","减少动态效果"]]:
		var control := Check.new()
		control.text = pair[1]
		control.custom_minimum_size = Vector2(0,44)
		fields.add_child(control)
		buttons[pair[0]] = control
		focus_order.append(control)
		control.toggled.connect(_controls_changed)
	error_label = Tokens.label("",18)
	column.add_child(error_label)
	var input_help := Tokens.label("Tab 切换 · ← → 调整 · Enter 确认 · Esc 取消\n鼠标拖动滑块；加强提示仅显示已有提示。",16)
	input_help.autowrap_mode = TextServer.AUTOWRAP_OFF
	column.add_child(input_help)
	for pair in [["apply","应用"],["cancel","取消"]]:
		var row := Row.new()
		row.display_text = pair[1]
		row.custom_minimum_size = Vector2(0,44)
		row.configure(0.7)
		column.add_child(row)
		buttons[pair[0]] = row
		focus_order.append(row)
	buttons.apply.pressed.connect(_request_apply)
	buttons.cancel.pressed.connect(cancel_settings)
	for index in focus_order.size():
		var control := focus_order[index]
		var next := focus_order[(index+1)%focus_order.size()].get_path()
		var previous := focus_order[posmod(index-1,focus_order.size())].get_path()
		control.focus_next = next
		control.focus_previous = previous
		control.focus_neighbor_bottom = next
		control.focus_neighbor_top = previous
	settings_panel.hide()

func _layout() -> void:
	var area := get_viewport().get_visible_rect().size
	var width := minf(620,area.x-48)
	settings_panel.position = Vector2((area.x-width)/2,24)
	settings_panel.size = Vector2(width,area.y-48)
	feedback_panel.position = Vector2(24,24)
	feedback_panel.size = Vector2(minf(440,area.x-48),0)

func _values(values: Dictionary) -> Dictionary:
	var result: Dictionary = DEFAULTS.duplicate()
	for key in SETTINGS_KEYS:
		if values.has(key): result[key] = values[key]
	for key in ["master","music","sfx"]: result[key] = clampf(float(result[key]),0,1)
	return result

func open_settings(values: Dictionary) -> void:
	if settings_open: return
	_return_focus = get_viewport().gui_get_focus_owner()
	_saved = _values(values)
	_draft = _saved.duplicate(true)
	_saved_options = _options.duplicate(true)
	settings_open = true
	_applying = false
	error_label.text = ""
	error_label.hide()
	_sync_controls()
	settings_panel.show()
	sliders.master.grab_focus()
	settings_scroll.scroll_vertical = 0

func _sync_controls() -> void:
	_updating = true
	for key in ["master","music","sfx"]: sliders[key].value = _draft[key]*100
	for key in ["muted","fullscreen"]: buttons[key].button_pressed = _draft[key]
	buttons.reduced_motion.button_pressed = _options.reduced_motion
	sliders.hint_strength.value = _options.hint_strength
	_updating = false
	_update_motion()

func _controls_changed(_unused: Variant) -> void:
	if _updating or not settings_open or _applying: return
	for key in ["master","music","sfx"]: _draft[key] = sliders[key].value/100.0
	for key in ["muted","fullscreen"]: _draft[key] = buttons[key].button_pressed
	set_accessibility({"reduced_motion":buttons.reduced_motion.button_pressed,"hint_strength":int(sliders.hint_strength.value)})
	settings_preview.emit(_draft.duplicate(true))

func _request_apply() -> void:
	if not settings_open or _applying: return
	_applying = true
	_set_editable(false)
	error_label.text = "正在保存…"
	error_label.show()
	settings_apply.emit(_draft.duplicate(true))

func settings_applied(values: Dictionary) -> void:
	if not settings_open or not _applying: return
	_saved = _values(values)
	_saved_options = _options.duplicate(true)
	_close_settings()

func settings_failed(message: String) -> void:
	if not settings_open: return
	_applying = false
	_sync_controls()
	_set_editable(true)
	error_label.text = message
	error_label.show()
	buttons.apply.grab_focus()

func _set_editable(enabled: bool) -> void:
	for slider in sliders.values(): slider.editable = enabled
	for button in buttons.values(): button.disabled = not enabled

func cancel_settings() -> void:
	if not settings_open or _applying: return
	_draft = _saved.duplicate(true)
	set_accessibility(_saved_options)
	settings_preview.emit(_saved.duplicate(true))
	settings_cancel.emit()
	_close_settings()

func _close_settings() -> void:
	settings_open = false
	_applying = false
	_set_editable(true)
	settings_panel.hide()
	if is_instance_valid(_return_focus) and _return_focus.is_visible_in_tree(): _return_focus.grab_focus()
	else:
		var focused := get_viewport().gui_get_focus_owner()
		if focused: focused.release_focus()

func _unhandled_key_input(event: InputEvent) -> void:
	if settings_open and event is InputEventKey and event.pressed and not event.echo and event.keycode == KEY_ESCAPE:
		cancel_settings()
		get_viewport().set_input_as_handled()

func set_accessibility(options: Dictionary) -> void:
	_options = {"reduced_motion":bool(options.get("reduced_motion",false)),"hint_strength":clampi(int(options.get("hint_strength",1)),0,2)}
	_update_motion()
	_update_details()
	accessibility_changed.emit(_options.duplicate(true))

func _update_motion() -> void:
	for key in ["apply","cancel"]:
		if buttons.has(key): buttons[key].set_reduced_motion(_options.reduced_motion)

func set_authored_hint(key_hint: String, optional_hint: String) -> void:
	_key_hint = key_hint
	_hint = optional_hint
	_update_details()

func _update_details() -> void:
	if not is_instance_valid(detail_label): return
	detail_label.text = _hint
	detail_label.visible = _options.hint_strength == 2 and not _hint.is_empty()
	input_label.text = _key_hint
	input_label.visible = _options.hint_strength > 0 and not _key_hint.is_empty()
	if _mechanism_hint and (_options.hint_strength < 2 or _hint.is_empty()): _clear_feedback()

func bind_context(session_id: String, level_run_id: String) -> void:
	if _session == session_id and _run == level_run_id: return
	_session = session_id
	_run = level_run_id
	_last_event = -1
	_clear_feedback()
	set_authored_hint("", "")

func _clear_feedback() -> void:
	_active_identity = {}
	_active_contract_version = ""
	_mechanism_hint = false
	feedback_panel.hide()
	status_label.text = ""

func consume_event(event: Dictionary) -> void:
	# Only the versioned authoritative event port can start feedback. No geometry or key inference.
	if not _supported_event(event): return
	if _session.is_empty() or event.get("session_id") != _session or event.get("level_run_id") != _run: return
	if not event.get("event_id") is int or event.event_id <= _last_event: return
	_last_event = event.event_id
	var identity: Variant = event.get("presentation_identity")
	var semantic: String = event.get("semantic","")
	var phase: String = event.get("phase","")
	if semantic == "MOVE_APPLIED_NORMAL" and phase == "STARTED" and _mechanism_hint:
		_clear_feedback()
		return
	if phase in ["COMMITTED","INTERRUPTED"]:
		if identity is Dictionary and not _active_identity.is_empty() and identity == _active_identity and event.contract_version == _active_contract_version: _clear_feedback()
		return
	if semantic == "PERSPECTIVE_FALL_APPLIED" and phase == "STARTED" and event.get("reason_category") == "NONE":
		if not identity is Dictionary or not _valid_identity(identity): return
		var result: Variant = event.get("result")
		if not result is Dictionary or result.get("status") != 0 or not _has_safe_verdict(event.get("safety_verdict")) or not event.get("target_pose") is Dictionary: return
		_active_identity = identity.duplicate(true)
		_active_contract_version = event.contract_version
		_mechanism_hint = false
		status_label.text = "错视坠落中 · 操作暂锁"
		_update_details()
		feedback_panel.show()
	elif semantic == "ACTION_FEEDBACK" and phase == "FEEDBACK" and event.get("reason_category") == "MECHANISM_LOCKED" and _active_identity.is_empty():
		if _options.hint_strength == 2 and not _hint.is_empty():
			_mechanism_hint = true
			status_label.text = "机制尚未开放"
			_update_details()
			feedback_panel.show()
	# Typed EDGE, Busy, invalid/safety/unknown rejections never become blocked-road popups.

func _supported_event(event: Dictionary) -> bool:
	var schema: Variant = event.get("schema_version")
	var contract: Variant = event.get("contract_version")
	if not schema is int or not contract is String: return false
	if schema == 1 and contract == "game_feel.event.v1": return true
	if schema != 2 or contract != "game_feel.event.v2": return false
	var semantic: Variant = event.get("semantic")
	var phase: Variant = event.get("phase")
	if not semantic is String or not phase is String: return false
	if semantic == "ANIMATION_INTERRUPTED": return phase == "INTERRUPTED"
	if semantic != "PERSPECTIVE_FALL_APPLIED" or phase not in ["STARTED","COMMITTED"]: return false
	if phase == "COMMITTED": return true
	# Read only the known trajectory envelope;01 owns its geometry, validity and Safety proof.
	var trajectory: Variant = event.get("authorized_trajectory")
	if not trajectory is Dictionary: return false
	var version: Variant = trajectory.get("trajectory_version")
	return version is String and version == "pfall.departure_cubic.v1"

func _valid_identity(identity: Dictionary) -> bool:
	return identity.size() == 4 and identity.get("session_id") == _session and identity.get("level_run_id") == _run and identity.get("generation") is int and identity.get("attempt_id") is int

func _has_safe_verdict(verdict: Variant) -> bool:
	#01 owns Safety truth; the UI only reads its structured status and opaque evidence reference.
	if not verdict is Dictionary: return false
	var status: Variant = verdict.get("status")
	if not status is String or status != "SAFE": return false
	var issues: Variant = verdict.get("issues")
	var evidence_ref: Variant = verdict.get("evidence_ref")
	return issues is Array and issues.is_empty() and evidence_ref is Dictionary and not evidence_ref.is_empty()
