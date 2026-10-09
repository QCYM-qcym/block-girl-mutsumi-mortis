# BETA-3D-INTEGRATION-02 independent final source review

Reviewed 2026-10-09 in `E:/godot/worktrees/block-girl-beta-3d-integration-02`, branch `feat/beta-3d-integration-02`. Fixed baseline: `dc0bd64b53a9ee3c0c12d4bd7f25ab1ab92df916`; review HEAD: `0abb91610d28d967b1e9883318e9b5fa4b6de972`, including its L02 commit, tracked L03 working changes, and the untracked coordinator helpers. Requirements are the user-authorized scope recorded in [the plan](../../superpowers/plans/2026-10-09-beta-3d-integration-02.md) and [PROGRESS.md](PROGRESS.md).

**Final source-review result after scoped verifier re-review: Critical 0 / Important 0 / Minor 0. Production presentation source and the corrected delivery helper pass this review. Final build and delivery gates remain pending below.** No engine was launched and no production or test file was changed by this reviewer.

## Findings

### Closed Important finding: bind the accepted build to the current delivery source

Corrected location: `docs/beta-sprint/three-d-integration-02/verify_delivery.ps1:33-39`, under the optional `BuildName` verification.

The initial helper checked copied files only against the build's own manifest and did not restrict its QA status. The corrected helper also compares every copied non-document payload hash with the current delivery source at line35, rejects either copy/source mismatch at line38, and at line39 accepts only `PASS` or `PASS_WITH_KNOWN_BASELINE_P2` with QA HEAD equal to manifest HEAD. The reviewed source/binding changes therefore cannot be silently replaced with an older self-consistent build. Receipt-only documentation commits remain possible without requiring the final Git HEAD to equal the build snapshot HEAD.

The scoped re-review also checked the source-evidence exception at lines20-23. It applies only to `production/ui/beta_shell_01/icons_source.svg.import`, only when the run SHA is the initial audited importer output `f6fff508689ec701d1fa0fb7f71b7185278a86da692160d8c1b198e5c0d2bc0d`, and only when the current SHA is the frozen Git value `c7911c2c43b002f31f1f245405f17fa1c6f086d342f831f4f643fb9b91af7b05`. No path wildcard, arbitrary source mismatch, Runtime/art/config/test exception, stderr exception or altered graphical-result acceptance is introduced. This permits exact metadata restoration while preserving L03/L01 actual evidence for the same production/test code.

The initial repository filter used `content`, although the audit key is `content_06`. The coordinator corrected it at `verify_delivery.ps1:11` and limits immutable external HEAD checks to Main/Integration at line44. Content06 is observed without blocking its owner's separately authorized future hint delivery; the feature's own protected hint hashes remain strict. No open Minor finding remains for that issue.

Read-only execution of the corrected verifier with `-EvidenceNames l03_g01,l01_g01`, without a build or clean-tree requirement, returned both cases PASS with zero source mismatches and only the exact named metadata-restoration record. It also returned protected/art/old08-project mismatches empty and old08 ZIP unchanged. Its PowerShell syntax check has zero errors. The build guard was inspected statically because the new candidate build is still pending.

## Standards axis

No production code-quality blocker was identified. The original L01 attachment adds only the default `_create_presenter()` factory and uses it for construction at `game/levels/mutsumi/batch_01/l01_3d/l01_presented.gd:13,35`. The original Presenter adds only the two-line absent-mechanism guard at `game/levels/mutsumi/batch_01/l01_3d/presenter.gd:306`. Roll interpolation, physical cube basis, camera framing/orbits, shift reconstruction, material handling, physics disabling, occlusion decisions and Reset remain inherited.

The new attachment at `game/levels/mutsumi/batch_01/levels_3d/presented_level.gd` chooses and names the subclass after the existing lifecycle. It retains the original Pixel board, ContentState, GridMovement, PerspectiveController, approved HUD and Shell integration. The subclass overrides asset construction, mechanism observations and diagnostics; no rewritten behavioral algorithm or unrelated abstraction was found. The diagnostic dictionary repeats the base observation shape to handle absent mechanisms, but this is small and does not introduce a second gameplay algorithm.

