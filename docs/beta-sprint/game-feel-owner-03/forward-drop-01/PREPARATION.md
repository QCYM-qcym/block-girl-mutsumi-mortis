# Forward-then-drop: Owner03 test preparation

Task: `PFALL_FORWARD_THEN_DROP_TO_YELLOW_FIX_01`.

The current user brief assigns ten focused checks to Quality. Preparation starts from clean Quality commit `4506b9b0896fc2d4b31b9a691afb3eb96bf929ef`. All changes stay within Owner03 tests and evidence. No production code, public contract, map or Runtime algorithm is changed.

## Authority and execution boundary

The sampler test loads the real Map A/B through the public Baker and Runtime Facade. Its actual STARTED event supplies the authorized trajectory and SAFE proof to the real 10A Motion sampler. It never creates fake transition events, writes actor pose, completes Runtime manually or copies a trajectory algorithm.

The source support boundary comes from official Spatial geometry: a unit cube has a half extent of 0.5. Fixed formal View projection measures descent even when Map B gains physical height. This projection is an observation, not an animation authoring rule. Owner01 retains geometry and Safety authority.

The existing strict receipt launcher remains unchanged. The new launcher writes a separate evidence directory and binds each future run to the supplied combined candidate and delivered 10A commit. It verifies production bytes, actual process identity, private profile, exit code, stderr and source drift. A baseline sampler RED cannot accept this new task.

The graphical test consumes the real Graphical TraceReplayer and its actual rendered completion frames. It retains the existing native identity, StateKey, World, Camera, Orientation, final pose and repeated-run checks, adding forward displacement, source-edge clearance and descent cadence. Input, lifecycle, Core and affected legacy recipes will run afresh after intake; prior PASS receipts are not reused.

## Measurements and Reduced Motion

Normal motion must start moving forward, clear the source edge before leaving its support plane, retain forward movement, avoid a positive-time stationary interval and accelerate through descent. Four observed positions at 15/35/65/85 percent of the descent interval are mapped back to geometry parameters using only Owner01's public sampling API. Later parameter advance per elapsed second must exceed the early rate by 20 percent. This rejects uniform timing that happens to accelerate in projected space because of curve geometry.

Reduced Motion records the same metrics. Its hard checks cover authorized geometry, forward direction, edge order, exact endpoints, identity and unchanged Runtime state. Normal-motion stationary-interval, speed, cadence-acceleration and lean assertions do not apply to Reduced Motion.

Eight Unit checks use hand-derived point/time data to exercise the measurement consumer. They detect uniform timing, off-path observations, an initial hold and descent while still supported. They do not certify Runtime or Graphical PASS. Quantitative observations also do not certify human feel.

## Evidence history

- `fd_parse_01`: a test-label type inference error, preserved as a preparation error. An explicit String annotation corrected it. Later parse runs exited 0 with empty stderr.
- `fd_baseline_red_01`: 1,018 real authorized-sampler checks, four expected failures. Normal Map A/B held still initially. Exit 1, empty stderr, no doubles or source drift.
- `fd_baseline_red_02`: 1,024 checks, six expected failures. Each normal map had 36 stationary intervals totaling 90 ms; early and late geometry rates were both approximately 1.7857 per second. Yellow target and source-edge ordering remained correct. The stronger cadence measurement exposed uniform timing despite increasing projected speed.
- `fd_measurement_unit_01` and `fd_python_unit_01`: 8 measurement and 52 existing Python Unit checks passed. Neither is Real acceptance.
- Review correction: move normal stationary-interval and projected-speed assertions out of Reduced Motion. Raw RED02 evidence remains unchanged; `fd_measurement_unit_02` parsed all four scripts successfully and passed eight Unit checks. `fd_baseline_red_03` bound the corrected tests: 1,020 checks, the same six expected normal-motion failures, exit 1, empty stderr, no doubles or source drift.

## Pending acceptance

All ten final cases remain PENDING until new-candidate execution. Owner00 has now supplied candidate `c89a87584d8d5db0916d4b0e516c449860063223`, containing 10A delivery `3b60de04f4c14e2d6576550acbf968e7c4b0be51`, and explicitly released the graphical window. Preparation is sealed before controlled intake. A new six-phase natural rendered receipt and actual target-contact/settle evidence must belong to that candidate.

No unsupported Pixel case or unrelated old 94-case pending item is added to this ten-case task. No new Build or push is performed by Owner03.
