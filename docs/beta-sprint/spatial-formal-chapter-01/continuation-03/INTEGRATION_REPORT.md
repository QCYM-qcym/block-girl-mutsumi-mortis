# SPATIAL_FORMAL_CHAPTER_01_CONTINUATION_03_REPORT

Date: 2026-10-21, Asia/Shanghai. Owner: 00 Integration Coordinator.

Baseline HEAD: `f972cb850845cb2c31da6975ac7466437aafdec2`.
Branch: `feat/spatial-formal-chapter-01`.
Worktree: `E:/godot/worktrees/bg-formal01`.
Baseline working tree: CLEAN. The remote branch independently matched this SHA. One baseline-query attempt failed with a Schannel TLS handshake error; a normal retry succeeded without changing TLS verification or Git security settings.

The retained Build is `E:/godot/beta-sprint-builds/beta_spatial_formal_chapter_20261019_01`, source `763f0132bc58360fab0e224d0e9c54e00c92ae90`. All 1,783 manifest files were rehashed with zero mismatches. ZIP SHA256 remains `38213cdca4987aff17e39e734e8bf6e0ee2e7d3e5588c749cd4bb1ea7d189307`. This is a documentation/test-evidence integration; the Build source does not advance with its receipt commit.

## S05 State Graph — actual increment

| Item | Actual |
| --- | --- |
| Initial States / Edges | 418 / 1,666 |
| Initial unexpanded non-Goal frontier | 56 |
| New States / Edges | 490 / 2,250 |
| Final observed States / Edges | 908 / 3,916 |
| Original frontiers expanded first | 56 / 56 |
| Total frontiers expanded this run | 476 |
| Remaining Frontiers | 0 |
| Goal states | 96 |
| States with a witnessed path to Goal | 908, previously 355; increase 553 |
| Previously unknown 63 states | All now have a Goal path |
| Incremental action evaluations | 5,712: 2,985 rejected, 2,251 changed, 476 no-op |
| Previously saved partial-node edge | 1 revalidated and deduplicated |
| Safety-unproven rejection code 1601 | 0 in this incremental run |

The exact saved 418 states and first 1,666 edges are preserved. The initial 56 frontiers were processed before new successors. Their phase added 71 states / 258 edges, producing 489 states / 1,924 edges and 61 newly queued states. Type recovery took 42.101 seconds, the initial-frontier phase 32.944 seconds, and total continuation after recovery 345.752 seconds. Search finished because its queue was exhausted, below the 800-second internal deadline and 2,500-state / 15,000-edge guards. The final checkpoint's elapsed field is 387.688 seconds; search-end timing after saving is 387.853 seconds. JSON and typed binary checkpoints preserve per-frontier actions and the queue.

All transitions use the formal ActionGenerator and PuzzleRuleKernel, including its Safety and permission calls. Saved JSON states are recovered through formal predecessor actions and checked by the complete StateKey. Test code only manages restoration, ordering and evidence; it defines no alternative movement or mechanism rules.

The incremental process completed 12,891 checks with zero failures, empty stderr and expected exit 3 (explicit provenance dependency pending). A separate fresh-process typed-checkpoint read-back passed 6 checks. Native Runtime replayed a 30-step prefix to a newly reached state and Reset restored exact spawn StateKey, idle state and zero commit count. Reset is sampled, not asserted for every state or interrupted lifecycle. A separate live frontier-start Explorer trace passed formal semantic validation; this is not a graphical TraceReplayer result.

### Formal certification

**State Graph: PARTIAL.** The separate live public Explorer reached its 580-second search budget at 580.026 seconds: 785 states, 3,328 edges, 768 expanded states (including 80 terminal Goals), 17 unexpanded frontiers and 8,265 candidate actions. The unmodified live graph was passed directly to the public Softlock Analyzer: 746 states have Goal paths, 39 remain unknown, `softlock_count=null`, `complete=false`. This is an actual incomplete certification, not a hypothetical interface limitation or a failed Gameplay assertion. Its shortest Goal route is seven actions. No further search was run after the stage budget was used.

The certification process finished in 619.012 seconds, with 410 checks, zero failures, empty stderr and expected exit 3 for incomplete coverage. Across setup, incremental search, typed-checkpoint verification and certification, total engine time was 1,136.299 seconds, below the 1,200-second stage ceiling. The assembled incremental graph still retains `complete=false` and its own analyzer's null softlock count, even though all 908 observed states have Goal paths. Neither record is rewritten to borrow the other's provenance or coverage. The zero remaining incremental frontiers and 17 remaining live-certification frontiers refer to different graph products.

