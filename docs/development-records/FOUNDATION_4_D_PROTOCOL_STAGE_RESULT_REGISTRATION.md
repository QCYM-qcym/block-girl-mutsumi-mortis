# FOUNDATION-4 D_PROTOCOL Stage Result Scoped Registration

D_PROTOCOL_STAGE_RESULT_RECEIPT_READY
CONTRACT_MISMATCH: NONE_WITHIN_APPROVED_SCOPE

Owner commit: ef1b0b8a3a16b04037eb5ac49faaa55e296b31e8
Previous D_PROTOCOL: 6176a45c614f678c8b248d5289f9a672a971043b
Integration pre-merge HEAD: 879a5b07c4f878fc51b64f3728a1b80f6be267b8
Common ancestor: 74892ba39c283e24efbd0755e85e552b5a685784

## Owner delivery verification

Evidence source: E:/godot/worktrees/block-girl-foundation-runtime-stage-result/.godot/protocol-compatibility/D_PROTOCOL_SCOPED_UPDATE_DELIVERY.json。
Owner commit只修改以下三个D1允许文件；全部blob SHA与delivery、Owner D1 GREEN测试副本、D2 Unit/Real测试副本逐字节一致：

| File | SHA-256 |
|---|---|
| tests/foundation/authoring_acceptance/test_tool_wire.gd | c4a9bcca64a7c4888d4450337f98dad5aea66ff52f00f703806b8216016b5303 |
| tools/foundation/authoring_acceptance/tool_wire.gd | d99af800ae3fdbc0246d69c37ec022032261ebad981996890f6f8e14f4e60d12 |
| tools/foundation/authoring_acceptance/wire_schemas.gd | 8beb683c7cad22bb92bd4204e1f20e8d489d7c7e51cd08d7f867d3bdef93b613 |

Stage Result批准74892ba为Owner祖先；Worker IPC批准以Owner本地12d50b2消费，对应两个批准文档与Integration的879a5b0版本字节完全一致。该既有Owner历史如实保留，本轮未cherry-pick。原613断言/调用保持，仅既有versions测试fixture改用新版正式注册表；新增协议测试追加，不删除原断言。A_SCHEMA兼容仍在D1真实执行。无D3/D4生产实现、Spec/Plans改动。

Owner原始最终GREEN1101/1101、D2 Unit89/89、Real91/91，exit0、原始import/run stderr空；同版本源码核验通过。Owner边界测试double仅为BoundaryControl状态provider，不替代算法；D2无double。

ff-only因正常协调分叉拒绝后，采用普通无冲突merge。两侧唯一路径重叠为字节相同的IPC澄清/批准文档；Owner生产范围无冲突，未手工复制或改写Owner文件。

## Receipt scope

唯一dependency_receipts中的D_PROTOCOL更新到ef1b0b8a3a16b04037eb5ac49faaa55e296b31e8；保留原十路径，仅上述三项SHA变化。其余BASE、I_HARNESS、A_SCHEMA、A_BAKE、C_QUALITY、D_SAVED全部不变，已逐项核验当前checkout及对应commit blob。

Implemented scope: STAGE_RESULT + BAKE storage + worker protocol version。
包含唯一foundationworkeripc.v1注册、公共封闭消息字段及严格版本校验、STAGE_RESULT ArtifactRef分支、stage_result/BAKE schema、native终态/null、graph排除与whole-payload路径规则、无状态字节长度/SHA/identity/stage绑定。

verify_stage_result不是文件系统/作业完整验收：真实消费者仍负责run-root containment/symlink、期望活动identity、sealed input/policy、canonical Codec/content_hash及正式发布顺序；本次不登记D_HOST、D_JOBS或完整IPC。

D_PROTOCOL_DEFERRED_TO_D4:
- non-stage payload schemas：HELLO、STAGE_STARTED、HEARTBEAT、EXIT、ERROR、CANCEL、LEASE；
- sequence stream semantics：起点、单调性、重复与跳号生命周期；
- non-stage stage_id semantics。

未实现kind在公共版本/封闭字段校验后仍返回DEPENDENCY_PENDING，不以版本检查通过宣称payload可用。无WORKER_IPC_COMPLETE、D_JOBS_READY或D_PROTOCOL_FULL_IPC_READY结论。

## Integration actual verification

| Run | Checks | Result |
|---|---:|---|
| stage_receipt_i0_20260927_01 | 15 | PASS / exit0 |
| stage_receipt_d1_20260927_01 | 1101 | PASS / exit0 |
| stage_receipt_d2unit_20260927_01 | 89 | PASS / exit0 |
| stage_receipt_d2real_20260927_01 | 91 | PASS / exit0 |
| stage_boundary_20260927_01 | 28 | PASS / exit0 |

使用Integration正式run_module.ps1分别运行Integration/I0/Unit、4D/4D-1/Unit、4D/4D-2/Unit与Real，以上名称分别作为EvidenceName。所有实际checks>0、failures=[]；实际import/run stderr空。Boundary沿前次28项检查，仅外部证据目录改变；其输出中的FAIL是预期聚合优先级故障注入，总28/28通过，不是忽略失败。

证据：E:/godot/foundation-4-stage-result-registration-20260927/verification.json、owner-delivery.json、d3-classification.json、stage_boundary_20260927_01/checks.json；测试完整日志位于Integration .godot/foundation-authoring-tests/上述EvidenceName。

## D3 actual classification

只调用Harness Get-Missing，未运行4D-3。原始Harness结果：script:res://tests/foundation/authoring_acceptance/test_whitebox_host.gd（OWNER_TEST_NOT_DELIVERED）。现有case manifest只检slot存在，不能表达已批准的新D_SAVED能力版本门槛，不能伪造它返回了另一个码。

协调合同门槛仍为DEPENDENCY_PENDING: UPDATED_D_SAVED_EXECUTION_CLOSURE；现有D_SAVED仍为a8ac1d4e05d9b9ff4f5b0df0a400677e413d88e0，尚未支持正式宿主场景资源闭包。FORMAL_STAGE_RESULT_SCHEMA不再是缺失的已批准BAKE storage schema；运行服务/发布/入口验收不属于本scoped协议登记完成证明。

D_JOBS: NOT_DELIVERED
D_HOST: NOT_ISSUED
D3: NOT_STARTED
I1: NOT_STARTED
Push: NOT_RUN

本轮仅受控合并Owner交付并更新receipt/本协调记录，未修改Owner工作树或WIP。最终receipt commit由提交后git rev-parse HEAD取得，外部证据记录真实SHA，避免文档自引用。
Recorded at: 2026-09-27T14:07:37.7968086+08:00
