# FOUNDATION-4 A4 Intent Resource Resolution Contract Clarification

Status: A4_INTENT_RESOURCE_RESOLUTION_CLARIFICATION_REVIEW_READY

本文件仅为待审阅合同澄清，不是批准记录，不授权实施、不登记交付。记录日期：2026-09-26（Asia/Shanghai）。

## 1. 核验基线与原合同不足

Integration R5：a40392c99a93db10e07fd5f15215192f29165e7f。
A_BAKE：e0940278fe425d7f77eb6a5b4ea042067606258d。
D_PROTOCOL：6176a45c614f678c8b248d5289f9a672a971043b。
D_SAVED：a8ac1d4e05d9b9ff4f5b0df0a400677e413d88e0。

依据：Tool Contracts §4及公开接口表；4A Implementation Plan公开接口、AuthoringPayload定义及4A-4；已批准BakeProvenance澄清（SHA-256：AD9A19383B07DB4319BE690E06B509CB0C80F62E06FAEE4DD21DCB30E3DCB00E）。源码核验对象为Integration已交付版本，未读取活动Owner WIP作为合同依据。

当前AuthoringPayload恰含authoring_version、level_ref、documents、resource_table。expected_milestones与forbidden_bypasses的元素是显式引用 `{resource_ref:String}`，并非内联Resource。引用指向resource_table中MILESTONE/BYPASS的authoring_id。旧Binder仅持有authoring_intent，无法读取引用目标的predicate或disabled_mechanics，也无法获得AT_FACE.face_ref。

4A-4当前为用户报告的CONTRACT_MISMATCH；不是实现失败或RED，测试NOT_RUN。假设调用方已经展开资源会创造未批准的第二种作者表示。此澄清只补足引用表输入。

## 2. 唯一拟议接口变更

旧签名：

```gdscript
bind_intent(authoring_intent: Dictionary,
            successful_bake: Dictionary,
            snapshot_identity: Dictionary) -> Dictionary
```

新签名：

```gdscript
bind_intent(authoring_intent: Dictionary,
            resource_table: Array[Dictionary],
            successful_bake: Dictionary,
            snapshot_identity: Dictionary) -> Dictionary
```

返回包装保持不变：

```text
{
  ok: bool,
  bound_intent: Dictionary | null,
  source_intent_digest: String | null,
  issues: Array[ToolIssue]
}
```

只增加resource_table参数。authoring_intent沿既有INTENT字段声明，不内联Milestone/Bypass；AuthoringPayload、AuthoringDocument、作者Resource schema不变。没有第二个wire，也不修改A_BAKE包装、BakeProvenance、SourceMap或formal PuzzleIntent。

## 3. 同一捕获Payload前置条件

调用方必须从同一次捕获、用于该次successful_bake输入的同一个AuthoringPayload取得authoring_intent声明与resource_table，并传入同轮snapshot_identity：

```text
same captured AuthoringPayload
├─ authoring_intent declaration
├─ resource_table
└─ A_BAKE → successful_bake

Binder(authoring_intent, same_payload.resource_table,
       successful_bake, same_snapshot_identity)
```

resource_table不是调用方任意拼造、另一次捕获或活动项目补取的表；调用期间必须保持该捕获值一致。此项是API前置条件，引用表结构验证及身份相等不能独立认证任意调用方提供的表确实来自该Payload。不得宣称新增参数形成密码学证明。

4A不拥有4D wire/hash，不能重新计算source_fingerprint、authoring_payload_digest、execution_digest。BakeProvenance与SnapshotIdentity继续核验执行身份；resource_table只解析作者引用闭包。

## 4. 封闭表与引用解析

每个条目精确为既有五字段：

```text
{
  authoring_id: String,
  kind: String,
  document_uri: String,
  resource_uid: String | null,
  fields: Dictionary
}
```

遵循已交付authoring_schema.gd的RESOURCE_FIELDS、RESOURCE_KINDS、FIELDS及既有字段/类型/身份约束，不放宽、不另建作者schema。kind仅为FACE、MECHANISM_CONFIG、INTENT、MILESTONE、BYPASS；不是把整个表限制成两种kind。fields必须满足相应kind的封闭白名单与类型/枚举规则；resource_uid可空，不扩展其它可空位置。

先验证表，再建立authoring_id → exactly one resource entry索引。重复authoring_id即失败，不能因内容相同去重。引用必须恰为 `{resource_ref:String}`，按身份精确解析。以下均使整个绑定失败：

- malformed entry、缺字段、额外字段、非法类型/身份、unknown resource kind、非法作者fields；
- resource_ref缺失、非法、目标不存在或解析多项；
- expected_milestones引用非MILESTONE、forbidden_bypasses引用非BYPASS；
- 嵌套未知Resource引用、非法引用闭包或Resource循环。

共享引用不等于循环；循环检测按引用路径识别，不能误拒绝合法共享资源。不得猜最近Resource、按数组位置匹配、按document_uri模糊匹配、动态load .tres、实例化Resource脚本，或从活动SceneTree补引用。

所有失败：ok=false、bound_intent=null，由既有issues报告；不得回填历史Intent或输出部分可用Intent。source_intent_digest失败语义保持原合同。

## 5. MILESTONE与Predicate转换

expected_milestones每项仍为resource_ref，解析到MILESTONE后只读取既有fields：milestone_id、required、predicate。正式输出仍恰为 `{milestone_id,required,predicate}`。输出里程碑保持作者声明顺序，resource_table排序不得改变该顺序。

