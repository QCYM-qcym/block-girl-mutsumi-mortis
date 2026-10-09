extends "res://tests/beta_sprint/game_feel_full_slice/test_audio.gd"

func run() -> void:
	var shell: Node=load(ProjectSettings.get_setting("application/run/main_scene")).instantiate()
	root.add_child(shell);await settle(0.2)
	var rows: Array=[]
	for number in range(1,6):
		var id: String="mutsumi_l%02d"%number
		# Use the real adapter as component-test setup without changing unlock/save data.
		shell._leave_level()
		var entry: Dictionary=shell.catalog.find(id)
		shell.adapter.enter(entry);shell.current_id=id
		shell._set_state(shell.State.PLAYING);shell._render_state()
		await settle(0.3)
		var level: Node=shell.adapter.level
		var audio: Node=shell.game_feel.audio
		check(level.scene_file_path==entry.scene,"exact delivered scene identity "+id)
		check(level.presenter!=null,"current actual3D Presenter "+id)
		check(audio.snapshot().context=="exploration" and audio.snapshot().target_world==0,"Surface BGM "+id)
		var cell: Vector2i=level.mover.cell
		var orientation: String=level.mover.orientation.key()
		var count: int=audio.snapshot().cue_counts.get("world_shift",0)
		native_key(KEY_SPACE,true);await process_frame;native_key(KEY_SPACE,false)
		await settle(1.4)
		check(level.mover.world==1,"actual native World Shift "+id)
		check(level.mover.cell==cell and level.mover.orientation.key()==orientation,"Shift pose/orientation parity "+id)
		check(audio.snapshot().target_world==1 and audio.snapshot().world_blend>0.99,"Inner BGM "+id)
		check(audio.snapshot().cue_counts.get("world_shift",0)==count+1,"single11 Shift voice "+id)
		for player in level.polish.audio.ambience:
			check(player.stream_paused,"old ambience retired from playback "+id)
		shell.pause_game();await settle(0.15)
		check(audio.snapshot().paused,"actual paused audio "+id)
		shell.resume_game();await settle(0.1)
		check(not audio.snapshot().paused,"resume audio "+id)
		if number in [2,5]:
			native_key(KEY_SPACE,true);await process_frame;native_key(KEY_SPACE,false);await settle(1.1)
			check(level.mover.world==0,"return to authored Surface road "+id)
		var roll_count: int=audio.snapshot().cue_counts.get("cube_roll",0)
		# Existing authored adjacent Inner support varies by level.
		var next_key: int=KEY_A if number==4 else KEY_D if number==3 else KEY_W
		native_key(next_key,true);await process_frame;native_key(next_key,false)
		await settle(0.5)
		check(level.mover.moves==1 and level.mover.cell!=cell,"native ordinary Roll "+id)
		check(audio.snapshot().cue_counts.get("cube_roll",0)==roll_count+1,"single11 native Roll cue "+id)
		rows.append({"id":id,"world":level.mover.world,"cell":str(level.mover.cell),"orientation":level.mover.orientation.key(),"audio":audio.snapshot()})
		native_key(KEY_R,true);await process_frame;native_key(KEY_R,false);await settle(0.7)
		check(level.mover.cell==cell and level.mover.world==0 and level.mover.orientation.key()==orientation,"Reset authoritative pose "+id)
		check(audio.snapshot().target_world==0,"Reset restores Surface music "+id)
		shell.show_main_menu();await settle(0.2)
		check(shell.adapter.level==null and audio.snapshot().context=="menu","scene unload/menu "+id)
	observations={"scope":"Five actual3D scenes loaded via approved Shell API; unlock/full playthrough NOT_RERUN","rows":rows}
	shell.queue_free();await settle(0.2);finish()
