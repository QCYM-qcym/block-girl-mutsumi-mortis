extends Node
## Test-only observer scene. The sealed production entry owns the SceneTree,
## loader and Host. This node never constructs a Session or a product artifact.
const HostType = preload("res://tools/foundation/authoring_acceptance/whitebox_host.gd")
const Types = preload("res://foundation/contracts/foundation_types.gd")
const Wire = preload("res://tools/foundation/authoring_acceptance/tool_wire.gd")
const Loader = preload("res://tools/foundation/authoring_acceptance/canonical_loader.gd")
const Entry = preload("res://tools/foundation/authoring_acceptance/whitebox_entry.gd")
var checks := 0
var failures: Array[String] = []
var transitions: Array = []
var host: Variant
var initial_key := ""
var loaded_hash := ""
var reset_pass := false
var late_callbacks: Dictionary = {}

func _ready() -> void:
	call_deferred("_run")

func check(condition: bool, label: String) -> void:
	checks += 1
	if not condition: failures.append(label)

func _run() -> void:
	var tree := get_tree()
	var run_dir := OS.get_environment("D3_FINAL_RUN")
	var expected: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(OS.get_environment("D3_CURRENT_HANDOFF")))
	check(DisplayServer.get_name() != "headless","real Graphical display")
	check(tree.get_script() == Entry,"actual SceneTree is the sealed whitebox_entry, not a substitute driver")
	check(ProjectSettings.globalize_path("res://").trim_suffix("/") == run_dir.path_join("execution/project"),"process resource root is the exact current controlled execution project")
	check(OS.get_cmdline_user_args() == PackedStringArray(["--run-dir="+run_dir]),"production entry receives only its approved run-dir option")
	var deadline := Time.get_ticks_msec()+10000
	while host == null and Time.get_ticks_msec()<deadline:
		for child in tree.root.get_children():
			if child.get_script()==HostType: host=child
		if host==null: await tree.process_frame
	check(host!=null and host.is_ready(),"formal entry installed its own real Host")
	if host==null or not host.is_ready():
		_finish()
		return
	loaded_hash=host.loaded_hash()
	check(loaded_hash==expected.content_hash,"loaded canonical content hash equals current D_SAVED handoff")
	var loaded: Dictionary = Loader.new().load_run(run_dir)
	check(loaded.ok,"formal loader independently verifies the same published BAKE")
	if not loaded.ok:
		_finish()
		return
	check(loaded.value.run_identity.run_id==expected.run_id,"full run identity is the current pinned final run")
	check(loaded.value.run_identity.snapshot_id==expected.snapshot_id,"snapshot identity equals current D_SAVED")
	check(loaded.value.run_identity.source_fingerprint==expected.source_fingerprint,"source fingerprint equals current D_SAVED")
	check(loaded.value.run_identity.execution_digest==expected.execution_digest,"execution digest equals current D_SAVED")
	check(loaded.value.input_refs.bake_stage_result.sha256==expected.artifacts[Loader.BAKE_STAGE_PATH][1],"consumer uses the current formal BAKE ArtifactRef")
	check(expected.source_intent_digest!=null and loaded.value.snapshot_identity.source_intent_digest==expected.source_intent_digest,"controlled loader preserves explicit empty Intent digest exactly")
	check(Entry.execution_context(run_dir,loaded.value.run_identity).ok,"entry execution-context binding accepts controlled project")
	initial_key=host.current_state_key().key
	check(not initial_key.is_empty() and host.commit_count()==0,"initial StateKey and commit count observed")
	_reflection_boundary()
	var local: Dictionary = await _transition({"kind":Types.PuzzleActionKind.MOVE,"face_axis":0},false,"LOCAL")
	_late_callbacks(local,"LOCAL")
	var reset: Dictionary = host.reset_run()
	check(reset.ok and host.current_state_key().key==initial_key,"official reset_run restores exact initial StateKey")
	check(host.commit_count()==0,"official Reset restores commit counter")
	check(host.runtime_observation().generation>local.get("generation",0),"Reset advances Session generation")
	reset_pass=reset.ok and host.current_state_key().key==initial_key and host.commit_count()==0 and host.runtime_observation().generation>local.get("generation",0)
	var global: Dictionary = await _transition({"kind":Types.PuzzleActionKind.ROTATE_INNER,"rotation_delta":22},true,"GLOBAL",local)
	_late_callbacks(global,"GLOBAL")
	_rejection_and_loading_negatives(run_dir)
	_finish()

