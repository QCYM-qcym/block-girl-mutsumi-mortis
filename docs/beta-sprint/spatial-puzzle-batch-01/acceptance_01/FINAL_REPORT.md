# SPATIAL_PUZZLE_BATCH_01_ACCEPTANCE_REPORT

2026-10-13 · 00 Integration · Technical fix delivered; overall acceptance PARTIAL.

| Field | Actual |
|---|---|
| Build Source / tested integration | `0bb0e01742eacf12272956111cd6b86fdc74f819` |
| Human QA | PARTIAL_USER_FEEDBACK on previous Build; new Build NOT_RUN |
| World Shift Comprehension | Space at switch point reported working; unaided rule comprehension NOT_VERIFIED |
| Orientation Loop Comprehension | NOT_VERIFIED |
| Face Lock Comprehension | NOT_VERIFIED |
| Perspective Fork Comprehension | NOT_VERIFIED |
| Combined Puzzle | Selected route historical PASS; independent human completion NOT_VERIFIED |
| Complete State Graph | PARTIAL overall; GOAL_TERMINAL_FORMAL_ACTION_API exhausted PASS |
| Reachable States | 908;3916 edges;96 Goal terminals;812 non-Goal recoverable;frontier0 |
| Softlocks | 0 in this exhausted domain;0 Reset-only;post-Goal expanded domain UNKNOWN |
| Unexpected Shortcuts | No bypass of inspected required cuts; arbitrary design-intent completeness not asserted |
| Design Findings | Input defect and roof readability observation; H1–H6 NOT_OBSERVED; Obsidian mirrored |
| Art Review | PARTIAL prototype review; formal unapproved assets PENDING_USER_REVIEW |
| P0 | 0 confirmed in this acceptance |
| P1 | 1, SPATIAL-CARDINAL-01 code fixed; OPEN_PENDING_GRAPHICAL_HUMAN_RECHECK |
| P2 | 4 registered in this scope:3 Art readability +1 existing ObjectDB lifecycle; roof feedback separately UNTRIAGED |
| P3 | 0 confirmed in this scope |
| New Build | `E:/godot/beta-sprint-builds/beta_spatial_acceptance_input_fix_20261013_01` |
| Launch | New Build `play.ps1`; Godot4.7.2 required, source-playable, isolated qa-profile |
| QA handoff | Sent to08; metadata/background only while user plays old Build |
| Graphical | NOT_RUN_USER_RESERVED_GUI |
| Push / remote / final working tree | Final receipt commit verified in00 handoff; Build Source previously pushed and exact remote verified |

## Focused fix and evidence

Confirmed Root cause: fixed-isometric projection ties at NORTH/EAST mapped horizontal and vertical cardinal input to the same axis family. At Inner Gate this made all four keys reject despite legal formal-action routes.01 changed only `foundation/game_feel/runtime_facade.gd`: retain existing validation/A-D mapping and choose a perpendicular axis for W-S only when the fixed projection collapses them. This does not authorize nonexistent roads or change puzzle rules.

Owner fix `3a87dfbab4d30753f53b2bf4f88862854a91d328`; normal production merge `31be5bd8de001bc216fbb3dab2106c36f2316d62`. Four Gate positions ×four Camera quadrants ×four keys through real Menu/Input.parse_input_event and natural Host completion. [RED](../evidence/acc_keys_red04/process.json):612checks/12 failures. [Source GREEN](../evidence/acc_keys_green01/process.json):612PASS. [Actual package GREEN](../evidence/acc_pkg_keys01/process.json):612PASS,exit0,stderr0,doubles[],source_drift[]. Headless engine execution does not prove rendered visibility or physical human keyboard play. Earlier harness setup failures remain in evidence.

Owner final4266 behavioral assertions had no behavioral failures; host_final01 emitted8 ObjectDB leaks/133 stderr bytes and failed its strict gate. Seven other final cases strictly passed. This existingP2 is not concealed by earlier clean runs or00's clean612checks. No unrelated full Foundation rerun.

## State graph and source compatibility

[03 report](../quality/acceptance_01/FINAL_REPORT.md) binds196 final assertions, official Solver/Safety/LogicalReplay,20-minute/5000-state/30000-edge budget; actual908states and3916edges complete without budget exhaustion. Same-live-graph SoftlockAnalyzer finds all908 Goal-reachable.13 independent Safety queries/15 assertions are samples, not3916 independent Safety calls. Formal Explorer ends at Goal; actual Runtime can move after Goal, so whole Runtime state-space coverage remains UNKNOWN. No alternative BFS or test doubles replace formal algorithms.

[Build validation](BUILD_VALIDATION.json) compares2151 graph-tested source files: only the00 runner/packager and input adapter differ. Formal action rules, graph algorithms and maps are unchanged, permitting reuse of the stated action-domain graph, not an extension to keyboard/post-Goal claims. Only production diff since d3b1314 is the P1 Facade input adapter. Kernel, RuntimeSession, generic mapper, View contract, Solver/Safety/Replay, Save, L01–L05/L06, project configuration and frozen Art sources remain unchanged.

## Human and design boundaries

Five append-only anonymous feedback records are in [human_qa](human_qa/USER_FEEDBACK_05.md). Suitable players were offered, but actual observer/player eligibility and first-time metrics were not verified. No times, prediction counts, completion or cognitive success are invented.04 feedback confirms both worlds and north/east.05 confirms the detached overhead gray-blue object is the official nonwalkable Surface roof occluder. Trying to climb it is readability feedback, not a newly established traversal bug.00 explained its purpose after confirmation; later roof understanding is assisted. Other blind tasks are not automatically invalidated. [13 clarification](../design/acceptance_01/ROOF_IDENTITY_CLARIFICATION.md) and Obsidian retain original hypotheses and unknowns.

## Build preservation and remaining work

New ZIP SHA256 `28bdef16329f8404c7e71851136fb09baa98c36066b5af8bc49f264f43b81285`;1641 manifest files verified. Previous Build source59531ad retains1561/1561 matching files and ZIP SHA256 `4d030c8f75f9e091bf9e775e8ffb4f35d0a92bfca98c11cdacd325e7e2b0b7b4`. No old QA directory, screenshot, log or player save replaced. New package embeds the truthful pre-package source receipt; this post-package report supersedes its PENDING packaging field without changing immutable package bytes.

Pending: actual new-Build graphical/key recheck then08 P1 closure; eligible first-time player observations; untriaged roof readability; broader post-Goal graph domain if required. No completed Beta/release claim. No main/release/tag writes.

## External Art scope deviation

05 mistakenly resumed an older external design-production task during this acceptance. [Scope deviation](../art/acceptance_01/SCOPE_DEVIATION.md) records61 paths written. Two script expressions were restored and the newly created note backed up then removed.59 regenerated exports lack trustworthy pre-edit hashes and remain unreconciled; modified-state backup exists. EXTERNAL_SCOPE_RECOVERY=PARTIAL. These files were not imported into this game Build; frozen masters and game QA packages were not affected. This is an execution error, not an approved Art fix; no blind regeneration or overwrite was used to claim restoration.
