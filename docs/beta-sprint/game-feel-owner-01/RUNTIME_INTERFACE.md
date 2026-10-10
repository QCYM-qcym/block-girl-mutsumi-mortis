# Owner01 Runtime core interface

Authority: shared `GAME_FEEL_CONTRACT.md` at 2938d6e534f5b596bb320ce79d72b69f5923f3cd. This Owner-local document describes the implemented extension. It does not amend the shared contract or wire other Owners' files.

## Host entry

```gdscript
const Runtime = preload("res://foundation/game_feel/runtime_facade.gd")
const Codec = preload("res://foundation/level/level_codec.gd")
var runtime = Runtime.new()
var decoded = Codec.decode(FileAccess.get_file_as_string(canonical_path))
if decoded.ok:
    var loaded = runtime.load_level(decoded.level)
    if loaded.ok:
        var scope = runtime.get_presentation_scope()
        # Invalidate previous render scope, then bind this exact read-only scope.
        # Consume game_feel_event and the existing native lifecycle signals.
```

Public methods: `load_level(Dictionary) -> {ok,issues}`, `request_action(Dictionary) -> native TransitionResult`, `request_move(Vector2) -> native TransitionResult`, `finish_transition(Dictionary) -> {ignored,transition}`, `reset()`, `interrupt(reason)` (CANCEL/UNLOAD/QUIT), `set_paused(bool)`, `get_state()`, `get_level()`, `get_generation()`, `get_commit_count()`, `get_presentation_scope()`, `get_pending_identity(token,generation,is_global)`, `is_idle()`, `is_loaded()`, `is_paused()`.

`get_state/get_level` are deep copies; there is no public writable Session/state setter. `get_presentation_scope()` returns an immutable `{session_id:String,level_run_id:String,generation:int}` from the actual bound session. Bind only after successful load. Reset/cancel/unload/quit changes generation; reload allocates a new run ID. The Host must reject even a previously unseen STARTED event from an obsolete scope. The event ID is not a substitute for scope validation.

Signals: `game_feel_event(event)`, `transition_started(result,transaction_id,generation,is_global)`, `committed(state)`, `feedback(result)`. Event snapshots are recursively read-only. Native state/result notifications are independent copies.

## Movement and completion

Native results retain their exact eight fields. MOVE kind0 first uses ordinary Kernel Roll. Only a proven empty ordinary road can resolve an explicitly authored Fall; a blocked/unsafe Roll is not bypassed. Explicit opt-in `Types.GameFeelActionKind.PERSPECTIVE_FALL=8` uses `{kind:8,connection_id:StringName}`. Fall stays one local transition and preserves the source cube24 orientation.

The accepted movement event is `PERSPECTIVE_FALL_APPLIED/STARTED` or `MOVE_APPLIED_NORMAL/STARTED`, with the actual full `transition_identity`, separate `presentation_identity`, and an authorized target. Only after actual natural motion has completed may the Host call `finish_transition(event.transition_identity)`. That method chooses native finish_local/global solely from the captured `is_global`. Native commit produces exactly one matching COMMITTED event. Rejection has no completion identity. Edge decoration cannot finish a Runtime transition.

Fall path points are absolute world **actor centers in doubled coordinates**; presentation positions are points2 * 0.5. Every linear segment has an exact integer/rational swept-unit-cube Safety proof including all same-world cubes; no source/target obstacle is exempt. The event's evidence reference binds level/profile hashes, source/target StateKeys and the actual Safety query. Timing is not gameplay truth. No visual transform may write state or invent an alternate curve.

Initial profile: TOP/upward source and target, same World, fixed four-view orthographic projection, whole path continuously descends within one screen column, first segment clears the declared source edge, PRESERVE orientation, 1..5000ms presentation duration. Actual target height is not an eligibility test. A target ENTER effect is explicitly rejected by this translation-only profile; it is never silently omitted. Existing native ordinary MOVE+ENTER semantics are unchanged.

## Camera native lifecycle clarification for 00

`Types.GameFeelActionKind.SET_CAMERA_QUADRANT=9` accepts `{kind:9,camera_quadrant:0..3}` only in opt-in levels. A changed Camera proposal follows the **existing native** transition_started/committed lifecycle, local `is_global=false`; authoritative camera changes at native commit. It has no Fall/landing/edge presentation identity.

Its `game_feel_event` is neutral `ACTION_FEEDBACK/FEEDBACK`, with `presentation_identity=null` and **transition_identity=null**. This feedback must never initiate completion. No new CAMERA semantic is invented in the shared event contract.

For the equivalent formal native bridge, 00 listens to `transition_started` and restricts the Camera handler to an original APPLIED+changed action kind9. Inside that callback it calls `get_pending_identity(transaction_id,generation,is_global)` to capture the real scoped identity, executes its natural Camera interpolation, and calls `finish_transition(captured_identity)` at completion. The accessor returns an immutable identity only for the exact active native token, generation and is_global; stale/mismatched requests return `{}`. It does not authorize an action. Rejected/ERROR/unchanged feedback cannot obtain a token or enter this bridge. Reset/unload invalidates its generation; 00 cancels its Camera handle before teardown and checks captured scope before later visual writes/completion.

