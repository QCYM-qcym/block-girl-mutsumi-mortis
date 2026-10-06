# Foundation-4 Core Freeze for Beta — 2026-10-06

FOUNDATION_4_CORE_FROZEN_FOR_BETA

Effective immediately under the user's [Beta Freeze Decision](BETA_FREEZE_DECISION_REQUEST_20261006.txt). This decision supersedes the earlier October12–15 target and the requirement to wait for full Editor acceptance. It changes Beta scope; it does not turn unachieved capabilities or failed checks into PASS.

| Scope | Current decision |
| --- | --- |
| FOUNDATION_4_CORE | FROZEN_FOR_BETA / PASS |
| I2 Core | CORE_VERTICAL_PASS / 352 checks |
| FOUNDATION_4_FULL | DEFERRED_POST_BETA |
| Editor Beta | CORE_AVAILABLE / ADVANCED_AUTHORING_DEFERRED |
| Editor full acceptance | NOT_ACHIEVED |
| D5 / D6 | POST_FREEZE_BACKLOG / POST_BETA |
| Confirmed Foundation P0 / P1 blockers | 0 / 0 within the accepted Core evidence scope |
| Next main milestone | BETA_3D_INTEGRATION_01 |
| Push | NOT_RUN |

## Accepted Core and unchanged receipts

Integration decision baseline:8bd49cbd3f878907d929ff313d4ec6d126ba740f. D_JOBS receipt96397ea5708e0e87dd05e3d1d4c682ca0a5478b8 remains authoritative. Formal slots in `tests/foundation/authoring_integration/dependency_receipts.json` are unchanged; B_EDITOR and D_FULL remain absent.

| Formal module | Delivery commit | Evidence |
| --- | --- | --- |
| D_PROTOCOL | 8f7fb52f029053bda10b965da840c6763fc13bf0 | existing PASS retained |
| D_SAVED | 4f2cfd4cba11677fe3dae6fa3dd66a4148e15e11 | existing PASS retained |
| A_EDIT | 8a67282ac3022cb3d9b43e553424ed1aa3b2d7d2 | existing PASS retained |
| D_HOST | 8289d804c3b5b42a2e6c2cf76e965679a0f83af8 | existing PASS retained |
| C_QUALITY | bb27f8c7cd6e2d9d94fbe3b8d3f98b99f86484d1 | existing PASS retained |
| D_JOBS | 7836de52866255dd6f9684214b014d9703e7854d | shared Unit490 / Real395 / Graphical117 PASS |
| I1 | 14936504ae4245cc1822786937f021afce4a7fd9 | FROZEN_PASS; script/UID/maps unchanged |
| I2 | 689ef1dd293a7525be6cb29c0bf7f5ead964a454 | shared i2_g01 Graphical352 PASS |

D_JOBS and I2 original results/process records/logs were reread, not rerun: failures=[], exit0, stderr0; Real/Graphical doubles=[]. D_JOBS fourteen current source hashes still match the exact formal receipt. Current project.godot matches the accepted Shell Main Scene boot evidence. The prior full Content/Shell slice and today's source playable build remain available. No new Foundation production change, contract change, receipt-gate relaxation or full development workflow is part of this decision.

Human QA P0=0/P1=0, L-03 stale hint and Inner readability feedback are new facts supplied by the user's Freeze Decision. 00 did not rerun Human QA or find a separate new raw Human QA report. Earlier blind-QA READY/NOT_RUN documents remain historical handoff snapshots, rather than being rewritten as automated human testing.

## 4B scoped phase evidence

EDITOR_CORE_PHASE_EVIDENCE:5a70d13748989c40cf530b1b019e62264dc4b828

The Owner-local scoped sync audited120 allowed dependency paths with outside-manifest changes0. The five Owner delta hashes match the original report. This is documentary phase evidence, not a formal B_EDITOR slot, a merged Editor baseline or EDITOR_BETA_BASELINE_READY.

Original evidence root: `E:/godot/worktrees/block-girl-foundation-editor-tools/.godot/foundation-authoring-tests/`.

| Original 4B run | Actual result | Scope |
| --- | --- | --- |
| eb_owner_final_unit_20261006 | 69/69 PASS; exit0; stderr0 | Unit declares service_double |
| eb_owner_final_editor_20261006 | 47 checks / 8 failures; exit1; stderr0 | real Windows Editor; doubles=[] |

Passed evidence: Plugin/Dock load, real TaskService/worker launch, BUSY, immediate CANCELLING, saved payload excluding unsaved changes, rerun with new identity/fingerprint, natural task release. CANCELLING and release do not prove a CANCELLED terminal outcome: the tested full path ended FAILED before stage execution.

