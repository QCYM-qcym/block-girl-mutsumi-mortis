# SPATIAL_PUZZLE_ACCEPTANCE_CONTINUATION_REPORT

2026-10-13 · 00 Integration Coordinator · Focused QA / Resource Protection.

| Field | Actual |
|---|---|
| North/East Input | PASS — independent real Windows graphical recheck |
| P1 | SPATIAL-CARDINAL-01 CLOSED by00 after08 evidence review |
| World Shift | PASS, actual Space transition through formal Host and Runtime |
| Floating Cube | READABILITY_REVIEW_READY; proposals unimplemented/PENDING_USER_REVIEW |
| Art59Files | Investigation verified;56 original-hash matches,3 differences;RECOVERY_PENDING |
| State Graph | PARTIAL overall;908/3916 Goal-terminal domain retained;bounded post-Goal samples PASS |
| Human QA | NOT_RUN this round; previous PARTIAL_USER_FEEDBACK retained |
| New Defects | 1 P2:QA08-C02-UI-RESET-LABEL-01;0newP0/P1 |
| Build | Existing beta_spatial_acceptance_input_fix_20261013_01, unchanged |
| Build Source | 0bb0e01742eacf12272956111cd6b86fdc74f819 |
| Integration baseline | 295a4702aeb17d6fced11cfdaa221e0ffa90dd12 |
| New Build | NOT_REQUIRED: no production change this round |
| Final Integration Commit / Push / Remote | Full receipt commit and independently verified remote SHA in00 final handoff |

## A — Graphical input recheck and P1 disposition

[08 report](qa08/CONTINUATION02_GRAPHICAL_QA.md), [structured results](qa08/CONTINUATION02_GRAPHICAL_QA.json), [external evidence manifest](qa08/EVIDENCE_MANIFEST.json), [00 disposition](DISPOSITION.json).

Godot4.7.2 real Windows/D3D12 Forward+ render at1280×720. Main run1355 assertions plus23 focused followup assertions;0failures;both observed natural process exits0.224 original PNGs,16 visual contact sheets;261 external files independently hash-verified by00. Initial launcher exit=null is retained; process_wait attached a live process handle and observed natural exit0. Actual godot.log corroborates engine/GPU and completion; empty redirected stdout alone was not accepted as proof.

Four locations (Surface source/gate,Inner gate/Goal) ×four Camera×WASD =64attempts,16legal Rolls and48normal edge rejections.00 independently recomputed each group's four unique axes, at least one legal move, accepted StateKey change/rejected StateKey preservation, and settled IDLE state.00 inspected NORTH/EAST source and Inner-gate contact sheets;08 inspected all16. Records include actual face,action,result,pre/postStateKey and visual pose. Input.parse_input_event passes through real Menu/Host; position preparation uses formal actions, natural animations, no injected gameplay state or manual completion. Physical OS keyboard and first-time Human QA remain NOT_RUN.

Focused Space Shift,Camera E traversal,EscPause/Resume,FaceLock wrong/correct face,PerspectiveFork camera rejection/accepted targets,Fall→Roll→Goal,Reset during actualFALL and oldcallback immunity passed. Q-alone,other resolutions,ColdContinue and full five-map human play were not tested. This supports closure of the cardinal input defect only.

New P2: after Gate D→Space→S reaches Goal,R resets actual player/Runtime toSurface/source but Shell goal_seen/title still says completed. Mouse Reset clears it. Captured again on a fresh followup profile. Owner07;OPEN_BACKLOG. Actual gameplay ResetPASS;completion-label ResetFAIL. No production UI fix in this resource-protection task. ExistingP2 items and roof readability were not silently closed.

QA root: `E:/godot/beta-sprint-builds/spatial_continuation02_08_20261013T135945Z`. OriginalBuild plus QA copy1641manifestfiles match;1489package source blobs independently match exact committed Build Source. OriginalZIP hash28bdef16329f8404c7e71851136fb09baa98c36066b5af8bc49f264f43b81285 retained. Only approved anonymous reports/manifest copied toGit; screenshots/rawlogs/harness/profiles retained externally. Old user process/saves/evidence untouched.

## B — Roof readability proposals, not approved implementation

[09 semantic review](../map/continuation_02/ROOF_READABILITY_REVIEW.md), [05 visual options](../art/continuation_02/ROOF_VISUAL_OPTIONS.md).

