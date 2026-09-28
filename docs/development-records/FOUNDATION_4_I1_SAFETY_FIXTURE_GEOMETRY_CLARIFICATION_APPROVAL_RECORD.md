# I1 Safety Fixture Geometry — Approval Record

Status: APPROVED

Clarification path: `docs/development-records/FOUNDATION_4_I1_SAFETY_FIXTURE_GEOMETRY_CLARIFICATION.md`

Clarification SHA-256: `A6E72C5063BCDD675E47D9CC35FA3B6449C2C14B3649803767F0441FD9328295`

Approval authority: explicit user approval of this exact content in the current conversation. The clarification body remains byte-for-byte unchanged.

## Approved scope

- Classification: I1_FIXTURE_CONTRACT_MISMATCH.
- Production regression: NOT_PROVEN. The original RED does not prove a production Safety algorithm error.
- Original fixture: floor=(0,0,0), middle=(1,0,0), exit=(2,0,0).
- Original Before MOVE: REJECTED / issue1601 / entity=exit; Safety UNPROVEN. Reason: Roll swept enclosure is not separated from an unrelated Cube.
- Approved fixture: floor=(0,0,0), middle=(1,0,0), exit=(3,0,0).
- Approved Before MOVE floor→middle: APPLIED / Safety SAFE / issues=[] / transition_started=YES, as established by the recorded formal candidate probe.
- Spawn remains floor/TOP; Goal remains exit/TOP; middle.TOP.walkable initially true.
- Only Before→After gameplay edit: middle.TOP.walkable true→false. Positions, Spawn, Goal, other Faces, Runtime policy, Safety rules and the fixed MOVE remain unchanged between runs.
- The original exit=(2,0,0) remains negative-control evidence. Future formal I1 uses exit=(3,0,0), without toggling exit during the test.

I1 proves Saved Authoring→Snapshot→Bake→Canonical→Runtime behavior propagation. It does not require a complete Solver proof, complete Goal route, zero Softlock, full Intent proof or full Acceptance PASS. The gap before exit is permitted; no added Cube or production workaround is authorized.

Production code changes: NONE. Safety, RuntimeSession, Kernel, Reader, Baker, D_HOST and all 4A/4B/4C/4D production remain unchanged. Design Spec, Tool Contracts and Plans remain unchanged.

## This approval commit

Only the exact clarification and this independent approval record are submitted. Existing uncommitted I1 test and maps/a_empty files are preserved without edits. The approved coordinate is not applied to the fixture in this commit.

CONTRACT_MISMATCH: RESOLVED_AT_I1_FIXTURE_LEVEL
I1: READY_TO_RESUME (not GREEN or complete)
Push: NOT_RUN

Recorded at: 2026-09-29T00:54:41.479900+08:00