This preserves ACTION_FEEDBACK's non-completion meaning and the shared Fall API. Other non-movement native transitions use the existing native bridge, not a classification guess. Pause prevents action/completion and preserves the token until resume.

## Versioned map contract

Legacy PuzzleActionKind is still exactly0..7; its names/membership, foundation.contract.v1, foundation.rules.v1, schema1 and statekey.v1 are unchanged. Opt-in levels use schema2, contract `foundation.game_feel.v1`, rule `foundation.rules.game_feel.v1`, orientation `cube24.v1`. Keep all existing Level fields and add:

```text
camera_initial_quadrant: int0..3
perspective_falls: Array[closed connection record]
connection_id: StringName lowercase ID
source_face_id, target_face_id: StringName cube_id/FACE
source_edge: FaceAxis int0..3
allowed_camera_quadrants: unique nonempty Array[int0..3]
allowed_world_orientations: unique nonempty Array[cube24 int0..23]
required_flags: Array[StringName] declared level flag IDs
path_points2: ordered Array[Vector3i], 3..64 points, abs(component)<=1000000
orientation_policy: StringName PRESERVE
motion_profile_id: StringName ID
presentation_duration_ms: int1..5000
```

Data rejects unknown/missing fields/versions, ambiguous overlapping permission domains and invalid references. Author metadata (`authorizes_traversal=false`, safety_status, candidate fields, route description) is not appended to closed Level records. 00/09 adds the above formal fields to author data before the existing Baker, or consumes the exact canonical output through the single existing LevelCodec. No second decoder/Baker or active-worktree source fallback exists here.

The seven core state fields are player, world_orientations, celestial, group_orientations, mechanism_states, level_flags, camera_quadrant. Key `statekey.game_feel.v1` is the existing canonical six-field serializer plus discrete camera at the front of its sorted state object, bound to level_hash/rule_version. Rendering camera transforms, animation, lighting, UI and debug fields are forbidden. SolutionTrace uses explicit `solutiontrace.game_feel.v1`; the real existing ActionGenerator/Explorer/Trace/Replayer handle it. No second BFS or reverse gameplay edge is created.

View quadrant0=NORTH,1=EAST,2=SOUTH,3=WEST. `foundation/game_feel/view_contract.gd` supplies the fixed right/down integer numerators and presentation Basis. EAST right=(1,0,1), down=(-2,-3,2); positive projected vertical means screen descent. Renderer yaw/zoom/pixels never authorize movement. Changing this basis requires a rule/view version change.

## A/B + Exit input for 00

Owner09 immutable input commit: 82a8a7dc85205e9391551f24267f35f5abe53393. No 09 production/test algorithm was copied or merged. Owner01's map test reads only the exact two JSON data blobs from Git, records blob/SHA256, and runs real Baker/Kernel/Safety/Runtime/Explorer/Softlock/Replayer.

For both: source center2=(0,4,0), source/TOP, edge U_NEG2, initial/permitted Camera EAST1, source World allowed orientation0, same-world target/TOP, flags=[], preserve. Target A=(-8,0,8); B=(-8,8,8). Exit is target+(2,0,0), goal exit/TOP. Authorized actor-center paths:

```text
A: (0,6,0),(-2,6,2),(-6,6,6),(-8,2,8)
B: (0,6,0),(-2,6,2),(-6,10,6),(-8,10,8)
```

Set connection IDs pfall_a/pfall_b; motion profile ID pfall_path; duration300ms. Complete route: player MOVE U_NEG2 → one Fall commit → MOVE U_POS0 → one ordinary Roll commit → Exit Goal. Reset restores exact spawn. Target alone is not Goal. Geometry including Exit is checked throughout the Fall path. Owner01 canonical A/B JSON artifacts and exact input identities are in the local `.godot/game-feel-owner-01/core_maps` final verification evidence folder; rebuilding them uses the documented test entry.

## Case boundary

Owner-local logical completion is explicitly LOGICAL_SESSION evidence, never natural graphical Fall playback. For opt-in GRAPHICAL, formal `TraceReplayer.replay(level,trace,{mode:1})` binds the fixed 00 `GraphicalCompletionBridge` to the same Runtime Facade. A/B Fall → Exit Roll now have actual natural Fall/Landing and Roll completion evidence. Missing/invalid Bridge still fails closed; no generic linear ghost tween can substitute for Fall parity. `get_step_evidence()` returns recursively read-only deep copies of each actual state/key, native identity, commit count and Bridge evidence. The original four options and eight result fields remain unchanged. Camera/other motion coverage, Art/Audio/UI and formal shared QA registration are outside this verified A/B case. 00 owns shared Presenter/host wiring, 10A owns motion samples, 03 owns shared formal QA registration.
