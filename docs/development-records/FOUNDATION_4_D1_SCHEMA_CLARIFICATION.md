# FOUNDATION-4 D1 schema 澄清提案

状态：**D1_SCHEMA_CLARIFICATION_REVIEW_READY / PROPOSED / NOT APPROVED**。

日期：2026-09-23。Owner：Integration 维护公共澄清；4D 仍独占 wire、身份、捕获和归档实现。本文件只提出字段冻结方案，不授予实施许可，不登记 D_PROTOCOL 完成，不启动 I1。

## 1. 依据、缺口与选择

依据为已批准 [Tool Contracts](../superpowers/specs/2026-09-22-foundation-authoring-tool-contracts.md) §1、§5.1、§5.2、§6、§9，[Runtime Plan](../superpowers/plans/2026-09-23-foundation-authoring-runtime-plan.md) D1/D2/D6，以及 [Integration 公共记录](../superpowers/plans/2026-09-23-foundation-authoring-integration-plan.md)。两份冻结 Spec 正文字节保持不变：

- Design SHA-256：`A4D9CD7CCFDE8E4FDB0EEA72746505B995361850E623BEF7952D49849EC9A13F`
- Contracts SHA-256：`C31A03E807A2BF9268D32AA00FA18BCD93C77BAD4C53ED00A8D349FED8462A6B`

批准内容已经要求版本/引擎/执行闭包内容身份和未知字段拒绝，但没有完整 VersionsRecord 字段表；泛称 manifest 同时出现在源摘要、输入封包、执行工程与最终归档语境。D1 计划的 `manifest.byte_length` 示例又与四字段 ArtifactRef 混在一起。这里明确二者不是同一记录。

只读检查 4D 当前十文件：`run_records.make_identity` 对 versions 仅检查非空；`wire_schemas.validate` 只开放 policy，其余类型（包括 manifest）返回 DEPENDENCY_PENDING。原始诊断 `4d_4d-1_identity_diagnostic_09/4D-1/run/results.json` 为 217 checks / 1 failure，失败标签为 `identity cannot certify versions without tool/contracts/engine/module/configuration identities`；不能登记成 GREEN。

考虑的方案：

1. 推荐：移除含混的 `manifest`，新增 `source_manifest`、`input_manifest`、`archive_manifest`，再允许单独编码封闭 `versions`，供 execution_digest 使用。没有第二 codec。
2. 单个 manifest + 强制 discriminator + 三个封闭 union 分支也能严格实现，但同名仍容易误用 digest/完成标记；不推荐。
3. 一个宽松 Dictionary 容纳三类字段违反未知字段拒绝要求，不采用。

**这是对已批准 record_kind 枚举的拟议补充，不是宣称原合同已经允许这些新名字。** 用户批准此独立澄清后才可启用。当前 4D 保持停止线，不需为了通过测试猜字段。

## 2. 全部记录共用的精确规则

- 内存记录是 Dictionary，字段键必须为 String。下表字段全部必填；仅显式标 `| null` 者可为 null。缺失不等于 null；bool 不当 int，StringName 不当 String。禁止额外字段，包括嵌套记录。
- `Digest`：String，恰 64 个小写十六进制字符，表示 SHA-256。`UUID`：String，36 字符规范小写 UUID；沿现有运行身份约束，不另建身份分配器。
- `Version`：非空 String，必须与本文件或已批准正式合同登记的期望字面值匹配；不能只校验正则 `*.v1` 就接受未知版本。
- `ResourcePath`：规范项目内 `res://...`，以 `/` 分隔；禁止空段、`.`、`..`、反斜线、NUL、路径大小写碰撞。`PackagePath`：同样规则但无 scheme、无起始 `/`，相对运行包根。磁盘解析须继续拒绝 symlink/junction 越界。
- `SourceURI`：沿捕获合同，项目文件用规范 res://；未保存文档用稳定 `editor://<editor_instance_id>/<document_authoring_id>`；外部源必须显式登记规范 URI，不能自动搜索活动工程补齐。该显式源位置不等于机器缓存/执行工程路径。机器缓存路径不进入源摘要。
- Array 保持值顺序；需要排序的集合按下列要求在构造前排序，解码器拒绝未排序和重复，不能读入后静默重排。字符串排序按原始 UTF-8 字节，无 Unicode 归一化。Dictionary 则沿 §5.2 按键的 canonical 编码字节排序；二者不混用。
- 附件摘要是实际 canonical wire 文件/正式 Codec 文件/原始冻结文件的字节 SHA-256，不是对象地址、mtime 或 Git HEAD。
- wire envelope、tagged array、精确数值、深度 64、128 MiB 默认限额、读取校验次序均沿冻结合同，不在本稿改变。

