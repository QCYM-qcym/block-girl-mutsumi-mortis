extends SceneTree
## One-time baseline capture. Requires the pre-migration factory at 088d4ba.
const Factory=preload("res://experiments/spatial_puzzle_batch_01/maps/map_factory.gd")
const Session=preload("res://foundation/runtime/runtime_session.gd")
const Key=preload("res://foundation/contracts/state_key.gd")
var failures:Array=[]
func _initialize()->void:call_deferred("run")
func run()->void:
	var out:String=OS.get_cmdline_user_args()[0]
	var directory:String="res://tests/beta_sprint/spatial_owner_09/migration_baseline"
	if DirAccess.dir_exists_absolute(directory):
		push_error("Frozen baseline exists; refusing to overwrite")
		quit(1);return
	DirAccess.make_dir_recursive_absolute(directory)
	for id in Factory.ids():
		var bake:Dictionary=Factory.bake(id)
		if not bake.ok:
			failures.append(String(id));continue
		var traces:Dictionary={}
		for label in Factory.witnesses(id):
			var session=Session.new()
			var tokens:Array=[]
			session.transition_started.connect(func(_r,i,g,b):tokens.append([i,g,b]))
			session.load_level(bake.level)
			var trace:Array=[{"state":session.state.duplicate(true),"key":Key.build(bake.level,session.state).key}]
			for action in Factory.witnesses(id)[label]:
				var response:Dictionary=session.request_action(action)
				if response.status!=0:failures.append(String(id)+"/"+label)
				if response.status==0 and response.changed:
					var token:Array=tokens[-1]
					if token[2]:session.finish_global(token[0],token[1])
					else:session.finish_local(token[0],token[1])
				trace.append({"action":action,"status":response.status,"state":session.state.duplicate(true),"key":Key.build(bake.level,session.state).key})
			traces[label]=trace
		FileAccess.open(directory.path_join(String(id)+".gdvar"),FileAccess.WRITE).store_string(var_to_str({"level":bake.level,"traces":traces})+"\n")
	FileAccess.open(out.path_join("report.json"),FileAccess.WRITE).store_string(JSON.stringify({"checks":5,"failures":failures,"source_head":"088d4ba815884a431f44e73d93cfb6881ff7faa3"},"\t"))
	quit(0 if failures.is_empty() else 1)
