# Beta Sprint — Phase 1 coordination

Current authority: [Foundation Core Freeze Decision](FOUNDATION_4_CORE_FREEZE_20261006.md), effective2026-10-06. Core is FROZEN_FOR_BETA; Full Foundation and advanced Editor are DEFERRED_POST_BETA. The earlier [Phase1 request](PHASE_1_REQUEST.txt) remains history except where superseded. Target: playable Beta before2026-11-30. Times below use Asia/Shanghai.

## 00 ownership

- OWNER_ROOTS: `docs/beta-sprint/`, Integration-owned `tests/foundation/authoring_integration/`, new coordinator smoke/build wrappers in `tests/beta_sprint/`, disposable evidence in `.godot/beta-sprint/`.
- Integration also owns shared `project.godot`, Main Scene configuration, Autoload, InputMap, audio buses, export presets and global resource registration. Owner changes to these require an `INTEGRATION_REQUEST` with the exact diff.
- FORBIDDEN_ROOTS for 00 production implementation: `foundation/`, `tools/foundation/`, `addons/`, `game/`, `prototype/`, `production/`, other Owners' tests and frozen Specs. Consume reviewed Owner commits; leave active Owner WIP in its worktree.
- A smoke/build subtask owns only its explicitly named new files and evidence. This is not permission to change an existing Owner wrapper.

## Working baseline

Primary development integration: `integration/foundation-4-authoring`, worktree `E:/godot/worktrees/block-girl-foundation-4-integration`. Starting HEAD: `9d23882638d2c491d68d58cbc360c3e60f56a894`.

`main` at `8a77874cc18ceb654664c3e9aeb10a2ccd318048` remains the P-01 playable snapshot. It is not evidence that Foundation-4 or Beta content is already shipped on main. Daily packages must identify their source branch, commit and any packaged local changes.

Current2026-10-06 decision: formal D_JOBS7836 / receipt96397ea5708e0e87dd05e3d1d4c682ca0a5478b8 and I2 Graphical352 PASS are accepted frozen Core. Editor5a70 is EDITOR_CORE_PHASE_EVIDENCE, CORE_AVAILABLE; full acceptance is NOT_ACHIEVED. D5/D6 are post-Beta and no longer Freeze or product blockers. See the Freeze Decision for exact evidence, reopening criteria and product priorities.

Current receipt is the source of delivery facts: `tests/foundation/authoring_integration/dependency_receipts.json`. A_EDIT, D_HOST, C_QUALITY and D_JOBS are formally registered. Do not repeat delivery registration. Previous Core remains historical phase evidence; the formal D_JOBS commit is7836.

## Concurrent tracks and ownership

| Track | Owner scope / existing worktree | Current handoff |
| --- | --- | --- |
| 00 Integration | This document's ownership; foundation-4-integration | Frozen Core coordination, L-01 3D product integration, focused QA and daily builds |
| 01 Runtime | Exact 4D plan paths; foundation-authoring-runtime | D_JOBS7836 formally delivered; maintenance for reproduced behavior failures, no finalization feature expansion |
| 02 Authoring | Exact 4A plan paths; foundation-authoring-data | A_EDIT delivered. Maintenance for compatibility and content-discovered P0/P1 only |
| 03 Quality | Exact 4C plan paths; foundation-authoring-quality | C_QUALITY frozen. Support reproduced correctness/content-production regressions only |
| 04 Editor | `addons/block_girl_level_tools/`, `tests/foundation/editor/`, dedicated 4B documents; foundation-editor-tools | CORE_AVAILABLE phase evidence5a70; full acceptance deferred. Bounded unavailable-action UX guard only; polish post-Beta |
| 05 Art | Existing approved production scope in `E:/Study/方块娘项目/若叶睦/model/art/production/` | Roll/six-face assets and Inner baseline exist outside the main game. Runtime consumption and approval evidence remain separate |
| 06 Content | `game/levels/mutsumi/`, `docs/game-content/`, `tests/playtest/`; beta-game-content | Content608a18 merged and accepted: L-01 formal, L-02/L-03 greybox; original P-01 preserved |
| 07 Shell | `game/shell/`, `tests/shell/`, `docs/game-shell/`; beta-game-shell | Shell7abf98 integrated with actual Content catalog; Main Scene/Save/independent Continue accepted |
| 08 QA & Build | New `tests/beta_sprint/` wrappers, separate evidence/output | Real smoke and source playable daily package. Route production defects to their Owner |

04/05 scope above is an observed or proposed routing boundary, not a new Owner acknowledgement. Each Owner must report its own OWNER_ROOTS/FORBIDDEN_ROOTS before further writes. Existing exact Foundation plan manifests remain binding within their scopes.

## Dependency decisions

