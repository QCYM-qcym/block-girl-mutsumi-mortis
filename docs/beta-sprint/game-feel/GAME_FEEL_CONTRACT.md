# GAME_FEEL_CONTRACT — game_feel.event.v1

2026-10-09 · 00 Integration Coordinator · BETA_GAME_FEEL_PARALLEL_BOOTSTRAP_01

Reference baseline: `d472885d7375ef73fd36e4abc1847a9ba36cac44`.
Scope: independent game-feel laboratory; existing L01–L05 and their accepted QA evidence remain unchanged. L06 continues in its own Content worktree.
Status: shared implementation contract, **not a delivered Fall capability**. Bootstrap authorizes concurrent Owner-local development; real dependent cases remain pending until their actual deliveries exist.

## 1. Verified current system

Five-level Shell uses `adapter:p01` and `prototype/perspective/grid_movement.gd`, through `game/levels/mutsumi/batch_01/content_level.gd`. It does not use Foundation RuntimeSession. P01 has no Fall action or typed blocked-move event; its neighbor failures fold into the current cell. Mesh/camera/phase observations cannot recover an authoritative edge reason.

The independent formal Foundation path is `foundation/runtime/runtime_session.gd` → `kernel_port.gd` → `foundation/rules/puzzle_rule_kernel.gd` → formal Connectivity/Safety. Existing signals are `transition_started(result, transaction_id, generation, is_global)`, `committed(state)` and `feedback(result)`. `RuleRecords` result has exactly `status, previous_state, next_state, action, changed, rejection_code, issues, global_kind`. Existing status values are APPLIED=0, REJECTED=1, ERROR=2. No Fall action, authoritative Camera field or Fall trajectory currently exists.

The lab uses this formal pipeline, with the versioned extension delivered by 01. No new P01 movement algorithm is permitted. Existing v1 shapes reject additional fields, so this envelope is a **separate versioned presentation port**, not an unregistered field inserted into TransitionResult. 01 owns any required action/state/codec extension and preserves old versions; 00 does not allocate a new numeric ActionKind/GlobalKind.

## 2. Authority and classification

Only 01 produces authoritative event classifications, accepted target states, path permission and completion identity. 09 supplies author data, never permission. 10A/10B/05/11/07 only consume the event. They never grant movement, alter support/face/world, set Runtime state, decide Goal or write orientation.

Required semantic outcomes below keep the suggested names. They wrap the real result and lifecycle rather than replacing native status/code/issues:

| semantic | phase | authoritative requirement | presentation |
| --- | --- | --- | --- |
| MOVE_APPLIED_NORMAL | STARTED / COMMITTED | APPLIED + changed, explicitly ordinary MOVE | inherited ordinary roll; one commit/landing cue |
| PERSPECTIVE_FALL_APPLIED | STARTED / COMMITTED | explicitly authorized Fall extension, proven complete motion and target | 10A FallMotion, then committed LandingMotion |
| MOVE_REJECTED_EDGE | REJECTED | REJECTED, unchanged state, explicit reason_category=EDGE | 10B EdgeLean/Recoil; no movement/commit |
| ANIMATION_INTERRUPTED | INTERRUPTED | Reset/load/unload/quit/cancel invalidates the captured active identity | stop scoped motion/VFX/SFX; settle to current authoritative state |
| ACTION_FEEDBACK | FEEDBACK | original non-edge result, including ERROR, with explicit reason category | neutral/class-specific UI/audio; no accepted motion, landing or Runtime completion |

Non-edge results remain observable as `ACTION_FEEDBACK` and retain native status/code/issues. Required `reason_category` values are `NONE`, `EDGE`, `MECHANISM_LOCKED`, `BUSY`, `INVALID_FACE`, `SAFETY_REJECTED`, `INVALID_ACTION`, `CAMERA_NOT_ALLOWED`, `WORLD_NOT_ALLOWED`, `FALL_NOT_AVAILABLE`, `UNCLASSIFIED_REJECTION` and `ERROR`. 01 may add a documented subtype; it may not collapse these classes into EDGE.

