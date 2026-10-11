# Spatial Puzzle Batch 01 — isolated QA handoff

This is the four-mechanism experiment batch plus **六面归位**, not L06–L08 or approval of the entire Beta. Human QA remains **NOT_RUN** until an actual tester supplies evidence.

## Identity and launch

The immutable package BUILD_IDENTITY.json records the exact source commit, per-file SHA-256 and project identity. Open project/project.godot in Godot 4.7.2 and press F5, or run play.ps1. The Main Scene is experiments/spatial_puzzle_batch_01/ui/main.tscn. Its unique project name isolates direct F5 user data; play.ps1 additionally isolates APPDATA/LOCALAPPDATA/TEMP under that new package's qa-profile. No old package, screenshot or save is reused or overwritten.

Choose any of the five independent menu entries. WASD/arrows roll; Q/E changes camera; Space explicitly requests World Shift; F always sends the same formal U_NEG move at a marked edge; R resets; Esc pauses; H optionally shows an advanced hint. Six numbered physical cube faces retain their identities during Camera/Shift. Continue restores the most recent experiment's **start**, not its mid-puzzle latch/orientation. Existing SaveStore owns persistence. Original five-level Shell remains accessible from the menu.

## Human checks requested from 08

- Gate: leave the marked point and confirm Shift rejection; stand on it and Shift. In Face Lock/combined, try locked and unlocked gate states.
- Loop: compare two routes to the same platform and a full return loop; observe genuinely different numbered faces without revealing a route beforehand.
- Face Lock: wrong face arrives without activating; correct physical face down latches once; leaving preserves it; Reset clears it.
- Fork: same marked source edge/input in two cameras leads to two distinct formal targets. Try an ineligible camera. Explore the reversible branch and return to Goal.
- 六面归位: normal complete route, Reset and complete again, then an alternate camera/branch order. Check latch → explicit Shift → Fork → Forward Drop → Roll → Goal.
- UI/lifecycle: Pause/Resume, reset during motion, repeated input, menu return, process exit and Cold Continue. Test failures without editing a save to simulate progress.

Record actual viewport sizes, input method, source identity, screenshots, and observations of feedback/learning. Automated replay and injected InputEvent tests are not human tests. A previously informed player cannot establish first-time comprehension. If no suitable player is available, keep that category pending.

## Scope and known limits

Experiment geometry is isolated primitive 3D and approved existing UI assets; no new formal Art replacement. Floating dark roofs are real nonwalkable Shadow occluders, not hidden helper platforms. Fixed F is a laboratory edge-action shortcut; ordinary movement retains camera mapping. Some hints and marker readability still require human evaluation. Reduced Motion is a current menu-session choice; no new global settings system is introduced.

The old five-level puzzle data and SaveStore source remain unchanged. Foundation edits are the authorized opt-in gate/latch implementation and affected consumers. No main/release/tag changes or push. STAIR_CLEARANCE remains PARTIAL_PASS and STAIR_TRAVERSAL NOT_RUN.

Measured test results and exact evidence layers are in TEST_REPORT.md. The source worktree retains raw attempts including RED and timed-out exhaustive searches. Those attempts are not converted into passes.