| Advanced capability | Beta classification |
| --- | --- |
| Analyze Current live/unsaved capture | DEFERRED_D5 |
| Full Accept Saved end-to-end | DEFERRED_D6_ARCHIVE; ARCHIVE rejected before HELLO |
| Formal report delivery/UI and concrete errors | DEFERRED_D6 |
| D_FULL | NOT_DELIVERED / DEFERRED_POST_BETA |

All eight original Editor failures are preserved: unsaved Analyze launch; A full saved completion; A graphical replay; result_ready report; cancelled terminal result; B Baker/Validator rejection; B concrete error presentation; repaired E full saved completion. None is registered as PASS or removed from the failed result. A copy of the original Owner receipt and the scope audit is retained in `.godot/beta-sprint/freeze_20261006/`.

## Minimal Editor UX guard

The original Owner Dock enables Analyze Current and Full Accept Saved when a service/context is available even though D5/D6 are absent. A bounded 4B-local guard is authorized to disable those actions, show `Not available in current Beta tools`, and reject direct UI signal invocation. Existing task status/cancel/release and ordinary authoring controls remain available. The guard must preserve public contracts and full-policy semantics; it does not implement or certify D5/D6.

EDITOR_BETA_UX_GUARD_READY:98db5f1fdef9b396d786225214d62d1216c17e62. Only the Dock and new dedicated guard test/UID changed; the production Dock delta is10 additions/3 removals. Analyze Current and Full Accept Saved stay disabled with the exact unavailable tooltip; direct UI invocation is rejected before service.start. The existing status/cancel/release code is unchanged. No Report button currently exists, so no Report UI was added.

Focused source-bound verification in `E:/godot/worktrees/block-girl-foundation-editor-tools/.godot/beta-editor-guard/`: RED Unit28 checks with18 expected guard failures; GREEN Unit28/0 with explicitly declared service_double; GREEN actual Editor12/0 with doubles=[]. Final two runs exit0, stderr0 and no engine errors/warnings. Original69/47-8 full evidence and tests remain unchanged. Initial disposable QA path setup failures and a D3D12 teardown exit were retained; final focused runs use CLI gl_compatibility without changing production renderer/configuration. These guard checks do not certify full acceptance or new worker algorithms.

| Guard Owner path | SHA-256 |
| --- | --- |
| addons/block_girl_level_tools/level_dock.gd | 111bd82c30cc4d9f72d1b74e2fadaa2eab5d965c4256e376e676fa14aabfc3ec |
| tests/foundation/editor/test_beta_guard.gd | d7351423e840710e20afda423db611bf79dd66c9c2e991324e80f76c08074b89 |
| tests/foundation/editor/test_beta_guard.gd.uid | 50d1c5bd1a60ef3f69de53432957d1458fc4273a4c92458e03a30c347ea34f3f |

Guard is committed in the 4B Owner worktree, CLEAN, Push NOT_RUN. The Integration project currently contains no Editor plugin and does not activate one in project.godot; this Owner-local safeguard is not an implicit whole-branch Editor merge or formal delivery registration. The original5a70 remains the requested EDITOR_CORE_PHASE_EVIDENCE.

## Freeze reopening rule

Foundation production is frozen. Reopen only the affected Owner scope for a reproduced Beta blocker meeting the user's criteria:

- P0: data corruption, crash, inability to load/play/save a level, or unrecoverable softlock caused by Foundation.
- P1: incorrect formal Runtime behavior; Saver/Baker/Binder/Quality/Jobs correctness regression; or Beta content that cannot be produced or executed.

Editor polish, D5/D6 completeness, better reports, nicer Dock UX and additional generic tooling stay in [POST_FREEZE_BACKLOG.md](POST_FREEZE_BACKLOG.md). These items do not block Level production, 3D integration, Shell, QA or Beta builds. Missing future stages keep their own classification; they do not reopen accepted Core.

## Product work after Freeze

| Order | Product outcome / handoff | Current state |
| --- | --- | --- |
| 1 | BETA-3D-INTEGRATION-01: L-01 playable 3D gameplay vertical slice | next main milestone; consume current Art in actual main gameplay |
| 2 | L-03 stale hint correction and focused retest | QA P2 feedback; Content Owner fix/retest pending |
| 3 | Inner readability handoff | QA P2 feedback; Art/Content handoff pending |
| 4 | Beta daily builds | continue from accepted playable Content/Shell build; identify exact source each time |
| 5 | Focused QA after every product slice | validate slice gameplay and new integration risks |

L-04 stays NOT_STARTED until both L-01 3D integration is playable and the L-03 hint fix has been retested. Product production uses the existing frozen Foundation APIs. This decision does not claim the 3D slice, hint fix or readability work has already shipped.
