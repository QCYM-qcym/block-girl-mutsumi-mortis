extends SceneTree
const MAIN := "res://experiments/spatial_puzzle_batch_01/ui/main.tscn"
const Factory = preload("res://experiments/spatial_puzzle_batch_01/maps/map_factory.gd")
const Store = preload("res://game/shell/save_store.gd")
const StateKey = preload("res://foundation/contracts/state_key.gd")
var phase := ""
var evidence := ""
var prior_report := ""
var save_root := ""
var save_path := ""
var checks := 0
var failures: Array[String] = []
var rows: Array[Dictionary] = []
var loop: Dictionary = {}
var ui

func _initialize() -> void:
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--phase="): phase = arg.trim_prefix("--phase=")
		elif arg.begins_with("--evidence-dir="): evidence = arg.trim_prefix("--evidence-dir=")
		elif arg.begins_with("--save-root="): save_root = arg.trim_prefix("--save-root=")
		elif arg.begins_with("--prior-report="): prior_report = arg.trim_prefix("--prior-report=")
	save_path = save_root.path_join("mechanisms.json" if phase == "mechanisms" else "loop.json")
	call_deferred("run")

func run() -> void:
	check(false,"case must implement run")
	await finish()

func check(ok: bool, label: String) -> void:
	checks += 1
	if not ok:
		failures.append(label)
		printerr("FAIL: ",label)

func setup() -> bool:
	check(DisplayServer.get_name() == "headless" and save_root.begins_with("user://spatial_puzzle_batch_01/tests/") and ".." not in save_root, "actual headless process with isolated test save")
	check(phase in ["mechanisms","loop_seed","loop_restore"] and not evidence.is_empty() and ResourceLoader.exists(MAIN), "actual Menu and known phase available")
	if not failures.is_empty(): return false
	root.content_scale_size = Vector2i.ZERO
	root.content_scale_mode = Window.CONTENT_SCALE_MODE_DISABLED
	root.size = Vector2i(960,720)
	ui = load(MAIN).instantiate()
	ui.save_path = save_path
	root.add_child(ui)
	await settle()
	check(ui.menu_panel.visible and ui.lab == null, "actual Menu loads without automatically starting a lab")
	return failures.is_empty()

func settle() -> void:
	for frame in 6: await process_frame

func key(code: int) -> void:
	for pressed in [true,false]:
		var event := InputEventKey.new()
		event.keycode = code; event.physical_keycode = code; event.pressed = pressed
		Input.parse_input_event(event)
		await process_frame
	await settle()

func click(control: Control) -> void:
	var point := control.get_global_rect().get_center()
	var motion := InputEventMouseMotion.new()
	motion.position = point; motion.global_position = point
	Input.parse_input_event(motion)
	await process_frame
	for pressed in [true,false]:
		var event := InputEventMouseButton.new()
		event.position = point; event.global_position = point
		event.button_index = MOUSE_BUTTON_LEFT; event.pressed = pressed
		Input.parse_input_event(event)
		await process_frame
	await settle()

func choose(id: StringName) -> bool:
	ui.menu_scroll.ensure_control_visible(ui.entries[id])
	await settle()
	await click(ui.entries[id])
	check(is_instance_valid(ui.lab) and ui.lab.runtime.is_loaded() and ui.lab.host_issues.is_empty(), "actual Factory/Baker/Host loads: "+String(id))
	if not is_instance_valid(ui.lab): return false
	check(root.gui_get_focus_owner() == null and not ui.lab._hint_visible, "gameplay releases focus and advanced Hint defaults off: "+String(id))
	return ui.lab.runtime.is_loaded()

func state_key(host) -> String:
	var built: Dictionary = StateKey.build(host.runtime.get_level(),host.runtime.get_state())
	check(built.ok,"actual formal StateKey is valid")
	return built.key

func wait_idle(host) -> void:
	var until := Time.get_ticks_msec()+4000
	while Time.get_ticks_msec()<until and (not host.runtime.is_idle() or host.presenter.snapshot().phase != "IDLE"):
		await process_frame
	check(host.runtime.is_idle() and host.presenter.snapshot().phase == "IDLE", "actual Host completes native motion naturally without finish injection")
	await settle()

func apply(host, action: Dictionary, label: String) -> Dictionary:
	var result: Dictionary = host.runtime.request_action(action)
	check(result.status == 0 and result.changed,label+": actual formal action accepted")
	await wait_idle(host)
	check(result.next_state != null and host.runtime.get_state() == result.next_state,label+": authoritative next_state committed")
	rows.append({"case":label,"input":"actual Facade action API","result":result,"state_key":state_key(host),"commits":host.runtime.get_commit_count()})
	return result

func latest_event(host, first: int, kind: int) -> Dictionary:
	for index in range(first,host.events.size()):
		var event: Dictionary = host.events[index]
		if event.result.action.get("kind") == kind: return event.duplicate(true)
	check(false,"native input produces an actual formal event")
	return {}

func markers(host, kind: String) -> Array[Dictionary]:
	var found: Array[Dictionary] = []
	var parent: Node = host.geometry_root.get_node_or_null("ActionMarkers")
	if parent == null: return found
	for marker in parent.get_children():
		if marker.get_meta("kind","") != kind: continue
		for child in marker.get_children():
			if child is Label3D: found.append({"face":String(marker.get_meta("face_id")),"text":child.text,"color":child.modulate.to_html()})
	return found

func rejection(host, code: int, kind: int, expected: int, reason: String, message: String, label: String) -> void:
	var before := state_key(host)
	var commits: int = host.runtime.get_commit_count()
	var first: int = host.events.size()
	await key(code)
	var event := latest_event(host,first,kind)
	if event.is_empty(): return
	check(event.result.status == 1 and event.result.rejection_code == expected and not event.result.changed and event.result.next_state == null,label+": formal rejection code and no candidate commit")
	check(event.reason_category == reason and message in host.status.text,label+": formal reason reaches actual HUD text")
	check(state_key(host) == before and host.runtime.get_commit_count() == commits,label+": rejection preserves full formal state and commit count")
	rows.append({"case":label,"input":"native Input.parse_input_event","event":event,"hud":host.status.text,"state_key":before,"commits":commits})

func return_menu() -> void:
	var old_runtime = ui.lab.runtime
	await click(ui.return_button)
	check(ui.lab == null and ui.menu_panel.visible and not old_runtime.is_loaded(), "native return unloads the actual Host and exposes Menu")

func finish() -> void:
	var report := {"phase":phase,"checks":checks,"failures":failures,"rows":rows,"loop":loop,"pid":OS.get_process_id(),"user_data_dir":OS.get_user_data_dir(),"save_path":save_path,"display":DisplayServer.get_name(),"engine":Engine.get_version_info(),"doubles":[],"authority":"actual Menu/Factory/Baker/Host/Facade/StateKey/original SaveStore and natural Presenter; no positive event or finish injection","graphical":"NOT_RUN","human_qa":"NOT_RUN","scope":"pre-migration baseline feedback and actual process-level Continue; final migrated integration is PENDING_00"}
	DirAccess.make_dir_recursive_absolute(evidence)
	var file := FileAccess.open(evidence.path_join("report.json"),FileAccess.WRITE)
	file.store_string(JSON.stringify(report,"\t")); file.close()
	if is_instance_valid(ui): ui.queue_free()
	await settle()
	await create_timer(0.15).timeout
	print(JSON.stringify(report))
	quit(0 if failures.is_empty() else 1)
