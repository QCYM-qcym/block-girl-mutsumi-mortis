# Beta Sprint — Phase 1 coordination

Authoritative request: [PHASE_1_REQUEST.txt](PHASE_1_REQUEST.txt). Target: playable Beta before 2026-11-30. Foundation-4 Freeze window: 2026-10-12 through 2026-10-15. Times below use Asia/Shanghai.

## 00 ownership

- OWNER_ROOTS: `docs/beta-sprint/`, Integration-owned `tests/foundation/authoring_integration/`, new coordinator smoke/build wrappers in `tests/beta_sprint/`, disposable evidence in `.godot/beta-sprint/`.
- Integration also owns shared `project.godot`, Main Scene configuration, Autoload, InputMap, audio buses, export presets and global resource registration. Owner changes to these require an `INTEGRATION_REQUEST` with the exact diff.
- FORBIDDEN_ROOTS for 00 production implementation: `foundation/`, `tools/foundation/`, `addons/`, `game/`, `prototype/`, `production/`, other Owners' tests and frozen Specs. Consume reviewed Owner commits; leave active Owner WIP in its worktree.
- A smoke/build subtask owns only its explicitly named new files and evidence. This is not permission to change an existing Owner wrapper.

## Working baseline

Primary development integration: `integration/foundation-4-authoring`, worktree `E:/godot/worktrees/block-girl-foundation-4-integration`. Starting HEAD: `9d23882638d2c491d68d58cbc360c3e60f56a894`.

`main` at `8a77874cc18ceb654664c3e9aeb10a2ccd318048` remains the P-01 playable snapshot. It is not evidence that Foundation-4 or Beta content is already shipped on main. Daily packages must identify their source branch, commit and any packaged local changes.

Current2026-10-06 finalization: D_JOBS7836 is formally registered by receipt96397ea5708e0e87dd05e3d1d4c682ca0a5478b8; actual I2 Graphical352 PASS. Both prerequisites for Freeze are satisfied; basic integrated Editor acceptance remains pending. See the latest daily record. Earlier handoff table/dependency snapshots below are historical kickoff context.

Current receipt is the source of delivery facts: `tests/foundation/authoring_integration/dependency_receipts.json`. A_EDIT, D_HOST, C_QUALITY and D_JOBS are formally registered. Do not repeat delivery registration. Previous Core remains historical phase evidence; the formal D_JOBS commit is7836.

## Concurrent tracks and ownership

| Track | Owner scope / existing worktree | Current handoff |
| --- | --- | --- |
| 00 Integration | This document's ownership; foundation-4-integration | Focused regression, I2, build, dependency/ownership coordination |
| 01 Runtime | Exact 4D plan paths; foundation-authoring-runtime | D_JOBS7836 formally delivered; maintenance for reproduced behavior failures, no finalization feature expansion |
| 02 Authoring | Exact 4A plan paths; foundation-authoring-data | A_EDIT delivered. Maintenance for compatibility and content-discovered P0/P1 only |
| 03 Quality | Exact 4C plan paths; foundation-authoring-quality | C_QUALITY delivered. Support orchestration/I2 and existing checks on Level 1 |
| 04 Editor | `addons/block_girl_level_tools/`, `tests/foundation/editor/`, dedicated 4B documents; foundation-editor-tools | Existing partial plugin. Continue against stable TaskService ports; unavailable stages remain local UI pending |
| 05 Art | Existing approved production scope in `E:/Study/方块娘项目/若叶睦/model/art/production/` | Roll/six-face assets and Inner baseline exist outside the main game. Runtime consumption and approval evidence remain separate |
| 06 Content | `game/levels/mutsumi/`, `docs/game-content/`, `tests/playtest/`; beta-game-content | Content608a18 merged and accepted: L-01 formal, L-02/L-03 greybox; original P-01 preserved |
| 07 Shell | `game/shell/`, `tests/shell/`, `docs/game-shell/`; beta-game-shell | Shell7abf98 integrated with actual Content catalog; Main Scene/Save/independent Continue accepted |
| 08 QA & Build | New `tests/beta_sprint/` wrappers, separate evidence/output | Real smoke and source playable daily package. Route production defects to their Owner |

