# FOUNDATION-4 Registry Module URI / Execution Closure Clarification

Status: REVIEW_REQUIRED
Approval: NOT_APPROVED
Recorded date: 2026-10-05 (Asia/Shanghai)
Owner: Integration 公共合同记录；4D 保持唯一协议、捕获与执行闭包实现 Owner。
CONTRACT_MISMATCH: REGISTRY_MODULE_URI_EXECUTION_CLOSURE_BOUNDARY_UNDEFINED（本稿提交 review；尚未以批准替代此阻塞）

Previous review SHA-256: 17FCBE2E911CC566964831F4BEE2763DBCA06CFF2626ED59B297E62BD04A9951
Previous review disposition: INCOMPLETE；当前受控工程阶段集合/来源未唯一冻结，七项协议基础依赖分类需要分离。本修订仅供重新review，不消费该旧SHA的条件批准。

Second review SHA-256: 93D32EEB65F2ED1552ACD027AAAEA091765F0072C445CED373191C28A7462FE9
Second review disposition: INCOMPLETE；未明确冻结policy.stages不能重定义stage顺序、prerequisites及质量算法依赖。本次只补澄清正文，并明确D2 capability与Stage Storage范围；该SHA不获批准，本修订仍REVIEW_REQUIRED / NOT_APPROVED。

## 1. 本轮目的、基线与效力

本稿只澄清 registry 实现身份与实际执行依赖的关系。下文“拟冻结规则”是本次单一建议，须精确版本批准后才实施，不修改冻结 Spec/Plans 或已有 Approval 正文，不为任何 Owner 宣告新交付。

| 正式事实 | 精确 commit |
|---|---|
| 当前 Integration HEAD / D_PROTOCOL receipt | 342a51f463697caf8953a56591ee1a16ecd1e02f |
| D_PROTOCOL | 8f7fb52f029053bda10b965da840c6763fc13bf0 |
| 当前正式 D_SAVED | 8289d804c3b5b42a2e6c2cf76e965679a0f83af8 |
| D_SAVED receipt | dd3cc6db6a27b7d843bc87ca5d70dbef550656f2 |
| BASE | bd393303d3a21ae3ddebc6643a94a114437365a3 |
| A_SCHEMA | 2908b99dd641d94cda7ea2995bf5ddefb3d82a64 |
| A_BAKE | e0940278fe425d7f77eb6a5b4ea042067606258d |
| C_QUALITY | bb27f8c7cd6e2d9d94fbe3b8d3f98b99f86484d1 |
| 正式 D_HOST（不升级） | b9bf7d4a02398cd354fab6a18948babaa22c531e |
| canonical_loader compatibility candidate（非 D_HOST PASS） | 8289d804c3b5b42a2e6c2cf76e965679a0f83af8 |
| I1 历史 FROZEN_PASS | 14936504ae4245cc1822786937f021afce4a7fd9 |

已读取唯一 dependency_receipts 的真实 slot/路径。A_EDIT、D_JOBS 不在正式登记集合。存在文件与正式交付身份分开：本文 BASE 文件 SHA 从 BASE Git blob 计算，并与当前文件 SHA 比较一致；不把活动 Owner WIP 当交付。

## 2. 正式依据与缺口

审计来源为两份冻结 Spec、4A/4D/4C/Integration 四计划，D1 VersionsRecord 澄清及独立批准，Stage Result 澄清及独立批准，D4 Required Stage Storage 澄清及独立批准，以及当前 D1/D2 源码。原文的历史待审标题不否认独立精确 SHA 批准。以下区分已批准依据与本稿新增裁定。

| 来源 | 已批准约束 / 本次结论依据 |
|---|---|
| Design §§2、6–8、12.1 | 唯一作者适配/Bake；Intent 绑定与质量分工；先保存源→Bake→白盒，后续完整质量；不是所有任务都先做全验收 |
| Tool Contracts §5.1(6)(7) | 仅物化正式 FOUNDATION 与必要 4A/4C/4D、受控宿主、白盒资源；静态/显式动态依赖必须完整；禁止活动工程补洞 |
| Tool Contracts §§5、6、7 | VersionsRecord / execution_digest 与 policy 身份分别绑定；StageRecord.module_ref 表明实际生产模块；完成不等于 PASS |
| 4D Plan“wire与任务实现约束”，当前第135行 | 首条只 Bake/手动运行的 policy 不列质量阶段、不要求提前加载 C；全验收 C 必需；A/quality 在实际需要而未交付时 DEPENDENCY_PENDING |
| 4D Plan 4D-2、4D-3、4D-4 | D2 捕获/封存/物化；D3 同轮白盒；D4 执行/传输/Replayer，C 未就绪阶段不得执行 |
| 4A Plan 4A-4 / Track A Approval“唯一执行顺序” | 成功 A_BAKE + 同轮 SnapshotIdentity；source_intent protocol→D_SAVED digest→4A-4→A_EDIT；不是 A_EDIT→所有 D_SAVED |
| 4C Plan 公开接口、4C-1/2 | run_quality 唯一编排；同次 Explorer 活图直接交 Softlock；Ablation 独立搜索；所选 trace 单独验证 |
| Integration Plan 依赖图/交付表、I1/I2 | D2/D3 首条链不等全质量或 A_EDIT；I2 需要真实 A_EDIT/C_QUALITY/D_JOBS |
| D1 Clarification §3 + Approval | schemas 声明格式身份，不表示生产实现已交付；modules/configuration 列实际受控闭包文件与 SHA；唯一摘要完整绑定 VersionsRecord |
| Stage Result §§7、10 + Approval | 发布实际 stage 时，其 module_ref 必须存在于该 run 的 versions.modules 并绑定实际 SHA；整个 payload 不接受机器绝对路径 |
| Required Stage Storage §§2、5、10、11 + Approval | 十阶段封闭生产模块；四 schema 键在每个 current VersionsRecord 都 mandatory，即使不执行全部阶段；D_JOBS Real 另需实际 A_EDIT/C_QUALITY 与兼容受控闭包 |

