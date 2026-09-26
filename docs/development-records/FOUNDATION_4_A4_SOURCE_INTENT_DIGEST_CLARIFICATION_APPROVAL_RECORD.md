# FOUNDATION-4 A4 Source Intent Digest Clarification Approval Record

Status = APPROVED

Clarification path = docs/development-records/FOUNDATION_4_A4_SOURCE_INTENT_DIGEST_CLARIFICATION.md

Clarification SHA-256 = E1DF9D6DA305C764BFFC53CB930EF7149A8EF734BB2585E10D2AECA69137CDEE

Approval authority：用户本轮条件授权APPROVE EXACT CURRENT CLARIFICATION。先完成正文完整性检查，全部通过后记录批准。澄清正文未修改任何字节；本记录不补造schema。

Integration receipt R5 = a40392c99a93db10e07fd5f15215192f29165e7f
Pre-approval HEAD = 24e2c18016a5f7ddba102c81c28c3c2f66be114a

## 批准前完整性检查：10/10

以下答案均已存在于澄清§3，不是通过本记录新增的规范。

| 检查 | 正文已冻结的答案 |
|---|---|
| 1. 顶层字段 | 恰root_authoring_id:String、resources:Array[ResourceEntry] |
| 2. INTENT位置 | 完整INTENT entry位于resources，由root_authoring_id指向唯一根 |
| 3. 引用闭包位置 | 同一resources数组保存完整被引用MILESTONE/BYPASS entries |
| 4. 是否排除INTENT自身 | 不排除；resources包含根恰一次，另加可达引用闭包，无第二份根 |
| 5. ResourceEntry schema | 既有A_SCHEMA五字段authoring_id、kind、document_uri、resource_uid、fields；复用类型、身份和fields封闭规则 |
| 6. resources排序 | authoring_id的UTF-8字节升序 |
| 7. 作者数组顺序 | expected_milestones、forbidden_bypasses及其它作者声明数组保持捕获顺序，不随表排序重排 |
| 8. duplicate authoring_id | 拒绝；合法共享引用只收录一次，不等于重复表身份 |
| 9. missing ref | 悬空引用拒绝，非missing Intent的替代表示 |
| 10. unrelated resources | 禁止额外entry，仅唯一INTENT根及可达MILESTONE/BYPASS闭包 |

## 批准的closed schema（引用澄清§3）

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

所有五字段参与摘要。fields不是任意Dictionary，必须符合已登记A_SCHEMA相应kind的封闭字段/类型/枚举规则。root_authoring_id指向同一已验证AuthoringPayload中所选Level根fields.intent引用的唯一INTENT。

只允许该INTENT及它经expected_milestones/forbidden_bypasses实际引用的MILESTONE/BYPASS闭包。FACE、MECHANISM_CONFIG、其它INTENT、未引用Milestone/Bypass和其它无关Resource全部排除。循环、缺失/未知引用、重复身份、非法类型、unknown字段/kind均拒绝。

相同resource_ref ID下，被引用Milestone/Bypass内容变化仍改变摘要；合法无关Resource变化不改变该摘要。作者声明数组顺序保留，resources自身规范排序。

## Digest Owner及身份承载

Digest owner = 4D

Canonical encoding = foundationtoolwire.v1 / record_kind source_intent

source_intent_digest = 唯一Wire.digest("source_intent", closed_closure)结果

4A不得encode wire、canonical serialize、SHA-256或重建闭包摘要；只读取snapshot_identity.source_intent_digest，在合法绑定成功时原值回传。4C不生成该摘要。

SnapshotIdentity field already existed：Integration Plan已冻结run_id、snapshot_id、source_fingerprint、source_intent_digest四字段；shape不变，不新增Binder第五参数。

Binder继续bind_intent(authoring_intent, resource_table, successful_bake, snapshot_identity)。同一Payload调用前提及BakeProvenance交叉核验保持。

合法存在Intent产生64位小写SHA-256 hex。Explicit empty仍有完整合法INTENT entry并生成非null digest。Missing Intent为null，不生成synthetic empty。Invalid作者Intent/闭包不能发布合法digest，capture/binding停链；正式IntentValidation后续失败与源schema非法的区别沿澄清§6。

source_intent_digest、source_fingerprint、authoring_payload_digest分别绑定Intent闭包、完整source-manifest、完整AuthoringPayload，不可互相替代。

正式PuzzleIntent仍恰八字段；不得加入source_intent_digest、resource_ref、authoring_id、snapshot_id或run_id。BakeProvenance恰三字段、SourceMap不变。

## 更新要求及本轮明确执行顺序

D_PROTOCOL = UPDATE_REQUIRED：新增source_intent封闭schema及正式版本身份，复用唯一Wire.digest，不挪用formal intent record、不接受任意Dictionary、不创建第二codec。

D_SAVED = UPDATE_REQUIRED：同一已验证Payload的capture计算摘要，missing写null，invalid停链；加载sealed包时按澄清§8重新计算并严格核验。SnapshotRef/SnapshotIdentity字段集合及package外层schema不扩展，input.ready仍最后发布。

A_BAKE = NONE / UNCHANGED
e0940278fe425d7f77eb6a5b4ea042067606258d

I1 semantics = NONE
I1 = WAIT_FOR_UPDATED_D_PROTOCOL_AND_D_SAVED

后两行明确落实用户本轮执行约束：I1尚未启动，未来必须消费正式更新后的D_PROTOCOL、D_SAVED，不能先用旧D版本启动再补兼容。此为本轮授权的接入顺序，不是通过Approval Record新增source_intent schema。

CONTRACT_MISMATCH = RESOLVED_AT_CONTRACT_LEVEL
4A-4 = CONTRACT_UNBLOCKED_AFTER_APPROVAL

合同层解除不代表实现或Real集成完成；正式4D更新交付前，真实依赖仍应如实DEPENDENCY_PENDING。本轮不修改或登记任何Owner交付、receipt、case_manifest、Spec或Plans，不启动4A-4 GREEN、I1/I2。

本轮只提交原澄清与独立批准记录。Push: NOT_RUN。

Recorded at = 2026-09-26T23:42:14.2882921+08:00
