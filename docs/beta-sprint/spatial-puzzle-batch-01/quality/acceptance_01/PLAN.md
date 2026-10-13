# Acceptance01 Complete State Graph Implementation Plan

> Use superpowers:executing-plans inline, TDD for reporting boundaries, one fresh independent final review.

Goal: independently enumerate the current combined puzzle's entire formal Goal-terminal reachable graph, analyze the same live graph and verify recovery/bypass/Runtime witnesses without modifying production.
Spec: Coordinator00 SPATIAL_PUZZLE_BATCH_01_ACCEPTANCE_01 delegation2026-10-13 plus Design13 docs/beta-sprint/spatial-puzzle-batch-01/design/SPATIAL_PUZZLE_BATCH_01_DESIGN_SPEC.md and formal 3A/3B APIs.
Base: d3b131440600048006ccc7679962fb7fc546a63f. Worktree E:/godot/worktrees/bg-spatial-quality02, branch test/spatial-acceptance-01, initially clean.
Architecture: production Maps.bake→Explorer.explore(FULL_GRAPH/UNFILTERED)→same in-process Softlock.analyze. Quality only counts/checks existing graph records, reads canonical predecessor witnesses and calls public Runtime/Safety/Replay; no BFS, graph builder, rule or reverse-reachability clone. Serialized graph is evidence only, never reloaded for analysis.
Tech: Godot4.7.2 GDScript and Python orchestration.

## Constraints and definitions

- Write only tests/beta_sprint/spatial_quality/acceptance_01/** and docs/beta-sprint/spatial-puzzle-batch-01/quality/acceptance_01/**. Preserve old matrix/evidence and all production/maps/legacy levels.
- Explorer graph treats Goal nodes as terminal, records them expanded, and never enumerates their outgoing actions. COMPLETE means exactly this domain, not all possible post-win Runtime actions. Theoretical/expanded post-win state-space denominator UNKNOWN.
- Reset is outside the solver action domain and never added to graph edges. Graph softlock = reachable non-Goal state with no graph route to Goal. Self-recoverable detour = authored target_b/return state with goal reachability proved by formal Analyzer; strict sink = non-Goal outdegree0. Only-Reset recovery requires actual public Runtime.reset from each claimed graph-softlock state, exact spawn StateKey, and spawn→Goal proof. Truly unrecoverable requires failed formal Reset recovery or unsolvable reset spawn. Incomplete graph/analyzer or untested reset state stays UNKNOWN; reset success never subtracts from graph softlock_count.
- Original Solver solution_trace is the hard shortest witness; validate and validate_semantics before conclusions. An arbitrary graph-prefix witness is GraphPath, never mislabeled SolutionTrace. Detour recovery uses a second formal FIRST_SHORTEST call from a current live graph node; cannot expand first graph or claim its initial is supported by production TraceReplayer.
- Required-cut proof: all Goals are latched Inner; all inter-world edges are authored permitted Shift; all edges entering goal-island {target_a,goal} from outside must be a formal authorized Fall. No filtered graph search or ablation clone.
- Check exact StateKeys/full states, lock monotonicity/correct-contact semantics, directed fall permissions and same-source/edge/camera/world overlap. Safety on all accepted transitions is integrated in actual Kernel; independent Safety samples are explicitly counted as sampled, not all-edge reruns. Preserve safety_unproven_rejections.
- GUI currently RESERVED_08_USER; no graphical processes until00 grants a slot. Headless Logical/Facade completion never signs Graphical.

## Task1 — honest projection and process receipt

- [ ] Build minimal test-only report projection; run real max_states1 graph/analyzer to pin incomplete UNKNOWN conclusions (metadata RED then GREEN). Preserve raw failed attempts and distinguish test syntax/setup failures from behavior.
- [ ] Runner reuses existing source snapshot/verification/admission helpers, owns fresh acceptance evidence/profile, records actual budget/PID/timeout/stdout/stderr/doubles/sourcehashes; default outer timeout1800s (bounded). Exact dependency bytes must equal fixed base; only Owner test code may differ.

## Task2 — full current live graph

- [ ] Bake actual saved combined map; run formal FULL_GRAPH/UNFILTERED once: max_states5000, max_edges30000, max_depth-1, max_action_evaluations60000, max_runtime_ms1200000 (20min). Softlock budget max_nodes5000/max_edges30000/max_runtime_ms180000. If real budget exhaustion occurs, keep partial frontier and UNKNOWN; at most one justified increase, no unlimited retries.
- [ ] Record counts, frontier, terminal Goal count, full canonical key→state/depth/predecessor and edge evidence, action/rejection/noop/unknown metrics. Complete reachable coverage numerator=denominator=actual nodes only when closure proven; absolute possible states UNKNOWN.
- [ ] Same-live-graph Analyzer, nonmutation check; census properties and shortest anomaly GraphPaths. Revalidate selected shortest trace, actual Safety samples, LOGICAL_SESSION Replay. Native Facade replay of graph prefixes and recovery plus Reset witnesses. If softlocks>64, untested reset classifications UNKNOWN instead of pretending all verified.

## Task3 — review and delivery

- [ ] Graphical selected original trace only if a GUI lease arrives; otherwise explicitly PENDING, no previous replay receipt promoted. No unrelated Foundation rerun.
- [ ] One independent review; one targeted fix pass for important findings. New per-case matrix, source binding, explicit current counts/UNKNOWNs and owner defect handoff. No production repair.
- [ ] Scope/privacy/blob audit, explicit Commit, ordinary single branch Push, remote full SHA equality. Final GUI status RELEASED/NOT_ACQUIRED, Human QA NOT_RUN.

## Review focus

1. Goal-terminal closure differs from post-win Runtime domain.
2. Partial/budget/analyzer incomplete cannot become zero-softlock/complete.
3. Reset proofs are actual Runtime observations and remain outside graph; graph softlock count retained.
4. Cut/lock checks cover all actual graph edges, while sampled Safety/Runtime witnesses have bounded claims.
5. Serialization is evidence only; no graph reload/reconstruction, no algorithm doubles or BFS copies.