关键缺口：没有已批准条款要求“每个 registry module_ref 字面量均为每个 D2 run 的加载依赖”。mandatory 格式键、实际阶段生产模块、实际文件闭包是三种不同证明。现代码的一刀切字面量规则不能反向成为此要求的合同依据。

## 3. 当前失败证据（只读复核，未重跑）

上一轮 Owner checkout：
E:/godot/worktrees/block-girl-foundation-runtime-saved-closure

证据根：
.godot/foundation-authoring-tests/

| 上轮证据 | 实际结果 |
|---|---|
| 4d_dsaved_stage_storage_registry_red_20261004_c | 82 checks / 11 failures，exit 1，产品 stderr 0 bytes，doubles=[] |
| 4d_dsaved_stage_storage_registry_d1_regression_20261004 | 3698/3698，exit 0，stderr 0 bytes；仅 BoundaryControl 状态提供者 Unit double，无算法 double |
| actual 814a-era run | 在正式 input_manifest schema gate 被拒绝；固定 input.ready SHA 校验、四新键缺失检查、读取前后该文件字节不变 |

不能把上轮 D1 检查数当本轮重新运行。初次 RED 的缺目录观察 stderr 已留档，最终干净 RED 不覆盖它。历史 run 的不改写断言只覆盖 input.ready，不宣称整个目录逐字节审计。

execution_project.gd:130 先调用 _closure，:134 才直接复制 S.SCHEMA_VERSIONS / S.CONTRACT_VERSIONS 构造 VersionsRecord。新键已能通过唯一 registry 取得，无须第二版本表。_closure:168–176 对所有 res://*.gd 字面量要求 files 存在。新 wire_schemas STORAGE_OWNERS:555–565 为阶段实现身份表，不执行其字符串指向的算法。

prepare / capture_saved 的真实返回：
- code=DEPENDENCY_PENDING
- path=res://foundation/authoring/intent_binder.gd
- message=Static/literal dependency is not frozen

这发生在 registry 发布之前，未产生合法新 current-profile run。不是 parse error、receipt 未接或测试不存在。六个未封存 URI 全部列于下一节；不只解决第一项后再撞后续项。

## 4. 完整 URI 枚举及单一分类建议

正式 registry 的实现身份字段实际叫 module_ref，没有 module_uri / implementation_uri 新字段。全部固定实现身份为 STORAGE_OWNERS 九项及 BAKE 固定比较一项：**10 个唯一 URI**。MANUAL_RUNTIME/ARCHIVE 在本 storage profile 没有已注册终态 producer URI；不得猜补。schemas 16 键及 contracts 9 键是版本值，不是另十几个可执行 URI。

B = STAGE_SCOPED_EXECUTION_DEPENDENCY。这里包括已选受控入口的真实静态/动态支持闭包；“stage-scoped”不等于只能在算法正在调用那一刻才加载。凡真实 preload/import 能到达的依赖必须提前完整封存，不能因阶段稍后可能 NOT_RUN 而漏掉。

