# FOUNDATION-4 A4 Source Intent Digest Contract Clarification

Status: A4_SOURCE_INTENT_DIGEST_CLARIFICATION_REVIEW_READY

记录日期：2026-09-26，Asia/Shanghai。本文是待批准提案，不是既有合同或实现完成声明。A4: STILL_BLOCKED_PENDING_APPROVAL。

## 1. 审计基线与分类

Integration receipt R5：a40392c99a93db10e07fd5f15215192f29165e7f；当前HEAD为资源解析批准提交24e2c18016a5f7ddba102c81c28c3c2f66be114a。资源解析澄清SHA为5E9E1EC021B700DC819F67585AA60390BF67EAA65EAB4EC5A0C45995564FBF63。

分类：APPROVED CONTRACT为明确批准条款；IMPLEMENTED BEHAVIOR为当前登记源码事实；PLAN ONLY为计划尚未兑现的动作；INFERENCE为审计推论；UNDEFINED为未找到精确定义。本文后续规范选择一律为PROPOSED，不以推论替代批准。

| 分类 | 证据与结论 |
|---|---|
| APPROVED CONTRACT | Design Spec §6：正式PuzzleIntent独立sidecar；4A保义绑定、4C正式验证、4D编排。missing不等于explicit empty；四集合均空但存在合法Intent仍需实际绑定/验证。 |
| APPROVED CONTRACT | Tool Contracts §4：Binder包装含source_intent_digest，不能回退旧level；未定义该摘要完整输入。§6：唯一foundationtoolwire.v1及封闭record_kind；§7：RunIdentity恰九字段，无source_intent_digest。 |
| APPROVED CONTRACT | Tool Contracts §6：source_fingerprint是source_manifest规范wire摘要，manifest含authoring_payload_digest、dependencies、source_locations；不是Intent子集摘要。 |
| APPROVED CONTRACT | 4A Plan公开接口表：digest从4D给定身份回传，不自行编码/hash。Integration Plan公共接口表：SnapshotIdentity恰为run_id、snapshot_id、source_fingerprint、source_intent_digest（String或null）。这与RunIdentity不同；已有承载字段，不需偷偷扩shape。 |
| APPROVED CONTRACT | 4A Plan：AuthoringPayload显式resource_table；引用为resource_ref。已批准资源解析澄清增加resource_table参数，且明确排除source_intent_digest语义。 |
| PLAN ONLY | 4A Plan 4A-4 GREEN条目要求回传D提供值；不能据此断言当前已有非空值生产算法。4D Plan D1要求封闭schema分派及canonical roundtrip；未列出本摘要的闭包定义。 |
| PLAN ONLY | Integration Plan I2需A_EDIT/真实质量链；I1是保存作者→正式Bake→Runtime链，不是作者Intent约束完整证明。 |
| IMPLEMENTED BEHAVIOR | tool_wire.gd encode_wire先调Schemas.validate；digest对完整encode_wire输出做SHA-256并返回小写hex；decode_wire重编码逐字节校验。内部值编码函数不赋予任意Dictionary合法record身份。 |
| IMPLEMENTED BEHAVIOR | wire_schemas.gd KINDS含intent，但validate没有intent生产schema分支，返回DEPENDENCY_PENDING。authoring分支委派4A validate_authoring；versions/source_manifest/input_manifest/archive_manifest已闭合。 |
| IMPLEMENTED BEHAVIOR | snapshot_capture.gd：authoring_payload_digest=完整authoring wire字节SHA；source_fingerprint=source_manifest wire字节SHA；每次SnapshotIdentity.source_intent_digest固定null，包含合法非空或显式空Intent时也未计算。 |
| IMPLEMENTED BEHAVIOR | run_records.gd make_identity校验SnapshotIdentity第四字段允许null或合法64位hex，输出RunIdentity不复制它。execution_project.gd snapshot_shape同样允许null。 |
| IMPLEMENTED BEHAVIOR | execution_project.gd verify_input校验manifest、附件、authoring/source绑定，但未从sealed authoring重算并比较source_intent_digest。当前nullable字段不是已完成的内容来源证明。 |
| IMPLEMENTED BEHAVIOR | authoring_adapter.gd接受SnapshotIdentity既有四字段，digest允许null或合法hex；BakeProvenance只复制已批准三字段；不消费digest计算formal Level。 |
| INFERENCE | 只摘要resource_ref字符串无法探测同ID的Milestone/Bypass内容变化；完整authoring摘要又会混入不相关世界/资源变化。两者都不能自动解释为Intent源声明闭包摘要。 |
| UNDEFINED | 既有合同未精确定义该摘要的闭包、排序、元数据参与范围、empty/missing/invalid摘要语义及sealed包中的一致性复验。 |
| UNDEFINED | intent record_kind仅被列名，当前并无足以编码作者闭包的已批准闭合shape；也不能据此断言其正式PuzzleIntent生产codec已实现。 |

