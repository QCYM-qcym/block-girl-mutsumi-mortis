# Owner07 integration request — GAME_FEEL_UI_EXTENSION_01

Contract baseline: `2938d6e534f5b596bb320ce79d72b69f5923f3cd`. Owner code: `game/feel/ui/game_feel_ui.gd` and `motion_row.gd`. Integration owner00; no shared-file edit was made by07.

## Host assembly and persistence

Instantiate the CanvasLayer only in `experiments/game_feel_01/host/**`, leaving accepted Shell/HUD unchanged. Host calls bind_context(actual_session_id,actual_level_run_id) on binding/load and routes immutable game_feel_event to consume_event. Same-run repeat binding preserves deduplication. Reset/reload/exit must deliver the old scoped interruption or bind the new run before deferred cleanup.

Phase pairing follows the committed contract: non-edge ACTION_FEEDBACK uses FEEDBACK (including MECHANISM_LOCKED); only typed MOVE_REJECTED_EDGE uses REJECTED. Native rejected status/code remains inside the copied result, separate from delivery phase. See FEEDBACK_CONTRACT_FIX.md for the corrected consumer and RED/GREEN.

Open with open_settings(actual_saved_settings). Connect:

- settings_preview(values) → delivered11 AudioDirector.apply_settings(values) and existing fullscreen lifecycle. Audio ignores fullscreen. Preview must not write Save.
- settings_apply(values) → existing host progress/Save transaction using unchanged version1 keys. On actual success apply the newly saved values to AudioDirector, then call settings_applied(values); on failure restore persisted values to AudioDirector, then call settings_failed(actual_message). Reapplying on success is essential after a failure rollback followed by retry without editing. Never acknowledge just because the signal was emitted. UI makes no independent Save call.
- settings_cancel() → captured host page/Pause state. Cancel first sends saved audio preview and restores prior presentation config. Host suspends real Runtime/input while Settings is open; UI does not change Runtime legality or invent pause state.
- accessibility_changed(options) → host presentation configuration `{reduced_motion:bool,hint_strength:int0..2}`. Notify formal Cube Presenter/motion composition to simplify Fall/Edge decoration; never change an authorized path, orientation endpoint, Safety or Runtime results. UI already suppresses its own row tweens. Persisting experimental config requires an explicit00-owned contract; do not silently insert it into legacy Save.

For asynchronous persistence, acknowledge/fail before another settings opening. Missing Audio stays silent with host diagnostics. Formal11 API is now delivered at4afbd068fae74a826dae4db04c2c612af23fa861 and normally merged as the consumer dependency. Actual Owner Settings/API/Save lifecycle tests pass; the explicit Unit00 host bridge remains separate from production00 host wiring.

## Authored hints and map placement

set_authored_hint(key_hint,optional_hint) takes existing Hint System text for the actual level. Call after context binding (a new run clears old text). Strong assistance appears only at strength2; default/context can display an authored operation cue during active status. Do not supply generated route/target guidance.

The passive band occupies top-left `(24,24)`, up to440px wide, ignoring pointer/focus. Host must reserve it outside map/header controls. Graphical occlusion, wrapping and actual HUD placement require fresh Build; logical Owner tests prove viewport containment only. Agree a host-selected placement port during integration if needed.

## Readiness contract gap —01/00

Committed v1 supplies accepted Fall STARTED/COMMITTED and typed refusals, but no pre-action query/signal for legal connection readiness/loss.07 does not infer permission from projected geometry, keys, maps, labels or generic MOVE_BLOCKED2000. Current feedback reports actual accepted Fall and lifecycle; it does not claim a pre-action “can fall” indicator.

01/00 must deliver an authoritative versioned optional readiness snapshot/notification for valid/disconnected/Fall-enabled state if these pre-action indicators are required. Specify actual connection identity, session/run, monotonic freshness and explicit reason. UI will render status without target/path guidance. Agree/commit the public interface before consumer work. Only this affected case is pending.

## Fresh integrated verification

After01 Runtime,10A/B sampling,11 Audio and00 host/Presenter are normally merged, provide immutable source SHA/Build/package/profile. Test1920×1080/1280×720/960×720 against that Build: text/hints, buttons, focus, HUD/map overlap, sliders/mute actual Audio effect, Apply/Cancel/cold restart, Pause/resume and Shell return. Reduced Motion must reach the real Presenter and retain Runtime/endpoint parity. Record visual regression and08 Human status separately. Old Alpha or Owner logical checks cannot supply these PASS labels.
