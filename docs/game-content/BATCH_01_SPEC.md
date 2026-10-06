# Game Content Batch 01

Baseline: `main` at `8a77874`; Godot 4.7.2. This is a content release against the playable P-01 runtime, not a Foundation integration.

## Authorization and ownership

The supplied Beta Sprint task explicitly authorizes immediate BUILD after the baseline audit, without a second approval. CONTENT_OWNER_ROOTS:

- `game/levels/mutsumi/`
- `docs/game-content/`
- `tests/playtest/`

Do not change P-01's main-entry scene/script, shared gameplay, assets, Foundation, authoring tools, project.godot, menus or saves. Build independent F6 scenes. Commit this batch on `feat/beta-game-content`, do not push. Preserve the original checkout's untracked imports.

## Baseline findings

`game/levels/mutsumi/p01_another_world.tscn` is the main scene. Its runtime already owns rolling, world shift, discrete views, pressure plate/door and completion. Existing assets and polish are reusable. `feat/playable-puzzle-p02` contains no additional level scene. Foundation Authoring lives on other branches: its `level_authoring_root.gd` is an exported declaration Node3D, not the playable main entry. No LevelDefinition pipeline exists on this checkout. Do not import incompatible branch subsystems.

## Content design

- L-01《另一个世界》: upgrade the existing 14-cell P-01 map to an independently named formal vertical slice; preserve bridge, Inner+EAST connection, momentary Surface plate and goal. Add clear content objectives and consistent title/completion text. Reuse all approved existing graphics, orientation sprites and polish.
- L-02《两岸之间》: greybox dual-world route. Surface spawn `(0,5)` -> `(0,3)` shore; Inner bridge through `(0,2),(0,1)` -> shared `(1,1)` landing; Surface path -> `(4,1)` goal. Two successful shifts are required; rotations cannot bypass missing floors.
- L-03《视线相接》: greybox perspective route. Surface spawn `(0,2)` -> `(3,2)` anchor; EAST aligns the authored endpoint at `(9,2)`; roll to `(11,2)` Surface goal. Logical gap remains six cells. The link is enabled only in Surface+EAST and stays traversable through the existing timed roll.

Content resources declare id/title/status, spawn/goal, world floors, platform membership, existing link configuration, and objective text. Local scene/state/board/hints adapters consume those resources without changing shared mechanics or adding global systems. L-02/L-03 have no pressure plate or door. A disabled existing link remains present as a runtime dependency, with `enabled=false`.

## Acceptance

All scenes load independently and finish through actual input. L-01 completes three times: normal, reset and replay, and alternate view order. Check continuous WASD, 90-degree adjacent view snaps in both directions, safe/unsafe world shift, actual link crossing, plate/door commit timing, Goal lock, and R during rolls/shifts/rotations/completion. L-02 and L-03 complete and reset, and their mandatory mechanic cannot be bypassed. Exhaustively inspect reachable cell/world/view states using the real content edge policy; every reachable state must reach Goal without Reset. Orientation does not gate these maps. Capture graphical checkpoints, including 900x700 and 1280x900 layouts.

## Integration requests

07 Game Shell / 00 Integration should register the three stable ids and independent scene paths in their level catalog. No global input, menu or save changes in this batch. TEMP existing audio and final greybox art remain an Art backlog. Human first-time-player comprehension is a playtest backlog, not proven by automated known-solution runs.
