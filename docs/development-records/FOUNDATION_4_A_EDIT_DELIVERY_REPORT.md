# FOUNDATION-4A A_EDIT 交付验收记录

A_EDIT_DELIVERY_READY
CONTRACT_MISMATCH: NONE

记录时间：2026-10-05，Asia/Shanghai。
工作树：E:/godot/worktrees/block-girl-foundation-authoring-data
分支：feat/foundation-authoring-data

## 历史与正式依赖

本轮恢复时 HEAD 为 6b7597ae2a6f77a882717581a63775f26cc1381e，工作区 clean；该提交已经包含 Binder 与扩充测试。本轮先只读核验现存提交、reflog、保存的行为 RED/GREEN 证据，复用现有实现，未重新制造 RED、覆盖 WIP 或重写历史。
当前正式 D_SAVED receipt 116538cb639791b01b9a5cf0bce18f2c006817b6 是该 HEAD 后代；本轮 ff-only 接入此用户指定 receipt，随后仅修正 Owner Real 测试的临时 saved source 路径。

| 交付/批准 | commit |
| --- | --- |
| A_SCHEMA | 2908b99dd641d94cda7ea2995bf5ddefb3d82a64 |
| A_BAKE 原交付 | 03e581d2c3ec28a1b42074d88495ce7ef580411d |
| A_BAKE update | e0940278fe425d7f77eb6a5b4ea042067606258d |
| 4A-3 | 750d34c59768dbe3b6351a30acca09333689f95c |
| A4 实现 | 6b7597ae2a6f77a882717581a63775f26cc1381e |
| Resource-resolution approval | 24e2c18016a5f7ddba102c81c28c3c2f66be114a |
| Track A approval | 21c23df2ac549a6c998cd2a3604ff55c2f891684 |
| Execution-closure approval | 536faf950cedd30a04172ae5744ecfde09fbdf97 |
| D_PROTOCOL | 8f7fb52f029053bda10b965da840c6763fc13bf0 |
| D_SAVED | 4f2cfd4cba11677fe3dae6fa3dd66a4148e15e11 |
| D_SAVED receipt / 本轮验收基线 | 116538cb639791b01b9a5cf0bce18f2c006817b6 |

已核验上述依赖/Owner 提交均为本分支祖先；A_SCHEMA、A_BAKE、4A-3 历史保留。
已核验批准澄清 SHA-256：
Resource resolution = 5e9e1ec021b700dc819f67585aa60390bf67eaa65eab4ec5a0c45995564fbf63。
Source Intent Digest = e1df9d6da305c764bffc53cb930ef7149a8ef734bb2585e10d2aeca69137cdee。

D_SAVED production 文件保持登记 blob SHA。current D2 test support 采用登记文档明确列出的独立 validation-support commit 5749b932f947c44b35f21c62478bd76720e32969；未修改历史 receipt 的测试 SHA，未复制/改写他 Owner 实现。4A-4 使用原登记 Harness，无 adapter。

## RED 与本轮验证

保留原证据，不覆盖或销毁：

| 阶段 | EvidenceName | checks | failures |
| --- | --- | ---: | ---: |
| Unit 行为 RED | binder_unit_red_02 | 107 | 86 |
| upstream 诊断回归 RED | binder_unit_diagnostics_red_02 | 130 | 1 |
| current saved 行为 RED（Owner 直接入口） | binder_real_current_d2_red_01 | 9 | 1 |

上述 RED 均实际进入 test_intent_binding.gd 并产生行为断言失败，非 parse error、missing file、unknown Harness case 或 exit2/checks0。

本轮第一次正式 Real：4a4_resume_real_20261005_01，child 6 checks / 1 failure / exit1 / stderr empty。原因是测试将项目外 evidence 目录转换为绝对 source URI，capture_saved 在绑定前返回 REQUEST_INVALID。Harness 汇总显示 checks0；不将其认作 Binder 行为 RED。修正仅涉及测试 fixture 的 URI：saved sources 放在当前项目内唯一 res://.godot/foundation-authoring-tests/binder_sources/<process>_<ticks>/<scenario>/ 路径。正式 Harness 和 production 均不变。