## 3. VersionsRecord（完整七字段）

```text
VersionsRecord = {
  record_version: String,
  tool_version: String,
  schemas: SchemaVersions,
  contracts: ContractVersions,
  engine: EngineIdentity,
  modules: Array[ExecutionFile],
  configuration: Array[ExecutionFile]
}
```

| 字段 | 精确值/约束 | 可 null |
|---|---|---|
| record_version | 提议新值 `foundationversions.v1` | 否 |
| tool_version | 已批准工具运行版本 `authoringrun.v1` | 否 |
| schemas | 下述恰九字段 SchemaVersions | 否 |
| contracts | 下述恰九字段 ContractVersions | 否 |
| engine | 下述恰两字段 EngineIdentity | 否 |
| modules | 非空；完整受控执行模块和资源闭包，包括必要脚本、白盒资源及 `.uid`；不包含配置数组的项目 | 否 |
| configuration | 非空；至少含 `res://project.godot`，包含其它真正影响执行的配置文件 | 否 |

SchemaVersions 的九个字段均为 String，不能省略，全部只接受下表字面值。声明一种格式的版本不表示其生产实现已经交付或允许绕过阶段依赖。

| 字段 | 唯一支持值 | 来源 |
|---|---|---|
| wire | foundationtoolwire.v1 | 批准 §5.2 |
| authoring | levelauthoring.v1 | 批准 §1；A_SCHEMA 已实现 |
| intent_authoring | puzzleintentauthoring.v1 | 批准 §1 |
| snapshot | authoringsnapshot.v1 | 批准 §1/§5.1 |
| source_map | authoringsourcemap.v1 | 批准 §1 |
| report | levelacceptance.v1 | 批准 §1 |
| source_manifest | authoringsourcemanifest.v1 | 本稿提议 |
| input_manifest | authoringinputmanifest.v1 | 本稿提议 |
| archive_manifest | authoringarchivemanifest.v1 | 本稿提议 |

ContractVersions 恰九字段：

| 字段 | 精确类型/支持值 |
|---|---|
| schema_version | int，固定 1 |
| contract_version | String，foundation.contract.v1 |
| contract_revision | String，v1.1 |
| orientation_version | String，cube24.v1 |
| rule_version | String，foundation.rules.v1 |
| execution_version | String，foundation.execution.v1 |
| analysis_version | String，foundation.analysis.v1 |
| intent_version | String，puzzleintent.v1 |
| trace_version | String，solutiontrace.v1 |

前七项沿冻结合同 §1/正式 Core；Intent、Trace 沿各正式校验器。所有字段非 null，不能用工具版本覆盖正式版本，也不向正式 Level/Intent/Trace 增添字段。

EngineIdentity 恰 `{version:String, executable_sha256:Digest}`。version 是实际绑定可执行文件输出的完整版本信息字符串（含 status/build/hash 部分），不是仅工程声明的 4.7；不能为空。运行前实际引擎必须与该字符串及可执行文件 SHA 同时一致，并通过既有能力/精度检查。当前证据为 `4.7.2.stable.steam.ed1daf0bf`，不是把所有未来不同引擎自动批准。本记录不含 engine path。

ExecutionFile 恰 `{path:ResourcePath, sha256:Digest, version:Version | null}`：