04/05 scope above is an observed or proposed routing boundary, not a new Owner acknowledgement. Each Owner must report its own OWNER_ROOTS/FORBIDDEN_ROOTS before further writes. Existing exact Foundation plan manifests remain binding within their scopes.

## Dependency decisions

1. Record local pending against the affected case or UI capability; keep other cases/tracks running.
2. A provisional dependency requires an explicit commit SHA, file hashes, approved public contract and unambiguous data format. Resolve it before Freeze. It does not change wire/save formats, gameplay semantics, Solver/Safety conclusions or public API.
3. I2 Graphical requires formal `D_JOBS`; the exact7836 receipt now satisfies it and shared i2_g01 passed352 checks. A direct local headless quality preflight is separate evidence and cannot replace formal delivery or I2 PASS.
4. Integration's old preflight lists `replay_run` as a missing capability. Runtime WIP is using the existing `start` API to dispatch replay. Update I2 against the actual approved Owner delivery; do not demand a new public API merely to match an old test assumption.
5. An absent future stage, an unregistered receipt with known qualified bytes, fixture/Harness work or pending art does not halt an Owner.

Stop the affected scope for real contract, corruption or gameplay semantic conflicts. Stop all tracks only for the five conditions in the request's STOP ONLY IF section. Preserve failed evidence; do not turn setup failures or missing dependencies into successful gameplay checks.

## Integration windows

Batch windows: 12:00 and 22:00; at most two per calendar day. Focused checks and builds outside the windows are allowed. Queue Owner commits instead of interrupting development on each delivery.

Before each batch: inspect worktree status, resolve exact delivery commits, check ownership and contract diffs, and review any shared-file integration request. At the window: merge reviewed commits, run checks appropriate to those changes, update dependency status, then generate a playable package. Preserve the last runnable integrated version if a candidate fails.

2026-10-06 pre-sprint integration activity is already present. Its window count was not supplied; do not assume two unused windows. This coordinator kickoff does not perform a merge or consume an additional batch window.

## Current next handoffs

- 01 → 00 completed: D_JOBS7836 exact files/hashes and fresh shared Unit/Real/Graphical accepted; receipt96397ea and immediate formal I2 PASS. Route any reproduced production behavior failures to01; finalization adds no further D_JOBS scope.
- 04 → 00: reviewed Editor commit and real stable-service lifecycle checks; stages without support display pending/unavailable. Plugin activation is a shared-file integration request.
- 05 → 01/06/00: approved runtime assets and their consumption contract; prove roll/six-face orientation in actual gameplay before marking integrated. Inner production validation does not imply visual approval.
- 06 → 07/00 completed: actual three-level catalog, L-01 FORMAL_PLAYABLE, L-02/L-03 greybox with real play/Reset/Goal evidence. Follow-up level production stays Owner-local.
- 07 → 00 completed: Shell/Main Scene/correct actual Content catalog, menu/pause/complete/settings and independent-process Save/Load/Continue accepted. Blind Human QA remains READY/NOT_RUN.
- 08 → 00: smoke results with uncovered checks explicitly UNVERIFIED, build path/type/source identity, and prioritized Owner-routed bugs.

## Freeze and daily report

Use the request's Freeze criteria; only core formal D_JOBS/I2 and a basically usable Editor are required. After Freeze, non-P0 tools enter POST_FREEZE_BACKLOG. Preserve format/semantic correctness and core playability.

Each daily record lists Foundation, D_JOBS, I2, Editor, Art, Levels 1–3, Shell, QA, build path/type, P0/P1 counts and backlog. Unknown bug counts are UNKNOWN, not zero. Distinguish fresh checks from Owner-reported or historical results.

Record player-visible changes by date. If two consecutive daily records show none, emit SPRINT_STALL_WARNING and name the infrastructure line consuming the time; a single day's initial snapshot cannot establish this warning.

Emit BETA_SPRINT_PHASE_1_READY only when all nine phase-end outcomes have actual evidence. Until then report BETA_SPRINT_PHASE_1_IN_PROGRESS with local pending; continue preparing the current slice. The next phase after acceptance is BETA CONTENT PRODUCTION.
