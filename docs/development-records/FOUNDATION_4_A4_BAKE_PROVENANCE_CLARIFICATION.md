# FOUNDATION-4 A4 Bake provenance contract clarification

Status: A4_BAKE_PROVENANCE_CLARIFICATION_REVIEW_READY

本文为待审阅澄清稿，不赋予实施授权，不登记新的交付。I1/I2: NOT_STARTED。

记录时间：2026-09-23T21:14:10.634084+08:00。

## 1. 核验基线与范围

- Integration R4: f1333fa5997f707eb01d4c93fd0c3297c05ccd77。
- A_BAKE: 03e581d2c3ec28a1b42074d88495ce7ef580411d。
- D_PROTOCOL: 6176a45c614f678c8b248d5289f9a672a971043b。
- 当前slot仍为BASE、I_HARNESS、A_SCHEMA、A_BAKE、D_PROTOCOL、C_QUALITY。

本稿仅补充工具层Bake结果与Binder的同轮来源证明。不修改冻结Design Spec、Tool Contracts或五份Implementation Plans的字节；不修改4A/4D源码、旧AuthoringReader/LevelBaker/LevelCodec及正式Level schema。不扩大其他公共合同，不批准A_EDIT/D_SAVED/I1/I2完成。

核验对象是R4中已登记的正式D_PROTOCOL文件，逐项SHA与receipt一致；不以4D活动工作树的未交付实现作为兼容依据。

## 2. 原合同冲突

依据：

- Tool Contracts §4（当前文件108–110行）要求本轮Bake成功、level非null、真实validation为VALID；无法证实同轮来源必须拒绝绑定。
- 4A计划公开接口（111行）将A2结果列为五字段：ok、level、issues、validation、source_map。
- 4A-4 RED（234行）要求失配run/snapshot/hash失败；GREEN（250行）只指定source_map.snapshot_id及source_fingerprint供交叉核对。
- 当前authoring_adapter.gd校验输入snapshot_identity的run_id，却没有将run_id保存在返回值中；source_map只有snapshot_id和source_fingerprint等来源字段。

因此successful_bake本身缺少run_id证据，Binder不能区分run_id不同而其余可见证明相同的输入。source_fingerprint明确排除run_id，重复源内容可具有相同fingerprint。snapshot_id标识快照，不是结果中显式携带的执行run身份；当前返回也没有可供Binder验证的snapshot→run关系。不能凭“通常一个快照对应一个run”、调用上下文、历史缓存或重新传入的当前run猜测生产者身份。

4A以CONTRACT_MISMATCH停止是正确行为；本稿审阅通过前不得要求4A靠推断绕过该缺口。

## 3. 拟定 BakeProvenance：恰三个字段

```text
BakeProvenance = {
  run_id: String,
  snapshot_id: String,
  source_fingerprint: String
}
```

封闭记录：恰上述三个String键，值均为String；缺字段、unknown field、错误类型、字段值null均拒绝。不得以StringName或自动类型转换替代String。身份值沿现有SnapshotIdentity输入约束验证，不创建第二套身份生成、摘要或版本算法；run_id/snapshot_id非空，source_fingerprint为既有64位小写十六进制SHA-256声明。

禁止加入level_hash、rule_version、captured_at、paths、Git SHA、engine info、authoring_id、source_intent_digest或任何其他字段。没有新增record_version或wire record_kind。

职责：只记录该A_BAKE调用实际消费的经验证执行身份。4D仍唯一拥有Snapshot/RunIdentity及其生成规则。4A从该次snapshot_identity复制三个字段形成独立值；不生成、不修复、不推导run_id/snapshot_id/fingerprint，不重新计算fingerprint。不得引用可被后续调用改写的整份输入Dictionary，或在Binder执行时从当前identity补造provenance。

这是进程内工具结果的来源绑定证据，不是签名或对任意可伪造Dictionary的密码学认证，也不提供新的持久化或跨进程恢复能力。

## 4. 拟定 A_BAKE 六字段工具包装

函数签名不变：

```text
bake_authoring(payload: Dictionary,
               bake_options: Dictionary,
               snapshot_identity: Dictionary) -> Dictionary
```

返回精确shape：

```text
{
  ok: bool,
  level: Dictionary | null,
  issues: Array[Dictionary],
  validation: Dictionary | null,
  source_map: Dictionary,
  bake_provenance: BakeProvenance | null
}
```

包装恰六字段；原五字段语义保持。不得把扩展字段加入正式LevelBaker返回、Reader输出或正式Level数据。

本稿对可空结果的明确提案（随本稿审阅）：

- 成功：正式Bake成功且validation为VALID时，bake_provenance必须非null，等于该调用入口经验证后保存的三字段副本。
- 所有失败出口：ok=false、level=null、bake_provenance=null；原issues/validation/source_map继续按既有语义提供诊断，不保留上次成功provenance。
- 输入身份非法时不构造有效provenance。临时树释放、成功/失败资源清理及失败不回填旧level的规则完全不变。

现有snapshot_identity仍是既有输入（含source_intent_digest）；只投影其三个指定字段，不改变输入shape。source_intent_digest仍按既有Binder接口从4D提供的身份回传，不进入BakeProvenance。

旧五字段结果不具有本澄清所需证明，不能在Binder中自动兼容补字段；缺失bake_provenance必须明确拒绝，不能拿调用方当前identity冒充生产者来源。

## 5. Binder完整核验顺序

bind_intent的签名与输出包装不变。先验证输入类型及封闭结果shape，再检查：

