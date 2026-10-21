# S05 incremental frontier investigation — CONTINUATION_03

Owner 03; baseline `f972cb850845cb2c31da6975ac7466437aafdec2`; branch `test/spatial-formal-frontier-cont03`; worktree `E:/godot/worktrees/bg-fsc03`.

**STATE_GRAPH = PARTIAL.** The true incremental candidate queue is exhausted, but the public Explorer has no resume API and a separate 580-second native certification attempt also stopped on its time budget. These two different evidence scopes are preserved below; neither graph's formal softlock count is changed from null to zero.

The saved S05 frontier was actually continued. All 56 initial frontier states were expanded before any newly discovered frontier. The resulting candidate queue exhausted at 908 states and 3916 edges. The prior 418 full states and 1666 ordered edges remain identical, including the one edge already emitted from the partially expanded old frontier node.

| Incremental result | Actual |
| --- | ---: |
| Initial states / edges | 418 / 1666 |
| Initial unexpanded non-Goal frontiers | 56 |
| New states / edges | 490 / 2250 |
| Initial frontiers expanded | 56 / 56 |
| Total frontiers expanded this run | 476 |
| Remaining frontiers | 0 |
| Final states / edges / Goal states | 908 / 3916 / 96 |
| Candidate action evaluations | 5712 |
| Accepted changed / accepted unchanged | 2251 / 476 |
| Rejected / Kernel ERROR | 2985 / 0 |
| Already saved edge replayed, deduplicated | 1 |
| Safety-unproven rejection code 1601 | 0 |
| Saved checkpoints | 62 JSON + 62 typed binary |
| Previously proven Goal-reachable → now | 355 → 908 |
| Previously unknown → now | 63 → 0 |

Typed restoration took 42.101 seconds. The initial 56 frontiers took another 32.944 seconds, adding 71 states and 258 edges; at that phase boundary 61 newly discovered frontiers remained. All incremental expansion took 345.752 seconds after restoration, and the final search checkpoint was saved at 387.853 seconds. The stop reason is **QUEUE_EXHAUSTED**, not the 800-second search deadline or capacity guard (2500 states / 15000 edges). Main process including subsequent analysis/witness/Reset took 478.165 seconds; setup took 3.511 seconds; fresh-process checkpoint read-back took 35.611 seconds. Separate certification took 619.012 seconds. **All engine processes total 1136.299 seconds, below the 1200-second task cap.** Native replay/Reset itself was not separately timed; its time is included in the main process receipt.

## Evidence and public API boundaries

Evidence directory: `E:/godot/beta-sprint-builds/spatial_formal_frontier_cont03_20261021_01`.

The 167 copied runtime/solver dependencies match the old evidence, current baseline Git blobs and immutable Build bytes. The immutable Build is `beta_spatial_formal_chapter_20261019_01`, source `763f0132bc58360fab0e224d0e9c54e00c92ae90`. S05 level hash is `5b4de9ca172f39ea537ceb00f3f56074d83f136cc768c66b9f4669764187d2c8`.

The public Explorer has no resume API. All 418 typed states were recovered by replaying the memoized predecessor tree through official ActionGenerator/Kernel/Safety; every full StateKey and saved state matched. New successors use those same formal APIs. Public Graph structural validation accepted the restored and final typed graphs. A fresh process also accepted the final binary checkpoint and rejected its raw JSON counterpart, demonstrating why an untyped JSON import is insufficient. The persisted queue and wire-equivalent checkpoint contents matched.

The assembled incremental graph remains **PARTIAL as a formal completeness certificate**, even with its queue exhausted. Its complete flag was never promoted. Public Softlock analysis on that graph is INCOMPLETE, `softlock_count=null`, reset classification UNKNOWN. It nevertheless proves a Goal path for all 908 observed states, including all 63 previously unknown states. An independent reverse-path audit agrees. Null is not reported as zero.

The separate live frontier Explorer found a Goal witness in 30.086 seconds, and public SolutionTrace semantic replay passed. The native Facade also executed a 30-step predecessor route from canonical spawn to a newly reached state, checking each captured transition identity and committed StateKey, then Reset restored exact spawn, idle and commit count zero. This proves sampled native recovery only. The public TraceReplayer was not falsely applied to the assembled graph or frontier-start trace: its public runtime contract requires official spawn.

