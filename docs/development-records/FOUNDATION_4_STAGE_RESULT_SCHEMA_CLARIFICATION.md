# FOUNDATION-4 Stage Result Schema Clarification — revised review

Status: STAGE_RESULT_SCHEMA_CLARIFICATION_REVIEW_READY
Date: 2026-09-27 (Asia/Shanghai)
Previous SHA-256: 3DFC9EE12A751F0F0F108659C69A66D6D9D74CDD29895D896D0D129C69E0A9C6
Previous status: SUPERSEDED_REVIEW_VERSION / DO NOT APPROVE

本稿是待审修订，不是批准记录。仅修改此文档，不修改Spec/Plans、Owner源码/WIP、receipts或现有密封包，不运行D3 Tween/I1。

## 1. 审计事实及范围

Tool Contracts §7.1冻结内存StageRecord字段与执行语义；§7冻结WorkerMessage身份/sequence及先附件后消息；§9冻结run目录和manifest-last。Integration Plan公共接口表引用StageRecord，4D Plan规定唯一工厂、materialize及进程传输Owner。

当前run_records.gd返回14字段内存骨架；wire_schemas.gd只列名stage_result，没有生产validate分支。D_SAVED capture_saved封存输入和执行源，D2 Real验证Bake/Codec但不发布正式BAKE stage_result。因此本稿补充持久化协议，不将已有内存骨架冒称完整wire实现。

## 2. 唯一envelope与注册表

外层仍为 `["foundationtoolwire.v1","stage_result",tagged_value]`。payload恰两字段：

```text
{
 run_identity: RunIdentity,
 stage_record: StoredStageRecord
}
```

不再使用旧提案storage_version或stage字段；不得保留兼容别名或metadata袋子。schema身份由正式schema registry/VersionsRecord绑定，变更须正式版本更新。未知字段、类型、版本或分支拒绝。

RunIdentity恰为已批准的editor_instance_id:String、run_id:String、generation:int、level_ref:LevelRef、snapshot_id:String、source_fingerprint:String、policy_digest:String、execution_digest:String、versions:VersionsRecord。沿已批准UUID、digest、非负generation及封闭LevelRef/VersionsRecord校验；不增加本机定位字段。

StoredStageRecord恰14字段：

```text
{
 stage_id: String,
 owner: String,
 module_ref: String,
 applicability: String,
 execution: String,
 reason: String,
 input_refs: StageInputRefs,
 actual_policy: StagePolicy,
 actual_budget: StageBudget,
 native_result: StageNativeResult | null,
 evidence_refs: StageEvidenceRefs,
 warnings: Array[StageWarning],
 started_at: String,
 finished_at: String
}
```

StageInputRefs/Policy/Budget/NativeResult/EvidenceRefs/Warning均为按stage_id选择的封闭类型，不是任意Dictionary别名。完整Stage ID枚举保持：AUTHORING、BAKE、INTENT_BIND、INTENT_VALIDATE、ORIGINAL_GRAPH、SOFTLOCK、ABLATION、TRACE_SEMANTICS、MILESTONES、GRAPHICAL_REPLAY、MANUAL_RUNTIME、ARCHIVE。

本次实际注册：BAKE → 下文BAKE分支。其它枚举成员不是unknown ID，但其storage分支尚未在本稿冻结，encode/decode必须返回DEPENDENCY_PENDING，不得用BAKE或通用Dictionary代替。枚举外stage_id、未知native分支/字段/版本返回schema错误。未来注册必须分别批准，不能靠optional graph等字段逐渐扩成宽松容器。

## 3. 终态及null规则

wire仅代表已进入执行且达到终态的阶段。execution允许COMPLETED、INCOMPLETE、ERROR、CANCELLED。RUNNING拒绝。纯NOT_RUN不发布worker STAGE_RESULT，仅由父RunEvidence/Report记录；不适用且未执行同样不伪造worker结果。