审计文件：docs/superpowers/specs/2026-09-22-foundation-authoring-editor-design.md、2026-09-22-foundation-authoring-tool-contracts.md；docs/superpowers/plans下2026-09-23-foundation-authoring-data-plan.md、runtime-plan.md、integration-plan.md；tools/foundation/authoring_acceptance下wire_schemas.gd、tool_wire.gd、run_records.gd、snapshot_capture.gd、execution_project.gd；foundation/authoring/authoring_schema.gd、authoring_adapter.gd。审计仅针对Integration登记源码，不以Owner WIP补定义。

## 2. 方案比较与唯一提案

1. 直接用intent record：没有可用作者闭包schema，不能合法直接编码；将作者源和绑定后正式Intent合并会混淆生命周期，不采用。
2. 复用完整authoring digest：已有实现，但不相关Resource或空间变化也会改变值，不满足专属Intent闭包定义，不采用。
3. 推荐：在现有foundationtoolwire.v1中新增封闭record_kind=source_intent。复用唯一编码器和digest函数，不创建第二codec。明确D_PROTOCOL UPDATE_REQUIRED，需正式批准后更新schema registry/VersionsRecord对应版本身份，不能静默拓宽旧schema。

本文选择方案3；新kind与下面的闭包投影均为PROPOSED。既有intent kind不改作作者闭包，不以本稿顺带实现或批准其正式输出schema。

## 3. Digest Owner与精确输入

唯一wire/digest Owner是4D。4A保有作者schema定义权，4D消费已登记A_SCHEMA进行结构校验并执行下面明确限定的纯值引用遍历；不转换Predicate、不绑定Level、不执行4C质量分析。4A不得实现SHA/canonical/JSON hash，4C不生成此摘要。

拟议source_intent记录恰两字段：

```text
{
  root_authoring_id: String,
  resources: Array[ResourceEntry]
}
ResourceEntry = {
  authoring_id: String,
  kind: String,
  document_uri: String,
  resource_uid: String | null,
  fields: Dictionary
}
```

类型/身份/fields规则完全复用A_SCHEMA；本record仅允许一个INTENT根及从它可达的MILESTONE/BYPASS。根由同一AuthoringPayload中所选Level根的fields.intent引用唯一选择，不能任选表中第一个INTENT。根缺失按missing处理；根引用悬空、歧义或非INTENT均invalid。

resources包含根完整entry及递归引用闭包的完整entry，各authoring_id恰一次，按authoring_id的UTF-8字节升序排列。root_authoring_id必须指向表内唯一INTENT。不得多放不相关entry，未知字段/kind、重复ID、悬空引用、种类错误、循环均拒绝。合法共享目标只收录一次，不因重复到达误判循环；遍历期间路径循环才失败。现有MILESTONE/BYPASS fields没有进一步Resource引用，递归不能成为接受未来未知字段的后门。

同一Payload先通过现有A_SCHEMA验证，才可投影。完整resource_table中即使不相关条目非法，也不能把非法Payload包装成有效捕获；“不相关变化不影响digest”仅指双方都是合法Payload时的内容影响。

所有五字段参与摘要，包括document_uri与resource_uid；这是保守的作者源身份摘要，不是去除来源身份后的语义hash。移动闭包资源URI、改变UID/authoring_id会改变digest。没有隐含元数据排除投影。

