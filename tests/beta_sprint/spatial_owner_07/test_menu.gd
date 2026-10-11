extends SceneTree
const MAIN := "res://experiments/spatial_puzzle_batch_01/ui/main.tscn"
const FACTORY := "res://experiments/spatial_puzzle_batch_01/maps/map_factory.gd"
const Store = preload("res://game/shell/save_store.gd")
var checks := 0
var failures: Array[String] = []
var evidence := ""
var save_path := ""
var ui
var observations: Array[Dictionary] = []
var faults: Array[String] = []

func _initialize() -> void:
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--evidence-dir="): evidence=arg.trim_prefix("--evidence-dir=")
		elif arg.begins_with("--shell-save="): save_path=arg.trim_prefix("--shell-save=").get_base_dir().path_join("menu_progress.json")
	call_deferred("run")

func check(ok: bool, label: String) -> void:
	checks+=1
	if not ok:
		failures.append(label)
		printerr("FAIL: ",label)

func settle() -> void:
	for frame in 6: await process_frame

func key(code: int) -> void:
	for pressed in [true,false]:
		var event:=InputEventKey.new()
		event.keycode=code;event.physical_keycode=code;event.pressed=pressed
		Input.parse_input_event(event)
		await process_frame
	await settle()

func click(control: Control) -> void:
	var point:=control.get_global_rect().get_center()
	var motion:=InputEventMouseMotion.new()
	motion.position=point;motion.global_position=point
	Input.parse_input_event(motion)
	await process_frame
	for pressed in [true,false]:
		var event:=InputEventMouseButton.new()
		event.position=point;event.global_position=point;event.button_index=MOUSE_BUTTON_LEFT;event.pressed=pressed
		Input.parse_input_event(event)
		await process_frame
	await settle()

func choose(id: StringName) -> void:
	ui.menu_scroll.ensure_control_visible(ui.entries[id])
	await settle()
	await click(ui.entries[id])

