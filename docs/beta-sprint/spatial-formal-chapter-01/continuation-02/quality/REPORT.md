# Formal chapter continuation 02 — Owner03 bounded state graphs

Source: `763f0132bc58360fab0e224d0e9c54e00c92ae90`; immutable Build: `E:/godot/beta-sprint-builds/beta_spatial_formal_chapter_20261019_01`.
Owner worktree: `E:/godot/worktrees/bg-fsc02`; branch: `test/spatial-formal-state-cont02`.
Only the new Owner test/report directories are changed. Integration belongs to 00.

The Build's prior `STATE_GRAPH=NOT_RUN` is retained as a historical fact. This continuation adds fresh, bounded, source-bound formal searches. Overall state-graph acceptance remains **PARTIAL**: public Explorer treats Goal states as terminal, and Runtime lifecycle/UI/Human domains remain outside this run.

## Method and evidence admission

The fixture copies 167 existing dependencies byte-for-byte from the exact source into an external directory without Art. All 167 match both the immutable Build project and Closure04's dependency manifest. `summarize.py` additionally compares every copied dependency to its exact Git blob at `763f013...`, checks fixture drift, and records evidence SHA-256 hashes. No serialized historical graph is passed to any formal algorithm.

Each fresh map uses saved authoring → public `Maps.bake` → canonical initial state → public `StateExplorer.explore` with unfiltered BFS/FULL_GRAPH → public `SoftlockAnalyzer.analyze` on that same in-process graph. The graph is compared before/after Analyzer. Pure property inspection reads returned nodes/edges and delegates geometry/orientation/Fall descriptions to production APIs; it does not implement a second search or gameplay algorithm.

Each available shortest solution is revalidated with formal `SolutionTrace.validate` and `validate_semantics`, then executed through actual `RuntimeFacade.request_action`. Completion uses the identity captured from real `transition_started`; committed full StateKeys match the trace. Goal Reset is tested **once per map at that shortest-route Goal**, checking canonical spawn/count zero/idle. It is not an every-state Reset proof or graphical replay.

Each run is headless, uses hidden processes and isolated APPDATA/LOCALAPPDATA/TEMP/TMP, with capture PID/head/profile verification. Godot 4.7.2 executable SHA-256 is `12310c74bdda7dcd43f28e971f33047dcecadd436b68169d61ce41009006df38`. Only the external minimal fixture received a headless editor import; no original project or Art was imported.

## Fresh results

| Map | Discovered states | Changed edges | Candidate evaluations | Goal states | Shortest native Goal | Graph / Analyzer | Goal softlocks / Reset-only |
| --- | ---: | ---: | ---: | ---: | ---: | --- | --- |
| S01 World Shift Gate | 16 | 56 | 108 | 4 | 3 actions | COMPLETE / COMPLETE | 0 / 0 |
| S02 Orientation Loop | 51 | 246 | 480 | 3 | 3 actions | COMPLETE / COMPLETE | 0 / 0 |
| S03 Face Lock | 104 | 472 | 828 | 12 | 5 actions | COMPLETE / COMPLETE | 0 / 0 |
| S04 Perspective Fork | 80 | 264 | 768 | 16 | 2 actions | COMPLETE / COMPLETE | 0 / 0 |
| S05 Combined | 418 | 1666 | 4035 | 26 | 7 actions | INCOMPLETE / INCOMPLETE | UNKNOWN / UNKNOWN |

The five admitted final map runs have **333 passing assertions, zero failed assertions, zero stderr bytes, zero source drift**, verified captures and no doubles. S05 deliberately exits 3 for budget-limited coverage, not an assertion failure. Native Goal and that Goal's Reset passed on all five maps. Formal Replayer/graphical completion were not used. The earlier two harness-error attempts are separately retained, never included as passing checks.

All maps used limits of 2500 states, 15000 edges, 30000 evaluations, unlimited depth. S01–S04 used 110000 ms Explorer limits, S05 200000 ms; each Analyzer had 2500-node/15000-edge/15000-ms limits. Process caps were 150 seconds for S01–S04, 240 seconds for S05 and 45 seconds for copied-fixture import, with an 850-second runner guard and conservative reservation across reruns. **Actual sum of all nine Godot process durations, including both imports and both failed attempts: 407.141 seconds**, below the authorized 900 seconds. Individual admitted process durations: S01 4.323 s, S02 16.485 s, S03 52.750 s, S04 22.085 s, S05 214.326 s.

S05 Explorer stopped on `MAX_RUNTIME` (budget reason 4), elapsed 200049 ms. It expanded 362 nodes (including the 26 terminal Goals), leaving 56 discovered non-Goal frontier nodes. The same-live-graph Analyzer proved Goal paths for 355 discovered states and left 63 discovered states unknown. It returned null softlock and reset-only counts; **absolute reachable cardinality and coverage percentage remain UNKNOWN**. No budget was raised to force closure. The final timed candidate can be counted before its edge is published, so partial candidate counts must not be forced to equal changed edges + rejects + noops.

