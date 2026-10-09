extends SceneTree
## Real default Facade + Owner maps + real 10A + 00 natural bridge.
const Lab = preload("res://experiments/game_feel_01/host/core_lab.tscn")
const Key = preload("res://foundation/contracts/state_key.gd")
const Goal = preload("res://foundation/rules/goal_evaluator.gd")
var checks := 0
var failures: Array = []
var rows: Array = []
var evidence := ""
var profile := ""
var host: Node3D

func _initialize() -> void:
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--evidence="): evidence=arg.trim_prefix("--evidence=")
		if arg.begins_with("--profile="): profile=arg.trim_prefix("--profile=")
	call_deferred("run")

func check(value: bool, label: String) -> void:
	checks+=1
	if not value:
		failures.append(label)
		print("BEHAVIORAL_FAIL: ",label)

func native_key(code: int) -> void:
	var press:=InputEventKey.new()
	press.physical_keycode=code
	press.pressed=true
	Input.parse_input_event(press)
	await process_frame
	var release:=InputEventKey.new()
	release.physical_keycode=code
	release.pressed=false
	Input.parse_input_event(release)
	await process_frame

func settle(seconds: float=3.0) -> Array:
	var samples: Array=[]
	var until:=Time.get_ticks_msec()+int(seconds*1000)
	while Time.get_ticks_msec()<until:
		await process_frame
		var snap: Dictionary=host.presenter.snapshot()
		samples.append({"time_ms":Time.get_ticks_msec(),"phase":snap.phase,"actor":host.actor.transform,"screen":host.camera.unproject_position(host.actor.global_position),"state":host.runtime.get_state(),"commits":host.runtime.get_commit_count()})
		if snap.phase=="IDLE" and host.runtime.is_idle(): break
	return samples

func run() -> void:
	check(OS.get_user_data_dir().replace("\\","/").begins_with(profile.replace("\\","/")+"/"),"fresh isolated user data")
	check(ResourceLoader.exists("res://foundation/game_feel/runtime_facade.gd"),"01 real Facade delivered")
	if not failures.is_empty():
		finish()
		return
	host=Lab.instantiate()
	root.add_child(host)
	await process_frame
	check(host.runtime!=null and host.runtime.is_loaded() and host.host_issues.is_empty(),"real lab loads actual opt-in Owner map")
	if not failures.is_empty():
		host.free()
		finish()
		return
	for letter in ["a","b"]:
		host.load_map(letter)
		await process_frame
		var level: Dictionary=host.runtime.get_level()
		var before: Dictionary=host.runtime.get_state()
		var before_key: String=Key.build(level,before).key
		var source: Transform3D=host.actor.transform
		var offset: int=host.events.size()
		await native_key(KEY_F)
		var started: Dictionary={}
		for event in host.events.slice(offset):
			if event.semantic=="PERSPECTIVE_FALL_APPLIED" and event.phase=="STARTED": started=event
		check(not started.is_empty(),letter+" native Fall input gets actual Kernel STARTED")
		if started.is_empty(): continue
		check(host.runtime.get_state()==before and host.runtime.get_commit_count()==0,letter+" STARTED does not mutate committed StateKey")
		var target: Transform3D=host.project_pose(started.target_pose).transform
		check(signf(target.origin.y-source.origin.y)==(-1.0 if letter=="a" else 1.0),letter+" real target height matches required sign")
		check(host.camera.unproject_position(target.origin).y>host.camera.unproject_position(source.origin).y,letter+" actual camera projects target DOWN")
		var busy: Dictionary=host.runtime.request_action({"kind":9,"camera_quadrant":0})
		check(busy.status==1 and host.events[-1].reason_category=="BUSY" and host.runtime.get_state()==before,letter+" in-flight Camera rejected by actual BUSY")
		host.runtime.set_paused(true)
		host.presenter.set_paused(true)
		host.paused=true
		var frozen: Transform3D=host.actor.transform
		await create_timer(0.08).timeout
		check(host.actor.transform==frozen and host.runtime.get_commit_count()==0,letter+" Pause has no motion or commit")
		host.runtime.set_paused(false)
		host.presenter.set_paused(false)
		host.paused=false
		var samples: Array=await settle()
		var after: Dictionary=host.runtime.get_state()
		check(after==started.result.next_state and host.runtime.get_commit_count()==1,letter+" natural Presenter makes exactly one authoritative commit")
		check(host.actor.transform.is_equal_approx(target) and host.presenter.snapshot().phase=="IDLE",letter+" Landing settles exact formal pose and orientation")
		check(after.player.orientation==before.player.orientation and after.player.location.layer==before.player.location.layer,letter+" PRESERVE orientation and World")
		check(Key.build(level,after).key==Key.build(level,started.result.next_state).key and Key.build(level,after).key!=before_key,letter+" exact authorized target StateKey")
		var intermediate:=false
		var descending:=true
		var previous_y:=host.camera.unproject_position(source.origin).y
		for sample in samples:
			if sample.phase=="FALL":
				intermediate=intermediate or (not sample.actor.origin.is_equal_approx(source.origin) and not sample.actor.origin.is_equal_approx(target.origin))
				descending=descending and sample.screen.y>=previous_y-0.001
				previous_y=sample.screen.y
		check(intermediate and descending,letter+" sampled continuous actual actor path descends on screen")
		var committed_count:=0
		for event in host.events.slice(offset):
			if event.semantic=="PERSPECTIVE_FALL_APPLIED" and event.phase=="COMMITTED": committed_count+=1
		check(committed_count==1,letter+" one matching native COMMITTED")
		var roll: Dictionary=host.runtime.request_action({"kind":0,"face_axis":0})
		check(roll.status==0 and roll.changed,letter+" actual post-landing ordinary Roll accepted")
		await settle()
		var goal: Dictionary=Goal.is_goal(level,host.runtime.get_state())
		check(goal.ok and goal.is_goal and host.runtime.get_commit_count()==2,letter+" ordinary natural Roll reaches actual exit Goal")
		host.reset_lab()
		await process_frame
		check(Key.build(level,host.runtime.get_state()).key==before_key and host.actor.transform.is_equal_approx(source),letter+" Reset restores formal spawn and actor")
		await native_key(KEY_F)
		var active: Dictionary=host.presenter.snapshot().transition_identity
		host.reset_lab()
		check(host.runtime.finish_transition(active).ignored and host.runtime.get_commit_count()==0,letter+" Reset rejects stale native completion")
		await native_key(KEY_F)
		await settle()
		check(host.runtime.get_commit_count()==1 and host.runtime.get_state().player.location.cube_id==&"target",letter+" new Fall works after interruption")
		rows.append({"map":letter,"before":before,"started":started,"after":after,"source":source,"target":target,"samples":samples,"input":"Godot Input.parse_input_event routed through actual Host; OS/human input NOT_RUN"})
	check(host.host_issues.is_empty(),"no Host integration errors")
	host.free()
	finish()

func finish() -> void:
	var report: Dictionary={"checks":checks,"failures":failures,"rows":rows,"doubles":[],"authority":"real default formal Runtime + Owner09 map + real10A +00 natural SceneTree bridge; no manual Fall finish","pid":OS.get_process_id(),"user_data_dir":OS.get_user_data_dir(),"display":DisplayServer.get_name(),"human_qa":"NOT_RUN"}
	FileAccess.open(evidence.path_join("report.json"),FileAccess.WRITE).store_string(JSON.stringify(report,"\t"))
	quit(0 if failures.is_empty() else 1)
