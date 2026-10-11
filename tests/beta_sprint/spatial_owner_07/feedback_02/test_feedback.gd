extends "res://tests/beta_sprint/spatial_owner_07/feedback_02/case_base.gd"

func run() -> void:
	if not await setup():
		await finish(); return
	if phase == "mechanisms": await mechanisms()
	elif phase == "loop_seed": await loop_seed()
	elif phase == "loop_restore": await loop_restore()
	await finish()

func mechanisms() -> void:
	# Read-only source seam audit, plus actual runtime behavior below.
	var audited: Array[Dictionary] = []
	for path in ["res://experiments/spatial_puzzle_batch_01/ui/main.gd","res://experiments/spatial_puzzle_batch_01/host/spatial_lab.gd","res://experiments/game_feel_01/host/core_lab.gd"]:
		var source := FileAccess.get_file_as_string(path)
		var permission_calls := false
		for call in ["gate_rejection(","mapping_rejection(","latch_arrival(","Orientation.apply("]:
			permission_calls = permission_calls or call in source
		check(not permission_calls,"UI/Host does not call formal Gate/contact qualification algorithms: "+path)
		audited.append({"path":path,"sha256":FileAccess.get_sha256(path)})
	rows.append({"case":"qualification boundary audit","files":audited,"limit":"known qualification entry points plus actual delegation, not arbitrary static-program proof"})
	if not await choose(&"world_shift_gate_lab"): return
	var host = ui.lab
	var gate_marks := markers(host,"SHIFT_GATE")
	check(gate_marks.size() == 1 and gate_marks[0].face == "gate/TOP", "authored Gate marker indicates identity, not spawn eligibility")
	await rejection(host,KEY_SPACE,1,2010,"WORLD_NOT_ALLOWED","请到标记的转换点确认","no Gate at ordinary source")
	await apply(host,Factory.witnesses(&"world_shift_gate_lab").solution[0],"reach declared Gate")
	var before: Dictionary = host.runtime.get_state()
	var first: int = host.events.size()
	await key(KEY_SPACE)
	var event := latest_event(host,first,1)
	check(not event.is_empty() and event.result.status == 0 and event.result.changed, "native Space applies actual allowed Gate proposal")
	await wait_idle(host)
	var shifted: Dictionary = host.runtime.get_state()
	check(shifted.player.location.layer != before.player.location.layer and shifted.player.orientation == before.player.orientation and shifted.camera_quadrant == before.camera_quadrant, "actual Shift changes world and preserves physical orientation/Camera")
	rows.append({"case":"allowed Gate","event":event,"state_key":state_key(host),"hud":host.status.text,"markers":markers(host,"SHIFT_GATE")})
	await return_menu()
	if not await choose(&"face_lock_lab"): return
	host = ui.lab
	var initial_key := state_key(host)
	var idle_mark := markers(host,"FACE_LOCK")
	check(host.runtime.get_state().mechanism_states[&"contact_lock"] == &"idle" and idle_mark.size() == 1 and idle_mark[0].text == "面 4 朝下", "initial Face Lock marker reads formal idle state and authored local-face symbol")
	await rejection(host,KEY_SPACE,1,2011,"MECHANISM_LOCKED","机关尚未激活","declared Gate before latch")
	var locked_key := state_key(host)
	await click(ui.hint_button)
	await click(ui.motion_button)
	check(state_key(host) == locked_key and host._hint_visible and host._reduced_motion, "requested Hint and Reduced Motion cannot grant Gate permission")
	await rejection(host,KEY_SPACE,1,2011,"MECHANISM_LOCKED","机关尚未激活","same Gate after presentation-only controls")
	for action in Factory.witnesses(&"face_lock_lab").wrong_face: await apply(host,action,"wrong contact route")
	var wrong: Dictionary = host.runtime.get_state()
	check(wrong.player.location.cube_id == &"corner" and wrong.player.orientation == 20 and wrong.mechanism_states[&"contact_lock"] == &"idle", "wrong contact is successful movement with actual orientation20 and no latch")
	check(markers(host,"FACE_LOCK") == idle_mark, "wrong contact never displays a fabricated activation marker")
	rows.append({"case":"wrong Face contact","hud":host.status.text,"markers":markers(host,"FACE_LOCK"),"state_key":state_key(host),"feedback_limit":"unchanged authored face requirement; no dedicated wrong-contact reason is emitted for successful MOVE"})
	await click(ui.reset_button)
	check(state_key(host) == initial_key and markers(host,"FACE_LOCK") == idle_mark, "native UI Reset restores actual idle state and marker")
	var correct: Dictionary = {}
	for action in Factory.witnesses(&"face_lock_lab").correct_face: correct = await apply(host,action,"correct contact route")
	var latched: Dictionary = host.runtime.get_state()
	check(latched.player.location == wrong.player.location and latched.player.orientation == 14 and latched.mechanism_states[&"contact_lock"] == &"latched", "same sensor location with actual orientation14 latches formal mechanism")
	check(correct.action.kind == 0 and correct.previous_state.mechanism_states[&"contact_lock"] == &"idle" and correct.next_state.mechanism_states[&"contact_lock"] == &"latched" and host.runtime.get_commit_count() == 2, "latch belongs to exactly the second successful MOVE commit, no UI/USE activation")
	check(markers(host,"FACE_LOCK").size() == 1 and markers(host,"FACE_LOCK")[0].text == "已激活", "actual committed latch appears in read-only world marker")
	for action in Factory.witnesses(&"face_lock_lab").solution.slice(2,4): await apply(host,action,"leave latched sensor and return to Gate")
	check(host.runtime.get_state().player.location.cube_id == &"source" and host.runtime.get_state().mechanism_states[&"contact_lock"] == &"latched", "formal latch survives leaving sensor and returning to source Gate")
	first = host.events.size()
	before = host.runtime.get_state()
	await key(KEY_SPACE)
	event = latest_event(host,first,1)
	check(not event.is_empty() and event.result.status == 0, "actual native Gate proposal succeeds after latch")
	await wait_idle(host)
	check(host.runtime.get_state().mechanism_states[&"contact_lock"] == &"latched" and host.runtime.get_state().player.orientation == before.player.orientation, "native Shift preserves formal latch and orientation")
	rows.append({"case":"latched Gate","event":event,"hud":host.status.text,"state_key":state_key(host)})
	await return_menu()
	if not await choose(&"perspective_fork_lab"): return
	host = ui.lab
	var spawn: Dictionary = host.runtime.get_state()
	var edge_marks := markers(host,"MOVE_EDGE")
	await key(KEY_Q)
	await wait_idle(host)
	check(host.runtime.get_state().camera_quadrant == 0 and host.runtime.get_state().player == spawn.player, "native Q changes only formal Camera, not physical pose/world")
	await rejection(host,KEY_F,0,2101,"CAMERA_NOT_ALLOWED","当前视角没有合法连接","Fork NORTH Camera rejects same declared edge")
	check(markers(host,"MOVE_EDGE") == edge_marks, "authored edge marker presence does not grant illegal Camera qualification")
	await key(KEY_E)
	await wait_idle(host)
	check(host.runtime.get_state().camera_quadrant == 1 and host.runtime.get_state().player == spawn.player, "native E restores legal Camera without changing physical pose")
	first = host.events.size()
	await key(KEY_F)
	event = latest_event(host,first,0)
	check(not event.is_empty() and event.semantic == "PERSPECTIVE_FALL_APPLIED" and event.result.status == 0 and event.result.action == {"kind":0,"face_axis":2}, "same native F submits same formal edge; Runtime grants legal Fall")
	await wait_idle(host)
	var fall_state: Dictionary = host.runtime.get_state()
	check(fall_state.player.location.cube_id == &"target_a" and fall_state.player.orientation == spawn.player.orientation and fall_state.player.location.layer == spawn.player.location.layer, "formal EAST target reached naturally with preserved orientation/world")
	rows.append({"case":"legal Fork Camera","event":event,"hud":host.status.text,"state_key":state_key(host)})
	await click(ui.reset_button)
	await key(KEY_E)
	await wait_idle(host)
	await key(KEY_E)
	await wait_idle(host)
	check(host.runtime.get_state().camera_quadrant == 3,"native E reaches WEST Camera")
	await rejection(host,KEY_F,0,2101,"CAMERA_NOT_ALLOWED","当前视角没有合法连接","Fork WEST Camera rejects same declared edge")
	check(host.host_issues.is_empty(),"actual Host reports no errors through feedback cases")
	await return_menu()

