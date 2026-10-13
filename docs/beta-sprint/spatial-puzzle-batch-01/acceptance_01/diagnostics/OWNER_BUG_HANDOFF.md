# SPATIAL-CARDINAL-01 — 00 → 01

2026-10-13. User reports Surface overhead cube inaccessible and Inner NORTH/EAST cannot move. Map not explicitly confirmed, but active process targets isolated accepted Build; latest profile recent=world_shift_gate_lab. Separate overhead concern pending visual identification.

Real reproduction in gate_probe.gd: official saved Map/Baker → spatial Host → Facade.request_move screen vectors → natural Presenter completion. No doubles, injected state, manual completion or graphical/Human PASS. Run process.json: exit1,32 direction attempts,4 camera/location groups with zero legal directions. Gate and Goal Inner positions at NORTH/EAST map W/A/S/D onto only axes0/2; SOUTH/WEST cover all4. Actual rejected code2000, no StateKey change. Host issues=[]; 8 ObjectDB exit warnings retained, not clean stderr.

Hypotheses: (1) generic mapper's exact projected diagonal tie selection collapses perpendicular keyboard axes; (2) View basis disagrees with actual face frame; (3) stale Camera/lifecycle affects mapping. Probe is repeatable; inspect mathematical directions and existing contracts before changing implementation. Rule-action witness still passes; earlier action-API routes did not exercise keyboard mapping.

Requested minimal fix: make fixed-view cardinal gameplay input expose all four independent/opposite directions while retaining official Runtime permission checks and exact current StateKeys. Do not change approved puzzles, source/target, map roof, Shift/Fall/Safety/Kernel, generic frozen InputMapper tie contract, or authoritative View projection to hide the bug. Opt-in facade input adaptation may be appropriate; final design belongs01. If scope requires a real shared contract change, report exact conflict instead of silently changing it.

Verification: failing real regression first; all4 quadrants, cardinal uniqueness/opposites, affected face orientations; actual Gate Inner NORTH/EAST move with real accepted transition; invalid edges still reject; Camera never changes Orientation; formal solution StateKey parity; existing Roll/Fall/Shift and legacy mapper tests focused. 00 reruns natural Host probe and actual UI input on isolated new Build after delivery. Grade P1 controls functional regression, workaround camera-dependent; final severity subject to triage. Does not prove unrecoverable state-graph softlock.

Owner isolated branch recorded in OWNER_SCOPE. Only scoped input adapter/test/report changes. Commit, ordinaryPush ownbranch, remoteSHA verification, handoff. No UI/Art rebuild, no main/tags/old QA write.