Roof is Surface nonwalkable on all six faces and supplies the current gate's required shadow. Removing it,changing Face permission or logical occlusion would change the puzzle. Its cube silhouette/top surface plausibly explains the player's platform interpretation; that observation is recorded, not a new traversal-rule defect. Gate/source also occlude light, so “all occluders are nonwalkable” would be wrong.

Minimal proposals for user review:

1. Preferred shared direction: opaque,low-frequency coarse/slanted surface pattern on roof top and sides,distinct from smooth roads. Preserve geometry,shadow and Runtime state. Avoid six-face symbols or walkable-edge highlights.
2. Art comparison: markings inset within the existing sealed edges,without protruding ledges/transparency. Greater risk of resembling FaceLock/PressurePlate;needs comparison before adoption.
3. Map alternative: neutral “遮光体·不可站立” identity and optional H explanation of shadow,placed away from the roof–gate gap. Risk:extra text/clutter/assisted understanding. Any readiness feedback must consume official Runtime eligibility.

Do not implement or combine by default. Full transparency is discouraged because it could appear to pass light while formal shadow remains. No textures,meshes,lights or maps were changed. Future approved proposal needs four-camera/small-resolution comparison and a new unprompted player observation; no readability improvement rate is claimed now.

## C — External Art integrity and recovery boundary

[05 investigation](../art/continuation_02/EXTERNAL_EXPORT_INVESTIGATION.md) includes exact59-file audit and recovery proposal.

Original local PACKAGE_SHA256 manifest covers59/59exports.56current exports equal original hashes;3changed: design/states/face_lock_D.svg,design/states/face_lock_D.png,reports/DRAWING_CONTACT_SHEET.png. All59exist and have structurally readable formats;no confirmed missing/corrupt current export. Full177-entry original package manifest has174matches/3differences;restored generator script matches original hash.4.blend files match without launching Blender. Local manifest provenance limits are documented;not a remotely signed release claim.

All59current exports match the post-edit backup,which remains an incident-state backup,not originalversion. Its HTML references one description file outside the partial backup;the working package contains it. Backup therefore is not a complete standalone offline gallery. Search of4558PNG/SVG files and214image members in4ZIPs found no original bytes for the3changed targets within the inspected model tree. This is not proof of permanent loss.

No restoration performed. Exact recovery scope is only those3files;56unchanged andrestoredgenerator must remain untouched. Prefer a trustworthy original copy matching each originalhash. If unavailable, rebuilding into a fresh candidate directory requires newauthorization;only after inspecting candidatehashes/differences and receiving replacementauthorization may original paths be changed. No reset/clean/reexport/backupdeletion. Current originalsandbackups remain preserved.

## D — Supplemental state verification

[03 bounded report](../quality/continuation_02/FINAL_REPORT.md). Official Explorer treatsGoal as terminal and exposes no public postGoal-expansion switch. No fakeGoal/privateports/secondBFS used.8actualGoal representatives across4cameras/8orientations are reached through real Runtime requests.32postGoal move attempts produce8departures/24rejections;all8canreturn to identicalGoal.32independentSafetyqueries,16Resetsincluding8pendingcancelidentities,9formalLogicalReplayruns/136matchedsteps.2225assertions PASS with exit0,stderr0,doubles[],source_drift[].3metadataUnitmethods reported separately.

Runtime-captured witnesses are formally validated and not called Solver traces.65observedkeys are samples,not a stategraph coverage denominator.Original908states3916edges96Goalterminals0softlocks remain unchanged and were not rerun. FullpostGoalstate/edge/softlock denominator UNKNOWN;overallPARTIAL.

Harness failures preserved and scoped adapters fixed;no confirmed newRuntimebug.03 briefly resumed an old task,writing4untracked nonproduction game-feeldocuments and running52oldPythonmethods before correction. Paths are recorded in03PROGRESS.md;excluded from integration,preserved without automatic deletion. Current03delivery is restricted to continuation_02tests/docs.

## Integration protections

Only scoped review/test/evidence files received. No productionGameplay,Runtime,Save,Art source,approvedmap,main orReleaseTag modifications. Build remains immutable. External resource snapshots are compared before/after;normalOwnerbranches and00integrationbranch use nonforcedPush and exactRemoteSHAverification. No newBuild orrelease publication is implied.