**MOVE_BLOCKED=2000 alone is not EDGE.** Current Safety can use this same code with issues; invalid source Face can be ERROR; P01 closed gate also looks like a missing neighbor. Missing classification defaults to UNCLASSIFIED_REJECTION and gives neutral feedback, not tilt/fall. BUSY may be rejected before a transition is created. Invalid input mapping must not be presented as physical edge refusal. Wrong Fall camera/world/target/path is not a normal edge result.

## 3. Event DTO and the 01 port

01 exposes a versioned `game_feel_event(event: Dictionary)` signal on its lab Runtime facade. Existing native start/commit/feedback stay available. This signal is required new delivery, **not an existing API**. Host binds only this explicit port; no inference from adjacent `committed`/`feedback` callbacks is accepted as a formal completion implementation.

Every event is an immutable deep snapshot with these fields:

| field | type / meaning |
| --- | --- |
| schema_version | int 1 |
| contract_version | string `game_feel.event.v1` |
| semantic, phase | strings from section 2 |
| event_id | unique monotonic identity within a level run; duplicate delivery is ignored |
| session_id, level_run_id | opaque strings allocated on binding/load; not reused on a new session |
| attempt_id | monotonic input-attempt identity, including rejected attempts |
| presentation_identity | `{session_id, level_run_id, generation:int, attempt_id:int}` for accepted motion or Edge decoration; captured before callbacks and shared by motion/audio/VFX; null when no presentation starts |
| transition_identity | `{session_id, level_run_id, generation:int, transaction_id:int, is_global:bool}` for accepted motion; null for a refusal without a Runtime transition |
| result | original native TransitionResult deep copy, or explicit versioned extension result; preserve status/code/issues and actual previous/next state |
| reason_category | authoritative string above; not derived by Presenter |
| source_pose | copied native player record `{location:{layer:int,cube_id:StringName,face:int},orientation:int}` |
| target_pose | same type from authorized next_state.player; null for rejection/interruption without a target |
| source_face, target_face | copied native location dictionaries identifying actual support faces; target null when not authorized |
| world_id | actual `WorldLayer` value 0 Surface / 1 Inner; agrees with source location |
| camera_quadrant | int 0 NORTH / 1 EAST / 2 SOUTH / 3 WEST, captured authoritative discrete lab state |
| authoritative_final_orientation | valid `cube24.v1` ID 0..23 from target_pose.orientation; null without accepted target |
| intended_move_direction | native FaceAxis 0..3 when a MOVE intent resolved; null for no valid mapped MOVE |
| interruption_reason | null unless INTERRUPTED; RESET / RELOAD / UNLOAD / QUIT / CANCEL |

`source_pose` is the real existing Dictionary record, not a guessed PlayerPose class or a Mesh Transform. `source_face`/`target_face` refer to support faces, not the Wakaba painted face. World ID is a layer value, not a character/skin selector. `cube24.v1` is the existing integer orientation ABI in `foundation/orientation/discrete_orientation.gd`.

Camera is presently absent from formal state/key. For Fall, 01 must deliver a versioned authoritative camera/action/state/key contract used by Kernel, Safety, Solver and Replay. A camera angle supplied only by a renderer does not authorize Fall. Old `foundation.contract.v1`, `statekey.v1` and old levels remain unchanged unless 01 supplies a backward-compatible explicit version dispatch. No private kind8 alias or ad-hoc unknown fields in old Codec/TransitionResult.

Fall STARTED additionally includes:

