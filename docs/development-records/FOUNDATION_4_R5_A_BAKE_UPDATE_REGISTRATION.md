# FOUNDATION-4 R5 A_BAKE update registration

A_BAKE_UPDATE_RECEIPT_READY
CONTRACT_MISMATCH: NONE
D_SAVED_COMPATIBILITY_WITH_UPDATED_A_BAKE: PASS

## 登记与历史

起点：f4e8ccd7144084b2def96d1020026c7eefd9c9f6。
新版A_BAKE：e0940278fe425d7f77eb6a5b4ea042067606258d。
原D_SAVED：a8ac1d4e05d9b9ff4f5b0df0a400677e413d88e0，保持不变。

Owner更新保留03e581d原A_BAKE、750d34c59768dbe3b6351a30acca09333689f95c的4A-3历史以及59b7eaf6c87ebd3dc434f1a95ebfcdadc9395ed3批准消费提交。批准澄清SHA仍为AD9A19383B07DB4319BE690E06B509CB0C80F62E06FAEE4DD21DCB30E3DCB00E。

共同祖先03e581d；双方共同新增的两份批准文档逐字节一致，其余路径无冲突。ff-only因正常分叉拒绝后普通merge成功。未重写历史、未cherry-pick或手工复制Owner文件。A3六文件随既有历史合入，但不登记A_EDIT；A4 intent_binder.gd/test_intent_binding.gd未在交付中，也未合入。未操作4A/4D WIP或4B/4C工作树。

唯一dependency_receipts仅把A_BAKE的commit和两个变化文件SHA更新为Owner清单，完整六文件路径保留。BASE/I_HARNESS/A_SCHEMA/D_PROTOCOL/C_QUALITY/D_SAVED完全不变。未登记A_EDIT/D_HOST/D_JOBS/B_EDITOR/D_FULL。case_manifest、Spec/Plans、SourceMap、Reader/Baker/Codec及正式Level schema均未改。

## Owner核验

读取A_BAKE_UPDATE_DELIVERY.json与A_BAKE_UPDATE_REPORT.md；RED105/15与GREEN105/0原始结果存在，GREEN六文件SHA与最终commit blob和受控project副本一致，exit0、import/run stderr0、doubles=[]。生产变化仅在适配器：经验证身份复制为独立的恰三字段BakeProvenance；成功六字段返回，失败明确null。run变化不影响formal Level/canonical/hash，SourceMap不增加run_id。本轮不宣称尚未交付Binder已通过unknown-field等负例。

## Integration实际复验

| Case | Mode | Checks | Result |
|---|---|---:|---|
| I0 | Unit | 15 | PASS / exit0 |
| Boundary | Harness | 28 | PASS / exit0 |
| 4A-2 | Real | 105 | PASS / exit0 / failures=[] / doubles=[] |
| 4D-2 | Unit | 89 | PASS / exit0 / failures=[] / doubles=[] |
| 4D-2 | Real | 91 | PASS / exit0 / failures=[] / doubles=[] |
| 新旧实际产物兼容比较 | 只读证据probe | 145 | PASS / exit0 / failures=[] |

三个Owner用例import/run stderr均0字节。正式receipt绑定源码SHA与本次隔离副本一致。边界仍28项，仅将已更新A2预期计数87改为105，拒绝门槛不变；故意FAIL输出是聚合负例，整体28/28。

证据根E:/godot/foundation-4-r5-registration-2026-09-26/。Harness EvidenceName分别r5_i0_20260926_01、r5_a2_20260926_01、r5_d2unit_20260926_01、r5_d2real_20260926_01及r5_boundary_20260926_01。原始运行记录在Integration/.godot/foundation-authoring-tests/。verification.json绑定最终receipt、源码、结果与分类。

## D_SAVED兼容结论与摘要说明

上一轮DEFERRED_UNTIL_UPDATED_A_BAKE待办在本次受控新版环境复验后关闭为PASS，没有创建新的D_SAVED提交或修改4D guard。

使用旧版ac_registration_a2_20260923_01及新版r5_a2_20260926_01真实Bake输出；实际作者fixture逐字节相同。通过正式Codec比较level和canonical，而非手写Level替代。新旧formal Level完全相等，canonical SHA-256为fee8ab66f690e9abe1c8aaa0ca8ee5c71f6852704e067be85f9f73b9872ea54b，content_hash为51dad92b4a10183a4ec82d8f27ceb4f2a8374d19d726f4a97165d6bbd4fe03a1。SourceMap完全相等。

使用旧版dsaved_receipt_confirm_real_20260923_01与新版r5_d2real_20260926_01实际input.ready：公开Wire.decode均接受；manifest、authoring/source/policy wire不包含bake_provenance，完整wrapper不能伪装成input_manifest，未引入provenance kind。作者payload wire逐字节相同，包schema版本/字段不变，D_SAVED生产文件SHA完全不变，input.ready写入顺序逻辑不变。

execution_digest不是要求在源码升级后保持相等。唯一变化的执行闭包模块是res://foundation/authoring/authoring_adapter.gd；其SHA变化按完整VersionsRecord规范摘要正常改变execution_digest。除modules中此项外，VersionsRecord所有字段均相同：

- 旧execution_digest：cf77ff019c5fe05677ff95c03f3ee6fb16bb4b469ea2a68022589170fb3dfa9f。
- 新execution_digest：e1882cf51fc2165bf5a809f9c7410c15c22b1049855c86d67a78669b25f4b5ea。

两者均实测等于Wire.digest("versions",versions)。input.ready摘要也绑定该执行身份、模块附件及本轮run/snapshot，不能声称跨run/代码版本的package digest不变。它没有混入运行后返回的wrapper字段；记录schema与摘要算法不变。源模块blob当然包含新增代码文本，这是合法源码身份，不是序列化BakeProvenance结果。

## 依赖分类与停止

使用原Harness Get-Missing只读分类，未Invoke-Case：

- A4 Real：Owner implementation pending，仅缺test_intent_binding.gd；A_BAKE slot已满足。
- D3 Graphical：OWNER_TEST_NOT_DELIVERED，仅缺test_whitebox_host.gd；D_SAVED slot已满足。
- I1：DEPENDENCY_PENDING: D_HOST、test_saved_vertical.gd。
- I2：DEPENDENCY_PENDING: A_EDIT、D_JOBS、test_quality_replay.gd。

I1/I2: NOT_STARTED。Push: NOT_RUN。

最终receipt完整SHA通过提交后git rev-parse HEAD记录于外部REGISTRATION_REPORT.md，避免文档自引用。
