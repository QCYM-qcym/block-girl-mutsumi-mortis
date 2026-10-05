# FOUNDATION-4 Registry Module URI / Execution Closure Clarification Approval Record

Status: APPROVED
Recorded at: 2026-10-05T20:23:49+08:00 (Asia/Shanghai)
Authority: 用户本轮FINAL APPROVAL REVIEW及条件成立后的APPROVE EXACT CURRENT CLARIFICATION明确授权。

Clarification path: docs/development-records/FOUNDATION_4_REGISTRY_MODULE_URI_EXECUTION_CLOSURE_CLARIFICATION.md
Clarification SHA-256: 0A852D7A46ECF3DA356F9D6644737BD958A59D4B57501966B718B6C810579FF1

Superseded review versions (not approved by this record):
- 17FCBE2E911CC566964831F4BEE2763DBCA06CFF2626ED59B297E62BD04A9951
- 93D32EEB65F2ED1552ACD027AAAEA091765F0072C445CED373191C28A7462FE9

## Exact approval and review findings

本记录批准上述精确SHA正文。正文中的REVIEW_REQUIRED / NOT_APPROVED为批准前历史状态，原字节保持；本独立记录提供正式批准事实，不修改正文或冻结Spec/Plans，不升级任何delivery slot，不启动Owner实现或产品测试。

| Boundary | Approved decision | Clarification source |
|---|---|---|
| Registry stage modules | 10 / STAGE_SCOPED_EXECUTION_DEPENDENCY | §4十项矩阵 |
| Global stage modules | 0（限十项registry stage producer） | §4 |
| Base protocol loading dependencies | 7 / STRICT；存在、封存、实际SHA进入execution_digest、禁止active-source fallback | §4.1、§5.3、§8 |
| D2 controlled project capability | AUTHORING / BAKE / MANUAL_RUNTIME；CONTROLLED_PROJECT_CAPABILITY_SET，不是Stage Storage required stage list | §5.3 |
| MANUAL_RUNTIME stage storage | OUT_OF_SCOPE / NO_NEW_STAGE_STORAGE；无新增storage branch/schema/registry entry | §4、§5.3 |
| D2 closure | Base protocol loading dependencies + current D2 capability dependencies + 现有其它正式non-stage runtime dependencies及传递闭包 | §5.1–§5.3 |
| Current D2 requires INTENT_BIND | NO / NOT_REQUESTED | §5.3 |
| intent_binder.gd | STAGE_SCOPED / INTENT_BIND；NOT_REQUIRED_FOR_CURRENT_D2；实际执行或真实加载需要时必须存在并封存，缺失严格拒绝 | §4、§5.2–§5.3 |
| D4 stage selection source | RunRequest.policy.stages，唯一来源 | §5.3、§6 |
| policy.stages role | SELECTION_ONLY，非workflow definition | §5.3 |
| policy.stages does not redefine | ORDER / PREREQUISITES / ALGORITHM_DEPENDENCIES；既有stage输入输出关系及正式编排保持 | §2、§5.3、§6 |
| Registry vs closure | 完整current schema身份与具体run实际modules/configuration正交；不以未封存URI伪造modules SHA | §5.1、§5.3 |
| Real execution closure strictness | UNCHANGED；真实加载、显式支持依赖、Host/runtime/资源/UID保持严格，不是ignore missing registry modules | §5.2–§5.3、§8–§9 |
| D_PROTOCOL | UNCHANGED；不改8f7 registry/wire_schemas或VersionsRecord shape，无metadata_only/execution_required字段 | §9 |
| D_SAVED | CLOSURE_LOGIC_UPDATE_REQUIRED | §9 |
| 4A-4 | READY_TO_START_AT_CONTRACT_LEVEL；不依赖current 8f7 Real capture的值转换/Unit工作可推进，最终Real仍等待对应current capture及新D_SAVED receipt | §7 |
| A_EDIT | NOT_DELIVERED | §7、§9 |
| D_JOBS | IMPLEMENTATION_READY / REAL_STAGE_DEPENDENCIES_STRICT；实际执行前需正式模块、兼容D_SAVED及计划真实依赖 | §6、§9 |
| D_HOST | UNCHANGED_BY_THIS_CLARIFICATION；8289 compatibility candidate仍为phase/test依赖，待新D_SAVED receipt后另行完整Graphical | §8 |
| I1 | FROZEN_PASS；fixture/test不改、不重跑 | §8–§9 |
| I2 | NOT_STARTED | §6、§9 |

Registry stage producers: AUTHORING、BAKE、INTENT_BIND、INTENT_VALIDATE、ORIGINAL_GRAPH、SOFTLOCK、ABLATION、TRACE_SEMANTICS、MILESTONES、GRAPHICAL_REPLAY。

七项base protocol loading dependencies精确为：
- res://foundation/contracts/contract_validation.gd
- res://foundation/contracts/foundation_types.gd
- res://foundation/solver/search_records.gd
- res://foundation/solver/solver_types.gd
- res://foundation/rules/rule_types.gd
- res://tools/foundation/authoring_acceptance/tool_wire.gd
- res://tools/foundation/authoring_acceptance/wire_schemas.gd

既有顺序、stage prerequisites、dependency graph、Solver/Quality/Replay算法及stage输入输出关系继续服从已批准Design、Tool Contracts、4D Runtime / 4C Quality / Integration Plans与正式算法合同；本记录只确认正文已有边界，不另造执行顺序或补缺输入。不得按文件存在性增减stage，不得因缺前置跳过、重排或省略真实模块。

## Verification and stop boundary

Integration parent HEAD: 342a51f463697caf8953a56591ee1a16ecd1e02f
Approval scope: registry identity / controlled-project capability / stage selection / execution closure boundaries only.
Clarification body: UNCHANGED.
Production code changes: NONE.
Test code changes: NONE.
Product tests: NOT_RUN（本轮为文档批准，历史结果不冒充新运行）。
Dependency receipts / case manifest / frozen Spec / Plans: UNCHANGED.
D2 Owner WIP: PRESERVED；test_saved_snapshot.gd SHA-256 = 83FD2ECEC92D5070596A6B0665A83C2CF9B28161C0A95003C8B8CC3C80B4629D。
Commit scope: clarification原字节 + 本独立approval record。
Push: NOT_RUN.

批准记录完成后停止。本轮不实施D_SAVED修复、不派发Owner、不创建工作树、不启动I2。