| stage / registry profile | module URI | 正式 Producer Owner / 编排 | 存在 | 正式交付 commit / 文件 SHA-256 | 当前用途 | 当前 D2 检查 / 已封存 | 当前工程真实加载要求 | 分类 |
|---|---|---|---|---|---|---|---|---|
| AUTHORING / foundationstagestorage.v1 | res://foundation/authoring/authoring_schema.gd | 4A | YES | A_SCHEMA: 2908b99dd641d94cda7ea2995bf5ddefb3d82a64；SHA=f01d2a7e32b8269e5f9322a15eb60f58440b5f5a13046bb9cac5a08456dd5979 | 验证已捕获作者值；Wire authoring/source_intent 会实际 load 此 schema | 全字面量规则要求；已登记 | YES，实际 schema load | B |
| BAKE / foundationstagestorage.v1 | res://foundation/authoring/authoring_adapter.gd | 4A | YES | A_BAKE: e0940278fe425d7f77eb6a5b4ea042067606258d；SHA=8e24075cc398a2c8e8e3542157d985e316b17ff14e5322f4396ad8b6cba6992b | 正式 A_BAKE 包装与 Reader/Baker；保留现有 Bake 支持 | 全字面量规则要求；已登记 | YES，已选 Bake 能力 | B |
| INTENT_BIND / foundationstagestorage.v1 | res://foundation/authoring/intent_binder.gd | 4A | NO | NOT_DELIVERED: NONE；SHA=NONE | 四参数 Binder；只在真正执行 INTENT_BIND 的工程内加载 | 全字面量规则要求；未登记 | NO，仅未来选中阶段触发 | B |
| INTENT_VALIDATE / foundationstagestorage.v1 | res://foundation/quality/intent/intent_validation.gd | 3C / 4C | YES | BASE: bd393303d3a21ae3ddebc6643a94a114437365a3；SHA=3d7b6373f263388462a1bd5727564c0ff376903f4fc2f499c0e2d9c8d7a18e51 | 正式 IntentValidation；由 4C 质量链调用 | 全字面量规则要求；未登记 | NO，仅未来选中阶段触发 | B |
| ORIGINAL_GRAPH / foundationstagestorage.v1 | res://foundation/solver/state_explorer.gd | 3A / 4C | YES | BASE: bd393303d3a21ae3ddebc6643a94a114437365a3；SHA=536badc3a36d47df297e541e742c506f158759f7edd87c2abf0fc18f34b92482 | 正式 Explorer；由 4C 质量链调用 | 全字面量规则要求；未登记 | NO，仅未来选中阶段触发 | B |
| SOFTLOCK / foundationstagestorage.v1 | res://foundation/quality/softlock/softlock_analyzer.gd | 3B / 4C | YES | BASE: bd393303d3a21ae3ddebc6643a94a114437365a3；SHA=0a22a5bc8b7901b9d375996e10beea78825ad2770290cf9f55622a6d540a4aee | 正式 Softlock；同进程消费 Explorer 活图 | 全字面量规则要求；未登记 | NO，仅未来选中阶段触发 | B |
| ABLATION / foundationstagestorage.v1 | res://foundation/quality/intent/ablation_analyzer.gd | 3C / 4C | YES | BASE: bd393303d3a21ae3ddebc6643a94a114437365a3；SHA=8ec8e876e57ce7260351754811a6f6aff8cb3f920e886591e08d049a3f0e91de | 正式 Ablation 独立 baseline/子搜索 | 全字面量规则要求；未登记 | NO，仅未来选中阶段触发 | B |
| TRACE_SEMANTICS / foundationstagestorage.v1 | res://foundation/solver/solution_trace.gd | 3A / 4C | YES | BASE: bd393303d3a21ae3ddebc6643a94a114437365a3；SHA=a45fdbc78e61db5782f298454dc7a9a560b409872973feec57eb99f181060d30 | 正式 Trace 结构/语义；亦为已有显式动态依赖 | 全字面量规则要求；已登记 | 保留已有白名单；不主张 capture 已执行此算法 | B |
| MILESTONES / foundationstagestorage.v1 | res://foundation/quality/intent/milestone_analyzer.gd | 3C / 4C | YES | BASE: bd393303d3a21ae3ddebc6643a94a114437365a3；SHA=3acdd52daa1ccd96b75518bd2fd06aa84cd41d59cab181844d1c003f7f03e693 | 正式所选原图 trace 里程碑分析 | 全字面量规则要求；未登记 | NO，仅未来选中阶段触发 | B |
| GRAPHICAL_REPLAY / foundationstagestorage.v1 | res://foundation/parity/trace_replayer.gd | 3D / 4D | YES | BASE: bd393303d3a21ae3ddebc6643a94a114437365a3；SHA=39a4eeac753c1fba8c2f5ada215811a6755dd69efb3bf7b56143137a4949e87f | 正式 Replayer；现有白名单已有此支持模块 | 全字面量规则要求；已登记 | 保留已有白名单；不主张 capture 已执行此算法 | B |

表中“当前 D2 要求”描述现行过宽扫描，不能充当拟批准规则。表中“需要加载”描述 capture/已选 Bake 与白盒工程的实际用途，不宣称上轮成功启动，也不把已登记支持模块擅自删掉。TRACE_SEMANTICS/GRAPHICAL_REPLAY 现有白名单支持与算法已执行是不同事实。

十项registry实现URI分类统计：A=0，B=10，C=0。GLOBAL EXECUTION MODULE COUNT = 0（限十项registry stage producer；不表示不存在必须封存的基础设施）。
- 不选 A：已批准 stage publication 确实要求生产模块在实际 run 的 versions.modules 中；不能把它永久降为无加载/内容绑定义务的纯审计信息。
- 不选 C：未找到所有 run 必须包含所有十个 producer 的明确批准；反而存在先 Bake/手动、后质量的阶段化依赖依据。
- 推荐 B：注册表项在未激活阶段只作身份声明；一旦实际入口/阶段或真实加载边需要该模块，存在性、UID、传递闭包、SHA 和启动校验全部严格成立。一个 URI 仍只有 B 分类，不因是否激活在 A/B 间切换。

### 4.1 完整扫描的七个真实协议加载依赖

为避免将 metadata 例外误伤 preload，额外列出三个协议文件中全部其余 res://*.gd URI。三文件去重总数为 **17**：上述10个阶段实现身份 + 下列7个真实协议依赖。七项不是registry stage producer，不纳入十项A/B/C分类；统一归为 BASE_PROTOCOL_LOADING_DEPENDENCY / STRICT，全部存在且在当前 D2 白名单中。当前使用ToolWire/RunRecords/schema的受控工程无条件封存这些真实加载依赖及其传递闭包，不受算法stage是否活跃影响。这里的基础依赖与C类“由全局registry强加所有stage实现”不是同一个概念。

