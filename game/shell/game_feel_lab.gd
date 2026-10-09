extends "res://experiments/game_feel_01/host/core_lab.gd"
## Adapter to the verified Core host, not another Runtime or Presenter.
func _ready() -> void:
	super._ready()
	status.hide() # Keep the verified native A/B/Reset controls; replace only debug text.
func reset_level() -> void: reset_lab()
func get_game_feel_runtime() -> Object: return runtime
func set_host_paused(value: bool) -> void:
	paused=value;runtime.set_paused(value);presenter.set_paused(value)
