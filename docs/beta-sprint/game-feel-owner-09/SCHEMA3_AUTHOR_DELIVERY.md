# Owner09 schema3 authoring delivery

Parent: ad8f4259df69a7e726762d6f42d95e00263eecf3. Consumes 00's registered supplement at ec826753435458abc41cc365e4b57dba27767fbd, `docs/beta-sprint/game-feel/yellow-target-01/TRAJECTORY_CONTRACT_DELTA.md`. Frozen base contract unchanged.

## Production interface and data

`map_factory.bake_game_feel(data)` still calls the real Baker. Its explicit author conversion now supports schema3 / foundation.game_feel.v2 / foundation.rules.game_feel.v2. New connection emits `trajectory`, never path_points2; old schema2 conversion retains path_points2 without reinterpretation. Unknown schema returns invalid author data for Baker to reject. v1 bake remains v1.

The registered closed trajectory record is consumed exactly: trajectory_version `pfall.departure_cubic.v1`, native Array[Vector3i] departure_points2 (2), descent_control_points2 (4). Both departures [0,6,0]→[-2,6,0]. A cubic [-2,6,0],[-4,6,0],[-6,4,8],[-6,2,8]. B cubic [-2,6,0],[-4,6,0],[-6,14,8],[-6,10,8]. No private evaluator, spline smoothing, permission test or fallback is introduced.

Four real platforms, EAST eligibility, explicit input U_NEG, PRESERVE and target/TOP→U_POS→exit/TOP intent remain unchanged. New target equals the original screenshot yellow position. Map does not publish events, convert event.v2 into v1, modify 00 Host or call the sampler as a permission check.

## Strict actual validation

- curve_author_red_01: 42 checks, 8 expected author-contract failures against old schema2.
- curve_author_green_01: 42 checks PASS, PID3348; schema/typed fields/canonical endpoints/exact join plus baseline map checks.
- curve_geometry_green_01: 17 checks PASS, PID34520; actual four-platform Baker/Anchor and nonwalkable reference support refusal.
- curve_legacy_green_01: final 46 checks PASS, PID47924, adding two-map legacy schema2 shape preservation and exact historical v1 baked content-hash equality. Legacy inputs are pinned to e4bcdfc6459f587cb26c25494dd5b57b76ccdca4, not mutated current inputs.

All use isolated user profiles, real baseline modules, doubles=[], raw process/source snapshots and retained WIP identity. The latest run's recorded code/map hashes bind the final source; this report is documentary only. Source manifest: SCHEMA3_FILES_SHA256.json.

## Dependencies still pending

The 09 worktree has not imported Owner01's new schema3 Runtime/Safety; the real local Baker rejects the new profile, and tests label that honestly. Formal schema3 bake, full cubic swept-volume SAFE, new-rule ordinary Roll separator, Solver/Replay full route, sampler-driven animation and graphical evidence must run after delivered dependencies are integrated. Prior yellow exit Roll rejection against blue_reference is not cleared by author-contract GREEN. All eleven full-Fall cases remain pending with zero checks. No PFALL_YELLOW_PLATFORM_LANDING_PASS, new Build or HumanQA claim.

00 may consume the registered author fields immediately in its integration line; actual Runtime rejection or validation issues must stay observable. Do not replace them with v1 or skip Safety. 09 has made no Foundation, shared Host/Presenter, frozen Art, old five-level or L06 change. Push NOT_RUN.
