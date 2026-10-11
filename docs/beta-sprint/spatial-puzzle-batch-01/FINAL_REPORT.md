# SPATIAL_PUZZLE_BATCH_01_FINAL_REPORT

**SPATIAL_PUZZLE_BATCH_01_PLAYABLE_READY** — 四机制和《六面归位》已完成实际自动化集成验收，真人 QA 尚未执行。

| Git / Baseline | 实际身份 |
|---|---|
| Development Worktree | `E:\godot\worktrees\block-girl-spatial-puzzle-batch-01` |
| Branch | `feat/spatial-puzzle-batch-01` |
| Base SHA | `d1277ec90b5a739efd4862d314e6c29ac5ac1eda` |
| Integration commit | `52548e47ffcc6f3d76dadfdb4a6b481b31e64511` |
| Build Source SHA | `26603d532154dbf1a7fb9cea475a55b206a40cb6` |
| 后续提交差异 | 测试与证据；Foundation/game/experiments/production/project 配置与 Build Source 完全相同 |
| Push / Merge to main | NOT_RUN / NOT_RUN |

| 功能 | 结果 |
|---|---|
| World Shift Gate | PASS：固定点、锁定/解锁、显式 Space、正式映射和拒绝保持状态 |
| Orientation Loop | PASS：同位置不同姿态与闭环，六面实体身份保持 |
| Face Lock | PASS：错误面移动成功不激活，正确面原子锁存，Reset 清除 |
| Perspective Fork | PASS：同 Source/World/Orientation/正式输入，Camera 分流到唯一目标，探索支路可恢复 |
| RUBIK_SPATIAL_PUZZLE_01 | PLAYABLE：正常、Reset 后及替代支路完整通关 |
| Solver / Safety | PASS：组合完整图908状态／3916边；软锁0，未锁存进入Inner绕过0 |
| Replay | Logical 与 Formal Graphical 分别 PASS；五图正式图形487项 |
| Graphical / input lifecycle | 五图自然图形947项 PASS，包含长按跨完成边界和实际 pending Unload |
| Human QA | NOT_RUN；首次理解性 RETEST_PENDING |

01：1393项；09：290项；03最终选定独立证据2547项。它们是不同范围的断言数，不能相加冒充唯一测试数。03的98条谓词保持80 PASS／8引用通过／10 NOT_RUN：5真人、4无需重复的替代搜索、1未执行的组合全边权限独立盘点。09的完整图支持其明确记录的零软锁和锁存绕过结论，不冒充该盘点。

| 回归 / 实际包 | 结果 |
|---|---|
| L01–L05 | 包内真实渲染受影响回归206 PASS，原谜题数据不变 |
| Perspective Fall / World Shift / Orientation | 01旧Profile专项、03旧Connection与Camera、五图正负路径 PASS |
| Game Shell / Save / Continue | 包内三尺寸219 PASS；独立冷进程真实Continue11 PASS |
| 启动 | 实际 play.ps1 启动正确主场景，exit0、stderr空 |
| 包完整性 | 测试后1467文件哈希仍匹配；150导入UID逐项匹配；zip SHA保持不变 |

所有选定包内运行 exit0、stderr空、doubles=[]、无源文件漂移。旧五关使用受控独立存档夹具做玩法回归，未据此新增“五关正常解锁链已重测”的结论。

- Godot Project：`E:\godot\beta-sprint-builds\beta_spatial_puzzle_batch_01_20261011_01\project\project.godot`，打开后 F5。
- Playable Build：`E:\godot\beta-sprint-builds\beta_spatial_puzzle_batch_01_20261011_01`。
- Launch Script：`E:\godot\beta-sprint-builds\beta_spatial_puzzle_batch_01_20261011_01\play.ps1`，需 Godot4.7.2；独立qa-profile。
- Archive：`E:\godot\beta-sprint-builds\beta_spatial_puzzle_batch_01_20261011_01.zip`。
- Zip SHA-256：`ade30ffc68d3e3853e6ce7a57ea8aed46d3b25282e889b8de2ccc4f1aec8d4ca`。
- Visual Evidence：`E:\godot\worktrees\block-girl-spatial-puzzle-batch-01\docs\beta-sprint\spatial-puzzle-batch-01\evidence\package_graphical_01`；另保留真实路线、Replay和旧五关图像。
- QA Handoff：08已接收并独立核验包身份，已准备玩家流程；当前合格首次测试者0人，见 [QA_HANDOFF.md](QA_HANDOFF.md)。包内证据包封存；最终包后验收以本目录收据为准。
- Obsidian Notes：`E:/obsdian/青澄的水泥房/方块娘/若叶睦/核心机制/13-游戏设计与机制研究/` 中本轮三篇；版本管理只读快照见design/。
- Design Documents：[CONTRACT.md](CONTRACT.md)、[RUNTIME_INTERFACE.md](RUNTIME_INTERFACE.md)、design/三篇最终规则/综合谜题/验收差异记录。
- 详细分层：[TEST_REPORT.md](TEST_REPORT.md)、[INTEGRATION_MATRIX.json](INTEGRATION_MATRIX.json)、[RECEIPT.json](RECEIPT.json)、quality/FINAL_REPORT.md。

未解决的新生产缺陷：0。已修复锁状态排序、复合ENTER分类、SourceMap来源、UI重试焦点/遮挡、着地期间Camera完成通知、包内GLB UID缓存。历史失败、超时与候选rc01均保留；Windows长路径合并遗留文件先按Git blob核验后隔离保存在本工作树.godot/merge_recovery_480，未reset或覆盖用户数据。

已批准Art与旧关卡/SaveStore源未修改；Foundation改动仅为本任务授权的opt-in机制与消费者。main/editor/release/tag身份保持基线。实验几何、主观手感和首次理解仍需真人评估。Continue恢复实验起点；减少动态为当前菜单会话选项。STAIR_CLEARANCE=PARTIAL_PASS，STAIR_TRAVERSAL=NOT_RUN。

本次保留专用分支和工作树；本报告随证据收据提交，提交后的实际 Working Tree 状态另在交付消息登记。不推送，不合入main。
