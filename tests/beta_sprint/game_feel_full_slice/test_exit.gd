extends "res://tests/beta_sprint/ui_host_integration/test_quit.gd"

func finish() -> void:
	if phase!="seed":
		super.finish()
		return
	# The actual production Quit is the sole exit authority. The old harness
	# called quit a second time and prevented any asynchronous audio cleanup.
	FileAccess.open(evidence.path_join("unit.json"),FileAccess.WRITE).store_string(JSON.stringify({"checks":checks,"failures":failures,"doubles":[],"pid":OS.get_process_id(),"display":DisplayServer.get_name(),"user_dir":OS.get_user_data_dir(),"observations":observations},"\t"))
	FileAccess.open(evidence.path_join("seed.json"),FileAccess.WRITE).store_string(FileAccess.get_file_as_string(evidence.path_join("unit.json")))