COMPLETED必须有该stage完整正式返回，native_result不得null。INCOMPLETE/ERROR/CANCELLED：实际正式调用有完整返回就必须保留；没有返回才为null。不得编造status、套上一轮结果、把null当成功或把未运行写成ERROR。reason在非COMPLETED时必须为非空真实工具层原因；不能伪装或篡改原生结果码。COMPLETED不等于PASS。

时间为真实UTC RFC3339毫秒字符串YYYY-MM-DDTHH:mm:ss.sssZ；finished_at不早于started_at。开始前取消属于NOT_RUN，不发布本wire。开始后未进入正式调用即失败/取消可发布对应终态null；若进程崩溃无法发布，由父侧记录实际错误，不伪造子进程消息。

## 4. BAKE精确分支：保留旧成功shape

BAKE固定stage_id="BAKE"、owner="4A"、module_ref="res://foundation/authoring/authoring_adapter.gd"、applicability="APPLICABLE"。

```text
StageInputRefs = { input_manifest: ArtifactRef, authoring_payload: ArtifactRef }
StagePolicy = { max_configurations: int, max_checks: int }
StageBudget = { max_configurations: int, max_checks: int }
StageEvidenceRefs = { canonical: ArtifactRef | null }
StageWarning = 无成员类型；本次warnings必须是空数组
```

预算为真实调用值，两个整数均大于零，满足正式Baker合同，actual_budget=actual_policy，并与sealed execution_policy.bake_options一致。无返回时也记录已确定的实际调用预算，不捏造执行计数。COMPLETED reason为空；其它终态沿§3。

保留旧稿成功BAKE native_result六字段及类型，不另造第二种成功BAKE表示：

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

计数为实际非负整数，status=0是正式VALID。内存native_result是原A_BAKE六字段返回；存储仅将level值替换为正式Codec canonical ArtifactRef，其余返回保留。非null结果目前只注册这一已冻结的成功原生分支，不允许删掉真实issues/warnings来套入它。

这一成功返回也可能在工具层超时/取消后才返回：须保留它，但execution/reason保留真实工具终态，不签发PASS。已有完整失败/INCOMPLETE原生Bake返回但其存储分支未注册时，必须保留内存实际结果并报告storage DEPENDENCY_PENDING，不能发布null冒充“没有返回”。本稿不假称覆盖所有失败Bake结果。

native_result=null只在INCOMPLETE/ERROR/CANCELLED且无正式返回时允许，此时evidence_refs恰为{canonical:null}，不得引用历史canonical。非null成功分支中evidence_refs.canonical与native_result.level逐字段相等；warnings固定空。有实际warnings时本次schema不支持，拒绝存储而不丢信息。

SourceMap仍内联，沿现有4A字段：

```text
{map_version:String, snapshot_id:String, source_fingerprint:String,
 level_hash:String, entries:Array[Entry]}
Entry = {authoring_id:String, document_uri:String,
 node_path_at_capture:String|null, resource_uid:String|null,
 resource_subpath:String|null, local_face:int|null,
 entity_kind:String, entity_id:StringName|null, field:String,
 reader_path:String|null, canonical_path:String|null}
```

map_version=authoringsourcemap.v1；成功level_hash非null合法hash；local_face非null时为正式FaceDirection。其余类型/身份沿4A已登记SourceMap描述，不能自动String转换；发现实际类型冲突应报告而非放宽为Variant。4D实现存储校验，不复制作者定位算法。

本BAKE分支不把source_map改成ArtifactRef，避免第二种BAKE shape。未来另行批准SourceMap附件分支时唯一位置为artifacts/stages/BAKE/source_map.wire；当前不接受两种表示自动择一。

## 5. 正式目录、ArtifactRef与协调产物

唯一run root：`<project-run-root>/.godot/foundation-authoring/runs/<run_id>/`。内部input/、execution/project/、ipc/、staging/、artifacts/沿已有合同；不创建第二套run布局。

所有ArtifactRef.relative_path都相对同一个run root：

