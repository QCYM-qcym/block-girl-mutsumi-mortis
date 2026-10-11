# Owner09 five-map logical delivery

Status: **SPATIAL_MAP_01_READY_FOR_INTEGRATION**. All five authored maps passed real logical acceptance. This is not the full batch Build/graphical/Human completion declaration.

Worktree: `E:/godot/worktrees/block-girl-spatial-map-01`; branch: `feat/spatial-map-01`. Production maps: `9debc8e33efc32593f33888a7d30e0e69a873fb6` (unchanged afterward). Runtime dependency: Owner01 `697a31ed85e29b1d37ec882e712d323751bd90a1`, normally merged at `0f26b64956c6b055f5f1ead49e7b8aee1146d0f8`. No rebase, push, main/release edit, old-level edit or old-QA rewrite.

## Measured results

| Map | Real Baker / Runtime | Complete Solver graph | Softlocks | Logical Replay |
|---|---|---|---|---|
| world_shift_gate_lab | PASS | 16 states / 56 edges | 0 | PASS |
| orientation_loop_lab | PASS | 51 states / 246 edges | 0 | PASS |
| face_lock_lab | PASS | 104 states / 472 edges | 0 | PASS |
| perspective_fork_lab | PASS | 80 states / 264 edges | 0 | PASS |
| rubik_spatial_puzzle_01 | PASS | 908 states / 3916 edges | 0 | PASS |

Final cases: `gate_runtime_01` 22 checks, `face_lock_runtime_01` 54, `combined_runtime_02` 103, `loop_fork_runtime_01` 74, `fork_matrix_runtime_01` 37: **290 checks PASS**, actual process exit 0, stderr empty, no source drift. See each `evidence/<case>/process.json`, `report.json`, source snapshots and logs. No doubles, fake Baker result, replacement rule engine, search or Safety algorithm.

### Gate, contact, orientation and isolation

Off-point Shift rejects with 2010; locked Shift rejects with 2011. Rejections preserve full StateKey and emit no transition or commit. Successful SAME_NORMAL Shift uses the original Shadow/mapping/Safety path and preserves exact cube orientation and camera. The nonwalkable roofs provide real shadow and must remain visible.

Wrong sensor arrival `[U_POS,V_NEG]` reaches orientation 20 and leaves `contact_lock=idle`; movement succeeds. Correct arrival `[V_NEG,U_POS]` reaches orientation 14 with RIGHT down and latches atomically. Each accepted transition has one native completion and one authoritative commit; direct USE of the ENTER sensor rejects. Repeat arrival preserves the latch; Reset restores the initial full StateKey.

Loop reaches the same corner with distinct orientations and completes a closed return with changed orientation. Its Goal is outside the loop; the post-loop solution is verified. Exit uses a real NORTH/U_POS Forward Drop. Fixed F remains U_NEG; ordinary camera-mapped input supplies U_POS.

Fork uses exactly the same source/edge/world/orientation and MOVE U_NEG with EAST→A versus SOUTH→B. NORTH/WEST reject (2101). A rolls onto Goal. B rolls to the return platform, takes its NORTH/U_POS Forward Drop back to source, then reaches Goal through A. Falls preserve layer and orientation. Cross-world targets reject 2102; unwalkable targets reject 2100; both preserve StateKey and produce no transition. Overlapping camera permissions fail real Baker admission.

### Combined puzzle

Both explicit complete routes passed: 8 actions through A, and 13 through the recoverable B branch. Those witnesses include an explicit camera request even when unchanged; Solver's shortest solution is 7 actions. Both finish at the Inner Goal with a latched mechanism. The full graph contains **zero** reachable Inner states without the latch. It also proves every reachable non-goal state can reach Goal without a Reset edge. Search reports zero Safety-unproven rejections; all accepted transitions still use formal Safety.

The first combined run hit the harness's 300-second process timeout. It remains FAILED in `combined_runtime_01`, with no final report and no gameplay failure inferred. The successful run increased only the harness ceiling to 900 seconds and added a Runtime-witness checkpoint; it did not change the map, action generator, search policy, permissions or Safety. Complete Solver elapsed time was 486313 ms. This is exhaustive verification cost, not an input-latency measurement.

## Evidence boundaries and next owners

| Gate | Owner09 result |
|---|---|
| UNIT / author admission | PASS through real Baker and negative cases |
| REAL_RUNTIME | PASS, actual RuntimeSession requests and state transitions |
| SOLVER / SAFETY / SOFTLOCK | PASS, real complete graphs and formal accepted edges |
| REPLAY | PASS, logical TraceReplayer and canonical StateKeys |
| GRAPHICAL / Pixel–3D visual parity | NOT_RUN by 09; 03/00 own these gates |
| BUILD / five-entry menu / save lifecycle | Owner00/07 integration gate |
| HUMAN_QA | NOT_RUN; requires a real new Build and eligible players |

Logical tests explicitly finish Runtime tokens. They never claim natural animation completion, actual keyboard delivery or human understanding. [New-batch QA preparation](QA_HANDOFF_PENDING_BUILD.md) and the blank [human observation table](HUMAN_OBSERVATIONS_TEMPLATE.csv) are ready for the appropriate owners after Build acceptance. Historical Perspective Fall A/B material is not evidence for this batch.

Remaining handoffs: 00 integrates/builds; 03 independently verifies graphics and formal graphical Replay; 07 checks five-entry UI/lifecycle and feedback; 08 arranges human testing. No remaining map-runtime defect was found. No new Art request. Owner09 Foundation edits: NONE (the named Owner01 implementation is an imported dependency). Art source changes: NONE. Production scope/hash proof: `OWNER_SCOPE.json` and `MAP_ACCEPTANCE_MANIFEST.json`. Push: NOT_RUN.
