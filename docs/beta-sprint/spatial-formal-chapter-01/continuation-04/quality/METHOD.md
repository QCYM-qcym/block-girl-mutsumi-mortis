# Continuation 04 certification criteria (recorded before engine execution)

Owner03; 2026-10-21 Asia/Shanghai. Worktree E:/godot/worktrees/bg-fsc03; branch test/spatial-formal-frontier-cont04. Clean audited base b3f8fa9b8a6562a25342787317f6b42bc6b973b9. Immutable Build source 763f0132bc58360fab0e224d0e9c54e00c92ae90.

PASS requires an unfiltered, official-spawn, FULL_GRAPH live public Explorer result with complete=true, no pending non-Goal nodes, unchanged graph accepted COMPLETE by the public Softlock Analyzer, and successful mechanics/identity checks. Graph.validate alone cannot establish live provenance. A resumed test graph remains complete=false and PARTIAL even if its own queue exhausts. No private dependency seams, doubles, alternative movement implementations, or production API modifications are allowed.

The native prior is continuation03 live_certification/explorer.json: 785 states, 3328 edges, 17 unexpanded states. The separate test candidate checkpoint_062_search_end was 908/3916 with zero queue, still incomplete provenance. Both are compared explicitly. A state already in the 908 candidate is rediscovery, never new overall coverage.

Recover all 785 typed states via canonical spawn and memoized predecessor Actions.generate/Kernel.evaluate_action; require exact full StateKey, full state and Goal match. Preserve 3328 ordered edges. All 17 original frontiers precede newly generated states in depth/predecessor order, matching original BFS insertion order. Partially saved source/action edges are re-evaluated and deduplicated. Every action outcome is persisted. Checkpoint every eight nodes and at original-frontier and stop boundaries, with typed binary and JSON companions.

Identity is the unchanged statekey.game_feel.v1 implementation: frozen field order, Unicode-scalar sorted map keys, level hash/rule version plus camera, celestial, group orientations, flags, mechanisms, full player layer/cube/face/orientation, both world orientations. No projection or custom normalization. Policy is BFS FULL_GRAPH, UNFILTERED version 1, no disabled mechanics, validator 4096 configurations/100000 checks. Spawn is Records.initial_state. Goal nodes terminate immediately; Reset is separately sampled lifecycle behavior, not an action edge. Scope excludes post-Goal, busy/cancel, graphical input and Human QA.

Before running, verify all 167 dependency hashes against prior binding, current baseline Git blobs and immutable Build project bytes; freeze historical checkpoint JSON/bin, native explorer/analyzer/process and Build identity hashes. Only fresh external evidence/profile directories are written. Source project and original Build profiles are untouched.

Budget: setup cap 25 seconds, continuation process cap 530 seconds, separate checkpoint verification cap 40 seconds (595 total caps). Continuation deadline 360000 ms includes restoration, checkpoints and atomic per-node expansion; capacities 2500 states/15000 edges. Reserve remainder for public Analyzer (30000 ms), focused checks, fresh FIRST_SHORTEST spawn Explorer (90000 ms), public logical Replay (20000 ms) and native Reset sample. All processes hidden/headless, owned PID only. No repeated 580-second full search. The fresh shortest search produces only a legitimate live trace and never upgrades full-graph certification.

Mechanic criteria: positive and wrong-orientation FaceLock arrivals, gated Shift permissions and offpoint/locked rejections, Fork permission-cell uniqueness, Fall exact target and preserved orientation plus a subsequent ordinary Roll, Goal witnesses, native Reset to exact initial key/idle/zero commits, no non-Fall Goal-island cut edge. Softlock count remains null while Analyzer is INCOMPLETE; observed reverse Goal reachability is reported separately from complete-space classification.

Reproduction uses run.py with a new absolute evidence directory, then verify_checkpoint.py and summarize.py on that directory. Historical results remain immutable; all current checks and delta counts are fresh.

## Prospective single native certification, conditional budget amendment

Before starting, root conditionally authorized exactly one additional unchanged public Explorer FULL_GRAPH run after this continuation reproduces all 908 full states and all 3916 ordered edges with zero remaining frontier and zero check failures. The fresh native run uses the official initial state, unchanged unfiltered policy, 900000 ms search budget, Analyzer 60000 ms, and process cap 1000 seconds. The stage hard cap becomes 1600 engine seconds, inclusive of all setup, continuation, verification and certification processes. The runner records actual spent seconds first and refuses if fewer than 1000 seconds remain. No second attempt, production modification or silent budget extension is permitted.

Forecast: candidate closure has 96 terminal Goal states and 812 non-Goal nodes, each with 12 public candidates, hence 9744 evaluations. Prior native search performed 8265 evaluations in 580026 ms. Linear action-count extrapolation gives 683.82 seconds plus an allowance of 35-45 seconds for final validation/copying. 900 seconds provides a bounded margin. Explorer's defensive argument copies and extra shape/identity checks differ from the continuation orchestration; this is a source-code explanation, not measured profiler attribution. Actual results supersede this forecast.

The future handoff gate is precise: archive that one public Explorer output unchanged, require FULL_GRAPH/UNFILTERED official spawn, complete=true/stop_reason=0, zero unexpanded non-Goal nodes, no errors, Analyzer COMPLETE with all 908 nodes checked and zero unknown; verify full state/edge-set equality to the candidate, valid trace and requested mechanics. Report native status independently of test continuation. If time/capacity intervenes, retain PARTIAL and exact fronts/checkpoints without another retry. A generic resume API is not a prerequisite for this bounded existing-API certification route.

Encoding note: JSON readers accept UTF-8 with optional BOM. The initial run.py launch snapshot in external tested_runner.py precedes this reader-encoding portability change; source_binding records the actually executed GDScript hashes. This edit changes no gameplay/search code and does not relabel the earlier launch snapshot.

The native public Explorer is synchronous and publishes its graph only on return. It has no intermediate checkpoint callback; the 18 new continuation checkpoints remain separate recovery evidence. Native process timing and owned PID are recorded before launch; process cap is enforced externally.

## Commands

From the Owner worktree, substitute a fresh nonexistent evidence path for `OUT`:

```powershell
python tests/beta_sprint/spatial_formal_frontier_cont04/run.py OUT
python tests/beta_sprint/spatial_formal_frontier_cont04/verify_checkpoint.py OUT
python tests/beta_sprint/spatial_formal_frontier_cont04/summarize.py OUT
python tests/beta_sprint/spatial_formal_frontier_cont04/certify.py OUT
python tests/beta_sprint/spatial_formal_frontier_cont04/summarize.py OUT
```

The certification runner is the once-only, conditionally approved additional run described above. Existing evidence directories refuse overwrite. Use the exact delivered source and retain original inputs; the summary performs read-only artifact accounting and creates only the Owner RESULTS.json document.

Delivery EOL note: executed harness archives retain their exact original SHA-256. The repository requires LF while Windows initially wrote CRLF. Delivered harnesses are normalized to LF; RESULTS records both byte hashes and checks exact content equality after CRLF-to-LF normalization. This permits only line-ending equivalence, not gameplay/test logic changes. Production dependency comparison remains exact byte-for-byte.
