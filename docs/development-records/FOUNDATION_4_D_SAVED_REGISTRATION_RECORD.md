# FOUNDATION-4 D_SAVED registration record

Owner delivery: a8ac1d4e05d9b9ff4f5b0df0a400677e413d88e0.

Consumed A_BAKE: 03e581d2c3ec28a1b42074d88495ce7ef580411d.

## 登记范围

本轮从Integration e8657375b6df8043069614217ace1750e9ab6828续接，保留R4及其后provenance独立批准记录。与Owner共同祖先为a4d0c9545d629e1c77518ac80781e1352510bf63；Owner仅七个计划内D2文件，Integration侧为文档，路径无重叠。ff-only因正常分叉拒绝后普通merge，无冲突、无Owner内容修改。未包含D3的test_whitebox_host.gd、canonical_loader.gd、whitebox_host.gd。

Owner最终Unit89/Real91证据是在七文件暂存、提交前运行；不是以测试名猜测已提交HEAD。逐文件核验identity.sources、真实受控project副本和最终Owner commit SHA一致，failures=[]、doubles=[]、import/run stderr0。正式A_SCHEMA/A_BAKE/D_PROTOCOL依赖版本与R4登记完全一致。Review交付记录无未解决Critical/Important。

唯一dependency_receipts仅新增D_SAVED；保留BASE/I_HARNESS/A_SCHEMA/A_BAKE/D_PROTOCOL/C_QUALITY。未登记A_EDIT/D_HOST/D_JOBS/B_EDITOR/D_FULL，未修改case_manifest或冻结Spec/Plans。

## 封包边界

捕获使用冻结源和执行模块的独立ResourceLoader工程调用正式4A投影/装配；input.ready在全部附件写入及最后源一致性边界通过后才发布。物化验证每个封存附件的长度/hash、snapshot身份、source fingerprint、执行版本和依赖/UID闭包，仅从包中取模块，不以活动源补缺。Real测试从封存authoring payload调用正式A_BAKE，再通过正式Codec往返，没有手写LevelDefinition替代。

真实测试包括缺blob时即使活动工程与物化目标存在也失败、移走活动源仍能物化、源改动期间拒绝发布input.ready、物理junction、执行文件篡改、引擎/UID/动态依赖不匹配等。测试修改限Harness隔离副本，没有操作4A活动工作树。

## 新版A_BAKE兼容复验的后续门槛

A_BAKE_PROVENANCE_COMPAT_REVALIDATION: DEFERRED_UNTIL_UPDATED_A_BAKE。

当前旧A_BAKE是正式收据中的有效依赖，本次D_SAVED交付可登记。获批BakeProvenance澄清不改变D_PROTOCOL、D_SAVED package schema、正式Level/Reader/Baker/Codec或I1 Runtime语义；不能据此否认本次旧wrapper上的GREEN。

触发点：协调者以后正式登记新版A_BAKE时，安排D_SAVED compatibility revalidation，记录新A_BAKE与D_SAVED的精确commit及证据：

1. 同一作者输入在新旧版本产生相同formal level/canonical语义。
2. package schema保持不变，D2封包/闭包/物化门槛仍通过。
3. 新provenance及其身份检查不会改变合法D2产物；失配来源必须按获批合同拒绝。
4. 若4D确需新增provenance guard，由4D另行交付D_SAVED update；不修改旧交付冒充兼容，不在本轮提前制造update。

## 证据与执行边界

本轮Integration证据根：E:/godot/foundation-4-d-saved-registration-2026-09-23/。I0/D2 Unit/D2 Real EvidenceName为dsaved_registration_i0_20260923_01、dsaved_registration_unit_20260923_01、dsaved_registration_real_20260923_01。边界为dsaved_registration_boundary_20260923_01。

D3 Graphical/I1只用原Harness Get-Missing读取依赖，不执行Invoke-Case。D3实现及I1均NOT_STARTED；不push，不修改Owner工作树。本次实际结果与最终收据SHA见该目录verification.json及REGISTRATION_REPORT.md。

本轮实际结果：I0 15/15、Boundary 28/28、D2 Unit 89/89、D2 Real 91/91；均exit0、failures=[]，D2 doubles=[]、import/run stderr均0字节。D3仅缺test_whitebox_host.gd；I1缺D_HOST与test_saved_vertical.gd。测试源码、receipt与准备提交的内容一致。