func run() -> void:
	check(DisplayServer.get_name()=="headless" and save_path.begins_with("user://spatial_puzzle_batch_01/tests/") and ".." not in save_path, "isolated fresh headless menu test")
	check(ResourceLoader.exists(MAIN), "spatial menu scene exists")
	if not failures.is_empty():
		await finish();return
	check(ResourceLoader.exists(FACTORY), "actual Owner09 map factory is delivered; no dummy catalog")
	if not failures.is_empty():
		await finish();return
	var Factory: Script=load(FACTORY)
	root.content_scale_size=Vector2i.ZERO
	root.content_scale_mode=Window.CONTENT_SCALE_MODE_DISABLED
	ui=load(MAIN).instantiate()
	ui.save_path=save_path
	root.add_child(ui)
	await settle()
	check(ui.entries.size()==5 and ui.menu_panel.visible and ui.continue_button.disabled, "fresh menu exposes five independent labs and no Continue")
	for id in Factory.ids():
		check(ui.entries.has(id) and ui.entries[id].text==Factory.describe(id).title and not ui.entries[id].disabled, "real Factory title/free selection: "+String(id))
	check(not FileAccess.file_exists(save_path) and not FileAccess.file_exists(Store.DEFAULT_PATH), "menu boot writes neither experimental nor legacy slot")
	for area in [Vector2i(1920,1080),Vector2i(1280,720),Vector2i(960,720)]:
		root.size=area
		await settle()
		check(root.get_visible_rect().size==Vector2(area) and root.get_visible_rect().encloses(ui.menu_panel.get_global_rect()), "measured contained menu viewport "+str(area))
		ui.entries[Factory.ids()[0]].grab_focus()
		for id in Factory.ids():
			await settle()
			check(ui.entries[id].has_focus() and ui.menu_scroll.get_global_rect().grow(1).encloses(ui.entries[id].get_global_rect()), "native Tab reaches visible lab button "+String(id)+" "+str(area))
			await key(KEY_TAB)
		check(ui.legacy_button.has_focus(), "native focus reaches old Shell switch "+str(area))
		observations.append({"requested":str(area),"measured":str(root.get_visible_rect()),"menu":str(ui.menu_panel.get_global_rect()),"scroll":str(ui.menu_scroll.get_global_rect())})
	await choose(&"orientation_loop_lab")
	check(is_instance_valid(ui.lab) and ui.lab.runtime.is_loaded() and ui.lab.lab_id==&"orientation_loop_lab", "actual mouse selection starts delivered Host with real baked Loop")
	if not is_instance_valid(ui.lab):
		await finish();return
	check(not ui.menu_panel.visible and ui.toolbar.visible and root.gui_get_focus_owner()==null, "entering gameplay releases all menu focus")
	check(root.get_visible_rect().encloses(ui.toolbar.get_global_rect()) and ui.toolbar.position.y>=root.size.y-110, "toolbar reserves bottom strip and avoids top Host status")
	var before: Dictionary=ui.lab.runtime.get_state()
	await click(ui.pause_button)
	check(ui.lab.paused and ui.lab.runtime.is_paused() and ui.lab.runtime.get_state()==before, "real pause port freezes Host without rewriting state")
	await key(KEY_ESCAPE)
	check(not ui.lab.paused and ui.pause_button.text=="暂停", "Host-owned Esc resumes and UI mirrors pause")
	await click(ui.motion_button)
	check(ui.lab._reduced_motion and ui.lab.runtime.get_state()==before, "Reduced Motion reaches real Host with unchanged formal state")
	check(not ui.lab._hint_visible and "提示：" not in ui.lab.status.text, "default presentation omits advanced Hint")
	await click(ui.hint_button)
	check(ui.lab._hint_visible and Factory.describe(&"orientation_loop_lab").hint in ui.lab.status.text, "explicit Hint button reveals actual authored Host hint")
	ui.lab.goal_reached.emit(&"face_lock_lab")
	faults.append("injected wrong-level Goal signal")
	check(ui.progress.snapshot().completed.is_empty(), "wrong level signal cannot mark completed")
	var old=ui.lab
	var old_runtime=old.runtime
	ui.return_button.pressed.emit()
	old.goal_reached.emit(&"orientation_loop_lab")
	faults.append("injected Goal signal from removed old Host")
	check(ui.lab==null and ui.progress.snapshot().completed.is_empty() and not old_runtime.is_loaded(), "return unloads real Host and ignores old-node Goal before deferred free")
	await settle()
	await choose(&"orientation_loop_lab")
	await click(ui.pause_button)
	await click(ui.reset_button)
	check(ui.lab.runtime.get_commit_count()==0 and not ui.lab.paused and ui.progress.snapshot().completed.is_empty(), "Reset returns actual start without completion and resumes")
	var route: Array=Factory.witnesses(&"orientation_loop_lab").solution_a
	for action in route:
		var accepted: Dictionary=ui.lab.runtime.request_action(action)
		check(accepted.status==0 and accepted.changed, "real Loop witness action accepted")
		var deadline:=Time.get_ticks_msec()+3500
		while not ui.lab.runtime.is_idle() and Time.get_ticks_msec()<deadline: await process_frame
		check(ui.lab.runtime.is_idle(), "natural Presenter completion reaches actual native idle")
	check(ui.lab.runtime.get_commit_count()==route.size() and ui.goal_seen, "actual witness commits produce actual Host Goal")
	var persisted: Dictionary=Store.new(save_path,"world_shift_gate_lab").load_save()
	check(persisted.completed==["orientation_loop_lab"] and persisted.recent=="orientation_loop_lab", "only real Host Goal writes experimental completion")
	check(ui.lab.host_issues.is_empty(), "actual Host has no diagnostics")
	await click(ui.return_button)
	check(ui.continue_button.disabled==false and ui.menu_panel.visible and ui.lab==null, "return exposes level-start Continue after actual Goal")
	DirAccess.remove_absolute(save_path+".bak")
	DirAccess.make_dir_absolute(save_path+".bak")
	faults.append("actual blocked backup directory")
	await click(ui.continue_button)
	check(ui.lab==null and ui.retry_button.visible and not ui.error_label.text.is_empty(), "actual start save failure stays in menu with visible retry")
	DirAccess.remove_absolute(save_path+".bak")
	await click(ui.retry_button)
	check(is_instance_valid(ui.lab) and ui.lab.runtime.get_commit_count()==0 and ui.progress.snapshot().completed==["orientation_loop_lab"], "retry enters once at actual start without another Goal")
	check(ui.lab.runtime.get_state().player==Factory.bake(&"orientation_loop_lab").level.spawn, "Continue retry restores the formal level spawn, never the saved Goal pose")
	await click(ui.return_button)
	check(not FileAccess.file_exists(Store.DEFAULT_PATH), "old QA save still untouched after real UI/Host lifecycle")
	ui.queue_free()
	await settle()
	# Separate fresh actual Goal/storage failure; no synthetic positive Goal or finish signal.
	var goal_failure_path:=save_path.get_base_dir().path_join("menu_goal_failure.json")
	ui=load(MAIN).instantiate()
	ui.save_path=goal_failure_path
	root.add_child(ui)
	await settle()
	await choose(&"orientation_loop_lab")
	DirAccess.make_dir_absolute(goal_failure_path+".bak")
	faults.append("actual Goal backup-directory write failure")
	var current_host=ui.lab
	for action in route:
		var accepted: Dictionary=ui.lab.runtime.request_action(action)
		check(accepted.status==0 and accepted.changed, "second actual witness action accepted for storage-failure case")
		var deadline:=Time.get_ticks_msec()+3500
		while not ui.lab.runtime.is_idle() and Time.get_ticks_msec()<deadline: await process_frame
		check(ui.lab.runtime.is_idle(), "second actual witness completes naturally")
	check(ui.goal_seen and ui.progress.dirty and ui.retry_button.visible and not ui.error_label.text.is_empty(), "real Goal save failure shows retry during gameplay")
	check(not ui._error_panel.get_global_rect().intersects(ui.toolbar.get_global_rect()), "wrapped save-error panel cannot cover gameplay controls")
	observations.append({"case":"goal_save_failure","error":str(ui._error_panel.get_global_rect()),"error_min":str(ui._error_panel.get_combined_minimum_size()),"toolbar":str(ui.toolbar.get_global_rect()),"pause":str(ui.pause_button.get_global_rect()),"return":str(ui.return_button.get_global_rect())})
	await click(ui.pause_button)
	check(ui.lab.paused, "native mouse reaches Pause with actual Goal-save error visible")
	ui.pause_button.grab_focus()
	for index in 5: await key(KEY_TAB)
	check(ui.retry_button.has_focus(), "paused keyboard focus reaches actual Goal-save retry")
	await key(KEY_ESCAPE)
	var actual_goal_state: Dictionary=ui.lab.runtime.get_state()
	DirAccess.remove_absolute(goal_failure_path+".bak")
	await click(ui.retry_button)
	check(ui.lab==current_host and ui.lab.runtime.get_commit_count()==route.size() and ui.lab.runtime.get_state()==actual_goal_state and not ui.progress.dirty, "Goal retry saves without restarting Host or changing native state/commit count")
	check(Store.new(goal_failure_path,"world_shift_gate_lab").load_save().completed==["orientation_loop_lab"], "Goal retry actually persists completion")
	await click(ui.return_button)
	ui.queue_free()
	await settle()
	var return_failure_path:=save_path.get_base_dir().path_join("menu_return_failure.json")
	ui=load(MAIN).instantiate()
	ui.save_path=return_failure_path
	root.add_child(ui)
	await settle()
	await choose(&"orientation_loop_lab")
	DirAccess.make_dir_absolute(return_failure_path+".bak")
	faults.append("actual Goal save failure retained across menu return")
	for action in route:
		var accepted: Dictionary=ui.lab.runtime.request_action(action)
		check(accepted.status==0 and accepted.changed, "actual return-case witness accepted")
		var deadline:=Time.get_ticks_msec()+3500
		while not ui.lab.runtime.is_idle() and Time.get_ticks_msec()<deadline: await process_frame
		check(ui.lab.runtime.is_idle(), "actual return-case witness completes naturally")
	observations.append({"case":"return_goal_save_failure","error":str(ui._error_panel.get_global_rect()),"toolbar":str(ui.toolbar.get_global_rect()),"return":str(ui.return_button.get_global_rect())})
	await click(ui.return_button)
	check(ui.lab==null and ui.progress.dirty and ui.retry_button.visible, "menu retains unsaved actual Goal and retry")
	ui.continue_button.grab_focus()
	for index in Factory.ids().size()+2: await key(KEY_TAB)
	check(ui.retry_button.has_focus(), "menu keyboard focus includes retained Goal-save retry")
	DirAccess.remove_absolute(return_failure_path+".bak")
	if ui.retry_button.has_focus(): await key(KEY_ENTER)
	else: ui.retry_button.pressed.emit() # Isolate the RED focus failure without a wrong action.
	check(ui.lab==null and not ui.progress.dirty and Store.new(return_failure_path,"world_shift_gate_lab").load_save().completed==["orientation_loop_lab"], "keyboard Goal retry returns confirmed progress without restarting a scene")
	ui.queue_free()
	await settle()
	var protected_path:=save_path.get_base_dir().path_join("menu_future.json")
	var protected_text:=JSON.stringify({"version":99,"payload":"future","checksum":"future"})
	var future_file:=FileAccess.open(protected_path,FileAccess.WRITE)
	future_file.store_string(protected_text);future_file.close()
	faults.append("actual future-version menu save")
	ui=load(MAIN).instantiate()
	ui.save_path=protected_path
	root.add_child(ui)
	current_scene=ui
	await settle()
	check(ui.progress.read_only and ui.continue_button.disabled and not ui.error_label.text.is_empty(), "future-format menu shows protection and no invalid Continue")
	await choose(&"orientation_loop_lab")
	check(ui.lab==null and not ui.retry_button.visible and FileAccess.get_file_as_string(protected_path)==protected_text, "future menu cannot downgrade or hide protected-write failure")
	# Actual scene switch to the untouched five-level Shell; old profile remains isolated.
	ui.legacy_button.pressed.emit()
	await settle()
	check(is_instance_valid(current_scene) and current_scene.scene_file_path=="res://game/shell/game_feel_shell.tscn", "old five-level button performs the actual scene switch")
	check(FileAccess.get_file_as_string(protected_path)==protected_text and not FileAccess.file_exists(Store.DEFAULT_PATH), "legacy scene boot writes neither protected experimental nor legacy default progress")
	await finish()