INTENT.fields所有字段参与：authoring_version、intent_id、required_mechanics、optional_mechanics、expected_milestones、forbidden_bypasses；MILESTONE与BYPASS所有既有fields参与。所有作者声明数组保持捕获顺序，尤其里程碑顺序；不排序标签或bypass数组来隐式等价化。本摘要记录源声明，因此合法标签数组换序也会改变值；仅resources收录顺序规范排序。String与StringName等精确类型按既有wire保留。

不加入run_id、snapshot_id、source_fingerprint、level_hash、rule_version、captured_at、执行配置、Git SHA或计算结果。AT_FACE保留作者face_ref，不先转换成正式face_id再摘要。转换仍归4A Binder。

## 4. Canonical编码与引用变化

```text
source_intent_digest = Wire.digest("source_intent", closed_closure).value
wire envelope = ["foundationtoolwire.v1", "source_intent", tagged_value]
```

精确摘要完整规范wire字节，包括envelope/type tags；SHA-256小写64位hex。只能经公开encode_wire/digest的封闭校验，不绕过schema调用内部值编码。无自含hash、无自引用摘要，也不把digest加入输入闭包。现有大小/深度/精确数值限制不变。

同ID被引用Milestone内容变化、Bypass内容变化、required/optional集合内容变化必须改变规范输入并相应改变摘要（采用SHA-256的正常抗碰撞假设）。有效的无关Resource变化不进入该闭包，digest不变。闭包资源排序不影响摘要，作者里程碑顺序变化影响摘要。

## 5. Binder正式输入与失败语义

维持已批准四参数签名，不增加第五参数：

```gdscript
bind_intent(authoring_intent: Dictionary,
            resource_table: Array[Dictionary],
            successful_bake: Dictionary,
            snapshot_identity: Dictionary) -> Dictionary
```

具体输入字段是既有snapshot_identity.source_intent_digest。SnapshotIdentity仍恰四字段；RunIdentity恰九字段；BakeProvenance恰三字段；SourceMap不变。调用方必须消费4D基于同一sealed/captured AuthoringPayload计算并核验的identity，而非自行提供一个看似合法hex。

合法且存在Intent时该字段必须为非null合法digest。4A验证类型/非空及既有同轮身份、BakeProvenance与SourceMap规则，成功后原值回传source_intent_digest，不重新算hash、不比较自制摘要。4D负责保证该值对应同一authoring_intent与resource_table，4A的hex格式检查不能被称为闭包认证。

Binder任一失败输出ok=false、bound_intent=null、source_intent_digest=null及issues，不能发布候选或保留上一轮digest。缺少Intent不允许用空Dictionary伪造合法空Intent。

## 6. Explicit empty、missing、invalid

| 情况 | 拟议语义 |
|---|---|
| EXPLICIT EMPTY | Intent存在且schema合法、四集合均空。闭包包含完整INTENT entry一个资源，正常计算非null digest；仍执行绑定及正式IntentValidation。不同源身份/intent_id可以有不同digest，不使用固定“空摘要”。 |
| MISSING | Level合法地没有Intent引用；source_intent_digest=null。单独Bake可继续，完整Intent链记MISSING_INPUT；不造空Intent，不对null调用source_intent编码。 |
| INVALID | 源schema/引用闭包非法时不产生可发布source_intent_digest；4D返回失败issues，不返回成功identity。Binder失败时摘要null。本提案不提供诊断用source_intent_digest；原始文件证据hash属于其它既有证据，不能冒名顶替。 |

合法作者Intent后来在正式IntentValidation中失败，不等于作者源schema非法：4D可以已经计算有效源摘要，但它不证明正式约束有效或关卡通过。4C仍独立报告正式失败，不将源摘要当作PASS证据。

## 7. 与其它摘要的关系

source_fingerprint：完整source_manifest摘要，涵盖完整payload、依赖磁盘字节/源定位；可能因无关作者资源或位置变化而改变。source_intent_digest是所选作者Intent闭包摘要，不替代fingerprint，不用于跳过整轮当前性检查。

