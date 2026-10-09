extends SceneTree
const Lab = preload("res://experiments/game_feel_01/host/core_lab.tscn")
const Key = preload("res://foundation/contracts/state_key.gd")
const Goal = preload("res://foundation/rules/goal_evaluator.gd")
var checks:=0
var failures: Array=[]
var rows: Array=[]
var evidence:=""
var profile:=""
var host: Node3D
func _initialize() -> void:
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--evidence="): evidence=arg.trim_prefix("--evidence=")
		if arg.begins_with("--profile="): profile=arg.trim_prefix("--profile=")
	call_deferred("run")
func check(ok: bool,label: String) -> void:
	checks+=1
	if not ok: failures.append(label)
func key(code: int) -> void:
	for pressed in [true,false]:
		var event:=InputEventKey.new()
		event.physical_keycode=code
		event.pressed=pressed
		Input.parse_input_event(event)
func settle() -> void:
	var deadline:=Time.get_ticks_msec()+3000
	while Time.get_ticks_msec()<deadline:
		await process_frame
		if host.runtime.is_idle() and host.presenter.snapshot().phase=="IDLE": return
	check(false,"natural presentation settled within bounded timeout")
func run() -> void:
	host=Lab.instantiate()
	root.add_child(host)
	await process_frame
	check(OS.get_user_data_dir().replace("\\","/").begins_with(profile.replace("\\","/")+"/"),"spam case user data isolated")
	for letter in ["a","b"]:
		host.load_map(letter)
		await process_frame
		var level: Dictionary=host.runtime.get_level()
		var initial: Dictionary=host.runtime.get_state()
		var source_key: String=Key.build(level,initial).key
		key(KEY_F)
		await process_frame
		check(host.presenter.snapshot().phase=="FALL" and host.runtime.get_commit_count()==0,letter+" real native input starts pending Fall")
		for iteration in 20:
			for code in [KEY_F,KEY_W,KEY_A,KEY_S,KEY_D,KEY_Q,KEY_E]: key(code)
		await process_frame
		check(host.runtime.get_state()==initial and host.runtime.get_commit_count()==0,letter+" 140 queued input attempts during Fall do not commit or retarget")
		var active: Dictionary=host.presenter.snapshot().transition_identity
		check(not active.is_empty() and host.presenter.snapshot().phase=="FALL",letter+" spam preserves active presentation identity")
		await settle()
		check(host.runtime.get_commit_count()==1 and host.runtime.get_state().player.location.cube_id==&"target" and host.runtime.get_state().camera_quadrant==1,letter+" natural landing commits once with original camera")
		check(host.runtime.finish_transition(active).ignored and host.runtime.get_commit_count()==1,letter+" late finish after spam is ignored")
		key(KEY_R)
		await process_frame
		check(Key.build(level,host.runtime.get_state()).key==source_key and host.runtime.get_commit_count()==0,letter+" native Reset restores spawn")
		key(KEY_F)
		await process_frame
		var old: Dictionary=host.presenter.snapshot().transition_identity
		for iteration in 10: key(KEY_F)
		key(KEY_R)
		await process_frame
		check(host.presenter.snapshot().phase=="IDLE" and Key.build(level,host.runtime.get_state()).key==source_key,letter+" native Reset interrupts queued input Fall")
		check(host.runtime.finish_transition(old).ignored and host.runtime.get_commit_count()==0,letter+" interrupted completion cannot overwrite Reset")
		key(KEY_F)
		await process_frame
		await settle()
		check(host.runtime.get_commit_count()==1 and host.runtime.get_state().player.location.cube_id==&"target",letter+" fresh natural Fall after spam interruption remains usable")
		key(KEY_D)
		await process_frame
		await settle()
		check(host.runtime.get_commit_count()==2 and Goal.is_goal(level,host.runtime.get_state()).is_goal,letter+" actual keyboard D maps to U_POS and natural Roll reaches Goal")
		rows.append({"map":letter,"level_hash":level.content_hash,"queued_attempts":150,"events":host.events.duplicate(true),"final_statekey":Key.build(level,host.runtime.get_state()).key})
	check(host.host_issues.is_empty(),"actual Host has no errors after input spam and interruption")
	host.free()
	FileAccess.open(evidence.path_join("report.json"),FileAccess.WRITE).store_string(JSON.stringify({"checks":checks,"failures":failures,"rows":rows,"doubles":[],"authority":"real Godot Input.parse_input_event -> native Host -> formal Runtime -> natural10A; manual finish used only to prove old callbacks ignored","display":DisplayServer.get_name(),"renderer":RenderingServer.get_current_rendering_method(),"user_data_dir":OS.get_user_data_dir(),"input":"Godot Input.parse_input_event; OS/human input NOT_RUN","human_qa":"NOT_RUN"},"\t"))
	quit(0 if failures.is_empty() else 1)
