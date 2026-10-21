# CONTINUATION_03 — Input environment diagnosis

Owner C / Quality and QA environment. Stage: **PARTIAL**. Input root cause: **E — UNKNOWN**. `GRAPHICAL_DIAGNOSTIC = NOT_RUN`; `HUMAN_QA = NOT_RUN`; `PRODUCTION_CHANGES = NONE`.

## Identity and actual increment

- Worktree: `E:/godot/worktrees/bg-input-c03`.
- Owner branch: `test/spatial-input-env-cont03`.
- Verified baseline: `f972cb850845cb2c31da6975ac7466437aafdec2`; integration worktree and new owner worktree were clean before work.
- Remote: `https://github.com/QCYM-qcym/block-girl-mutsumi-mortis.git`.
- Allowed scope: this `continuation-03/input/` directory and `tests/beta_sprint/spatial_input_environment_cont03/`; no production or shared harness edits.
- Historical QA receipt: `da78ba930332e6ed33ab1b86210eda0d80ca2adc`; observed build source: `763f0132bc58360fab0e224d0e9c54e00c92ae90`. Neither is this diagnosis's live test run.
- New external evidence: `E:/godot/beta-sprint-builds/spatial_input_cont03_20261021T062748Z`.

At **2026-10-21 06:27:48.9329473Z** (14:27:48 Asia/Shanghai), a real read-only process/foreground sample found **no process whose name contains Godot**, and **PID 32312 was absent**. This replaces the continuation-02 present-process observation only for this new instant; it does not establish when, why or by whom the old process exited. The historical launcher names `godot.windows.opt.tools.64.exe`, so that prior executable is within the query scope. This is not a claim that no renamed game executable can exist.

No current Godot target window could be bound. The foreground window did not belong to an observed Godot process; unrelated title, identity and content were not recorded. Target activation/focus therefore remain **N/A (target absent at sample)**. The collector supports read-only per-thread focus metadata when a target exists; it does not activate a target. No current input delivery or reception can be inferred from this snapshot.

The known tool process names `codex-computer-use` and `cua_node` were not present in the sample. This narrow name check is not proof that every possible backend is absent or unhealthy. The current `mcp__cua_repl` contract explicitly disables native APIs. The installed Computer Use skill was read, but its import/launch sequence was not used to create an alternate native control path. Tool health is **UNKNOWN**, native-control availability is **DISABLED_BY_TOOL_CONTRACT**. No tool input was attempted.

## Historical evidence newly checked

Read only the known QA evidence directory, its scoped logs, the committed QA receipt and launcher. No private conversation archive or unrelated app logs were scanned. The old evidence manifest's **16 files still match all 16 recorded SHA-256 hashes**; the excluded unrelated-window capture was not opened or published.

Five inspected logs contain only engine/renderer startup or are empty:

| File in historical QA root | Bytes | Input dispatch/receipt records |
| --- | ---: | ---: |
| `launch.stdout.log` | 150 | 0 |
| `launch.stderr.log` | 0 | 0 |
| `log_snapshot/launch.stdout.log` | 150 | 0 |
| `log_snapshot/launch.stderr.log` | 0 | 0 |
| isolated profile `logs/godot.log` | 147 | 0 |

The hashes, timestamps, exact paths and startup lines are in [HISTORICAL_EVIDENCE_AUDIT.json](HISTORICAL_EVIDENCE_AUDIT.json). Absence of event telemetry is **not evidence of game nonreceipt**. Raw automation call IDs, dispatch acknowledgement, target HWND at dispatch, and corresponding game-side input events were not found in this scoped evidence. The two errors survive as the QA report's transcription: `user input was detected in this window; call get_window_state before continuing`. No exact per-error timestamp is available in those records.

## Classification and causal limit

| Candidate | Evidence and verdict |
| --- | --- |
| A — Game did not receive input | **UNKNOWN**. No correlated game receipt trace. A visually unchanged menu cannot distinguish nonreceipt, ignored input, scrolling limits, or rejected dispatch. |
| B — Input sent to wrong window | **UNKNOWN**. Historical capture contamination is recorded; it proves an invalid observation, not which window received an input. No target-at-dispatch record exists. |
| C — Test tool send failed | **PARTIAL evidence, underlying dispatch UNKNOWN**. Two calls reported a user-input guard error. This establishes unsuccessful tool calls as recorded, not whether the implementation rejected before injection, injected partly, or failed on subsequent state validation. |
| D — Other process/tool interfered | **UNKNOWN**. The tool reported user input, and the report describes an unrelated window in a later capture. No timestamped actor/device/tool correlation links those observations causally. Do not identify the human, another process, or another agent as the cause. |
| E — Cause unconfirmed | **Current diagnosis**. Observability and execution constraints prevent attributing the historical interruption to one of A–D. |

The supported sequence is: QA report records a menu observation, two guarded scroll-call errors with a refresh between them, then an excluded contaminated capture and stopped input. The new sample establishes that the former PID is no longer present. There is **no confirmed causal chain from external actor → dispatched event → game receipt → wrong gameplay result**. `QA08-ENV-INPUT-01` remains an unresolved test-environment issue; no new Gameplay defect or severity is assigned.

## Safe minimal next operation

First establish an **independent interactive desktop/session or VM** with native tool access enabled, a dedicated test window, an isolated profile, and verified build identity. Another window on the same shared desktop and a separate save directory alone do not isolate focus/input. This turn did not establish those conditions, so no launch, activation, click, scroll, key, drag, close, process termination, or GUI experiment occurred.

Then, under that isolated condition, refresh and bind exactly one returned tool window; record UTC, PID/start time, HWND and focus immediately before **one** intended action; retain the raw tool call/result and a target-side receipt trace (event timestamp, type and sequence) from approved diagnostic instrumentation. Correlate dispatch and receipt before assigning A–D; refresh once to observe outcome. If the guard fires again, stop instead of repeatedly injecting. Adding instrumentation to production/shared UI remains a separate Owner 00 decision; this report does not authorize it. Do not recover or reuse PID 32312 as a current identity.

First-time human comprehension still has no qualified participant. Agent input, historical user play, and known-solution replay are not a substitute. No timings, comprehension scores, progression or softlock outcomes are estimated.

## Validation and delivery boundary

The read-only collector was actually run once; it wrote [PROCESS_WINDOW_SNAPSHOT.json](PROCESS_WINDOW_SNAPSHOT.json). Its declarations contain only metadata reads and it records zero attempted input/process/window mutations. [TOOL_CAPABILITY.json](TOOL_CAPABILITY.json) distinguishes contractual availability from observed process names and unknown health. Documentation/JSON, immutable manifest hashes, explicit path scope, syntax and Git whitespace checks are the applicable verification; gameplay and GUI test matrices are **NOT_RUN** because no production changes or safe interactive environment exist.

The debugging workflow remains at evidence collection: no safe, red-capable GUI reproduction loop was established. No fix is proposed or claimed. Development-branch delivery may complete while this diagnosis remains PARTIAL. The final commit/push/remote-SHA receipt is stored in the new external evidence directory as `FINAL_DELIVERY.json` after actual verification and handed to Owner 00; it is not backfilled into historical QA.
