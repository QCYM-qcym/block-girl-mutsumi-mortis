# One-event diagnostic protocol (prepared, not executed)

Owner C; continuation 04; source baseline `b3f8fa9b8a6562a25342787317f6b42bc6b973b9`. This protocol closes specific evidence gaps in the historical QA08 input incident. It authorizes no production instrumentation and records no new gameplay observations. Use the [blank event template](EVENT_TEMPLATE.json) only in a new external diagnostic session directory.

## Admission gate

Owner 00 must first coordinate a declared, independently controlled interactive session/desktop or test VM, its operator, and exclusive input ownership. Prove the tool can address that environment without affecting the user's session. A separate window or profile on the same shared input desktop is insufficient. Native control must be explicitly supported by the actual tool contract; helper-process presence is insufficient. Do not bypass disabled native APIs with another input implementation.

Bind a dedicated test window and fresh profile. Verify the actual runtime executable, package/source SHA, manifest, copied package location, profile paths and launch arguments at execution time. Bind PID **and process start time**, OS session, desktop/VM identity, tool window token, HWND and window-owner PID. Reject a headless Godot test, editor-only process, mismatched source path or stale PID. Owner 00's headless quality work under a `*cont04*` evidence path is not an interactive target.

Before dispatch, demonstrate an already approved game-side receipt channel with event sequence and timestamps plus a runtime-action observation channel. Record the channel's boundaries, clock alignment uncertainty, sequence baseline, collection start/end and drop/gap evidence. Startup-only logs cannot provide this. If the channel is unavailable, defer the correlated experiment; any new production instrumentation requires a separate Owner 00 decision. Do not invent an event from an unchanged screenshot.

## Minimal sequence after admission

1. Copy the template into a new session directory; retain original template unchanged. Fill admission evidence, current build identity and expected input/runtime action **before** sending. Select one harmless, reversible action valid in the recorded screen/state. Specify key/button, press/release or scroll direction/amount and the expected input-to-action mapping; do not assume menu focus or the mapping from earlier builds.
2. Start the approved receipt channel before the action. Record UTC and monotonic time plus frequency/source for each observation. Record the mapping between tool and game clocks and its uncertainty; if clocks cannot be aligned, correlate a unique event sequence in an otherwise idle bounded interval and retain the ambiguity.
3. Refresh/bind the target through the supported tool. Immediately before dispatch, sample target PID/start/session/window owner, target-thread focus and system foreground equality. Record the observation time and dispatch time; a pre-dispatch focus sample does not prove focus at dispatch. Use a tool-provided dispatch-time target/focus trace if available; otherwise leave those fields null and explicitly retain gap B.
4. Dispatch **one** declared action. Keep exact tool call ID, redacted target-only arguments, call start/end, raw response/error evidence path+SHA, and acknowledgement semantics. Distinguish accepted/queued/injected/rejected/unknown. A successful response is not automatically OS injection or game receipt. A guard error alone does not prove pre-injection rejection.
5. Collect the game event sequence, timestamp, type/value, game PID/session, mapped action and runtime decision/state observation through the approved channel. Record whether an action was accepted, blocked or unmapped and the reason if observable. Record receipt trace bounds and continuity; null means unavailable, not no event. One target-scoped post-action observation may confirm visible outcome but cannot replace receipt telemetry.
6. Stop after that one action. Stop immediately on user-input guard, changed foreground/target, unexpected process/profile identity, or other interference; do not retry, activate, drag, close or terminate the user's window. Retain the error and metadata, with no unrelated-app capture. If target identity changes, abandon the correlation rather than reusing its PID/token.
7. Hash the new evidence, compare identity across the event, then apply the matrix below. Multiple contributing factors may remain possible. Record UNKNOWN when the chain is incomplete. A later isolated successful run validates that run only; it does not retrospectively diagnose the historical incident.

## Evidence gaps and admissible conclusions

The A–F labels below are continuation-04 labels; they deliberately supersede the old report's different A–E ordering without relabeling historical records.

| Candidate | Minimum evidence needed | Current evidence / unresolved gap |
| --- | --- | --- |
| A — Tool send failure | Exact call ID, raw error/ACK, timestamp and documented dispatch stage; pre-injection failure requires explicit stage evidence | Two historical guard errors are transcriptions only. No raw call or dispatch-stage trace. UNKNOWN. |
| B — Focus interference | Target identity and timestamped foreground/focus transitions correlated with the actual dispatch interval | Old contaminated capture proves observation contamination only. New point-in-time metadata cannot reconstruct old focus. UNKNOWN. |
| C — Wrong process/window | Intended and actual dispatch target with PID/start/session/HWND, tool token and receipt identity | No historical dispatch-target identity. A process name or remembered PID is insufficient. UNKNOWN. |
| D — Game nonreceipt | Confirmed dispatch to verified target plus complete, gap-accounted game receipt trace covering the action interval and clock uncertainty | Startup-only logs do not establish trace completeness or nonreceipt. UNKNOWN. |
| E — Path/build/profile mismatch | Hash-bound expected package and actual process executable/launch source/profile identity for the same event | Historical package integrity alone cannot bind an old dispatch to a running instance. UNKNOWN. |
| F — Unconfirmed cause | A–E remain unresolved or evidence conflicts | Current conclusion: UNKNOWN. No confirmed Gameplay defect. |

Game receipt with a valid mapped action and an unexpected runtime result is a separate gameplay investigation only after environment/identity uncertainty is addressed. Normal blocking, invalid action in current state, or no visible change alone is not a defect.

## Human QA is a separate future session

Use the existing [continuation-02 protocol](../../continuation-02/HUMAN_QA_PROTOCOL.md), [session template](../../continuation-02/SESSION_TEMPLATE.json), and [continuation-03 execution addendum](../../continuation-03/HUMAN_QA_EXECUTION_ADDENDUM.md). Do not duplicate empty player observations in this diagnostic record.

The retained package is `beta_spatial_formal_chapter_20261019_01`, source `763f0132bc58360fab0e224d0e9c54e00c92ae90`. Those are historical retained identities, not automatic authorization to label a future player session as a newly verified Build. The user requires an explicitly verified new Build for future player testing. At the actual run, Owner 00 must identify the authorized Build, verify its source/package/manifest and fresh session copy/profile, and update the copied session record with actual identities; never inherit the old template's hash blindly. This preparation does not repackage anything or decide a new Build is ready.

No eligible player exists now: `HUMAN_QA = NOT_RUN`, `FIRST_TIME_COMPREHENSION = NOT_OBSERVED`. Earlier user play, author replay and automated diagnostic input remain separate. Never send automated input into a player's live session.
