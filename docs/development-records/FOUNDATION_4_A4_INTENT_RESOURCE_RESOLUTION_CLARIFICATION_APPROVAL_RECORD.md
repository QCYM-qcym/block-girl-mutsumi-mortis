# FOUNDATION-4 A4 Intent Resource Resolution Clarification Approval Record

Status = APPROVED

Clarification path = docs/development-records/FOUNDATION_4_A4_INTENT_RESOURCE_RESOLUTION_CLARIFICATION.md

Clarification SHA-256 = 5E9E1EC021B700DC819F67585AA60390BF67EAA65EAB4EC5A0C45995564FBF63

Integration baseline R5 = a40392c99a93db10e07fd5f15215192f29165e7f

Authorization: 用户明确批准上述精确当前澄清版本；批准以其SHA-256绑定，不改写澄清正文。

## Approval scope

本批准仅解决A4作者资源引用解析输入不足。新Binder签名为：

```gdscript
bind_intent(
  authoring_intent: Dictionary,
  resource_table: Array[Dictionary],
  successful_bake: Dictionary,
  snapshot_identity: Dictionary
) -> Dictionary
```

旧三参数bind_intent(authoring_intent, successful_bake, snapshot_identity)签名在本FOUNDATION-4工具合同用途下废止。既有冻结Spec/Plans原字节保持不变，本独立批准记录与精确澄清共同记录接口裁定。

resource_table必须来自产生authoring_intent并用于同轮A_BAKE输入的同一个AuthoringPayload.resource_table。这是调用API的前置条件，不允许另行拼造表或由活动源补齐。

允许解析链：resource_ref → resource_table精确authoring_id索引 → MILESTONE/BYPASS作者定义 → 正式PuzzleIntent值。要求authoring_id唯一、entry与fields符合既有封闭schema；missing ref、重复引用目标身份、kind mismatch、unknown kind、非法字段、未知嵌套引用及循环均拒绝。合法共享引用本身不等于重复表身份或循环。

不得按数组位置解析、按URI模糊匹配、动态load作者Resource或从SceneTree补缺。

AT_FACE必须先验证合法输入，再调用正式SurfaceGeometry.face_id(cube_id, face)。不得复制Geometry算法、自行拼接或通过SourceMap猜面。转换失败时ok=false、bound_intent=null。

## Unchanged contracts

formal PuzzleIntent unchanged：仍恰八字段intent_version、intent_id、level_hash、rule_version、required_mechanics、optional_mechanics、expected_milestones、forbidden_bypasses。

resource_ref、authoring_id、document_uri、resource_uid、run_id、snapshot_id、source_fingerprint不得进入正式PuzzleIntent。

BakeProvenance继续恰含run_id、snapshot_id、source_fingerprint；与SnapshotIdentity及SourceMap的既有交叉核验不弱化。

A_SCHEMA、A_BAKE、SourceMap、D_PROTOCOL、D_SAVED、C_QUALITY、formal Level、Reader、Baker、Codec与I1全部不变。

A_BAKE = e0940278fe425d7f77eb6a5b4ea042067606258d
D_SAVED = a8ac1d4e05d9b9ff4f5b0df0a400677e413d88e0

本批准不更新dependency_receipts或case_manifest，不登记A_EDIT，不修改Owner源码或WIP。

## Explicit exclusion and remaining blocker

source_intent_digest semantics = NOT COVERED BY THIS APPROVAL

Remaining A4 contract blocker = SOURCE_INTENT_DIGEST_INPUT_SEMANTICS
Status of remaining blocker = CONTRACT_PENDING
Overall CONTRACT_MISMATCH = PARTIALLY_RESOLVED

本批准不暗含4A自行hash、resource_table自行hash、authoring_intent自行JSON hash，也不允许使用source_fingerprint或authoring_payload_digest代替。不得默认空串，不得把默认null解释为合法非空摘要。

A4资源解析合同已解决，但4A-4整体仍不能开始正式GREEN实现，直到source_intent_digest合同另行批准。该独立问题不会由本记录默认为已解决。

## Execution boundary

本轮仅提交澄清原字节与本独立批准记录。未运行A4产品测试、未启动A4实现或I1/I2；不修改Spec、Plans、receipts、case_manifest或Owner文件。本地commit获授权，Push: NOT_RUN。

Recorded at = 2026-09-26T23:16:12.6719065+08:00
