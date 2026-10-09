# Structured Fall Safety DTO — Owner07 incremental fix

2026-10-10. Previous07 delivery:d9dd3317e558f0d8380a2e6635452308d49240f1.00 identified another real DTO mismatch after integrating Runtime candidate **26387d6c34a869ad7035ee13ee77d8d5c24d796a**. The actual01 `foundation/game_feel/fall_permission.gd` motion() supplies safety_verdict as a Dictionary:

```text
{status:"SAFE", issues:[], evidence_ref:{kind,query,before_statekey,
 after_statekey,level_hash,connection_id,profile_hash}}
```

The UI compared that dictionary to the scalar string SAFE. Actual local RED also demonstrates Godot's Invalid operands Dictionary/String comparison error, followed by missing Fall status. It is an execution/DTO failure, not a parser/import failure.

## Minimal consumer correction

Fall STARTED now checks dictionary verdict, string status SAFE, Array issues with no unresolved entries and a nonempty Dictionary evidence_ref. Evidence remains opaque: UI does not calculate Safety, validate a path, regenerate statekeys, invent permission or copy Rules. Accepted native result, authorized target and captured presentation identity gates stay unchanged. Scalar SAFE has no production compatibility alias and is rejected.

Owner fixtures now have the same structured shape. Their evidence deliberately identifies kind=PRESENTATION_CONTRACT_UNIT, query=fixture_only and authoritative_runtime=false; unit statekeys/profile/level references are visibly synthetic. Reports declare all DTO/host doubles and Runtime candidate as a read-only schema reference. This is UI contract compatibility evidence, never real SAFE/path proof. No Runtime module/contract was merged or modified for this correction;00 owns real integration.

## RED/GREEN

- evidence/owner07_structured_safety_red_01:60 checks,5 failed assertions, exit1. Structured positive cases fail and scalar SAFE incorrectly passes; actual Dictionary/String runtime errors are retained in raw stderr. It runs the prior implementation with corrected fixtures.
- evidence/owner07_structured_safety_green_01: complete180 checks — Save19, Shell20, Owner settings/actual Audio API/events/structured Safety60, cold5, three logical viewports76. All exit0/stderr0/failures=[], source_drift=false;172 actual source hashes, isolated hidden headless processes, engine4.7.2.stable.steam.ed1daf0bf.
- Positive cases: structured status visible, verdict/issue/evidence immutability and matching completion cleanup. Negative cases: scalar SAFE; UNSAFE; UNPROVEN; unresolved issues; missing issues; missing, empty and wrong-type evidence reference.

All previous raw evidence is retained. Earlier scalar-fixture Fall PASS is not actual structured Runtime DTO compatibility proof; this correction supersedes that affected case. Prior169-check binding remains evidence/feedback_contract_172_binding.json. Current binding is updated after incremental commit.

Only07 UI/tests/docs changed. Approved UI tokens, old Shell, shared contract, Runtime, Host and Audio dependency remain unchanged. Real Host/Presenter/Build/graphical/Human acceptance remains outside Owner unit evidence; this fix adds no broader READY claim and does not block00 CORE Fall.
