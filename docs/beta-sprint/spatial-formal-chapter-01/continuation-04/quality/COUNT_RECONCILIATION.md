# S05 count reconciliation

All values below were read from frozen native outputs and the new continuation checkpoint on 2026-10-21. The separate native certification outcome is recorded in REPORT.md and RESULTS.json; this document explains the two baselines without merging their authority.

| Evidence | States | Edges | Goal terminals | Unexpanded non-Goal | Action evaluations | Search elapsed |
| --- | ---: | ---: | ---: | ---: | ---: | ---: |
| Continuation02 native Explorer | 418 | 1666 | 26 | 56 | 4035 | 200049 ms |
| Continuation03 native Explorer | 785 | 3328 | 80 | 17 | 8265 | 580026 ms |
| Continuation03 test candidate | 908 | 3916 | 96 | 0 | Not a spawn search | 387688 ms including recovery/checkpoints |
| Continuation04 test continuation | 908 | 3916 | 96 | 0 | 1488 freshly evaluated continuation actions | 182151 ms including recovery/checkpoints |

All graphs use identical `stategraph.v1`, `statekey.game_feel.v1`, level hash `5b4de9ca172f39ea537ceb00f3f56074d83f136cc768c66b9f4669764187d2c8`, rule version `foundation.rules.spatial_puzzle.v1`, official spawn, BFS FULL_GRAPH mode and UNFILTERED v1 policy. The StateKey includes orientation, camera, mechanism and world state, not only location. The 785 native full states are a subset of the 908 candidate, and all 3328 native edges are its exact ordered prefix. All 167 dependency files match old binding, current integration Git blobs and the immutable Build. No map/filter/rule/normalization change explains the count difference.

The native 580-second budget stopped during expansion. Of its 785 nodes, 80 were terminal Goals, 688 non-Goal nodes were fully expanded, and 17 non-Goal nodes remained. The native action count is `688 * 12 + 9 = 8265`: nine candidates had already been evaluated on the interrupted node. Its partial outgoing edges contained one applied changed transition. The other eight evaluated candidates did not publish edges.

Continuation04 restores all 785 typed states and preserves all 3328 edges. It re-evaluates all 12 candidates for every unexpanded node, including the nine interrupted-node candidates. That one already-saved source/action transition is matched and deduplicated. The 17 original frontiers run before new successors. They and 107 newly rediscovered non-Goal successors produce 124 expansions and `124 * 12 = 1488` evaluations. The 123 restored-to-frontier additions comprise 107 non-Goals and 16 terminal Goals. Newly appended edges number 588. These are +123/+588 relative to the native 785/3328, but exactly 0 new states and 0 new edges relative to the prior 908/3916 candidate. Full states and all ordered edges match exactly.

The candidate's zero queue establishes closure of this test orchestration, while the public graph contract assigns completeness provenance to the live Explorer. Both test candidates therefore retain complete=false, stop_reason=2 and PARTIAL. The 908 observed states all have Goal paths under the public Analyzer, but its test-graph softlock_count remains null. Prior native Analyzer proved 746 Goal-reachable states and left 39 unknown; the continuation resolves paths for those 39 plus the 123 rediscovered states, a gain of 162 proven witnesses, with zero new domain states beyond the prior candidate.

The earlier 200-second and 580-second native runs evaluated 4035 and 8265 candidates respectively. Whole-run mean costs differ (about 49.58 versus 70.18 ms/action), so state counts or one constant rate are not a guarantee. The later observation is the conservative forecast input. Candidate closure needs `812 * 12 = 9744` native evaluations; 1479 remain beyond the old native prefix. The 1488 continuation evaluations include nine repetitions and must not be treated as 1488 novel native actions.

The once-only 900-second native certification budget was prospectively justified by `9744 * 580.026 / 8265 = 683.82 seconds`, plus 35-45 seconds finalization allowance and bounded margin. Native Explorer wraps formal calls with defensive copies and additional validation; the test orchestration does not have identical wrapper overhead. This is code-path analysis, not a profiler measurement or a second gameplay implementation. The one-attempt cap and actual outcome govern the final certification claim.