- 两数组各按 path UTF-8 字节升序；各自及跨数组禁止重复 path/大小写歧义。
- version 是所属模块/配置已登记的版本标识；未单独版本化的资源、UID、配置文件填 null，不能虚构版本。非 null 值必须来自上面已登记版本值集合，且由所属 Owner 的闭包声明指定适用项；不是从文件名/HEAD推测。
- 同版本不代表同内容：所有条目必须校验实际文件 sha256。非 null version 不替代 sha256；null 也不取消内容验证。
- modules 包括受控正式 FOUNDATION、所需 4A/4C/4D 及白盒资源的静态依赖和显式动态依赖。不得为填满清单而复制全项目，也不能先写空 modules 后签有效身份。
- configuration 对真正物化后的有效项目配置取摘要，禁止主项目 autoload/editor plugin、缓存目录和临时绝对路径混入语义设置；机器路径通过包定位/子进程环境处理。确有影响执行的设置不能以“路径”为由排除。
- 本记录不含 source metadata、Git HEAD、构建时间、run_id、generation、engine path 或自身 digest。

**摘要定义（提议）：** `execution_digest = ToolWire.digest("versions", versions).value`。VersionsRecord 七字段及全部嵌套字段都参与；脚本/资源/配置的 path、hash、version、引擎版本与可执行文件 hash 均参与。make_identity 必须先封闭校验，再核对传入 execution_digest 恰为该值，失败仍沿现有签名返回 `{}`，不得返回半有效身份。新运行/编辑代次变化不改变相同执行闭包的摘要。

Git HEAD 仅作来源说明；不得以 clean/commit hash 推导内容身份。它和 engine path 只放下述 SourceMetadata，**不属于 versions，也不进入 execution_digest/source_fingerprint/policy_digest**。

## 4. ArtifactRef 与 manifest 类型分开

ArtifactRef 沿已批准四字段，不新增生产 record_kind：

```text
{relative_path:PackagePath, byte_length:int, sha256:Digest, format_version:String}
```

字段非 null；byte_length >= 0、不得超所选 policy 的附件限额。format_version 必须与消费者预期的已登记格式相符。原始源/执行文件本稿提议统一封装标识 `rawbytes.v1`，只表示按原字节验证，不赋予任意反序列化/执行许可。正式 Level 仍使用原 Codec 格式身份，不改 Level hash。后续若出现这里未列出的附件格式，必须先按其所属已批准合同登记，不能接受任意字符串。

`manifest.byte_length` 不再是模糊测试输入：byte_length 属于 **ArtifactRef**。超 int64/精确数值的纯编码测试继续走 D1 内部值编码用例，不能凭此给 manifest 发明字段。

### 4.1 record_kind = source_manifest

保持批准 §5.2 的恰三字段，不加 run_id 或时间：

```text
SourceManifest = {
  authoring_payload_digest: Digest,
  dependencies: Array[SourceDependency],
  source_locations: Array[SourceLocation]
}
```

其格式版本固定为 `authoringsourcemanifest.v1`，由唯一 kind→schema 注册及 ArtifactRef.format_version/VersionsRecord.schemas 共同验证；本版无内嵌 manifest_version。不存在无版本上下文的任意 manifest 解析。未来如需另一种源清单语义，必须新增受批准的 versioned kind 或提升 wire 版本，不能在同 kind、同字节下重解释 source_fingerprint。

SourceDependency 恰八字段：

| 字段 | 精确类型/规则 |
|---|---|
| source_uri | SourceURI；数组按它升序且唯一 |
| resource_uid | String 或 null；非 null 为捕获时真实 UID，只作定位 |
| kind | String；提议只允许 SCENE / RESOURCE，表示源载体，不是 Level/World 角色 |
| origin | String；SAVED / EDITOR_BUFFER |
| content_digest | Digest；本提案首版固定等于同一 SourceManifest.authoring_payload_digest，覆盖该源选定声明及整关闭包；不是局部文件摘要 |
| disk_digest | Digest 或 null；SAVED 必须非 null；EDITOR_BUFFER 无磁盘源时才为 null，否则记录实际冻结磁盘字节摘要 |
| declared_version | Version；SCENE=levelauthoring.v1；RESOURCE 根 Intent=puzzleintentauthoring.v1，其余白名单语义 Resource=levelauthoring.v1 |
| authoring_ids | 非空 Array[String]；规范 authoring UUID，按 UTF-8 升序、唯一 |

