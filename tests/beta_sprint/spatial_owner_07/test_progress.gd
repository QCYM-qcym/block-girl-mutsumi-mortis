extends SceneTree
const Store = preload("res://game/shell/save_store.gd")
const ADAPTER := "res://experiments/spatial_puzzle_batch_01/ui/progress_adapter.gd"
const IDS: Array[StringName] = [&"world_shift_gate_lab",&"orientation_loop_lab",&"face_lock_lab",&"perspective_fork_lab",&"rubik_spatial_puzzle_01"]
var checks := 0
var failures: Array[String] = []
var evidence := ""
var save_path := ""
var phase := "progress_seed"
var fault_exercises: Array[String] = []

func _initialize() -> void:
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--evidence-dir="): evidence = arg.trim_prefix("--evidence-dir=")
		elif arg.begins_with("--shell-save="): save_path = arg.trim_prefix("--shell-save=")
		elif arg.begins_with("--phase="): phase = arg.trim_prefix("--phase=")
	call_deferred("run")

func check(ok: bool, label: String) -> void:
	checks += 1
	if not ok:
		failures.append(label)
		printerr("FAIL: ",label)

func raw_write(path: String, text: String) -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(path.get_base_dir()))
	var file := FileAccess.open(path,FileAccess.WRITE)
	file.store_string(text)
	file.close()

func block_backup() -> void:
	DirAccess.remove_absolute(save_path+".bak")
	DirAccess.make_dir_absolute(save_path+".bak")
	if "blocked backup directory" not in fault_exercises: fault_exercises.append("blocked backup directory")