func loop_seed() -> void:
	check(not FileAccess.file_exists(save_path),"closed-loop seed uses a genuinely fresh original Store slot")
	if not await choose(&"orientation_loop_lab"): return
	var host = ui.lab
	var initial: Dictionary = host.runtime.get_state()
	var initial_key := state_key(host)
	var before_hash := FileAccess.get_sha256(save_path)
	var route: Array = Factory.witnesses(&"orientation_loop_lab").closed_loop
	for action in route: await apply(host,action,"actual Orientation closed loop")
	var looped: Dictionary = host.runtime.get_state()
	var looped_key := state_key(host)
	check(looped.player.location == initial.player.location and looped.player.orientation != initial.player.orientation, "real closed loop returns to same Position with changed physical Orientation")
	check(looped_key != initial_key and looped.camera_quadrant == initial.camera_quadrant and looped.world_orientations == initial.world_orientations and looped.mechanism_states == initial.mechanism_states, "formal full StateKey distinguishes only actual looped pose; Camera/world/mechanism unchanged")
	check(host.runtime.get_commit_count() == route.size() and not ui.goal_seen and ui.progress.snapshot().completed.is_empty(), "all actual loop Roll commits occur without Goal completion")
	check(FileAccess.get_sha256(save_path) == before_hash,"real loop motion never writes mid-puzzle orientation to Store")
	loop = {"initial_state":initial,"looped_state":looped,"initial_key":initial_key,"looped_key":looped_key,"level_content_hash":host.runtime.get_level().content_hash,"seed_pid":OS.get_process_id(),"seed_user_data_dir":OS.get_user_data_dir(),"save_sha256":before_hash,"commits":host.runtime.get_commit_count()}
	await return_menu()
	var saved: Dictionary = Store.new(save_path,"world_shift_gate_lab").load_save()
	check(saved.recent == "orientation_loop_lab" and saved.completed.is_empty() and not saved.has("player") and not saved.has("orientation") and not saved.has("state_key"), "existing Store retains level-start identity only, with no pose/statekey extension")
	check(FileAccess.get_sha256(save_path) == before_hash,"exiting the actual loop does not save the looped pose")
	check(not FileAccess.file_exists(Store.DEFAULT_PATH),"legacy save slot remains untouched")

