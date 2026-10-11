extends "res://tests/beta_sprint/spatial_quality/suite.gd"
## Formal production GRAPHICAL trace only; no actor/state writes or manual finish.
const MapsPath := "res://experiments/spatial_puzzle_batch_01/maps/map_factory.gd"
const Records = preload("res://foundation/contracts/contract_records.gd")
const Explorer = preload("res://foundation/solver/state_explorer.gd")
const Search = preload("res://foundation/solver/search_records.gd")
const Trace = preload("res://foundation/solver/solution_trace.gd")
const Replayer = preload("res://foundation/parity/trace_replayer.gd")
const Geometry = preload("res://foundation/spatial/surface_geometry.gd")
const Math = preload("res://foundation/orientation/discrete_orientation.gd")
const View = preload("res://foundation/game_feel/view_contract.gd")
const PREFIX := {&"world_shift_gate_lab":"gate",&"orientation_loop_lab":"loop",&"face_lock_lab":"lock",
	&"perspective_fork_lab":"fork",&"rubik_spatial_puzzle_01":"combined"}

func vector(value: Variant) -> Vector3:
	if value is Vector3: return value
	return Vector3(value[0],value[1],value[2])

func verify_completion(level: Dictionary, trace: Dictionary, step: Dictionary, index: int) -> void:
	var expected: Dictionary = trace.steps[index].expected_state
	var before: Dictionary = trace.initial_state if index == 0 else trace.steps[index-1].expected_state
	check(step.status == 0 and step.completion_received and step.commit_delta == 1 and step.commit_signals == 1,"one real commit and natural completion")
	var c: Dictionary = step.get("completion_evidence",{})
	check(c.has_all(["transition_identity","final_statekey","final_state","final_visual_pose","final_camera_pose","delivered"]),"native completion carries real state and render evidence")
	if not c.has_all(["transition_identity","final_statekey","final_state","final_visual_pose","final_camera_pose","delivered"]): return
	check(c.transition_identity == step.transition_identity and c.transition_identity.has_all(["session_id","level_run_id","generation","transaction_id","is_global"]),"exact full current transition identity")
	check(c.delivered and c.cancelled_order == 0 and c.started_order < c.committed_order and c.committed_order < c.completion_order,"native start commit completion order")
	check(c.final_state == expected and c.final_statekey == trace.steps[index].resulting_statekey and step.actual_statekey == step.expected_statekey,"full authoritative Runtime state parity")
	check(c.orientation == expected.player.orientation and c.world_id == expected.player.location.layer and c.camera_quadrant == expected.camera_quadrant,"Orientation World and Camera match")
	var columns := Math.columns(expected.player.orientation)
	check(range(3).all(func(i): return vector(c.final_visual_pose.basis[i]).is_equal_approx(Vector3(columns[i]))),"actual actor basis matches formal Orientation")
	var spatial := Geometry.snapshot(level,expected)
	check(spatial.ok,"formal endpoint Spatial snapshot")
	if spatial.ok:
		var anchors: Array = spatial.value.anchors.filter(func(a): return a.face_id == Geometry.face_id(expected.player.location.cube_id,expected.player.location.face) and a.layer == expected.player.location.layer)
		check(anchors.size() == 1,"unique endpoint anchor")
		if anchors.size() == 1:
			check(vector(c.final_visual_pose.origin).is_equal_approx(Vector3(anchors[0].position2 + anchors[0].frame.normal)*0.5),"actual visual center matches logical support")
	var camera := View.basis(expected.camera_quadrant)
	var camera_columns := [camera.x,camera.y,camera.z]
	check(range(3).all(func(i): return vector(c.final_camera_pose.basis[i]).is_equal_approx(camera_columns[i])),"actual Camera basis matches committed quadrant")
	if c.semantic == "PERSPECTIVE_FALL_APPLIED":
		check(c.frames.size() > 3 and c.frames.any(func(f):return f.phase == "FALL") and c.frames.any(func(f):return f.phase == "LANDING"),"actual Fall and Landing frames exist")
		check(c.orientation == before.player.orientation and c.terminal.get("terminal_phase") == "LANDING_SETTLED","Fall preserves pose and waits for Landing settle")

func run() -> void:
	if not ResourceLoader.exists(MapsPath):
		dependency_pending.append("REAL_09_MAP_FACTORY")
		finish()
		return
	var maps: Script = load(MapsPath)
	var selected := ""
	var mode := 1
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--map="): selected = arg.trim_prefix("--map=")
		if arg == "--search-mode=first": mode = 0
	for id in maps.ids():
		if not selected.is_empty() and String(id) != selected: continue
		var prefix: String = PREFIX[id]
		begin(prefix + ".formal_replay","FORMAL_GRAPHICAL")
		var baked: Dictionary = maps.bake(id)
		check(baked.get("ok",false),"real authored map Baker")
		if not baked.get("ok",false): continue
		var level: Dictionary = baked.level
		var explored := Explorer.explore(level,Records.initial_state(level),Search.default_policy(mode),Search.default_budget())
		check(explored.status == 0 and explored.graph != null and (mode == 0 or explored.graph.complete) and explored.solution_trace != null,"actual original search solved; partial witness never proves complete graph")
		if explored.solution_trace == null: continue
		var original: Dictionary = explored.solution_trace
		check(Trace.validate(level,original).ok and Trace.validate_semantics(level,original).ok,"selected ORIGINAL Solver witness checked")
		for repeat_index in 2:
			var driver := Replayer.new()
			root.add_child(driver)
			var actual: Dictionary = await driver.replay(level,original,{"mode":1,"step_timeout_ms":5000})
			check(actual.status == 0 and actual.matched_steps == original.total_actions and actual.actual_statekey == original.goal_statekey,"formal GRAPHICAL original trace repeat " + str(repeat_index))
			var steps := driver.get_step_evidence()
			check(steps.size() == original.total_actions,"all steps retained")
			for index in steps.size(): verify_completion(level,original,steps[index],index)
			rows.append({"map":id,"repeat":repeat_index,"level_hash":level.content_hash,"original_trace":original,"formal_graphical":actual,"steps":steps})
			driver.free()
	finish()