- `connection_id`: actual validated author connection identifier;
- `authorized_path_points2`: ordered canonical logical **actor-center** positions, Array[Vector3i], half-unit coordinates consistent with formal geometry;
- `motion_profile_id` and `motion_profile_hash`: identity of the entire Safety-proven path/profile;
- `safety_verdict`: explicit SAFE with no unresolved issues; actual evidence reference supplied by 01;
- `orientation_policy`: initially PRESERVE; source/target/final IDs agree. Other policies require an explicit contract revision, not animation invention;
- `presentation_duration_seconds`: positive bounded presentation timing, separate from Rule truth;
- `source_frame`: actual source anchor/frame snapshot needed to map FaceAxis to visual directions.

Path/position conversion is specified once by 01 with its geometry/version delivery. Pure timing/easing can be adjusted by 10A only within the authorized path. No curve may cut through unproven space; overshoot/shake is decorative and cannot move the authoritative body outside that path. If a path representation must change after actual Safety implementation, 01 submits an explicit field/version delta to 00; unaffected Owner-local work continues.

Edge REJECTED needs current `source_pose`, `source_face`, `source_frame`, mapped `intended_move_direction`, `attempt_id`, `presentation_identity`, `reason_category=EDGE`, native REJECTED result and unchanged before state. Its generation is the current Runtime generation at refusal. It has no target, authorized Fall path, Runtime completion token or final-orientation mutation. Motion/audio/VFX sample and cancel APIs use presentation_identity; only 00's native finish bridge uses transition_identity. Interruption names the captured old presentation_identity even after the current run/generation has advanced.

## 4. Timing, completion and interruption

Acceptance is a proposal, not a commit. Existing Runtime can publish APPLIED feedback both at acceptance and at completion; never play landing or count success from feedback alone. Existing committed also fires on reset/load, so it is not by itself a landing event.

Capture id/generation/is_global from the start signal at acceptance. Public `session.transaction_id` may still name a global transaction during local movement; it cannot replace the captured local token. 01 emits COMMITTED exactly once for that token after its native commit, including complete next state and final orientation. No animation may call a finish API for Edge Recoil.

00 owns the natural-motion completion bridge. Fall sample completion requests the real native finish_local/finish_global with the captured token exactly once. The Runtime validates identity and commits; only its matching COMMITTED event starts landing feedback/audio. A renderer does not set `session.state`, call kernel completion itself or manually finish an unexecuted motion to obtain PASS. Solver uses formal instant evaluation separately and must be labelled as Solver evidence.

First Fall version locks new MOVE, Shift, Camera and other conflicting actions while in flight: explicit BUSY. Reset/cancel/exit remain available. Existing global/local concurrency rules stay unchanged outside this opt-in Fall. Authoritative camera cannot change mid-flight; render interpolation cannot open a connection.

Reset/reload advances Runtime generation and clears pending authority. Unload/quit/cancel also invalidate the accepted token through the 01 lifecycle port. 00 invalidates presentation identity before deferred node cleanup; both animation modules kill/clear their own handles synchronously and return neutral samples. Late sample, tween, completion, audio and VFX callbacks compare full captured identity. An old cancellation/completion cannot clear a newly started effect. Completion observer reentrancy may start/reset another transaction during a synchronous signal; all cleanup is identity-scoped.

Pause suspends elapsed motion/audio without landing or cancellation. Resume continues the same token. Focus loss clears held input and ends camera dragging; it does not manufacture EDGE or Fall. An explicitly interrupted effect does not emit landing/Goal/Save or leave a loop playing.

## 5. Independent animation APIs and one writer

00 owns `game/feel/cube_presenter.gd` and `experiments/game_feel_01/host/**`. It owns the actual character/pivot writes and event routing. Existing Alpha Presenter writes its full PhysicalCubePose transform every sync, so another tween cannot safely write that node. Bootstrap does not modify the accepted presenter chain.

10A owns `game/feel/animation/fall_landing/fall_motion.gd` and `landing_motion.gd`. 10B owns `game/feel/animation/edge_recoil/edge_lean.gd` and `recoil_motion.gd`. They are independently testable sampling modules:

```text
begin(event: Dictionary) -> Dictionary {ok:bool, issues:Array}
sample(elapsed_seconds: float) -> Dictionary
cancel(identity: Dictionary) -> void
clear() -> void
```