authoring_payload_digest：完整authoring wire摘要。source_intent闭包从同一经验证payload确定性导出，但摘要不可通过该摘要字符串再hash来获得。两者互不替代，也不直接相等比较。仅改变run不应改变这两个源值；若源定位或源内容变化，按各自输入范围变化。

## 8. D_PROTOCOL与D_SAVED follow-up（待批准，不在本轮实施）

D_PROTOCOL impact: UPDATE_REQUIRED。增加source_intent封闭schema与已登记schema版本身份，沿唯一Wire.digest；补闭包roundtrip、未知字段/类型/重复/悬空/循环/多余entry负例及排序/变化关系测试。不修改formal PuzzleIntent、旧LevelCodec或扩大通用Dictionary。SnapshotIdentity、RunIdentity、ArtifactRef shape不扩字段。

D_SAVED impact: UPDATE_REQUIRED（生产计算和加载校验行为；不是包格式扩字段）。capture_saved应从实际组装的同一Payload计算非空或missing null后返回identity，不再对所有情况写null。execution_project验证sealed包时从已有authoring附件重算闭包摘要，与传入SnapshotRef.identity.source_intent_digest严格比较；不得从活动项目补依赖。不需要新附件或新manifest字段，因为全部源输入已在authoring附件内。input.ready仍最后发布。

重新构造SnapshotRef时由4D从已验证包导出该字段；已有明确字段的SnapshotRef不允许静默把null升级为计算结果来掩盖不一致。旧D_SAVED对合法存在Intent返回null的结果在新规则下不能直接通过新的严格校验。保留历史收据事实，升级后重新捕获并复验，不修改历史证据冒充新版。

现有RunIdentity不存此字段，故不能只比较manifest.identity就声称其已绑定；上述从封包payload重算是必须补足的闭环。摘要自身不进入payload，不形成循环。execution_digest随实际模块/schema版本变化正常更新。

## 9. 交付影响与顺序

| 项目 | 影响 |
|---|---|
| A_BAKE | NONE：已有四字段identity接受合法非空值；正式Level/hash与六字段包装、三字段BakeProvenance均不改。需在后续真实链回归，不制造无源码变化的更新。 |
| A_SCHEMA / SourceMap | NONE：沿现有字段定义，只增加4D消费的闭包记录规则。 |
| D_PROTOCOL | UPDATE_REQUIRED：新record_kind及封闭schema，现有intent kind不挪用。 |
| D_SAVED | UPDATE_REQUIRED：计算、sealed输入重算比较及回归；包schema不扩展。 |
| C_QUALITY | NONE：消费正式八字段bound Intent，仍独立正式IntentValidation；不生成源digest。 |
| I1 | 正式Level/Runtime语义及“不依赖A_EDIT”不变；现有receipt不撤销。未来登记D更新后须复验D2/I1所消费的capture身份行为，不因本稿自动启动I1或提前宣称通过。 |
| I2 | 需要批准本澄清、正式D_PROTOCOL/D_SAVED更新及A4真实接入；仅有文档不能解除A_EDIT等实际依赖。 |

拟议顺序：精确文档批准 → 4D交付唯一闭包codec/digest与D_SAVED闭环 → 协调者登记正式更新/真实复验 → 4A消费新4D identity完成A4 → 后续另行授权集成。任何未交付依赖如实DEPENDENCY_PENDING；不能以4A自制hash替身冒充Real。

## 10. 审阅门槛与本轮范围

未来必须验证：引用ID不变但Milestone/Bypass内容变化会改变digest；required/optional变化；合法无关Resource变化不改变；里程碑顺序保留；表排序稳定；empty/missing/invalid分离；篡改SnapshotIdentity摘要被封包重算拒绝；缺失依赖不回活动源；formal Level/hash不受工具摘要影响。所有这些是待实施验收要求，本轮测试NOT_RUN。

本轮仅文档审计与一致性/变更范围/SHA检查。不修改Spec/Plans、Approval记录、dependency_receipts、Owner源码或WIP。Commit: NOT_RUN。Push: NOT_RUN。I1/I2: NOT_STARTED。不得把本稿视为批准，A4仍等待本澄清批准及真实依赖交付。
