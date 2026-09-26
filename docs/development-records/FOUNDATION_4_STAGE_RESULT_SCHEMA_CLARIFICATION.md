# FOUNDATION-4 Stage Result Schema Clarification — BAKE success storage

Status: STAGE_RESULT_SCHEMA_CLARIFICATION_REQUIRED / REVIEW_READY

本稿未批准，不授权修改4D WIP。范围仅冻结供D3读取成功BAKE正式产物的stage_result存储分支，不能冒充全部阶段协议已完成。

## 1. 审计结论

Tool Contracts §7.1已列出StageRecord内存字段及execution枚举；§7规定native_result保留正式返回，落盘图附件须明确替换且不得恢复可信图。Integration Plan公共表引用这些字段，4D Plan把工厂与报告schema归4D。

当前run_records.gd make_stage_record返回14字段骨架：stage_id、owner、module_ref、applicability、execution、reason、input_refs、actual_policy、actual_budget、native_result、evidence_refs、warnings、started_at、finished_at。wire_schemas.gd只列名stage_result，没有对应validate分支，公开encode_wire返回DEPENDENCY_PENDING。

D_SAVED capture_saved只封存authoring/source_manifest/policy、执行源与input.ready；没有持久化BAKE StageRecord。D2 Real测试实际调用A_BAKE/Codec验证，但没有交付正式stage_result。不能把测试日志当正式产品协议。

缺口不是仅需把已有完整schema翻译成代码：input_refs/actual_policy/native_result分阶段封闭形状、顶层身份绑定及成功BAKE canonical存储投影没有唯一冻结定义。因此本稿新增提案，须审阅批准后才可由4D实施。

## 2. 拟议唯一wire envelope与成功分支

复用foundationtoolwire.v1，record_kind=stage_result；无第二codec、无custom JSON Bake sidecar。payload恰三字段：

```text
{
 storage_version: String = "bakestageresult.v1",
 run_identity: RunIdentity,
 stage: BakeSuccessStoredStage
}
```

RunIdentity沿已批准九字段与VersionsRecord封闭规则，不增字段。只实现本storage_version对应的BAKE成功分支；其它版本、阶段、未运行/失败/取消分支必须明确拒绝为未交付schema，不通过可选字段或任意Dictionary兜底。后续阶段必须另行冻结其storage分支；本稿不批准通用宽松StageRecord序列化。

BakeSuccessStoredStage恰14字段：

```text
{
 stage_id: String = "BAKE",
 owner: String = "4A",
 module_ref: String = "res://foundation/authoring/authoring_adapter.gd",
 applicability: String = "APPLICABLE",
 execution: String = "COMPLETED",
 reason: String = "",
 input_refs: { input_manifest: ArtifactRef, authoring_payload: ArtifactRef },
 actual_policy: { max_configurations: int, max_checks: int },
 actual_budget: { max_configurations: int, max_checks: int },
 native_result: BakeSuccessStoredResult,
 evidence_refs: { canonical: ArtifactRef },
 warnings: [],
 started_at: String,
 finished_at: String
}
```

两个预算字段必须与本轮真实调用的bake_options一致、严格大于零并满足现有正式Baker允许范围；actual_budget与actual_policy相等。本分支不允许额外策略。时间为真实UTC RFC3339毫秒时间戳（YYYY-MM-DDTHH:mm:ss.sssZ），finished_at不得早于started_at，不填虚构时间。warnings固定空，仅供无warning成功分支；有warning的真实结果不能丢弃warning强行装入本分支，须等待明确扩展。

本字段集合保持内存StageRecord名称，不增加completion或顶层PASS。COMPLETED仅表示调用返回；D3仍必须验证下面原生成功语义及真实产物。

## 3. native_result的明确存储投影

```text
BakeSuccessStoredResult = {
 ok: bool = true,
 level: ArtifactRef,
 issues: [],
 validation: {
   status: int = 0,
   issues: [],
   configurations_checked: int,
   checks_performed: int
 },
 source_map: SourceMap,
 bake_provenance: {run_id:String, snapshot_id:String, source_fingerprint:String}
}
```

status=0为现有ValidationStatus.VALID；计数必须是实际正式返回非负整数。只有真实ok=true、VALID、无issues的成功A_BAKE结果可进入此窄分支。错误/不完整/带issues结果不能被清空或改写成成功。内存native_result仍保留原A_BAKE六字段，其中level是正式Level；存储时仅把level替换为canonical ArtifactRef，其它值不改写。读档返回存储记录，不能把ArtifactRef冒充内存Level或直接传给Binder。

