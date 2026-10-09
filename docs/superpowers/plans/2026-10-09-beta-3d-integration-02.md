# Beta 3D Integration 02 Implementation Plan

> **For agentic workers:** Use parallel owners with disjoint paths, then sequential L02 / L03 graphical gates. User BUILD / PARALLEL authorization is the execution method. No additional design approval or future Foundation migration gate.

**Goal:** Upgrade current native L02 and L03 entries to formal approved 3D presentation without changing their playable Runtime or solutions.

**Architecture:** Reuse the QA-passed L01 Presenter algorithms; its only extension is a two-line optional-mechanism guard in occlusion. Add a default `_create_presenter() -> Node3D` factory to its existing attachment, then inherit that attachment and Presenter for data-driven L02/L03 layout and optional mechanism observations. Original Pixel board, ContentState, GridMovement, PerspectiveController and approved HUD remain the authorities and regression reference.

**Tech Stack:** Existing Godot 4.7.2, GDScript, PowerShell; approved production/art_3d scenes.

**Spec:** User BETA-3D-INTEGRATION-02 request; source baseline dc0bd64b53a9ee3c0c12d4bd7f25ab1ab92df916. Existing Runtime parity means P01 observation SHA256, not Foundation statekey.v1.

## Global Constraints

- Worktree E:/godot/worktrees/block-girl-beta-3d-integration-02; branch feat/beta-3d-integration-02.
- L02 GREEN before L03 production entry is attached.
- Keep Runtime/Rules/Foundation/Save/Load/hints/map resources/Art source/project.godot/Main Scene unchanged.
- Keep current Integration/Main and 08 build/profile/evidence untouched. Fresh user://beta_sprint/b3d02_* saves only.
- STAIR_CLEARANCE=PARTIAL_PASS; STAIR_TRAVERSAL=NOT_RUN.
- No meshes, collision, transforms, visual labels or callbacks decide gameplay.
- L03 hint P2 stays with06; no delivered hint change at content HEAD608a18a.

## Owner Paths

- Presentation Owner: game/levels/mutsumi/batch_01/levels_3d/**; l01_3d/l01_presented.gd factory only; l01_3d/presenter.gd two-line optional-mechanism guard only; l02_between_shores.tscn and l03_lines_meet.tscn script binding only.
- Test Owner: tests/beta_sprint/three_d_02/test_*.gd, *.gd.uid, run_integration.ps1. Controller serializes all engine launches.
- Coordinator: docs/beta-sprint/three-d-integration-02/**, this plan, tests/beta_sprint/three_d_02/build_qa.ps1 if needed.
- Existing catalog and .tres quality metadata stay as historical Content declarations. Receipt/build handoff explicitly registers presentation status separately; no false claim that06 reauthored content.

## Review Focus

- No false L01-only bridge/plate/gate on L02/L03; every walkable visual footprint maps to original per-world support.
- Runtime-disconnected L03 endpoints remain unmistakable at wrong world/view and during rotation; labels observe actual link state only.
- Roll, shift, view and Reset use original commit timing; early/mid/late visual samples and isolated Shell Pause freeze are checked.
- Identical original action sequences produce per-commit and settled-view parity records for cell/world/orientation/mechanisms/link/Goal.
- Importer may invalidate unused frozen defs-only SVG metadata; preserve failed evidence, restore exact original metadata at delivery, never alter frozen SVG.

## Task 1: L02 presentation + formal gate

- [x] Write/run entry test against current native L02; expected RED: missing display_3d/Presenter.
- [x] Add L01 attachment default factory and subclass Presenter/attachment, then bind only L02 native scene.
- [x] Floors use actual surface_cells/inner_cells and graph.nodes platform IDs. Exit/world-switch use existing formal state methods; omit unauthored gate/plate.
- [ ] Run graphical L02: normal, reset_replay, alternate_views plus Pixel parity; Surface/Inner, world shifts, real cube basis/6faces, both four-quarter orbits, reset during roll/shift/view, native Shell completion.
- [ ] Confirm failures=[], checks>0, exit0, stderr empty; commit task before attachingL03.

## Task 2: L03 + L01 regression

- [ ] Run L03 entry RED before attaching it.
- [ ] Bind L03 native scene only; extend data-driven layout for actual authored link endpoints and Runtime-active status labels without adding logical edges or bridges.
- [ ] Run graphical L03: before connection, rotate, Surface EAST activation, timed crossing3→9, disconnect/wrongworld blocked crossing, reset, goal; Pixel parity exact including view/link events.
- [ ] Run L01 graphical regression through unchanged Presenter/default factory, actual route/roll/view/shift/plate/gate/Goal; no Cold Continue matrix.
- [ ] Independent reviewer inspects scope and runtime-write absence; resolve actual regressions only; commit.

## Task 3: Isolated QA build + receipt

- [ ] Verify protected files and current Main/Integration HEADs; retain all failed/successful evidence.
- [ ] Generate fresh source playable build; reuse existing source build copier, provide isolated-save launcher and truthful import/boot evidence.
- [ ] Preserve old08 source build/profile/report; do not execute or edit them.
- [ ] Verify copied source hashes, record Files/SHA, receipt + 00/08 handoff, presentation status separate from Content quality and Human QA.
- [ ] Final commit/docs hash verify, working tree CLEAN, Push NOT_RUN.
