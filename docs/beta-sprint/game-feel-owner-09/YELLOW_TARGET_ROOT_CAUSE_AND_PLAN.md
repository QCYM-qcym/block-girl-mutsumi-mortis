# PFALL_YELLOW_TARGET_LANDING_FIX_REPORT — 09 phase 1 / design RED

Not PFALL_YELLOW_PLATFORM_LANDING_PASS. This commit contains diagnosis, proposed author coordinates and an intentionally failing design regression; active A/B and v1 bake behavior are unchanged pending the coordinated curve contract.

## Root cause verified

09 worktree starts clean at `e4bcdfc6459f587cb26c25494dd5b57b76ccdca4`. Integration source inspected at exact `264b0c4615c4080457c829a824ac2948e8bb7158`.

`experiments/game_feel_01/host/core_lab.gd` builds each platform from resolved cube geometry; lines around 149 color **exit** yellow. The actual player Mesh is independently parented below `AuthoritativeCubePose` (around lines 29–35). Author maps bind Fall to **target/TOP**, whose platform is blue under that host rule. Thus the current landing is consistent with the old author target but inconsistent with the user's newly specified yellow-position target. This establishes category A (author target binding versus requested platform). It does not establish a Runtime misresolution, wrong final Presenter anchor or a player/platform identity bug. No actor Mesh should be removed as part of this map correction.

Source/TOP is center2=[0,4,0], anchor2=[0,5,0], actor-center2=[0,6,0]. Current target center2=[-8,0,8] / [-8,8,8], anchors [-8,1,8] / [-8,9,8]. Current yellow exit center2=[-6,0,8] / [-6,8,8]. EAST=1, explicit Fall `connection_id=pfall_a/pfall_b`, source_edge=U_NEG(2), orientation PRESERVE.

Transition ID, actual Runtime final StateKey and Presenter final Visual Pose for the new correction: NOT_RUN. Previous Core receipts do not prove this correction; 00 will capture new native/graphical events. This owner-local phase does not make up dynamic identifiers or substitute static Baker evidence for them.

## Proposed minimal real geometry

| Entity | MAP A center2 | MAP B center2 | Role |
|---|---|---|---|
| source | [0,4,0] | [0,4,0] | unchanged visible departure platform |
| target | [-6,0,8] | [-6,8,8] | actual former yellow location, legal TOP landing |
| blue_reference | [-8,0,8] | [-8,8,8] | original blue platform retained, all faces nonwalkable |
| exit | [-4,0,8] | [-4,8,8] | new visible platform, TOP walkable, Goal |

New target Anchor2: A [-6,1,8], B [-6,9,8]. Actor-center endpoint2: A [-6,2,8], B [-6,10,8]. New exit Anchor2 = target Anchor2 + 2*TOP.frame.u. This retains Fall→target/TOP→MOVE U_POS(0)→exit/TOP Goal, Surface-only source/target, A real delta -2 and B +2. All four cubes are real author geometry that the host must render; no hidden support. 00 must color the new target's Mesh as the yellow landing identity and visibly distinguish exit; simply recoloring old target is insufficient.

## Why curve interface coordination is necessary

Old EAST profile constrains every point to the same screen column. In 01's currently observed EAST basis, horizontal numerator is x+z: source=0, new target=2. Therefore substituting only the endpoint cannot satisfy that old permission profile. This is an endpoint incompatibility diagnosis, not a proposed relaxation of Safety. 01 must provide the explicit curve/profile delta; 10A must consume the same authorized path. 09 will then supply controls/path author data ending at the canonical target actor center and run formal acceptance against **all four cubes**, including reference and exit. No renderer-selected target or private curve is provided here.

## Actual evidence

`evidence/yellow_target_red_01`: PID 42332, 13 checks, exactly two expected behavioral failures: current A/B target is not the former yellow position. stderr empty, no source drift. Eleven checks succeed, including fresh real Baker/Geometry checks on test-only proposed four-cube resources, exact target Anchors, U_POS exit adjacency and nonwalkable reference faces. No full sweep, accepted Fall, natural animation or graphical claim.

The runner uses a fresh isolated profile and retains original HEAD/WIP, exact source snapshots and raw logs. Existing QA/evidence remains untouched. Proposal data: `experiments/game_feel_01/maps/yellow_target_proposal.json`. Active `map_a.json`, `map_b.json` and `map_factory.gd` are deliberately unchanged in this phase.

Next required input: delivered 01 curve authoring/permission schema and shared 00/10A path convention. After that, 09 activates the minimal four-cube data and provides real acceptance/regression. Shared Host/Presenter/animation, old five levels/L06, Runtime and Art are outside this change. Push NOT_RUN.