00 independently confirmed that all 785 live states match the corresponding full incremental states and the 3,328 live edges match the ordered prefix of the incremental graph. Across the three test processes, 13,307 checks have zero failures; this is not a complete-state-space PASS.

| Classification | Actual supported conclusion |
| --- | --- |
| Ordinary dead ends | None among the 908 incremental states with recorded Goal paths; 39 states remain unknown within the smaller live-certification graph. Unknown is not a proven dead end. |
| Reset-only recovery | No state in the incremental observed set needs Reset to reach Goal. Native Reset was independently sampled on one 30-step reached state; every-state/lifecycle Reset was not run. Formal analyzer reset-only count remains null. |
| Legal operations blocked by implementation error | None observed in checked permission/orientation invariants; no independent exhaustive legality oracle, so no universal absence claim. |
| Non-design unrecoverable softlocks | None proven. Formal whole-domain softlock count is unresolved/null, never reported as zero. |
| Unexpected shortcuts | Zero checked non-Fall entries into the authored Goal island; this is not exhaustive designer-intent or post-Goal shortcut acceptance. |

The next minimum technical choice is a separately budgeted larger native Explorer run, or an Owner-approved supported typed-resume interface; neither is implemented here. The saved original/new frontiers, full transition records and typed checkpoints are retained for reuse. See [Quality method](quality/METHOD.md) and [machine-readable results](quality/RESULTS.json) for exact phase receipts, rejection classifications, source binding and evidence hashes.

S01–S04 results remain their separate historical first-Goal-terminal results. Post-Goal actions, pending/busy/cancel combinations, actual keyboard/GUI delivery, every-state Reset, and human understanding are outside this graph's coverage. No old level logic or Foundation implementation changed.

## Art Resource Audit

Read-only audit delivered by `docs/spatial-formal-art-cont03`, worktree `E:/godot/worktrees/bg-art-cont03`, final Owner commit `2fe020ec3c48aff10685874511de35c77b017354`. It preserves the initial audit commit `b6fca3381632c874f5697d8a4c627902dd4549a7`. Both are actual history; the final branch SHA was independently verified remotely.

Source root: `E:/Study/方块娘项目/若叶睦/model/art/production/work/GAME_ART_MECHANICS_BATCH_01`.
Backup root: the same parent with package name `GAME_ART_MECHANICS_BATCH_01_SCOPE_RECOVERY_20261013`.

| File relative to each root | Actual finding |
| --- | --- |
| `design/states/face_lock_D.svg` | Current layout corroborates the historical generator edit to text baseline and rail geometry. Current = post-incident backup; both differ from original manifest hash. Exact original text unavailable. |
| `design/states/face_lock_D.png` | Six panel pixel samples corroborate changed rail placement. Current = backup pixels and hash. Missing original PNG prevents an original/current full pixel comparison. |
| `reports/DRAWING_CONTACT_SHEET.png` | All 28 current tiles exactly match current source PNGs after documented resize/background composition: 0 differing pixels across 3,628,800 pixels. Twenty-seven source PNGs match the original manifest; the Face Lock D source differs. This does not prove only one historical tile changed. |

The [Art audit](art/ART_AUDIT.md) contains the exact original/current/backup SHA256 table, full paths, per-file classifications, recovery risks and provenance limits. These identities were freshly checked; 00 independently rechecked all 37 watched source/backup/dependency files against the Owner evidence. The expected 22 transparent corner pixels per raw-resized tile are explained by background composition; they are not a new content defect.

The external package is outside Git. A bounded local reachable-history scan found no exact-name original export among 13,062 objects. This is not an exhaustive search of untracked archives, alternate names or unfetched history. Original manifest provenance remains corroborated local evidence rather than an independently immutable anchor. The backup is post-incident and is not an original recovery candidate.

Art Recovery: **PENDING**. Preserve current files and backups. The smallest next operation is read-only comparison of a trusted Owner-provided original package/file set at a named location. No recovery, regeneration or master replacement is authorized. No reference to these three exports was found in the retained prior static Build audit; current payload integrity was separately reverified by 00. Dynamic/native/runtime I/O remains outside that non-reference proof.

00 review additionally found a rerun-overwrite risk in the audit helper's fixed output location. The Owner corrected it to require a new absolute directory and exclusive output creation. Syntax and rejection-path checks passed; the original pixel audit was not rerun or overwritten. This is a test-evidence preservation fix, not an Art or Gameplay change.

## Input Environment

Owner branch `test/spatial-input-env-cont03`, worktree `E:/godot/worktrees/bg-input-c03`, commit `2ce5656412a9678d424f08b29d8771b73822e913`; normal push and exact remote SHA independently verified.

