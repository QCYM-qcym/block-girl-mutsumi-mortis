# Continuation 04 — Input diagnostic preparation

Owner C. **INPUT_ENVIRONMENT = UNKNOWN; CONFIRMED_CAUSE = UNKNOWN; GRAPHICAL_DIAGNOSTIC = NOT_RUN; HUMAN_QA = NOT_RUN.** Preparation is deliverable; the historical incident remains unresolved. No Gameplay defect was confirmed.

## Identity and actual increment

- Worktree: `E:/godot/worktrees/bg-input-c03`; new branch: `test/spatial-input-env-cont04`.
- Base: `b3f8fa9b8a6562a25342787317f6b42bc6b973b9`. Actual pre-reuse worktree was CLEAN on `test/spatial-input-env-cont03` at `2ce5656412a9678d424f08b29d8771b73822e913`; that old branch is preserved. The new name was absent locally and remotely before creation.
- Scope: only new files in `docs/beta-sprint/spatial-formal-chapter-01/continuation-04/input/`. No helper or production change.
- Fresh external evidence: `E:/godot/beta-sprint-builds/spatial_input_cont04_20261021T071000Z`.
- Newly useful artifact: [one-event protocol and A–F evidence-gap matrix](CORRELATED_INPUT_PROTOCOL.md) plus [blank machine-readable event template](EVENT_TEMPLATE.json), with explicit target identity, time/clock bounds, tool call/ACK semantics, receipt sequence/continuity and runtime-action correlation. These are preparation, not synthetic observations.

## New read-only observations

At **2026-10-21T07:10:00.9371085Z**, the unchanged, already committed [metadata collector](../../../../../tests/beta_sprint/spatial_input_environment_cont03/capture_readonly.ps1) ran once. [PROCESS_WINDOW_SNAPSHOT.json](PROCESS_WINDOW_SNAPSHOT.json) records no Godot-named process and no PID 32312. No target could be bound. Unrelated foreground identity/title/content were not retained. This instant does not exclude a renamed executable or a later headless quality job.

Unlike the prior snapshot, the narrow tool-name check now found `codex-computer-use`, PID **35720**, start **2026-10-21T07:02:23.9138548Z**, session **1**. No control call was made to it, and its presence proves neither health nor native access. The active `mcp__cua_repl` contract still disables native APIs. No alternate control backend was imported or launched.

At **2026-10-21T07:10:26.2950809Z**, a read-only `WTSEnumerateSessions` query returned session 0 (state code 4, not active) and session 1 (state code 0, active); the collector itself is in session 1. Only IDs/state were retained, with no usernames or station names. [SESSION_AVAILABILITY.json](SESSION_AVAILABILITY.json) records this limited availability check. It does not establish exclusive ownership, separate input desktop, native-tool reachability or absence of a VM. The scoped handoff/protocols contain no declared available test VM/session. No unrelated VM/app inventory was scanned.

Independent interactive window + isolated profile + supported exclusive input control have **not** been jointly established. Therefore the graphical experiment was not run. No activation, key, click, scroll, drag, close, termination or user-process modification occurred. `USER_WINDOW_MODIFIED = NO`. A future Owner 00 headless quality run is not a player/GUI session and must not be selected by process name alone.

## Historical evidence and preservation

The prior [continuation-03 audit](../../continuation-03/input/REPORT.md) remains historical: its five startup-only logs and two transcribed guard errors do not supply raw call ID, send acknowledgement, dispatch target or game receipt. We did not repeat the log investigation or reclassify its findings as new observations. The excluded unrelated foreground capture was not opened, hashed or published.

This stage performs before/after SHA-256 checks of only the 16 explicitly listed historical QA files from the prior audit. Results and timestamps are in external `PRESERVATION_BEFORE.json` and `PRESERVATION_AFTER.json`; final validation records exact counts. This is a narrow preservation check, not a full package/profile certification. Old Build and player/save directories were not written; broader Build/profile verification belongs to Owner 00's integration baseline/end audit. No repackaging occurred: `PRODUCTION_CHANGES = NONE`, `NEW_BUILD = NOT_REQUIRED` for this preparation.

## Human QA and execution boundary

Qualified player: **NONE**. First-time comprehension: **NOT_OBSERVED**. No new session or player result is fabricated. Continue using the existing [protocol](../../continuation-02/HUMAN_QA_PROTOCOL.md), [session template](../../continuation-02/SESSION_TEMPLATE.json), and [execution addendum](../../continuation-03/HUMAN_QA_EXECUTION_ADDENDUM.md) by reference.

Retained Build `beta_spatial_formal_chapter_20261019_01` / source `763f0132bc58360fab0e224d0e9c54e00c92ae90` is unchanged. The user's future-player requirement is an explicitly verified new Build: resolve and verify actual authorized Build/source/package/manifest at the future run, then record it in a fresh session copy; do not inherit the historical template's Build identity blindly. No eligible player or new Build is claimed now. Earlier user play and automated diagnostic sessions remain separate.

## Validation and handoff

Applicable checks are JSON parsing and blank-template inspection, relative-link resolution, explicit added-file scope, whitespace, before/after historical hashes, and old branch/main/tag reference preservation. There is no production implementation or new helper requiring gameplay tests. GUI input, game receipt correlation and human comprehension tests are **NOT_RUN**. Exact validation evidence is `VALIDATION.json` in the new external evidence directory.

The final commit, ordinary push, independently queried remote SHA and CLEAN status are recorded in external `FINAL_DELIVERY.json` after completion and handed to Owner 00. Owner-local document validation is not Integration PASS. Stage remains **PARTIAL** for diagnosis/Human QA; the smallest next action is for Owner 00 to identify a supported independently controlled environment and approved receipt channel, then admit one event through the protocol. Without that gate, preserve UNKNOWN/NOT_RUN.