Incremental harness: 12,891 checks, zero failures; typed checkpoint read-back: 6 checks, zero failures. Both processes have empty stderr, isolated profiles and verified headless capture. Python evidence audit checks original-state/edge preservation, first-56 ordering, unique expansion, exact new-count sums, every checkpoint queue, Goal terminality, dependency hashes and all saved Goal proofs.

## Separate native certification: bounded, incomplete

After incremental work and checkpoint recovery were complete, 665 remaining process seconds were reserved for one larger-budget native certification. This used only the public Explorer from canonical spawn and the unchanged same live graph passed to the public Softlock analyzer. It was a distinct provenance check, not a replacement or re-run of the old 200-second task.

| Native certification | Actual |
| --- | ---: |
| Explorer budget / actual | 580.000 / 580.026 seconds |
| Solver status / stop | BUDGET_EXCEEDED / MAX_RUNTIME_MS |
| Native states / edges / Goal states | 785 / 3328 / 80 |
| Native remaining non-Goal frontiers | 17 |
| Native action evaluations | 8265 |
| Native Goal-proven / unknown states | 746 / 39 |
| Analyzer elapsed | 33.559 seconds |
| Formal graph complete / softlock count | false / null |
| Certification checks / failures | 410 / 0 |

All 785 native full states match the incremental graph, and all 3328 native ordered edges exactly match its prefix. The native result independently confirms that portion of the continuation, but its remaining 17 frontiers and 39 unknown states do not replace the larger incremental evidence's exhausted queue and 908 proven states. Both have explicit provenance. No further engine run was attempted. The complete phase delivered 13,307 checks with zero failures and empty stderr across the three test processes, plus source/hash/checkpoint/Python audits; a bounded solver result remains PARTIAL despite passing those integrity checks.

## Mechanisms and A–D classification

Across the observed final edges: 192 World Shift transitions satisfy gate requirements and preserve orientation/camera; 8 latch changes satisfy authored contact-face conditions; 144 fall transitions preserve the required pose and land on the authored target. All reached Inner states satisfy the latch condition. There are 48 entries into the authored Goal island and zero nonfall entries. No checked permission, orientation or shortcut invariant failed. The minimum observed Goal depth remains 7. All 24 player orientations occur. Goal nodes have no outgoing edges in this scope.

Rejected frontier actions are recorded individually: 1140 MOVE_BLOCKED (2000), 380 SHIFT_GATE_NOT_FOUND (2010), 310 FALL_NOT_AVAILABLE (2100), and 1155 CAMERA_NOT_ALLOWED (2101). These documented rejections are not by themselves implementation defects. There are no code-1601 unproven Safety rejections.

| Category | Actual conclusion from incremental evidence |
| --- | --- |
| A. Ordinary dead end without a progress route | No observed state lacks a Goal path; no ordinary dead end is established in the 908-state observed domain. |
| B. Recoverable only by Reset | None established: all observed states already have legal Goal paths. Reset was additionally verified on one new-state native route, not every state or pending lifecycle. |
| C. Legal operation blocked by implementation error | None observed in checked invariants/native route; the implementation is not treated as an independent exhaustive legality oracle. |
| D. Non-design softlock unrecoverable by legal actions or Reset | None established in observed states; full Gameplay and post-Goal/lifecycle claims remain outside scope. |

The separately stored live certification is incomplete and also has a null formal softlock count. Neither analysis excuses implementation defects merely because Reset exists.

## Scope and remaining work

S01–S04 retain their prior, separate first-Goal-terminal results and were not rerun. S05 coverage is stable public actions before first Goal, with Goal terminal; Reset is not a graph edge. Post-Goal outgoing actions, pending/busy/cancel combinations, keyboard/Presenter/UI behavior and real graphical input are not expanded. Human QA remains NOT_RUN; no first-time player participated. No production code, gameplay rule, Art asset, original evidence/profile or immutable Build was changed; no new Build is required.

The next minimal operation is Runtime/Solver Owner support for an admitted typed checkpoint resume, or a later public Explorer run with a budget greater than 580 seconds plus analyzer/finalization time. This turn's 1200-second engine limit precludes another complete search. No production API changes are authorized here. Post-Goal/lifecycle/graphical/Human acceptance remains independent even after a future Goal-terminal graph certificate completes.

Reproduction, public API constraints and budget enforcement are in [METHOD.md](METHOD.md). Per-frontier compact outcomes, phase timings, process receipts, checkpoint hashes and the independent certification result are in [RESULTS.json](RESULTS.json). Full candidate outcomes and checkpoints remain in the absolute evidence directory; only reviewed source tests and compact reports are delivered through Git.
