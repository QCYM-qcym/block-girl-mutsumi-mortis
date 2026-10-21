# SPATIAL_FORMAL_CHAPTER_01_CONTINUATION_04_REPORT

Date: 2026-10-21, Asia/Shanghai. Owner: 00 Integration Coordinator.

## Baseline and delivery identity

Repository: `https://github.com/QCYM-qcym/block-girl-mutsumi-mortis.git`.
Worktree: `E:/godot/worktrees/bg-formal01`.
Branch: `feat/spatial-formal-chapter-01`.
Base SHA: `b3f8fa9b8a6562a25342787317f6b42bc6b973b9`.
At admission the real worktree was CLEAN and a live remote-reference query matched this exact SHA. The actual worktree list and repository policies were checked before reusing the three clean Owner worktrees; their old branch references were retained.

The unchanged playable package is `E:/godot/beta-sprint-builds/beta_spatial_formal_chapter_20261019_01`, Build Source `763f0132bc58360fab0e224d0e9c54e00c92ae90`. This stage changes tests, investigation tools and evidence documents only. Its receipt commit does not become a new gameplay Build Source.

Final Commit / Integration Commit, exact remote SHA, normal push result and final working-tree state are recorded after commit in `E:/godot/beta-sprint-builds/spatial_formal_cont04_00_20261021_01/FINAL_DELIVERY.json`. This avoids a self-referential commit identity in a tracked report. The final user handoff states those actual values.

## S05 scope and count reconciliation

The previous 908/3916 and 785/3328 results describe the same authored map and intended search domain, but different completed work and provenance. They must not be added together. Root independently compared complete state dictionaries, ordered edges and policy identities, not just counts.

| Identity or rule | Verified agreement |
| --- | --- |
| Build inputs | 167 copied dependencies match the unchanged Build, Git baseline and previous source binding |
| Map content hash | `5b4de9ca172f39ea537ceb00f3f56074d83f136cc768c66b9f4669764187d2c8` |
| Runtime rules | `foundation.rules.spatial_puzzle.v1` |
| StateKey | Unmodified `statekey.game_feel.v1`, complete formal state; no custom projection or normalization |
| Initial state | Formal `Records.initial_state`, same initial key |
| Search | Breadth first, `FULL_GRAPH`, `UNFILTERED` policy version 1, no disabled mechanics |
| Termination | First Goal is terminal; Reset is a separately sampled lifecycle operation, not a graph edge |

The previous native public Explorer stopped at its 580-second search budget. Its 785 states comprise 80 terminal Goals, 688 expanded non-Goal states and 17 unexpanded frontiers. Its 8,265 evaluations equal 688 × 12 plus nine actions on the interrupted node. All 785 full states match the previous test-orchestrated 908-state graph, and all 3,328 edges match that graph's ordered prefix. No map/version/filter discrepancy was found.

| Exploration product | States | Edges | Remaining frontiers | Provenance |
| --- | ---: | ---: | ---: | --- |
| Previous incremental result, inherited | 908 | 3916 | 0 | Test-orchestrated formal Kernel, incomplete certification |
| Previous formal certification, inherited | 785 | 3328 | 17 | Live public Explorer, budget exhausted |
| This continuation from actual native frontier | 908 | 3916 | 0 | Test-orchestrated formal Kernel, still `complete=false` |

New States / New Edges relative to the previous formal run: **123 / 588**. New unique states / edges beyond the previous incremental candidate: **0 / 0**. This round first expanded all **17/17** original frontiers, then 107 successor frontiers: **124** total expansions and 1,488 action evaluations. Nine interrupted-node evaluations were repeated; one previously saved changed edge was verified and deduplicated. There are 18 fresh JSON/typed-binary checkpoints; historical inputs are unchanged.

The continuation's 360-second search deadline included restoration and checkpointing; guards were 2,500 states / 15,000 edges. Its final checkpoint elapsed field is 181.949 seconds; the post-save search-end observation is 182.151 seconds. It ended by queue exhaustion. Its separate Analyzer still treats this assembled graph as incomplete; its null formal softlock count is not relabeled zero.

Fresh focused work covers eight correct Face Lock arrivals, 16 wrong-orientation non-latching arrivals, off-point and locked World Shift rejection, zero overlapping authored Fork permission cells, and one actual Fall-followed-by-Roll sample. A new seven-step official-spawn trace passes formal semantic validation and LOGICAL_SESSION Replay 7/7. Native Runtime Reset after a 30-step reached-state sample returns to the exact initial StateKey, idle and zero commit count. These are actual scoped samples, not graphical or every-state interruption acceptance. Continuation plus fresh typed-checkpoint read-back: **6,483 checks, zero failures**.

