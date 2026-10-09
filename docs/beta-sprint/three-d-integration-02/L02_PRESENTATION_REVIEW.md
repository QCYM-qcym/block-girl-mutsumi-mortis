# L02 presentation source review

Review time: 2026-10-09T03:36:27.573228+00:00. Worktree: `E:/godot/worktrees/block-girl-beta-3d-integration-02`. Fixed baseline: `dc0bd64b53a9ee3c0c12d4bd7f25ab1ab92df916`; HEAD remains that commit, so the scope is the current tracked working-tree diff plus the new untracked `levels_3d` production files. Plan: [2026-10-09-beta-3d-integration-02.md](E:/godot/worktrees/block-girl-beta-3d-integration-02/docs/superpowers/plans/2026-10-09-beta-3d-integration-02.md), with the coordinator's explicitly authorized two-line optional-mechanism guard refinement.

Result: **no Critical or Important source findings; no Minor finding identified. SOURCE_REVIEW_PASS / GRAPHICAL_GATE_PENDING.** This independent review read code, diffs, asset contracts, the baseline SHA inventory and existing entry evidence. It did not launch Godot, run tests, edit production, or prove a playthrough.

## Standards

No documented-standard breach or load-bearing duplication identified. All behavioral algorithms remain in their accepted owner. The subclass overrides asset construction and mechanism observations; its diagnostic snapshot handles absent mechanisms. It does not copy roll, actor pose, camera, World Shift, material reconstruction, physics disabling, Reset, or occlusion implementation.

The only base Presenter delta is the two-line `if not mechanisms[world].has(kind): continue` before lookup at [presenter.gd:306](E:/godot/worktrees/block-girl-beta-3d-integration-02/game/levels/mutsumi/batch_01/l01_3d/presenter.gd:306). Removing those exact two lines reproduces the original Git blob byte-for-byte. Existing L01 creates gate and exit in both worlds, so this guard does not alter its present mechanism path. Actual L01 graphical regression is still required.

The L01 attachment adds `_create_presenter()` returning the original Presenter and replaces its single construction call at [l01_presented.gd:13](E:/godot/worktrees/block-girl-beta-3d-integration-02/game/levels/mutsumi/batch_01/l01_3d/l01_presented.gd:13). Removing that factory and restoring the constructor call also reproduces the original blob exactly. The new [presented_level.gd:5](E:/godot/worktrees/block-girl-beta-3d-integration-02/game/levels/mutsumi/batch_01/levels_3d/presented_level.gd:5) chooses the subclass and renames presentation nodes after `super._ready()`; lifecycle, HUD, Pixel retention and input remain inherited.

Re-read all 830 strict protected tracked files against original Git-byte SHA256: only the already-recorded `production/ui/beta_shell_01/icons_source.svg.import` generator delta differs. That file must be restored by the coordinator before final delivery. It is a known import side effect, not a new L02 source finding. Foundation/tools/shared Runtime/Gameplay/content resources/hints/Save/Load/approved art and UI source remain unchanged. No new UI art, hint timer, hint text, Save/Load, catalog, project configuration or Rule ownership was introduced.

## Spec

