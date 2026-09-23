# FOUNDATION-4 A4 Bake provenance clarification approval record

Status = APPROVED

Scope = A_BAKE tool wrapper provenance only

Clarification path = docs/development-records/FOUNDATION_4_A4_BAKE_PROVENANCE_CLARIFICATION.md

Clarification SHA-256 = AD9A19383B07DB4319BE690E06B509CB0C80F62E06FAEE4DD21DCB30E3DCB00E

Recorded at = 2026-09-23T21:58:29.868809+08:00

Integration baseline = f1333fa5997f707eb01d4c93fd0c3297c05ccd77 (R4)

## 授权来源与精确对象

用户本轮明确批准上述SHA绑定的澄清稿，并授权仅将原澄清文件与本独立批准记录本地提交。本记录使该精确版本获得正式批准；原稿中的REVIEW_READY及待审阅表述保留为历史正文，不修改其字节或批准hash，不因此再次进入缺少批准循环。此批准不覆盖其他内容版本。

## 批准范围

BakeProvenance恰三个字段，unknown field拒绝：

```text
{
  run_id: String,
  snapshot_id: String,
  source_fingerprint: String
}
```

A_BAKE工具包装恰六字段：

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

按获批澄清，成功结果具有经验证的三字段provenance独立值，失败出口为null；4A只复制本次snapshot_identity，不生成或推断身份。Binder核验成功Bake、正式有效validation、非null provenance及run/snapshot/fingerprint相等，并交叉核对SourceMap的snapshot_id/source_fingerprint；不一致则ok=false、bound_intent=null。正式Intent hash/rule继续从当前成功level取值。

## 冻结职责

- SourceMap unchanged；不增加run_id。
- D_PROTOCOL compatible；COMPATIBLE_NO_UPDATE / NO UPDATE REQUIRED。
- D_SAVED package schema unchanged。
- Formal Level unchanged；LevelDefinition schema不变。
- Reader/Baker/Codec unchanged；AuthoringReader、LevelBaker、LevelCodec不变。
- Snapshot/RunIdentity的生成及正式Owner仍属于4D。
- BakeProvenance仅属于A_BAKE工具层同轮来源证明，不增加wire record kind、任意Dictionary许可或第二套hash。
- 冻结Design Spec、Tool Contracts与Implementation Plans正文均不修改。

## 当前交付事实与后续边界

Current A_BAKE = 03e581d2c3ec28a1b42074d88495ce7ef580411d。

A_BAKE = UPDATE_REQUIRED。

该已登记交付仍为澄清前的公开shape，不能解释为已带BakeProvenance。本轮dependency_receipts与case_manifest保持原字节、既有slots不变。必须等待4A给出A_BAKE_UPDATE_DELIVERY_READY及正式commit/文件SHA/验证证据，之后由协调者另行核验登记，不静默升级旧收据。

本轮不执行4A-4、不修改Owner源码、不接入新的Owner提交；批准消除合同缺口，不代表更新实现已经交付或测试通过。

## 4A-3阶段事实（不作为slot）

4A_3_PASS。

Commit = 750d34c59768dbe3b6351a30acca09333689f95c。

用户本轮提供的阶段证据：RED 12 checks / 6 failures；GREEN 53 checks / 0 failures / exit0 / stderr empty；A_SCHEMA回归110 checks PASS；A_BAKE回归87 checks PASS；Doubles NONE。本轮只读确认该commit存在，包含该阶段六个Owner文件；没有重跑上述Owner用例，也未将其合入Integration。

4A-3只是A_EDIT组成阶段。A_EDIT = NOT_DELIVERED；4A-4尚待后续实施与验收，不能由本阶段或本批准替代。

I1: NOT_STARTED

I2: NOT_STARTED

Push: NOT_RUN
