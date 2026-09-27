# FOUNDATION-4 Worker Message Protocol Version Clarification

Status: WORKER_MESSAGE_PROTOCOL_VERSION_CLARIFICATION_REVIEW_READY
Date: 2026-09-27 (Asia/Shanghai)
本稿未批准；以下新增literal/注册规则为待批准提案，不是当前已实现事实。

## 1. 缺口与审计范围

Integration HEAD：5f30cc41c894858c62d7d6afd5b28b6eb59a5c85。
Stage Result approval commit：74892ba39c283e24efbd0755e85e552b5a685784。
Stage Result批准SHA：DBE2B5B4EA01F91160FD8E9F6D939766E5E0D2F319F84D6F26A80C0D06653AD0，已核对未变化。

当前WORKER_MESSAGE_PROTOCOL_VERSION_UNDEFINED属于CONTRACT_MISMATCH，不是实现失败或D1 RED。本轮不读取/修改Protocol Owner工作树来填补合同，不运行D1；用户提供的该树clean、NOT_STARTED/NOT_RUN状态不冒称本轮实测。

已检索并对照：Design Spec、Tool Contracts、Integration Plan、4D Runtime Plan、development-records全部clarification/approval；当前D_PROTOCOL的wire_schemas.gd、tool_wire.gd、run_records.gd；execution_dependencies.json。搜索包含protocol_version、worker_message、WorkerMessage、HELLO、STAGE_STARTED、STAGE_RESULT、HEARTBEAT、EXIT、ERROR、CANCEL、LEASE、foundationtoolwire.v1及版本注册概念。

| 分类 | 事实与来源 |
|---|---|
| APPROVED | Tool Contracts wire条款冻结foundationtoolwire.v1数组封套和worker_message record_kind，但未给任务IPC版本literal。 |
| APPROVED | Tool Contracts IPC条款（现文件182行）定义WorkerMessage六字段；子消息HELLO/STAGE_STARTED/STAGE_RESULT/HEARTBEAT/EXIT/ERROR，父指令CANCEL/LEASE；每方向单写者、完整身份、单调sequence、先附件后消息。未定义另一父命令版本值。 |
| APPROVED | Stage Result澄清§6要求“正式WorkerMessage注册版本”，但没有冻结其literal；它只冻结STAGE_RESULT的ArtifactRef及身份/hash关系。批准记录没有补入literal。 |
| PLAN_ONLY | 4D Plan D4要求HELLO验证engine/module/identity及传输校验，Implementation Plans未指定protocol_version具体字符串。Integration Plan指定4D协议所有权，不另注册IPC版本。 |
| IMPLEMENTED | tool_wire.gd encode/decode精确使用foundationtoolwire.v1，属于通用封套。 |
| IMPLEMENTED | wire_schemas.gd KINDS列worker_message，但validate没有其生产分支；未交付kind返回DEPENDENCY_PENDING。SCHEMA_VERSIONS、CONTRACT_VERSIONS无WorkerMessage协议版本注册。 |
| IMPLEMENTED | run_records.gd有身份/策略/阶段工厂但无IPC版本常量；execution_dependencies.json的version=1是内部依赖声明格式，与IPC无关。 |
| INFERENCE | 父CANCEL/LEASE与子消息共享同run IPC及身份/sequence边界，采用同一协议版本可避免两个未定义版本体系；这不是既有literal的发现。 |
| UNDEFINED | 当前不存在唯一正式protocol_version值，父/子版本相等规则和唯一注册源尚未明确。不得把wire/tool/engine版本代入该字段。 |

结论：没有可直接复用的已批准IPC版本literal，需要本独立澄清批准后注册。

## 2. 唯一版本选择与注册位置（PROPOSED）

protocol_version精确literal：

```text
foundationworkeripc.v1
```

ASCII、大小写敏感、无前后空白。名称明确表示任务worker IPC，区别于通用foundationtoolwire.v1；不从tool_version、schema_version或engine版本拼接生成。

唯一Owner：4D / D_PROTOCOL。
唯一正式定义源：

```text
tools/foundation/authoring_acceptance/wire_schemas.gd
const WORKER_PROTOCOL_VERSION = "foundationworkeripc.v1"
```

选择wire_schemas而非run_records作为定义源，因为wire_schemas持有公开decode/encode前置schema验证及版本表；run_records已经依赖wire_schemas，可直接引用，不新增循环依赖。

WorkerEntry、ProcessTransport、run_records、消息构造器、消费者和测试全部引用该公共常量，不维护第二份相同字面值。正常测试构造合法版本只消费常量；拒绝测试使用明确非法样本，不能另定义“测试正式版本”。

VersionsRecord既有schemas封闭映射新增worker_message键，其值直接引用WORKER_PROTOCOL_VERSION，不重复硬编码literal。SCHEMA_VERSIONS是该常量的注册投影，不是第二定义源。VersionsRecord七字段shape不变；精确允许的schemas键集合通过本次D_PROTOCOL正式更新演进，不偷偷兼容缺该键的旧版本记录。实际版本wire/模块变化按唯一Wire.digest("versions",...)进入execution_digest。此注册不自动使尚未定义的其它消息payload schema可用。

## 3. WorkerMessage封闭外形与严格校验

WorkerMessage仍恰六字段，不增减：

