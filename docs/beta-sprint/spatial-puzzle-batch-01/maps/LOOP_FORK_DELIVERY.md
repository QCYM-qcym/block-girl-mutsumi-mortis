# Owner09 incremental delivery: Loop and Fork

Base: `5664a32a33eb178934e3233cc59c938132622fc0`. This is a two-map delivery; Gate, FaceLock and combined maps remain pending the schema4 implementation. The factory lists all five stable IDs; the pending IDs fail real Baker admission and must not be presented as playable.

## Real results

`python tests/beta_sprint/spatial_owner_09/run.py loop_fork_05` passed 74 checks, PID 40440, exit 0, empty stderr, zero source drift. Exact sources, hashes, engine identity, isolated profile and raw results are retained in `evidence/loop_fork_05/`.

| Map | Real complete graph | Softlocks | Logical Replay |
|---|---|---|---|
| orientation_loop_lab | 51 states / 246 edges | 0 | PASS |
| perspective_fork_lab | 80 states / 264 edges | 0 | PASS |

No test doubles or replacement algorithms. Formal Baker, RuntimeSession, Safety, Goal, BFS, Softlock and TraceReplayer are used. Runtime witnesses explicitly finish native tokens in logical test mode; this is not graphical animation evidence. Graphical, integration and human acceptance remain pending with their owners.

## Map design and consumption

Loop uses four platforms in a square. `[U_POS,V_NEG]` and `[V_NEG,U_POS]` reach the same corner with different orientations; `[U_POS,V_NEG,U_NEG,V_POS]` returns to spawn with changed orientation. Goal is outside the square at `(8,0,10)` in center2 units. A real camera-NORTH, U_POS Forward Drop from the corner reaches it. Goal is not encountered during the closed loop. `solution_after_loop` explicitly validates completing the loop before leaving. Host must expose the ordinary mapped movement for the U_POS exit; fixed F retains U_NEG and is not remapped.

Fork has the exact same source/edge/world/orientation and MOVE U_NEG for EAST→A versus SOUTH→B. A rolls onto Goal. B rolls onto its return platform; NORTH + U_POS activates a second authored Forward Drop back to the original source, then EAST→A→Goal. The return is a real Safety-validated connection, not Reset or teleport. All reachable non-goal states can reach Goal in the real full graph.

## Failed evidence retained

- `loop_fork_01`: test mistakenly treated Goal's dictionary result as bool.
- `loop_fork_02`: added straight-road cube made Roll Safety UNPROVEN; negative-number IDs also failed author grammar.
- `loop_fork_03`: replay was called with an absent solution trace; process timed out. The test now preserves this failure instead of crashing.
- `loop_fork_04`: 61 checks passed, but the Loop goal was on the corner. Superseded for delivery by the external-goal design in 05.

The conservative Roll sweep is unchanged. The final maps avoid the problematic extra straight platform; they do not disable Safety or add hidden supports. Foundation, legacy levels and Art sources: no Owner09 changes. Push: NOT_RUN.
