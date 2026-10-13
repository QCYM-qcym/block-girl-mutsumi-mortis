# SPATIAL_PUZZLE_BATCH_01_ACCEPTANCE_01 — 03 Complete State Graph

**Overall:PARTIAL. Formal Goal-terminal/action-API graph:PASS.** Post-Goal enlarged domain:UNKNOWN; keyboard controls have external confirmed SPATIAL-CARDINAL-01 P1; Graphical/Human:NOT_RUN. No whole playable acceptance claim.

Base `d3b131440600048006ccc7679962fb7fc546a63f`, branch `test/spatial-acceptance-01`, worktree `E:/godot/worktrees/bg-spatial-quality02`. Production/maps/old levels/old matrices unchanged. All writes stay in the two acceptance_01 Owner paths. Delivery SHA and remote equality are supplied after final publication, not invented inside the containing commit.

## Actual current enumeration

Current actual saved combined map→production Explorer FULL_GRAPH/UNFILTERED: **908 states,3916 edges,96 Goal terminals,frontier0**. The new run is independent; prior graph numbers are not used as proof. Actual elapsed486183ms;9744 action evaluations=3916 changed accepted edges+5016 rejected attempts+812 noops; filtered0, safety_unproven_rejections0. Maximum shortest-prefix depth30. Every formal StateKey includes canonical level/rule identity and Position/Orientation/World/Camera/Mechanism (plus declared flags/groups/celestial). Actual census observes9 support Positions,24 Orientations,2 Worlds,4 Camera values,2 mechanism/flag configurations; not a Cartesian/theoretical coverage denominator.

Budget: max_states5000, max_edges30000, max_depth-1, max_action_evaluations60000, max_runtime_ms1200000. Softlock max_nodes5000/max_edges30000/max_runtime_ms180000; outer process timeout1800s. No exhaustion or limit increase. Raw budget,metrics and phases are retained.

Formal Explorer makes Goal nodes absorbing terminals, marks them expanded and does not enumerate their outgoing actions. Therefore reachable coverage908/908 and accepted-edge census3916/3916 refer **only to its Goal-terminal action domain**. Formal non-Goal candidate evaluations9744/9744 were exhausted. All possible/post-win/keyboard state-space denominator:UNKNOWN. Goal terminal completeness is not arbitrary Runtime-input completeness.

## Same-live-graph recovery

Production SoftlockAnalyzer consumed the exact same in-process Explorer-returned graph, PID25288. A deep copy is used only to detect mutation, never supplied instead. The original graph was unchanged. Formal Analyzer COMPLETE, checked908 nodes/3916 edges, proved **all908 can reach Goal,0 graph softlocks**. Serialized graph is evidence only; no disk graph is reconstructed or reloaded for analysis.

| Classification | Actual |
|---|---:|
| Goal terminals |96|
| Non-Goal states with a graph route to Goal |812|
| B/return detour states, all self-recoverable |192 (subset of812)|
| Non-Goal outdegree0 sinks |0|
| Graph softlocks (no graph route to Goal) |0|
| Only-Reset graph softlocks |0|
| Irrecoverable under graph+formal Reset |0|
| Unknown Reset classification among graph softlocks |0|

Definitions are in PLAN.md. Graph softlock_count is never reduced by Reset. Reset is not an ActionGenerator edge and was not silently inserted into the graph. There are no graph-softlock states requiring reset classification here; counts0 follow the complete graph proof, not the Analyzer's inferred Reset flag. Separately, actual public Facade.reset after Goal/post-Goal restores exact canonical spawn StateKey, commits0 and idle. If future softlocks exist, the harness verifies Reset per actual predecessor replay (cap64, remainder UNKNOWN), instead of treating an inferred spawn key as a Runtime observation.

## Finite bypass/permission properties

All908 states and3916 edges inspected:192 authored permitted Shifts,8 genuine latch edges,192 latched reentry edges,144 authorized directed Fall edges,48 Goal-island incoming cut edges. No unlatched Inner/Goal, wrong-face latch, lock→idle without Reset, unauthorized cross-world edge, Shift-pose mutation, Camera physical mutation, directed-Fall mismatch or island Fall bypass was found. Fork same-source/edge/Camera/World author permissions have no overlap.

