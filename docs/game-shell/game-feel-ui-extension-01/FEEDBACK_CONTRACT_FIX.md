# ACTION_FEEDBACK phase correction — Owner07 incremental fix

2026-10-10. Previous delivery HEAD:cccd9e2f23fbf3761e15dc44aa74a8496f78d268.00 independent review identified a public event mismatch: committed GAME_FEEL_CONTRACT.md section2 specifies ACTION_FEEDBACK/FEEDBACK, while the mechanism UI and its fixtures incorrectly used REJECTED. The actual01 feedback port follows FEEDBACK. This fix stays within07 UI/tests/docs; no shared contract, Host, Runtime, Audio or old Shell edit.

## Minimal change

- Production: one consumption-condition change from ACTION_FEEDBACK/REJECTED to ACTION_FEEDBACK/FEEDBACK for explicit MECHANISM_LOCKED.
- Fixtures: mechanism, Busy and Safety ACTION_FEEDBACK now use FEEDBACK. Their original native result remains REJECTED, unchanged before/after and no authorized target; refusal status is independent of delivery phase. Typed Edge retains MOVE_REJECTED_EDGE/REJECTED.
- Four extra contract assertions: invalid ACTION_FEEDBACK/REJECTED remains silent; proper FEEDBACK shows existing authored mechanism help at player-selected strong hints; the event/native result is immutable; default hints stay quiet. Positive and negative cases are independently cleared so incorrect negative feedback cannot make the positive case pass.

No Runtime legality or general UI redesign.00 CORE Fall work is unaffected. This only restores the previously requested optional mechanism assistance.

## Behavioral RED then GREEN

evidence/owner07_feedback_contract_red_01: actual49 checks, exit1. Three explicit failures: correct mechanism FEEDBACK missing, incorrect REJECTED showing guidance, correct FEEDBACK positive assertion missing. No parser/import failure; the original implementation was still active. Raw output/report retained.

evidence/owner07_feedback_contract_green_01: actual full169 checks: Save19 + Shell20 + Owner Settings/API/events49 + cold5 + three logical viewports76. Every process exit0, stderr0, failures=[], source_drift=false. Five isolated hidden headless processes; engine4.7.2.stable.steam.ed1daf0bf. Source manifest records172 files and exact original WIP HEAD/dirty state. Actual Audio11 and SaveStore are used; event/host fixtures remain explicitly PRESENTATION_CONTRACT_UNIT, authoritative_runtime=false.

All old evidence/bindings remain immutable. Earlier mechanism fixture PASS used the wrong phase and is not public-contract compliance evidence. This new RED/GREEN supersedes that affected assertion. Prior165-check/172-source Audio binding is preserved as evidence/audio_api_172_binding.json; current DELIVERY_BINDING.json is updated after the incremental source commit.

Actual Runtime/Host/Presenter/readiness/immutable integrated Build/graphical/Human scope remains pending in this Owner checkout. This fix adds no Real/Human/overall READY claim and inherits no old size PASS.
