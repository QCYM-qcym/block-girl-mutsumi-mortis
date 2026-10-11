# Spatial Puzzle Batch 01 — shared implementation contract

Authority: `USER_REQUEST.md`. Baseline: `d1277ec90b5a739efd4862d314e6c29ac5ac1eda`.
This contract authorizes implementation, not acceptance. Every result remains pending until measured.

## Authoritative state and compatibility

All actions, orientation, world, mechanism state, permission, goal, Solver, Safety and Replay use the existing Foundation Runtime. Presentation never supplies gameplay results. Existing five-level content, frozen Art, SaveStore semantics, legacy v1/v2/v3 behavior, ordinary Roll priority and Forward Drop remain compatible. New gated behavior requires an explicit authored opt-in schema/profile; old levels never acquire a gate by default.

01 owns the precise validated record/API extension and documents it in `RUNTIME_INTERFACE.md` before downstream use. The extension must be minimal, reusable and closed/validated. Preserve legacy Shadow, mapping and safety requirements. Author new Shift points with compatible SAME_NORMAL mapping to preserve orientation; reject an invalid target rather than teleporting. No UI permission algorithm or second gameplay kernel.

## Four mechanisms

1. World Shift Gate: an explicit Space action is required at an authored source Face/Anchor. Fixed gates are available immediately; gated points require authoritative mechanism/flag state. Off-point and locked attempts preserve StateKey. Successful Shift changes world and valid target pose, preserves cube orientation and camera semantics. Reset restores the authored initial state.
2. Orientation Loop: actual Roll routes reach the same pose with different orientations, and a closed loop changes orientation. Six physical local faces remain distinguishable; Camera rotation never rewrites cube orientation. No artificial orientation setter.
3. Face Lock: a stable mechanism on a formal Face/Anchor compares the **post-arrival** authoritative local face against the contact/down direction. Correct arrival latches until Reset; wrong face leaves MOVE successful but does not activate. Idempotent re-entry; the latch controls a real route/gate. No visual, hint or mesh-position inference. 01 integrates this with formal mechanism state and every affected formal consumer.
4. Perspective Fork: same source, edge, world, orientation and formal MOVE can select different uniquely camera-qualified targets. New Host F sends exactly `{kind: 0, face_axis: 2}` (U_NEG); the Runtime selects the target. F does not scan/select a connection id. WASD continues using the existing screen input mapper. Missing, overlapping, cross-world or unsafe edges remain rejected by formal contracts. Existing Forward Drop performs the actual animation.

## Maps and public entry points

09 owns `experiments/spatial_puzzle_batch_01/maps/**`.
Factory: `map_factory.gd`, a RefCounted script with static methods:

- `ids() -> Array[StringName]`: `world_shift_gate_lab`, `orientation_loop_lab`, `face_lock_lab`, `perspective_fork_lab`, `rubik_spatial_puzzle_01`.
- `bake(id: StringName) -> Dictionary`: real Baker result with `ok`, `level`, `issues`, `validation` (retain actual upstream evidence; no synthetic success).
- `describe(id: StringName) -> Dictionary`: teaching/display metadata only, at least `title`, `objective`, `hint`; never permission or authoritative state.
- `witnesses(id: StringName) -> Dictionary`: named arrays of formal actions for repeatable tests; no default HUD route spoilers.

Combined map: real Orientation Loop → Face Lock → unlocked Shift gate → Inner Fork → existing Forward Drop → Roll → Goal. One fork branch is exploratory and recoverable; another reaches Goal. It is an isolated experiment, not L06/L07/L08. All puzzles preserve valid Reset and expose actual solution witnesses to Quality. Do not add hidden support blocks to bypass Fall.

## Host and lifecycle

00 owns `experiments/spatial_puzzle_batch_01/host/**`, scenes, the isolated project's `project.godot`, build assembly and shared integration changes. Reuse `game/feel/cube_presenter.gd` and existing Fall/Landing/Edge modules. Six face marks follow the authoritative actor basis. New Shift visual completion uses actual animation completion and the existing Runtime pending identity, with Reset/unload/generation cancellation. No fabricated completion or fixed timer standing in for animation.

Menu exposes all five labs clearly. Default instructions teach controls and objective; advanced hints require H or an explicit button. Existing Shell/SaveStore stays authoritative for persistence. Experimental save data is isolated from all old QA profiles; Continue restores a level start, not an unversioned mid-puzzle state.

## Owners and file isolation

| Owner | Exclusive change scope |
|---|---|
| 01 | Necessary Foundation contracts/rules/Baker/solver/safety/replay/quality classification and typed authoring extension; `tests/beta_sprint/spatial_owner_01/**`; `docs/beta-sprint/spatial-puzzle-batch-01/runtime/**` and `RUNTIME_INTERFACE.md` |
| 09 | `experiments/spatial_puzzle_batch_01/maps/**`; `tests/beta_sprint/spatial_owner_09/**`; `docs/beta-sprint/spatial-puzzle-batch-01/maps/**` |
| 03 | `tests/beta_sprint/spatial_quality/**`; `docs/beta-sprint/spatial-puzzle-batch-01/quality/**` |
| 13 | Design notes in existing Obsidian hierarchy; versioned `docs/beta-sprint/spatial-puzzle-batch-01/design/**` only |
| 00 | New Host/scenes, isolated main project entry, integration tests/tooling, remaining task documentation/build manifests |

Any actual shared-file conflict is coordinated before edits. Existing Owner worktrees and QA packages remain intact. New 01/09/03 worktrees branch from this common contract commit. 13 may keep its existing document-only worktree. No push, main merge, reset, rebase, squash or tag move.

## Evidence gates

Separate UNIT, REAL_RUNTIME, SOLVER, SAFETY, REPLAY, GRAPHICAL, INTEGRATION and HUMAN_QA per mechanism. Solver/Safety must include real Shift, latch and Fall edges. Natural graphics and formal graphical replay are distinct. Preserve all failed runs. Serialize graphical windows. No Human PASS without actual eligible human testing. Build readiness requires an actual runnable copied project, engine/launch identity, five menu entries, runtime-driven graphical checks, regression evidence and QA handoff. No claim that the entire game Beta is complete.