以上 kind/origin/Resource 版本落点为本稿新增具体化，需用户批准；不声称原批准已列过这些 enum。content_digest **统一复用整关 AuthoringPayload 的 authoring_payload_digest**：该值覆盖该源选定声明，但保守地随其它关卡声明变化。这里没有“单文档 payload”捷径，不放宽 4A 对整关闭包的校验；也不新增 document kind 或局部编码器。代价是无法凭这个值单独辨认哪份文档改变，定位仍使用来源记录与原磁盘摘要。该保守投影是本稿明确待批的首版规则，不让实现任选算法。

SourceLocation 恰 `{document_uri:SourceURI, authoring_id:String, node_path:String | null, label:String}`。authoring_id 为规范 UUID；节点用捕获时文档内 NodePath 字符串，资源定位填 null；label 允许空字符串，保存实际捕获标签。数组按 `(document_uri,authoring_id,node_path,label)` UTF-8 字节元组升序，null 先于 String；四元组唯一。主键 authoring_id 仍用于跨改名定位，不把标签当身份。

`source_fingerprint = ToolWire.digest("source_manifest", source_manifest).value`，三字段及每个嵌套值都参与，含明确的 source_uri/节点路径/标签/disk_digest。排除 snapshot_ref、run_id、时间、generation、窗口/相机状态、机器缓存绝对路径。改变文件位置/标签可改变源摘要，这是批准 source_locations 覆盖范围；不能再私自排除。

### 4.2 record_kind = input_manifest（input.ready）

```text
InputManifest = {
  manifest_version: String,       # authoringinputmanifest.v1
  identity: RunIdentity,         # 原九字段，versions 使用第3节
  input_mode: String,            # ANALYZE_CURRENT / ACCEPT_SAVED
  source_manifest: ArtifactRef,
  authoring_payload: ArtifactRef,
  execution_policy: ArtifactRef,
  attachments: Array[ArtifactRef],
  source_metadata: SourceMetadata
}
SourceMetadata = {git_head:String | null, engine_path:String | null}
```

全部顶层字段非 null。SourceMetadata 的键也必须存在：git_head 是真实 40 位小写 Git SHA 或 null，不拿它替代任何文件摘要；engine_path 是实际本机绝对路径 String 或 null，仅溯源，不按历史路径自动启动引擎。路径/HEAD 存在时必须真实，缺失填 null，不伪造。

attachments 按 relative_path UTF-8 升序、唯一且拒绝大小写碰撞，至少完整覆盖三个显式 ArtifactRef、全部冻结输入字节和 VersionsRecord 指定的执行文件/配置。执行文件/配置先冻结为 `input/execution/<sha256>.blob`（ArtifactRef.format_version=rawbytes.v1），每个 ExecutionFile.sha256 必须对应此清单中长度和摘要都已验证的附件；相同字节可复用一个 blob。ResourcePath 只规定随后物化到 `execution/project/<去掉res://的路径>` 的目的位置，不要求 input.ready 引用未来才产生的文件。原始作者磁盘源也在 input 下按摘要命名，不能以路径相同覆盖不同字节。

