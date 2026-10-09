extends SceneTree
## Real 10A samplers; synthetic port/commit only. Not legal Fall acceptance.
const Fixture = preload("res://tests/beta_sprint/game_feel_owner_10a/fixture.gd")
const Fall = preload("res://game/feel/animation/fall_landing/fall_motion.gd")
const Landing = preload("res://game/feel/animation/fall_landing/landing_motion.gd")
const Orientation = preload("res://foundation/orientation/discrete_orientation.gd")
const Factory = preload("res://experiments/game_feel_01/maps/map_factory.gd")
const Session = preload("res://foundation/runtime/runtime_session.gd")
var checks := 0
var failures: Array = []
var evidence := ""
var presenter: RefCounted
var actor: Node3D
var active_event: Dictionary
var finish_calls := 0
var reentrant_reset := false
var native_session: RefCounted
var native_token: Dictionary = {}
var unit_target2 := Vector3i(-8,2,8)

func _initialize() -> void:
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--evidence="): evidence = arg.trim_prefix("--evidence=")
	call_deferred("run")

func check(value: bool, label: String) -> void:
	checks += 1
	if not value:
		failures.append(label)
		print("BEHAVIORAL_FAIL: ", label)

func projection(pose: Dictionary) -> Dictionary:
	if not pose.get("location") is Dictionary or pose.location.cube_id not in [&"source",&"target"]:
		return {"ok":false,"issues":["Unknown formal anchor"],"transform":null}
	var columns := Orientation.columns(pose.orientation)
	return {"ok":true,"issues":[],"transform":Transform3D(Basis(Vector3(columns[0]),Vector3(columns[1]),Vector3(columns[2])), Vector3(Vector3i(0,6,0) if pose.location.cube_id == &"source" else unit_target2)*0.5)}

func finish_double(token: Dictionary) -> Dictionary:
	finish_calls += 1
	check(token == active_event.transition_identity, "captured native completion token, not presentation identity")
	if reentrant_reset:
		presenter.clear()
		presenter.sync_pose(active_event.source_pose)
		active_event = Fixture.event(true, 5, 100)
		unit_target2=Vector3i(-8,10,8)
		presenter.bind_scope(active_event.presentation_identity)
		presenter.consume_event(active_event)
	else:
		if native_session != null:
			var completed: Dictionary = native_session.finish_local(token.transaction_id,token.generation)
			check(not completed.get("ignored",false),"ordinary Roll finishes actual native Session")
		presenter.consume_event(Fixture.committed(active_event))
	return {"ignored":false}

