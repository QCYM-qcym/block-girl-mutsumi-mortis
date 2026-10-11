# Spatial Batch 01 Full Development — QA handoff

This is an isolated four-mechanism prototype plus 六面归位, not a release or full Beta QA approval. Human QA and first-time comprehension remain NOT_RUN. The package BUILD_IDENTITY.json is the authoritative source SHA and per-file identity; the post-build RECEIPT.json in the delivery repository records measured package results.

## Launch and isolation

Requires Godot 4.7.2. Run the new package play.ps1, or open project/project.godot and press F5. Main Scene: experiments/spatial_puzzle_batch_01/ui/main.tscn. Project name is Mutsumi Veilshift - Spatial Full Development 20261012. Direct F5 has a new user-data identity; play.ps1 additionally isolates its profile under this package. Never reuse old QA saves or overwrite old packages.

The menu exposes World Shift Gate, Orientation Loop, Face Lock, Perspective Fork and 六面归位. WASD/arrows roll, Q/E camera, Space explicitly requests World Shift, F requests the same formal U_NEG edge move, R Reset, Esc Pause, H optional hints. The original five-level Shell is accessible. Continue restores the most recently selected experiment START through existing SaveStore; it does not restore mid-puzzle orientation or latch state.

## Requested human checks

- Gate: compare a marked permitted point with a forbidden point; check locked/unlocked conditions and explicit Space input.
- Loop: compare two routes arriving at the same position with different physical face orientation, then a closed loop and Reset.
- Face Lock: arrive with wrong face without activation, then correct local face down; activation should occur once, persist on leaving, and clear on Reset.
- Fork: use the same source edge/input in EAST and SOUTH to select distinct targets; NORTH/WEST remain rejected. Recover from the alternate branch to Goal.
- Combined: complete the latch → Shift → Fork → forward/drop → Roll → Goal route, Reset and retry, then change camera/branch order.
- Presentation: hear Roll/Shift/Fall/Landing/lock cues, check pause and return, held input and Reset during motion. Verify no old callback produces sound or completion after cancellation.
- Save: exit the actual process, relaunch, Continue to the correct lab start. Do not edit saves to simulate success.

Record actual viewport, source SHA, input method, screenshots and observations. Automated InputEvent injection and TraceReplayer are not human testing. A player who knows the routes cannot establish first-time comprehension.

## Known scope limits

Experimental BoxMesh and six numbered face marks reuse existing approved resources. No new formal Art or R02/R03 native face symbols are adopted. Dark roofs are real nonwalkable Shadow occluders. Yellow indicates an authored candidate target, not current Runtime eligibility. The latched Face Lock marker says activated without retaining target identity; wrong-face accepted movement has no separate failure-reason text. These readability details require human assessment.

Reduced Motion remains the existing menu-session setting. No second SaveStore, AudioManager or persistence system was added. STAIR_CLEARANCE remains PARTIAL_PASS; STAIR_TRAVERSAL remains NOT_RUN. Combined current complete-graph/Softlock census remains NOT_RUN; selected real routes, current Solver/Safety witnesses and Replay are measured separately.

See [test report](TEST_REPORT.md), [03 matrix](../quality/full-development/MATRIX.json) and [support audit](SUPPORT_AUDIT.json). Raw execution receipts remain in the source repository; package excludes raw evidence/profile directories.