The three PowerShell helpers parse with zero syntax errors. The delivery validation finding above is closed after the scoped re-review.

## Spec axis

- **Support and approved assets:** `levels_3d/presenter.gd:14-18` creates one approved FLOOR wrapper for each original per-world cell and takes platform IDs from `graph.nodes`. L02 has exactly its original Surface7/Inner5 footprints; L03 has its original seven cells in each world, retaining the logical `(3,2)` to `(9,2)` gap and platform1 ownership. There is no L01-only bridge, pressure plate or gate. The approved one-cell floor contract uses walk height0.24. Existing `_instance()` and `_disable_asset_physics()` disable imported collision and Area monitoring recursively.
- **Optional exit and global shift:** the exit is created only where the original Goal cell has support, at `levels_3d/presenter.gd:21-24`. Its state observes Goal/world. The world-switch assets remain decorative cues for native Space; they do not add activation areas, rules or support.
- **Formal connection:** L03 retains the original `PerspectiveLink`/authored anchor pair. `levels_3d/presenter.gd:38-53` attaches two real Label3D observations to those anchors, using approved shared typography and only a vertical stagger where EAST positions coincide. At lines61-66 their text reads `graph.link.active and not view.busy`; visibility reads actual world support, and position follows the inherited interpolated platform offset. Wrong-world EAST keeps adjacent visible floors, but clearly shows two `未连接` labels. The retained screenshot `l03_g01/gameplay_mutsumi_l03/028_probes_wrong_world_blocked.png` was visually inspected and supports that conclusion. Rotation suppresses the stale committed-link readout until the view settles.
- **Authority:** all new production assignments target presentation nodes, materials or diagnostic values. No writes to mover cell/world/orientation/phase, graph support/link permissions, Content resources, Save/Load, hints, Runtime/Foundation or gameplay signals were found. Scene changes are script-reference-only. Meshes, physics, labels and transforms never decide movement or completion.
- **Lifecycle and test harness:** `test_gameplay.gd:107-112` fixes the focused Shell Complete-button Space acceptance issue by querying the existing completed `mover.shift()` guard and testing real E/S inputs. It no longer activates native navigation and then dereferences an unloaded level. The fixture deliberately uses the existing SaveStore with already unlocked levels and a fresh `user://beta_sprint/b3d02_*` path; it introduces no Save implementation or unlock/Cold Continue matrix.
- **Observation contract:** `test_gameplay.gd:133-139` records native cell, world, orientation, marked face, view, link, plate, gate, Goal, moves and phase; identical input arrays plus per-commit and settled-view observations are compared between Pixel and 3D. This is explicitly P01 Native Gameplay observation SHA256, not Foundation `statekey.v1`. Existing routes remain the source of solutions. L02/L03 run normal, Reset replay and alternate-view inputs; L01's original route exercises plate/gate, roll, view, shift and Goal.
- **Scope preservation:** the initial independent SHA reads of all830 protected files differed only at the known generated `production/ui/beta_shell_01/icons_source.svg.import`. The coordinator restored that file to its exact frozen SHA above. The scoped final verifier now reports all830 protected files matching the baseline, including Runtime, Foundation, Save/Load, hints, map resources, approved art source and project configuration. The frozen SVG source was not repaired or changed.

## Existing actual evidence read

| Case | Entry | Graphical | Result |
| --- | --- | --- | --- |
| `l02_g02` | PID42660, 9 checks | PID49124, 445 checks | PASS; 3 matching Pixel/3D route pairs |
| `l03_g01` | PID36536, 9 checks | PID33684, 1349 checks | PASS; exact native connection/wrong-world/disconnect/crossing checks |
| `l01_g01` | PID29008, 9 checks | PID26816, 279 checks | PASS; native L01 regression and all six marked-face directions |