| URI | Owner / 当前用途 | 当前闭包规则 |
|---|---|---|
| res://foundation/contracts/contract_validation.gd | Core；wire_schemas SS_DATA preload | 必须继续封存 |
| res://foundation/contracts/foundation_types.gd | Core；SS_CORE_TYPES preload | 必须继续封存 |
| res://foundation/solver/search_records.gd | 3A；SS_SEARCH preload | 必须继续封存 |
| res://foundation/solver/solver_types.gd | 3A；SS_SOLVER_TYPES preload | 必须继续封存 |
| res://foundation/rules/rule_types.gd | 2A；SS_RULE_TYPES preload | 必须继续封存 |
| res://tools/foundation/authoring_acceptance/tool_wire.gd | 4D；run_records 实际 preload | 必须继续封存并绑定正式 D_PROTOCOL SHA |
| res://tools/foundation/authoring_acceptance/wire_schemas.gd | 4D；ToolWire/run_records 实际 preload | 必须继续封存并绑定正式 D_PROTOCOL SHA |

authoring_schema 同时在阶段身份表和实际 load 路径出现，已在十项矩阵中按唯一 URI 计一次。不能因为它也有身份元数据用途，就免除它的真实 load 依赖。间接依赖、UID、scene/resource 闭包继续递归计入实际文件清单，不假称17个就是整个 execution project 的文件数量。

## 5. 拟冻结的唯一 D2 依赖规则

### 5.1 三种身份不得相互代替

1. VersionsRecord.schemas/contracts：当前协议支持的格式/语义身份。所有 mandatory 键始终精确校验；不执行某阶段不允许删键。
2. registry 的 producer URI：某阶段的正式实现是谁；规范 res://、精确 stage/owner/module_ref 匹配，不因文件目前存在就授权执行该阶段。
3. VersionsRecord.modules/configuration：这个 run 实际封存的可执行和资源闭包，逐文件实际 SHA。只包含需要的受控模块/配置，不用版本字符串或 Git HEAD 替代 bytes，也不把未交付 URI 配虚构 SHA/null 文件加入清单。

拟唯一规则：execution_closure = transitive_closure(base_execution_dependencies ∪ implementation_dependencies(actual_execution_stage_set))，再纳入对应UID、真正资源和有效配置。基础集合包括七项协议加载依赖与现有严格受控声明；stage集合必须按§5.3由正式入口/请求唯一确定。不得用全部registry URI、目录扫描或文件存在性决定集合。

当前已有 execution_dependencies.json 仍是唯一受控依赖声明，modules/dynamic/engine/version 的封闭结构保持。保留现有合法白名单，不在此审计中增删任何项；后续需要的选择、检查和 stage 依赖汇合由4D维护，不让A/C各写一套闭包构建器。本稿不新增 ExecutionPlan wire、policy token、RunRequest 参数或通用动态 loader。

### 5.2 metadata 与真实加载边的精确边界

允许不作为加载边的，仅是当前批准 registry 中用于声明/精确比较 stage producer identity 的数据位置，例如 STORAGE_OWNERS 的 module_ref 值和 BAKE 的 module_ref 比较。其 URI 与阶段身份仍由原 D_PROTOCOL 验证；不是忽略全部字符串或所有叫 module_ref 的字段。

真实依赖始终包括：
- 已选 entry 的脚本/场景及白盒资源；
- 执行脚本实际 preload、load、ResourceLoader 调用与其引用传播；
- 场景 ext_resource、受控资源引用、UID 对应目标；
- 明确登记的动态路径和它们的传递依赖；
- ToolWire 使用的 schema 及 schema 自身真正调用的作者/正式值校验支持；
- 实际将执行的阶段 producer 及其调用的正式模块、4C唯一编排和图形支持。

同一个 URI 若还被真实加载或作为声明依赖，必须按该真实边封存；metadata 用途不抵消执行用途。若以后 load(STORAGE_OWNERS[stage][1]) 实际把 registry 值送入 loader，它成为阶段限定动态执行边，须经已选阶段/显式动态声明约束并封存。无法证明间接加载目标集合时停链，不以 metadata 名义豁免。除明确身份声明/比较位置外，现有保守检查不能被整文件跳过。

实现不得仅按 URI 值全局过滤、文件名特判 intent_binder、跳过 wire_schemas、只抓一行 preload 正则然后漏掉变量 load，或对任意 Dictionary 的同名字段给豁免。判定依赖来自值在代码中的执行用途，不能只看扩展名或目录。下一轮4D实现必须用对应负例证明此边界；本稿只冻结义务，不提供绕过检测的代码。

### 5.3 当前D2能力集合、D4阶段集合、唯一来源与执行边界（本次新增待审裁定）

当前代码没有独立execution-plan参数：capture_saved(request,project_root)仅接受原RunRequest；Execution.prepare(source_root)读取封闭execution_dependencies.json。该JSON只有version/engine/modules/dynamic，没有stage集合。本修订不假称该字段或stage exporter已存在，不允许D2 Owner自行补一个来源。

本修订拟将现有D2 saved-only入口的受控工程能力唯一冻结为以下静态profile（仅本合同称谓，不是新wire token/字段）：

