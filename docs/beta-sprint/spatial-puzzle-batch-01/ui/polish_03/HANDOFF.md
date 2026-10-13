# Owner07 — QA08-C02-UI-RESET-LABEL-01

Task: SPATIAL_PUZZLE_BATCH_01_POLISH_AND_ACCEPTANCE_03
Base: e4fe5365334e93138dc9b8856d09670478789abc
Worktree: E:/godot/worktrees/block-girl-spatial-ui-polish-03
Branch: fix/spatial-ui-reset-polish-03

## Root cause and change

Native R calls Host.reset_lab directly. The actual Session Reset increments generation, restores authoritative spawn and emits committed; Shell only observed Host Goal and the mouse reset_current path. Thus the player reset while goal_seen/bottom completion title remained. The old Goal callable carried Host Node identity but no run/generation, so a delayed delivery could restore stale completion after Reset.

Only experiments/spatial_puzzle_batch_01/ui/main.gd changes production: subscribe to real committed after Host ready; validate current Host/loaded state/current authoritative snapshot; on a changed formal session/run/generation clear run completion flag/title and rebind the real Goal callback to captured scope. Goal callback rejects obsolete scope. Ordinary commits within the same lifecycle retain completion presentation; original persistent completion is preserved. No hardcoded hiding, UI Goal calculation, changed Goal rule, Runtime refactor or Host modification.

Existing tests signature audit across all tests .gd/.ps1/.py:0 direct _on_goal callers. No range-external adaptation required. Input P1 remains CLOSED and unchanged.

## Actual RED/GREEN

| Fresh run | Actual result |
| --- | --- |
| reset_red_01 |30 checks/4 expected assertion FAIL, engine exit1; actual Goal commit3/gen1→R spawn/commit0/gen2 while Shell still complete; captured gen1 callback repopulated completion after mouseReset/gen3 |
| reset_green_01 |30 checks/0 assertion failures/exit0, but446 stderr bytes from initial null Callable is_connected; recorded FAIL and fixed validity guard |
| reset_green_02 |30 checks PASS, exit0/stderr0, original4 RED assertions now pass |
| reset_full_01 |194 checks/3 harness-assumption FAIL: current Gate camera1→E camera2, and already-active Camera1 witnesses are accepted no-ops; no engine error; retained unchanged |
| reset_full_02 |**196 checks PASS**, actual PID2548, exit0/stderr0, source/cache no drift |

Command: `./tests/beta_sprint/spatial_owner_07/polish_03/run.ps1 -EvidenceName reset_full_02`.
Actual engine: Godot4.7.2.stable.steam.ed1daf0bf, headless, isolated fresh APPDATA/LOCALAPPDATA / original Store slot. No physical OS keyboard/Human QA claim; native Input.parse_input_event crosses real Menu/Host input routing. Positive Goal only through actual actions and natural Presenter completion. Obsolete callbacks/finish identities are negative probes after actual Goal/reset/reload, never positive Goal evidence.

Coverage: real Gate D→Space→S→Goal→R→Goal, mouse parity, sticky completion on ordinary Camera commit, eight rapidR, exit/menu reentry, real same-Host reload and old run callback rejection, old generation/state callback rejection, pending Shift/Camera/Fall Reset and old completion rejection, elapsed old Fall duration, actual saved-authoring witnesses/Goal/keyboardReset across all5 maps. Approved author resources/L01-L05/Host/Runtime/Save/Tokens/project/Art unchanged.

Source hash closure342 files,18 approved imported cache files and engine SHA recorded in raw run. Commit-bound exact tested/live/Git proof will be recorded in DELIVERY_BINDING.json; original execution HEAD/WIP retained. Only scoped raw report/log files archived, not profiles/player saves. All previous external QA evidence untouched.

## Delivery and acceptance boundary

Owner Local: PASS, headless focused fix. Source commit and final Owner Push / independent full remote SHA appear in the final task Handoff after those operations. Only Main and the new polish_03 test/doc prefixes are delivered.

00 integration/new Build/08 independent graphical recheck: PENDING_00.
Graphical/3-resolution/visual regression: NOT_RUN (no GUI permission this round).
Human QA: NOT_RUN; no old PASS inherited.

00 can integrate this minimal UI change, build a new immutable package and hand08 Goal→R→Goal plus pending-motion Reset for actual graphical recheck. No shared Host interface change or candidate diff is required. Local headless evidence does not close the QA defect's integrated/graphical acceptance by itself.
