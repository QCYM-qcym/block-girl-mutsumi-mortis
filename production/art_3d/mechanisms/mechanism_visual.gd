extends Node3D
@export var manifest_path:String
var manifest={}
var state_id=""
var parts={}
var base_positions={}
var preview_phase=0.0
func _ready():
	manifest=JSON.parse_string(FileAccess.get_file_as_string(manifest_path))
	for name_ in ["Plate","GateLeft","GateRight","Carrier","Dial","SwitchA","SwitchB","Glow","SurfaceMotif","InnerMotif","SharedMotif","PathSymbols"]:
		var n=get_node("Visual").find_child(name_,true,false)
		if n:parts[name_]=n;base_positions[name_]=n.position
	set_visual_state(manifest.state_contract.initial_state,0.0)

func set_visual_state(id:String,phase:float=1.0,travel:Vector3=Vector3.ZERO,angle:float=0.0):
	assert(id in manifest.state_contract.state_ids,"Unknown mechanism state "+id)
	state_id=id;preview_phase=clampf(phase,0,1)
	for n in get_node("StateViews").get_children():n.visible=n.name==id
	for name_ in parts:parts[name_].position=base_positions[name_];parts[name_].rotation=Vector3.ZERO
	var kind=manifest.mechanism_type
	if kind=="pressure_plate":parts.Plate.position.y-=.032*(0 if id=="inactive" else 1)
	if kind=="gate":
		var f=0.0 if id=="closed" else 1.0 if id=="open" else preview_phase
		parts.GateLeft.position.x-=.84*f;parts.GateRight.position.x+=.84*f
	if kind=="moving_platform":parts.Carrier.position+=travel
	if kind=="rotating_platform":parts.Dial.rotation.y=angle
	if kind=="world_switch":
		var f=preview_phase if id=="switching" else 1.0 if id=="completed" else 0.0
		parts.SwitchA.rotation.y=f*PI*.5;parts.SwitchB.rotation.y=-f*PI*.5
	if kind=="path_marker":
		parts.SurfaceMotif.visible=id=="surface_only";parts.InnerMotif.visible=id=="inner_only";parts.SharedMotif.visible=id=="shared";parts.PathSymbols.visible=id!="inactive"
	if parts.has("Glow"):
		parts.Glow.visible=id not in ["inactive","locked","idle"]
		if id in ["activated","complete","triggered","completed"]:parts.Glow.scale=Vector3(1.08,1.08,1.08)
		else:parts.Glow.scale=Vector3.ONE
		if kind=="exit":
			var streams=parts.Glow.get_children()
			for i in range(streams.size()):streams[i].visible=id=="complete" or (id=="activated" and i!=2) or (id=="available" and i==1)
		if kind=="pressure_plate":parts.Glow.position.y-=.032 if id!="inactive" else 0.0;parts.Glow.visible=id=="activated"
		if kind=="reset_marker":parts.Glow.rotation.z=-PI*.3 if id=="triggered" else 0.0

func state_contract(id):
	for row in manifest.states:
		if row.id==id:return row
	return {}