All six recorded stages have exit0, `failures=[]`, positive checks and actual stderr length0. Gameplay uses `display=Windows`; source `changed_sources=[]` in all three run reports. L03/L01 recorded source hashes match the production/test snapshot read during this review, with only the exact unused generated-metadata restoration now accepted by the corrected verifier. These two graphical gates do not need rerunning for that restoration. L02's accepted earlier gate predates the L03 scene binding, shared Presenter marker extension and test extension, so its earlier source comparison has three expected mismatches; the coordinator is running the final L02 gate against the current code and restored metadata.

The build helper `tests/beta_sprint/three_d_02/build_qa.ps1:24-41` preserves the base builder's original failed import record and permits only the three exact known SVG error lines for the initial import, with exit0/no timeout/no stdout error. Accepted boot stderr must match SHA256 `bf8149e7a4c220bbef9c5eac13cd97f17ae895e5fff5a7befa152e30319f4d9d`, the known133-byte ObjectDB exit warning. This classification is confined to build import/boot evidence; `run_integration.ps1` requires all actual graphical cases to have empty stderr, positive checks, empty failures and exit0. It does not weaken graphical gates or fix frozen SVG source.

## Limits and remaining final gates

This review read code, manifests, hashes, existing process reports and one relevant real L03 screenshot. It did not independently replay input, prove first-player comprehension, launch a source build, export an executable, run Human/08 QA or establish Foundation RuntimeSession acceptance.

Required before final delivery: finish the current-code final L02 graphical gate; produce and verify the fresh isolated QA source build; confirm source/copied hashes, final protected/old08/Main/Integration preservation and clean committed feature worktree; record receipt/handoff. The source builder and the final verifier's optional build branch have not been executed by this reviewer; its L03/L01 source-evidence and protected-file branches were executed read-only during the scoped re-review. Human QA remains `NOT_RUN_FOR_NEW_BUILD`; Push remains `NOT_RUN`; `STAIR_CLEARANCE=PARTIAL_PASS` and `STAIR_TRAVERSAL=NOT_RUN` are preserved. No new Foundation migration, new puzzle, hint repair or future-stage requirement is added.

## Reviewed production/test snapshot SHA256

| File | SHA256 |
| --- | --- |
| `game/levels/mutsumi/batch_01/levels_3d/presenter.gd` | `e3cf9fbfbc5e7049eeaa67e15578a12219c76d96792a3390e2b370771a2ff7e4` |
| `game/levels/mutsumi/batch_01/levels_3d/presented_level.gd` | `9f201206c16cfc62bdad1a6f39d68aedf8eb0639da7618f27c41cb268f0f8435` |
| `game/levels/mutsumi/batch_01/l01_3d/presenter.gd` | `0bb1c430b5ce078b3ff811ba2e42e7edb375f7056378f6f2ceceb1c6dce54a23` |
| `game/levels/mutsumi/batch_01/l01_3d/l01_presented.gd` | `a72dfde4c7b69294c887d1cebc8c29dce49f0b0d2f3b2b74694efc1d0e113b0e` |
| `game/levels/mutsumi/batch_01/l02_between_shores.tscn` | `6f9717ac84efe7603503db17b822890d7e790333cf42a6c063300c2dff9e0913` |
| `game/levels/mutsumi/batch_01/l03_lines_meet.tscn` | `45859ddcdc0dfc67d3a502fd5430ad129d053fffc447520a019b85ea71a1b86a` |
| `tests/beta_sprint/three_d_02/test_gameplay.gd` | `ea5698b3e4dcf740a8caae2b7b18bf7605c661c374ac1e3266bd5a2d6ac24da5` |
| `tests/beta_sprint/three_d_02/run_integration.ps1` | `c21344264e83319e152422d98fdaa905addb6e9ab70ec1c8f74e487626de792a` |
| `tests/beta_sprint/three_d_02/build_qa.ps1` | `1359e0be79bcc90478abd911711cb7afcdf68956122b655dfd02f44aa17c791f` |
| `docs/beta-sprint/three-d-integration-02/verify_delivery.ps1` (scoped fix) | `a86f5a0581c32b2b1fda48fae01c324ae1e4637ff45f99134f4454a5e22df239` |

Standards: zero open findings after the delivery-helper fix. Spec: zero production source findings. Final build/delivery acceptance remains pending.