S01 and S03 contain 8 and 12 accepted Shift edges respectively. S03 has 8 accepted latch transitions, all satisfying actual local-face contact. S02 exhibits 12 player orientations, with up to 3 at the same location. S04 has 24 described Fall edges and no authored Fork permission overlap. S05's inspected portion contains 96 Shift edges, 8 latch transitions, 58 described Falls and 24 Goal-island entries; there were no sampled edge invariant violations or non-Fall island entries. These S05 observations do not replace missing graph closure.

## Interpretation and semantic limits

- Complete Goal-terminal graphs permit a formal claim about all states reachable **before first Goal** under public ActionGenerator candidates and idle Kernel context. Camera, direct PerspectiveFall and Move are included where generated; changed edges include distinct actions reaching the same target, and exclude rejected/noop candidates.
- On an incomplete graph, Analyzer may prove that some discovered states can reach an observed Goal. Its `unknown_states` counts only discovered states without a current proof. It is not a count of all possible states; total reachable cardinality and coverage percentage remain **UNKNOWN**. A null softlock/reset-only count stays null.
- Softlock means no Goal path in the complete supplied graph. Reset is never added as a graph edge. Analyzer's reset-recoverable count is a formal graph/spawn classification, distinct from the single actual native Goal Reset sample per map. Neither a Goal-terminal node with no outgoing edges nor a post-Goal return-to-earlier-map restriction is automatically a Goal softlock.
- The finite shortcut assertion only inspects entry into the explicitly named `target_a`/`goal` island on maps that contain authored Fall connections. It finds no non-Fall entry among inspected edges. It does not prove the absence of every design shortcut or every alternative teaching route. Current S02 also has authored Fall links and exercises this check.
- S04's shortest witness has two Moves. Initial Camera is already quadrant 1; the example witness's Camera-to-1 request is a noop, so its omission is expected and does not bypass Fall permission.
- Shift edge checks inspect the directed authored gate, required flags/mechanism states, and pose/Camera preservation. Latch checks inspect the actual local contact face and forbid regression without Reset. Fall checks preserve orientation/layer and match authored target. Camera edges must preserve all physical/mechanism/flag state. Fork permission cells are inspected for overlaps; assertions cover the encountered graph and authored data, not malformed external dictionaries.
- The current graph's `frontier` counts nodes whose `expanded` is false. Formal Explorer marks Goal nodes expanded when inserted, so terminal Goals are counted separately and do not inflate this unexplored non-Goal frontier.

## Historical reference, kept separate

`E:/godot/beta-sprint-builds/spatial_closure04_quality_20261019_01` remains immutable. Its S05 certificate combines historical non-Goal expansion and a separately exhausted Goal boundary into 908 stable states / 4300 changed edges. All 167 dependencies match current source/Build exactly, and the current canonical S05 map hash is checked in fresh map identity evidence.

This establishes exact dependency compatibility for citing that prior scoped certificate. It does **not** turn it into a fresh current-Build formal Explorer/Softlock result. No 13491 old assertions or 2196 old native actions are counted in this continuation. The old post-Goal claim remains a finite stable-action certificate, not whole-Runtime acceptance.

## Preserved test incidents

The first fixture assumed every map exposed the optional `face_locks` extension. S02 and S04 use earlier schemas: each formal Explorer and Analyzer returned, then property inspection raised a missing-field script error and the process remained alive. Both owned PIDs were verified by command line and stopped; raw stderr, graph/Analyzer output, process receipts and the exact old `project/graph.gd` remain in evidence01. These are harness defects, not production defects.

The Owner harness now uses optional-extension defaults. S02 and S04 were freshly baked/searched/analyzed/executed in evidence02 with new profiles. Prior failures remain in runtime accounting and are not counted as passing assertions. No production workaround was made.

## Reproduction and handoff

Initial attempt (exact tested harness retained in evidence01; it predates the optional-field correction):

```powershell
python tests/beta_sprint/spatial_formal_state_cont02/run.py E:/godot/beta-sprint-builds/spatial_formal_state_cont02_20261019_01
```

Corrected S02/S04 (450 seconds conservatively reserved for the first runner, whose completed stages plus remaining hard cap were below 391 seconds):

```powershell
python tests/beta_sprint/spatial_formal_state_cont02/run.py E:/godot/beta-sprint-builds/spatial_formal_state_cont02_20261019_02 --maps orientation_loop_lab perspective_fork_lab --prior-seconds 450
python tests/beta_sprint/spatial_formal_state_cont02/summarize.py E:/godot/beta-sprint-builds/spatial_formal_state_cont02_20261019_01 E:/godot/beta-sprint-builds/spatial_formal_state_cont02_20261019_02
```

Evidence directories are append-only; use a new output directory for any reproduction. The second run began while S05 was active, with conservative reservation; report runtime is the **sum of all Godot process durations**, not overlapping wall-clock time.

No production bugs were changed. Integration status: **PENDING_00**. Human QA: **NOT_RUN**. Whole Runtime lifecycle, Presenter, keyboard routing, pending/busy/cancel/interrupted combinations, arbitrary malformed dictionaries, and fresh post-Goal exhaustive expansion remain **NOT_RUN / UNKNOWN** as applicable. Stage status: **PARTIAL**, independently deliverable test/report work.