| 入口/请求用途 | D2 controlled-project capability set / D4 actual stage set | 集合权威来源 |
|---|---|---|
| 当前D2 capture_saved生成的保存作者→Bake→手动白盒工程 | [AUTHORING, BAKE, MANUAL_RUNTIME] | 本节冻结的D2入口职责，依据4D Plan 4D-2/3、首条只Bake/手动规则与Integration I1；所有此入口调用使用同一集合 |
| D4真正执行完整ACCEPT_SAVED请求 | 原RunRequest.policy.stages的完整有序集合，即现有ACCEPT_STAGES十一项 | 已校验、冻结并进入policy_digest的正式请求；不得裁剪ARCHIVE或其它required阶段 |
| D4真正执行ANALYZE_CURRENT局部请求 | 原RunRequest.policy.stages的已校验精确集合 | 既有正式请求；RunRecords默认值为[AUTHORING, BAKE, MANUAL_RUNTIME]，不按源码存在性增减 |

当前D2的实际capture函数只执行作者投影/校验、source_intent摘要、执行文件准备、输入封口；它不执行BAKE算法或启动MANUAL_RUNTIME。表中的三阶段集合规定随后该受控工程允许提供的能力，不把封存当作阶段已运行，不制造STAGE_STARTED/STAGE_RESULT证据。BAKE仍必须由正式A_BAKE真实执行，手动宿主只消费同run正式BAKE证据。

D2的[AUTHORING, BAKE, MANUAL_RUNTIME]恰为CONTROLLED PROJECT CAPABILITY SET，不是Stage Storage required stage list。MANUAL_RUNTIME在当前十个stage_result storage stage之外，沿Required Stage Storage批准保持OUT_OF_SCOPE；不得新增MANUAL_RUNTIME stage_result branch、registry module URI或storage schema。

当前D2 execution closure唯一导出为：transitive_closure(BASE_PROTOCOL_LOADING_DEPENDENCIES ∪ current D2 controlled-project capability dependencies ∪ 其它现有正式non-stage runtime dependencies)，并封存相应UID/资源/配置及实际SHA，全部参与既有execution_digest。AUTHORING/BAKE要求正式producer及真实传递依赖；MANUAL_RUNTIME要求既有Runtime/Host闭包。其它八个registry stage producer不因身份声明进入D2能力依赖；正式能力集合只有未来另行批准才能改变。现有显式支持脚本的封存义务保持，不将其封存解释为请求对应算法stage。七项基础协议依赖无条件存在、封存和绑定实际SHA，禁止活动源fallback。

D4实际stage选择唯一来自已校验的RunRequest.policy.stages；不得从registry、文件存在性、已有artifact、WorkerMessage或历史run推断额外stage。policy.stages只选择实际执行阶段，不重新定义stage顺序、stage prerequisites或质量算法依赖关系；这些继续服从已批准4D / Quality / Integration plans及其正式编排。本澄清只规定哪些源码/资源进入closure，不授权任意stage执行器。缺少已选阶段所需正式前置时拒绝/DEPENDENCY_PENDING，不删stage、不重排来规避前置，不以metadata例外放宽质量活图、独立搜索或trace校验关系。

当前D2入口排除INTENT_BIND、INTENT_VALIDATE、ORIGINAL_GRAPH、SOFTLOCK、ABLATION、TRACE_SEMANTICS、MILESTONES、GRAPHICAL_REPLAY、ARCHIVE作为计划执行阶段。已有solution_trace/trace_replayer等显式支持依赖仍按原白名单严格保留；“支持脚本封存”不等于把其算法stage加入计划。现有modules/dynamic全部维持，不因stage profile收缩而删除已批准的真实/显式支持依赖。

Current D2 capture executes INTENT_BIND = NO；Current D2 profile requires Binder = NO。只有实际计划包含INTENT_BIND或出现真实加载该Binder的执行边时才要求正式Binder。文件碰巧存在不能激活该stage，文件缺失不能让D4删掉已请求stage。profile由正式入口职责决定，未被批准的任意profile/入口组合不得由Owner猜测接受。

当前capture_saved仍校验并封存ACCEPT_SAVED policy的全部十一项要求；不得把policy.stages改成三个阶段以绕过完整验收。三阶段D2工程是第一条纵向交付的输入/能力包，不能据此宣称完整ACCEPT_SAVED可执行或PASS。D4不得直接在这种sealed工程上执行完整请求；其实际stage集合按表中请求选择，必须在封口前建立对应完整闭包，未具备该封存路径时明确DEPENDENCY_PENDING，不静默复用三阶段profile。

由完整请求到不同阶段工程的调度/捕获接线尚属于D4实施职责，不由D2本轮registry修复发明新API。本节冻结其集合来源与拒绝规则；若现有D4实际接口无法在封口前表达此选择，必须先报告具体接口缺口再review，不能改公共shape或事后扩包。普通D2 follow-up只实现上述固定三阶段profile的元数据/加载边区分。

因此不存在“registry列了十种storage producer，所以当前D2执行十种”的推导。VersionsRecord必须保留全部current schema身份；stage存在性来自本节入口/正式请求，closure存在性来自真实文件/加载依赖，三者分别检查。

## 6. Stage-scoped closure、D_JOBS 与不可变包

