# Spatial Lab Menu and Save Adapter Implementation Plan

> **For agentic workers:** Use superpowers:executing-plans inline under the approved autonomous BUILD. Steps use checkboxes; no additional approval loop.

**Goal:** Provide five independent experimental entries, level-start Continue and real SaveStore persistence around00's delivered Host.
**Architecture:** progress_adapter.gd wraps the unchanged SaveStore and receives known IDs from09. main.gd consumes actual Factory metadata and owns menu/lifecycle controls; Host alone owns input, gameplay, hints, native completion and Goal. main.tscn is the entry;00 owns project.godot.
**Tech Stack:** Godot4.7.2, approved Shell tokens/fonts/theme, isolated hidden headless evidence.
**Spec:** ../USER_REQUEST.md, ../CONTRACT.md at7442e8172e865d093ff1e73570d891f60d9134af and00's explicit07 Menu/Save delegation.

## Global Constraints

- Only experiments/spatial_puzzle_batch_01/ui/**, tests/beta_sprint/spatial_owner_07/** and this ui documentation root. No shared project/Shell/SaveStore/art/Host edits.
- Default save: user://spatial_puzzle_batch_01/progress.json. Original SaveStore.VERSION=1, settings and level-start semantics remain unchanged; no mid-puzzle state.
- Factory ids/describe/title are the display authority; no generated routes, formal unlock progression or UI permission rules.
- Host: lab_id:StringName before add_child; menu_requested, goal_reached(level_id:StringName); reset_lab(), set_lab_paused(bool), set_reduced_motion(bool), optional toggle_hint(). No WASD/F/QE/Space handling.
- No GUI until coordinated00; no Human/graphical/new mechanism acceptance inferred from service/UI tests. No push/main merge/history rewrite.

## Review Focus

- Start-save failure must preserve disk bytes, remain in menu and retry the same selection without double-start.
- Goal-save failure must retain the actual reached completion for retry without producing another gameplay event.
- Future/unknown catalog progress is protected; default/legacy QA profiles remain isolated.
- Old/unloaded Host signals and wrong level IDs must not mark completed; Reset/menu return invalidate active UI routing.
- Scroll/focus/buttons at1920x1080/1280x720/960x720 remain bounded; menu controls release gameplay focus and do not consume reserved keys.

### Task1: real progress adapter

Files: ui/progress_adapter.gd; tests/spatial_owner_07/test_progress.gd and run.ps1.
Consumes: SaveStore.new(path,first_id), load_save(), save(data); Factory's stable ID list.
Produces: begin_level(id)->bool, mark_goal(id)->bool, retry()->bool, continue_id()->StringName, snapshot()->Dictionary, leave_level(), last_error/read_only/dirty.
- [x] RED: adapter presence guard, then actual start/Goal/cold/failure/retry/future/unknown-ID tests with real files and SaveStore, no mocks.
- [x] Implement transactional pending candidate and fixed catalog compatibility field; completion only through active-ID Goal port, not selection/Reset/Continue.
- [x] GREEN: fresh isolated processes and original Save regression; preserve raw RED/GREEN, commit Owner files.

### Task2: menu and Host composition

Files: ui/main.tscn, ui/main.gd; tests/spatial_owner_07/test_menu.gd; UI API/receipt/evidence docs.
Consumes: actual09 Factory and actual00 Host, plus Task1's adapter.
Produces: five independent buttons/metadata, Continue, Save error/retry, old Shell switch, pause/Reset/Hint/Reduced Motion/menu return. Slot at bottom reserved for toolbar.
- [x] RED: scene presence and actual control/lifecycle assertions. Missing Factory remains a real dependency, never replaced with a production dummy.
- [x] Implement menu with approved theme/native controls, read-only Host event routes, captured-node stale signal guards and lifecycle cleanup.
- [x] GREEN: real Factory/Host seam where delivered, real storage/cold restore, affected legacy regressions and three measured headless viewports. Separate new gameplay/graphical acceptance from these assertions.
- [ ] Fresh read-only branch review, resolve actual findings with RED/GREEN, commit and bind tested/live/Git blob hashes. Report exact source/dependency/HEAD/CLEAN/Push NOT_RUN.