func finish() -> void:
	var report: Dictionary={"checks":checks,"failures":failures,"pid":OS.get_process_id(),"engine":Engine.get_version_info(),"display":DisplayServer.get_name(),"user_data_dir":OS.get_user_data_dir(),"save_path":save_path,"observations":observations,"doubles":[],"fault_exercises":faults,"input":"native Input.parse_input_event mouse/Tab/Esc; formal real Loop witness actions for natural Goal","authority":"actual Factory/Baker + Host + Facade + natural Presenter + unchanged SaveStore; no finish injection","evidence_type":"UI_HEADLESS_WITH_REAL_LOOP_LIFECYCLE","new_gate_face_lock_fork":"NOT_ATTESTED_BY_THIS_UI_CASE","graphical":"NOT_RUN","human_qa":"NOT_RUN"}
	DirAccess.make_dir_recursive_absolute(evidence)
	var file:=FileAccess.open(evidence.path_join("report.json"),FileAccess.WRITE)
	file.store_string(JSON.stringify(report,"\t"));file.close()
	if is_instance_valid(ui): ui.queue_free()
	if is_instance_valid(current_scene): current_scene.queue_free()
	await settle()
	await create_timer(0.15).timeout # Mixer/scene cleanup only, never motion completion.
	print(JSON.stringify(report))
	quit(0 if failures.is_empty() else 1)