func run() -> void:
	check(DisplayServer.get_name()=="headless" and save_path.begins_with("user://spatial_puzzle_batch_01/tests/") and ".." not in save_path and not evidence.is_empty(), "fresh isolated headless SaveStore service test")
	check(ResourceLoader.exists(ADAPTER), "spatial UI progress adapter exists")
	if not failures.is_empty():
		finish()
		return
	var Adapter: Script = load(ADAPTER)
	var progress = Adapter.new(IDS,save_path)
	if phase=="progress_restore":
		check(progress.continue_id()==&"face_lock_lab", "cold process Continue retains last selected level start")
		check(progress.snapshot().completed==["orientation_loop_lab","perspective_fork_lab"], "cold process restores only Goal-port completions")
		check(progress.snapshot().settings.master==0.37 and progress.snapshot().settings.muted, "unchanged version1 settings survive adapter cold restore")
		check(progress.active_id.is_empty() and not progress.dirty and not progress.snapshot().has("player"), "cold Continue is no active/mid-puzzle state")
		finish()
		return
	check(not FileAccess.file_exists(save_path) and progress.continue_id().is_empty(), "first launch has no Continue or write")
	check(progress.begin_level(IDS[0]), "real SaveStore persists level-start selection")
	check(progress.snapshot().completed.is_empty() and progress.continue_id()==IDS[0], "selection is not a Goal completion")
	var settings_store = Store.new(save_path,String(IDS[0]))
	var settings_data: Dictionary = settings_store.load_save()
	settings_data.settings.master=0.37
	settings_data.settings.muted=true
	check(settings_store.save(settings_data), "test stores existing settings through the actual SaveStore")
	progress=Adapter.new(IDS,save_path)
	check(progress.begin_level(IDS[1]), "second independent lab can be selected without completion")
	var before := FileAccess.get_file_as_string(save_path)
	check(not progress.mark_goal(IDS[0]) and FileAccess.get_file_as_string(save_path)==before, "wrong-level Goal port cannot alter persisted completion")
	check(progress.mark_goal(IDS[1]), "current active Goal port persists completion through real Store")
	check(progress.snapshot().completed==[String(IDS[1])] and progress.snapshot().settings.master==0.37, "actual Goal candidate preserves settings and records only that level")
	before=FileAccess.get_file_as_string(save_path)
	var backup_before := FileAccess.get_file_as_string(save_path+".bak")
	check(progress.mark_goal(IDS[1]) and FileAccess.get_file_as_string(save_path)==before and FileAccess.get_file_as_string(save_path+".bak")==backup_before, "duplicate Goal port is idempotent without another write")
	progress.leave_level()
	check(not progress.mark_goal(IDS[1]) and FileAccess.get_file_as_string(save_path)==before, "unloaded active scope cannot mark Goal")
	check(progress.begin_level(IDS[2]) and progress.snapshot().completed==[String(IDS[1])], "independent selection preserves completions without manufacturing another")
	before=FileAccess.get_file_as_string(save_path)
	block_backup()
	check(not progress.begin_level(IDS[3]) and progress.dirty and not progress.last_error.is_empty(), "actual blocked backup makes start fail with retryable diagnostic")
	check(FileAccess.get_file_as_string(save_path)==before and progress.continue_id()==IDS[2], "failed start preserves exact primary and prior Continue")
	DirAccess.remove_absolute(save_path+".bak")
	check(progress.retry() and progress.active_id==IDS[3] and not progress.dirty, "retry persists the same pending start exactly before activation")
	before=FileAccess.get_file_as_string(save_path)
	block_backup()
	check(not progress.mark_goal(IDS[3]) and progress.dirty, "actual reached Goal candidate remains pending on storage failure")
	check(FileAccess.get_file_as_string(save_path)==before and String(IDS[3]) not in progress.snapshot().completed, "failed Goal save leaves confirmed disk progress unchanged")
	DirAccess.remove_absolute(save_path+".bak")
	check(progress.retry() and progress.snapshot().completed==[String(IDS[1]),String(IDS[3])], "retry writes the retained Goal candidate without another gameplay event")
	check(progress.begin_level(IDS[2]) and progress.snapshot().completed.size()==2, "final cold fixture has selected start and only prior Goal completions")
	var copy: Dictionary=progress.snapshot()
	copy.completed.clear()
	check(progress.snapshot().completed.size()==2, "UI snapshot cannot mutate adapter progress")
	var unknown := save_path.get_base_dir().path_join("unknown/progress.json")
	var unknown_store = Store.new(unknown,"future_lab")
	var unknown_data: Dictionary=unknown_store.defaults()
	unknown_data.has_progress=true
	unknown_data.recent="future_lab"
	check(unknown_store.save(unknown_data), "unknown catalog fixture uses actual valid Store envelope")
	fault_exercises.append("unknown catalog file")
	var unknown_adapter=Adapter.new(IDS,unknown)
	before=FileAccess.get_file_as_string(unknown)
	check(unknown_adapter.read_only and unknown_adapter.continue_id().is_empty() and not unknown_adapter.begin_level(IDS[0]), "unknown catalog progress is protected rather than discarded")
	check(FileAccess.get_file_as_string(unknown)==before, "unknown catalog primary remains byte-identical")
	var future := save_path.get_base_dir().path_join("future/progress.json")
	var future_text := JSON.stringify({"version":99,"payload":"future","checksum":"future"})
	raw_write(future,future_text)
	fault_exercises.append("future-version file")
	var future_adapter=Adapter.new(IDS,future)
	check(future_adapter.read_only and not future_adapter.begin_level(IDS[0]) and not future_adapter.retry(), "future format blocks all downgrade writes and retry")
	check(FileAccess.get_file_as_string(future)==future_text and not FileAccess.file_exists(future+".bak"), "future primary is untouched and no new backup invented")
	var race := save_path.get_base_dir().path_join("race/progress.json")
	var race_adapter=Adapter.new(IDS,race)
	raw_write(race,future_text)
	fault_exercises.append("future file appearing after load")
	check(not race_adapter.begin_level(IDS[0]) and race_adapter.read_only and FileAccess.get_file_as_string(race)==future_text, "future file appearing after load is protected by real Store write guard")
	before=FileAccess.get_file_as_string(save_path)
	check(not progress.begin_level(&"not_a_lab") and FileAccess.get_file_as_string(save_path)==before, "unknown selection never reaches a Store write")
	check(not FileAccess.file_exists(Store.DEFAULT_PATH), "experimental adapter never writes the default legacy QA slot")
	finish()

func finish() -> void:
	var report := {"phase":phase,"checks":checks,"failures":failures,"pid":OS.get_process_id(),"engine":Engine.get_version_info(),"display":DisplayServer.get_name(),"user_data_dir":OS.get_user_data_dir(),"save_path":save_path,"evidence_type":"UNIT_REAL_SAVESTORE","store":"actual unchanged game/shell/save_store.gd","doubles":[],"goal_port_calls":"service-unit API calls only; not real Runtime Goal evidence","fault_exercises":fault_exercises,"real_runtime":"NOT_RUN","graphical":"NOT_RUN","human_qa":"NOT_RUN"}
	DirAccess.make_dir_recursive_absolute(evidence)
	var file := FileAccess.open(evidence.path_join("report.json"),FileAccess.WRITE)
	file.store_string(JSON.stringify(report,"\t"));file.close()
	print(JSON.stringify(report))
	quit(0 if failures.is_empty() else 1)
