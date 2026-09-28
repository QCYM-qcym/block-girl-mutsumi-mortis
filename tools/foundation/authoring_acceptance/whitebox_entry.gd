extends SceneTree
## Manual graphical entry for an existing sealed D2 run. It never captures,
## interprets or rebakes authoring data; it accepts only same-run Bake outputs.
const S = preload("res://tools/foundation/authoring_acceptance/wire_schemas.gd")
const Execution = preload("res://tools/foundation/authoring_acceptance/execution_project.gd")
const Loader = preload("res://tools/foundation/authoring_acceptance/canonical_loader.gd")
const HostScene = preload("res://tools/foundation/authoring_acceptance/whitebox_host.tscn")

func _initialize() -> void:
	call_deferred("_start")

func _start() -> void:
	var arguments := _options(OS.get_cmdline_user_args())
	if not arguments.ok:
		_fail("Exactly --run-dir=<absolute E-drive run directory> is required")
		return
	var run_root: String = arguments.value
	var validated: Dictionary = Loader.new().load_run(run_root)
	if not validated.ok:
		_fail("Formal saved-run BAKE publication is missing or invalid")
		return
	var context := execution_context(run_root,validated.value.run_identity)
	if not context.ok:
		_fail(context.issues[0].message)
		return
	var host = HostScene.instantiate()
	root.add_child(host)
	var loaded: Dictionary = host.load_run(run_root)
	if not loaded.ok:
		printerr("D_HOST_LOAD_FAILED ",loaded.issues)
		quit(1)
		return
	print("D_HOST_READY ",JSON.stringify({"snapshot_id":loaded.value.run_identity.snapshot_id,
		"loaded_hash":host.loaded_hash(),"canonical_digest":loaded.value.canonical_digest,
		"controls":"WASD move, Q/E rotate, Space shift, F use transition, R reset"}))

static func _options(values: PackedStringArray) -> Dictionary:
	if values.size() != 1 or not values[0].begins_with("--run-dir="):
		return S.failure("ENTRY_ARGUMENT_INVALID", "Only --run-dir is supported")
	var path := values[0].substr(10).replace("\\","/")
	if not Execution.safe_path(path): return S.failure("PATH_INVALID", "Run directory must be a canonical E-drive path")
	return S.success(path)

static func execution_context(run_root: String, identity: Dictionary) -> Dictionary:
	# This is deliberately not satisfied by a source-staging graphical test.
	# The final entry must run inside the materialized project with D3 in its
	# sealed VersionsRecord; D2 will deliver the scene/resource closure support.
	if not S.identity_shape(identity): return S.failure("IDENTITY_INVALID", "Invalid execution identity")
	var modules := {}
	for module in identity.versions.modules: modules[module.path] = module
	for path in ["res://tools/foundation/authoring_acceptance/whitebox_entry.gd","res://tools/foundation/authoring_acceptance/whitebox_host.gd","res://tools/foundation/authoring_acceptance/canonical_loader.gd","res://tools/foundation/authoring_acceptance/whitebox_host.tscn"]:
		if not modules.has(path): return S.failure("DEPENDENCY_PENDING", "UPDATED_D_SAVED_EXECUTION_CLOSURE")
	var actual_root := ProjectSettings.globalize_path("res://").replace("\\","/").trim_suffix("/")
	if actual_root != run_root.path_join("execution/project"):
		return S.failure("EXECUTION_VERSION_MISMATCH", "Entry must start from this run's controlled execution/project")
	return S.success(null)

func _fail(message: String) -> void:
	printerr("D_HOST_ENTRY_REJECTED ",message)
	quit(2)