- stage_result：artifacts/stages/<STAGE_ID>/stage_result.wire
- BAKE canonical：artifacts/stages/BAKE/canonical.level
- 未来SourceMap附件：artifacts/stages/BAKE/source_map.wire
- 其它已注册分支附件：artifacts/stages/<STAGE_ID>/<artifact-name>，名称由对应schema明确白名单；不是任意上传路径。

ArtifactRef仍恰relative_path:String、byte_length:int、sha256:String、format_version:String。长度非负，hash为64位小写hex；拒绝绝对路径、空/点段、..、反斜线、路径逃逸、大小写歧义、重复路径、symlink/junction逃逸。stage id段必须使用上述精确大写枚举。

本提案stage_result引用format_version固定foundationtoolwire.v1，按消息期望record_kind=stage_result解码并验证schema registry身份；canonical为levelcanonical.v1，表示正式LevelCodec schema_version=1输出，不新建Level codec。input_manifest仍为authoringinputmanifest.v1且relative_path=input.ready；authoring_payload仍为levelauthoring.v1并逐字段匹配manifest引用。

input.ready只封住输入/执行闭包；发布stage输出不得回写input/、input.ready或原execution/project/。stage结果位于artifacts/，不是受控工程代码。

当前E:/godot/foundation-4-d3-unblock-20260927/canonical.level仅为COORDINATION_HANDOFF_EVIDENCE，不是正式stage publication，也不是产品ArtifactRef来源。现有JSON handoff只作COORDINATION / TEST HANDOFF EVIDENCE，不作为D_HOST loader协议。

批准并实现后，4D正式stage publication必须验证同一canonical bytes，再发布至原绑定run的artifacts/stages/BAKE/canonical.level并生成正式ArtifactRef。要求sha256=22f63447bc282029190d0c8b29a2016630c176b8dcce91dc2b1c94a9677484f9、byte_length=4171、正式content_hash=51aa7a4cf9b9328ed533434bf579b4ab9ae8393687f33fcc39a982f3f6d8a72e。不改Level，不Bake另一fixture，不依赖协调目录作为永久运行输入。

如重新执行阶段发布，必须绑定原作者输入/真实BAKE身份和返回证据，不能为满足schema虚构预算、时间或返回记录。缺少完整原生证据时不能从canonical倒推伪造StageRecord；先补真实证据/合法执行边界，记录新阶段结果且不覆盖已有发布。重新发布不授权改变已密封输入或改用其它作者源。

## 6. WorkerMessage闭环

沿正式六字段：protocol_version、identity、sequence、kind、stage_id、payload_ref_or_inline。不扩字段；protocol_version使用正式WorkerMessage注册版本，不能用stage_result版本替代。本文只规定kind=STAGE_RESULT分支，不借此冻结其它消息未完成的schema。

STAGE_RESULT唯一方式：payload_ref_or_inline必须是ArtifactRef，指向artifacts/stages/<stage_id>/stage_result.wire。禁止inline StageRecord、native_result、canonical bytes、JSON sidecar。identity为完整RunIdentity，sequence按既有每方向单写者单调协议，过期/重复/跳号均报协议问题，不覆盖已接收结果。

父侧原子接受顺序：

1. 校验WorkerMessage封闭schema、正式protocol_version、完整identity与当前期望run。
2. 校验sequence及stage_id为当前可接收阶段，不推进已接受游标直到整个结果核验完毕。
3. 验证stage_result ArtifactRef固定路径、run根 containment、长度与实际bytes SHA。
4. decode_wire("stage_result", bytes)，拒绝unknown字段/类型/版本/未注册分支。
5. message.identity == stage_result.run_identity，全字段精确相等。
6. message.stage_id == stage_result.stage_record.stage_id。
7. 校验全部输入绑定及全部非null输出ArtifactRef：存在、同run根内、长度/hash一致、format/schema合法。
8. 全部通过才接受整个记录并推进sequence；任一失败拒绝整个消息，不部分接受native_result，不覆盖当前有效记录。

消息引用的SHA是完整stage_result.wire字节SHA；stage_result不包含自己ArtifactRef/hash，避免循环。

## 7. 输入、产物与身份复核

