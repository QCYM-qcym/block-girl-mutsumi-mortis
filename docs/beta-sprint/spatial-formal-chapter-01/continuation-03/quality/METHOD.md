# S05 incremental frontier method — Owner 03

Task: `SPATIAL_FORMAL_CHAPTER_01_CONTINUATION_03`, 2026-10-21 Asia/Shanghai.
Owner worktree: `E:/godot/worktrees/bg-fsc03`; branch: `test/spatial-formal-frontier-cont03`.
Verified integration baseline: `f972cb850845cb2c31da6975ac7466437aafdec2`.
Immutable Build: `beta_spatial_formal_chapter_20261019_01`, source `763f0132bc58360fab0e224d0e9c54e00c92ae90`.
Write scope is only this quality directory and `tests/beta_sprint/spatial_formal_frontier_cont03/`.

## Recovery and authority

The previous public Explorer result is `E:/godot/beta-sprint-builds/spatial_formal_state_cont02_20261019_01/rubik_spatial_puzzle_01/explorer.json`: 418 states, 1666 edges, 56 unexpanded non-Goal states. The old search reached its 200-second time budget during a node expansion. All old files remain unchanged.

`foundation/solver/state_explorer.gd` exposes `explore(level, initial, policy, budget)`, which always creates a new graph. There is no public queue/graph import or resume API. Saved JSON loses Godot integer and StringName types required by the closed public graph contract. Re-reading that JSON is not a supported formal graph resume.

This test harness recovers states with a memoized predecessor tree: construct the official spawn using `Records.initial_state`; for each remaining saved state, choose its predecessor's saved action from the public `ActionGenerator.generate` output, then call `Kernel.evaluate_action` with `Rules.idle_context`. The Kernel itself calls formal Safety and permission logic. The returned full state, StateKey and Goal marker must match the saved node. No dictionary-to-state gameplay decoder, alternative movement rule or injected dependency seam is used. One saved predecessor edge is replayed per noninitial state. All saved edges retain their index, source, target, action and global kind; the source action is restored from the official candidate list. Historical nonpredecessor edges retain their original, byte-bound Explorer provenance rather than being claimed as freshly replayed.

The StateKey is the full canonical `statekey.game_feel.v1` string. It includes level hash, rule version, camera quadrant, celestial slot, group orientations, level flags, mechanism states, player location/layer/face/orientation and both world orientations. It is not a position-only key. Every restored and new state is checked through the official StateKey builder.

## Actual continuation

Initial frontier order uses saved depth and first predecessor edge order. The initial 56 keys precede every newly discovered successor. Each node enumerates all public candidate actions and records Kernel status, changed flag, rejection code/issues, target key and edge index. An already saved source/action edge is re-evaluated and its target/global kind must match; it is not counted or inserted twice. Goal states remain terminals, as in the old Explorer policy.

Only test queue and evidence orchestration is added. Every eight expanded nodes and at phase boundaries, both JSON evidence and a typed Godot `store_var` checkpoint are saved. Each checkpoint includes graph, remaining queue, original 56 frontier membership, per-frontier action outcomes and elapsed time. A separate fresh process reads the final binary checkpoint through `get_var` and public `Graph.validate`, compares it to the JSON wire evidence, and checks pending queue identities. This establishes usable type-preserving recovery data; it does not create a new public Explorer resume API.

The internal search deadline is 800 seconds including recovery, with node expansion atomic at a budget boundary. Capacity guards are 2500 nodes and 15000 edges. The isolated main process has a 1050-second outer cap, initial setup 35 seconds, and checkpoint verification 40 seconds. After these completed in 517.287 engine seconds, one independent formal certification was authorized to resolve the remaining provenance gap: public Explorer 580 seconds, public Analyzer 60 seconds, process cap 665 seconds. This makes the actual spent-plus-remaining hard bound 1182.287 seconds, within the task's 1200-second engine cap. Actual times are in `RESULTS.json`; only this task's child processes are controlled. Profiles are unique per run, all processes are hidden/headless, and the copied project contains the same 167 dependency files as the prior evidence. Those files are checked against current baseline Git blobs, old evidence hashes and immutable Build bytes. No source-project import, Art import, GUI window operation or new Build occurs.

## Limits of the result

`Graph.validate` checks structure, StateKeys and Goal flags; its own contract says completeness provenance belongs to the live Explorer. A graph assembled by this test does not acquire that provenance merely by passing the validator. Therefore its `graph.complete=false`, stop reason remains budget/incomplete, and its `STATE_GRAPH=PARTIAL`, even if the candidate-action queue exhausts. Queue exhaustion is reported separately as closure of this test-orchestrated, observed Goal-terminal domain. The later separate certification may establish a scope-bound formal PASS only if a fresh public Explorer itself exhausts the queue and its unchanged live graph is accepted as complete by the public Analyzer. That result never mutates or relabels the incremental graph. The audit compares all state keys, full states and ordered edges between the two independent results.

The public Softlock analyzer is called on the typed graph without changing it or replacing validation. It preserves `INCOMPLETE`, `softlock_count=null`, reset classification UNKNOWN. Its proven Goal-reachable subset is still useful, and the audit independently checks those reverse paths against saved edges. Null is never translated to zero. Ordinary dead ends, reset-only recovery, erroneous blocking and non-design unrecoverable softlocks remain separate categories, with actual scope and uncertainty in the result report.

A separate live `Explorer.explore` starts at one original frontier with FIRST_SHORTEST and a 60-second budget. A returned live trace is checked by public `SolutionTrace.validate_semantics`. That witness belongs only to its live search. `foundation/parity/trace_replayer.gd` also requires the official spawn StateKey; it cannot replay a frontier-start trace as if it were a spawn trace. No assembled-graph TraceReplayer PASS is claimed. Native Facade additionally replays one saved predecessor path from official spawn to a newly reached state, commits only captured native transition identities, and verifies Reset restores the exact canonical initial key, idle state and zero commit count. This is a sampled Reset test, not every-state or pending-lifecycle coverage.

S01–S04 prior Goal-terminal results remain separate and are not rerun. Post-Goal actions, pending/busy/cancel combinations, UI/keyboard delivery, graphical behavior and first-time Human QA are not covered. No production file or Gameplay rule changes.

## Reproduction

Use a new, nonexistent absolute output directory for each run; never reuse the old evidence directory. From the Owner worktree run:

```powershell
python tests/beta_sprint/spatial_formal_frontier_cont03/run.py E:/godot/beta-sprint-builds/spatial_formal_frontier_cont03_20261021_NEW
python tests/beta_sprint/spatial_formal_frontier_cont03/verify_checkpoint.py E:/godot/beta-sprint-builds/spatial_formal_frontier_cont03_20261021_NEW
python tests/beta_sprint/spatial_formal_frontier_cont03/certify.py E:/godot/beta-sprint-builds/spatial_formal_frontier_cont03_20261021_NEW
python tests/beta_sprint/spatial_formal_frontier_cont03/summarize.py E:/godot/beta-sprint-builds/spatial_formal_frontier_cont03_20261021_NEW
```

The first command genuinely continues the old saved frontier, rather than repeating the old 200-second spawn search. The third command is a distinct larger-budget provenance check after continuation and refuses to start without enough remaining budget. Further continuation can consume the final typed checkpoint and its pending queue; production Explorer support for importing checkpoints remains a Runtime/Solver Owner decision, outside this test-only scope.
