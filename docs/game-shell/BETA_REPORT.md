# GAME_SHELL_BETA_BASELINE_READY

Track: **07 Game Shell** · Mode: BUILD · Sprint target: 2026-11-30.
Baseline: `main @ 8a77874cc18ceb654664c3e9aeb10a2ccd318048`.
Delivery branch: `feat/beta-game-shell`.
Checkout: `E:/godot/worktrees/block-girl-beta-game-shell`.

GOAL: P0 functional loop implemented and verified: startup/menu/start or Continue,
real P-01 gameplay, pause/resume/reset/settings/navigation, immediate durable Goal
completion, selection/progress, exit and separate-process progress/settings restore.

| Component | Result | Evidence |
| --- | --- | --- |
| Main Menu | PASS | Cold startup, GUI mouse navigation, keyboard Enter |
| Pause | PASS | In-flight roll frozen; input released; drag canceled; resume |
| Level Select | PASS | Locked fixture refused, unlock/completion shown, real scene entered |
| Save/Load | PASS | user://, checksum, staged replacement, backup/corrupt recovery, future protection |
| Settings | PASS | Master/Music/SFX, persisted independent mute, apply/cancel, fullscreen/windowed |
| Level Complete Flow | PASS | Real Goal recorded immediately; immediate reset/leave retains completion |
| Continue | PASS | Correct unlocked recent level, authored-spawn restart |
| Cold Start | PASS | Actual configured Main Scene and no-save first startup |
| Restart Persistence | PASS | Separate processes restore progression/settings and actual fullscreen |

## Acceptance evidence

Final run: `tests/shell/evidence/shell_beta_final/`.
**112 assertions, zero failures; all 11 stderr logs are empty.**

| Stage | Assertions |
| --- | ---: |
| Safe progress store | 19 |
| Shell lifecycle / two-level fixture | 20 |
| Immediate real P-01 Goal boundary | 7 |
| Mute and chosen gain after restart | 4 |
| Cold process | 4 |
| Seed process | 3 |
| Headless restore process | 6 |
| Separate graphical restore process | 8 |
| Actual P-01 graphical keyboard/mouse playthrough | 41 |

The actual Main Scene additionally boots with no test-script override. Graphical
renderer: D3D12 Forward+, NVIDIA GeForce RTX 5060 Ti; Godot 4.7.2 Steam.
Screenshots in the final run were visually inspected for main/pause/complete/settings.

CASE A–E functional sequences passed with actual graphical Godot input plus the
separate-process stages. **Human-operated manual acceptance: NOT_RUN.** These
automated graphical events are not presented as physical desktop input or human
playtesting. Human gameplay feel, focus switching and final Beta acceptance remain
available for user validation using F5 in the delivery checkout.

Existing regression evidence: `tests/shell/evidence/shell_beta_01/` and
`tests/gameplay/evidence/shell_beta_01_regression/`. Passed:
P-01 state (31), P-01 runtime (167), orientation/sprite presentation (1780),
perspective logic (66), perspective bugfix (172), perspective runtime (54),
legacy prototype state (50), legacy input/runtime (3518 runtime assertions),
sprite/tileset/mechanism visual suites. P-01 legacy runtime expects the old Main
Scene: owner-local `test_p01_legacy_entry.gd` supplies its explicit old in-memory
entry context, leaving all original tests unchanged; the real Shell entry is
separately tested. The existing runner preserves the tileset sample bytes.

## Ownership and shared files

OWNER PATHS (relative to the delivery checkout):

- `game/shell/`
- `tests/shell/`
- `docs/game-shell/`
- `project.godot`, only application/run/main_scene

Shared files changed: **project.godot**, one setting: P-01 scene → Shell scene.
Global Autoload/InputMap/Audio Bus/Theme Registry/export configuration: NONE.
Game Content changes: **NONE**.
Foundation production changes: **NONE**.
Art source changes: **NONE**.
Original checkout's pre-existing seven untracked import files: untouched.
This isolated checkout's generated untracked README import sidecars are removed
after verification; generated evidence and `.godot/` remain ignored.

Files/SHA: `FILES_SHA256.csv` lists every delivered source/test/document and UID
except the manifest itself (a manifest cannot contain its own hash).
`verification.json` records exact test summaries and protected-directory integrity.
Working tree: **CLEAN**, delivered as local commits after verification.
Push: **NOT_RUN**. Merge: **NOT_RUN**. Worktree and branch retained.

## Review and decisions

Independent read-only review identified a completion-delay loss: the real Goal
could be reset/left before the old 1.8-second presentation finished. Actual-action
regression reproduced it, then passed after the adapter observed the existing
commit signal immediately. The Shell now supplies formal completion feedback.
No rolling, Goal layout or puzzle semantics changed.

Restart-unmute increasing a chosen 40% gain to 100% was treated as an Important
settings-persistence defect despite the reviewer's Minor label. Separate persisted
mute preserves gain; regression changed from two failures to four passing checks.
Invalid mute-schema regression also changed from failure to pass.

Rulings: Continue restarts the authored spawn; additional formal levels/music and
gamepad are outside this baseline. Cross-process fullscreen required graphical
evidence, so an actual graphical restore process was added and passed.
The only source file outside Shell ownership is the one-line Main Scene change.

## Known backlog and integration requests

- Owner 06: register additional accepted formal levels; production currently has
  P-01 only. Unlock/Next is verified with the owner-local A/B fixture. No fake P-02
  is exposed to players.
- P1: transition/loading presentation and optional UI sound assets. Confirmation,
  Continue availability, key prompts, UI sound interface and a consistent local
  Beta theme are already present.
- Deferred minor: dedicated final-primary-replacement failure and completion-save
  retry fault-injection tests. Backup replacement failure and old-primary byte
  preservation are covered; the prior misleading assertion label was corrected.
- First graphical_01 run had one drag-pause assertion failure and a subsequent
  navigation error. Its root cause was not established. Diagnostics were expanded;
  graphical_02, shell_beta_01 and shell_beta_final each passed 41 checks with empty
  error logs. Earlier evidence is retained, rather than represented as a clean run.
- Human-operated manual acceptance and final UI/art polish remain unperformed.

Integration requests: accepted content catalog entries from Owner 06 only;
no Foundation public API or contract request is needed for this baseline.
