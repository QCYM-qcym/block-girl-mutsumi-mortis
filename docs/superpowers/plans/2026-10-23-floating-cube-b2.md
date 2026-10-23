# Floating Cube A2 WEST material-only revision plan

**Task:** `FLOATING_CUBE_A2_WEST_VIEW_READABILITY`. **Authority:** PREVIEW ONLY.

**Binding specification:** User's STEP B2, including the exclusive roughness/specular/microtexture/base-color allowlist and mandatory stop on insufficient WEST readability or regression. Previous A2 (`continuation-06`) changed diffuse response and coarse texture and is historical, not this task's candidate.

**Implementation:** Derive a new shader from immutable A1. Preserve the original color mixture, stripe function, diffuse model, geometry, scene, light, background and all four existing camera poses. Test only roughness0.90, specular0.15, grayscale base-value multiplier1.06, and tiny high-frequency tangent normal perturbation0.10. This is one bounded candidate; if it misses any threshold, stop rather than broaden changes.

**Blender delivery:** Actual source is a Godot procedural BoxMesh, not a Blender source model. Create a new material-library-only `.blend` with zero objects/meshes and editable material parameters, embedded source identities and authoritative Godot shader text. Blender node settings are reference authoring parameters, not numerically equivalent to Godot shading or a Blender model/render. No geometry is created/imported/rebuilt for this delivery.

**Allowlist:** New files under `tests/beta_sprint/spatial_art/a2_west_b2/` and `docs/beta-sprint/spatial-formal-chapter-01/floating_cube/option_a2_west_view/`, plus this plan. New external run only under `E:/godot/beta-sprint-builds/QA/floating_cube_b2/`. Existing sources, assets, schemas, scores, preview evidence and Build/profile files are read-only.

1. Verify actual branch, source SHA and old evidence; retain a protected hash manifest.
2. Render CURRENT/A1/new A2 in the copied formal Surface scene, at its four natural camera poses. No new labels, UI, geometry or material/camera conditionals. Record all native frames and invariants.
3. Visually assess all12 raw PNGs against the 3/5 and no-regression thresholds. Preserve V1–V6 weights and null V5/full total. Retain historical CURRENT/A1/B and old A2 with original identities.
4. Produce/reopen the isolated Blender material library, actual parameter JSON, source identity, exact shader diff, render-condition list, four-view overview, SHA manifest and the existing-named scoring artifacts. Schema reuses the previous scoring definitions rather than replacing the rubric.
5. Verify byte preservation, source/material boundaries, images and schema; commit actual results, normal-push the authorized development branch and verify remote SHA. No formal asset integration or formal Build.

**Stage decision:** `A2_PREVIEW_READY` requires every real A2 view >=3 and no view below same-run A1. Otherwise `A2_MATERIAL_ONLY_LIMIT_REACHED`. Missing views are NOT_ASSESSED, never guessed. Art approval NOT_GRANTED; GAME_INTEGRATION NOT_RUN; formal Build NOT_CREATED.
