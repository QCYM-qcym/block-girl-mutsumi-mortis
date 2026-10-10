# Curve Fall event.v2 — bounded Owner07 consumer extension

2026-10-10. Task: PFALL_TARGET_PLATFORM_AND_TRAJECTORY_FIX_01. Previous07 HEAD: **6d3bf4b7f5120b44dad4790b657a4be953dd4954**, verified clean before edits.00 requested only known new Fall/interruption consumption in the existing worktree; no UI redesign or persistence change.

The explicit supplemental contract was registered by00 at **ec826753435458abc41cc365e4b57dba27767fbd**, `docs/beta-sprint/game-feel/yellow-target-01/TRAJECTORY_CONTRACT_DELTA.md`. Read-only reference SHA256: **4e230017b25b047940c8b6b28d0253e35836c67833ce6698005ff63e24d77a3f**. Its exact bytes are retained under evidence/owner07_curve_event_green_02/source/TRAJECTORY_CONTRACT_DELTA.reference.md. The original shared contract remains byte-identical; no shared contract/Runtime/Host file is changed or imported by this increment.

## Minimal behavior

- Existing schema1/game_feel.event.v1 dispatch remains available for old Fall, Roll, Edge and mechanism feedback.
- Schema2/game_feel.event.v2 accepts only PERSPECTIVE_FALL_APPLIED with STARTED/COMMITTED, and ANIMATION_INTERRUPTED with INTERRUPTED. New Roll/Edge/feedback versions are not invented.
- New STARTED requires the Dictionary authorized_trajectory with known string trajectory_version=pfall.departure_cubic.v1, then the existing native APPLIED result, structured SAFE verdict, authorized target and captured presentation identity gates. Missing/unknown trajectory cannot fall back to authorized_path_points2. UI reads no trajectory coordinates, samples no curve and recomputes no Safety or gameplay permission.
- The same existing passive Fall status is reused. Full captured presentation identity and event contract version both scope COMMITTED/INTERRUPTED cleanup. Cross-version callbacks, old attempts, duplicate events and foreign runs cannot clear or resurrect current feedback. Matching Reset interruption may have null target; a new context clears both identity and captured version.
- Unknown/mismatched event versions, noninteger/nonstring version fields, unsupported v2 semantics/phases and unknown trajectory envelopes are rejected before event deduplication. No v2-to-v1 rewrite exists.

Settings, Save, Audio routing, Reduced Motion, Hint behavior, UI tokens/fonts, Main/Select/HUD and passive band layout are unchanged. No runtime/legal target is inferred from mesh, color or camera.

## Actual RED/GREEN evidence

- owner07_curve_event_red_01: prior production consumer with new tests;97 checks,8 failed assertions, exit1. Known v2 starts are invisible. Raw stderr also retains the old Dictionary/int version-comparison execution error from an explicitly malformed fixture; no parser/import failure supplied the RED.
- owner07_curve_event_green_01:217 checks pass after the minimal consumer correction. This preceding test revision is retained as history.
- owner07_curve_event_green_02:217 checks pass against the final tested sources, including explicit supplemental-contract reference/Unit labels in reports. Save19 + Shell20 + Owner Settings/actual Audio API/events97 + cold restore5 + three logical viewports76. Every stage exits0, stderr0, failures=[], source_drift=false;172 physical source hashes, isolated hidden headless processes, actual Godot4.7.2.stable.steam.ed1daf0bf.

The37 added assertions cover readonly nested trajectory/native result consumption; matching completion/Reset; cross-version callbacks in both directions; late attempts; duplicates; unsupported envelope/schema/profile/phase/kind; no old-path fallback; high-ID dedup isolation; unchanged APPLIED/SAFE/target gates; new-run cleanup and old-run isolation; retained v1 Fall behavior. Fixtures and their SAFE evidence are deliberately synthetic, authoritative_runtime=false. Runtime pose/path legality, sampler, continuous Safety and real native completion are not attested by these UI tests.

Source/tested/physical Git-blob binding is published in DELIVERY_BINDING.json after the actual source commit. Earlier structured Safety binding remains evidence/structured_safety_172_binding.json; all earlier raw logs, save/QA packages and contracts remain unchanged. Original WIP HEAD/dirty records are retained exactly, never relabelled as a clean-commit execution.

## Dependent cases

Only Owner-local compatibility is ready for00 normal integration. New-profile real Runtime/Host event consumption and fresh immutable Build/graphical/Human verification remain pending with zero checks in CURVE_CASE_PENDING.json. The registered contract commit is a schema reference, not a delivered Runtime SHA. Old integrated graphics or legacy size PASS cannot certify this new candidate. No broad GAME_FEEL_UI_EXTENSION_READY claim or push.