- source_manifest 格式必须 authoringsourcemanifest.v1，sha256 等于 identity.source_fingerprint。
- authoring_payload 格式必须 levelauthoring.v1，sha256 等于 SourceManifest.authoring_payload_digest。
- execution_policy 格式本稿提议 `authoringpolicy.v1`，sha256 等于 identity.policy_digest；摘要仍为 `digest("policy", policy)`，不改变 policy 字段或数值。
- 三个显式引用必须在 attachments 中有完全相同的四字段项；任何附件长度/摘要或版本错误都拒绝。
- identity.execution_digest 与 identity.versions 按第3节重算匹配；封包身份在全部引用中一致。
- `input_mode == execution_policy.entry_kind == SnapshotRef.input_mode`；若包内另含 InputSnapshot，其 input_mode 也相等。不能用匹配的 hash 掩盖 ANALYZE_CURRENT/ACCEPT_SAVED 模式不一致。
- ACCEPT_SAVED 的每条 SourceDependency.origin 必须 SAVED，disk_digest 必须非 null，source_uri 不得为 editor://。封包前仍须按批准 §5.1 检查已保存磁盘投影与相关当前投影一致、版本/代次/依赖前后复核；仅把 origin 写成 SAVED 不构成已保存证明。ANALYZE_CURRENT 可包含 SAVED 和 EDITOR_BUFFER，但任何技术结果都不能提升成完整验收 PASS。
- input.ready 的内容就是该 input_manifest canonical wire，所有附件 close/重读/核验完成后最后发布。不存在另一个同名宽松 JSON 完成标记。
- attachments **不得列 input.ready 自身**，也不得列含 input.ready 摘要的 SnapshotRef。服务返回的 SnapshotRef.input_manifest 指向完成文件，是外部结果，不回写进被它覆盖的输入，避免循环。
- source_metadata 参与 input.ready 本身的文件摘要；不参与三个独立语义摘要。换机器路径可改变包完成文件摘要，不改变相同源/策略/执行闭包的身份摘要。

Runtime Plan D2 `materialize(...).value.manifest` 推荐返回**已有 input.ready 的 ArtifactRef**：执行闭包条目已包含在 input_manifest，不另创 execution_manifest 格式。顺序明确为：capture 的内部准备阶段冻结声明、模块/配置 blob 并完成复核 → 最后写 input.ready → 返回带该引用的 sealed SnapshotRef → 公共 `materialize(sealed_snapshot_ref, source_root)` 校验完成包，将已冻结 blob 按 ResourcePath 物化/复核到 execution/project，返回 project_root、execution_digest 和原完成包引用。source_root 只用于核对明确来源上下文，不能替代已冻结 blob 或回活动工程找补。公共 materialize 不接收半成品 SnapshotRef，不写假 input_manifest，也不修改 input.ready；内部准备函数不是新增跨 Owner 公共接口。已存在目标文件必须与该闭包逐字节匹配，否则失败，不能覆盖后伪称同一 sealed 输入。

### 4.3 record_kind = archive_manifest（根 manifest.wire）

```text
ArchiveManifest = {
  manifest_version: String,      # authoringarchivemanifest.v1
  identity: RunIdentity,
  input_manifest: ArtifactRef,
  report: ArtifactRef,
  attachments: Array[ArtifactRef]
}
```

顶层全部非 null。attachments 按 relative_path UTF-8 升序、唯一且拒绝大小写碰撞。必须列 report（levelacceptance.v1）、input.ready（authoringinputmanifest.v1）、所引用的完整输入附件闭包及实际生成的正式证据附件；两显式引用必须与列表项完全一致。缺少未运行产物不能拿旧文件填充；失败/取消包允许缺少这些产物，Report 的 missing evidence/native_result=null 如实记录。

根 manifest.wire 自身不得在列表中；report 也不得含自己的 hash 或根 manifest hash。归档清单是最后发布的完成标记，完整核验附件才可接受发布；可验证完成包仍可能是 FAIL/UNDETERMINED，不能据 manifest 签 PASS。历史图附件只读，绝不恢复可信活图。

input_manifest 的 identity 必须与归档 identity 完全相同；report 内 run_identity/versions 也一致。首次发布与后续显式导出失败语义、无覆盖 rename、E 盘路径保持批准 §9 原样。

## 5. kind/摘要/兼容边界

| 项目 | 拟议处理 |
|---|---|
| `manifest` | 从支持枚举删除；明确 WIRE_SCHEMA_INVALID，绝不按字段猜 source/input/archive；目前没有可用该类型产物，故无正式数据迁移 |
| `versions` | 新增；仅第3节七字段；作为 execution_digest 的唯一 canonical wire 输入 |
| `source_manifest` | 新增；仅第4.1节三字段；其摘要就是 source_fingerprint |
| `input_manifest` | 新增；仅第4.2节；input.ready 完成标记，digest 仅作为包引用摘要 |
| `archive_manifest` | 新增；仅第4.3节；manifest.wire 完成标记 |
| 其它既有 kind | 名称、正式语义保持原样；尚未实现者继续 DEPENDENCY_PENDING |
| ArtifactRef | 仍是四字段嵌套记录，不偷换成 `manifest`，无独立任意附件加载接口 |