func _transition(action: Dictionary, is_global: bool, label: String, previous: Dictionary = {}) -> Dictionary:
	var before: String = host.current_state_key().key
	var count_before: int = host.commit_count()
	var starts_before: int = host.runtime_observation().transition_starts
	var action_index: int = host.action_records().size()
	var result: Dictionary = host.submit_action(action)
	check(result.get("status",-1)==0,label+" formal action is APPLIED")
	check(host.has_active_transition(),label+" transition_started created an active ticket")
	check(host.runtime_observation().transition_starts==starts_before+1,label+" exactly one transition_started observed")
	var ticket: Dictionary = host.transition_status()
	check(ticket.get("is_global",not is_global)==is_global,label+" is_global selects the formal completion route")
	check(ticket.get("token",0)>0 and ticket.get("generation",0)>0,label+" real token and generation recorded")
	check(host.commit_count()==count_before and host.current_state_key().key==before,label+" proposal does not precommit logical state")
	var tween_inventory := get_tree().get_processed_tweens()
	print("D3_TWEEN_INVENTORY ",label," ",tween_inventory.map(func(tween): return {"valid":tween.is_valid(),"running":tween.is_running()}))
	var tweens := tween_inventory.filter(func(tween): return tween.is_valid() and tween.is_running())
	check(tweens.size()==1 and tweens[0].is_running(),label+" actual Presenter Tween is running")
	if ticket.is_empty() or tweens.size()!=1:
		return ticket
	var finished := [false]
	tweens[0].finished.connect(func(): finished[0]=true,CONNECT_ONE_SHOT)
	var observed_frames := 0
	var busy: Dictionary = host.submit_action({"kind":Types.PuzzleActionKind.MOVE,"face_axis":0})
	check(not busy.get("ok",true) and not busy.has("status") and busy.issues[0].code=="HOST_BUSY",label+" concurrent input is gated without invented Runtime status")
	check(host.action_records().size()==action_index+1,label+" busy admission creates no false runtime action record")
	if not previous.is_empty():
		var current_ticket: Dictionary = host.transition_status()
		host.on_visual_finished(previous.token,previous.generation,false)
		check(host.transition_status()==current_ticket and host.commit_count()==count_before,"LOCAL late callback cannot overwrite the following GLOBAL ticket")
	var deadline := Time.get_ticks_msec()+10000
	while host.has_active_transition() and Time.get_ticks_msec()<deadline:
		observed_frames+=1
		await get_tree().process_frame
	check(not host.has_active_transition(),label+" completion reaches idle before watchdog")
	check(finished[0],label+" real Tween.finished signal observed without seek, sleep-success or manual finish")
	check(observed_frames>0,label+" visual transition spans real SceneTree frames")
	check(host.commit_count()-count_before==1,label+" natural completion commits exactly once")
	var after: String = host.current_state_key().key
	check(after!=before,label+" committed StateKey changes")
	var record: Dictionary = host.action_records()[action_index]
	check(record.completion is Dictionary and not record.completion.get("ignored",true),label+" official Session completion accepted its token")
	check(record.after_statekey==after and record.commit_count==host.commit_count(),label+" action evidence matches committed endpoint")
	check(host.runtime_observation().visual_issues.is_empty(),label+" Presenter reports no issues")
	check(host.loaded_hash()==loaded_hash,label+" loaded canonical hash remains stable")
	var evidence := {"kind":label,"action":action,"status":result.get("status",-1),"transition_started":host.runtime_observation().transition_starts==starts_before+1,"is_global":is_global,"token":ticket.token,"generation":ticket.generation,"before_statekey":before,"after_statekey":after,"before_commit_count":count_before,"after_commit_count":host.commit_count(),"commit_delta":host.commit_count()-count_before,"natural_finished":finished[0],"observed_frames":observed_frames,"completion":record.completion}
	transitions.append(evidence)
	return ticket

