extends "res://tests/beta_sprint/spatial_formal/graphical.gd"
var inputs: Array[Dictionary] = []

func fresh_process() -> void:
	shell.new_game()
	game = shell.adapter.level
	await route_l01("input_probe")

func key(code: int, pressed: bool) -> void:
	var start := Time.get_ticks_usec()
	var before := {"cell":str(game.mover.cell),"phase":game.mover.phase,"moves":game.mover.moves,"world":game.mover.world,"view":game.view.current,"shell":shell.state}
	await super.key(code,pressed)
	inputs.append({"key":code,"pressed":pressed,"start_us":start,"return_us":Time.get_ticks_usec(),"before":before,"after":{"cell":str(game.mover.cell),"phase":game.mover.phase,"moves":game.mover.moves,"world":game.mover.world,"view":game.view.current,"shell":shell.state}})

func finish() -> void:
	FileAccess.open(evidence.path_join("input_trace.json"),FileAccess.WRITE).store_string(JSON.stringify(inputs,"\t"))
	await super.finish()
