# Beta Game Shell Implementation Plan

> Execution: superpowers:executing-plans, inline. The user's BUILD instruction
> overrides additional approval gates. Test-driven-development and
> verification-before-completion apply. Final review uses a fresh reviewer.

**Goal:** Complete the Beta startup/menu/play/pause/complete/save/restart loop.
**Architecture:** Local Shell scene, local catalog, P-01 adapter, safe SaveStore,
and local UI/settings. Only Main Scene changes outside owner directories.
**Tech Stack:** Existing Godot 4.7 GDScript and PowerShell runners.
**Spec:** DESIGN.md plus the user's complete Beta BUILD brief.

## Constraints and review focus

- No Foundation, content, runtime semantics, art or global-input changes.
- Future saves, corruption and failed replacement must not lose the old save.
- Pausing during held keys/drag must not cause ghost input on resume.
- Modal settings must return to the correct suspended screen and apply/cancel.
- Locked/missing scenes must never become playable via Continue/selection.
- Cold start and separate-process restart must use isolated user data.

## Task 1: Save and catalog

Files: `game/shell/save_store.gd`, `level_catalog.gd`, `settings.gd`,
`tests/shell/test_save.gd`.
Interfaces: SaveStore.new(path, first_id), load_save() -> Dictionary,
save(data) -> bool, defaults() -> Dictionary, last_error/read_only.
Catalog.entries, first_id(), find(id), next_id(id), is_available(id).
- [x] Write failing disk/persistence/recovery/future-format/failed-write tests.
- [x] Run headless test; expect missing SaveStore failure.
- [x] Implement and run; expect zero failures and old save preserved.

## Task 2: Shell flow and UI

Files: `game/shell/game_shell.{gd,tscn}`, `shell_view.gd`, `shell_input.gd`,
`level_adapter.gd`, `tests/shell/{test_flow.gd,fixture_level.gd}`.
Interfaces: Shell exports save_path/catalog_entries; state enum;
start_level(id), pause_game(), resume_game(), reset_current(), show_main_menu(),
show_level_select(), open_settings(), save_settings(), cancel_settings().
View action_requested(action,id), settings_changed(key,value), buttons/sliders.
- [x] Write failing navigation/unlock/pause/focus/reset/settings tests.
- [x] Run headless test; expect missing Shell scene failure.
- [x] Implement local Shell and verify tests pass.
- [x] Change only application/run/main_scene in project.godot.

## Task 3: Graphical acceptance and delivery

Files: `tests/shell/test_playthrough.gd`, `test_restart.gd`,
`run_validation.ps1`, local evidence and reports.
- [x] Drive actual P-01 solution with keyboard and mouse rotation; freeze mid-roll,
      reset from Pause, verify M/settings and complete/selection navigation.
- [x] Capture and inspect actual graphical menu/pause/settings/complete screenshots.
- [x] Launch separate seed/restore/cold-start processes with isolated saves.
- [x] Run existing regressions; report old Main Scene assertion explicitly.
- [x] Fresh review, fix meaningful findings with regression tests.
- [x] Record exact paths/SHA, owner integrity, acceptance limits, commit locally;
      no push and no merge. Verify clean delivered worktree.

## Execution ledger

- Baseline audited; current checkout is separate from Foundation worktrees.
- Native worktree tool returned Not a git repository (task cwd is parent);
  fallback isolated Git worktree created on feat/beta-game-shell.
- Task 1: SaveStore missing RED; disk suite GREEN, 18 checks, zero failures.
- Task 2: Shell missing RED; lifecycle suite GREEN, 20 checks, zero failures.
- Ruling: only P-01 is production content; fixture A/B demonstrates unlock/next.
- Ruling: Continue restores the authored level start, not puzzle snapshots.
- Task 3: graphical P-01 keyboard/mouse completion passed in graphical_02 and
  shell_beta_01 (41 checks each). Initial graphical_01 drag-pause failure retained;
  root cause not established. Diagnostic now includes state/busy/view/screen.
- Final review: independent read-only reviewer found delayed Goal persistence.
  Fixed using existing committed signal; actual Goal boundary RED 5 failures to
  GREEN 7 checks. No gameplay semantics changed.
- Final: Ruling: restart unmute raising chosen 40% gain to 100% is a settings
  persistence defect; regraded Important and fixed. Mute RED 2 failures to GREEN
  4 checks; invalid mute schema RED to GREEN through the final save suite.
- Final: minor (deferred): final-primary-rename failure and completion-save retry
  deserve dedicated fault-injection tests; backup replacement failure is covered
  and its misleading test label corrected.
- Final: Ruling: authored-spawn Continue, additional content/music/gamepad remain
  outside scope. No public API or production content edits needed.
- Final: Ruling: graphical fullscreen restart requires actual process evidence;
  added separate graphical restore stage rather than claiming headless evidence.
- Final verification: shell_beta_final, 112 assertions and all 11 stderr logs
  empty; shell_beta_01 existing regressions passed. Fullscreen restored in an
  actual separate graphical process. Manual human acceptance is NOT_RUN.
- Delivery: local branch/worktree retained, no merge/push; exact SHA manifest and
  ownership integrity recorded. User explicitly requested CLEAN / NOT_RUN push.
