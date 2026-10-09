# PFALL_ANIMATION_LANDING_01 implementation plan

Goal: independent deterministic Fall/Landing samplers for the approved game_feel.event.v1 seam. Native inline implementation is authorized by the implementation task and 00's BUILD continuation.

Spec: ../game-feel/GAME_FEEL_CONTRACT.md (2938d6e534f5b596bb320ce79d72b69f5923f3cd).

Architecture: RefCounted modules own immutable event/config snapshots, never nodes or Runtime. Fall samples a distance-parametrized polyline from canonical actor-center points2; its configurable anticipation/departure/fall intervals fit the authorized presentation duration. Landing returns rotation/scale offsets only after COMMITTED. Caller owns elapsed time, pause and the one visual writer.

Files: game/feel/animation/fall_landing/{motion_parameters,fall_visual_state,fall_motion,landing_motion}.gd; tests/beta_sprint/game_feel_owner_10a/{unit,fixture,preview,run}.gd/.ps1; this documentation root.

Constraints: PRESERVE only; exact source/target path positions, no additional control points, no Runtime finish calls, no gameplay bus, no shared edits, no push. Defaults are experimental. Synthetic fixtures declare authoritative_runtime=false and doubles. Natural authoritative A/B/input/Reset cases remain pending until 01/00 delivery.

Review focus: malformed DTO/config fails atomically; monotonic easing stays on every polyline segment; sample snapshots cannot mutate private state; stale cancel cannot clear a new identity; finite elapsed time and degenerate path/config produce no invalid transform.

- [x] Task 1 RED: isolated behavioral test for missing sampler delivery; retain raw sources/logs separately from parser/dependency failures.
- [x] Task 2 GREEN: event/identity validation, tunable parameters, deterministic Fall polyline sampler and Landing damped recovery; validate read-only consumption and all 24 endpoints.
- [x] Task 3: private 3D preview for both height signs, four fixed camera quadrants, actual rendered screenshots and sample trace. Label presentation Unit, never real Runtime/Safety evidence.
- [x] Task 4: interruption/input/pause controls in private fixture; malformed, duplicate, late/new identity and reduced-motion tests; preserve process identity, isolated user://, source hashes and drift checks.
- [x] Task 5: read-only fresh-agent review found no Critical/Important defects. Fresh verification and integration request recorded; delivery receipt binds actual commit to unchanged tested source hashes. Push NOT_RUN.

Ruling: Owner-local begin/cancel/sample are tested independently of the pending real 01 port. No synthetic test is counted as natural Fall gameplay acceptance.

Ledger: red_01 failed the expected missing-sampler checks (exit1, no parser failure); green_01 exposed the test's missing explicit host clear; green_02 passed. unit_extended_01=2002/0; unit_final_01=2003/0. graphical_unit_01 was a separate parser failure (private preview variable shadowed Node3D.basis), never counted as behavioral RED. graphical_unit_02=255/0; graphical_final_01=251/0; frame counts vary with actual process FPS. COMMITTED-only fields remain optional where the contract specifies them only on STARTED. Review notes: 00 owns event-ID deduplication; noninitial landing frames require explicit destination-frame extension.