AT_FACE作者predicate为 `{kind,face_ref}`，face_ref恰为 `{cube_id:StringName,face:int}`。先按既有作者schema检查类型、cube_id及FaceDirection范围，再调用正式：

```gdscript
SurfaceGeometry.face_id(cube_id, face)
```

正式实现位于foundation/spatial/surface_geometry.gd，参数类型为StringName/int，返回StringName；它对非法face使用断言，不是可恢复Result。Binder必须在调用前拒绝非法输入，不能把引擎断言当作正常失败路径。不能完成合法解析时整个bind失败，ok=false、bound_intent=null。不得字符串拼接、复制Geometry算法、自算面编号或经SourceMap猜面。

正式AT_FACE predicate输出沿原合同为 `{kind,face_id}`。其它Predicate严格沿Tool Contracts §4：

| Predicate | 正式封闭字段 |
|---|---|
| IN_LAYER | kind、layer |
| FACE_LIGHT | kind、light_state |
| MECHANIC_USED | kind、mechanic |
| GOAL | kind |

FACE_LIGHT仍描述样本玩家所在面，不增加任意target face。所有类型/枚举、标签唯一性与既有语义约束保持，不新增Predicate。

## 6. BYPASS转换与正式输出

forbidden_bypasses每项resource_ref必须解析为BYPASS，仅消费既有fields：bypass_id、disabled_mechanics。正式输出恰为 `{bypass_id,disabled_mechanics}`；不夹带authoring_id、resource_ref、document_uri、resource_uid。标签非法/重复仍拒绝，不自动补约束。

bound_intent仍恰八字段：

```text
{
  intent_version,
  intent_id,
  level_hash,
  rule_version,
  required_mechanics,
  optional_mechanics,
  expected_milestones,
  forbidden_bypasses
}
```

level_hash只来自successful_bake.level.content_hash，rule_version只来自successful_bake.level.rule_version。run_id、snapshot_id、source_fingerprint、authoring_id、resource_ref全部不得进入正式PuzzleIntent。其正式版本、类型及后续IntentValidation规则不变。

## 7. BakeProvenance规则完整保留

先要求successful_bake.ok严格为true、level非null、正式validation有效、bake_provenance非null并符合已批准的恰三String字段封闭记录。缺失、未知字段或非法身份均拒绝，不从当前identity补造证明。仍必须严格比较：

```text
bake_provenance.run_id == snapshot_identity.run_id
bake_provenance.snapshot_id == snapshot_identity.snapshot_id
bake_provenance.source_fingerprint == snapshot_identity.source_fingerprint
source_map.snapshot_id == bake_provenance.snapshot_id
source_map.source_fingerprint == bake_provenance.source_fingerprint
```

任何不一致使整个bind失败，bound_intent=null。SourceMap不增加run_id；BakeProvenance不增字段。本澄清不弱化此前批准规则。

## 8. source_intent_digest独立待澄清项

4A计划明确该值从4D给定身份回传，不自行编码/hash。本澄清保持这一规则，禁止JSON hash、resource_table hash或intent closure hash。

只读核验显示，当前D_SAVED snapshot_capture.gd创建的identity.source_intent_digest为null；run_records.gd及execution_project.gd允许null或既有合法摘要。现有记录并未在本次核验范围内明确非null值的具体输入范围及生产路径。因此单独记录：SOURCE_INTENT_DIGEST_INPUT_DEFINITION — 独立待澄清，不由本稿解决。不得凭新增resource_table参数推导算法、扩大4A职责，也不得把本稿获批等同于A4所有合同问题均已消除。

## 9. Owner边界与兼容结论

| Owner | 本稿职责 |
|---|---|
| 4A | 消费既有resource_table schema、解析resource_ref、转换Milestone/Bypass、调用正式Geometry.face_id、实现Binder |
| 4D | 保持snapshot、wire、digest、source fingerprint、execution identity唯一所有权 |
| 4C | 正式IntentValidation及后续quality |
| 4B | 无影响 |

A_SCHEMA不变；A_BAKE保持e0940278fe425d7f77eb6a5b4ea042067606258d，不产生新版包装；D_PROTOCOL、D_SAVED、C_QUALITY不变。

D_PROTOCOL已交付wire_schemas.gd对authoring仍委派现有A_SCHEMA，并无编码此Binder调用参数列表的公开record。新增参数仅传入已存在的Payload资源表，不增加wire类型、字段或宽松Dictionary通道。未交付schema不被本稿追认为可用。D_SAVED package schema、封包及摘要规则不变；Formal Level、AuthoringReader、LevelBaker、LevelCodec、SourceMap全部不变。

D_HOST/I1不受本次A4作者资源解析澄清阻塞；I1本身仍等待既有D_HOST及test_saved_vertical.gd交付。I2仍需未来正式A_EDIT、D_JOBS、test_quality_replay.gd等。本稿不能登记A_EDIT，也不启动I1/I2。

## 10. 审阅与本轮边界

A_EDIT impact: REQUIRED_BEFORE_A4。此精确文本待用户审阅批准；批准前不实施新签名。未来验收应覆盖封闭表负例、引用种类/缺失/重复/循环、表排序不改变里程碑顺序、正式Geometry调用、所有身份失配及正式八字段输出；本轮不创建测试或宣称RED/GREEN。

本轮仅新增本澄清文件并检查文档一致性/变更范围/SHA-256。不修改冻结Design Spec、Tool Contracts、五份Implementation Plans原字节，不修改receipt/case_manifest、Owner源码或4A/4D WIP。不commit、不push。I1/I2: NOT_STARTED。
