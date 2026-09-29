# FOUNDATION-4 Consolidated D_PROTOCOL Registration

Status: D_PROTOCOL_CONSOLIDATED_RECEIPT_READY
Contract mismatch: NONE
Recorded: 2026-09-29T11:43:50.265444+08:00

## Approved content and history binding

Approval binding mode: CONTENT_EQUIVALENT_TO_CANONICAL_APPROVAL
Owner history classification: APPROVAL_CONTENT_EQUIVALENT_HISTORY
Approval history mismatch: RESOLVED_BY_CONTENT_EQUIVALENCE
Authority: user's explicit authorization to accept identical approved artifacts without requiring identical commit objects/ancestry.

| Track | Canonical approval | Owner-history equivalent | Clarification SHA-256 |
| --- | --- | --- | --- |
| A | 21c23df2ac549a6c998cd2a3604ff55c2f891684 | 01aba03ba87d1a168adb3c29cc60bbd650deb935 | E1DF9D6DA305C764BFFC53CB930EF7149A8EF734BB2585E10D2AECA69137CDEE |
| D | 2aa086972e2749262d4128b537e4e687e284cb55 | a4f0bb32936eb0af064dc8256d90c79ddb50e2cd | C3086988452E6DFB13AFCE60196C33F9FAD69CECF38E4F5C259A08629024583B |

Both clarification blobs and both approval-record blobs were compared byte-for-byte at canonical, equivalent and final Owner commits. All equal. Owner history after each equivalent approval contains no subsequent modification of those paths. Canonical approvals remain authoritative; equivalent commits are not relabeled as canonical ancestors.

## Owner and controlled merge

Previous D_PROTOCOL: ef1b0b8a3a16b04037eb5ac49faaa55e296b31e8
Updated D_PROTOCOL: 814a1d7264140eec44a6b32752166832beb8ce75
Integration pre-merge: 2aa086972e2749262d4128b537e4e687e284cb55
Common ancestor: ef1b0b8a3a16b04037eb5ac49faaa55e296b31e8
Integration merge: 19af1b73b5a019e1fc22388acba0fc947db278de

Normal divergent histories; no Integration changes to the two incoming Owner paths since the common ancestor. Normal merge completed without conflict. Approval files merged as identical content. No reset, rebase, squash, cherry-pick, Owner copying or history rewrite.

Final Owner commit changes exactly:

| Path | SHA-256 |
| --- | --- |
| tools/foundation/authoring_acceptance/wire_schemas.gd | 6d3d9b9a7678eb26b65d2d6bfc574106f2cfc27549fc44def68c061157d1ddd0 |
| tests/foundation/authoring_acceptance/test_tool_wire.gd | 2dee55a28b4d8f1b8b4dc34bb36aca6df00b3b54d858363b84e30ddae6be89f8 |

Earlier approval-only commits are documentation dependencies, not production Owner violations. Frozen Spec/Plans, D_SAVED, D_HOST and I1 source files unchanged. D_PROTOCOL receipt retains its complete ten-path inventory; all hashes recomputed from Owner blobs and verified against Integration checkout. Only two hashes changed. All other registered slots and their exact records remain unchanged.

## Contract audit

source_intent is registered in foundationtoolwire.v1 and the schema registry. Its exact root_authoring_id/resources shape reuses A_SCHEMA ResourceEntry and kind-specific fields. The projection first validates the full AuthoringPayload, selects the Level's INTENT and referenced MILESTONE/BYPASS entries, retains full entries and author array order, and sorts the resource collection by UUID UTF-8 order. Missing Intent returns null; explicit empty forms a non-null digestable record. Unknown fields, duplicate identities, missing/wrong-kind references, invalid predicates and unrelated entries in the canonical closure are rejected. Existing ToolWire.digest("source_intent", value) remains the sole digest path; no new hashing implementation was added.

foundationworkeripc.v1 unchanged. Seven non-STAGE_RESULT kinds validate inline closed payloads, required fields, null/type/domain rejection and approved stage_id values. STAGE_RESULT remains ArtifactRef-only with its existing binding checks. Constants include first sequence 0, initial last -1, per-direction first LEASE/HELLO, 1000ms renewal/30000ms validity. validate_worker_context is a pure comparison using caller-owned active-stage/direction/expected-sequence values. It retains no cursor and performs no transport/process effects. D4 still owns ordering state, duplicate/gap tracking, polling, lease continuity, cancellation races and release confirmation; this registration does not claim those are implemented.

Non-BAKE native storage schemas remain subject to their approved separate boundaries; protocol registration does not permit generic native dictionaries or prove D_JOBS delivery.

