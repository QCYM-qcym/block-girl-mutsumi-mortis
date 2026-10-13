extends "res://tests/beta_sprint/spatial_owner_07/test_menu.gd"
const Maps=preload("res://experiments/spatial_puzzle_batch_01/maps/map_factory.gd")
const Key=preload("res://foundation/contracts/state_key.gd")
func idle()->void:
 var limit:=Time.get_ticks_msec()+5000
 while (not ui.lab.runtime.is_idle() or ui.lab.presenter.snapshot().phase!="IDLE") and Time.get_ticks_msec()<limit: await process_frame
 check(ui.lab.runtime.is_idle() and ui.lab.presenter.snapshot().phase=="IDLE","real natural completion settles")
func run()->void:
 check(DisplayServer.get_name()==expected_display,"requested real display")
 check(save_path.begins_with("user://spatial_puzzle_batch_01/tests/"),"isolated test save")
 if not failures.is_empty(): await finish();return
 root.content_scale_size=Vector2i.ZERO
 root.content_scale_mode=Window.CONTENT_SCALE_MODE_DISABLED
 root.size=Vector2i(1280,720)
 ui=load(MAIN).instantiate();ui.save_path=save_path;root.add_child(ui);await settle()
 await choose(&"world_shift_gate_lab")
 check(is_instance_valid(ui.lab),"real menu mouse entry")
 if not is_instance_valid(ui.lab): await finish();return
 for prefix_size in [0,1,2,3]:
  for quadrant in 4:
   var accepted:=0
   var axes:Array=[]
   for code in [KEY_W,KEY_A,KEY_S,KEY_D]:
    await key(KEY_R);await idle()
    var actions:Array=Maps.witnesses(&"world_shift_gate_lab").solution
    for i in prefix_size:
     var result:Dictionary=ui.lab.runtime.request_action(actions[i]);check(result.status==0,"canonical setup prefix accepted");await idle()
    var camera:Dictionary=ui.lab.runtime.request_action({"kind":9,"camera_quadrant":quadrant});check(camera.status==0,"formal camera accepted");await idle()
    var before:Dictionary=ui.lab.runtime.get_state()
    var old_key:String=Key.build(ui.lab.runtime.get_level(),before).key
    var count:int=ui.lab.events.size()
    await key(code);await idle()
    var events:Array=[]
    for index in range(count,ui.lab.events.size()):
     var event:Dictionary=ui.lab.events[index]
     if event.result.action.get("kind")==0 and event.phase in ["STARTED","FEEDBACK","REJECTED"]: events.append(event)
    check(events.size()==1,"one real keyboard event produces one move result")
    if events.is_empty(): continue
    var result:Dictionary=events[0].result
    axes.append(result.action.face_axis)
    var after:Dictionary=ui.lab.runtime.get_state()
    var changed:bool=old_key!=Key.build(ui.lab.runtime.get_level(),after).key
    if result.status==0 and result.changed: accepted+=1;check(changed,"accepted move commits new key")
    else: check(not changed,"rejected edge preserves key")
    observations.append({"key":OS.get_keycode_string(code),"camera":quadrant,"location":before.player.location,"result":result,"state_changed":changed})
   axes.sort()
   check(axes==[0,1,2,3],"WASD exposes all four distinct axes at quadrant %d"%quadrant)
   check(accepted>0,"Current platform has reachable keyboard move at quadrant %d"%quadrant)
   await capture("gate_%d_prefix%d"%[quadrant,prefix_size])
 await click(ui.return_button)
 check(ui.lab==null and ui.menu_panel.visible,"return to actual menu")
 await finish()
func finish()->void:
 var report:Dictionary={"checks":checks,"failures":failures,"doubles":[],"display":DisplayServer.get_name(),"renderer":RenderingServer.get_current_rendering_method(),"observations":observations,"captures":captures,"input":"Input.parse_input_event keyboard and menu mouse; formal action prefix only for positioning; natural Presenter, no manual finish","human_qa":"NOT_RUN","graphical":"NOT_RUN" if expected_display=="headless" else "AUTOMATED_RENDERER"}
 FileAccess.open(evidence.path_join("report.json"),FileAccess.WRITE).store_string(JSON.stringify(report,"\t"))
 if is_instance_valid(ui): ui.queue_free()
 await settle();await create_timer(0.2).timeout
 quit(0 if failures.is_empty() else 1)