Diagnosis: **E — UNKNOWN**. At 2026-10-21 06:27:48Z, no Godot-named process was observed and old QA PID 32312 was absent. This point-in-time result does not exclude renamed executables or identify how/when the former process exited. Unrelated foreground-window identity/content was not recorded.

Historical QA evidence: 16/16 manifest hashes match. Five scoped game/launcher logs contain no input dispatch/receipt telemetry. Two tool guard failures are recorded in the old report, but there is no correlated raw call ID, send acknowledgement, target-at-dispatch identity and game receipt. They do not prove nonreceipt, wrong-window input or an identifiable interfering actor. Current native control is disabled by the tool contract; the narrow process-name probe does not establish backend health.

Confirmed Cause: **UNKNOWN**.
Graphical Diagnostic: **NOT_RUN**.
User Window Modified: **NO**.

The [diagnosis](input/REPORT.md) provides the A–E evidence matrix and minimum next diagnostic: an independent desktop/session or VM, supported native tool access, a fresh isolated profile/window, and one correlated send/receive observation. No repeated injection, game launch, focus change, input, screenshot of another application or process termination occurred in this stage.

## Human QA and Floating Cube

HUMAN_QA: **NOT_RUN**. Qualified Player: **NONE**. No observations, predictions, timings or quotations are invented. Earlier user play and known-route replay remain separate. The [execution addendum](HUMAN_QA_EXECUTION_ADDENDUM.md) updates the old PID/focus assumptions while preserving the original protocol and empty observation template.

Floating Cube: **PENDING_USER_REVIEW**. A opaque coarse material / B inset edge markings / C necessary use explanation remain isolated proposals. ART_IMPLEMENTATION = **NOT_AUTHORIZED**. No occluder deletion, walkable-face conversion, hidden road or Runtime permission change occurred.

## Production, preservation and GitHub

| Owner | Branch / Worktree | Accepted commit |
| --- | --- | --- |
| 03 Quality | `test/spatial-formal-frontier-cont03` / `E:/godot/worktrees/bg-fsc03` | `bdc04b7a42548ea237247f29a56ed90294446e37` |
| 05 Art audit | `docs/spatial-formal-art-cont03` / `E:/godot/worktrees/bg-art-cont03` | `2fe020ec3c48aff10685874511de35c77b017354` |
| Input diagnosis | `test/spatial-input-env-cont03` / `E:/godot/worktrees/bg-input-c03` | `2ce5656412a9678d424f08b29d8771b73822e913` |

Each Owner used an independent worktree from the verified baseline, changed only its assigned documentation/test paths, completed normal push and exact remote SHA verification, and handed off a clean worktree. No shared production-file conflict exists. 00 reviewed the actual commit scopes and evidence; all 158 files in the Quality evidence hash index match. Owner integration follows a normal merge preserving their commits, not squash, rebase, reset or repeated cherry-pick.

Production Changes: **NONE**. New Build: **NOT_REQUIRED**. No new Gameplay defect is confirmed in the actual covered scope; input cause, Art original-byte recovery and first-time comprehension remain unresolved, not counted as zero-risk conclusions.

The old QA profile has 69 files at this stage's baseline: all 67 files recorded previously retain their hashes; two additional shader-cache files have 2026-10-19 02:10:19Z modification timestamps. These are preserved as found. The original Build profile remains absent. No stored progression was edited. Existing Build, ZIP, graph, QA screenshots/reports, A/B/C preview files and baseline profile snapshots are protected by before/after hash checks.

Only current Owner documentation/test paths are accepted. No main, Release Tag, release branch, historical experiment branch, production resource, L01–L05 puzzle or other Owner WIP is changed. Stage delivery does not imply Beta release acceptance.

The normal multi-parent merge completed without conflicts. Integrated verification passed: 1,783 Build payload hashes, ZIP identity, prior reports/graph/screenshots, all 1,759 files in the retained A/B/C preview directory, both baseline profile snapshots, and protected Git refs remain unchanged. The five delivered JSON documents parse, 13 relative documentation links resolve, Python/JavaScript/PowerShell helper syntax checks pass, and the Git whitespace/scope checks pass. Only the two new test directories and continuation-03 documentation are changed. No unrelated Godot matrix or GUI test was rerun for this documentation/test integration.

00 external evidence: `E:/godot/beta-sprint-builds/spatial_formal_cont03_00_20261021_01`. Baseline, Owner review, checkpoint-accounting and preservation receipts are retained there. The post-commit `FINAL_DELIVERY.json` records the actual integration SHA, normal push result, independent remote SHA and final clean state; no self-referential SHA or unperformed success is fabricated in this tracked report.