唯一构造与核验 Owner 为4D：
1. D4 TaskService按§5.3正式RunRequest.policy.stages的精确集合构造实际阶段计划，遵守原policy与单槽；当前D2 saved-only入口固定为本节三阶段profile，不给Owner自由选择active stage。
2. D2 ExecutionProject 根据此实际需求和唯一正式依赖声明封存完整脚本/UID/配置、真正资源及传递加载边，形成实际 modules/configuration SHA 和唯一 execution_digest；D1只提供规范 schema/wire/digest。
3. 新 immutable run 封口后才能启动；worker只读封存 bytes并验证engine/module/configuration。启动前缺件停链，不在运行时补源码。
4. 4C仅提供 run_quality 的真实编排、正式所选 trace 校验和所需正式算法来源；不得生成另一套 execution manifest 或恢复磁盘 graph 当活图。
5. D4受控图形入口使用同run、相同执行身份的 canonical/trace；Replayer/Session/Presenter/Safety 动态与资源依赖提前封存。

Quality/replay 的六个4C阶段 producer、quality_workflow/quality_stage_records/selected_trace_checks、Binder、worker_entry、graphical_entry 及各自传递闭包在实际D_JOBS计划需要时都必须交付。C_QUALITY收据只列14个4C文件，底层3A/3B/3C/3D来源是BASE；不能误称这些旧算法归4C新写。

不得在一个已 sealed 的普通 saved run 上增加质量/Binder/Jobs源文件，追改 versions或execution_digest。现有 materialize只恢复input.ready指定的blob，不扩大闭包。需要不同代码能力时从同一saved source创建新run/snapshot，用实际新闭包计算新execution_digest，source_fingerprint/合法canonical内容按已批准相同源规则核验，重新在同run发布正式BAKE证据；不跨run拿ArtifactRef，不修改旧封包。沿已批准 D3 NEW_RUN_FROM_SAME_SAVED_SOURCE 模型，不新增迁移或双身份算法。

D_JOBS正式状态仍 NOT_DELIVERED；Owner已有IMPLEMENTATION_READY阶段事实不等于Real已通过。本稿只明确下一步Real的closure门槛：当前协议storage已登记，但还要兼容current D_SAVED closure receipt、真实A_EDIT/C_QUALITY、同run质量/图形证据；不启动实现、Real或I2。

## 7. 4A-4顺序与循环依赖消除

Track A独立批准的链已在正式血统满足：
D_PROTOCOL source_intent（814a，当前8f7保留能力）
→ D_SAVED source_intent（8289 / dd3cc6正式收据）
→ 4A-4消费同轮SnapshotIdentity和成功Bake
→ A_EDIT。

Stage Storage 的 schema版本扩展/存储发布不是 Binder 值转换的语义前置。Binder消费四参数：authoring_intent、同轮同Payload的resource_table、successful_bake、snapshot_identity；source_intent_digest由4D计算并验证、4A原值回传；正式Intent八字段、BakeProvenance三字段均不变。

拟正式移除人为增设的“4A-4 WAITING_FOR_D_SAVED_REGISTRY_FOLLOWUP”作为语义依赖。4A-4 = READY_TO_START（合同/Owner值转换TDD范围），可消费现有8289已经正式交付的source_intent能力。本轮不派发4A、不修改case_manifest、不升级A_EDIT、不把本待审文档当Owner启动指令。

需明确版本边界：814a历史run仍是历史有效来源证据，但其旧VersionsRecord不能在8f7 current decoder下静默升级。4A可使用正式8289生成并验证的同轮作者/identity/Bake值进行Binder行为验证；不能手写替代digest，也不能把旧package重新认证为8f7 current run。若4A某Real测试实际要求再次调用当前8f7 capture_saved，则该capture部分确实仍被本轮D2闭包问题阻塞，准确记局部DEPENDENCY_PENDING，不把它扩大为Binder语义依赖。A_EDIT正式交付还须按批准计划完成真实接入与所有门槛，合同ready不等于GREEN或DELIVERED。

无环建议顺序：
- 本澄清review/精确批准→D2最小加载边修复→新current capture及D_SAVED登记；
- 4A-4基于既有正式source_intent能力推进→A_EDIT；
- 新D_SAVED + A_EDIT + C_QUALITY + 实际D4执行闭包→D_JOBS Real→以后另行授权I2。

第一、第二线在各自已授权范围可独立推进。D2普通链不等Binder；D_JOBS真正执行INTENT_BIND时等A_EDIT。因此不形成D_SAVED→Binder→A_EDIT→同一个D_SAVED的循环。

## 8. D_HOST、不变项及失败语义

D_HOST formal slot仍b9bf；source-intent loader candidate仍8289的phase/test依赖，不升级为D_HOST PASS。canonical_loader保持SHA：
4f9b0785ae42fa726cd6053b1b1e475bab5c2216fd04011d0ca25d7922cfc904。

whitebox_entry.gd、whitebox_host.gd、whitebox_host.tscn、canonical_loader.gd、RuntimeSession、Kernel、Safety、Presenter、Geometry和实际支持资源全部维持原严格闭包/内容核验。缺任何真实依赖、UID、engine/version不符、路径或附件逃逸、half-package、hash不符都拒绝。metadata例外不能豁免白盒真实资源或七个协议 preload。

唯一execution_digest仍完整VersionsRecord wire摘要；不增加metadata/content/execution多套digest。schemas mandatory四新键不变，SnapshotIdentity四字段、SnapshotRef、input.ready shape/source_fingerprint/source_intent规则不变，正式Level/Reader/Baker/Codec不变。

发布仍input.ready最后封输入；附件→stage_result→WorkerMessage及archive manifest-last保持；整个stage payload不携带本机绝对路径。已执行阶段module_ref仍必须在实际versions.modules里有真SHA，未封存时不能发布有效stage_result，包括已开始但无返回的合法终态。

