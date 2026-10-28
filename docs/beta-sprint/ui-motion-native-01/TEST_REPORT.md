# Native character menu — verification

2026-10-29, Godot 4.7.2, native Windows D3D12 renderer. User-approved V4 is implemented in the actual Godot Shell. The browser prototype is not a product dependency.

| Scope | Result | Limits |
|---|---:|---|
| Native graphical matrix | 144 PASS, 0 failures | 23 original frames, 1920×1080 / 1280×720 / 960×720; menu Surface/Inner, real mouse events, keyboard Tab, settings, catalog footer, character gestures, actual L01 entry/pause/reset/resume |
| Backdrop lifecycle | 24 PASS | Headless assertions, actual approved meshes, no physics/gameplay state |
| Palette and checkbox contrast | 6 PASS | Foreground/filled-background preserved; source SVGs unchanged |
| Native View | PASS | Existing actions, disabled Continue/locked levels, confirm, toolbar focus, scrolling, gameplay background |
| Native settings | 15 PASS | Drawer bounds, long error, actual option API; headless |
| Host/Runtime world seam | 19 PASS | Actual S01 World Shift/Reset; injected one-entry catalog, no progression claim |
| Actual persistence failure/cancel/retry/cold restore | 134 PASS | Two independent processes, real SaveStore failure seam, audio and accessibility; headless |
| Existing catalog/settings/Goal-landing | 79 / 9 / 15 PASS | Focused resource/real seams; settings/landing use one-entry fixtures |

All listed successful process runs exited 0 with empty stderr. No new full ten-level playthrough, Human QA, full state-graph certification or asset approval is claimed. Old passes remain historical.

Actual PNGs were inspected, including both worlds, each required size, settings checkmarks and catalog navigation. Review fixes: keyboard access/visible focus for toolbar, stacked narrow catalog footer, reduced-motion propagation to the experimental menu entry, and preserving checkbox marks when recolouring filled icons. Initial failed test runs and raw evidence are preserved outside this repository and are not counted as passes.

Independent component/Host review and final whole-change review completed; no remaining actionable findings at review time. See EVIDENCE_INDEX.json for original paths and hashes. SOURCE_IDENTITY.json records task sources and unchanged approved models.

Runtime/Foundation/SaveStore algorithms, puzzles, frozen art sources, project settings, previous QA packages/saves/evidence remain unchanged. A2 candidate assets are not consumed. Connection readiness remains pending its real Runtime facade; the settings note states that limit.

Final revision: native_graphical_20261029_07 repeated the 144-check matrix after correcting the Surface floor shortcut ink. All checks PASS, empty stderr. Initial23 frames remain unchanged; final23 originals are separately preserved. One final Surface frame is published under screenshots/final07. The first candidate package _01 remains immutable; final delivery uses the new _02 package.

Copied final _02 package:144 native graphical checks,23 original frames and19 Host/Runtime checks PASS;1920 declared files verified without change. Launcher enters the real main scene, exit0. Explicit timed `--quit-after` smoke reports2 ObjectDB-instance warnings (both12/180 frame samples); these are retained as P2 shutdown backlog and are not counted as empty-stderr passes. Normal Shell request_quit in the full graphical test exits with empty stderr. Human QA remains NOT_RUN.
