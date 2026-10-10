# PFALL_TARGET_PLATFORM_AND_TRAJECTORY_FIX_01 — timing delivery

Baseline 4781dfcf16757ccbde13e54ee449f1cf00174944. Changes remain exclusively within Owner10A paths. Public shared integration remains 00's responsibility. Push NOT_RUN.

Delivered: C1 monotone temporal easing at departure/main Fall and custom timing-table knots; no default or Reduced Motion interior stall; existing exact source/target, cancelled neutral samples and 24 orientation recovery retained. `begin().phase_schedule` supplies existing phase timestamps for six-frame/continuous captures. Reduced Motion retains the impact phase label while suppressing deformation. Duration floor 1ms matches 01's documented authoring resolution. Default settings are experiments, not art approval.

Measured default 300ms join speeds in the collinear six-unit DTO fixture: before 20.013916 / after 20.000669 units/sec. Previous default before 20.000669 / after .092723. Reduced Motion current before 17.009842 / after 16.999247. Boundary finite differences use 30 microseconds; remaining small differences include finite-step acceleration and Vector3 precision.

Evidence, all `authoritative_runtime=false`:

- `evidence/trajectory_timing_red_01`: 2023 checks / 6 failures, actual timing defect.
- `evidence/trajectory_markers_red_01`: 4025 / 2, missing Reduced Motion impact/capture metadata.
- `evidence/trajectory_duration_red_02`: 4430 / 2, sub-ms acceptance and its downstream uncleared active-state failure.
- `evidence/trajectory_timing_delivery_unit_01`: 4430 / 0, PASS, source/copy drift empty, isolated profile.
- `evidence/trajectory_timing_delivery_preview_01`: 251 / 0, PASS, real Godot graphical private playback and sixteen A/B PNGs; input/SAFE/commit are explicit doubles.

Preserved harness observations: `trajectory_timing_acceptance_01` incorrectly required movement at the exact departure entry, despite that being the stationary source instant (2 failures). Assertion corrected to compare samples within the same moving phase. `trajectory_duration_red_01` is PASS because the ultra-small literal became zero and was already rejected; the actual reproducible duration RED uses 1e-9 in red_02. Neither is represented as production failure evidence.

Read-only independent review found no Critical/Important issues; its duration robustness note was addressed. No official cube Presenter, Runtime, event bus, nodes, tween, Camera, meshes, maps or project config edited. Landing remains COMMITTED-only, null position, exact neutral completion after 340ms; actual bottom-support compensation remains 00's single-writer responsibility.

Pending: delivered 01 curved-profile contract/SAFE proof, consumption of its exact author controls, 09 yellow-target map delivery, 00 natural Presenter and transformed-bottom contact evidence. **YELLOW_PLATFORM_LANDING_PASS is not claimed.** Polyline Safety does not authorize geometric Hermite/Bezier smoothing. This commit can be integrated for timing and phase markers independently while the real curve delivery proceeds.
