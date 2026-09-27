# FOUNDATION-4 Stage Result Schema Clarification Approval Record

Status = APPROVED

Clarification path = docs/development-records/FOUNDATION_4_STAGE_RESULT_SCHEMA_CLARIFICATION.md
Clarification SHA-256 = DBE2B5B4EA01F91160FD8E9F6D939766E5E0D2F319F84D6F26A80C0D06653AD0
Previous SHA-256 = 3DFC9EE12A751F0F0F108659C69A66D6D9D74CDD29895D896D0D129C69E0A9C6
Previous status = SUPERSEDED

批准依据：用户本轮明确授权APPROVE EXACT CURRENT CLARIFICATION。已核对精确SHA；澄清正文任何字节均未修改。本记录明确批准范围与排除项，不将待实现协议登记为已交付。

## 批准范围

foundationtoolwire.v1 / record_kind=stage_result。

批准精确澄清中的closed envelope（恰run_identity、stage_record）、StoredStageRecord十四字段映射、按stage_id注册的封闭native_result存储分支及未知字段/类型/分支拒绝规则。内存StageRecord正式shape不变。尚未注册的其它stage分支不因本批准被视作已定义或已实现。

批准WorkerMessage STAGE_RESULT仅使用ArtifactRef引用stage_result.wire；禁止inline任意StageRecord/native_result/canonical/JSON。完整identity、stage_id、sequence、路径/长度/hash闭环全部校验通过才可接受，不部分接收、不覆盖已有有效记录。

批准COMPLETED必须有非null正式返回；INCOMPLETE/ERROR/CANCELLED按是否有实际完整返回保留native_result或null；RUNNING及纯NOT_RUN不发布该wire。未注册的真实原生结果不能丢弃后伪装null或成功。

批准attachment → close/readback/hash/final rename → stage_result → close/readback/hash/final rename → WorkerMessage的发布顺序。run级manifest-last及避免循环摘要保持。

## 正式路径

所有ArtifactRef.relative_path相对正式run root：

- stage output root：artifacts/stages/<STAGE_ID>/
- BAKE canonical：artifacts/stages/BAKE/canonical.level
- stage result：artifacts/stages/<STAGE_ID>/stage_result.wire

不得使用协调目录、活动工程或本机缓存绝对路径作为产品引用。整个stage_result payload禁止机器绝对路径；SourceMap路径也必须属于批准的逻辑URI/结构路径。

D_SAVED INPUT PACKAGE SCHEMA = UNCHANGED

发布stage输出不得修改sealed input package，不修改SnapshotRef/input.ready/sealed input layout。

## Graph与正式加载

BAKE branch禁止graph、graph_archive_ref及live graph。含graph的已注册阶段必须把graph写为只读graph_archive附件，持久化native_result通过明确ArtifactRef替换graph字段，其余正式字段不改写。graph_archive不能作为可信live graph恢复源、Softlock或Ablation可信输入。具体未注册阶段的完整storage schema仍须另行冻结，不产生通用optional graph字段。

E:/godot/foundation-4-d3-unblock-20260927/canonical.level仅为COORDINATION_HANDOFF_EVIDENCE。custom JSON Bake sidecar仅为COORDINATION / TEST HANDOFF ONLY，不是D_HOST产品协议。

正式实现后必须按批准stage publication流程发布经核验的canonical和正式引用，不能把协调JSON追认为产品协议。D3正式链为run → stage_result.wire → 经完整身份/摘要校验的BAKE native_result → canonical ArtifactRef → canonical bytes → LevelCodec.decode；全部沿澄清规定的input.ready与发布身份绑定核验。

## 实现交付与明确排除

D_PROTOCOL = UPDATE_REQUIRED
Current registered D_PROTOCOL = 6176a45c614f678c8b248d5289f9a672a971043b

该旧slot不包含本次批准协议，不能自动升级。4D协议Owner负责实现stage_result、WorkerMessage引用规则、stage-specific storage branches、BAKE正式持久化与graph_archive边界，产生新的Owner update后由Integration另行登记。本轮不修改dependency_receipts。

D3_HOST_EXECUTION_BINDING_CONTRACT_PENDING

execution materialization如何增加新宿主模块闭包，以及新execution identity如何绑定原BAKE/source证据，NOT COVERED BY THIS APPROVAL。

按用户本轮明确范围裁定，澄清§11/§12中execution materialization follow-up的UPDATE_REQUIRED描述不作为已批准的D_SAVED实现结论。正文原字节保留；本批准只冻结D_SAVED输入包schema不变，不决定D_SAVED实现update required或not required，须待独立宿主执行绑定合同批准后判断。此前其它已批准澄清的独立义务不因本次排除而撤销。

CONTRACT_MISMATCH = RESOLVED_AT_STAGE_RESULT_CONTRACT_LEVEL
D_HOST = BLOCKED
I1 = NOT_STARTED

本批准不是协议实现通过或D_HOST交付。4D现有WIP与SESSION_WRITE_EXPOSURE内部审阅问题保持Owner职责，不跨Owner修改。

## 本轮执行范围

仅本地提交精确澄清正文与本独立批准记录。未修改Spec/Plans、case_manifest、receipts、4D源码/WIP、D_PROTOCOL或D_SAVED实现；未启动Tween/I1。
Push = NOT_RUN

Recorded at = 2026-09-27T13:19:47.6299843+08:00