func run() -> void:
	var path := "res://game/feel/cube_presenter.gd"
	check(ResourceLoader.exists(path), "natural sampler-to-native-completion bridge exists")
	if not failures.is_empty():
		finish()
		return
	var Presenter = load(path)
	check(Presenter.can_instantiate(), "presenter compiles")
	if not failures.is_empty():
		finish()
		return
	for higher in [false,true]:
		active_event = Fixture.event(higher,5,1 if not higher else 10)
		unit_target2=Vector3i(-8,10 if higher else 2,8)
		finish_calls = 0
		actor = Node3D.new()
		root.add_child(actor)
		presenter = Presenter.new()
		presenter.bind(actor,Fall.new(),Landing.new(),projection,finish_double)
		presenter.bind_scope(active_event.presentation_identity)
		presenter.sync_pose(active_event.source_pose)
		var source := actor.transform
		check(presenter.consume_event(active_event).ok,"authorized STARTED accepted by single writer")
		presenter.tick(0.3)
		check(actor.position != source.origin and actor.position != projection(active_event.target_pose).transform.origin,"continuous actual actor moves between endpoints")
		check(finish_calls == 0,"acceptance and partial motion never finish or land")
		var invalid := Fixture.event(higher,5,9 if not higher else 19)
		invalid.safety_verdict = {"status":"UNPROVEN","issues":["no path proof"],"evidence_ref":{}}
		var preserved := actor.transform
		check(not presenter.consume_event(invalid).ok,"invalid Safety attestation cannot start a motion")
		check(actor.transform == preserved and presenter.snapshot().presentation_identity == active_event.presentation_identity,"invalid replacement is atomic and keeps existing motion")
		var stale := Fixture.event(higher,5,300 if not higher else 400)
		stale.level_run_id="retired-unseen-run"
		stale.presentation_identity.level_run_id=stale.level_run_id
		stale.transition_identity.level_run_id=stale.level_run_id
		check(presenter.consume_event(stale).get("ignored",false),"unseen retired STARTED ignored before any sampler/projection")
		check(presenter.consume_event(Fixture.committed(stale)).get("ignored",false) and actor.transform==preserved,"unseen retired COMMITTED cannot replace active run")
		for defect in ["translated_path","missing_pose","unknown_anchor"]:
			var bad := Fixture.event(higher,5,500+["translated_path","missing_pose","unknown_anchor"].find(defect)+(100 if higher else 0))
			if defect=="translated_path":
				for point in range(bad.authorized_path_points2.size()): bad.authorized_path_points2[point]+=Vector3i(20,0,0)
			elif defect=="missing_pose": bad.erase("target_pose")
			else:
				bad.target_pose.location.cube_id=&"unknown"
				bad.target_face=bad.target_pose.location.duplicate(true)
				bad.result.next_state.player=bad.target_pose.duplicate(true)
			check(not presenter.consume_event(bad).ok,defect+" is rejected atomically")
			check(actor.transform==preserved and presenter.snapshot().presentation_identity==active_event.presentation_identity,defect+" preserves the live authoritative motion")
		var paused := actor.transform
		presenter.set_paused(true)
		presenter.tick(3.0)
		check(actor.transform == paused and finish_calls == 0,"Pause freezes actor and native completion")
		presenter.set_paused(false)
		presenter.tick(2.0)
		check(finish_calls == 1,"natural motion completes native transition exactly once")
		check(actor.position == projection(active_event.target_pose).transform.origin,"matching commit locks exact authoritative target center")
		presenter.tick(2.0)
		check(actor.transform == projection(active_event.target_pose).transform,"Landing settles exact cube24 Basis, origin and ONE scale")
		presenter.consume_event(active_event)
		presenter.consume_event(Fixture.committed(active_event))
		presenter.tick(3.0)
		check(finish_calls == 1 and actor.transform == projection(active_event.target_pose).transform,"duplicate start/commit cannot replay motion or landing")
		presenter.clear()
		presenter = null
		actor.free()
	active_event = Fixture.event(false,5,30)
	unit_target2=Vector3i(-8,2,8)
	actor=Node3D.new()
	root.add_child(actor)
	presenter=Presenter.new()
	presenter.bind(actor,Fall.new(),Landing.new(),projection,finish_double)
	presenter.bind_scope(active_event.presentation_identity)
	presenter.sync_pose(active_event.source_pose)
	finish_calls=0
	presenter.consume_event(active_event)
	presenter.tick(0.35)
	var old := active_event.duplicate(true)
	presenter.clear()
	presenter.sync_pose(active_event.source_pose)
	active_event=Fixture.event(true,5,40)
	unit_target2=Vector3i(-8,10,8)
	presenter.consume_event(active_event)
	var interrupted := old.duplicate(true)
	interrupted.semantic="ANIMATION_INTERRUPTED"
	interrupted.phase="INTERRUPTED"
	interrupted.event_id=old.event_id+1000
	presenter.consume_event(interrupted)
	presenter.tick(0.3)
	check(presenter.snapshot().presentation_identity == active_event.presentation_identity,"late old interruption cannot erase a new Fall")
	presenter.clear()
	presenter.sync_pose(active_event.source_pose)
	presenter.tick(2.0)
	check(finish_calls == 0 and actor.transform == projection(active_event.source_pose).transform,"Reset clears old motion without commit or landing")
	active_event=Fixture.event(false,5,60)
	unit_target2=Vector3i(-8,2,8)
	presenter.consume_event(active_event)
	finish_calls=0
	reentrant_reset=true
	presenter.tick(3.0)
	check(finish_calls == 1 and presenter.snapshot().presentation_identity == active_event.presentation_identity,"completion observer Reset/new-start survives old cleanup")
	check(actor.position == projection(active_event.source_pose).transform.origin,"old sampled transform not written after reentrant replacement")
	reentrant_reset=false
	presenter.clear()
	presenter=null
	actor.free()
	var data: Dictionary = Factory.read_spec("a")
	data.id="integration_roll_control"
	data.target_center2=[2,4,0]
	data.erase("exit_center2")
	var baked: Dictionary = Factory.bake(data)
	check(baked.ok,"ordinary control uses real Baker")
	if not baked.ok:
		print("CONTROL_BAKE_ISSUES: ",baked.issues)
		finish()
		return
	native_session=Session.new()
	check(native_session.load_level(baked.level).ok,"ordinary control uses actual Runtime Session")
	native_session.transition_started.connect(func(_r:Dictionary,id:int,generation:int,_global:bool):
		native_token={"transaction_id":id,"generation":generation})
	var result: Dictionary = native_session.request_action({"kind":0,"face_axis":0})
	check(result.status == 0 and result.changed,"actual Kernel authorizes ordinary Roll")
	active_event=Fixture.event(false,0,200)
	unit_target2=Vector3i(2,6,0)
	active_event.semantic="MOVE_APPLIED_NORMAL"
	active_event.result=result.duplicate(true)
	active_event.source_pose=result.previous_state.player.duplicate(true)
	active_event.target_pose=result.next_state.player.duplicate(true)
	active_event.source_face=active_event.source_pose.location.duplicate(true)
	active_event.target_face=active_event.target_pose.location.duplicate(true)
	active_event.authoritative_final_orientation=active_event.target_pose.orientation
	active_event.presentation_identity.generation=native_token.generation
	active_event.transition_identity.generation=native_token.generation
	active_event.transition_identity.transaction_id=native_token.transaction_id
	for k in ["connection_id","authorized_path_points2","motion_profile_id","motion_profile_hash","safety_verdict","orientation_policy","presentation_duration_seconds"]: active_event.erase(k)
	actor=Node3D.new()
	root.add_child(actor)
	presenter=Presenter.new()
	presenter.bind(actor,Fall.new(),Landing.new(),projection,finish_double)
	presenter.bind_scope(active_event.presentation_identity)
	presenter.sync_pose(active_event.source_pose)
	finish_calls=0
	check(presenter.consume_event(active_event).ok,"ordinary STARTED consumes actual authorized result")
	presenter.tick(0.12)
	check(actor.position.x > 0.0 and actor.position.x < 1.0 and actor.position.y > 3.0,"ordinary Cube Roll moves continuously about its support edge")
	presenter.tick(1.0)
	check(finish_calls == 1 and native_session.state.player == active_event.target_pose,"ordinary natural bridge commits actual Runtime once")
	check(actor.transform == projection(active_event.target_pose).transform,"ordinary Roll ends at exact formal orientation and center")
	presenter.clear()
	presenter=null
	native_session=null
	actor.free()
	finish()

func finish() -> void:
	var report := {"checks":checks,"failures":failures,"fixture_kind":"PRESENTATION_CONTRACT_UNIT","authoritative_runtime":false,"doubles":["01 event DTO/Safety attestation","native finish/commit"],"authority":"Real10A samplers and00 single-writer lifecycle Unit; no legal Runtime Fall acceptance","pid":OS.get_process_id(),"user_data_dir":OS.get_user_data_dir(),"display":DisplayServer.get_name()}
	FileAccess.open(evidence.path_join("report.json"),FileAccess.WRITE).store_string(JSON.stringify(report,"\t"))
	quit(0 if failures.is_empty() else 1)
