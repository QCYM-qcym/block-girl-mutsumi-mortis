extends SceneTree
const MAIN = preload("res://experiments/spatial_puzzle_batch_01/ui/main.tscn")
const StateKey = preload("res://foundation/contracts/state_key.gd")
const Goal = preload("res://foundation/rules/goal_evaluator.gd")
const Factory = preload("res://experiments/spatial_puzzle_batch_01/maps/map_factory.gd")
var ui
var evidence := ""
var checks := 0
var failures: Array[String] = []
var rows: Array[Dictionary] = []
var commits: Array[Dictionary] = []

func _initialize() -> void:
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--evidence-dir="): evidence = arg.trim_prefix("--evidence-dir=")
	call_deferred("run")

func check(value: bool, message: String) -> void:
	checks += 1
	if not value: failures.append(message); printerr("FAIL: ",message)

func settle() -> void:
	for frame in 4: await process_frame

func key(code: int, settled: bool = true) -> void:
	for pressed in [true,false]:
		var event := InputEventKey.new()
		event.keycode = code; event.physical_keycode = code; event.pressed = pressed
		Input.parse_input_event(event)
		await process_frame
	if settled: await settle()

func click(control: Control) -> void:
	var point := control.get_global_rect().get_center()
	for pressed in [true,false]:
		var event := InputEventMouseButton.new()
		event.position = point; event.global_position = point
		event.button_index = MOUSE_BUTTON_LEFT; event.pressed = pressed
		Input.parse_input_event(event)
		await process_frame
	await settle()

func idle(host) -> void:
	var deadline := Time.get_ticks_msec()+5000
	while Time.get_ticks_msec()<deadline and (not host.runtime.is_idle() or host.presenter.snapshot().phase != "IDLE"):
		await process_frame
	check(host.runtime.is_idle() and host.presenter.snapshot().phase == "IDLE","natural native motion settles, no manual positive finish")
	await settle()

func state_key(host) -> String:
	var built: Dictionary = StateKey.build(host.runtime.get_level(),host.runtime.get_state())
	check(built.ok,"formal complete StateKey valid")
	return built.key

func snapshot(host, label: String) -> Dictionary:
	var row := {"case":label,"state":host.runtime.get_state(),"scope":host.runtime.get_presentation_scope(),"state_key":state_key(host),"commits":host.runtime.get_commit_count(),"shell_goal":ui.goal_seen,"title":ui._lab_title.text,"host_hud":host.status.text}
	rows.append(row)
	return row

func choose(id: StringName) -> bool:
	ui.menu_scroll.ensure_control_visible(ui.entries[id]); await settle()
	await click(ui.entries[id])
	check(is_instance_valid(ui.lab) and ui.lab.runtime.is_loaded() and ui.lab.host_issues.is_empty(),"actual Menu/author resources/Baker/Host loaded "+String(id))
	if not is_instance_valid(ui.lab): return false
	ui.lab.runtime.committed.connect(record_commit.bind(ui.lab))
	return true

func record_commit(state: Dictionary, host) -> void:
	commits.append({"state":state,"scope":host.runtime.get_presentation_scope(),"shell_goal_at_observer":ui.goal_seen,"title_at_observer":ui._lab_title.text})

func goal_route(host) -> void:
	for code in [KEY_D,KEY_SPACE,KEY_S]:
		await key(code); await idle(host)
	var goal: Dictionary = Goal.is_goal(host.runtime.get_level(),host.runtime.get_state())
	check(goal.ok and goal.is_goal and ui.goal_seen and "已抵达终点" in ui._lab_title.text,"real native Gate D/Space/S reaches Goal and Shell marks completion")

func goal_callback(host) -> Callable:
	for connection in host.goal_reached.get_connections():
		if connection.callable.get_object() == ui: return connection.callable
	check(false,"actual Shell Goal callback connected")
	return Callable()

func clear_at_spawn(host, initial_key: String, title: String, label: String) -> void:
	check(state_key(host) == initial_key and host.runtime.get_commit_count() == 0,label+": authoritative exact spawn and zero commits")
	check(not ui.goal_seen,label+": Shell completion flag clears")
	check(ui._lab_title.text == title,label+": bottom title returns to level identity")

func pending_identity(host, label: String) -> Dictionary:
	for index in range(host.events.size()-1,-1,-1):
		var identity = host.events[index].get("transition_identity")
		if identity is Dictionary and identity.generation == host.runtime.get_generation():
			return identity.duplicate(true)
	check(false,label+": actual native pending identity captured")
	return {}