stage_record.input_refs.input_manifest绑定同轮input.ready，authoring_payload匹配其中正式引用。解码input_manifest后比较其identity与stage_result.run_identity逐字段相等；校验VersionsRecord wire摘要=execution_digest、policy附件摘要=policy_digest、authoring/source_manifest绑定及source_fingerprint，不凭run_id或level_hash单字段判断。

BAKE module_ref必须在identity.versions.modules中，以实际文件SHA绑定；Bake执行engine/模块必须与该BAKE身份相符。bake_provenance恰三字段分别与run_identity对应值相等；SourceMap snapshot_id/source_fingerprint一致。

canonical先核验路径、length、SHA，再调用正式LevelCodec.decode及正式shape/content_hash验证；Level.content_hash=source_map.level_hash，level_id对应level_ref。不允许运行时Bake补缺、活动Owner worktree补洞或手填canonical路径。

D3加载链：run_dir → input.ready identity → 已发布worker/stage result ArtifactRef → decode_wire("stage_result") → identity/stage/hash验证 → BAKE native_result → canonical ArtifactRef → canonical bytes → LevelCodec.decode → WhiteboxHost。离线打开同样必须取得正式已发布ArtifactRef并执行完整校验；不能因没有在线worker而降级到JSON或路径约定。

## 8. 发布事务与manifest-last

阶段只有一个最终不可覆盖记录；临时文件放现有staging/内，接收方不消费临时文件。所有rename发生在同一run、同一文件系统，拒绝覆盖既有最终文件。

1. 写全部native/output附件临时文件 → close → 重读length/hash → rename至artifacts/stages/<STAGE_ID>/正式路径；再次核验最终引用。
2. 仅当所有附件完成后编码stage_result.wire → 写临时文件 → close → 重读/hash/公开decode校验 → rename至最终stage_result.wire → 复核最终ArtifactRef。
3. 最后发送WorkerMessage(kind=STAGE_RESULT)，只引用该最终ArtifactRef；IPC文件自身仍沿已有临时写/close/rename规则。

失败保留可确认部分证据，不发成功结果、不修补旧记录、不覆写input.ready。最终run级manifest.wire仍按§9在全部正式附件后发布，report/manifest自身不形成循环摘要。阶段发布标志不等于run级PASS或最终归档完成。

## 9. Graph持久化隔离

内存StageRecord.native_result保留本次正式活结果。含graph的正式阶段落盘前必须：把graph单独编码为record_kind=graph_archive的只读附件，再在该阶段的已批准持久化native schema中移除live graph字段，以graph_archive_ref:ArtifactRef替换；其余正式字段保持不变。此转换不是可逆可信图恢复接口。

graph_archive仅用于archive/read-only inspection。禁止重建可信live graph交Softlock/Ablation或重新签发完整性证明；4C Softlock仍只接收同次Explorer直接返回的内存活图。

BAKE、INTENT_BIND、INTENT_VALIDATE、TRACE_SEMANTICS、MILESTONES、GRAPHICAL_REPLAY、MANUAL_RUNTIME、ARCHIVE等不含正式活graph的native分支禁止graph、live_graph、graph_handle、可恢复Object。BAKE还明确禁止graph_archive_ref。不得把这些字段放进通用optional字段袋。

ORIGINAL_GRAPH及其它实际含graph阶段必须有独立注册schema，明确graph_archive_ref位置/附件格式/其余原生字段。当前未注册，返回DEPENDENCY_PENDING；本稿不以原则性替换规则冒称完整Solver storage schema已冻结。作者任意字典也不能借字段名绕过stage-specific校验。

## 10. 全payload路径边界

所有嵌套字段包括RunIdentity/VersionsRecord、module_ref、SourceMap、input_refs/evidence_refs/native_result及reason/warnings均不得携带机器文件绝对路径（Windows盘符/UNC、POSIX根路径、run/execution/user/temp/cache绝对目录）。不得把本机路径混入诊断文本后落盘；不合规值须拒绝，不能静默删改原生结果。SnapshotRef.root_path只在进程内定位，绝不进入本wire。