```text
{
 protocol_version: String,
 identity: RunIdentity,
 sequence: int,
 kind: String,
 stage_id: String,
 payload_ref_or_inline: KindSpecificClosedPayload
}
```

KindSpecificClosedPayload是按kind选择的正式封闭类型，不是任意Dictionary。STAGE_RESULT精确为已批准ArtifactRef；其它尚未冻结/实现的payload分支继续DEPENDENCY_PENDING，不能因版本值已注册就放行。stage_id、sequence和RunIdentity沿既有适用阶段/方向/次序规则，不在本稿发明未冻结的非阶段消息sentinel或sequence起点。

protocol_version必须存在，typeof精确为String（不接受StringName、数字、null、隐式转型），并逐字节等于WORKER_PROTOCOL_VERSION。以下全部拒绝：missing、empty、unknown、future unsupported、foundationtoolwire.v1误填、任意字符串、错误大小写/空白、错误类型。没有fallback、自动降级、trim或“前缀看起来兼容”。

公开schema验证返回既有失败包装，code=WIRE_SCHEMA_INVALID，并以issues说明protocol_version缺失/非法/不支持；不得发明成功解析后忽略版本的路径。版本失败时不执行消息副作用、不接受任何payload、不推进已接受sequence、不覆盖当前run记录或续租/取消状态。

## 4. 适用种类、方向与HELLO

同一literal覆盖所有子→父消息：HELLO、STAGE_STARTED、STAGE_RESULT、HEARTBEAT、EXIT、ERROR。

父→子CANCEL、LEASE使用相同WORKER_PROTOCOL_VERSION，属于同一任务IPC版本域。已有合同没有发现单独父命令版本/不同版本封套；本提案冻结父命令也携带同名protocol_version:String并执行相同严格校验，不另设command_version常量。其完整kind-specific payload与方向校验沿正式父指令schema，不借本稿补造完整命令payload或允许子侧发送父命令。

HELLO本身必须使用该版本。父构造任务/启动期望版本来自同一正式常量，子发送HELLO，父验证相等后才接受该协议会话；子对后续父命令同样校验版本。因此双向接收都核验本地支持版本，不需要本稿新增HELLO_ACK消息。若父子版本不一致，不能继续以任一方的tool/wire/engine值兜底。

HELLO如另含tool_version、wire_version、engine身份或模块信息，这些仍分别校验；它们不能替代顶层protocol_version，反之IPC版本相等也不证明engine/module兼容。没有完整已批准HELLO payload时，本稿不宣称握手实现已可用。

## 5. 与其它版本及Stage Result的关系

- foundationtoolwire.v1：通用带类型canonical封套版本。
- foundationworkeripc.v1：任务IPC消息协议版本，本次新提案。
- tool/module版本与VersionsRecord：实际执行内容身份。
- engine.version/executable_sha256：引擎执行身份。

四者不同维度。WorkerMessage.protocol_version不得等于foundationtoolwire.v1，也不使用stage_result ArtifactRef.format_version来代替。

Stage Result Schema正文/批准SHA保持不变。本稿仅补它引用的IPC注册值、适用方向与拒绝规则，不改变stage_result payload、BAKE分支、ArtifactRef、graph_archive、native_result终态语义、路径或发布顺序。STAGE_RESULT依旧只用ArtifactRef引用同run正式stage_result.wire，identity/stage_id/sequence/hash必须全部核验。

## 6. 未来演进

当前仅支持精确foundationworkeripc.v1。未来版本需独立明确批准：新literal、兼容策略、kind-specific schema、迁移/拒绝规则及真实测试，再由4D更新唯一注册源并交付。默认不向前兼容、不按v数字大小接受、不动态协商降级；不静默给v1扩未知字段。

即便未来明确允许多版本，支持集与分派也只能位于唯一D_PROTOCOL注册源，并分别闭合；不能让入口、transport、测试各自决定。重放旧run仍必须核对真实版本/模块身份，不改写历史记录以通过校验。

## 7. 交付影响及后续验证要求

D_PROTOCOL: UPDATE_REQUIRED。归当前同一个stage_result Owner update任务，不增正式slot名字。新版交付应同时提供WORKER_PROTOCOL_VERSION唯一注册、VersionsRecord schemas绑定、stage_result schema、STAGE_RESULT ArtifactRef关系和严格负例。其它kind完整payload如尚未交付仍如实pending，不借此宣称D4完成。

后续至少覆盖：合法常量往返；缺失、空、StringName/null/数字、unknown/future、错误wire版本、空白/大小写拒绝；父CANCEL/LEASE与HELLO及各子消息均通过同一版本校验；版本错误不产生副作用或推进sequence；既有stage_result身份/hash/路径规则回归。测试本轮NOT_RUN，不标RED/GREEN。

Stage Result Schema: UNCHANGED。
D3: STILL_BLOCKED_PENDING_APPROVAL_AND_PROTOCOL_IMPLEMENTATION；还需更新receipt及既有D_SAVED闭包、真实入口/Tween等门槛，不把版本澄清当D_HOST通过。
I1: NOT_STARTED。

## 8. 本轮边界

仅新增本待审文档。未修改Stage Result澄清、Tool Contracts、Spec/Plans、receipts、4D源码或Protocol工作树；未启动D1 RED/D3/I1。Commit: NOT_RUN。Push: NOT_RUN。不得自行批准。