func return_menu() -> void:
	var runtime = ui.lab.runtime
	await click(ui.return_button)
	check(ui.lab == null and ui.menu_panel.visible and not runtime.is_loaded(),"native return unloads actual Runtime and exposes Menu")

func extensions(host, initial_key: String, base_title: String) -> void:
	await goal_route(host)
	var old_run_goal := goal_callback(host)
	var goal_scope: Dictionary = host.runtime.get_presentation_scope()
	var old_goal_state: Dictionary = host.runtime.get_state()
	await key(KEY_E); await idle(host)
	check(host.runtime.get_state().camera_quadrant != old_goal_state.camera_quadrant and host.runtime.get_presentation_scope() == goal_scope and ui.goal_seen,"ordinary Camera commit within same lifecycle retains reached-Goal UI")
	await key(KEY_R); await idle(host)
	clear_at_spawn(host,initial_key,base_title,"Camera→R")
	# Stale state callback is an invalid-delivery probe, not a positive commit.
	ui._on_lab_committed(old_goal_state,host)
	clear_at_spawn(host,initial_key,base_title,"old Goal state commit callback ignored")
	await goal_route(host)
	old_run_goal = goal_callback(host)
	goal_scope = host.runtime.get_presentation_scope()
	# Real Host reload of the same saved author resource changes level_run_id;
	# retain the same Node to exercise the run fence independently of source Node.
	host.load_map("world_shift_gate_lab"); await idle(host)
	check(host.runtime.get_presentation_scope().level_run_id != goal_scope.level_run_id,"actual same-Host reload starts a different formal run")
	old_run_goal.call(&"world_shift_gate_lab")
	clear_at_spawn(host,initial_key,base_title,"old run Goal callback rejected")
	snapshot(host,"same Host different run rejects actual captured Goal callback")
	await goal_route(host)
	var generation: int = host.runtime.get_generation()
	for repeat in 8: await key(KEY_R,false)
	await idle(host)
	check(host.runtime.get_generation() == generation+8,"eight rapid physical R events each reach real Reset generation")
	clear_at_spawn(host,initial_key,base_title,"rapid consecutive R")
	await goal_route(host)
	await return_menu()
	if not await choose(&"world_shift_gate_lab"): return
	host = ui.lab
	clear_at_spawn(host,initial_key,base_title,"exit and native menu reentry")
	await goal_route(host)
	await key(KEY_R); await idle(host)
	await key(KEY_D); await idle(host)
	await key(KEY_SPACE,false)
	var shift_token: Dictionary = host._shift_identity.duplicate(true)
	check(not shift_token.is_empty() and not host.runtime.is_idle(),"native Shift is actually pending before Reset")
	await key(KEY_R); await idle(host)
	host._finish_shift(shift_token)
	check(host.runtime.finish_transition(shift_token).ignored,"old Shift native completion rejects obsolete generation")
	clear_at_spawn(host,initial_key,base_title,"Reset during actual Shift and old callback")
	await key(KEY_E,false)
	var camera_token: Dictionary = host._camera_motion.get("token",{}).duplicate(true)
	check(not camera_token.is_empty() and not host.runtime.is_idle(),"native Camera is actually pending before Reset")
	await key(KEY_R); await idle(host)
	check(host.runtime.finish_transition(camera_token).ignored,"old Camera native completion rejects obsolete generation")
	clear_at_spawn(host,initial_key,base_title,"Reset during actual Camera and old callback")
	snapshot(host,"Shift and Camera cancellation remain at exact spawn")
	await return_menu()
	if not await choose(&"perspective_fork_lab"): return
	host = ui.lab
	var fork_initial := state_key(host)
	var fork_title: String = ui._lab_title.text
	await key(KEY_F,false)
	var fall_token := pending_identity(host,"Fork Fall")
	check(not host.runtime.is_idle() and host.presenter.snapshot().phase == "FALL","native F starts actual Fall before Reset")
	await key(KEY_R); await idle(host)
	check(host.runtime.finish_transition(fall_token).ignored,"old Fall completion rejects obsolete generation")
	await create_timer(0.65).timeout
	clear_at_spawn(host,fork_initial,fork_title,"Reset during Fall and elapsed old motion duration")
	await return_menu()
	# Current saved-authoring maps share this Shell. Positive Goal comes only
	# from their actual formal witness actions and natural native completion.
	for id in [&"orientation_loop_lab",&"face_lock_lab",&"perspective_fork_lab",&"rubik_spatial_puzzle_01"]:
		if not await choose(id): return
		host = ui.lab
		var start_key := state_key(host)
		var title: String = ui._lab_title.text
		var witness: Dictionary = Factory.witnesses(id)
		var route: Array = witness.get("solution",witness.get("solution_east",witness.get("solution_a",[])))
		check(not route.is_empty(),"saved author resource has formal solution witness: "+String(id))
		for action in route:
			var prior: Dictionary = host.runtime.get_state()
			var prior_commits: int = host.runtime.get_commit_count()
			var result: Dictionary = host.runtime.request_action(action)
			check(result.status == 0,"actual witness action accepted: "+String(id))
			if not result.changed:
				check(action.kind == 9 and action.camera_quadrant == prior.camera_quadrant and host.runtime.get_state() == prior and host.runtime.get_commit_count() == prior_commits,"already-active witness Camera is accepted no-op, not a missing move: "+String(id))
			await idle(host)
			rows.append({"case":"actual saved-author witness: "+String(id),"result":result,"scope":host.runtime.get_presentation_scope(),"commits":host.runtime.get_commit_count()})
		var reached: Dictionary = Goal.is_goal(host.runtime.get_level(),host.runtime.get_state())
		check(reached.ok and reached.is_goal and ui.goal_seen and "已抵达终点" in ui._lab_title.text,"actual Goal signal shows Shell completion: "+String(id))
		await key(KEY_R); await idle(host)
		clear_at_spawn(host,start_key,title,"native R after actual Goal: "+String(id))
		snapshot(host,"shared Shell reset on saved author map: "+String(id))
		check(host.host_issues.is_empty(),"Host issue list empty: "+String(id))
		await return_menu()

