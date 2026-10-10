# PFALL_TARGET_PLATFORM_AND_TRAJECTORY_FIX_01 — approved Owner01 profile delta

Approved by 00 in the current BUILD delegation on 2026-10-10. This Owner document records the concrete interface for 00's shared registration; it does not edit the frozen shared contract. Implementation proceeds in the existing feat/pfall-runtime worktree at c60912b494baccb942e3f37f7c28d0c0c035dcc8.

## Explicit version dispatch

- Old schema1/foundation.contract.v1 and schema2/foundation.game_feel.v1/foundation.rules.game_feel.v1 retain their exact shapes and semantics.
- New level: schema_version=3, contract_version="foundation.game_feel.v2", rule_version="foundation.rules.game_feel.v2", orientation_version="cube24.v1".
- New connection retains connection_id/source_face_id/source_edge/target_face_id/allowed_camera_quadrants/allowed_world_orientations/required_flags/orientation_policy/motion_profile_id/presentation_duration_ms. Replace path_points2 with REQUIRED trajectory. No old-version migration, unknown field/version fallback, or second LevelCodec.
- New curve Fall STARTED/COMMITTED/INTERRUPTED uses schema_version=2, contract_version="game_feel.event.v2". Common event fields and five-field native transition_identity remain unchanged. Its motion field is authorized_trajectory; no authorized_path_points2 fallback. Roll/Edge/non-Fall events retain event.v1.
- StateKey and SolutionTrace retain statekey.game_feel.v1/solutiontrace.game_feel.v1 format and seven core fields; current level_hash and new rule_version bind their semantics. No animation/trajectory/progress field enters PuzzleState. Native result remains eight fields, Fall remains one local transition, and Replay is reused.

## Closed trajectory record

```text
trajectory_version: String = "pfall.departure_cubic.v1"
departure_points2: Array[Vector3i], exactly 2
descent_control_points2: Array[Vector3i], exactly 4
```

All points are canonical world actor centers in doubled coordinates, component range [-1000000,1000000]. Wire coordinates are integer triples. Arrays retain their ordered geometry; connection/permission collections use existing canonical ordering. No optional fields or implicit values.

Let S,D be departure_points2 and P0..P3 the cubic controls. P0=D. Normalized geometry parameter u∈[0,1]: line S→D over [0,1/4]; cubic Bernstein P0..P3 with t=(4u-1)/3 over [1/4,1]. P1-P0=D-S gives C1 at u=1/4. The source line is nonzero, parallel to the positive declared FaceAxis direction, on the support plane, and clears at least 2 doubled units. P3 equals the target actor center; P3-P2 is a nonzero negative target-normal vector. Exact source/target TOP anchors, same World and PRESERVE cube24 orientation remain mandatory. New profile allows screen-x variation but proves nondecreasing screen-v over the entire curve and strictly positive net descent using the fixed game_feel.orthographic.v1 projection; real height is not a rejection condition.

## Pure sampling API for 10A

```gdscript
const Trajectory = preload("res://foundation/game_feel/trajectory_profile.gd")
static func sample_actor_center(trajectory: Dictionary, parameter: float) -> Dictionary
```

The return has exactly `{ok:bool, position:Vector3|null, issues:Array[ValidationIssue]}`. position is in ordinary WORLD UNITS (doubled coordinates divided by 2). parameter must be finite and in [0,1]; reject invalid input, never clamp or silently normalize it. Endpoints and the join are returned exactly. This function validates the closed representation and evaluates that single authorized geometry. It has no Runtime/Node/clock/state mutation and does NOT authorize traversal or attest Safety. 10A consumes the Runtime's immutable authorized_trajectory after its actual SAFE attestation, calls this pure function, and may only apply a monotone C1 time reparameterization. It must not invent controls, smooth old polylines into this profile, or fall back when the version is unsupported.

## Continuous Safety

Safety.validate_perspective_motion keeps its existing signature/result and dispatches by the validated level version. For the new profile it binds exact source/target actor centers and frames before proving the full translating unit-cube sweep. Every same-world entity, including source, target, blue_reference and exit, is tested. Bernstein convex hulls are conservatively expanded by the actor envelope; exact dyadic subdivision proves separation, exact interior witnesses prove UNSAFE, unresolved bounds return UNPROVEN. A hull overlap alone is never a collision verdict or SAFE.

Frozen local proof limits: max depth12, max100000 hull/obstacle tests; common scale2^36 supports exact half splits through depth12 without rational cross-products. Far obstacles are first separated against integer root hulls; scaled comparisons only involve the bounded near region. All integer operations are checked; overflow reports ARITHMETIC_OVERFLOW=1105. Exhausted proof returns VALIDATION_INCOMPLETE/UNPROVEN. No epsilon or sampled-frame SAFE. Evidence kind is "dyadic_cubic_cube_sweep.v1" and binds the actual query, before/after StateKeys, level_hash, connection_id and canonical motion_profile_hash (including trajectory and view version).

Only new rule.v2 may supplement ordinary Roll's existing conservative enclosure with a rigorously proven directed quarter-turn half-space separator. No entity-ID exemption; any unresolved body retains the old fail-closed result. Old versions retain their original enclosure behavior.

## Approved four-platform A/B candidates

09 owns source[0,4,0], target[-6,y,8], nonwalkable visible blue_reference[-8,y,8], exit[-4,y,8], y=0/8. Source/Target are TOP, Camera EAST1, input U_NEG2, PRESERVE. Exit is a distinct TOP Goal after U_POS0 Roll.

Departure for both: [0,6,0]→[-2,6,0].
A cubic: [-2,6,0],[-4,6,0],[-6,4,8],[-6,2,8].
B cubic: [-2,6,0],[-4,6,0],[-6,14,8],[-6,10,8].
The read-only rational feasibility calculation proves A at root hull and B with four leaves/depth3; it is not formal Runtime or graphical acceptance. B's projected cubic derivative minimum is4, A's12 (unscaled projection numerators, local cubic t).

## Owner boundaries and verification

01 implements representation/codec/version dispatch, pure sampler, permission/Safety, event payload and new-rule Roll proof. 09 consumes the approved fields in author DATA; 10A consumes the pure sampler; 00 owns Presenter/Host integration; 03 owns shared acceptance registration. This Owner does not change those roots or reimplement Replay/Solver/Spatial/Orientation.

RED/GREEN must cover closed versions/types/bounds, exact endpoints/C1, deterministic samples, screen-descending physically higher target, interior curve collision/UNPROVEN, source/target contact, new-rule Roll with real blue entity, illegal Camera/World/face/no connection, authoritative identity/count/Busy/reset/late callbacks, directed Solver/Softlock/logical Replay, and legacy v1/v2 regression. Natural new-profile graphical verification requires 00/10A consumption; it cannot be replaced with a linear ghost or synthetic finished signal.
