# FOUNDATION-4 A4 Source Intent Digest — Track A Approval Record

Status = APPROVED

Approval binding = APPROVED_EXACT_CURRENT_CLARIFICATION

Recorded date = 2026-09-29 (Asia/Shanghai)

Approval authority = 用户本轮 TRACK A 条件授权：原 SHA 一致且逐项完整性检查通过后，建立独立批准记录；不得改动原澄清。

Clarification path = docs/development-records/FOUNDATION_4_A4_SOURCE_INTENT_DIGEST_CLARIFICATION.md

Approved clarification SHA-256 = E1DF9D6DA305C764BFFC53CB930EF7149A8EF734BB2585E10D2AECA69137CDEE

Read-only audit HEAD = 14936504ae4245cc1822786937f021afce4a7fd9

本记录复核并绑定上述精确原文，不修订其字节、不引入新 schema。已有 FOUNDATION_4_A4_SOURCE_INTENT_DIGEST_CLARIFICATION_APPROVAL_RECORD.md 绑定相同 SHA；保留该历史记录。本轮另建记录以避免覆写其历史日期、执行范围或 I1 叙述。原文中的 REVIEW_READY、PROPOSED 与历史审计基线保留；批准由独立记录表达，不把历史源码观察视作当前实现已完成的证明。

## 完整性复核

检查结论 = COMPLETE；缺口 = NONE。下表记录原文已定义的规则及真实 schema 对照，不通过本记录补充定义。

| 检查项 | 原文答案与核验证据 |
|---|---|
| 顶层 closed shape | §3 恰 root_authoring_id:String、resources:Array[ResourceEntry]；未知字段拒绝。 |
| INTENT entry 精确字段 | §3 完整五字段 ResourceEntry；kind=INTENT；fields 恰 authoring_version、intent_id、required_mechanics、optional_mechanics、expected_milestones、forbidden_bypasses。authoring_schema.gd:25、30、117–127、171–176 定义封闭字段及类型/版本/枚举规则。 |
| referenced closure 精确字段 | §3 明确完整 entry、所有既有 fields 参与并完全复用 A_SCHEMA；MILESTONE.fields 恰 milestone_id:StringName、required:bool、predicate:Dictionary；BYPASS.fields 恰 bypass_id:StringName、disabled_mechanics:Array。authoring_schema.gd:26–27、177–180、217–233 定义其闭合字段、枚举和 Predicate 各分支；不存在任意 Dictionary 通道。 |
| 沿用 authoring resource_table entry | §3 五字段 authoring_id:String、kind:String、document_uri:String、resource_uid:String或null、fields:Dictionary，与 authoring_schema.gd:30、247–252 一致；不新增第二种作者表示。 |
| resources 排序 | §3 authoring_id 的 UTF-8 字节升序；INTENT 根及每一可达资源各收录一次。 |
| expected_milestones 顺序 | §3 所有作者声明数组保持捕获顺序，特别点明里程碑；资源表排序不重排引用数组。 |
| forbidden_bypasses 顺序 | §3 明确不排序 bypass 数组；沿捕获顺序。 |
| duplicate authoring_id | §3 拒绝；schema:250–251 同样拒绝重复身份，内容相同也不使其合法。共享可达目标仅收录一次与重复表身份不同。 |
| missing refs | §3 悬空、歧义、类型错误、循环拒绝；schema:371–378 校验两类引用目标，420–435 的 _references 校验精确 resource_ref、存在性与路径循环。 |
| unrelated 排除 | §3 仅所选 Level.fields.intent 唯一 INTENT 根及其可达 MILESTONE/BYPASS；不多放无关 entry。合法完整 Payload 是先决条件；无关非法内容不能通过裁剪被掩盖。 |
| explicit empty | §6 合法存在、四集合空的 INTENT 仍形成单根闭包并计算非null摘要，仍绑定及正式验证。 |
| missing Intent | §6 合法 Level 无 Intent 引用时摘要 null；不伪造空 Intent，不编码 null。 |
| invalid 不发布 digest | §6 源 schema/闭包非法时 4D 失败且无成功 identity；§5 Binder 失败摘要 null。源合法但后续正式质量失败不被混为源非法。 |

核验 schema = foundation/authoring/authoring_schema.gd

Schema SHA-256 = F01D2A7E32B8269E5F9322A15EB60F58440B5F5A13046BB9CAC5A08456DD5979

Predicate 精确分支沿上述 schema：AT_FACE={kind,face_ref} 且 face_ref={cube_id,face}；IN_LAYER={kind,layer}；FACE_LIGHT={kind,light_state}；MECHANIC_USED={kind,mechanic}；GOAL={kind}。这是对原文“完全复用 A_SCHEMA”的核验展开，不增加字段。AT_FACE 不在摘要前转换 face_id。

已批准 Binder 依据 = FOUNDATION_4_A4_INTENT_RESOURCE_RESOLUTION_CLARIFICATION_APPROVAL_RECORD.md 及其绑定原澄清（SHA-256 5E9E1EC021B700DC819F67585AA60390BF67EAA65EAB4EC5A0C45995564FBF63）。维持四参数 bind_intent(authoring_intent, resource_table, successful_bake, snapshot_identity)，两份作者值来自同一 captured Payload；不增加第五参数，不改变正式 PuzzleIntent 八字段、BakeProvenance 三字段或 SourceMap。

## 批准范围与后续真实依赖链

批准仅解除本文精确 source_intent 合同的文档待批准状态，不是实现、测试、receipt 登记或 A_EDIT 完成声明。

唯一执行顺序：4D source_intent protocol 实现与正式 update receipt → 4D capture digest / sealed 复算校验 D_SAVED 实现与正式 update receipt → 4A A4 消费同轮新 identity → A_EDIT 正式交付登记。

4D 保有 foundationtoolwire.v1 的唯一 canonical/wire/digest 实现权；source_intent 使用完整规范 envelope/type tags 的 Wire.digest。4A 只验证既有输入身份及 digest 类型/非空要求，并在绑定成功时原值回传；不得自行 SHA、JSON hash、canonical serialize，或以 source_fingerprint / authoring_payload_digest 替代。

SnapshotIdentity 仍四字段；RunIdentity 仍九字段；D_SAVED 从同一已验证 Payload 计算，并按原文§8对 sealed 包重新计算严格比较。两个正式 update receipt 完成之前，4A 实际依赖保持 DEPENDENCY_PENDING。批准记录不能充当任一 receipt。

本轮不启动、撤销、重跑或重新判定 I1；不登记 I2，不修改生产、Spec、Plans、receipts 或现有批准记录。仅新增本独立批准记录；原澄清 hash 复验。产品测试 NOT_RUN（文档审计）；commit NOT_RUN；push NOT_RUN。

## Git approval handoff

Digest Owner = 4D

source_intent closure = selected INTENT full ResourceTable entry + actually referenced MILESTONE/BYPASS full closure

Canonical = foundationtoolwire.v1 / record_kind=source_intent

SnapshotIdentity.source_intent_digest = existing field; shape unchanged

Explicit empty = non-null digest

Missing = null

Invalid = no valid digest published

A_BAKE = UNCHANGED

D_PROTOCOL = UPDATE_REQUIRED

D_SAVED = UPDATE_REQUIRED

4A = MUST_NOT_HASH

本轮授权将此批准记录本地提交；上文 commit NOT_RUN 是前轮审计状态。原澄清已在历史中，本次保持原字节。禁止 push，不启动实现。两条协议合同均批准后仅安排一次 CONSOLIDATED_D_PROTOCOL_UPDATE，不并行建立重叠协议实现线。