SourceMap沿Tool Contracts §8既有精确shape，内联以唯一wire带类型编码：

```text
{map_version:String, snapshot_id:String, source_fingerprint:String,
 level_hash:String, entries:Array[Entry]}
Entry = {authoring_id:String, document_uri:String,
 node_path_at_capture:String|null, resource_uid:String|null,
 resource_subpath:String|null, local_face:int|null,
 entity_kind:String, entity_id:StringName|null, field:String,
 reader_path:String|null, canonical_path:String|null}
```

map_version固定authoringsourcemap.v1；本成功分支level_hash非null合法hash；Entry字段值继续服从已交付4A SourceMap实际类型/身份规则，不能接受其它Variant/Object。4D必须消费4A正式schema/描述，不另写作者定位算法；实施前若实际类型与上述提案不一致应报告CONTRACT_MISMATCH，不能转换字符串掩盖。该内联存储分支不自动宣称独立source_map record已交付。

ArtifactRef恰relative_path:String、byte_length:int、sha256:String、format_version:String。byte_length非负，sha256小写64hex；path为显式产物包根内相对路径，拒绝绝对路径、..、大小写歧义及symlink/junction逃逸。canonical format_version拟定levelcanonical.v1，仅指既有LevelCodec schema_version=1编码结果，不是新Level格式；不得手写或改变正式Codec。level与evidence_refs.canonical必须相同。

## 4. 身份及读入验证

1. input_refs.input_manifest精确绑定同轮已封存input.ready ArtifactRef；authoring_payload必须等于该manifest的正式authoring_payload引用。
2. run_identity必须与input_manifest.identity逐字段一致，包括完整VersionsRecord及execution_digest；不凭run_id单字段确认。
3. bake_provenance三字段与run_identity对应值一致；SourceMap snapshot_id/source_fingerprint一致；完整A_BAKE来源验证沿已批准澄清，不额外塞digest到provenance。
4. module_ref必须在run_identity.versions.modules内，以其SHA证明实际模块身份；实际engine须匹配封存版本。跨包根的输入引用由调用方显式提供sealed input根，输出canonical引用仅相对输出包根，两个根不能混用。
5. 先核验canonical长度/hash，再由正式Codec.decode恢复Level，正式shape/content_hash验证成功；Level.content_hash等于source_map.level_hash，level_id对应run_identity.level_ref。不得运行时重新Bake补缺或读取活动worktree。
6. 同一sealed输入可能被不同策略执行，故必须核对完整identity/policy，不能只比较level_hash。

## 5. 发布顺序与D3边界

D_SAVED input.ready是作者输入封口，不含后来BAKE产物，不允许补写它。本提案采用独立、显式输出包根；先写canonical、close/readback并核验，再写完整stage_result.wire为此成功阶段的最后发布标志，拒绝覆盖。发布标志不得含自己的hash；交付侧另给stage_result ArtifactRef，避免循环。input.ready/最终archive_manifest各自原有语义不变。

D3必须消费正式wire阶段记录定位canonical，custom JSON sidecar只能作为旧测试证据，不能继续作为最终产品加载协议。当前Coordinator action证据JSON仅是离线交接证据，不赋予正式stage_result身份，也不得被canonical_loader当成替代协议。

D_PROTOCOL UPDATE_REQUIRED。4D需实现闭合schema、真实roundtrip/unknown字段/错identity/错ref/错误原生状态负例及读取验证。D3当前9个WIP保持原样，由Owner收到批准及正式依赖后自行RED→修复→GREEN。

## 6. 当前交付与未完成项

Integration作者fixture独立提交323891ec27859a60d33fe2d59c2633621b7f55d8真实生成action-capable canonical；动作能力不代表Tween或D_HOST通过。本提案尚未批准，正式stage_result不READY，不能宣布D3完全解锁。

D3_REVIEW_REQUIRED: SESSION_WRITE_EXPOSURE。
受控execution project当前不包含未交付whitebox_entry.gd；Coordinator提供真实路径用于后续Owner流程设计，不能往已密封项目补WIP。4D正式交付入口/依赖后需重新形成包含入口的受控执行包，并实际启动入口，而非主项目preload。

Presenter、真实Tween、natural finished、finish_local/finish_global、转场后Session commit由4D-3证明，本轮NOT_RUN。I1 NOT_STARTED，仍遵守等待更新D_PROTOCOL/D_SAVED的已有批准顺序。本轮仅使用用户特别指定的旧D2能力做D3动作产物预检。