1. successful_bake.ok严格为true。
2. successful_bake.level非null且为正式可接受Level；不能把任意非空Dictionary当作成功Level。
3. successful_bake.validation为正式有效ValidationResult，status为现有ValidationTypes.ValidationStatus.VALID；null、非法结果、INVALID或INCOMPLETE均拒绝。不新增私有Baker validation seam或自制Validator。
4. bake_provenance非null，满足恰三字段封闭shape；snapshot_identity也必须通过现有输入身份验证。
5. 逐字段严格相等，不归一化、转换或回填：

```text
bake_provenance.run_id == snapshot_identity.run_id
bake_provenance.snapshot_id == snapshot_identity.snapshot_id
bake_provenance.source_fingerprint == snapshot_identity.source_fingerprint
source_map.snapshot_id == bake_provenance.snapshot_id
source_map.source_fingerprint == bake_provenance.source_fingerprint
```

source_map相应字段缺失、类型错误或任何比较不一致都失败。任何前提不成立：ok=false、bound_intent=null，并通过既有issues报告具体失败；不能产生可用的旧候选。source_intent_digest的既有回传/失败语义不由本稿改写。

绑定成功时，正式Intent.level_hash仍只取successful_bake.level.content_hash；rule_version仍只取successful_bake.level.rule_version。不得从BakeProvenance、旧缓存或作者声明替代。正式Intent八字段及后续正式IntentValidation责任不变。

## 6. SourceMap与正式产物保持原职责

SourceMap继续负责作者来源和诊断定位，不新增run_id或承担执行身份Owner。现有map_version、snapshot_id、source_fingerprint、level_hash、entries及定位规则均保持；已有level_hash不因本稿删除，也不替代Intent绑定时读取level.content_hash的规则。

正式Level schema、content_hash计算、rule_version、Reader量化/orientation及Baker/Codec合同均不变。BakeProvenance不进入Level内容摘要，不导致相同内容仅因run不同而改变Level hash。

## 7. 4D正式兼容审查

D_PROTOCOL compatibility: COMPATIBLE（范围限上述已登记6176a45版本与本稿进程内扩展）。

证据：

- wire_schemas.gd:5的KINDS没有完整A_BAKE wrapper或BakeProvenance类型。
- validate在12–22行将authoring交给4A的输入schema；它不是A_BAKE输出包装。
- 23–31行只额外实现versions/source_manifest/input_manifest/archive_manifest/policy；其余已命名kind返回DEPENDENCY_PENDING。没有已交付的stage_result/quality_result/report/worker_message codec接受完整Bake wrapper。
- tool_wire.gd:8–19的公开encode_wire先执行Schemas.validate；decode_wire也重新通过encode_wire核验。内部带类型Dictionary编码能力不等于任意产品记录合法，不得绕过公开schema。
- run_records.gd:34–38仅构造StageRecord骨架，native_result初始null；BAKE阶段名及native_result容器并非完整A_BAKE包装的封闭wire schema，也不赋予任意Dictionary跨进程许可。

结论：当前没有受影响的已交付wire record，无需改D_PROTOCOL、VersionsRecord、manifest、RunIdentity字段或摘要算法，不新增wire版本。本稿也不把尚未交付的source_map/stage_result等schema宣称为已实现。

后续若4D的worker/report/归档确实需要编码完整A_BAKE包装或BakeProvenance，必须在其明确封闭schema中审查和实现，列出受影响record及适用版本；不得直接接受未知Dictionary字段。本稿不预先批准该未来wire扩展。

## 8. D_SAVED、I1/I2与交付影响

D_SAVED impact：无已登记D_SAVED需要迁移，R4中仍未交付。其SnapshotRef/input package/manifest格式不因本提案变化；待本稿获审阅批准后，消费新A_BAKE的进程内调用和测试应检查六字段结果及三字段身份，不用SourceMap猜run。若存在完整wrapper的精确字段断言，需要按批准澄清更新对应Owner测试；本轮不检查或修改未交付活动实现。

I1 impact：作者→唯一4A适配→正式Reader/Baker→canonical Level→Runtime链和正式Level消费不变。新增工具证明不使I1依赖A_EDIT，也不要求改Runtime；后续接入新版A_BAKE时核对真实调用身份及新返回shape。当前仍缺D_SAVED、D_HOST和test_saved_vertical.gd，I1 NOT_STARTED。

I2 impact：A4绑定同run的缺口需要此澄清审阅通过并由4A实际实现/验收后才能消除；仅有文档不足以解除。仍缺A_EDIT、D_JOBS和test_quality_replay.gd等真实接入条件，I2 NOT_STARTED。

未来A_BAKE源码变化必须由4A正常交付新commit与文件SHA，协调者另行更新唯一receipt；本稿不改变当前03e581d交付事实、不给旧五字段结果追认provenance，也不登记A_EDIT。

## 9. 审阅后的最小验收意图（本轮均未实施）

- 成功结果六字段；provenance恰三字段且等于入口身份；输入Dictionary后续改变不改写已有结果。
- provenance缺失/null、unknown字段、缺字段、类型错误和旧五字段包装均使Binder拒绝。
- 仅改变run_id而保留snapshot/fingerprint的负例必须拒绝；其余两个identity字段及两个SourceMap交叉字段分别失配也必须拒绝。
- failed Bake、level=null、validation不为正式VALID均拒绝，bound_intent=null；所有失败出口不残留旧level/provenance。
- 同内容不同run的provenance不同，正式Level内容摘要仍由Codec决定；Intent hash/rule始终来自当前成功level。
- 复核真实Reader/Baker/Codec及资源释放回归；不创建新坐标/orientation/hash算法。

本轮只进行源码/合同只读兼容核验、文档一致性检查与SHA计算；未创建测试脚本、未运行产品行为验收、未修改Owner文件、未commit/push。待用户审阅本精确文档版本后再决定后续授权。
