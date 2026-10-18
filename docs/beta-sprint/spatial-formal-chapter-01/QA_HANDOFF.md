# Spatial Formal Chapter 01

User approved five existing spatial maps as a formal chapter after L05 on 2026-10-19. This is a menu/lifecycle/progression integration, not new puzzle rules or a redesign of L06. Branch: `feat/spatial-formal-chapter-01`; baseline: `7259917c83a9ba26b5d3b39fe14265dc8d4627f3`.

## Playable scope

The original five registry rows remain unchanged. The additional `spatial_chapter/level_order.json` registers:

1. `spatial_world_shift_gate_lab` — 世界转换点
2. `spatial_orientation_loop_lab` — 六面回环
3. `spatial_face_lock_lab` — 接触之面
4. `spatial_perspective_fork_lab` — 视角岔路
5. `spatial_rubik_spatial_puzzle_01` — 六面归位

The original saved map authoring, Runtime, Presenter and audio bridge remain authoritative. A thin level wrapper supplies the existing Shell completion/reset interface, freezes real motion/audio during pause, and fences deferred completion after reset/unload. Goal committed during pause remains pending until resume. The approved HUD consumes read-only world/camera/hint feedback; it does not infer permissions. Existing Settings route volume and accessibility to the wrapper without a second SaveStore.

Formal entry: `res://game/shell/game_feel_shell.tscn`. New Game starts L01; each real Goal unlocks the next entry. A previously completed L05 save needs another L05 completion to unlock the appended chapter. No automatic save migration or direct unlock seeding is introduced. Continue starts the most recent level at its initial state. L06 remains design-only and unregistered.

## Independent build and data

Package committed clean source with `python tests/beta_sprint/spatial_integration/package.py <new-absolute-output-directory> --formal-chapter`. Output must not exist. `BUILD_IDENTITY.json` records the exact commit and file hashes. Run `play.ps1` from the package; it isolates APPDATA/LOCALAPPDATA/TEMP under its own `qa-profile`. The package requires the recorded Godot 4.7.2 executable. Do not launch the old QA build or reuse its saves for new tests.

The spatial chapter retains its tested greybox presentation. Floating-cube A/B/C are proposal-only; no proposal or incident export replaces approved Art. Three external Art export differences remain recovery-pending.

## Acceptance boundaries

Automated results belong to their exact source hashes and process receipts. The prior user's report that all five experimental maps were successfully played remains a separate, partial Human QA observation; cognition timing, prediction counts, hints and player quotations were not supplied. It does not certify this new formal-shell build.

08 should check new chapter entry/progression, pause/resume, Reset/Goal/replay, HUD at 1920×1080 / 1280×720 / 960×720, accessibility/volume, return to menu, and cold Continue. Preserve older Input P1 and Goal Reset P2 closures. Recheck any new defect with its actual Runtime state and build identity; do not reopen old fixes without new evidence.

## Ownership and protection

00: additive registration, shared Shell/HUD adapters, entry/configuration, packaging and delivery. Host integration: new `spatial_level.gd` only. Quality: new `tests/beta_sprint/spatial_formal/` tests. Existing Owner worktrees, old QA builds/evidence, L01–L05 puzzle resources, L06 design, Runtime/Foundation, SaveStore and frozen Art are not modified. No push to main or release-tag modification.
