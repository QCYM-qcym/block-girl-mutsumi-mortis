extends "res://tests/beta_sprint/game_feel_full_slice/test_matrix.gd"
## Same real Shell checks, with an explicit foreground precondition and focus ledger.
## Never changes Shell pause, Runtime state, animation, or completion.
var focus_rows:Array=[]

func _initialize()->void:
	super._initialize()
	root.focus_entered.connect(func(): observe_focus("WINDOW_FOCUS_IN"))
	root.focus_exited.connect(func(): observe_focus("WINDOW_FOCUS_OUT"))

func observe_focus(label:String)->void:
	var shells:Array=[]
	for child in root.get_children():
		if child.has_method("pause_game"):
			var bridge:Node=child.game_feel
			var lab:Node=child.adapter.level
			var actual_lab:bool=lab!=null and lab.has_method("reset_lab")
			shells.append({"state":child.state,"audio_paused":bridge.audio.snapshot().paused,
				"presenter":lab.presenter.snapshot() if actual_lab else {},
				"events":lab.events.duplicate(true) if actual_lab else []})
	focus_rows.append({"time_msec":Time.get_ticks_msec(),"label":label,"focused":root.has_focus(),"shells":shells})

func key(code:int)->void:
	observe_focus("key_before_"+str(code))
	if not root.has_focus():
		root.grab_focus()
		await process_frame
		check(root.has_focus(),"real foreground precondition before native key")
	await super.key(code)
	observe_focus("key_after_"+str(code))

func press(code:int,down:bool=true,echo:bool=false)->void:
	if not root.has_focus(): root.grab_focus()
	observe_focus("press_"+str(code)+"_"+str(down)+"_"+str(echo))
	super.press(code,down,echo)

func capture(label:String)->void:
	observe_focus("capture_"+label)
	await super.capture(label)

func finish()->void:
	observations["focus_evidence"]=focus_rows
	super.finish()