## Owner evidence audit

Delivery: E:/godot/worktrees/block-girl-foundation-runtime-stage-result/.godot/dprotocol-consolidated-delivery/delivery.json

RED: 1486 checks / 322 failures, exit 1, stderr empty. Final D1 GREEN: 1583 / 0. Compatibility: D2 Unit165 / 0, Real194 / 0, D3 source-staging Graphical88 / 0, I1 Graphical88 / 0. GREEN exit0 and stderr empty. Raw results and test project copies of both delivered files were checked against final delivery SHA. D1 retains only the declared in-memory BoundaryControl state provider; D2/D3/I1 doubles=[].

## Integration verification

All cases use the actual merged Integration checkout and updated dependency_receipts. Command template:

```powershell
pwsh -NoProfile -File tests/foundation/authoring_integration/run_module.ps1 -Module <Module> -Case <Case> -Mode <Mode> -EvidenceName <EvidenceName>
```

| Module / Case / Mode | EvidenceName | Checks | Failures | Exit |
| --- | --- | ---: | ---: | ---: |
| Integration / I0 / Unit | consolidated_registration_i0_20260929_01 | 15 | 0 | 0 |
| 4D / 4D-1 / Unit | consolidated_registration_d1_20260929_01 | 1583 | 0 | 0 |
| 4D / 4D-2 / Unit | consolidated_registration_d2unit_20260929_01 | 165 | 0 | 0 |
| 4D / 4D-2 / Real | consolidated_registration_d2real_20260929_01 | 194 | 0 | 0 |
| 4D / 4D-3 / Graphical | consolidated_registration_d3_20260929_01 | 88 | 0 | 0 |
| Integration / I1 / Graphical | consolidated_registration_i1_20260929_01 | 88 | 0 | 0 |

Evidence root: E:/godot/worktrees/block-girl-foundation-4-integration/.godot/foundation-authoring-tests/.
D3 explicitly uses D3_SOURCE_STAGING_REGRESSION=1, matching the delivered 88-check compatibility mode. It creates fresh capture evidence under current registry; this is not a repeat/relabel of the historical R6 final controlled run or D4 lifecycle proof. Both Graphical runs report Windows display. Product import/run stderr logs are all empty and failures=[]. I0 has deliberate failing children (180 stderr bytes in expected injected evidence), its 15 checks all pass; this does not waive product stderr gates. D1 allows the existing BoundaryControl state provider, D2/D3/I1 have no doubles. Final project copies bind the exact new protocol SHA.

Boundary command:

```powershell
pwsh -NoProfile -File E:/godot/foundation-4-stage-result-registration-20260927/verify_boundaries.ps1 -RunName consolidated_registration_boundary_20260929_01
```

Boundary: 28/28 PASS, exit0. Its printed FAIL is an expected aggregation fault-injection result; all checks.json entries passed. Evidence: E:/godot/foundation-4-stage-result-registration-20260927/consolidated_registration_boundary_20260929_01/.

## Retained deliveries and next dependencies

D_SAVED: 7cbdae3d0d04ed6b2dc8fc4d05eb6e49472b2664
Classification: UPDATE_REQUIRED_FOR_SOURCE_INTENT_DIGEST_AND_CURRENT_PROTOCOL_REGISTRY
Current registered delivery is not FAILED. Old VersionsRecord without the new registry key is intentionally rejected. Next D_SAVED update must capture source_intent_digest and bind the complete current registry. SnapshotRef and input.ready outer shapes remain unchanged.

D_HOST: b9bf7d4a02398cd354fab6a18948babaa22c531e (unchanged; no redelivery required)
I1: 14936504ae4245cc1822786937f021afce4a7fd9 / FROZEN_PASS (all six file bytes unchanged)

Track A next: D_SAVED_SOURCE_INTENT_DIGEST_UPDATE_READY; new D_SAVED receipt must precede 4A-4/A_EDIT.
Track D next: D4_JOBS_IMPLEMENTATION_READY; lifecycle implementation still required, not delivered by value-schema tests.
These implementation lines may proceed after this receipt; neither is started by this registration turn.

Registered slots: BASE, I_HARNESS, A_SCHEMA, A_BAKE, D_PROTOCOL, C_QUALITY, D_SAVED, D_HOST.
A_EDIT: NOT_DELIVERED
D_JOBS: NOT_DELIVERED
B_EDITOR: NOT_DELIVERED
D_FULL: NOT_DELIVERED
I2: NOT_STARTED
Push: NOT_RUN
