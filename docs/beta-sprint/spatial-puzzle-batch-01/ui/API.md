# Spatial experiment Menu API

Entry: `res://experiments/spatial_puzzle_batch_01/ui/main.tscn`; script `main.gd`. Coordinator owns project.godot/F5 integration. Default progress: `user://spatial_puzzle_batch_01/progress.json`, through unchanged `game/shell/save_store.gd`.

Actual Owner09 Factory supplies `ids()`, `describe(id)` and Baker availability; five entries are independent. UI constructs actual Owner00 Host, assigns `lab_id` before add_child, and connects `menu_requested` / `goal_reached(level_id)` with captured-node guards. Host owns WASD/F/QE/Space/Esc/H and formal state. UI calls only reset_lab, set_lab_paused, set_reduced_motion and optional toggle_hint. Continue starts at level spawn; no mid-puzzle state is saved.

Selection starts only after successful original SaveStore persistence. Actual current Host Goal alone routes completion. Save failure retains pending candidate, shows error/Retry; retry neither manufactures a Goal nor restarts an existing Host. Reset/return invalidate routing from old Host. Future format and unknown saved catalog are protected. Original five-level button switches to `res://game/shell/game_feel_shell.tscn`, with its own unchanged default save slot.

Approved token/font/theme resources are reused. Native focus border uses existing accent/light colors. Menu scroll follows focus; Retry participates in menu and paused focus rings. Gameplay toolbar releases focus while running. Wrapped error panel reserves its actual height above toolbar/menu. Reduced Motion is forwarded to Host and cannot alter formal legality. No Audio/settings API replacement is introduced by this experimental Menu.

Headless tests and renderer tests are separate evidence. Formal witnesses in tests call actual Facade and await natural Presenter idle; no finish injection or dummy maps. Positive Goal comes from actual Host. Wrong-ID/stale signals are explicitly negative fault exercises.
