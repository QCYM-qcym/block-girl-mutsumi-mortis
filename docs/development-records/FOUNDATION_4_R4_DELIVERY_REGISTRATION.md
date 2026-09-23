# FOUNDATION-4 R4 unified delivery registration

本轮仅登记/核对 A_BAKE、C_QUALITY 并记录 4B-1 Unit 阶段证据。I1/I2 NOT_STARTED；不登记 B_EDITOR。

## 承接正式历史

用户引用的起点9dca4538ca77a88a9adf16803579b663f4ea6c87已由上一轮受控合并及登记推进至a4d0c9545d629e1c77518ac80781e1352510bf63。本记录在该真实当前HEAD上续接，不回退、不重复合并、不制造第二份dependency_receipts。

唯一正式收据：tests/foundation/authoring_integration/dependency_receipts.json。其字节本轮不变。R4由包含本协调记录的提交承载；最终完整提交SHA见外部REGISTRATION_REPORT.md，避免自引用。

| Registered | Commit |
|---|---|
| BASE | bd393303d3a21ae3ddebc6643a94a114437365a3 |
| I_HARNESS | a7e9a80a5542b184a2e06610d3e2f651fa4edfaf |
| A_SCHEMA | 2908b99dd641d94cda7ea2995bf5ddefb3d82a64 |
| A_BAKE | 03e581d2c3ec28a1b42074d88495ce7ef580411d |
| D_PROTOCOL | 6176a45c614f678c8b248d5289f9a672a971043b |
| C_QUALITY | bb27f8c7cd6e2d9d94fbe3b8d3f98b99f86484d1 |

A_EDIT、D_SAVED、D_HOST、D_JOBS、B_EDITOR、D_FULL均未登记。

## A_BAKE与C_QUALITY核验

承接上一轮完整Owner交付审查与证据：E:/godot/foundation-4-abake-cquality-registration-2026-09-23/。本轮再次核对所有正式slot的commit blob/工作区SHA完全相符。A6文件、C14文件归属批准计划；其Owner提交与阶段历史已保留，没有复制Owner文件或修改交付内容。

A仅将Authoring转换成临时旧profile，正式Reader拥有坐标量化/Cube orientation，正式Baker拥有验证与canonical构建，Codec拥有content hash。没有调用私有validation seam。树在Reader返回后、处理结果前释放；后续Baker失败不再持有树；schema/identity失败发生在分配之前。87项Real测试覆盖成功、Reader/Baker/schema/identity/budget/semantic失败的临时树释放，失败level=null且不回填旧level，以及正式Codec往返。SourceMap早期仅捕获Reader路径，成功后按实体身份关联canonical路径，歧义/未定位不猜作者对象。A_EDIT未声明交付。Owner旧回归210项证据沿用已核验记录。

C将同进程Explorer活图直接交Softlock；不恢复磁盘图为可信图。Ablation正式独立baseline/子搜索，原图selected trace保持独立，经过Trace.validate、Spawn绑定、validate_semantics、Milestone分析；不用Ablation内部trace替换。原native_result及budget/incomplete/safety unknown保留，无顶层acceptance verdict。C1/C2 Real无算法double；C3仅Unit边界/显式计数和故障注入。Owner旧回归1446项证据沿用已核验记录。

## 4B-1阶段证据

4B-1 Unit: RECORDED_AS_PHASE_EVIDENCE_ONLY
Owner status: 4B_1_UNIT_PASS
Commit: 7870924423a505eb080b14934489ed50c46a9013
56 checks / 0 failures / exit0 / import及run stderr0字节。
Double: res://tests/foundation/editor/service_double.gd
Real: NOT_RUN
Owner Editor: DEPENDENCY_PENDING: D_JOBS。

只读核验Owner的4b_4b1_final_20260923与4b_4b1_editor_gate_20260923原始证据；最终Unit受控副本与14个提交文件逐一SHA一致。未将此提交合入Integration；不把Owner Editor依赖分类冒充当前Integration已接入B实现。未新增B_EDITOR slot，不宣称B_EDITOR交付。

## 本轮验证证据位置

E:/godot/foundation-4-r4-registration-2026-09-23/。复验结果由verification.json、REGISTRATION_REPORT.md记录。Integration运行EvidenceName为r4_registration_i0/a2/c1/c2/c3_20260923_01（五个独立名称），边界为r4_registration_boundary_20260923_01。

I1/I2仅调用原Harness的Get-Missing进行只读分类，不执行Invoke-Case。预期I1缺D_SAVED/D_HOST及test_saved_vertical.gd；I2缺A_EDIT/D_JOBS及test_quality_replay.gd。D2 Unit/Real只缺尚未接入的test_saved_snapshot.gd，A_BAKE已满足；具体以本次实测记录为准。

不push，不启动I1/I2；不修改Owner工作树、公共Spec/计划、case_manifest或project.godot。

## 本轮实际结果

记录时间：2026-09-23T21:06:20.504765+08:00。

I0 15/15；Boundary 28/28；4A-2 Real 87/87；4C-1 Real 58/58；4C-2 Real 79/79；4C-3 Unit 47/47。均exit0、failures=[]；四项Owner用例import/run stderr均0字节。每次identity中的receipt与当前正式JSON一致；正式slot源码SHA与受控project副本一致，Real排除double文件。

D2 Unit/Real均exit2、checks0、failures=[]，唯一missing为script:res://tests/foundation/authoring_acceptance/test_saved_snapshot.gd。I1/I2实际缺项与上述预期完全一致，仍NOT_STARTED。Boundary中的故意FAIL输出仅验证聚合失败优先级，整体28/28。

A_BAKE_RECEIPT_READY；C_QUALITY_RECEIPT_READY；CONTRACT_MISMATCH: NONE。