### Single live certification

**S05 State Graph: PASS within the predefined first-Goal-terminal stable-public-action scope.** The independent public Explorer returned `status=0`, `complete=true`, `stop_reason=0`, **908 states / 3,916 edges**, **0 remaining frontiers**, 96 terminal Goal states and 9,744 candidate evaluations. Public Analyzer accepted the same unchanged graph as COMPLETE, checked all 908 nodes / 3,916 edges, and reported **908 Goal-reachable states, 0 unknown states, 0 softlocks and 0 Reset-recoverable-only states**. Root independently compared full states, ordered edges, identity, process receipts and Analyzer output. The assembled continuation remains PARTIAL; it is not rewritten to inherit the live graph's provenance.

Native search elapsed: **552.284 seconds**; Analyzer: **24.721 seconds**; native process: **582.984 seconds**, exit 0, empty stderr, 486 checks and no failures. All engine processes in this stage total **910.835 seconds**, below the declared 1,600-second ceiling. Actual performance was faster than the forecast; no unmeasured cause is asserted. This round totals **6,969 fresh checks / 0 failures**: 6,477 continuation checks, six fresh checkpoint checks and 486 native-certification checks. The continuation's expected exit 3 denotes its explicit incomplete-provenance status; the fresh checkpoint and native certification both exit 0.

| Classification | Certified result and limit |
| --- | --- |
| Goal reachability | All 908 reachable states have a path to Goal; shortest spawn route seven actions. |
| Ordinary dead ends | No non-Goal state lacks a Goal path in this closed scope. Terminal Goals are intended stopping states. |
| Reset-only recovery | Zero in this closed graph. Separate native Reset is a 30-step reached-state sample, not every-state or interrupted-lifecycle proof. |
| Unrecoverable softlocks | Zero under the formal Analyzer's Goal-reachability definition within this domain. No claim about excluded lifecycle states. |
| Mechanism errors / illegal transitions | Zero checked permission, orientation and graph invariant violations; no independent exhaustive oracle for all designer intentions. |
| Unexpected shortcuts | Zero non-Fall entries among 48 edges entering the authored Goal island. This does not certify every possible designer-intent shortcut. |

The live graph also confirms 192 World Shift edges, eight latch edges and 144 Fall transitions (72 explicit Fall and 72 movement-triggered Fall). Its maximum explored depth is 30; rejected candidates are 5,016, no-ops 812, filtered edges zero and Safety-unproven rejections zero. These figures describe this specific map and policy, not all chapters. Detailed check identities, evidence hashes and scope are in [Quality report](quality/REPORT.md), [method](quality/METHOD.md) and [results](quality/RESULTS.json).

The one additional native run was prospectively bounded after the continuation reproduced the old candidate exactly. The candidate has 812 non-Goal states × 12 candidates = 9,744 evaluations. Scaling the prior slower native average (8,265 evaluations / 580.026 seconds) gives about 683.82 seconds, with a further 35–45 seconds allowed for final validation/copying. This justified one 900-second search budget, not repeated open-ended budget increases. Defensive argument copies and additional state/identity validation differ between the public Explorer and continuation orchestration; this is code inspection, not a measured profiler attribution.

The certification uses public `Explorer.explore` from official spawn, an unchanged unfiltered policy, then passes its unchanged live graph to public `Softlock.analyze`. Analyzer budget is 60 seconds; process cap 1,000 seconds. The prospective total engine ceiling is 1,600 seconds. Actual engine time before this run was 327.851 seconds, so even its process cap stays within the ceiling. No second native attempt is authorized or executed. The synchronous public Explorer has no intermediate checkpoint callback; its eventual output remains separate from the 18 continuation checkpoints.

S01–S04 first-Goal-terminal results remain their separately identified historical evidence, not new tests. Post-Goal transitions, busy/cancel combinations, every-state Reset, actual keyboard/GUI input and first-time human understanding remain outside this state-graph certification. Prior 13,307 checks are not included in this round's count.

## Three-file Art source investigation

**Art Resource Audit / Art Recovery: BLOCKED_NO_TRUSTED_SOURCE.** The bounded source search is complete, but the originals were not located. This is a narrower, explicit unresolved-source conclusion; it does not mean every possible source has been exhausted or that differing hashes alone prove damaged artwork.

Source root: `E:/Study/方块娘项目/若叶睦/model/art/production/work/GAME_ART_MECHANICS_BATCH_01`.
Backup root: `E:/Study/方块娘项目/若叶睦/model/art/production/work/GAME_ART_MECHANICS_BATCH_01_SCOPE_RECOVERY_20261013`.
The paths below are relative to these respective roots.

