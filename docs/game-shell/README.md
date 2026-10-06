# Game Shell Beta baseline

Open `E:/godot/worktrees/block-girl-beta-game-shell/project.godot` in the installed
Godot editor and press F5. This checkout is on `feat/beta-game-shell`; the original
`E:/godot/若叶睦/方块少女-若叶睦` checkout remains on main.

The default Main Scene is `res://game/shell/game_shell.tscn`.
Production currently registers P-01 only. New Game enters it, Continue restarts
the recent unlocked level at its authored spawn, and completion is retained.
Esc opens/resumes Pause, R resets the level, M toggles persisted mute.
Mouse buttons/sliders and keyboard focus/Enter are supported.
New Game confirms before resetting existing progression; settings are retained.

Progress: `user://mutsumi_veilshift/beta_progress.json`, a versioned checksummed
JSON envelope. Backups use `.bak`; malformed originals use `.recovery-*`.
Never use the test directories as a player's save path. Validation isolates all
data under `user://shell_tests/` and does not touch the production slot.
Music uses the existing environment/ambience category. Master/SFX/Music gains
retain the existing authored bus calibration; zero mutes the relevant bus.

Run from this checkout in PowerShell:

```powershell
./tests/shell/run_validation.ps1 -EvidenceName shell_new_run
./tests/shell/run_validation.ps1 -EvidenceName shell_full_run -IncludeRegressions
```

Evidence names must be fresh; the runner will preserve earlier runs. The runner
defaults to the existing Steam Godot executable; override `-Godot` if necessary.
It records stdout/stderr, actual graphical screenshots and JSON results. Graphical
tests inject Godot keyboard/mouse events; they are not human-operated manual tests.

## Content integration

Owner 06 can provide accepted scene IDs/titles/paths for the local catalog in
`game/shell/level_catalog.gd`. Register only real, accepted levels. P-01 uses its
existing mover `committed` signal, `graph.complete` and `reset_level()`.
For a different accepted level, the existing local `signal` adapter expects a
`completed` signal and a `reset_level()` method on the scene root. If a future
level uses another public lifecycle, adapt it within Shell after its contract is
agreed; never change runtime semantics or author content to satisfy the Shell.
The local A/B fixture is only for unlock/next-level tests and is not user content.

There are no Autoload, InputMap, bus-layout, Foundation or art-source changes.
Only application/run/main_scene changes in project.godot. UI cue hooks emit
`ui_cue_requested("select"/"complete")`; optional UI sounds/transitions can be
added locally later.
