# Fresh baseline diagnosis

Exact baseline 44f3d3db190b616f4121516576337ed8d40f6ae4. Natural graphical baseline_red02: 56 checks, six expected behavior failures (three on each map), exit1, stderr0, doubles=[], source drift0. Native Runtime drives actual Presenter throughout.

The existing 600ms action reserves 90ms of stationary ANTICIPATION, then 90ms departure. The lean peaks while stationary and recedes through departure. Consequently the first 5% of action time has zero advance. Descent starts at 180ms; both equal-duration early and late descent intervals advance the geometry parameter by ~0.15. A default two-knot table and matching Hermite join yield uniform path travel. This proves the user-reported missing immediate forward progression and lacks the requested falling acceleration. Historical continuous-curve evidence is valid for geometry/contact but cannot establish this cadence.

Actual geometry: source actor (0,3,0), native U_NEG2 forward -X, source support edge x=-.5. COM reaches that boundary at geometry u=.125; strict leave occurs beyond it. The body fully clears at u=.25, departure point (-1,3,0). Both actual targets are original yellow target/TOP, doubled support anchors A(-6,1,8), B(-6,9,8); blue_reference is nonwalkable and not a connection target. No Runtime/Map production correction indicated.

Harness correction: baseline_red01 additionally failed geometry inversion at the cubic's flat-forward endpoint; the harness now recognizes the exact endpoint before float32 inversion. baseline_red02 retains only the six intended behavior failures. Neither run was overwritten. Pure sampler probes only observe an already accepted real motion and cannot commit/complete a Runtime transition.