kind 枚举变化属于公共合同增补，批准后各工具版本支持矩阵须同步更新；wire 的通用 tagged-value 表达不变。旧 D1 接收端遇到新 kind 必须拒绝，不兼容回退到 Dictionary。记录版本未知、字段未知、错误 kind、跨类型交换都失败，不能“尽量读”。

## 6. 对当前 4D 十文件及 4C 的影响

| 当前文件（均由4D修改，本轮只读） | 获批后预计最小变更 |
|---|---|
| tools/foundation/authoring_acceptance/wire_schemas.gd | 新增 VersionsRecord/三类 manifest 的精确字段与域校验、kind 分派、跨引用约束；继续复用正式校验/A schema，不复制作者投影 |
| tools/foundation/authoring_acceptance/run_records.gd | make_identity 校验完整 versions 及 execution_digest；原签名、九字段返回、失败 `{}` 不变 |
| tools/foundation/authoring_acceptance/tool_wire.gd | tagged-value 算法不重写；若新增 kind 注册全在 schemas 则可不改本文件；digest 继续走同一 codec。避免 run_records↔tool_wire↔schemas preload 循环 |
| tools/foundation/authoring_acceptance/boundary_control.gd | 预计无需改变取消/租约逻辑 |
| tests/foundation/authoring_acceptance/test_tool_wire.gd | 替换当前四字段临时 versions fixture；新增封闭记录及 digest/完成标记负例；原 217 项相关意图不得删除或放宽 |
| 上述五个 .gd.uid | 身份保持，不重新生成；无需新增第十一文件 |

旧 fixture `{tool,engine,engine_sha256,modules:[]}` 和 `{bogus:true}` 都应拒绝；前者是未冻结样例，不是公共兼容格式。必须先用精确有效 VersionsRecord 构造正例，再验证所有必需字段、嵌套未知字段、空闭包、重复路径、顺序、错误版本、hash/engine/config 不匹配、错误 kind、manifest 循环引用被拒绝。不要只给 bogus 单独写特判。

还需增加获批后的 D2/协议用例：未 sealed 输入不能调用公共 materialize；冻结后源磁盘再变不能替换冻结 blob；input_mode/entry_kind/SnapshotRef 模式任一不一致均拒绝；ACCEPT_SAVED 携带 EDITOR_BUFFER、editor:// 或 null disk_digest 均拒绝；即使模式字段一致，捕获时当前投影与已保存投影不一致仍返回 SAVE_REQUIRED，不产生 sealed 输入。

4C 的 `run_quality(level,bound_intent,policy,identity,boundary_control)` 及 QualityRunResult 字段不变；只消费 identity.versions 时按获批后的完整形状透传/验证，更新局部 fixture。4C 不获得第二 versions/digest/wire 实现权限，仍等待真实 D_PROTOCOL。版本列表出现某正式模块名字不代表该模块已交付或整链通过。

## 7. 待批准内容与停止线

请用户审阅并决定是否批准：七字段 VersionsRecord、嵌套版本表及 nullable 模块版本；新增 versions + 三个 manifest kind/删除旧 manifest；三份完整字段表、排序/闭包/循环规则；源依赖 content_digest 复用整关声明摘要的保守首版方案；D2 materialize 复用 input.ready 引用的装配约定。

这些是**澄清提案**，并未获批。尤其整关声明摘要投影、源载体 kind enum、新格式标识和 kind 枚举补充必须在此次审阅中明确接受，不能以“兼容原语义”为由绕过批准。不同意时修改本独立提案，不修改两个冻结 Spec 正文，不让 4D 先做一版再反推合同。

本轮没有修改 4D 十文件，没有消费未提交的 4D 实现，没有向公共收据填 D_PROTOCOL/C_QUALITY/B_EDITOR/A_BAKE/A_EDIT。未执行 I1 或实际跨 Owner 业务集成。批准后仍由各 Owner 在其授权范围内实现并交正式阶段证据。