func loop_restore() -> void:
	var prior = JSON.parse_string(FileAccess.get_file_as_string(prior_report))
	check(prior is Dictionary and prior.get("phase") == "loop_seed" and prior.get("failures",["missing"]).is_empty() and prior.get("checks",0)>0,"cold restore consumes a successful actual seed process report")
	if not prior is Dictionary or not prior.has("loop"): return
	var seed: Dictionary = prior.loop
	check(seed.seed_pid != OS.get_process_id() and seed.seed_user_data_dir == OS.get_user_data_dir(), "Continue is in a different OS process with the same isolated profile, not a simulated reload")
	check(FileAccess.file_exists(save_path) and FileAccess.get_sha256(save_path) == seed.save_sha256, "cold Menu boot restores unchanged actual original save bytes")
	check(ui.lab == null and not ui.continue_button.disabled and ui.progress.continue_id() == &"orientation_loop_lab", "cold actual Menu restores recent Loop and exposes Continue without starting gameplay")
	await click(ui.continue_button)
	check(is_instance_valid(ui.lab) and ui.lab.runtime.is_loaded(), "cold native Continue starts actual Host")
	if not is_instance_valid(ui.lab): return
	var host = ui.lab
	var restored: Dictionary = host.runtime.get_state()
	var restored_key := state_key(host)
	check(restored_key == seed.initial_key and restored_key != seed.looped_key, "cold Continue restores exact full initial StateKey instead of looped StateKey")
	# Diagnostic JSON uses String/float; compare declared fields, while the
	# independent canonical StateKey assertion above verifies the complete state.
	var location: Dictionary = restored.player.location
	var recorded_location: Dictionary = seed.initial_state.player.location
	check(restored.player.orientation == int(seed.initial_state.player.orientation) and String(location.cube_id) == String(recorded_location.cube_id) and location.layer == int(recorded_location.layer) and location.face == int(recorded_location.face) and host.runtime.get_commit_count() == 0, "cold Continue restores formal start Position/Orientation and zero commits")
	check(host.runtime.get_level().content_hash == seed.level_content_hash and not ui.goal_seen and ui.progress.snapshot().completed.is_empty(), "same real level content restored; Continue cannot manufacture a Goal")
	loop = {"seed_pid":seed.seed_pid,"restore_pid":OS.get_process_id(),"seed_user_data_dir":seed.seed_user_data_dir,"restore_user_data_dir":OS.get_user_data_dir(),"initial_key":seed.initial_key,"discarded_looped_key":seed.looped_key,"restored_key":restored_key,"restored_state":restored,"commits":host.runtime.get_commit_count(),"diagnostic_boundary_types":{"native_cube_id":typeof(location.cube_id),"json_cube_id":typeof(recorded_location.cube_id),"native_face":typeof(location.face),"json_face":typeof(recorded_location.face),"native_location_equals_json_dictionary":location == recorded_location}}
	await return_menu()
	check(not FileAccess.file_exists(Store.DEFAULT_PATH),"cold lifecycle leaves legacy save slot untouched")
