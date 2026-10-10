# Owner10A forward-then-drop delivery

Task: **PFALL_FORWARD_THEN_DROP_TO_YELLOW_FIX_01**, continuing PFALL_ANIMATION_LANDING_01. Production commit: **3b60de04f4c14e2d6576550acbf968e7c4b0be51**, parent **09f1f681575674a49a75402e7ea4d922c6d8d72b**. Only `fall_motion.gd` and `motion_parameters.gd` changed in this production commit. This receipt, test harness changes and fresh raw evidence are delivered separately. Push **NOT_RUN**.

## Behavior and boundary

Event.v2 immediately advances along the author-approved Source→Departure line while raising a signed forward lean. It holds that lean through the cleared edge, enters the approved cubic with matching positive velocity, then fades lean to exactly identity at the actual target. The default descent timing accelerates its authorized geometry parameter. No spatial control points are generated or changed; every v2 position still comes exclusively from Owner01 `sample_actor_center`. The motion cannot alter Runtime, Gameplay Roll, orientation, Camera, support geometry or Safety. LandingMotion is unchanged and requires COMMITTED; visual arrival remains AWAITING_COMMIT.

The old stationary anticipation interval is replaced by a moving lean-in for v2. The local phase schedule is now FORWARD at zero, DEPARTURE when the actor center crosses the real source unit-support edge, FALL_MOVING at the author-approved line/cubic join, and AWAITING_COMMIT at the authoritative presentation duration. This schedule describes visual timing and grants no gameplay permission. LeavePlatform uses the derived center-edge time; FallMoving uses the join. Source support is a formal unit cube: its center-edge distance is 0.5 world units along the declared native departure. Descent begins only at the supplied Departure, at least 1 world unit from Source. Reduced Motion preserves default and custom physical timing, endpoints and phase markers while omitting lean decoration.

The begin/sample/cancel API and event.v2 DTO remain unchanged. 00 retains sole Presenter/Visual Root and Transition wiring. No shared Presenter/Host/Event Bus files were edited. Consumers that display local phase labels should recognize FORWARD; Audio/VFX owners can use the returned cue schedule through existing 00 integration. A matching cancel/clear restores a neutral sampler immediately; restoring the corresponding authoritative Visual Root pose remains 00's existing responsibility.

## Experimental tuning and deterministic timing

Existing anticipation_duration, departure_duration and fall_duration weights remain configurable. V2 adds forward_duration_multiplier = 13/3, forward_start_speed_ratio = 0.15, and fall_entry_speed_ratio = 0.25. These are experimental values, not formal art approval. Only the new three ranges use float64 bounds so their declared inclusive 0.05 and 0.9 endpoints work; legacy range validation is unchanged.

Forward weight is `(anticipation_duration + departure_duration) * forward_duration_multiplier`. With default weights, forward occupies 65% and descent 35% of the supplied duration. For 300 ms: forward starts at 0; the real center-edge marker is 123.005965 ms; the author Departure/cubic join is 195 ms; visual arrival is 300 ms. Lean reaches 5 degrees halfway through the forward interval and persists through the join.

The default main timing is `entry*p + (1-entry)*p*p`. Its entry speed is capped to make the forward Hermite derivative's Bernstein coefficients nonnegative. The same positive parameter velocity is shared across the spatial C1 join. Custom curves retain frozen, monotone Hermite interpolation; v2 rejects flat sampled intervals in both Reduced and regular modes to prevent air pauses. Authored geometry and supplied total time remain unchanged. No claim is made that world-space speed or projected screen speed is globally monotone on Map B; geometry can change speed independently of parameter timing.

## Fresh evidence for this task

All cases below are under `evidence/`, use isolated user profiles, and preserve original raw logs and source snapshots. Owner01 dependency is actual clean committed **fd22434d3eb0de52a764cb98222371a39412635a**. Sampler SHA256 **02f2f3f3660cbffd31d72acd7dae3f99a8f91249cfd9672734297862230c711c**, Git blob **3bd7d54c5e7577d88873d909e2afdc77e1c42245**. Recursive Foundation dependency bindings and source/copy drift checks are recorded in the JSON receipt.

