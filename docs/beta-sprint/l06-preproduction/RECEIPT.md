# L06_DESIGN_READY

2026-10-09 · 06 Game Content · Beta Phase 3 / Track C

终章《交织的归途》设计已可评审：目标、现有机制组合、难度估计、作者地图/正式动作路线、失败与Reset恢复、局部提示及后续验收规格齐备。候选使用六次必要World Shift、Surface/EAST唯一投影连接、远岸Inner绕路与原Surface踏板/门，没有新增Runtime机制。

| 身份 | 实际值 |
| --- | --- |
| Worktree | `E:/godot/worktrees/block-girl-l06-preproduction` |
| Branch | `feat/l06-preproduction` |
| Baseline | `9e2e9c29a73272d431795f12db1fefaff2433b05` |
| Design / validation commit | **2276a7247251007686dd7409311e6d01258f86ce** |
| Candidate JSON SHA256 | `c6599a5ef256729f6861854ac970a075a487e0387766000d00cdcfb4f7fa174f` |
| Source commit history | 保留上述基线与设计提交；没有squash/rebase/reset |
| Push | **NOT_RUN** |

最终Delivery是包含本收据和文件清单的提交；最终交付消息给出其实际40位HEAD及CLEAN核验。收据不伪造自己的提交SHA。

## 可评审内容

- [DESIGN.md](DESIGN.md)：谜题目标、三方案取舍、当前接口约束、地图与六次世界选择、28动作参考键序、替代解、提示和失败恢复。
- [CANDIDATE.json](CANDIDATE.json)：完整候选地板、Spawn/Goal、唯一连接许可及作者路线；**DESIGN_ONLY_NOT_REGISTERED**。
- [ACCEPTANCE.md](ACCEPTANCE.md)：未来Owner分工、正式输入/3D/Reset/视角/自然解锁/Save/人类试玩验收步骤。
- [VALIDATION.md](VALIDATION.md)：原规则验证事实、局限、原始日志与重现命令。
- [SELF_REVIEW.md](SELF_REVIEW.md)、[STRUCTURAL_AUDIT.json](STRUCTURAL_AUDIT.json)：设计自审和33项结构核对；没有独立Reviewer或Human PASS声称。
- [SOURCE_REFERENCES.json](SOURCE_REFERENCES.json)：17份本地来源和两份外部08只读报告的精确SHA。
- [FILES_SHA256.json](FILES_SHA256.json)：本轮交付文件清单、长度与SHA；清单自身排除，最终Git提交提供其对象身份。

## 实际验证

最终 `native_02`：Godot4.7.2，PID **51476**，exit **0**，stderr **0字节**，**500 checks / 0 failures**。四条路线均通过原ContentState完成判定：正常、Reset重玩、不同视角顺序各21翻滚+6Shift提交；出生即切Inner替代路线23翻滚+6Shift提交。相机使用原90°snap，路线经原计时与commit完成，未注入路线位置或强制动画提交。

原查询拓扑 **148可达 / 148可完成**，最少Shift **6**，最少总动作 **28**；没有Shift、连接或门边的路径均不能到Goal。两种出生world×四view有合法后继；Inner门及错误连接世界/视角保留正常拒绝。roll/shift/view/held中原Reset取消pending并恢复。

首轮 `native_01` PID47168 / 485 checks / exit0 / stderr0保留。其后只增加设计验证断言，地图不变。结构核对曾发现DESIGN参考键序把EAST转角D误写为S，单字符文档修正后33项核对全部通过；失败与原因保留在 [STRUCTURAL_AUDIT_HISTORY.json](STRUCTURAL_AUDIT_HISTORY.json)。原Native结果没有被覆盖或升格。

Native进程执行HEAD仍为基线，实际消费的未提交源码SHA保留；不能把原日志HEAD改成设计commit。四条路线是**原timed API验证**，没有生产Scene、Presenter、原生InputEvent或正式Shell完成回调。图形、人类、FoundationSafety、Save/Continue与L05→L06自然解锁本轮均NOT_RUN。

## 字节保护与状态

每次运行均对 **3963** 份全部已有跟踪文件作前后SHA/长度核验，changed=[]；提交前结构审计再次确认当前字节一致。所有新增/修改路径限定在：

```text
docs/beta-sprint/l06-preproduction/**
tests/beta_sprint/l06_preproduction/**
```

L04 `.tres` SHA256仍为 **10f7a6a69a5e42c3796a6d0546938c7378be10f705fff3e40baf27db24efa18a**；L05 `.tres` 仍为 **b44258c1f5bb932956876eec83625d4c1f9be9596174ad75b8e1640c8ea209a6**。其Scene、提示及L01–L03均未修改。没有重玩五关来转记回归PASS；这是字节保护结果。

Foundation modifications：**NONE**；Runtime/Presenter modifications：**NONE**；Art modifications：**NONE**；Game Shell / Save modifications：**NONE**；production L06 registration：**NONE**。旧QA包、执行副本、日志、截图、存档未运行或写入。本轮只读引用08实际收据，不改变其L04 P1 CLOSED、L05 Human PASS、P0/P1/P2=0/0/3及L03 RETEST_PENDING。

设计自洽且由当前规则可表达；3D可读性、人类难度与正式接入仍须未来生产任务的独立证据。00可按两份真实提交核查范围并正常合并设计资料；本轮不自行接入第六关，不等待五关3D或L03首次玩家。