- **Exact support:** [presenter.gd:14](E:/godot/worktrees/block-girl-beta-3d-integration-02/game/levels/mutsumi/batch_01/levels_3d/presenter.gd:14) iterates only the native per-world `.tres` cells and obtains each platform from `graph.nodes[cell]`. L02 has Surface `(0,5),(0,4),(0,3),(1,1),(2,1),(3,1),(4,1)` and Inner `(0,5),(0,3),(0,2),(0,1),(1,1)`: exactly 7/5 floor instances, all platform0. Approved floor footprint is one cell and walk height0.24; `_add_asset` and actor/display mapping remain inherited. No L01 hardcoded cell skip, extra support, bridge, gate or plate is instantiated.
- **Native mechanics retained:** link and gate are disabled by existing resource defaults. The two required world shifts remain native Runtime decisions; floors and missing support are never changed by visual nodes. The Inner route is presented through its original five floor cells; this review does not claim first-player comprehension of that route.
- **Optional Goal by world:** [presenter.gd:20](E:/godot/worktrees/block-girl-beta-3d-integration-02/game/levels/mutsumi/batch_01/levels_3d/presenter.gd:20) creates exit only when the world contains `definition.goal`. L02 Goal `(4,1)` exists only in Surface, so Inner has no exit asset and the occlusion guard safely skips it. Exit is non-walkable presentation bookkeeping with all imported physics disabled; it adds no Runtime support. State observes `graph.complete` and existing world semantics via `set_visual_state`, with no second completion authority.
- **World cue:** both world-switch assets retain the inherited non-walkable decorative-cue placement at spawn plus `(1.4,0)`. Their states observe native shift/visual-tail status; no Area interaction, separate activation condition or new world-switch rule is installed. Native failed-shift feedback and objectives remain on the existing HUD. Visual clarity must be assessed in the graphical gate.
- **Approved consumption:** L02 consumes seven already-approved IDs: Wakaba, Mortis, Surface/Inner FLOOR, Surface EXIT, Surface/Inner WORLD_SWITCH. `_instance` loads existing wrappers and disables their physics recursively; `set_visual_state` only changes approved StateViews/GLB parts. No raw-GLB replacement, mesh/material/asset-source edit, mechanism_runtime import or new asset production is present. The original 121 binding files were already verified physically in Main/Integration/task worktrees in BASELINE_AUDIT.json.
- **No Runtime writes:** new production methods create/read presentation objects and read `definition`, `graph`, `mover`, `view`. They do not assign Runtime position/world/orientation/phase/flags, submit actions, call Rule decisions, attach gameplay signals, redefine connectivity, mutate floor resources or alter Save/Load. Native L02 scene changes only its script reference; content resource, node name and stable ID remain original.
- **Sequential boundary:** native L03 scene is still byte-identical to baseline and points to the greybox ContentLevel. L03 production attachment and endpoint review remain a separate later gate.

Existing entry evidence read: `.godot/beta-sprint/three-d-02/l02_entry_green/report.json`, PID39548, 9 checks, `failures=[]`, native `mutsumi_l02`, `display="headless"`, Godot4.7.2 Steam. The sibling entry/import stderr files are empty. The coordinator reports exit0. These checks establish loading/default-3D/Pixel-toggle state retention only; graphical rendering, complete L02 input routes, physical-face coverage, Pause, reset-in-action and parity are **pending** at this review.

`STAIR_CLEARANCE=PARTIAL_PASS`, `STAIR_TRAVERSAL=NOT_RUN`; no stairs are used. No Human QA or Foundation RuntimeSession/statekey.v1 acceptance is inferred.

## Reviewed source SHA256

| Source | SHA256 |
| --- | --- |
| [game/levels/mutsumi/batch_01/levels_3d/presenter.gd](E:/godot/worktrees/block-girl-beta-3d-integration-02/game/levels/mutsumi/batch_01/levels_3d/presenter.gd) | `32bb23f3da28d46871f56b4bf031c1bb69c4e625b6a161a3d6afbba98e36763e` |
| [game/levels/mutsumi/batch_01/levels_3d/presented_level.gd](E:/godot/worktrees/block-girl-beta-3d-integration-02/game/levels/mutsumi/batch_01/levels_3d/presented_level.gd) | `9f201206c16cfc62bdad1a6f39d68aedf8eb0639da7618f27c41cb268f0f8435` |
| [game/levels/mutsumi/batch_01/l01_3d/presenter.gd](E:/godot/worktrees/block-girl-beta-3d-integration-02/game/levels/mutsumi/batch_01/l01_3d/presenter.gd) | `0bb1c430b5ce078b3ff811ba2e42e7edb375f7056378f6f2ceceb1c6dce54a23` |
| [game/levels/mutsumi/batch_01/l01_3d/l01_presented.gd](E:/godot/worktrees/block-girl-beta-3d-integration-02/game/levels/mutsumi/batch_01/l01_3d/l01_presented.gd) | `a72dfde4c7b69294c887d1cebc8c29dce49f0b0d2f3b2b74694efc1d0e113b0e` |
| [game/levels/mutsumi/batch_01/l02_between_shores.tscn](E:/godot/worktrees/block-girl-beta-3d-integration-02/game/levels/mutsumi/batch_01/l02_between_shores.tscn) | `6f9717ac84efe7603503db17b822890d7e790333cf42a6c063300c2dff9e0913` |
| [game/levels/mutsumi/batch_01/l02_between_shores.tres](E:/godot/worktrees/block-girl-beta-3d-integration-02/game/levels/mutsumi/batch_01/l02_between_shores.tres) | `4a99f16f13603dd0759371462f4052afd11195c5cd70b282679b501a87507e5e` |

Standards:0 findings; Spec:0 source findings. Required remaining gates are graphical L02 acceptance, L01 regression and final known SVG importer metadata restoration.