1. Record local pending against the affected case or UI capability; keep other cases/tracks running.
2. A provisional dependency requires an explicit commit SHA, file hashes, approved public contract and unambiguous data format. Resolve it before Freeze. It does not change wire/save formats, gameplay semantics, Solver/Safety conclusions or public API.
3. I2 Graphical requires formal `D_JOBS`; the exact7836 receipt now satisfies it and shared i2_g01 passed352 checks. A direct local headless quality preflight is separate evidence and cannot replace formal delivery or I2 PASS.
4. D5/D6 and full Editor acceptance are DEFERRED_POST_BETA. Their unavailable actions are guarded locally; product production consumes the delivered frozen Core APIs, including TaskService.start and the worker's formal replay_run.
5. An absent future stage, an unregistered receipt with known qualified bytes, fixture/Harness work or pending art does not halt an Owner.

Reopen only the affected frozen Owner scope for a reproduced P0/P1 Foundation correctness or Beta production/playability blocker under the current Freeze Decision. Preserve failed evidence and keep deferred capabilities classified separately; missing future stages do not block current product tracks.

## Integration windows

Batch windows: 12:00 and 22:00; at most two per calendar day. Focused checks and builds outside the windows are allowed. Queue Owner commits instead of interrupting development on each delivery.

Before each batch: inspect worktree status, resolve exact delivery commits, check ownership and contract diffs, and review any shared-file integration request. At the window: merge reviewed commits, run checks appropriate to those changes, update dependency status, then generate a playable package. Preserve the last runnable integrated version if a candidate fails.

2026-10-06 pre-sprint integration activity is already present. Its window count was not supplied; do not assume two unused windows. This coordinator kickoff does not perform a merge or consume an additional batch window.

## Current next handoffs

- 01 → 00 completed: D_JOBS7836 exact files/hashes and fresh shared Unit/Real/Graphical accepted; receipt96397ea and immediate formal I2 PASS. Route any reproduced production behavior failures to01; finalization adds no further D_JOBS scope.
- 04 → 00:5a70 recorded as EDITOR_CORE_PHASE_EVIDENCE; original Unit69 PASS/real Editor47 checks8failures retained. Minimal local UX guard disables D5/D6-dependent actions. Full Editor, D5/D6 and polish are post-Beta; no B_EDITOR/D_FULL formal slot.
- 05 → 01/06/00: approved runtime assets and their consumption contract; prove roll/six-face orientation in actual gameplay before marking integrated. Inner production validation does not imply visual approval.
- 06 → 07/00 completed: actual three-level catalog, L-01 FORMAL_PLAYABLE, L-02/L-03 greybox with real play/Reset/Goal evidence. Follow-up level production stays Owner-local.
- 07 → 00 completed: Shell/Main Scene/correct actual Content catalog, menu/pause/complete/settings and independent-process Save/Load/Continue accepted. Latest user Freeze Decision reports Human QA P0=0/P1=0 and P2 L-03 hint/Inner readability feedback; earlier blind handoff is historical.
- 08 → 00: smoke results with uncovered checks explicitly UNVERIFIED, build path/type/source identity, and prioritized Owner-routed bugs.

## Next product milestone

BETA_3D_INTEGRATION_01: L-01 playable 3D Gameplay Vertical Slice, consuming current Art in actual gameplay. In parallel route QA P2 L-03 stale hint to Content with focused retest and Inner readability to Art/Content. Continue daily builds and focused QA after each product slice. L-04 remains NOT_STARTED until L-01 3D is playable and L-03 hint retest passes. These product tasks do not reopen Foundation for D5/D6.

## Freeze and daily report

FOUNDATION_4_CORE is FROZEN_FOR_BETA now. Full Foundation and advanced Editor are deferred, and the actual full Editor failure is retained. Apply the current Freeze Decision's P0/P1 reopening rule; editor polish and generic tools stay in POST_FREEZE_BACKLOG. Preserve format/semantic correctness and core playability.

Each daily record lists Foundation, D_JOBS, I2, Editor, Art, Levels 1–3, Shell, QA, build path/type, P0/P1 counts and backlog. Unknown bug counts are UNKNOWN, not zero. Distinguish fresh checks from Owner-reported or historical results.

Record player-visible changes by date. If two consecutive daily records show none, emit SPRINT_STALL_WARNING and name the infrastructure line consuming the time; a single day's initial snapshot cannot establish this warning.

Evaluate Phase1 completion against the latest Beta scope: full Foundation and advanced Editor are deferred, while remaining product outcomes still require actual evidence. Until those outcomes are met, report BETA_SPRINT_PHASE_1_IN_PROGRESS and continue the product slice. D5/D6 completeness is not a Phase1 or product blocker. The next phase after acceptance is BETA CONTENT PRODUCTION.
