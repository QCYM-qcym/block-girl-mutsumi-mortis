extends SceneTree
const F = preload("res://experiments/game_feel_01/maps/map_factory.gd")
const Base = preload("res://tests/foundation/level/baker_fixture.gd")
const Geometry = preload("res://foundation/spatial/surface_geometry.gd")
const Baker = preload("res://foundation/level/level_baker.gd")
const Records = preload("res://foundation/contracts/contract_records.gd")
var checks := 0
var failures: Array = []
func _initialize() -> void:
	call_deferred("run")
func check(ok: bool,label: String) -> void:
	checks+=1
	if not ok: failures.append(label)
func run() -> void:
	var output := ""
	var profile := ""
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--evidence="): output=arg.trim_prefix("--evidence=")
		if arg.begins_with("--profile="): profile=arg.trim_prefix("--profile=")
	if output.is_empty() or profile.is_empty():
		quit(2)
		return
	check(OS.get_user_data_dir().replace("\\","/").begins_with(profile.replace("\\","/")+"/"),"isolated profile")
	var proposal: Dictionary = F.spec("res://experiments/game_feel_01/maps/yellow_target_proposal.json")
	var rows: Array = []
	for letter in ["a","b"]:
		var current: Dictionary = F.read_spec(letter)
		var plan: Dictionary = proposal.maps[letter]
		check(F.vector(current.target_center2)==F.vector(plan.target_center2),letter+" actual Fall target must bind existing yellow location")
		check(F.vector(current.exit_center2)==F.vector(plan.exit_center2),"actual exit at approved new position")
		var author: Dictionary = F.authoring(current)
		var baked: Dictionary = Baker.bake(author,{"max_configurations":4096,"max_checks":100000})
		check(baked.ok,"production geometry real Baker valid")
		check(author.cubes.size()==4 and author.cubes.any(func(c):return c.cube_id==&"blue_reference" and c.center2==F.vector(plan.reference_center2)),"original blue structure is a real visible cube")
		var anchors: Array = Geometry.snapshot(baked.level,Records.initial_state(baked.level)).value.anchors
		var target: Dictionary = {}
		var exit_anchor: Dictionary = {}
		for a in anchors:
			if a.face_id==&"target/TOP": target=a
			if a.face_id==&"exit/TOP": exit_anchor=a
		check(target.position2==F.vector(plan.target_anchor2),"production target Anchor")
		check(exit_anchor.position2==target.position2+2*target.frame.u,"production exit formal U_POS adjacency")
		check(baked.level.faces.filter(func(f):return f.cube_id==&"blue_reference" and f.walkable).is_empty(),"reference has no walkable landing face")
		rows.append({"map":letter,"actual_target_center2":current.target_center2,"approved_geometry":plan,"production_bake_hash":baked.level.content_hash,"target_anchor":target,"exit_anchor":exit_anchor,"scope":"production v1 geometry; not curve Safety"})
	FileAccess.open(output.path_join("report.json"),FileAccess.WRITE).store_string(JSON.stringify({"checks":checks,"failures":failures,"rows":rows,"doubles":[],"user_data_dir":OS.get_user_data_dir(),"pid":OS.get_process_id(),"fall_safety":"PENDING","input":"direct Baker/Geometry; no graphics or Runtime Fall"},"\t"))
	print("YELLOW PROPOSAL checks=",checks," failures=",failures)
	quit(0 if failures.is_empty() else 1)
