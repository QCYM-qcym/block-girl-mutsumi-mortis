# A2 strict revision log

One tested material candidate derived from immutable A1. Roughness .94→.90; SPECULAR engine-default→.15; original linear ALBEDO×1.06; tangent micro-normal amplitude .10 at32 cycles/local unit. Original wide-wave function and default diffuse response preserved.

No geometry, light, camera, exposure, background, UI or Runtime change. All four views share one A2 material instance. No second material iteration after WEST failure.

Actual views: NORTH3/EAST3/SOUTH3/WEST2. Stop: A2_MATERIAL_ONLY_LIMIT_REACHED. Added micro lines do not solve dark-side nonwalkability. The previous wider-scope A2 stays historical.

Blender file is a material library only: 0 objects/meshes; not the original source model or a Blender scene/render. Actual saved parameters are in A2_MATERIAL_PARAMETERS.json and reopened receipt. Blender use_nodes emits a recorded nonfatal deprecation warning; no warning was suppressed or altered.
