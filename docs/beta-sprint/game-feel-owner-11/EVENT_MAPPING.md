# Owner 11 event and playback mapping

Contract: game_feel.event.v1; runtime authority belongs to 01, routing to 00. No Runtime transition finish, state assignment, collision/support decision, camera inference or Save write exists in these modules.

| Authoritative input | Audio behavior | Current evidence |
| --- | --- | --- |
| MOVE_APPLIED_NORMAL / STARTED | cube_roll; captured presentation identity | Presentation Unit / actual local player |
| Same token/source/target / COMMITTED | stop that scoped voice; cube_contact once | Presentation Unit |
| PERSPECTIVE_FALL_APPLIED / STARTED | fall_start plus identity-scoped fall_whoosh loop; no impact | Presentation Unit; no claim of legal Fall |
| Matching Fall / COMMITTED | stop same loop synchronously; landing_impact once | Presentation Unit |
| Explicit EDGE / REJECTED / unchanged native result | edge_recoil once per attempt, maximum one per 0.35 seconds | Held-input Unit burst |
| BUSY / invalid Face / mechanism / safety / wrong camera or world / generic feedback | neutral silence; never EDGE or landing | Presentation Unit |
| ANIMATION_INTERRUPTED / captured presentation_identity | cancel matching local voices and deferred cues, no landing; works while paused | Presentation Unit |
| Pause | freeze stream playheads and music fade clock | Actual local playback |
| COMMITTED while paused | finalize identity, stop loop, defer one committed cue until resume; cancel/clear removes deferred cue | Presentation Unit |
| clear / exit_tree | retire current run, stop all local loops and one-shots synchronously | Actual local playback |

All event_id values are monotonic nonnegative integers within a run. 00/01 must confirm this concrete type because the prose shared contract calls it monotonic identity without explicitly typing it. A malformed/unsupported event stays silent with bounded diagnostics. Every accepted endpoint is compared to the captured STARTED endpoint, not only transaction numbers. Old generations, duplicate commits, feedback and reset-native commits never become landings.

`AudioDirector.play_ui(cue, cue_identity)` aliases `select`→ui_select, `back`→ui_back and `complete`→goal. Stable identical completion identity starts goal SFX and complete music only once across `goal` and `complete` sources. `discovery` starts the musical discovery cue. It also accepts the exported names perspective_connect, perspective_disconnect, world_shift and edge_lean for 00's independently confirmed presentation callbacks. These names are AUDIO cues, not new Runtime semantic events. Full presentation-identity dictionaries are rejected after cancellation, retired runs or old generations; menu UI may use opaque nonempty unique string identities. Do not use a new arbitrary string to circumvent a captured gameplay identity's cancellation.

World/menu lifecycle uses audio-only `set_music(context, world_id=0)`, where context is menu / exploration / none and world_id is 0 Surface / 1 Inner. Surface and Inner run concurrently on entering exploration. Subsequent calls with exploration change only gain target, never restart or seek either stream. The equal-power world fade lasts 0.65 seconds; context gain ramps last 0.6 seconds. Pausing holds these ramps. Goal fades exploration away while its short completion theme plays.

The v1 movement envelope does not define standalone World Shift, Perspective Connect/Disconnect, EdgeLean sample milestones or Goal/Menu events. These source bindings remain **PENDING_00/actual native delivery**. The fallback is silence, not a fabricated rule result. Generic APPLIED feedback cannot substitute for a World Shift commit or Goal truth.

A fixed 18-player population comprises 5 music voices and 13 SFX voices, max_polyphony=1 each. Repeated cues replace the same voice. Missing manifest/resources report diagnostics and return; gameplay never waits for audio. There are no per-input player allocations, new Audio Bus, Autoload or global inputs. PCM16 WAV loop frame endpoints are applied to locally loaded streams without editing import settings.

Synchronous `cue_played` observers may cancel/reset or deliver a new action. The director checks lifecycle epoch across the cue sequence. An old identity's cancellation does not invalidate a newer sequence. Completion, start and cancellation state is updated before observers run.

Lifecycle tombstones for retired runs/canceled identities are retained until the director is freed, to reject late callbacks. Event/terminal/UI dedup caches and diagnostic messages are bounded; lifecycle tombstone memory grows with loads/cancellations. The intended host creates one director per lab lifecycle and frees it on teardown. This is a documented small metadata limitation, not a claim of constant lifetime memory.