| File | Original SHA256 from historical manifest | Current SHA256 | Candidate backup SHA256 |
| --- | --- | --- | --- |
| `design/states/face_lock_D.svg` | `5482941575c67f1be0b5e83ff0dd3fde067c1b8b4bb31424b7a905d000aaa45b` | `8fe6caa92e1de5db0ea79e3e05b1fd8a341e625b4bb737544b07f8b71ebb14fc` | `8fe6caa92e1de5db0ea79e3e05b1fd8a341e625b4bb737544b07f8b71ebb14fc` |
| `design/states/face_lock_D.png` | `cb619b6d77cc838295fca8c57d36255dbcf4f0280895bda8056819465b680b69` | `f2fa9426f7a27552f2aa91af8714c29ff1cdeed516f78f257ae00ad19511e27d` | `f2fa9426f7a27552f2aa91af8714c29ff1cdeed516f78f257ae00ad19511e27d` |
| `reports/DRAWING_CONTACT_SHEET.png` | `8a503ee044ccbd54210754c840ddb957be6d1bace43096b66f1dfec46b5cc51e` | `30bba2f66d99031b4fb027e9e2f17d0e14136908b58165ee098aeeddfaefcad3` | `30bba2f66d99031b4fb027e9e2f17d0e14136908b58165ee098aeeddfaefcad3` |

The backup is reliable only as the recorded post-incident state; it is not an original recovery source. Original hash manifest SHA256 is `0a4eba41609a75ecda0dbdc33979da543968bf613f3f37a6dba4f77c10f62313`. Its first related committed copy is the post-incident `a851a9189825d2500f94aa275d079e7d63756879`; no independent pre-incident immutable anchor was found.

New investigation inspected **26 ZIP archives / 24,941 members**, 13 Build manifests, 166 source-qualified Art records, 5,240 loose PNG/SVG files, 2,071 archived PNG/SVG files, 70 relevant reachable Git paths and seven related image blobs. There are zero matches to any of the three original hashes. Six same-name files are only current exports and post-edit backups. An expanded exploratory image scan reached its 2 GiB guard and was not counted as complete; the final narrowed Art-loose/Build-archive scan completed within declared limits.

The Asset Manifest and `face_lock_D01.blend` match the historical manifest. They describe pending design-greybox assets, with formal production not started and formal GLB/Godot paths null. The Blender generation log outputs other renders; the separate board-generation recipe does not contain original export bytes. Nothing was opened in Blender, regenerated, reconstructed, restored or overwritten.

Historical SVG layout edits, six-panel PNG corroboration and the current Contact Sheet's 28 matching composite tiles remain inherited content findings. Original/current full-content comparison is still impossible without original bytes. Prior static Build non-reference checks remain bounded static evidence; they do not prove absence of arbitrary dynamic resource loading. Root freshly verifies the retained Build payload independently.

Full source identities, trust limits, generation dependencies, per-file recommendations and bounded search corpus are in [Art audit](art/ART_AUDIT.md) and [source records](art/ART_SOURCE_SEARCH.json). Thirteen key source/current/backup files and 208 source records had no hash drift. Root independently verified the 13 key files and parsed raw/repository evidence equivalence; Git LF versus external CRLF byte identities are explicitly distinguished.

## Input preparation, Human QA and visual direction

Input Environment: **UNKNOWN**. Confirmed Cause: **UNKNOWN**. Graphical Diagnostic: **NOT_RUN**. User Window Modified: **NO**.

At 2026-10-21 07:10:00Z the scoped read-only process snapshot found no Godot-named process and no old PID 32312. It did find a new `codex-computer-use` process, PID 35720; process presence does not establish tool health or explain the historical incident. Native control remains disabled by the active tool contract. Read-only session enumeration showed one active OS session and did not establish an independently controlled test environment. No input, focus change, game launch, unrelated-window screenshot or user-process operation occurred. Later owned headless Quality processes are separate from this snapshot and are not player windows.

The new [correlated one-event protocol](input/CORRELATED_INPUT_PROTOCOL.md), [blank event template](input/EVENT_TEMPLATE.json) and [input audit](input/REPORT.md) now specify target PID/start/window/session identity, dispatch/receipt timestamps, tool acknowledgement semantics, game-side event sequence continuity and six evidence-gap categories. Historical startup logs and transcribed guard errors still cannot identify the cause. These preparation artifacts are not a successful graphical test. Sixteen named historical QA evidence hashes were preserved; the excluded unrelated foreground capture was not opened or published.

