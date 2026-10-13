# SPATIAL-CARDINAL-01 — Runtime Owner handoff

Date2026-10-13, Asia/Shanghai. Worktree:E:/godot/worktrees/block-girl-spatial-runtime-01. Branch:fix/spatial-cardinal-input-01. Base:3d6cad7f7d07c5bcb36e7fd9ab36ef40260ab2d8. Original tree CLEAN; no branch recreation, merge, rebase, reset or other Owner edits. Commit and independently verified remote SHA are returned in the final delivery message.

Stage:INPUT_FIX_IMPLEMENTED / OWNER_SCOPED_HANDOFF_WITH_KNOWN_P2. Acceptance:PARTIAL_PENDING_00. No all-checks-PASS, Graphical, Build or Human QA claim. No GUI launched; every Godot process used --headless/CREATE_NO_WINDOW and an isolated profile. Player's active window/profile untouched.

## Root cause and minimal production repair

Facade independently called frozen generic InputMapper with fixed isometric View. At TOP NORTH/EAST, horizontal and vertical projected tie representatives chose the same u axis family. Opposite pairs still worked, but four WASD keys covered only0/2, leaving v directions inexpressible. On Surface this duplicated the one legal road onto two keys; at Inner Gate/Goal it made the actual v road inaccessible at these two cameras. This is a control-mapping defect, not proof of an irreversible graph softlock, a permission defect or a stale Camera.

Only foundation/game_feel/runtime_facade.gd changed (18 insertions/2 deletions). Its private fixed-view input adapter retains generic validation and A/D tie results. Nonvertical/diagonal/analog input and already-independent W/S results are preserved. Only when both keyboard pairs select one axis family, W/S receive the perpendicular family with its sign taken from the unchanged exact View projection. Every intent still goes to the original request_action/Runtime/Kernel. No road lookup, best-legal-direction fallback, second rule system, new public API or state write.

Generic InputMapper, View basis/project, RuntimeSession, Kernel, Safety, Solver, Replayer, Action/Event/StateKey contracts, Host/Presenter, InputMap, map resources and Save logic remain byte-for-byte unchanged in this diff. Normal semantic actions and their accepted/rejected/error results retain native behavior. Adaptation is confined to the already explicit game-feel opt-in Facade; the generic continuous-camera contract remains frozen.

## Actual RED and final verification

- Initial real Inner RED:473 checks/8 behavioral failures, exit1/stderr0.
- Expanded Surface+Inner RED:833 checks/16 behavioral failures, exit1/stderr0. All four route prefix positions0/1/2/3 and four Cameras used actual saved Gate state reached via official actions; no injected state.
- Corrected same behavioral suite:833/833. All16 position/camera groups expose all4 axes with opposite keys and exactly one legal road; every result equals official Kernel evaluation for its resolved semantic action. Rejection preserves StateKey and commit count; acceptance commits exactly once using the actual native token/generation.

Final snapshot: **4266 behavioral assertions,0 failures**. Seven strict receipts PASS. The final Host strict receipt is **FAILED**, solely because of stderr133 bytes (8 ObjectDB instances leaked at exit); exit0,482 assertions,failures=[],source_drift=[]. Never promote this to a clean Host receipt. All8 final manifests fingerprint the same shipped source, including inherited Foundation test dependencies.

|Final evidence|checks|strict status|exit|stderr bytes|
|---|---:|---|---:|---:|
|cardinal_final01|833|PASS|0|0|
|frames_final01|2200|PASS|0|0|
|host_final01|482|FAILED|0|133|
|mapper_final01|330|PASS|0|0|
|facade_final01|63|PASS|0|0|
|curve_runtime_final01|96|PASS|0|0|
|spatial_runtime_final01|26|PASS|0|0|
|saved_final01|236|PASS|0|0|

Exact commands, source/engine SHA256, timestamps, PID and profiles are in evidence/<case>/process.json. Runner entry:python tests/beta_sprint/spatial_runtime/input_acceptance_01/run.py <case> <res://test>. Actual Godot4.7.2.stable.steam.ed1daf0bf. Normal frame guard:--max-fps60 --quit-after10000; Host has an explicit150second timeout guard and per-transition5second condition deadline. Guards are cooperative, not forced termination of synchronous hangs.

Frame suite covers all24 right-handed signed face frames x4 quadrants: valid generic horizontal/vertical mapping, distinct cardinal families, exact opposite pairs, visual projection signs, magnitude independence, unchanged A/D and noncardinal results, invalid input/frame rejection, frame immutability. No legality algorithm double.

Host suite is **headless natural lifecycle evidence**:64 actual request_move attempts across Surface/Inner source/gate/goal states; real saved Map->Host->Facade->Presenter frame updates and Shift Tween. Accepted Roll begins ROLL, emits real local transition_started token/generation/is_global, naturally completes with one commit; duplicate late actual completion identity is ignored. Rejection creates no authoritative transition or StateKey change. Camera doesn't rotate the physical pose. This is not real keyboard dispatch or rendered Graphical QA.

Saved migration regression236 uses immutable09 scenes and oracles: all5 whole canonical levels/hashes, witness action states/StateKeys/orientation, Reset and SourceMap agree. Generic Mapper330 literal goldens including old tie semantics pass. Real Facade63, Curve Runtime96 and Spatial Runtime26 preserve Fall/Roll/Shift, Busy/Pause/Reset, permissions and lifecycle negatives.

L01–L05 affected-scope audit: existing Shell LevelAdapter/mover route uses the legacy implementation, not this opt-in Facade. Their code/data/recipes and generic Mapper are unchanged. Full legacy native playthrough and rendering are NOT_RUN because the GUI remains reserved; no new proof claimed for those historical routes.

## Failed setup attempts retained

host_green01:0 checks, normal frame-count guard stopped the natural suite early, exit0/stderr133; FAILED, not behavioral RED. Runner guard was corrected without animation or test-expectation changes. host_green02 subsequently had482 checks/exit0/empty stderr; this earlier clean run is preserved but does not replace host_final01.

saved_reg01:0 checks, missing user arguments caused out-of-bounds in the unchanged09 test; normal guard ended the process, no force kill. Runner now supplies official output/profile arguments; saved_final01 passes236. No failed receipt overwritten or relabeled.

## Review and explicit disposition

Fresh read-only reviewer cardinal_input_final_review:0 Critical,1 Important validation finding,0 Minor; no production mapping issue. The Important finding is exactly the final Host exit warning.00 explicitly permits non-blocking P2 disposition, keeps FAILED evidence, forbids shared Host/scope expansion or chance-based repeated runs, and will produce clean Menu+Input.parse_input_event acceptance evidence after integration. Root cause of ObjectDB warnings remains NOT_DETERMINED; do not attribute it to this input change.

Reviewer boundaries retained: no final leak-free Host certification; no GUI keyboard events/rendered readability/player comprehension or overhead-object diagnosis; no full L01–L05 playthrough/Combined graph/Integration/Build/Human QA certification. Remote verification is performed separately after this report is committed.

## Handoff

00 consumes only this Owner commit, runs the same existing native-UI headless suite (its612-check/64-key RED preserved), integrates through its branch and creates a new isolated Build when appropriate. True rendered/player acceptance remains PENDING until the user ends the current play session. Do not alter generic tie contract, View, map roof or mechanisms to compensate. The separately reported overhead block is neither identified nor fixed by this cardinal-input work.
