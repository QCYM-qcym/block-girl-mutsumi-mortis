# Owner11 — curve Fall event consumption, 2026-10-10

Status: **OWNER_LOCAL_V2_AUDIO_READY**. New curve native Runtime API: **PENDING_01**. New natural/Graphical trajectory and yellow TOP contact: **PENDING_00_01_10A**. Human listening: **NOT_RUN**. Push: **NOT_RUN**.

Parent Audio commit: `7363e9e7d7849018cc456ae866a60e23472591d6`. Shared candidate supplied by00: `9533f102095ed9ee011bfa2aa046d6f1f4504780`. Explicit supplemental registration: `ec826753435458abc41cc365e4b57dba27767fbd`, `docs/beta-sprint/game-feel/yellow-target-01/TRAJECTORY_CONTRACT_DELTA.md`; exact byte/hash binding is V2_CONTRACT_BINDING.json. The original frozen contract is untouched. Delivery SHA is the commit containing this receipt.

## Consumption boundary

- Exact integer schema1/event.v1 retains Fall, Roll, Edge and existing feedback/interruption consumption. Exact schema2/event.v2 accepts only PERSPECTIVE_FALL_APPLIED and ANIMATION_INTERRUPTED. Unknown/mismatched pairs and wrong types fail closed; v2 is never rewritten as v1.
- v2 Fall consumes the readonly closed `pfall.departure_cubic.v1` trajectory: exactly three fields, two departure Vector3i points, four descent Vector3i controls, each component within the registered bounds. It requires structured SAFE evidence bound to connection/profile with `dyadic_cubic_cube_sweep.v1`. Missing/unsupported/mutable records cannot fall back to a legacy polyline.
- Audio does not sample, smooth, prove, select or execute that curve. Its geometry, support contact, monotonicity, exact continuous Safety and real completion remain their formal Owners' responsibilities. No Foundation dependency was added to the production consumer.
- STARTED starts existing scoped fall_start/whoosh with no impact. COMMITTED must match the captured presentation identity, native transition, event version, exact source/target and authorized trajectory; it stops that loop and plays one landing_impact. Duplicate/mismatched/late canceled completions remain silent.
- v2 Interrupt addresses the captured original identity. Reset/Cancel/Unload/Quit stop without impact; an old scoped cancellation cannot stop the replacement. A wrong-version interrupt cannot cancel a live matching v2 capture. Paused COMMITTED remains deferred, and Reset removes that queued impact before resume.
- Existing AudioDirector, 18 voice players, buses, volume keys and SaveStore remain unchanged. Only the pure audio event policy changes production behavior. No new AudioManager or persistence writer.

## Fresh evidence

| Evidence directory | Classification | Result |
|---|---|---|
| v2_lifecycle_red01 | Version/lifecycle Unit | 101 checks, 8 expected version failures, exit1, stderr0, driftfalse |
| v2_lifecycle_green01 | Parser failure, not GREEN | Type inference error, child terminated; raw failure retained, no test report, driftfalse |
| v2_lifecycle_green02 | Intermediate Unit | 101 PASS before concrete trajectory shape tests |
| v2_trajectory_red01 | Concrete shape Unit | 113 checks, 15 expected authority/path failures, exit1, stderr0, driftfalse |
| v2_trajectory_green01 | Intermediate Unit | 113 PASS |
| v2_final_policy02 | Final presentation Unit | 116 PASS, exit0, stderr0, driftfalse |
| v2_final_director02 | Final actual Godot audio | 60 PASS, WASAPI/OpenGL, captured nonzero PCM, peak0.11598439514637, exit0, stderr0, driftfalse |
| v2_final_settings02 | Unchanged SaveStore API | 10 PASS; separate PID20884/2224, same isolated profile/save hash |
| v2_legacy_native02 | Actual legacy Runtime DTO API | 16 PASS, no doubles, exact archived Runtime26387d6; direct finish_transition API, not natural animation |

Final total: **202 checks**. v2 samples are synthetic presentation fixtures using the registered literal A record; their SAFE dictionary is a Unit input, not real Safety attestation. Actual v2 players prove AudioDirector port/lifecycle consumption, not a natural Fall or a real yellow-platform contact frame. The legacy native API run explicitly uses old Runtime candidate `26387d6c34a869ad7035ee13ee77d8d5c24d796a`; it is not labeled new-profile Real coverage. Earlier raw runs are retained with their actual source identity and are not retroactively relabeled final.

The final verifier binds all executed owner audio/test/runner sources to the new raw evidence, checks 4,388 baseline files unchanged, and checks all 63 production audio files byte-identical to original delivery4afbd. No original music/SFX/old QA log/save membership was rewritten. Earlier FILES_SHA256 inventories remain historical; FILES_SHA256_V2_FIX.json binds only this incremental delivery.

## Review and pending integration

Read-only review of the concrete supplemental contract and final diff confirmed version isolation, captured curve/version matching, immutable input handling, native identity reuse and scoped interruption. Regression includes ordinary Roll/Edge, existing settings, actual music looping/crossfade/voice teardown, reentrancy and paused lifecycle. No sample-based Safety or timer completion was added.

00 can merge this independent Owner commit and connect unchanged AudioDirector.consume_event to real Facade events. Reset inside the same run uses captured identity cancel/interruption; clear retires the run and remains reserved for actual teardown. New curve actual Facade STARTED/COMMITTED/INTERRUPTED, real per-frame yellow TOP contact and integrated Graphical/Human listening remain separate pending cases until those dependencies are delivered. This pending Real case does not block the verified Owner-local consumer commit.
