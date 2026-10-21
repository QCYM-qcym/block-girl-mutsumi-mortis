# SPATIAL_FORMAL_CHAPTER_01_CONTINUATION_04_REPORT - Owner 03 Quality

## Result

**S05 State Graph: PASS** for the prospectively defined **official-spawn, unfiltered, Goal-terminal stable public action domain**. A new, unchanged public Explorer call exhausted its own queue and returned `complete=true`, `stop_reason=0`, status 0. The same unmodified live graph was accepted COMPLETE by the public Softlock Analyzer. This is a new formal certification result; neither historical test candidate is promoted to live provenance.

| Measure | Current actual result |
| --- | --- |
| Formal certified states / edges | 908 / 3916 |
| Original native baseline | 785 / 3328; 17 unexpanded |
| Delta versus original native | +123 states / +588 edges |
| Prior test candidate | 908 / 3916 |
| Genuinely new states / edges beyond prior candidate | **0 / 0** |
| Continued frontier expansions | 124: original 17 first, then 107 rediscovered non-Goal successors |
| Remaining frontiers | 0 in continuation and new live certification |
| Native full action evaluations | 9744 |
| Goal terminals / shortest Goal route | 96 / 7 actions |
| Formal Goal reachability | 908 of 908 |
| Formal Analyzer status / softlocks / unknown | COMPLETE / **0** / **0** |
| Fresh current checks | **6969; 0 failures** |
| Total owned headless engine time | **910.8351206 seconds**, within amended 1600-second hard cap |

The 6969 checks comprise 6477 continuation/mechanic/Replay/Reset checks, 6 fresh typed-checkpoint admission checks and 486 separate live-certification checks. Historical 13307 checks are not counted again. Setup exited 0; continuation exited 3 because its assembled graph deliberately retains PARTIAL provenance; checkpoint verification and separate full certification exited 0. Every process had zero stderr bytes and verified isolated headless capture. No process retry was used.

## Git, source and scope

- Owner: 03 Quality; handoff to 00 Integration.
- Repository: `https://github.com/QCYM-qcym/block-girl-mutsumi-mortis.git`.
- Worktree: `E:/godot/worktrees/bg-fsc03`.
- Branch: `test/spatial-formal-frontier-cont04`, newly created after checking local and remote absence.
- Exact integration base: `b3f8fa9b8a6562a25342787317f6b42bc6b973b9`.
- Old Owner worktree was CLEAN at `bdc04b7a42548ea237247f29a56ed90294446e37`; its prior branch remains intact.
- Immutable Build: `E:/godot/beta-sprint-builds/beta_spatial_formal_chapter_20261019_01`.
- Build Source SHA: `763f0132bc58360fab0e224d0e9c54e00c92ae90`.
- All 167 dependency hashes match prior evidence, baseline Git blobs, current source and immutable Build bytes. Source drift is empty.
- Allowed changes only: `tests/beta_sprint/spatial_formal_frontier_cont04/**` and this `continuation-04/quality/**` directory.
- Exact delivery commit, independent remote SHA query and post-push CLEAN status are supplied in the Owner handoff and external `delivery.json`; they cannot be a self-referential SHA inside this commit.

PRODUCTION_CHANGES = NONE. NEW_BUILD = NOT_REQUIRED. No Art files, production APIs, main or Release tags were changed. No stash/reset/clean, history rewrite, old branch/evidence overwrite, GUI operation or original Build profile write occurred. Root independently owns integration and the other acceptance categories.

## Why 908 and 785 were both valid observations

The complete explanation and arithmetic are in [COUNT_RECONCILIATION.md](COUNT_RECONCILIATION.md). The native 580026 ms search stopped mid-node after 8265 evaluations, leaving 17 non-Goal frontiers. Its 785 full states and 3328 ordered edges are an exact subset/prefix of the 908/3916 test candidate. Same map hash, StateKey implementation, rule version, spawn, filters and BFS/Goal-terminal policy were verified; no changed identity normalization or gameplay domain explains the difference.

Continuation04 actually restores all 785 typed states through formal predecessor actions and expands the 17 native frontiers first. It evaluates 1488 candidates on 124 nodes, including nine interrupted-node evaluations already attempted historically. One prior changed edge is matched and deduplicated. It appends 123 states and 588 edges relative to native evidence, but reproduces exactly the prior candidate full states and ordered edges. Rediscovery is not reported as new domain coverage.

The resumed graph remains `complete=false`, `stop_reason=2`, `PARTIAL`, with Analyzer INCOMPLETE and null softlock count despite all 908 observed Goal paths. The separate fresh native call is the sole basis of the new formal PASS. Its entire 908 full-state set and all 3916 ordered edges match the continued graph, while its live completion provenance legitimately differs.

## Actual method, timing and bounded certification

[Predeclared criteria and reproduction](METHOD.md) were written before engine execution. The initial total process caps were 595 seconds; actual setup/continuation/checkpoint consumption was 327.8506808 seconds. After count/closure equality and zero failures were established, 00 conditionally authorized exactly one additional existing-API certification: 900000 ms Explorer budget, 60000 ms Analyzer budget, 1000-second process cap, amended 1600-second stage cap. The runner required at least that full 1000 seconds remaining and recorded the spent time before starting. No production redesign or second attempt occurred.

