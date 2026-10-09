# Owner09 opt-in authoring candidate — formal acceptance pending

Based on read-only observation of 01 WIP; exact observed file hashes in OPT_IN_WIP_OBSERVATION.json. Runtime HEAD remained bootstrap `2938d6e`, with no delivered extension SHA. This is a preparatory map candidate, not formal compatibility/Safety/Fall acceptance.

`map_factory.opt_in_authoring_candidate(spec)` returns explicit v2 authoring with the observed schema tags, camera_initial_quadrant and perspective_falls fields. It converts JSON numeric arrays to native Vector3i/int and ID fields to StringName. Default `authoring`/`bake` still emit baseline v1 and never activate this proposal. No foreign Runtime code is copied or executed, no runtime enum is added, no shared contract/host/Presenter is changed.

Host interface: `map_factory.bake_game_feel(data) -> {ok, level, issues, ...}` returns the actual Baker result without replacing its validation or errors. Currently baseline Baker rejects v2, which is expected and tested. After 01's delivered version dispatch is merged, reclassify this capability test and validate successful resources using the actual complete-motion Safety/Runtime pipeline. A successful bake by itself must never be interpreted as path authorization. This entry uses our three-cube geometry, never 01's test fixture as a substitute map.

| Map | canonical actor-center path_points2 |
|---|---|
| A | [0,6,0] → [-2,6,2] → [-6,6,6] → [-8,2,8] |
| B | [0,6,0] → [-2,6,2] → [-6,10,6] → [-8,10,8] |

Paths follow the authored example currently present in 01's fixtures, adapted to our source IDs. Source edge U_NEG (2), target target/TOP, Surface, allowed Camera EAST (1), allowed world orientation [0], PRESERVE, no required flags. Proposed duration 600ms is author presentation metadata, not a permission criterion. Goal remains exit/TOP at [-6,0,8] / [-6,8,8]. Real target heights remain -2/+2.

The first segment stays on the source support plane and extends beyond its U_NEG edge. The rest is a proposed piecewise translation. We do not duplicate 01's projection/Safety algorithms in a map validator. All three support cubes, including exit, must be checked by the actual complete sweep. Neither the WIP example nor these coordinate endpoints proves full motion SAFE.

## Required confirmation from 01 after candidate delivery

Run the actual schema validator/Baker and `Safety.validate_perspective_motion` against the three-cube opt-in resources (not the older two-cube fixture). Confirm no source/target/exit blanket exemption; exact endpoint pose; EAST-only screen descent; PRESERVE; wrong camera/world/target/obstruction rejection. Then real Runtime, Solver and Replay must establish Fall→Roll→Goal. If exit intersects the path, provide the exact segment and obstacle; 09 will adjust owner-local geometry/path without widening Safety. Until a delivered SHA and actual result exist, confirmation and all eleven Fall cases remain pending.

## Local evidence

- `candidate_shape_01`: PID 31100, 38 checks PASS. Eight candidate shape/native conversion/default-isolation checks plus 30 baseline checks. These eight are author-data checks, not Runtime v2 acceptance.
- `candidate_exit_01`: PID 21228, 17 checks PASS. Baseline landing-spawn controls still solve and replay one ordinary U_POS Roll; complete baseline maps remain unreachable.
- After 00 requested the public host seam: `candidate_host_seam_01`, PID 47728, 40 checks PASS, additionally proving that the actual baseline Baker rejects both unsupported opt-in resources; `candidate_host_exit_01`, PID 10084, 17 checks PASS. These are the final source-binding runs. Earlier WIP runs remain unchanged.

Both isolated profiles record raw logs, original HEAD/WIP, source copies, hashes, actual user_data_dir and zero doubles. Old evidence is untouched. No new Graphical/HumanQA/Safety-Fall PASS. Formal dependency SHA is null, not bootstrap HEAD.

00 can retain this prepared data independently. Activate only after actual 01 delivery and compatibility verification; report exact deltas if the final schema differs. File receipt: CANDIDATE_FILES_SHA256.json. Push NOT_RUN.
