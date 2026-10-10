# PFALL_YELLOW_TARGET_LANDING_FIX_REPORT — production map data / route blocked

Parent: 09fba13e1179477e3d90c606ab09e435200e5f09. Active A/B author data now implements the approved four-platform layout; this is no longer just a proposal. No PFALL_YELLOW_PLATFORM_LANDING_PASS claim.

## Actual map changes

A/B target center2=[-6,0/8,8], target/TOP Anchor2=[-6,1/9,8], target actor-center2=[-6,2/10,8]. Exit center2=[-4,0/8,8], Goal exit/TOP. Original blue platform remains a real `blue_reference` Cube at [-8,0/8,8], all faces nonwalkable. Source stays [0,4,0]; A remains 2 units lower, B 2 units higher; Surface, EAST and PRESERVE intent unchanged.

Factory constructs all four real Cubes for normal host geometry rendering. No invisible support, Runtime mutation, art deletion or recolor substitution. v1 `bake(data)` remains the same real Baker API/schema and adds no Fall permission; its author resource reflects the requested new geometry. Legacy input without blue_reference_center2 retains its original behavior. 00 owns visible canonical target/exit/actor color mapping.

Opt-in endpoint now matches the true new target actor-center. Its old polyline profile is explicitly pending replacement by 01's curve interface. It is not accepted curve data, not same-column compatible, and not proof of Safety. No speculative fields were added to the formal schema. 01 observed HEAD c60912b still exposes the old path_points2 contract in this phase.

## Strict evidence

| Run | Actual result |
|---|---|
| yellow_production_red_01 | 15 checks, 8 design failures before implementation: target/exit/reference/Anchor for A/B |
| yellow_production_green_01 | 17 checks PASS, PID 19448: actual production Baker/Geometry, exact Anchors, adjacent exit, real visible reference Cube, real Safety refusal of reference as standing support |
| yellow_map_regression_01 | 40 checks PASS, PID 21652: baseline map/Codec/Runtime rejection/Reset, candidate shape, ordinary isolated control Solver/Replay |
| yellow_exit_green_01 | FAILED: 13 checks, 2 route failures, PID 31288; directory name is intent, not a passing status |
| yellow_exit_diagnosis_01 | FAILED: 13 checks, 2 route failures, PID 49916; exact Solver and Runtime rejection recorded |

All new processes use isolated user://, source snapshots, native modules and doubles=[]. Historical evidence remains untouched. The 17/40 PASS results must not hide the failed route.

## New Owner01 handoff: real ordinary Roll refusal

From a separately authored legitimate target/TOP spawn, MOVE U_POS is REJECTED 2000, issue 1601, entity `blue_reference`: “Roll swept enclosure is not separated from an unrelated Cube.” A/B reproduce this; baseline Solver cannot reach exit. Exact record: evidence/yellow_exit_diagnosis_01/report.json. This is an observed rule rejection, not yet a claim that the algorithm is incorrect. It was sent to Owner01 for examination against its formal candidate.

Do not delete/hide/move the specifically approved reference cube, re-enable its support, teleport, skip Runtime or loosen Safety to turn this green. 01 must determine whether its conservative Roll enclosure requires a correct targeted change or whether the authorized layout needs a coordinated revision. This public rule issue is outside 09.

## Remaining outcomes

Target Yellow Face/Anchor data: implemented and validated. Wrong Blue Target standing support: rejected by actual Safety. Natural Forward Departure/Continuous Descent/Yellow contact/Landing-Rebound: NOT_RUN pending curve/host. Full Fall→Roll→Goal: BLOCKED by the observed ordinary Roll rejection as well as curve dependency. Graphical/Pixel parity/HumanQA/new Build: NOT_RUN in this owner delivery. No shared Runtime/Host/Presenter/Art/five-level/L06 changes; Push NOT_RUN.

Production source and diagnostics are reviewable now. Do not promote this to playable fix acceptance until 01 dependencies are actually resolved and real integrated tests run. Hashes: YELLOW_PRODUCTION_FILES_SHA256.json; new actual commit is provided in final receipt.
