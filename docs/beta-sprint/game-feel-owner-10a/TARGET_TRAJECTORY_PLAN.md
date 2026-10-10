# PFALL_TARGET_PLATFORM_AND_TRAJECTORY_FIX_01 — 10A interface plan

Baseline: 4781dfcf16757ccbde13e54ee449f1cf00174944. Owner-local changes only; shared Presenter and target platform remain 00/09 responsibilities.

Observed 01 baseline c60912b still authorizes only `authorized_path_points2` polylines with `motion_profile_id`, `motion_profile_hash`, `safety_verdict`, `source_frame` and `presentation_duration_seconds`. No Bezier controls or curve kind are authorized yet. Do not round those corners or introduce intermediate points outside that Safety proof. The arc sampler will consume the delivered explicit kind/version and exact controls, bound to structured SAFE evidence, after 01 delivers its contract delta.

Timing defect: at a 300ms Runtime duration the experimental weights .12/.12/.56 become anticipation 45ms, departure 45ms, fall 210ms. Departure ends at path fraction .15 with speed 3.333 path lengths/sec; the previous quadratic main easing restarts at approximately .0158 path lengths/sec. This is an abrupt slowdown at FallMoving. First add finite-difference velocity checks for ordinary and Reduced Motion, then replace the restart with monotone C1 timing on the same authorized geometry. Default tuning remains experimental.

Unchanged public sampler APIs: `begin(event)`, `sample(elapsed_seconds)`, `cancel(presentation_identity)`, `clear()`. Runtime provides immutable endpoints/profile/duration; the host supplies elapsed time and keeps camera fixed. No new event bus, nodes, signals, clocks or Runtime writes.

Landing starts only from matching COMMITTED. Default impact 60ms, compression .055, rebound .025, damping 6, settle 280ms; complete at 340ms. `position` stays null. 00 must apply transformed support/bottom-point compensation through its single VisualWriter; 10A supplies deformation and exact neutral endpoint, never a guessed platform anchor. Completion remains active+motion_done until host clear/cancel. Cancellation is synchronous neutral and motion_done=false, scoped to full presentation identity. All 24 final orientation bases remain authoritative.

Owner-local tests are presentation DTO/Safety/native-commit doubles. Yellow target correctness, actual curved SAFE sweep, natural Presenter completion and graphical support contact require the new delivered 01/09/00 integration evidence; they cannot be claimed from these tests.
