extends RefCounted
## Existing category gains remain calibrated; Music currently controls Ambience.
const BUS_MAP := {"master": "Master", "music": "Ambience", "sfx": "SFX"}
const BASE_DB := {"master": 0.0, "music": -12.0, "sfx": -6.0}

static func apply(values: Dictionary, window: Window) -> void:
	for key in BUS_MAP:
		var index := AudioServer.get_bus_index(BUS_MAP[key])
		if index < 0:
			continue
		var amount: float = values[key]
		AudioServer.set_bus_volume_db(index, linear_to_db(maxf(amount, 0.0001)) + BASE_DB[key])
		AudioServer.set_bus_mute(index, amount <= 0 or (key == "master" and values.get("muted", false)))
	if DisplayServer.get_name() != "headless":
		window.mode = Window.MODE_FULLSCREEN if values.fullscreen else Window.MODE_WINDOWED
