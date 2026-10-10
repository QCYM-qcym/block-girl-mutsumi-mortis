# PFALL_FORWARD_THEN_DROP_TO_YELLOW_FIX_01 — read-only Map audit

Audited exact Integration commit `44f3d3db190b616f4121516576337ed8d40f6ae4`. Map/Host/Foundation/fixture files used by the process were matched byte-for-byte to that commit before execution; SHA-256 inventory and zero post-run drift are in run_01/process.json. No map, shared source, QA package or historical evidence was edited. Only this new Owner09 audit directory is added.

## Exact geometry (doubled coordinates)

| Entity | MAP A | MAP B |
|---|---|---|
| Source Cube center2 | [0,4,0] | [0,4,0] |
| source/TOP face4 Anchor2 | [0,5,0] | [0,5,0] |
| target Cube center2 (original yellow location) | [-6,0,8] | [-6,8,8] |
| target/TOP face4 Anchor2 | [-6,1,8] | [-6,9,8] |
| Target actor-center2 | [-6,2,8] | [-6,10,8] |
| blue_reference center2 | [-8,0,8] | [-8,8,8] |
| exit/TOP Anchor2 | [-4,1,8] | [-4,9,8] |

All are Surface. Both target normals are +Y. Four actual Cubes are present; blue_reference has no walkable Face and actual Safety rejects it as standing support. The sole connection targets target/TOP, never blue_reference. Goal is distinct exit/TOP. A real height delta is -2 world units, B +2.

Schema3 / foundation.game_feel.v2 / foundation.rules.game_feel.v2 is actually baked. source_edge=2 U_NEG is world -X because TOP.frame.u=(1,0,0). Registered departure [0,6,0]→[-2,6,0] therefore moves one world unit along the actual input edge, on the support plane. A cubic controls: [-2,6,0],[-4,6,0],[-6,4,8],[-6,2,8]; B: [-2,6,0],[-4,6,0],[-6,14,8],[-6,10,8]. Exact canonical endpoints are retained. Camera=EAST1 and Fall orientation policy=PRESERVE.

## Input meaning, measured through formal InputMapper

Pinned Host maps A/Left to Vector2.LEFT, D/Right to RIGHT, W/Up to UP, S/Down to DOWN. At EAST on this TOP frame, actual mapper results are A/Left and S/Down → U_NEG2; D/Right and W/Up → U_POS0. Thus “forward” here is the authored U_NEG edge, not a general claim that W means forward. No input mapping was changed.

## Actual fresh verification

PID11456, isolated profile, headless, 29 checks / 0 failures, exit0, stderr empty, doubles=[]. Actual Baker, Geometry, InputMapper, continuous curve Safety, Solver and logical Runtime TraceReplayer were executed against pinned production code. Both sweeps return SAFE. Both Solver traces are exactly MOVE U_NEG2 (authorized Fall) then MOVE U_POS0 (ordinary Roll), and actual Runtime Replay matches both steps. First landing is target/TOP orientation0; final Goal is exit/TOP orientation12. Full traces, canonical StateKeys and native results are retained in run_01/report.json.

Level hashes: A `8e84f99421d0bac47ec175dbec2f19a30d704644fd86d6af70c2bbf0df7104b5`; B `331725e09d6af1ee57193f540c7e1d2487f469e8ea947ec54553ecb363f977ce`.

Conclusion: no current author target/Anchor error found; no map correction needed. New-rule Roll succeeds with the actual blue_reference entity, unlike the intentionally preserved earlier baseline-v1 rejection. This is a new pinned Integration result, not an overwrite of historical evidence. Continuous animation timing, visual forward/readability and natural graphical trajectory are outside this headless audit; 00 retains the graphical desktop and must assess those independently. Push NOT_RUN.