The module validates the event kind/version. A sample includes `active:bool`, `identity:Dictionary|null` (the captured presentation_identity), `phase:String`, `progress:float`, `motion_done:bool`, `position:Vector3|null`, `rotation_offset:Quaternion`, `scale_multiplier:Vector3`. cancel(identity) matches this same presentation_identity; it never treats a rejected attempt as a Runtime transaction. An inactive cleared sample may have null identity. Fall position is sampled solely from authorized path (points2 × 0.5), and exact at its end; decorative Landing/Edge returns null position. Neutral samples use identity rotation and scale ONE. No module owns the player Node, Camera, Runtime or shared pivot. Private demo pivots are allowed only in that Owner's standalone scene.

00 combines authoritative base pose, authorized Fall position, then Fall/Landing and Edge decorative offsets in a fixed declared order, writing the final visual transform once. Accepted motion preempts an outstanding rejection decoration. Landing and Edge do not simultaneously steer the same accepted body. Decorative scaling/lean ends neutral and never changes the formal cube24 endpoint. This sampling seam avoids two Owners inserting competing nested pivots into frozen characters.

## 6. Map, Art, Audio and UI consumption

09 owns only `experiments/game_feel_01/maps/**`: A real lower target; B real higher target with legal screen descent. Keep author metadata outside old strict baked records until 01 delivers the versioned config validator/codec. Both maps need active player input, one allowed quadrant, other three rejected, same-world source/target, invalid landing/path negatives, deterministic orientation, Reset/Goal, formal Solver/Replay witness and actual continuous character descent. No static line/ghost/target screenshot constitutes Fall playback.

Do not merge the entire previous `prototype/perspective-fall-01` branch: it contains a separate L03 hint change. Only reference/copy its isolated A/B author data and audit fixtures. The old Fall prototype correctly reports Runtime extension required; it remains historical NOT_APPLIED evidence.

05 continues external Art production in a new experimental release (`game_feel_01` namespace), separate from approved batch_05 and _runtime_polish/_01. New platform/edge/landing/VFX assets declare origin, footprint, clearance, Surface/Inner pairing, cues, bounds and SHA in a new handoff. They do not supply traversal permission or collision algorithms. Integration target is only `production/experimental/game_feel_01/art_vfx/**`, copied by 00 after handoff review. Approved Wakaba/Surface/Inner/UI masters stay frozen. Stair clearance/traversal stay PARTIAL_PASS/NOT_RUN.

11 owns `game/feel/audio/**` and `production/experimental/game_feel_01/audio/**`: original music/SFX, licensing/provenance, manifest and `AudioDirector`. It exposes `consume_event(event)`, `play_ui(cue, cue_identity)`, `apply_settings(values)`, `set_paused(bool)`, `cancel(identity)` and `clear()`. Fall STARTED may start scoped falling sound; matching COMMITTED plays one landing; EDGE plays at most one rejection cue with held-input throttling; BUSY/invalid/safety never reuse edge audio. Cancel stops matching loops and does not play landing. Duplicate event IDs/committed feedback/UI-complete sources are deduplicated.

Current bus mapping is Master/SFX/Ambience; `music` controls Ambience. Consume unchanged `master, music, sfx, fullscreen, muted` settings keys; audio ignores fullscreen. No Save schema expansion, default_bus_layout edit, new Autoload or global InputMap. Local fixture buses must be explicitly scoped and cleaned. Any production Music bus or shared signal wiring goes to 00 as INTEGRATION_REQUEST. Missing audio remains silent with diagnostics and does not block gameplay.

