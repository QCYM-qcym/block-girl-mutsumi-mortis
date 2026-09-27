# FOUNDATION-4 Worker Message Protocol Version Clarification Approval Record

Status: APPROVED
Clarification path: docs/development-records/FOUNDATION_4_WORKER_MESSAGE_PROTOCOL_VERSION_CLARIFICATION.md
Clarification SHA-256: 6E2F4FC318D84DD5C20E4922D8238BDD1F10293805B7000F5ED45BB6830F0DF6

用户本轮授权APPROVE EXACT CURRENT CLARIFICATION。已核对精确SHA，澄清原文字节不变。本记录登记合同批准，不宣称生产实现已注册或交付。

## 正式版本与唯一规范源

Registered protocol_version: foundationworkeripc.v1
Owner: 4D / D_PROTOCOL
Canonical location: tools/foundation/authoring_acceptance/wire_schemas.gd::WORKER_PROTOCOL_VERSION
foundationtoolwire.v1 relation: DISTINCT

foundationtoolwire.v1是通用canonical wire envelope；foundationworkeripc.v1是Parent/Worker任务IPC版本，不可互换或fallback。唯一常量由4D实现；worker_entry、process_transport、task_service、graphical_entry及tests消费该值，不各自硬编码另一规范源。测试可以比较literal，但生产真相仍唯一。澄清规定的SCHEMA_VERSIONS注册投影引用该常量，不复制第二定义。

## 消息方向与拒绝规则

WorkerMessage kinds: HELLO、STAGE_STARTED、STAGE_RESULT、HEARTBEAT、EXIT、ERROR。
Parent commands: CANCEL、LEASE。

全部必须携带protocol_version:String，精确等于foundationworkeripc.v1。父指令不另建foundationparentipc版本。missing、null、empty、unknown、unsupported future、foundationtoolwire.v1误填、StringName/其它错误类型、大小写改变、前后空白均拒绝，不trim、不降级、不fallback。

HELLO同样校验顶层protocol_version；tool/module、wire、engine version/hash及RunIdentity校验不能替代它，版本错误不能因为其它身份一致而忽略。未冻结的kind-specific payload不能因版本批准被自动当作任意Dictionary可用。

Unknown/future: REJECT。当前仅支持foundationworkeripc.v1，不用starts_with等宽松匹配。未来升级必须独立合同变更、schema/compatibility决策及正式批准。

## Stage Result保持不变

Stage Result Schema: UNCHANGED
Stage Result approval commit: 74892ba39c283e24efbd0755e85e552b5a685784

STAGE_RESULT消息必须同时满足正式IPC版本、kind=STAGE_RESULT、payload_ref_or_inline为正式stage_result ArtifactRef，以及已批准的完整identity、sequence、stage_id、ArtifactRef hash与stage_result身份闭环。stage_result payload、BAKE branch、graph_archive、ArtifactRef、发布顺序、正式路径、native_result语义全部不变。

## D_PROTOCOL交付与D3门槛

D_PROTOCOL: UPDATE_REQUIRED
Current registered D_PROTOCOL: 6176a45c614f678c8b248d5289f9a672a971043b

旧slot不满足新协议，不自动升级、不创建新slot。下一版同一D_PROTOCOL Owner更新应包含Stage Result批准实现、唯一IPC版本注册、WorkerMessage closed schema、STAGE_RESULT ArtifactRef关系、HELLO及CANCEL/LEASE版本校验所需schema能力、严格missing/unknown拒绝测试。若其它payload细节仍未冻结，应准确报告，不自行放宽。

D3: WAIT_FOR_UPDATED_D_PROTOCOL_RECEIPT / BLOCKED_PENDING_PROTOCOL_IMPLEMENTATION
Action-capable artifact: READY（既有预检事实，不是本轮新验收）
D_HOST: NOT_ISSUED
I1: NOT_STARTED

还须满足已于5f30cc41c894858c62d7d6afd5b28b6eb59a5c85批准的D3 Host Execution Binding及D_SAVED execution closure实际更新/登记，才能进入最终D3 run。版本批准本身不授权启动正式Tween或视作D_HOST通过。

CONTRACT_MISMATCH: RESOLVED_AT_WORKER_IPC_VERSION_LEVEL

## 本轮范围

仅本地提交精确clarification与本独立approval record。未修改4D源码、D_PROTOCOL实现、D3九个WIP、dependency_receipts、case_manifest、Spec或Plans。未运行D1/D3/I1。
Push: NOT_RUN

Recorded at: 2026-09-27T13:35:53.5863983+08:00
