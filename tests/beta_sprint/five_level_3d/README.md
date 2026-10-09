# Formal L04/L05 3D Owner verification

Run only from `E:/godot/worktrees/block-girl-five-level-3d`; every case name must be new. Evidence stays under the Owner docs directory and is never overwritten.

```powershell
./tests/beta_sprint/five_level_3d/run_case.ps1 -Mode entry -Case <new-case>
./tests/beta_sprint/five_level_3d/run_case.ps1 -Mode gameplay -Case <new-case> -Timeout 600
./tests/beta_sprint/five_level_3d/run_case.ps1 -Mode continue -Case <new-case> -Save <actual-gameplay-save-path>
python tests/beta_sprint/five_level_3d/audit_scope.py --output docs/beta-sprint/five-level-3d-owner/evidence/<new-name>.json
```

The default rendering path is the project's shipped Forward+ setting; `-Renderer gl_compatibility` is explicit optional coverage only. PASS requires positive checks, exit 0, zero failures, empty stderr and no source byte drift. Engine, actual HEAD, actual PID, arguments, source SHA, report, stdout and stderr are recorded. The process is launched with WindowStyle Hidden and an actual graphical Godot window/renderer, not headless for gameplay.

Entry expands each approved asset's logical footprint through its actual basis to check native supported cells/platforms and overlap. A legal 2×1 bridge over existing cells is allowed; it cannot add absent support. `-BaselineLayout` constructs the original Batch02 class against frozen resources for the two missing-presentation RED assertions, without editing scene files.

Gameplay retains the original Content Batch02 InputEvent route and helpers; L04 uses the accepted Spawn-Shift route through retained Inner `(0,5)`. Each level completes normal, reset_replay and alternate_camera in Pixel and 3D. Native JSON observations at every commit plus settled actions must match exactly, including world, orientation, link, plate, gate and Goal. This serialization is explicitly P01 native observation JSON, not Foundation `statekey.v1`.

Each new gameplay save explicitly qualifies prior L01–L03, initially locks L05, and uses real L04 Goal to unlock it. Menu input is real mouse InputEvents to the existing Shell buttons. All gameplay movement is real key InputEvents to the original GridInput. No graph/mover/view state is injected; doubles remain empty. Goal callbacks, save checksums, native menu return, same-process Continue and a new-PID Cold Continue are observed.

Historical RED, warning and harness-error cases are retained and classified in the Owner ledger. HumanQA for the new package remains NOT_RUN; stairs clearance PARTIAL_PASS and traversal NOT_RUN are preserved; Foundation and push are NOT_RUN.