允许的路径值只有：

- ArtifactRef.relative_path：规范run-root-relative路径。
- 作者source URI：规范res://逻辑URI；editor://仅在ANALYZE_CURRENT且相应作者schema已批准允许时可用，ACCEPT_SAVED拒绝。不能以逻辑URI包装盘符/..逃逸。
- module_ref/VersionsRecord模块：正式res://模块引用或原合同明确的仓库相对版本身份，不是本机绝对路径。
- SourceMap node_path_at_capture、resource_subpath、reader_path、canonical_path：已批准的逻辑/结构路径，不是操作系统路径；不允许绝对路径或路径逃逸。

不得泛化为“任何String都可作路径”。与现有封闭类型冲突时fail closed并报告合同问题。SourceMap文件化只能通过已批准分支的run-relative ArtifactRef，不能写绝对日志路径。BAKE evidence_refs当前只有canonical字段，不接受路径数组或任意inline信息；其它stage inline evidence必须另行注册闭合类型。

## 11. Execution materialization更新的身份边界

当前动作预检包不含已完成whitebox入口。4D需完成入口、更新自有execution dependency closure，以实际新模块/schema/engine/配置重算execution_digest，构建新的受控materialization并从其execution/project真实启动入口。禁止主项目preload冒充，禁止往旧密封run塞WIP，禁止沿用旧digest掩盖模块变化。

这不授权重新Bake不同源；原Snapshot/source_fingerprint及canonical内容身份必须可验证地保留。原BAKE stage_result仍绑定原实际Bake RunIdentity，不能把其versions/execution_digest或BakeProvenance追改成新宿主身份。

实现限制必须明确：当前execution_project.materialize(snapshot_ref, source_root)只能恢复input.ready绑定的files/versions，不能单靠再次调用此API就获得新模块闭包。4D须交付受控execution materialization更新能力，区分“原sealed输入/BAKE证据身份”与“新宿主实际执行身份”，建立显式经核验的绑定；不得要求两套不同模块身份相等，也不得放宽本稿WorkerMessage与其stage_result完整身份相等规则。新宿主不能把旧BAKE消息冒充自己新身份产生的结果。

该能力涉及D_SAVED执行物化合同/实现follow-up，不能由本稿凭空宣称已存在的API支持。其新执行身份承载/绑定方案须先独立冻结并审阅后实施，不在stage_result塞metadata解决。若该绑定尚不可证明，正式入口停链；动作预检证据仍有效但D_HOST未解锁。

## 12. 影响与验收边界

D_PROTOCOL: UPDATE_REQUIRED，stage_result及worker_message STAGE_RESULT分支、BAKE封闭存储/终态null/身份校验；不修改其它Owner算法。
D_SAVED: input package schema和原封存输入不变；仅发布artifacts不要求重写capture，但本轮要求的新入口闭包更新超出现有materialize能力，因此execution materialization follow-up为UPDATE_REQUIRED，绑定设计须先冻结。此前source_intent_digest批准引出的D_SAVED更新义务独立保留。
D_HOST: STILL_BLOCKED_PENDING_APPROVAL_AND_PROTOCOL_IMPLEMENTATION，并须满足受控入口身份绑定依赖。
D3_REVIEW_REQUIRED: SESSION_WRITE_EXPOSURE，仍由4D RED→修复→GREEN，不跨Owner修改。

后续顺序：批准精确澄清 → 4D实现/交付协议更新 → Integration登记 → 必要D_SAVED更新与兼容复验/新materialization绑定审阅 → 4D正式stage publication及loader → 真实受控入口 → Tween/natural finished/finish_local/finish_global/Session commit证据 → D_HOST。任何步骤未交付不以替身或协调JSON替代。

本轮没有批准、代码或测试实施，没有修改现有run/4D九个WIP，不启动I1。原动作能力LOCAL/GLOBAL预检结果保留为历史事实，不能当作Tween完成。Commit: NOT_RUN。Push: NOT_RUN。