原814a run拒绝行为保持；不得补新keys改旧包。失败不读活动4A/4C工程补件，不创建Binder stub、不伪造SHA、不删registry metadata、不恢复历史canonical、不忽略safety1601或新协议失败。I1历史14936504 FROZEN_PASS不重判、不改fixture、不重跑。

## 9. Owner影响与批准后验收要求（本轮不实施）

| 项目 | 本稿建议结论 | 后续责任 |
|---|---|---|
| D_PROTOCOL | UNCHANGED | producer身份、on-stage modules SHA要求及现有wire足够；不加 metadata_only/execution_required字段，不放宽schema |
| D_SAVED | CLOSURE_LOGIC_UPDATE_REQUIRED | 4D D2修正从registry身份位置自动推导加载依赖的边界；prepare和verify/reconstruction必须一致，registry继续唯一来源 |
| 4A-4 | READY_TO_START，取消人为语义前置 | 既有source_intent正式收据可消费；需要当前capture的新Real输入仍须等对应capture修复，不伪称完成 |
| A_EDIT | NOT_DELIVERED | 等4A真实完成与正式收据 |
| D_JOBS | IMPLEMENTATION_READY阶段事实保留 / REAL_DEPENDENCY_PENDING | 需要已选stage实际完整闭包、current兼容D_SAVED和A_EDIT；不运行本轮Real |
| D_HOST | 既有正式事实不变；后续新包兼容复验 | 不改loader、不宣布新D_HOST交付 |
| 4C / 4B | UNCHANGED | 不拥有D2闭包构建或另一registry |
| I1 / I2 | FROZEN_PASS / NOT_STARTED | 本轮不启动 |

最小预计Owner编辑边界：execution_project.gd的闭包检查及test_saved_snapshot.gd对应测试；只有实际阶段执行计划确实要求时才在同Owner execution_dependencies.json登记真实已交付依赖。snapshot_capture无新字段需求，需实测才决定是否存在必要调用调整。本轮不批准这些修改。禁止触碰D1协议、D3loader、D4 Jobs WIP、4A/4C代码、共享Harness/receipts或I1。

不得修改wire_schemas.gd/ToolWire schema/VersionsRecord shape、source_intent digest、canonical_loader、D_HOST或4A Binder来实现本边界。D2内部辅助文件仅在实际职责证明必要且属于原D2 Owner范围时同步；不能借“builder调整”重新设计公共协议。

批准后测试必须至少证明：
- 当前D2入口的stage集合恰为AUTHORING/BAKE/MANUAL_RUNTIME；Binder文件存在/不存在不改变集合；完整D4请求不能在三阶段工程上降级执行或发布PASS；七项基础协议加载依赖无条件严格检查；
- registry表中未执行阶段的六个URI缺席不导致普通capture失败，四mandatory键仍精确完整；
- 同一URI若出现在真实preload、load（含可判定变量传递）/动态声明或场景资源引用，缺席仍明确拒绝；不能仅测试意外被regex放行；
- 精确身份位置以外的未知间接依赖不能静默忽略；别名、大小写、unknown registry/stage/module_ref拒绝；
- wire_schemas真正load的A_SCHEMA与七个preload实际缺失仍拒绝；同schema名字的unsupported newer/missing/wrong版本仍拒绝；
- 拒绝真实whitebox入口/scene/loader依赖、缺UID、错engine/hash、half-package、链接/路径逃逸；旧封包和历史产物无fallback；
- 选中INTENT_BIND却缺正式Binder时DEPENDENCY_PENDING；真正质量/replay计划缺其producer/4C编排/图形支持时拒绝；已封存生产stage要求不放宽；
- prepare生成和sealed verify/snapshot_from_run使用一致依赖边界；已封存bytes可在活动源缺失后物化，禁止读活动源补缺；
- current8f7真实saved capture及reconstruction通过；source_intent empty非null/missing null/invalid不发布、四字段身份不变；
- D2 Unit/Real、D1适用回归；D_HOST/I1按新的正式收据gate由Integration后续复验，不绕过。

未来若实现只能通过新增公共计划字段或修改D1 schema实现此义务，必须先报告具体接口缺口再review，不以本稿宽泛授权发明接口。本稿当前不需要新wire shape，也不依赖所有未来Owner文件预先存在。

## 10. 文档审计结果与停止边界

本轮仅静态读取文档/源码、枚举URI、对照正式commit文件SHA、检查本地变更范围。没有调用Godot、run_module或任何产品测试。

Production code: NONE
Tests: NOT_RUN（上轮证据仅只读复核）
D2 WIP: PRESERVED
D2 WIP SHA-256: 83fd2ecec92d5070596a6b0665a83c2cf9b28161c0a95003c8b8cc3c80b4629d
Commit: NOT_RUN
Push: NOT_RUN
Approval: NOT_APPROVED

唯一新增文件为本clarification，位于Integration工作树。Owner D2测试WIP及历史RED留原处、原字节；不创建approval record，不写receipt，不启动后续工作。

## 11. 本轮重新核验的来源字节

以下SHA是文档审计身份，不是新增runtime registry或第二digest。D4 Required Stage Storage精确SHA与其Approval一致；冻结Spec及四计划原字节保持。

