extends SceneTree
## Controlled author INPUT variants, through the real public 09 Baker and 01 Facade.
const Maps = preload("res://experiments/game_feel_01/maps/map_factory.gd")
const Baker = preload("res://foundation/level/level_baker.gd")
const Facade = preload("res://foundation/game_feel/runtime_facade.gd")
const Key = preload("res://foundation/contracts/state_key.gd")
var evidence := ""
var checks := 0
var failures: Array[String] = []
var rows: Array = []
func _initialize() -> void:
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--evidence="): evidence = arg.trim_prefix("--evidence=")
	call_deferred("run")
func check(ok: bool, label: String) -> void:
	checks += 1
	if not ok: failures.append(label)
func run() -> void:
	for letter in ["a", "b"]:
		for layer in [0, 1]:
			for restricted in [false, true]:
				var data := Maps.read_spec(letter).duplicate(true)
				data.id = "quality_permission_" + letter + "_" + str(layer) + "_" + str(restricted)
				data.source_layer = layer
				data.target_layer = layer
				var author := Maps.opt_in_authoring_candidate(data)
				if restricted:
					author.worlds[layer].allowed_states = [0, 22]
					author.perspective_falls[0].allowed_world_orientations = [22]
				var baked := Baker.bake(author, {"max_configurations": 4096, "max_checks": 100000})
				check(baked.ok, "formal Baker admits explicit author permission variant")
				if not baked.ok: continue
				var runtime := Facade.new()
				var events: Array = []
				runtime.game_feel_event.connect(func(event): events.append(event))
				check(runtime.load_level(baked.level).ok, "real default Facade admits canonical variant")
				var before := runtime.get_state()
				var source_key: String = Key.build(baked.level, before).key
				var result := runtime.request_action({"kind": 8, "connection_id": StringName("pfall_" + letter)})
				if restricted:
					check(result.status == 1 and not result.changed and result.rejection_code == 2102 and result.next_state == null, "formal authored World orientation restriction rejects")
					check(runtime.get_state() == before and runtime.get_commit_count() == 0 and Key.build(baked.level, runtime.get_state()).key == source_key, "permission rejection preserves full actual state/key")
					check(events.size() == 1 and events[0].reason_category == "WORLD_NOT_ALLOWED", "same formal permission reason in Surface and Inner")
				else:
					check(result.status == 0 and result.changed and runtime.get_state() == before and runtime.get_commit_count() == 0, "authorized same-World Fall proposes without early commit")
					if result.status == 0 and result.changed:
						check(not runtime.finish_transition(events[-1].transition_identity).ignored, "explicit LOGICAL_SESSION native completion; no graphical claim")
						check(runtime.get_state() == result.next_state and runtime.get_commit_count() == 1 and runtime.get_state().player.location.layer == layer and runtime.get_state().player.orientation == before.player.orientation, "authorized Surface/Inner endpoint exactly matches formal proposal")
				rows.append({"map_variant_of": letter, "layer": layer, "restricted": restricted, "level_hash": baked.level.content_hash,
					"author_input": data, "allowed_world_orientations": author.perspective_falls[0].allowed_world_orientations,
					"before": before, "after": runtime.get_state(), "result": result, "events": events,
					"scope": "CONTROLLED_AUTHOR_INPUT_VARIANT; not registered 09 Map A/B artifact; real LOGICAL_SESSION completion, no natural Presenter or formal graphical replay"})
	FileAccess.open(evidence.path_join("report.json"), FileAccess.WRITE).store_string(JSON.stringify({"checks": checks, "failures": failures,
		"rows": rows, "doubles": [], "pid": OS.get_process_id(), "display": DisplayServer.get_name(), "user_data_dir": OS.get_user_data_dir(),
		"authority": "real public Baker/default Facade; explicit layer and authored permission inputs; no copied algorithms"}, "\t"))
	quit(0 if failures.is_empty() else 1)