func run() -> void:
	check(DisplayServer.get_name() == "headless" and not evidence.is_empty(),"actual headless scoped test process")
	root.content_scale_size = Vector2i.ZERO; root.content_scale_mode = Window.CONTENT_SCALE_MODE_DISABLED; root.size = Vector2i(1280,720)
	ui = MAIN.instantiate()
	ui.save_path = "user://spatial_puzzle_batch_01/tests/polish_03/progress.json"
	root.add_child(ui); await settle()
	if not await choose(&"world_shift_gate_lab"): await finish(); return
	var host = ui.lab
	var initial_key := state_key(host)
	var base_title: String = ui._lab_title.text
	await goal_route(host)
	var old_goal := goal_callback(host)
	var before := snapshot(host,"Goal before keyboard R")
	var saved_hash := FileAccess.get_sha256(ui.save_path)
	await key(KEY_R); await idle(host)
	var reset := snapshot(host,"keyboard R after actual Goal")
	check(reset.scope.generation > before.scope.generation and reset.scope.level_run_id == before.scope.level_run_id,"native Reset changes real generation within same run")
	clear_at_spawn(host,initial_key,base_title,"Goal→keyboard R")
	check(FileAccess.get_sha256(ui.save_path) == saved_hash and ui.progress.snapshot().completed.has("world_shift_gate_lab"),"Reset clears run presentation while preserving original persistent completion")
	await goal_route(host)
	await click(ui.reset_button); await idle(host)
	clear_at_spawn(host,initial_key,base_title,"Goal→mouse Reset")
	# Negative delayed delivery only: this callback was captured from a real Goal,
	# then belongs to an obsolete formal generation. It never proves positive Goal.
	old_goal.call(&"world_shift_gate_lab")
	snapshot(host,"old generation actual Goal callback after mouse Reset")
	clear_at_spawn(host,initial_key,base_title,"old generation callback rejected")
	await extensions(host,initial_key,base_title)
	await finish()

func finish() -> void:
	var report := {"checks":checks,"failures":failures,"rows":rows,"committed_signals":commits,"pid":OS.get_process_id(),"display":DisplayServer.get_name(),"engine":Engine.get_version_info(),"user_data_dir":OS.get_user_data_dir(),"doubles":[],"positive_authority":"actual Menu/author resources/Baker/Host/Runtime/native input and natural Presenter","negative_probes":"only obsolete callbacks after actual Goal/Reset","graphical":"NOT_RUN","human_qa":"NOT_RUN"}
	DirAccess.make_dir_recursive_absolute(evidence)
	var file := FileAccess.open(evidence.path_join("report.json"),FileAccess.WRITE)
	file.store_string(JSON.stringify(report,"\t")); file.close()
	ui.queue_free(); await settle(); await create_timer(0.15).timeout
	print("POLISH03 checks=",checks," failures=",failures.size())
	quit(0 if failures.is_empty() else 1)