Required-cut proof: spawn is Surface/unlatched/outside {target_a,goal}; all Goals are latched Inner; every world-changing edge is permitted Shift; every edge entering {target_a,goal} from outside is formal authorized Fall. These are independent finite properties over actual graph edges. They show **no confirmed bypass of these required cuts**, not every design intention/milestone or all possible solutions' intent. No second BFS/filtered graph/Ablation/physics/rule implementation was added.

Original selected shortest trace is7 actions:MOVE[3,0,1,2]→SHIFT→MOVE2 (Fall)→MOVE0 (Roll/Goal). Trace.validate and validate_semantics both ran first. Author witness has8 entries because it explicitly sets Camera1 when already1, an applied noop omitted by Solver; no new shortcut conclusion is inferred from length alone.

Actual production LOGICAL_SESSION Replayer matches the original complete shortest trace. Native Facade explicitly LOGICAL phase-replays real graph predecessor prefixes, exact StateKeys/full states/commit counts, initial locked Shift2011, wrong contact idle at sensor, off-point Shift2010 and reentry without duplicate MECHANISM_TRIGGER. B recovery is a separate real FIRST_SHORTEST query from a live B graph node:29 discovered states/89 edges,6-action solution,12888ms; validated semantics then native Runtime reaches Goal without Reset. This local witness never replaces the original full-graph trace or proves another closure.15 independent Safety samples cover original shortest and recovery edges; full graph edges originate real Kernel with integrated formal Safety.15 samples are not mislabeled3916 independent Safety queries.

Actual Runtime accepts MOVE2 after winning and reaches non-Goal target_a, Orientation17. This is separate observed post-Goal behavior; its expanded reachable domain remains UNKNOWN. Explorer was not rewritten and Goal was not falsified to conceal the boundary.

## Receipts, failures and handoff

Final current receipts: `contracts_final` PID28912,9 metadata UNIT checks; `full_graph_03` PID25288,187 checks. Total **196 assertions**:UNIT12, Solver14, Safety15, LOGICAL_REPLAY1, native Runtime154. Both exit0/failures[]/stderr0/doubles[]/source drift[]. [Matrix](MATRIX.json), [results](RESULTS.json), [source binding](SOURCE_BINDING.json) bind2151 tested files, exact engine and raw artifacts. Cases12PASS,3NOT_RUN,1UNKNOWN,1FAIL_EXTERNAL. External diagnostics add0 assertions.

Preserved failed attempts: contracts_red0 parse errors (builtin Projection name); contracts_red2 real9 checks/6 expected metadata failures/stderr0; contracts_green9 preparation excluded from final total. full_graph_010 checks/type-inference parse error; full_graph_02 dependency compile errors, ownedPID35480 was verified and stopped, no graph conclusion; explicit bool fix+check-only then fresh full_graph_03. These are03 harness issues, not production Runtime failures. Full search has no doubles or private Explorer port seam.

Known external production failure: **SPATIAL-CARDINAL-01 P1**,00 diagnostic `89ebf7a60e405d7617298e49a3f43e3461e38376`, OWNER_BUG_HANDOFF.md read from that immutable commit. Gate Inner NORTH/EAST WASD collapse onto axes0/2 with2000 rejection;01 scoped input fix pending. It is a controls defect, not a graph softlock. Our action-API graph does not certify WASD. Diagnostic exit1/ObjectDB warnings remain external, never converted into our clean PASS. No fix commit merged here; future byte comparison may reuse this graph only if formal rules/action semantics remain unchanged.

The player's overhead block has not been identified; a nonwalkable roof exists but is not substituted for user confirmation. No map/Runtime repair undertaken. Current graph property anomalies:NONE; shortest anomaly list empty, actual prefixes retained for Runtime evidence.

Graphical:NOT_RUN_GUI_RESERVED_08_USER. GUI:RELEASED (never acquired this task). Human:NOT_RUN by03;08/user activity is not signed as independent first-player completion. No old graphical or complete graph receipt is promoted.

One fresh review and necessary metadata fix, if any, are recorded in REVIEW.md before normal Owner Commit→Push→Remote SHA verify. No unrelated Foundation rerun, new mechanism, Editor or production change.