| Case | Checks / failures | Meaning |
| --- | --- | --- |
| forward_drop_owner_red_01 | 788 / 40 | Baseline stationary onset, lost departure lean and uniform descent timing reproduced |
| forward_drop_custom_reduced_red_01 | 1911 / 239 | Custom Reduced timing mismatch and flat-curve acceptance reproduced |
| forward_drop_parameter_bounds_red_01 | 1935 / 6 | Inclusive new .05/.9 bounds rejected by float32 storage reproduced |
| forward_drop_parameter_bounds_green_01 | **1935 / 0** | Final new-task headless acceptance, including both later fixes |
| forward_drop_release_curve_regression_01 | **6856 / 0** | Final event.v2, Landing, orientation and cancellation regression |
| forward_drop_release_v1_regression_01 | **4431 / 0** | Final legacy v1 regression |

Two intermediate zero-check runs failed because diagnostic variables required explicit GDScript types: forward_drop_owner_extended_green_01 and forward_drop_owner_acceptance_01. These are harness failures, not behavioral RED. Later runs corrected the harness; old records are append-only. Earlier task evidence, including the old 7556-check sampler rebind and private screenshots, is not reused as acceptance for this correction.

The final forward tests cover A (world Y 3→1) and B (world Y 3→5), 120 strict advancing samples per default case, approved fixed-view descent, no source-normal drop while center remains over support, exact Source/Departure/Target, no teleport, finite-difference C1 at the join, signed forward lean in all 24 actual composed cube bases, default/custom Reduced parity, frozen configuration, atomic invalid bounds/path rejection and scoped cancellation. The broader final curve/v1 suites cover COMMITTED-only impact, damped settle, exact orientation/scale restoration and lifecycle doubles.

For both maps the first 15 ms advances **0.019064959 world units** with **0.005567265 radians** of correctly signed lean. Join lean is **0.087265939 radians**. The first/last 20% descent windows advance the actual sampler parameter by **0.059999989 / 0.240000015**. Finite-difference velocities across the join remain positive and differ by under 2%. The actual fixed-view projected distance in the late window exceeds the early window by the tested factor >1.5 on both A/B; full diagnostic rows are in `forward_drop_parameter_bounds_green_01/diagnostics.json`. These measurements substantiate the timing correction, not human approval of weight/feel.

## Acceptance scope and handback

**Presentation headless Unit PASS**: A/B continuous trajectory; forward onset/lean; Landing sampler; cube24 orientation; DTO/World immutability; Reduced Motion; identity-scoped cancel and interruption/input doubles. Event DTO, SAFE attestation and native commit are explicit doubles. `authoritative_runtime=false` in every raw record. Actual committed pure trajectory math is consumed, but this is not RuntimeReal or natural gameplay evidence.

**00/08 pending**: actual Runtime/Presenter graph GREEN, real yellow-platform bottom contact, natural Reset/Pause/scene exit/WASD/World Shift/Q/E/drag arbitration and human feel/video acceptance. No graphical Godot window was opened for this task because 00 reserves the desktop. No new screenshot/video is claimed. 00 can merge the narrow production commit immediately for independent graph replay, followed by the metadata/tests/evidence commit. No shared integration edit is required by this Owner delivery.

Production files:

- `game/feel/animation/fall_landing/fall_motion.gd` SHA256 **ab7b46d282c5c8952866b1d3deb4a663c6f967afdea9e65309ca8c581098001b**.
- `game/feel/animation/fall_landing/motion_parameters.gd` SHA256 **e8f15370b962ec84ff8d449a1ae39f191dd1b20702383c08f0347367c4e33add**.

Test changes: `curve_forward_unit.gd`, runner mode `curve_forward_unit`, and preview capture support for FORWARD (capture mode not run). Review found no remaining Critical/Important issues after the custom Reduced and parameter boundary fixes.
