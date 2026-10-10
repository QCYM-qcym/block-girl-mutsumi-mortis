extends SceneTree
const Facade = preload("res://foundation/game_feel/runtime_facade.gd")
const Trajectory = preload("res://foundation/game_feel/trajectory_profile.gd")
const Geometry = preload("res://foundation/spatial/surface_geometry.gd")
const Key = preload("res://foundation/contracts/state_key.gd")
const R = preload("res://foundation/contracts/contract_records.gd")
var checks := 0
var failures: Array[String] = []
var rows: Array = []
func check(ok: bool, label: String) -> void:
 checks += 1
 if not ok: failures.append(label)
func _initialize() -> void:
 create_timer(20).timeout.connect(func():printerr("AUDIT_TIMEOUT");quit(2))
 call_deferred("run")
func run() -> void:
 var input: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://.godot/game-feel-owner-01/d04_forward_audit/input.json"))
 check(FileAccess.get_file_as_string(input.factory_path).sha256_text() == input.factory_sha256,"actual external Factory equals pinned00 blob")
 var factory: Script = load(input.factory_path)
 for map in input.maps:
  var baked: Dictionary = factory.bake_game_feel(map.data)
  check(baked.ok,"actual00 Factory -> formal Baker success "+map.letter)
  if not baked.ok: rows.append(baked);continue
  var level: Dictionary = baked.level
  var initial: Dictionary = R.initial_state(level)
  var snapshot: Dictionary = Geometry.snapshot(level,initial)
  check(snapshot.ok,"actual formal Geometry snapshot")
  var source: Dictionary = snapshot.value.anchors.filter(func(a):return a.face_id==&"source/TOP")[0]
  var target: Dictionary = snapshot.value.anchors.filter(func(a):return a.face_id==&"target/TOP")[0]
  var source_cube: Dictionary = snapshot.value.cubes.filter(func(c):return c.cube_id==&"source")[0]
  var target_cube: Dictionary = snapshot.value.cubes.filter(func(c):return c.cube_id==&"target")[0]
  var connection: Dictionary = level.perspective_falls[0]
  var trajectory: Dictionary = connection.trajectory
  var source_center: Vector3 = Vector3(source.position2+source.frame.normal)*0.5
  var target_center: Vector3 = Vector3(target.position2+target.frame.normal)*0.5
  var y: int = 8 if map.letter=="b" else 0
  check(source.position2==Vector3i(0,5,0) and source.frame.normal==Vector3i.UP,"Source actual TOP anchor/frame")
  check(target.position2==Vector3i(-6,y+1,8) and target.frame.normal==Vector3i.UP and target.layer==0,"Target actual TOP anchor/frame/World")
  check(target_cube.center2==Vector3i(-6,y,8) and connection.target_face_id==&"target/TOP","profile points at real yellow support")
  check(Trajectory.sample_actor_center(trajectory,0.0).position==source_center and Trajectory.sample_actor_center(trajectory,1.0).position==target_center,"profile endpoints agree with actual actor support centers")
  check(connection.source_edge==2 and -source.frame.u==Vector3i.LEFT,"forward input is actual U_NEG/negativeX")
  var edge_x: float = float(source_cube.center2.x)*0.5-0.5
  var samples: Array = []
  for u in [0.0,0.124,0.125,0.126,0.25,0.625,1.0]:
   var sampled: Dictionary = Trajectory.sample_actor_center(trajectory,u)
   check(sampled.ok,"formal pure sample "+str(u))
   samples.append({"u":u,"actor_center":sampled.position,"centroid_strictly_outside_source":sampled.position.x<edge_x,"rear_extent_x":sampled.position.x+0.5,"fully_clear_source_open_support":sampled.position.x+0.5<=edge_x})
  check(Trajectory.sample_actor_center(trajectory,0.125).position==Vector3(-0.5,3,0) and edge_x==-0.5,"u=.125 is exact centroid boundary, not strictly beyond it")
  check(Trajectory.sample_actor_center(trajectory,0.25).position==Vector3(-1,3,0),"u=.25 has fully departed unit body before cubic descent")
  var runtime := Facade.new()
  var events: Array = []
  var starts: Array = []
  runtime.game_feel_event.connect(func(e):events.append(e))
  runtime.transition_started.connect(func(r,t,g,global):starts.append({"token":t,"generation":g,"is_global":global}))
  check(runtime.load_level(level).ok,"formal runtime loads pinned00 canonical level")
  var before: String = Key.build(level,runtime.get_state()).key
  var result: Dictionary = runtime.request_action({"kind":0,"face_axis":2})
  check(result.status==0 and result.changed and starts.size()==1 and not starts[0].is_global,"STARTED reserves one real local transition")
  var event: Dictionary = events[-1]
  check(event.schema_version==2 and event.semantic=="PERSPECTIVE_FALL_APPLIED" and event.authorized_trajectory==trajectory and event.safety_verdict.status=="SAFE","actual immutable event identifies authorized profile and Safety")
  check(runtime.get_commit_count()==0 and runtime.get_state().player.location.cube_id==&"source" and Key.build(level,runtime.get_state()).key==before,"visual departure begins with unchanged authoritative Source state")
  check(result.next_state.player.location=={"layer":0,"cube_id":&"target","face":4} and result.next_state.player.orientation==initial.player.orientation,"reserved target is correct yellow TOP/PRESERVE")
  var identity: Dictionary = event.transition_identity
  var busy: Dictionary = runtime.request_action({"kind":0,"face_axis":2})
  check(busy.status==1 and starts.size()==1 and runtime.get_commit_count()==0,"visual forward/edgeleave cannot create second native transition")
  var completed: Dictionary = runtime.finish_transition(identity)
  var landed: String = Key.build(level,runtime.get_state()).key
  check(not completed.ignored and runtime.get_commit_count()==1 and events[-1].phase=="COMMITTED" and runtime.get_state()==result.next_state,"logical captured completion commits yellow TOP exactly once")
  check(runtime.finish_transition(identity).ignored and runtime.get_commit_count()==1 and Key.build(level,runtime.get_state()).key==landed,"duplicate completion remains ignored")
  rows.append({"map":map.letter,"source_map_sha256":map.sha256,"level_hash":level.content_hash,"source_anchor":source,"target_anchor":target,"target_cube":target_cube,"source_actor_center":source_center,"target_actor_center":target_center,"source_support_edge_x":edge_x,"trajectory":trajectory,"samples":samples,"initial_statekey":before,"landing_statekey":landed,"started_identity":identity,"commit_count":runtime.get_commit_count(),"logical_result":result})
  for signal_name in ["game_feel_event","transition_started"]:
   for c in runtime.get_signal_connection_list(signal_name):runtime.disconnect(signal_name,c.callable)
 check(FileAccess.get_file_as_string(input.factory_path).sha256_text() == input.factory_sha256,"Factory bytes unchanged during audit")
 var output := {"task":"PFALL_FORWARD_THEN_DROP_TO_YELLOW_FIX_01","checks":checks,"failures":failures,"doubles":[],"authority":"pinned00 author JSON + actual unchanged00 Factory + matching formal Runtime/Geometry/Baker; completion=LOGICAL_ONLY","production_changes":"NONE","commit":input.commit,"rows":rows}
 FileAccess.open(OS.get_environment("FOUNDATION_TEST_EVIDENCE").path_join("results.json"),FileAccess.WRITE).store_string(JSON.stringify(output))
 print("FORWARD_AUDIT checks=",checks," failures=",failures)
 quit(0 if failures.is_empty() else 1)