| Phase | Actual |
| --- | ---: |
| Setup process | 4.3433346 s |
| Typed restoration completed (summary clock) | 88854 ms |
| Original 17 frontier checkpoint | 99705 ms |
| Search-end checkpoint timestamp | 181949 ms |
| Search end after checkpoint write (summary clock) | **182151 ms** |
| Whole continuation process | 295.829394 s |
| Fresh typed-checkpoint reader | 27.6779522 s |
| Separate live Explorer API, including its finalization | **552284 ms** |
| Same live graph Analyzer | 24721 ms |
| Whole live certification process | 582.9844398 s |
| All owned engine processes | **910.8351206 s** |

The action-count forecast was 683.82 seconds plus a 35-45-second finalization allowance. The actual Explorer returned in 552.284 seconds. This is an observed runtime difference, not evidence of a specific performance cause. Defensive-copy/validation differences between public Explorer and the test continuation are source-code observations, not profiler attribution. All 18 new continuation checkpoints include graph, pending queue, original-frontier membership, per-action outcomes and timing. The public synchronous Explorer has no intermediate checkpoint callback; its returned complete graph is separately archived.

## Mechanics, Replay and classifications

- FaceLock: 8 correct-orientation arrivals latch; 16 wrong-orientation arrivals remain unlatched. All reached Inner states require the latch. No latch regression or wrong-contact latch was observed.
- Shift: 192 graph edges satisfy exact authored gate, flags/mechanism state and preserved orientation/camera. Fresh off-point and locked samples receive the formal 2010/2011 rejections.
- Fork: no overlapping authored camera/world permission cells for the same source face/edge.
- Fall: 144 graph edges have formal safe Fall motion and the exact authored target with preserved orientation/layer. A subsequent ordinary Roll was freshly evaluated through Kernel and matched its stored rotated target state.
- Goal/shortcuts: all 908 states reach Goal; 48 entries into the Goal island are Fall edges, with zero non-Fall entries and zero census violations.
- Replay: a separate fresh public FIRST_SHORTEST spawn search supplied a seven-step live trace. Formal semantic validation passed and public LOGICAL_SESSION Replay matched all 7/7 steps. It is not a fabricated trace from the resumed test graph.
- Reset: a native Facade replay of a 30-step predecessor path followed by Reset restored the exact canonical initial key, idle state and zero commits. This is a sample, not exhaustive pending/cancel lifecycle coverage.
- Formal softlocks: 0 in the certified domain, with 0 unknown states and 0 reset-recoverable softlock states. Ordinary non-Goal dead ends and reset-only softlocks are absent within this certified domain because every state has a Goal path. No erroneous legal-operation block was observed; no independent exhaustive legality oracle is claimed. Non-design unrecoverable Goal softlocks are absent in this scope, not asserted for untested UI/lifecycle behavior.

## Evidence and integrity

Fresh external evidence root: `E:/godot/beta-sprint-builds/spatial_formal_frontier_cont04_20261021_01`.

- `source_binding.json`: source/Build/engine identity, 167 copied dependency hashes, executed GDScript hashes and frozen historical file hashes.
- `incremental/checkpoint_001_restored.*` through `checkpoint_018_search_end.*`: JSON plus type-preserving Godot binary checkpoints. Separate reader admitted the binary with public Graph.validate, rejected raw JSON as untyped input, and proved identical wire evidence/queue identities.
- `incremental/frontier_outcomes.json`, `focused_mechanics.json`, `native_reset.json`, `live_spawn_explorer.json`, `live_spawn_trace_semantics.json`, `live_spawn_replay.json`, `report.json`, `process.json`.
- `checkpoint_verification/report.json` and `process.json`.
- `live_certification/explorer.json`, `softlock.json`, `summary.json`, `report.json`, `process.json`.
- [RESULTS.json](RESULTS.json): current metrics, both deltas, checkpoint/evidence SHA-256 manifest, isolation receipts, forecast and actual native verdict.

Frozen prior checkpoint JSON/bin, prior native Explorer/Analyzer/process and Build identity hashes remain unchanged. The initial Python runner snapshot is preserved; a later UTF-8/BOM-reader portability edit is disclosed in METHOD.md and does not alter executed GDScript/search semantics. Executed harness byte hashes remain bound to the archived CRLF files; delivered LF files have explicitly verified content equality after line-ending normalization, recorded alongside both hashes in RESULTS.json. No test logic change is hidden by this check. No old evidence is overwritten or relabeled. Profiles for every engine child are under the new evidence root.

## Remaining scope and handoff

Owner03 S05 certification work is ready for Integration review. No generic resume API work is required to close this certification, and no further native full search is needed for this unchanged dependency/domain identity. Future source/map/policy changes require new evidence tied to their actual hashes.

Post-Goal outgoing actions, busy/pending/cancel combinations, GUI/keyboard delivery and first-time Human QA are not covered. S01-S04 prior results were not rerun. Art audit, input environment and Human QA are NOT_RUN by Owner03 and are reported separately by their authorized Owners. No new gameplay defect is confirmed. This scoped S05 PASS does not turn the entire continuation task or Human QA into PASS.

Next minimal action: 00 reviews and normally merges this Owner branch, reruns read-only evidence verification against the integrated dependency hashes, and combines the separate Art/input/Human-QA statuses without expanding this scope.
