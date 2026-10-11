# Gate / FaceLock / combined map authoring

Current status: LOGICAL_ACCEPTANCE_PASS; see [final map report](MAP_DELIVERY_REPORT.md). The authoring/dependency notes below retain the pre-integration design history. Exact contract: `../RUNTIME_INTERFACE.md`. No public Runtime implementation is supplied by Owner09.

## Physical layout and intended route

Positions use the existing integer `center2` units. Surface and Inner gate pairs coincide geometrically with SAME_NORMAL TOP anchors. Nonwalkable roofs at y=12 provide real Surface shadow from the authored celestial slot `(0,30,0)`; they are visible world geometry and must not be hidden by the Host. They are not landing platforms or fall supports.

| ID | Design | Witness |
|---|---|---|
| world_shift_gate_lab | Surface spawn→east gate; fixed forward/reverse gates; Inner gate→south Goal | MOVE 0, SHIFT_WORLD, MOVE 3 |
| face_lock_lab | Four-platform Surface loop, RIGHT local face sensor on corner, latched source gate to Inner Goal | MOVE 3,0,1,2; SHIFT_WORLD |
| rubik_spatial_puzzle_01 | Same loop and sensor, latched source gate to Inner fork; goal branch and recoverable exploration branch | Closed loop, Shift, camera-qualified Fall, ordinary Roll; B returns through its own formal Fall before taking A |

The sensor is an ordinary Roll arrival, distinct from every Gate/Fall landing. Route `[0,3]` reaches the sensor with the wrong down face; MOVE must still apply, keeping idle. Route `[3,0]` arrives with RIGHT down and must latch. Returning to the source completes the loop. No face setter, camera-based contact guess, flag injection or permission decision exists in the factory.

The combined map copies only authored fork topology/trajectories into Inner, renaming its source to `inner_source`; Surface has no Fall connection. The only entry to Inner is a gate requiring `contact_lock=latched`. A formal full graph must prove there is no reachable Inner state before the latch, and every reachable non-goal state can still reach Goal without Reset.

## Pending acceptance

`gated_test.gd` exercises real Baker/Runtime/Goal/Solver/Softlock/Replay. It records actual rejection codes, native transition and commit counts, before/after StateKeys, correct/wrong/repeated contact, direct-use denial, Shift orientation/camera preservation, and Reset. Expected pass is not a measured pass.

The initial pinned Foundation rejected schema4. `gate_contract_red_01`, `face_lock_contract_red_01`, and `combined_contract_red_01` preserve that real dependency RED. The first gate run additionally exposed GDScript new-key dot assignment producing StringName keys; the factory creates new schema fields with explicit String dictionary keys. Committed Owner01 implementation `697a31e` was subsequently merged and all three maps passed formal verification; no uncommitted dependency was used as acceptance evidence.

## Independent regression

`loop_fork_06`: 74 checks PASS with the extended factory, empty stderr and zero source drift. `fork_matrix_02`: 37 checks PASS; four views, orientation/layer preservation, Reset, missing camera qualification, cross-world target, unwalkable target, and overlapping qualifications. In `fork_matrix_01`, the test incorrectly expected Baker to reject the two conditional landing cases; the formal contract admits those resources and rejects the attempted Runtime action. The corrected test verifies those actual Runtime rejections and unchanged StateKey.

Existing committed evidence remains untouched. New evidence excludes live profile files and disables Git text conversion. No legacy level, Foundation, Art source, Host or save implementation changes. No graphical/Human acceptance is claimed. Push: NOT_RUN.
