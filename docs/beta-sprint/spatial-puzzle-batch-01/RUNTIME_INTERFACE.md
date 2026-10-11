# Runtime interface — Spatial Puzzle Batch 01

Authority: CONTRACT.md at 7442e8172e865d093ff1e73570d891f60d9134af. Owner01's exact opt-in interface; implementation/tests are pending at this document's first commit.

## Level profile

Use all existing schema3 Level fields and cubic Fall records, plus these **required** fields:

- `schema_version: 4`
- `contract_version: "foundation.spatial_puzzle.v1"`
- `orientation_version: "cube24.v1"`
- `rule_version: "foundation.rules.spatial_puzzle.v1"`
- `shift_gates: Array[ShiftGate]`
- `face_locks: Array[FaceLock]`

Empty arrays are explicit, never defaults. Legacy schema1/2/3 reject these fields and keep their original codecs/hashes/keys/rules. This profile retains camera, cubic Forward Drop and ordinary Roll priority. Formal Baker/LevelCodec remain the only bake/codec.

## Closed records (typed memory)

`ShiftGate` has exactly:

```gdscript
{"gate_id": &"gate_name", "source_face_id": &"source/TOP",
 "target_face_id": &"target/TOP", "required_flags": [],
 "required_mechanism_states": [{"mechanism_id": &"lock_name", "state": &"latched"}]}
```

IDs are StringName using the existing ID/Face ID grammar. Every requirement references a declared mechanism and one of its allowed states. All requirements and flags must hold. Fixed gates have both requirement arrays empty. Exactly one gate per source Face; duplicate gate IDs/source Faces and duplicate requirement mechanism IDs are invalid. The pair must reference walkable Faces in opposite layers. Direction is explicit; a reverse gate is a separate record.

`FaceLock` has exactly:

```gdscript
{"mechanism_id": &"lock_name", "required_local_face": 3,
 "activation_mode": &"LATCH_ON_SUCCESS", "latched_state": &"latched"}
```

`required_local_face` uses the frozen six FaceDirection values (FRONT0/BACK1/LEFT2/RIGHT3/TOP4/BOTTOM5). It is the player's physical local face, **not** the host surface Face. The referenced existing MechanismDefinition must have `trigger=&"ENTER"`, self-bound `action={"kind":5,"mechanism_id":&"lock_name"}`, distinct initial/latched states, and exactly `allowed_states=[initial_state,latched_state]`. One ENTER mechanism per sensor Face; first profile does not mix latch and other ENTER effects.

## Gate permission and rejection

Input continues to send the existing `{"kind":1}` SHIFT_WORLD. For this opt-in only, the current source must have a gate and its requirements must hold. Then the existing **unfiltered** Derived.shift_mapping must be UNIQUE and match the declared pair with SAME_NORMAL. Surface departure still requires SHADOW; exit/entry blockers and real Safety still apply. Camera and the exact player Orientation are preserved. Gate permission never turns ambiguous geometry into a valid mapping.

Extension-local `SpatialRejectionCode` values (in `foundation/rules/spatial_puzzle_rules.gd`): `SHIFT_GATE_NOT_FOUND=2010`, `SHIFT_GATE_LOCKED=2011`, `SHIFT_GATE_TARGET_MISMATCH=2012`. These are execution rejection codes, not replacements for legacy ValidationCode/ActionRejectionCode values. Existing mapping/Shadow/block/Safety errors retain their actual upstream codes. Every rejection has next_state=null, changed=false, and no authoritative commit.

## Contact and atomic latch

Only ordinary successful Roll arrival activates the first profile. Check the post-roll candidate through formal integer math:

```gdscript
Orientation.apply(arrived.player.orientation,
    Geometry.face_frame(required_local_face).normal) == -host_anchor.frame.normal
```

The direction is inward contact against the current formal support normal; on the first TOP/UP sensors it is physical DOWN. Camera screen DOWN, mesh color and temporary transforms do not participate. Wrong pose leaves MOVE successful and the latch unchanged. Correct pose changes only `mechanism_states[mechanism_id]` in the **same MOVE candidate**, with local transition kind and one commit. Re-entry after latching does not retrigger; leaving preserves state. Reset restores the declared initial state. Direct USE of this ENTER-only sensor is rejected.

First-profile sensors are not Shift/FaceTransition/Fall landing targets. Existing static/global entry restrictions remain; author the sensor on an ordinary Roll route separate from gate/Fall landing Faces. No new action, BFS implementation, gameplay state map, or animation is introduced.

## Canonical identity and formal consumers

LevelCodec sorts gates by gate_id, requirements by mechanism_id, face_locks by mechanism_id and required_flags with the existing codepoint set order. All these rule fields enter content_hash. Existing mechanism state and player Orientation enter the existing full StateKey; `statekey.game_feel.v1` also includes Camera and the new level hash/rule version. Trace uses the existing `solutiontrace.game_feel.v1` contract and actual Kernel semantics. Search/Safety/Replay reuse their formal implementations. The intent classifier recognizes a real newly latched contact as MECHANISM_TRIGGER and does not invent a trigger for wrong/repeated contact.

## Typed authoring / Resource Binding

The existing levelauthoring.v1 document envelope remains. A LEVEL declaration opts in using the exact four versions above and declares `camera_initial_quadrant`, cubic `perspective_falls`, and `shift_gates` in addition to its existing fields. `face_locks` are projected from existing MechanismAuthoringNode + MechanismConfig resources, not a second independent author declaration.

For the new self-bound kind5 config only, declare `kind=5`, `initial_state`, `allowed_states=[initial_state,latched_state]`, `required_local_face`, `activation_mode=&"LATCH_ON_SUCCESS"`, `latched_state`. MechanismAuthoringNode retains stable mechanism_id, host_face, trigger ENTER, priority and `target_bindings={}`. The existing Adapter binds action identity and projects one FaceLock record. Legacy authoring kinds remain unchanged. Reader/Baker/SourceMap stay authoritative.

## Ownership

01 implements the versioned Foundation profile and its affected consumers/tests. 09 authors maps/witnesses; 00 owns Host/Presenter/ForwardDrop and native Shift completion wiring. No Owner01 Host, animation, fixture-map production or p01 algorithm copy. Continue uses the existing start-of-level persistence semantics.