func _late_callbacks(ticket: Dictionary, label: String) -> void:
	if ticket.is_empty(): return
	var before: String = host.current_state_key().key
	var count_before: int = host.commit_count()
	var ignored_before: int = host.runtime_observation().ignored_visual_callbacks
	host.on_visual_finished(ticket.token,ticket.generation,ticket.is_global)
	host.on_visual_finished(ticket.token,ticket.generation-1,ticket.is_global)
	host.on_visual_finished(ticket.token,ticket.generation,ticket.is_global)
	check(host.runtime_observation().ignored_visual_callbacks==ignored_before+3,label+" old token, old generation and duplicate callback ignored")
	check(host.commit_count()==count_before,label+" late callbacks do not increment commit count")
	check(host.current_state_key().key==before,label+" late callbacks do not change StateKey")
	late_callbacks[label]=host.runtime_observation().ignored_visual_callbacks==ignored_before+3 and host.commit_count()==count_before and host.current_state_key().key==before

func _reflection_boundary() -> void:
	check(host.get("session")==null,"Host has no exposed Session property")
	var exposed := false
	for property in host.get_property_list():
		var value: Variant = host.get(property.name)
		if value is RefCounted and not value is Script:
			if value.get_script()==HostType.Session or value.get_script()==preload("res://foundation/runtime/kernel_port.gd"): exposed=true
	check(not exposed,"Host reflection exposes neither RuntimeSession nor Kernel")
	var capabilities: Dictionary = host.get("_runtime")
	var keys: Array = capabilities.keys()
	keys.sort()
	check(capabilities.is_read_only() and keys==["action","close","input_frame","observe","reset"],"only fixed capabilities, no finish or general mutation dispatcher")
	var observed: Dictionary = capabilities.observe.call()
	observed.state.clear()
	observed.level.clear()
	var frame: Dictionary = capabilities.input_frame.call()
	frame.clear()
	check(host.current_state_key().key==initial_key and not capabilities.input_frame.call().is_empty(),"state, level and input-frame observations are detached copies")
	check(host.get_children().all(func(child): return child.get_script()!=HostType.Presenter),"public child list does not return internal Presenter")

func _rejection_and_loading_negatives(run_dir: String) -> void:
	check(host.reset_run().ok,"Reset before illegal-action regression succeeds")
	var before: String = host.current_state_key().key
	var count_before: int = host.commit_count()
	for action in [{"kind":Types.PuzzleActionKind.ROTATE_SURFACE,"rotation_delta":22},{"kind":Types.PuzzleActionKind.USE_FACE_TRANSITION,"transition_id":&"missing_transition"}]:
		var result: Dictionary = host.submit_action(action)
		check(result.get("status",-1) in [1,2],"explicit illegal action is rejected or errors through real Session")
		check(not host.has_active_transition(),"illegal action creates no visual transition")
		check(host.current_state_key().key==before and host.commit_count()==count_before,"illegal action keeps state and commits unchanged")
	var records: Array = host.action_records()
	var size_before: int = records.size()
	records.clear()
	var last: Dictionary = host.last_result()
	last.clear()
	check(host.action_records().size()==size_before and not host.last_result().is_empty(),"action records and result observations do not alias Host state")
	var retained: Dictionary = host.get("_runtime")
	var failed: Dictionary = host.load_run(run_dir.path_join("missing"))
	check(not failed.ok and not host.is_ready() and host.loaded_hash().is_empty(),"invalid run clears previous Session and loaded hash")
	check(retained.observe.call().is_empty(),"failed load revokes retained observation capability")
	var revoked: Dictionary = retained.action.call({"kind":Types.PuzzleActionKind.MOVE,"face_axis":0})
	check(not revoked.get("ok",true) and not revoked.has("status"),"failed load revokes retained action capability")
	check(host.load_run(run_dir).ok and host.loaded_hash()==loaded_hash,"recovery reloads only the same immutable current run")
	check(not Loader.new().has_method("decode_bake_receipt"),"JSON sidecar is not a product loader interface")

func _finish() -> void:
	var result := {"checks":checks,"failures":failures,"doubles":[],"display":DisplayServer.get_name(),"pid":OS.get_process_id(),"entry_script":get_tree().get_script().resource_path,"project":ProjectSettings.globalize_path("res://"),"run_dir":OS.get_environment("D3_FINAL_RUN"),"loaded_hash":loaded_hash,"transitions":transitions,"reset_pass":reset_pass,"late_callbacks":late_callbacks}
	var file := FileAccess.open(OS.get_environment("D3_FINAL_EVIDENCE").path_join("observer-results.json"),FileAccess.WRITE)
	file.store_string(JSON.stringify(result,"\t"))
	file.close()
	get_tree().quit(0 if failures.is_empty() else 1)
