# 00 integration request — PFALL_ANIMATION_LANDING_01

Contract baseline: 2938d6e534f5b596bb320ce79d72b69f5923f3cd. No shared-file edits by 10A.

## Exact seam

Preload `game/feel/animation/fall_landing/fall_motion.gd` and `landing_motion.gd`, instantiate once per bound run. Both expose the contracted `begin(event)`, `sample(elapsed_seconds)`, `cancel(presentation_identity)`, `clear()`. `parameters` is a `motion_parameters.gd` Resource. Configure before begin; each begin freezes values and custom timing Curve into a private snapshot. Defaults are experimental, not accepted art values.

00's router must deduplicate `(session_id, level_run_id, event_id)` before begin, including duplicate STARTED/COMMITTED after an effect has cleared. The samplers reject overlapping begin while active; clear/cancel intentionally releases their effect state, and they do not own a lifetime Gameplay event ledger. Add duplicate committed delivery to real host integration tests.

STARTED validation consumes the canonical immutable v1 Fall DTO, explicitly `safety_verdict="SAFE"` (literal string), nonempty profile/connection identities, PRESERVE, canonical source_frame u/v/normal Vector3i and positive duration <=30 seconds. This is consumer validation, not Safety proof. If 01 chooses a structured Safety verdict instead, submit the exact version/field change through 00; do not silently infer SAFE. Only supplied points2 positions are used, including corners/duplicate knots; no added control point or generated world-gravity path.

Fall begin returns duration_seconds and cue_schedule `{FallStart:0, LeavePlatform:anticipation_end, FallMoving:departure_end}`. The anticipation/departure/fall duration settings are weights rescaled to Runtime's exact presentation_duration_seconds. Departure traverses the first `departure_path_fraction` of arc length; the main fall consumes the rest with monotonic timing. The source center is exact at t=0. `AWAITING_COMMIT` remains active at the exact target with neutral offsets and motion_done=true until host clear/cancel, permitting native completion to happen asynchronously. Repeated sample does not emit signals or finish anything.

On motion_done, **00 alone** requests native completion once using the captured transition_identity. Dedupe completion using the complete identity; do not replace its transaction id with session.transaction_id. On matching authoritative COMMITTED, clear Fall then begin Landing. Gate this event against the captured presentation_identity before calling Landing.begin; a standalone Landing sampler does not own the prior Runtime proposal. COMMITTED may omit STARTED-only fields; default decoration is world-UP (initial TOP->TOP). If the captured STARTED source_frame is available, retain that same immutable frame for direction-aware pitch; no geometry inferred from mesh transforms.

Landing returns null position always. Its begin returns cue_schedule `{LandingImpact:0, LandingSettled:duration_seconds}`; deformation goes through finite compression then a damped, windowed rebound. Exact end sample is identity quaternion / ONE scale. Decoration uses world-frame rotation and diagonal world-axis scale: compose `Basis(rotation_offset) * Basis.from_scale(scale_multiplier) * authoritative_basis`. This release supports the initial same-normal TOP->TOP lab; other support frames require a reviewed destination-frame contract rather than assuming source normal is the landing normal. Offset positions use canonical points2*0.5 before the **same** existing visual/world-layer translation used for platforms. Only 00's final writer owns the real Actor/Pivot. Do not add a competing tween writer.

Route cue_schedule crossings through the existing presentation/audio/VFX wiring, deduped per captured presentation_identity, including skipped-over markers after long frames. These markers are local presentation times, not a second Gameplay Event Bus. FallCancelled derives from the authoritative ANIMATION_INTERRUPTED event; cancel() synchronously clears and does not synthesize landing or completion. Audio/VFX Owners choose their playback. No runtime event or audio bus was added by 10A.

Pause: freeze caller elapsed time; resume same elapsed/token. Reset/load/unload/quit/cancel: invalidate host identity first, call both cancel(old_presentation_identity), restore the current authoritative base pose. Late cancel cannot erase a new motion. A cancelled sampler has null position and neutral offsets immediately. Validate identity before applying a sampled transform or handling deferred completion. No tweens/signals/nodes exist inside these modules.

Reduced Motion: set each module's `parameters.reduced_motion` before begin. Fall removes anticipation lean and preserves continuous path/timing; Landing remains neutral for its duration with the same completion markers. It does not allocate new Save/settings keys.

## Cases requiring 01/00 integration

Natural legal MAP A/B Fall, native exactly-one-commit, Runtime Orientation/StateKey parity, native BUSY for held WASD/Shift/Q/E/drag, Reset generation changes, Safety/Solver/Replay and Audio/VFX/HumanQA: **case_pending; checks=0; doubles=[]; actual delivery SHA=null**. Owner-local records below must not be registered as these cases.