最终新鲜结果：

| Case / 入口 | EvidenceName | checks | failures | exit | stderr |
| --- | --- | ---: | ---: | ---: | --- |
| 4A-4 Unit / Owner Godot entry | 4a4_final_unit_20261005_01 | 130 | 0 | 0 | 0 bytes |
| 4A-4 Real / 正式 Harness | 4a4_resume_real_20261005_02 | 127 | 0 | 0 | import/run/engine 均 0 bytes |
| A_SCHEMA / 4A-1 Real | 4a1_aedit_regression_20261005_01 | 110 | 0 | 0 | import/run/engine 均 0 bytes |
| A_BAKE / 4A-2 Real | 4a2_aedit_regression_20261005_01 | 105 | 0 | 0 | import/run/engine 均 0 bytes |
| Edit operations / 4A-3 Unit | 4a3_aedit_regression_20261005_01 | 53 | 0 | 0 | import/run/engine 均 0 bytes |

合计 525 checks，全部 failures=[]、exit0。
证据根目录：.godot/foundation-authoring-tests/，均未纳入 Git。

正式 Real/回归命令：
pwsh -NoProfile -File tests/foundation/authoring_integration/run_module.ps1 -Module 4A -Case <case> -Mode <mode> -EvidenceName <上表名称>

Owner Unit 命令：
Godot --headless --path E:/godot/worktrees/block-girl-foundation-authoring-data --script res://tests/foundation/authoring/test_intent_binding.gd
进程环境 FOUNDATION_TEST_MODE=Unit，FOUNDATION_TEST_EVIDENCE 指向上表独立目录，用户/临时目录隔离；process.json 记录退出码及实际参数。

引擎：Godot 4.7.2.stable.steam.ed1daf0bf。
引擎 SHA-256：12310c74bdda7dcd43f28e971f33047dcecadd436b68169d61ce41009006df38。

## Binder 与真实链

正式签名保持四参数：
bind_intent(authoring_intent, resource_table, successful_bake, snapshot_identity)。

成功输出包装保持四字段，bound_intent 严格既有八字段 PuzzleIntent。level_hash / rule_version 仅消费本轮成功正式 Level。绑定后调用真实 IntentValidation.validate；失败 bound_intent=null、source_intent_digest=null，不保留历史结果，上游正式 AnalysisIssue 保留。

Explicit empty、milestone、bypass、mixed references、AT_FACE、标签合法性/唯一性、整表封闭校验、duplicate authoring_id、missing/wrong-kind refs、陌生 Payload 根、错误 Bake、run/snapshot/source fingerprint、SourceMap 和未知作者版本均有断言。
AT_FACE 经作者 schema 校验后调用正式 SurfaceGeometry.face_id。资源仅按 authoring_id 索引；声明顺序保留，表重排不改变结果，无动态 load 资源、邻近推断或数组位置匹配。

Real 链：
实际保存 .tscn/.tres → current D_SAVED.capture_saved → execution_project.verify → verified AuthoringPayload → 正式 A_BAKE → Binder → 正式 IntentValidation。

binder-real-captures.json 记录 empty、optional、mixed、missing 的实际 SnapshotRef、真实摘要、Bake hash 及绑定结果。前三者得到恰八字段正式 Intent；missing 捕获成功、摘要 null、Binder 拒绝而不造空声明。missing 的完整流程 NOT_RUN/MISSING_INPUT 由合同指定的 4C/4D 分类；Binder 不创建流程状态。

每种存在 Intent 的场景均重新 capture 同一 saved source：新的 run/snapshot ID、相同源 fingerprint/digest；旧 Bake 对新 identity 被拒绝。篡改 SnapshotRef.source_intent_digest 被真实 4D execution_project.verify 拒绝，在绑定前终止。

