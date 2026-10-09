# EDGE_LEAN_RECOIL_01 — integration request to 00

10B delivery is independent sampling code. No shared Presenter/Host/Runtime/InputMap/Shell/Art file was edited. Consumes `game_feel.event.v1` from contract commit `2938d6e534f5b596bb320ce79d72b69f5923f3cd`.

## Module and sampling

Load `res://game/feel/animation/edge_recoil/edge_lean.gd`. Its internal `recoil_motion.gd` is also independently testable. `edge_event.gd` validates only the presentation boundary and source frame; `edge_admission.gd` guards both public samplers.

Public contract methods: `begin(event: Dictionary) -> {ok: bool, issues: Array}`, `sample(elapsed_seconds: float) -> Dictionary`, `cancel(presentation_identity: Dictionary)`, `clear()`.

Additional 10B methods/signals required for host wiring:

```gdscript
signal cue(name: String, identity: Dictionary)
set_intent(mapped_direction: Variant) -> void # FaceAxis int 0..3, or null on release/focus loss
support_pivot_offset(half_extent: float = 0.5) -> Vector3
```

Sample retains the shared shape: `position=null`, scale ONE, source-world `rotation_offset`, full copied presentation identity. `motion_done=true` means only decorative completion. It must NEVER call `finish_local`, `finish_global`, change PuzzleState, or generate a Gameplay Transition.

Timing is absolute since accepted decoration start: 0–0.130s smooth lean, 0.130–0.175s blocked, 0.175–0.440s cubic ease-out return. Peak 12 degrees, no reverse overshoot into the support plane. At/end/after 0.440s quaternion is exactly IDENTITY. Cancel/clear neutralize synchronously. Pause is host-owned: stop advancing elapsed, keep the same identity, resume from the same elapsed; no cancellation/landing cue.

## Required one-writer pivot formula

`source_frame.{u,v,normal}` are the formal signed-axis frame. Native FaceAxis chooses `[u, v, -u, -v]`. Do not remap a W key again or rotate by camera a second time. Axis is `normal.cross(mapped_tangent)`.

For a centered unit actor, pivot relative to authoritative actor center is `(mapped_tangent - normal) * 0.5`. This is the bottom front support edge. The **null sample position is not a center-pivot instruction**. 00 must apply both rotation AND its decorative origin compensation:

```gdscript
var s: Dictionary = edge.sample(elapsed)
# Guard against scoped callbacks/new identity before applying any sample.
var r := Basis(s.rotation_offset)
var p: Vector3 = edge.support_pivot_offset(0.5)
var visual := Transform3D(r * authoritative_base.basis,
    authoritative_base.origin + p - r * p)
# 00 writes the actual character transform once, together with accepted motion.
```

All vectors above are in source logical-world coordinates. If the lab has an additional visual basis V, convert `p` by V and R by `V * R * V.inverse()` before composition. Layer translation does not change p. Do not right-multiply R by the cube basis: source direction is already world-resolved, including arbitrary support normal and cube24 orientation.

The approved Wakaba/Mortis manifests have bottom origin `(0,0,0)` and logical cube center `(0,0.5,0)`, size ONE. Normalize the model child to local `(0,-0.5,0)` under a centered authoritative actor ONCE. Do not rotate the model's unnormalized bottom origin and then apply a second half-height offset. Host may supply a different positive finite half_extent only if its actual model/visual scale is normalized consistently. No mesh-derived rule geometry is introduced.

## Admission, intent, priority and lifecycle wiring

- Bind only the explicit 01 facade port. `MOVE_REJECTED_EDGE`, phase REJECTED, category EDGE, unchanged native REJECTED MOVE, mapped native integer FaceAxis and valid source frame are required. Code 2000 or `neighbor==cell` alone cannot start this module.
- Missing/wrong classification, BUSY/Paused/mechanism/invalid Face/Safety/Shift/wrong camera/world feedback never starts/replaces decoration. Diagnostics are returned; do not promote them to EDGE.
- `event_id` and `attempt_id` must be monotonic ints within the level run. Both samplers reject repeated/older delivery and generation regressions. Clear preserves watermarks and retired known runs. 00 must still reject any event whose session/run/generation is not currently bound, including an unseen late run.
- Route mapped intent changes to `set_intent()` immediately, even when the new attempt succeeds or is rejected for a different reason. Direction change cancels the old decoration before the next render. On release/focus loss pass null. This rearms future attempts; release alone allows the current cycle to finish. A rapid same-direction repress during an active identical cycle preserves progress and cannot restart it.
- Identical held input/current pose/frame/camera/generation produces one cycle and remains latched after completion. Moving to a different authoritative pose or mapped direction naturally gives a new intent. Do not call clear every frame; clear is for Reset/reload/world/camera/unload/quit lifecycle.
- Before ordinary MOVE or Fall STARTED, cancel the captured edge identity synchronously and give the complete visual pose to the accepted motion writer. The edge never participates in Runtime Busy/locks. It cannot prevent Roll/Fall, Shift or Camera acceptance.
- Reset/reload, accepted world/camera change and scene exit call clear, rebuild from the CURRENT authoritative pose, and discard the old host elapsed/identity. ANIMATION_INTERRUPTED cancels the named captured presentation_identity; old cancellation cannot clear a new effect. Accepted motion takes priority over edge/landing composition.
- Capture identity before callbacks. Cue listeners may synchronously Reset, cancel or start another effect. After begin/sample/cue callbacks check that the host identity still matches the captured request before updating elapsed, writing a transform or cleanup. Never invoke an old elapsed sample on a newly bound effect.

## Audio/VFX hooks

Connect `cue(name, identity)` and forward the exact scope to the eventual 11/05 adapters. Names are `EdgeLeanStart`, `EdgeBlocked`, `EdgeRecoilEnd`. They fire once each on a natural cycle, in order. Normal cancellation does not manufacture `EdgeRecoilEnd` or landing. No audio paths, audio nodes, VFX resources or shared buses are embedded. If host frame timing skips across boundaries, the logically crossed hooks still emit once; paused sampling does not cross boundaries.

## Still pending, zero checks

01 authoritative EDGE facade delivery; native ordinary Roll/Fall STARTED preemption; 00 actual sole-writer pivot assembly/world/camera/unload integration; formal Quality registration and Human QA. Owner-local rendered Unit uses native input mapping and approved visual assets but synthetic immutable classifications, and does not authorize gameplay.