Qualified Human Player: **NONE**. Human QA: **NOT_RUN**. First-time Comprehension: **NOT_OBSERVED**. Maintain the existing [playtest protocol](../continuation-02/HUMAN_QA_PROTOCOL.md), [empty session template](../continuation-02/SESSION_TEMPLATE.json) and [execution addendum](../continuation-03/HUMAN_QA_EXECUTION_ADDENDUM.md). A future eligible player must use an explicitly verified new Build and isolated profile. At execution, verify the authorized Build, source/package/manifest and fresh session copy; never inherit the historical template's identity blindly. This future requirement does not require repackaging this evidence-only stage. No timings, predictions, quotations or observations are invented.

Floating Cube: **PENDING_USER_REVIEW**. User Approval: **PENDING**. A opaque coarse material / B inset edge markings / C necessary use explanation remain the existing isolated proposals. No master asset, occluder, walkable face, hidden road or Runtime permission was changed.

## Integration, preservation and unresolved work

| Owner | Worktree | Branch | Accepted commit |
| --- | --- | --- | --- |
| 03 Quality | `E:/godot/worktrees/bg-fsc03` | `test/spatial-formal-frontier-cont04` | `5dfcd0cab9591924fbe175aa8bb350ca2adb486f` |
| 05 Art investigation | `E:/godot/worktrees/bg-art-cont03` | `docs/spatial-formal-art-cont04` | `1cb96ab09af4a9c855ebb76a500e082db366afef` |
| Input / QA preparation | `E:/godot/worktrees/bg-input-c03` | `test/spatial-input-env-cont04` | `3f59169e3d149581ea4466b47e6040c19aad5323` |

All three Owner commits were normally pushed and independently verified against their exact remote branch references. Their worktrees were CLEAN, with zero unpushed commits at handoff. Root accepted them through a normal multi-parent merge without conflicts, preserving all Owner history. Only 23 new files in the assigned continuation-04 documentation and Quality test directory are included; no binary Art, save, cache, secret or unrelated Owner file is part of this delivery.

Integrated verification passed: 72 Quality evidence-file hashes, 167 exact production/dependency hashes and four exact executed harness archive hashes. Delivered harness files are byte-identical after only CRLF-to-LF normalization; original executed bytes remain archived. No gameplay/test semantics changed and no Godot run was repeated for line-ending normalization.

Old Build / QA Evidence / Save Integrity: **verified unchanged within the recorded preservation manifests**. All 1,783 Build payload hashes, the package ZIP identity, watched historical reports/graphs/screenshots, all 1,759 isolated A/B/C preview files, original Build profile absence and all 69 files of the historical QA profile match the admission snapshot. Protected main, release branch/tag and historical experiment refs match. Six delivered JSON documents parse, 33 relative Markdown links resolve, Python helpers compile in memory and Git scope/whitespace checks pass. Production diff is empty. No unrelated full Godot matrix or GUI test was run.

Integration Handoff: **READY for this scoped evidence delivery**; overall acceptance remains PARTIAL. Final normal push and remote-reference verification are recorded in the post-commit external receipt, alongside the final full SHA and CLEAN state. No successful remote delivery is inferred merely from a local commit.

Production Changes: **NONE**. New Build: **NOT_REQUIRED**. New Defects: **NONE_CONFIRMED in the actual checked scope**. This does not classify unknown input cause, missing Art originals or unobserved player understanding as passed. North/East Input P1 and Goal Reset P2 remain historically closed and were not reopened.

main Modified: **NO**. Release Tag Modified: **NO**. Release branch, prior experiment branch, old Owner refs, original Build, QA evidence and saves remain protected. No L01–L05 logic or Foundation code was changed. This is a development-branch evidence delivery, not release approval.

Overall status: **SPATIAL_FORMAL_CHAPTER_01_CONTINUATION_04_PARTIAL**. The following unresolved actions remain separate from completed bounded investigation and test work:

- **05 / source custodian:** supply a named pre-incident package or exact original exports with provenance. Hash and compare them read-only before any recovery decision. If unavailable, a newly labeled reconstruction requires separate explicit authorization; never restore from the post-edit backup as though it were original.
- **00 / 08:** establish supported independent input control, a dedicated test profile/window and an approved correlated game-receipt channel, then execute one bounded diagnostic event. Until then retain UNKNOWN / NOT_RUN.
- **08:** arrange an eligible first-time player and record real observations using the existing protocol. Automated graph/replay work cannot satisfy this dependency.
- **User / 05 / 09:** review existing Floating Cube A/B/C proposals before any formal visual replacement. Traversability remains unchanged.

Root external evidence directory: `E:/godot/beta-sprint-builds/spatial_formal_cont04_00_20261021_01`. Baseline identities, independent count reconciliation, Owner review, integrated preservation and final GitHub receipts are kept there without modifying historical evidence.
