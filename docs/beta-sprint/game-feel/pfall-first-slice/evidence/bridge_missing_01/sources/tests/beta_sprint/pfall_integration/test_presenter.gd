extends SceneTree
## Real 10A samplers; synthetic port/commit only. Not legal Fall acceptance.
const Fixture = preload("res://tests/beta_sprint/game_feel_owner_10a/fixture.gd")
const Fall = preload("res://game/feel/animation/fall_landing/fall_motion.gd")
const Landing = preload("res://game/feel/animation/fall_landing/landing_motion.gd")
const Orientation = preload("res://foundation/orientation/discrete_orientation.gd")
var checks := 0
var failures: Array = []
var evidence := ""
var presenter: RefCounted
var actor: Node3D
var active_event: Dictionary
var finish_calls := 0
var reentrant_reset := false

func _initialize() -> void:
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--evidence="): evidence = arg.trim_prefix("--evidence=")
	call_deferred("run")

func check(value: bool, label: String) -> void:
	checks += 1
	if not value:
		failures.append(label)
		print("BEHAVIORAL_FAIL: ", label)

func projection(pose: Dictionary) -> Transform3D:
	var columns := Orientation.columns(pose.orientation)
	var points: Array = active_event.authorized_path_points2
	return Transform3D(Basis(Vector3(columns[0]),Vector3(columns[1]),Vector3(columns[2])), Vector3(points[0] if pose.location.cube_id == &"source" else points[-1])*0.5)

func finish_double(token: Dictionary) -> Dictionary:
	finish_calls += 1
	check(token == active_event.transition_identity, "captured native completion token, not presentation identity")
	if reentrant_reset:
		presenter.clear()
		presenter.sync_pose(active_event.source_pose)
		active_event = Fixture.event(true, 5, 100)
		presenter.consume_event(active_event)
	else:
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
		finish_calls = 0
		actor = Node3D.new()
		root.add_child(actor)
		presenter = Presenter.new()
		presenter.bind(actor,Fall.new(),Landing.new(),projection,finish_double)
		presenter.sync_pose(active_event.source_pose)
		var source := actor.transform
		check(presenter.consume_event(active_event).ok,"authorized STARTED accepted by single writer")
		presenter.tick(0.3)
		check(actor.position != source.origin and actor.position != projection(active_event.target_pose).origin,"continuous actual actor moves between endpoints")
		check(finish_calls == 0,"acceptance and partial motion never finish or land")
		var paused := actor.transform
		presenter.set_paused(true)
		presenter.tick(3.0)
		check(actor.transform == paused and finish_calls == 0,"Pause freezes actor and native completion")
		presenter.set_paused(false)
		presenter.tick(2.0)
		check(finish_calls == 1,"natural motion completes native transition exactly once")
		check(actor.position == projection(active_event.target_pose).origin,"matching commit locks exact authoritative target center")
		presenter.tick(2.0)
		check(actor.transform == projection(active_event.target_pose),"Landing settles exact cube24 Basis, origin and ONE scale")
		presenter.consume_event(active_event)
		presenter.consume_event(Fixture.committed(active_event))
		presenter.tick(3.0)
		check(finish_calls == 1 and actor.transform == projection(active_event.target_pose),"duplicate start/commit cannot replay motion or landing")
		presenter.clear()
		presenter = null
		actor.free()
	active_event = Fixture.event(false,5,30)
	actor=Node3D.new()
	root.add_child(actor)
	presenter=Presenter.new()
	presenter.bind(actor,Fall.new(),Landing.new(),projection,finish_double)
	presenter.sync_pose(active_event.source_pose)
	finish_calls=0
	presenter.consume_event(active_event)
	presenter.tick(0.35)
	var old := active_event.duplicate(true)
	presenter.clear()
	presenter.sync_pose(active_event.source_pose)
	active_event=Fixture.event(true,5,40)
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
	check(finish_calls == 0 and actor.transform == projection(active_event.source_pose),"Reset clears old motion without commit or landing")
	active_event=Fixture.event(false,5,60)
	presenter.consume_event(active_event)
	finish_calls=0
	reentrant_reset=true
	presenter.tick(3.0)
	check(finish_calls == 1 and presenter.snapshot().presentation_identity == active_event.presentation_identity,"completion observer Reset/new-start survives old cleanup")
	check(actor.position == projection(active_event.source_pose).origin,"old sampled transform not written after reentrant replacement")
	reentrant_reset=false
	presenter.clear()
	presenter=null
	actor.free()
	finish()

func finish() -> void:
	var report := {"checks":checks,"failures":failures,"fixture_kind":"PRESENTATION_CONTRACT_UNIT","authoritative_runtime":false,"doubles":["01 event DTO/Safety attestation","native finish/commit"],"authority":"Real10A samplers and00 single-writer lifecycle Unit; no legal Runtime Fall acceptance","pid":OS.get_process_id(),"user_data_dir":OS.get_user_data_dir(),"display":DisplayServer.get_name()}
	FileAccess.open(evidence.path_join("report.json"),FileAccess.WRITE).store_string(JSON.stringify(report,"\t"))
	quit(0 if failures.is_empty() else 1)