| 来源（相对Integration根） | SHA-256 |
|---|---|
| docs/development-records/FOUNDATION_4_D1_SCHEMA_CLARIFICATION_APPROVAL_RECORD.md | 45d25befdf659281feb823e4f28d6c726261df44c50680d36f73bc9cd984c657 |
| docs/development-records/FOUNDATION_4_A4_SOURCE_INTENT_DIGEST_CLARIFICATION.md | e1df9d6da305c764bffc53cb930ef7149a8ef734bb2585e10d2aeca69137cdee |
| docs/development-records/FOUNDATION_4_A4_SOURCE_INTENT_DIGEST_TRACK_A_APPROVAL_RECORD.md | 75875712210eda84746dc827eea3259d6d68c761cc7cd6be675c2dede4a73530 |
| docs/development-records/FOUNDATION_4_D1_SCHEMA_CLARIFICATION.md | 93e0a52f524dad19925f477b31f8da12db2dceb52cba81ef78c1b730db01e79c |
| docs/development-records/FOUNDATION_4_D3_HOST_EXECUTION_BINDING_CLARIFICATION_APPROVAL_RECORD.md | 6c011c913f7c4838029756e71d52f096604b9b40cf48a320e22bb083e5b1084c |
| docs/development-records/FOUNDATION_4_D3_HOST_EXECUTION_BINDING_CLARIFICATION.md | 9bc4cd3a348d35bf0839fd723c53504552e1b5040b77cda2378dbdc0381abba4 |
| docs/development-records/FOUNDATION_4_D4_REQUIRED_STAGE_STORAGE_CLARIFICATION_APPROVAL_RECORD.md | 7f747167d5b412cfc09f06c73b434c37ff41994cc681409e680f9066e04be068 |
| docs/development-records/FOUNDATION_4_D4_REQUIRED_STAGE_STORAGE_CLARIFICATION.md | d87239efa0fa0ed36ba80a4e5b072e8269b1969cf03b32fa50ad663e998657e8 |
| docs/development-records/FOUNDATION_4_STAGE_RESULT_SCHEMA_CLARIFICATION_APPROVAL_RECORD.md | 05f483004b7f76b51b62ed6d538d9c3bfc6333dd46dcb62be8d45659056e39a2 |
| docs/development-records/FOUNDATION_4_STAGE_RESULT_SCHEMA_CLARIFICATION.md | dbe2b5b4ea01f91160fd8e9f6d939766e5e0d2f319f84d6f26a80c0d06653ad0 |
| docs/superpowers/plans/2026-09-23-foundation-authoring-data-plan.md | deb5f052f3de84db80450fcfa84abfdc6fe3c3535b41f838163a999e8b2e402a |
| docs/superpowers/plans/2026-09-23-foundation-authoring-integration-plan.md | 179d1f2d416b59e3c890c6026d28f57f28f84e1ebe67f233666b4e98f7bd99ff |
| docs/superpowers/plans/2026-09-23-foundation-authoring-quality-plan.md | 87bddd1ff7a691ad19e0ff5804fd011ec3ca7c57f73689d1bbf83bb7e07cea98 |
| docs/superpowers/plans/2026-09-23-foundation-authoring-runtime-plan.md | 5e8293d9ecf5580f48669875fb0324511218c423c582fb888a5cf14bf445315d |
| docs/superpowers/specs/2026-09-22-foundation-authoring-editor-design.md | a4d9cd7ccfde8e4fdb0eea72746505b995361850e623bef7952d49849ec9a13f |
| docs/superpowers/specs/2026-09-22-foundation-authoring-tool-contracts.md | c31a03e807a2bf9268d32aa00fa18bcd93c77bad4c53ed00a8d349fed8462a6b |
| tools/foundation/authoring_acceptance/execution_dependencies.json | 1380f8e0c6ae1a03db959282ad058f0e252c5b524c640e05bfafbc07c2cc4b46 |
| tools/foundation/authoring_acceptance/execution_project.gd | cae8fe56fdfa4741fd733bb62258d8ee78fb199d83dfdad6c33c475a698f2c25 |
| tools/foundation/authoring_acceptance/run_records.gd | 14eafee84be3da0b334828220abfe5f561c9d45b32eaed68a51bf79d4d7189dc |
| tools/foundation/authoring_acceptance/snapshot_capture.gd | 82bce8ae48866872e4b22f28da205d86cd4421a57dc0a50a06d7c1f2639fce9b |
| tools/foundation/authoring_acceptance/tool_wire.gd | a0f078ba1194293cc8430af373dd2f884c9e1c8ebd96572a801c3835abddd924 |
| tools/foundation/authoring_acceptance/wire_schemas.gd | 55ff3a3183f40152d70dd865e0e9535f1060b33e0d04c98becbcad72f411fbb0 |
| tests/foundation/authoring_acceptance/test_saved_snapshot.gd（正式8289；Owner WIP另记§10） | 076772487219ad11a6272f2448d6675c20a2ca88358d56df700c92960077ecbb |

静态一致性复核：38个保护文件SHA前后一致（含五份计划、冻结Spec、协议/捕获/loader、receipts/case manifest与Owner D2 WIP）；A_SCHEMA/A_BAKE/D_PROTOCOL/D_SAVED清单中的实际文件SHA全部匹配。Integration仅新增本文件，HEAD仍342a51f；Owner仅保留既有D2测试WIP。此复核不是Godot产品测试，也不是新的delivery/approval。
