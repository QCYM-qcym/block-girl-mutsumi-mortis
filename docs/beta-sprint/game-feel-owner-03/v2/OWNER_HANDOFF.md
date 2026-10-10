# PFALL v2 Quality handoff

03 tested source: `99f2f1db9d9646d8fc7f3856fc4e64df81ff6cff`, branch `test/game-feel-quality`. The old clean Quality source `9f378d0f29694686f41eb605640dcd35e09de26a` was fast-forwarded to the user-specified v2 integration. All new changes are in 03 tests/evidence/docs. No Runtime, Presenter, Replay, shared contract or other Owner files were edited. Push: NOT_RUN.

Formal Graphical TraceReplayer is **BLOCKED**, not FAIL or PASS. Both actual A/B Solver witnesses were structurally and semantically validated before the sole formal production call:

```gdscript
var result = await driver.replay(level, witness, {"mode": 1})
```

The exact source/API is `foundation/parity/trace_replayer.gd::replay`. Its accepted public options are integer `mode`, `max_steps`, `max_runtime_ms`, `step_timeout_ms`. It offers no registered completion-bridge injection. For an enabled v2 level, the mode1 gate returns before constructing its RuntimeSession:

```text
status: ERROR (2)
matched_steps: 0
code: 3016
path: dependencies.GameFeelPresenter
message: CASE_DEPENDENCY_PENDING: GAME_FEEL_GRAPHICAL_COMPLETION_BRIDGE
details.owner: 00+10A
details.required: authorized path sampling + natural completion bridge
```

Exact independent evidence: [formal_gfx_04/report.json](evidence/formal_gfx_04/report.json), [process and source hashes](evidence/formal_gfx_04/process.json), [empty stderr](evidence/formal_gfx_04/stderr.log). This is a13-check dependency probe, with zero graphical steps. `capture.authoritative_runtime=false` records that no graphical Runtime was constructed. These checks are excluded from successful replay and matrix assertion totals.

00+10A should deliver the registered authorized-path/native completion bridge; 01 should consume it inside the formal production Replayer. Keep the existing public replay boundary if possible. 03 cannot supply a private adapter, override `_make_session`, swap the old linear prototype tween into v2, or call `finish_transition` to create a graphical result. No shared schema changes are requested by this report.

After Owner delivery/intake, the formal mode1 test needs to assert actual matched Fall→Landing→Roll→Goal steps, every expected full StateKey/Orientation/World/camera, actual projected physical actor poses, captured transition identity and natural completion, Reset/cancel cleanup and repeat-run consistency. The current dependency-probe test must be replaced with that positive formal-consumer test; it intentionally fails if the old gate changes rather than silently treating any result as PASS.

Natural graphical and logical results remain separate:

- [natural_01](evidence/natural_01/report.json): actual registered A/B native Fall, natural 10A Landing, ordinary Roll→Goal, full keys and physical poses, Reset, forbidden views.62 checks and8 rendered screenshots.
- [lifecycle_03](evidence/lifecycle_03/report.json):409 checks,24 actual A/B observations for12 Fall/Landing input rows.13 actual EDGE attempts per map for Landing edge spam;13 BUSY attempts per map in flight. Required captured Fall commits, full native proposal/state/key equality, distinct Reset generations, no old in-flight commit, no residual scene Tween, released keys, subsequent natural input.
- [logical_path_01](evidence/logical_path_01/report.json):134 checks. Canonical public Baker/Codec/complete Explorer, original selected trace, live graph Softlock, production Safety and formal LOGICAL_SESSION Replay,2 matched steps/map. Explicit native logical completion is identified as logical scope.
- [permissions_01](evidence/permissions_01/report.json):40 real logical checks on controlled author-input variants through the public09 Baker. Both layers and authored restrictions are covered; this is not a registered09 Inner graphical delivery or natural Presenter proof.
- [swept_safety_01](evidence/swept_safety_01/report.json):12 checks. Delivered01 fixture data plus explicit obstacle, real production sweeps and admitted default Facade. Both height variants reject with SAFETY_REJECTED, zero commits and unchanged complete state/key. No copied volume/sweep algorithm.
- [audio_lifecycle_04](evidence/audio_lifecycle_04/report.json):36 checks of actual Main/AudioDirector. One start/contact cue, active-before-pause voice identities with real `stream_paused`, same motion token on resume, actual gain previews/cancel and in-flight Reset loop cancellation. Contact-center callback is observed; hardware A/V latency and an undeclared tolerance remain unassessed.
- [legacy_focused_01](evidence/legacy_focused_01/report.json):206 checks on actual L01–L05 native original routes, Goal, Reset, Pause, view, old connections and actual physical Orientation. Navigation uses public Shell start/exit; legacy P01 observable identity is explicitly separate from Foundation StateKey.

No confirmed new Gameplay or Presenter defect was found in the executed scope. No Runtime handoff for an invented failure is issued.

03 Harness failures remain in append-only evidence. Initial graphical/audio parse failures were test type-inference errors. Audio assertion failures assumed no formal Ambience/SFX base gain and assumed paused voices still reported `playing`; corrected tests use formal base constants and capture voices active before pause. Initial legacy stdout parsing used the wrong separator; corrected parsing matches the original marker. None is behavior RED for Fall.

The first960×720 Apply attempt (`ui_960_01`) hit an inherited test's unsafe `settings.game_feel` field access, then timed out, with three test source files changing during the run and no final report. It is invalid harness evidence, not a confirmed07 UI failure. A03-only fail-closed report guard was added; `ui_960_guarded_02` and `_03` each subsequently PASS71. Current three-size results and rendered frames are retained. Human QA is NOT_RUN. If Apply failure recurs under an unchanged source/profile/renderer, the guard captures the actual panel/control rectangles, error text, focus, native inputs and screenshot for00/07 triage.

00 separately reported candidate `1938096d48f5edcfc247923a4badf13877c3eb1b`, Build `E:/godot/beta-sprint-builds/beta_game_feel_full_slice_20261010_01`, with10B/audio/UI wiring and230 checks per size. This03 report did not intake or execute that candidate and does not confer a Quality/Human verdict on it. Pending10B/audio/UI rows refer to the tested99f host integration, not a claim that the individual Owner implementation is absent.

The remaining43 rows and exact dependency/execution scope are in [MATRIX_94.md](MATRIX_94.md) and [MATRIX_94.json](MATRIX_94.json). Old69 Core assertions map to three registered rows and are never added as69 matrix cases. Full Game Feel acceptance, the formal graphical replay, new art/VFX, complete audio/recoil/focus/drag/exit lifecycle, phase performance and soak remain pending; L06 stays outside scope.

CONTRACT_MISMATCH: NONE
