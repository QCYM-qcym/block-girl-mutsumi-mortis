# Beta Game Shell

Track: 07 Game Shell. Baseline: main, 8a77874cc18ceb654664c3e9aeb10a2ccd318048.
The user supplied the complete BUILD brief and authorized continuous implementation.

## Scope and owner roots

`game/shell/`, `tests/shell/`, `docs/game-shell/`; `project.godot` only for Main Scene.
No changes to puzzle, Foundation, production art/audio, global inputs, buses or Autoload.
Original checkout's seven untracked README import files remain untouched.

## Architecture

One local Shell scene owns BOOT, MAIN_MENU, LEVEL_SELECT, PLAYING, PAUSED and
LEVEL_COMPLETE. Settings are an overlay with an explicit return destination,
not another gameplay state. No existing Shell state model or Autoload exists.
A catalog registers only P-01 on this baseline; no fake production P-02.
A two-level owner-local fixture verifies sequential unlock/next-level navigation.

The P-01 adapter instantiates the unchanged scene, calls `reset_level()`, reads
`graph.complete` through the existing mover commit signal immediately, and uses
the existing focus-loss notification to release held input/cancel drag on pause.
Pause disables the level subtree and pauses its audio players; Shell stays active.
The Shell input gate runs above gameplay and intercepts Escape, completion Reset,
the pause button and persistent M mute. The puzzle's rolling/shift rules remain
the only gameplay authorities. Shell completion feedback appears immediately and
the achieved Goal is saved before reset/navigation/quit can discard the level.
Continue restarts the recent unlocked level at
its authored spawn, preserving unlock/completion progress, not mid-puzzle snapshots.

## Storage and settings

`user://mutsumi_veilshift/beta_progress.json` contains one versioned checksummed
JSON payload: progress flag, unlocked/completed IDs, recent ID and settings.
Write/flush/re-read a same-directory temporary file, protect the previous primary
as a backup, then rename the verified temporary file over the primary. Never
delete a good primary before replacement. A backup is also verified before use.
Malformed originals are retained under a unique recovery name before replacement.
Unsupported future versions are read-only: no silent downgrade/overwrite.
Failed writes retain old progress, report an error and permit retry.

Master maps to Master, Music to existing Ambience (no authored music currently),
SFX to SFX. Zero uses bus mute; settings are previewed and explicitly applied.
Cancel restores persisted settings. Fullscreen uses the existing window.
No global bus layout changes. The local UI uses a consistent readable dark theme,
keyboard focus/Enter, Escape/Back, mouse buttons and sliders. No gamepad support
exists on this baseline, so it is outside scope.

## Verification

Test actual disk writes under isolated `user://` test directories, recovery,
future/invalid data, write failure and settings persistence. Graphical tests inject
real Godot keyboard/mouse input, traverse production P-01 through its actual Goal,
check pause/reset/navigation and capture screenshots. Separate processes prove
restart persistence and initial main-scene startup. Run existing gameplay/state,
presentation and visual regressions; report any existing tests asserting the old
Main Scene distinctly rather than altering them. A graphical automated run is
not described as a human-operated manual run.