Digest ownership = 4D_ONLY / PASS。
4A 只检查给定摘要格式/非空，核对 provenance，并原值回传；没有 SHA、ToolWire.digest、JSON canonical hash 或源 Resource hash。
同 Payload 来源是批准 API 前置条件，Real 从同一经验证 sealed Payload 取声明和表。Binder 本身的格式检查不认证任意调用方提供的摘要或资源表。

## Doubles 与 Review

Unit 唯一 double：明确标记的 test-only SnapshotIdentity fixture，不宣称完成 4D sealed provenance 认证；投影、组装、Bake、Geometry、IntentValidation 为正式模块。
Real doubles=[]。A_SCHEMA/A_BAKE/4A-3 回归 doubles=[]。

独立只读源码审查：无 Critical/Important findings。核对四参签名、封闭表/引用、正式 Geometry/IntentValidation、八字段输出、清空失败结果、Bake/SourceMap 身份与无 4A hash。
审查不代替测试，本文测试计数来自本轮真实进程结果。
不将任意调用方表的密码学认证、4C/4D missing-stage 分类、其它 Owner 或 I2 纳入 4A 实现职责。

4A-3 COPY/DELETE/MAKE_UNIQUE/proposal lifecycle 保持原交付，53 checks 回归通过，源码自 750d34c5 未改。
A_BAKE wrapper/SourceMap 自 e0940278 未改。未修改冻结 Spec/Plans、公共合同、4B/4C/4D、Reader/Baker/Codec 或 dependency_receipts。

## Owner files / SHA-256

| 文件 | SHA-256 |
| --- | --- |
| foundation/authoring/id_registry.gd | d1f69acf0675a405efda5df5511e33f067a583ea4bce4a9a3e90524e5e476a11 |
| foundation/authoring/id_registry.gd.uid | 6202ee5e98cf071573e667ef3f6945471b79553f8bea6be76a1f7d4c012b07fd |
| foundation/authoring/edit_operations.gd | e2a02cdb7deee38162fc0d358c769e4f551314113fe89e5db082779087581cea |
| foundation/authoring/edit_operations.gd.uid | 323b818448a1826cef50cf99d7badedb72cf44feab17cdb6fbe57b92fefa88ec |
| tests/foundation/authoring/test_authoring_edits.gd | 0e470ded63c5a2de137cbe4db6ddae52fd7000166cefe28d62f7aa1ddb554eb1 |
| tests/foundation/authoring/test_authoring_edits.gd.uid | a8c010f008551b7c9d9617f33999f945f96205e744831f1d976f61e233ce735e |
| foundation/authoring/intent_binder.gd | 0d67b9c2c86e9bf59e7b29c84241136c0cde7e35bb4fc7e121e911958262cdce |
| foundation/authoring/intent_binder.gd.uid | e22a3cf54a73caaf0f67b0c81544ad1e97362da243c028a938dd78204068dae6 |
| tests/foundation/authoring/test_intent_binding.gd | 34fbab48db2f0f0c31a5d1d05b32cff19de0b4ad15d88318df9d0be54dae31cc |
| tests/foundation/authoring/test_intent_binding.gd.uid | 244c23ff51e7596e170fb7dc51ac9bd177bdcf01e49eb0b228ea053dde989331 |

本轮后继提交仅包含 Owner Real fixture 路径修正及本验收报告；既有 Binder/4A-3 实现提交保留。交付 commit 的真实 SHA 在提交完成后的响应列出，不伪造预先 SHA。
提交前 git diff --check 通过；只暂存上述测试和此报告，证据、缓存、stdout/stderr 均忽略。
Push: NOT_RUN。I2: NOT_STARTED。无需等待其它 4A 功能，交付供协调者登记 A_EDIT。