07 owns `game/feel/ui/**` and optional `production/experimental/game_feel_01/ui/**`. Reuse read-only approved `game/shell/visual_01/tokens.gd` and existing control style. New lab HUD shows real reason/status/locked input and emits `settings_preview(values)`, `settings_apply(values)`, `settings_cancel()` using existing keys. 00 routes to 11/settings lifecycle. Reduced Motion/Hint Strength may be separate experimental presentation configuration and notification, never silently added to the legacy Save/settings schema. Do not touch approved Shell view, HUD, Save/Load, level catalog or Main; no UI art redesign. Owner-local sinks can verify values/focus/cancel while Audio is pending.

00 later owns all shared wiring, including old polish/audio deduplication and any explicit approved shared-file change. No Owner simultaneously changes project.godot, InputMap, Autoload, Main Scene, bus layout, shared Presenter, Shell or contract. Actual existing shared-file sites are listed in AUDIT.md and OWNER_MATRIX.json.

## 7. Owner-local and formal Quality

03 owns only `tests/beta_sprint/game_feel/**` and its own docs. Other Owners use disjoint `tests/beta_sprint/game_feel_owner_<id>/**` roots. Owners submit their script/case/source/evidence references; only 03 registers shared matrix/manifest. 00 bootstrap metadata checks do not claim any new gameplay PASS.

Synthetic immutable cue/path fixtures are allowed for animation/UI/audio Unit tests and must declare `fixture_kind=PRESENTATION_CONTRACT_UNIT`, `authoritative_runtime=false`, and all doubles. They do not imply a legal Fall. Local behavioral RED/GREEN proceeds without the formal shared Harness. Parser/import/config/dependency failures are retained separately and are not behavioral RED.

Real/Graphical cases use actual default Runtime/Kernel/Safety/Solver/Replay, real motion and native input, doubles=[]. No rules copied into test or renderer, no direct authoritative state assignment, no hand-written winning edges. Fault injection has separate expected-failure case/evidence; it is not counted as natural success. Existing strict Foundation Harness gates remain intact; new game-feel registration does not make arbitrary checkouts pass old receipts.

Required matrix: ordinary move; explicit EDGE; mechanism lock; Busy; invalid Face; Safety rejection/unproven; legal Fall A/B; other three quadrants; wrong world/target/path obstruction; 24-state endpoint; six visible faces; natural roll/Fall/Landing/Recoil; held-input throttling; Reset during each effect; exit/cancel/late callback/new launch; exactly one commit; exact state/key parity; Solver and Replay; audio mute/settings/apply/cancel/pause; UI focus and necessary viewport coverage.

Only the case needing an undelivered dependency is `case_pending` with zero checks and no fictional SHA; other Unit/Real work continues. Future integration stages and ordinary P2/P3 do not block current stages. Genuine contract conflict, gameplay/data corruption risk pauses only the affected line.

Every run records actual execution HEAD/dirty state/source SHA, engine/PID/display/renderer/input/profile, raw stdout/stderr, checks/failures/doubles, authority and source drift. Keep original WIP identity; separately bind final delivery SHA to actual unchanged sources. Evidence directories are fresh and append-only. Isolate process environment/profile and record OS.get_user_data_dir; never touch old saves/QA packages.

## 8. Integration and Human QA

All code Owners start from the commit containing this contract, registered by 00 after commit. Existing experimental/Art lines remain intact; clean new branches are prepared instead of resetting/rebasing/squashing old worktrees. Normal Owner history merges are batched by 00, at most two integration windows per day. Main Integration remains runnable.

Integration order: formal Runtime extension → new maps → Fall/Landing/Edge modules → approved new Art/VFX → Audio/UI → registered Quality cases → independent lab Build. This is merge order, not a sequential development dependency. Owners may implement and validate their local seams immediately.

08 receives the actual immutable integrated Build/source/ZIP/profile and precise QA scope **after** delivery. Until then Human QA is NOT_RUN/WAITING_FOR_INTEGRATED_BUILD. Current five-level Alpha evidence stays accepted at its exact original package identity. New player's first-time comprehension cannot be replaced by repeated testing. No broader Beta completion claim, existing P2/P3 repair, universal authoring tool or L06 dependency is added to this bootstrap.
