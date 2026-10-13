extends SceneTree
const Host=preload("res://experiments/spatial_puzzle_batch_01/host/spatial_lab.gd")
const Maps=preload("res://experiments/spatial_puzzle_batch_01/maps/map_factory.gd")
const Key=preload("res://foundation/contracts/state_key.gd")
var rows:Array=[]
var failures:Array=[]
var host:Node
var evidence:=OS.get_environment("FOUNDATION_TEST_EVIDENCE")
func _initialize()->void: call_deferred("run")
func settle()->void:
 var deadline:=Time.get_ticks_msec()+5000
 while (not host.runtime.is_idle() or host.presenter.snapshot().phase!="IDLE") and Time.get_ticks_msec()<deadline: await process_frame
 if not host.runtime.is_idle() or host.presenter.snapshot().phase!="IDLE": failures.append("natural completion timeout")
func run()->void:
 host=Host.new();host.lab_id=&"world_shift_gate_lab";root.add_child(host);await process_frame
 if not host.runtime.is_loaded(): quit(2);return
 var source:Dictionary=host.runtime.get_level()
 var nonwalkable:Array=[]
 for cube in source.cubes:
  var walkable:=false
  for face in source.faces:
   if face.cube_id==cube.cube_id and face.walkable: walkable=true
  if not walkable: nonwalkable.append(cube)
 var witness:Array=Maps.witnesses(&"world_shift_gate_lab").solution
 for prefix_size in [2,3]:
  for quadrant in 4:
   var accepted:=0
   for entry in [["W",Vector2.UP],["A",Vector2.LEFT],["S",Vector2.DOWN],["D",Vector2.RIGHT]]:
    host.reset_lab()
    for index in prefix_size:
     var step:Dictionary=host.runtime.request_action(witness[index])
     if step.status!=0: failures.append("prefix rejected")
     await settle()
    var camera_result:Dictionary=host.runtime.request_action({"kind":9,"camera_quadrant":quadrant})
    if camera_result.status!=0: failures.append("camera rejected")
    await settle()
    var before:Dictionary=host.runtime.get_state()
    var result:Dictionary=host.runtime.request_move(entry[1])
    await settle()
    var after:Dictionary=host.runtime.get_state()
    if result.status==0 and result.changed: accepted+=1
    rows.append({"location":before.player.location,"camera":quadrant,"key":entry[0],"result":result,"before_key":Key.build(source,before).key,"after_key":Key.build(source,after).key,"idle":host.runtime.is_idle()})
    host.presenter.release_edge_intent()
   if accepted==0: failures.append("zero accepted directions: prefix %d camera %d"%[prefix_size,quadrant])
 var report:={"kind":"TECHNICAL_DIAGNOSTIC_NOT_HUMAN_QA","input":"formal request_move screen vectors; not OS keyboard injection","display":DisplayServer.get_name(),"source_hash":source.content_hash,"rows":rows,"failures":failures,"nonwalkable_cubes":nonwalkable,"host_issues":host.host_issues.duplicate(true)}
 host.free();await process_frame
 FileAccess.open(evidence.path_join("report.json"),FileAccess.WRITE).store_string(JSON.stringify(report,"\t"))
 quit(0 if failures.is_empty() else 1)
