# FIVE_LEVEL_ALPHA_QA_01_COMPLETE

Task: L04_P1_RECHECK_AND_L05_FIRST_PLAYTEST

| 项目 | 独立实测结果 |
|---|---|
| L04 P1 | CLOSED — L04_INNER_MOVEMENT_P1 |
| L04 Full Playthrough | PASS |
| L05 Unlock | PASS — 正式 L04 Goal 自然解锁 |
| L05 First Human Playthrough | PASS — L05_FIRST_HUMAN_PLAYTHROUGH_PASS |
| Five-Level Progression | PASS（历史前三关真实进度 + 本包 L04→L05 连续推进） |
| Save / Continue | PASS，含进程冷重启 |
| P0 / P1 / P2 | 0 / 0 / 3（P2 均为既有问题，本轮新增 0） |
| Softlocks | NONE_OBSERVED |
| Unexpected Shortcuts | NONE_OBSERVED |
| Release Recommendation | CONTINUE_BETA |
| Production changes | NONE |
| Push | NOT_RUN |

当前五关具备继续 Alpha/Beta 试玩的条件。本轮独立实际操作覆盖 L04、L05、真实解锁、正式完成 UI、Save 与 Cold Continue；没有读取 L05 作者解法，没有把 Owner 自动化结果转记为 Human QA。L05 仍保留 GREYBOX_PLAYABLE，首次通关通过不自动授予 FORMAL_PLAYABLE。L03 首次理解性保持 RETEST_PENDING。

## 构建与隔离

Build: E:/godot/beta-sprint-builds/beta_l04_p1_20261009_01

Integration receipt: 9e2e9c29a73272d431795f12db1fefaff2433b05

Frozen source: 4267365d5d794a82dff4acc731073eb532ee40a1

ZIP SHA256: 0e45be5e2fe21767bc0e72ddf0017d7013a93a6b25c3fb2eec2bcafb6a14c3b9

Engine: 4.7.2.stable.steam.ed1daf0bf，原始日志记录 D3D12 / Forward+。使用字节一致独立 run 副本中的原 play.ps1，APPDATA/LOCALAPPDATA 指向本轮外部 profile。正式包未被运行导入修改。

资格来自上一轮正常完成 L01–L03 的存档原始字节副本；其 completed/unlocked 未编辑。启动时 L04 可进入、L05 锁定。原文件 SHA256 620536263e49fe4a600a17859f7235c18f09b621595f90a7b51f10fe7c3504fb 保持不变。不得将本轮解释为新包首次从空存档重跑五关。

## L04 P1 关闭依据

正式选关进入 Surface/NORTH 起点；Space 切 Inner，短按 A 出现翻滚并在新位置落定，W 能继续移动。转到 EAST 后仍能移动。R 返回 Surface/NORTH 起点，随后重新切 Inner、沿路移动、依据游戏内提示建立 Perspective Connection、实际跨越、返回 Surface 并进入 Goal。正式完成界面及保存回调出现，L05 正常解锁。

之后从选关重新进入 L04，切 Inner 后先转 EAST，再用 S、A 翻滚继续，未遇新阻塞。本轮完成的是“中途 Reset 后一次完整通关 + 完成后重进入/转视角移动复测”，不声称第二次完整通关。

关键证据：

- [Inner 切换](E:/godot/beta-sprint-builds/l04_p1_l05_human_recheck_20261009T075359Z/screenshots/005_l04_spawn_shift_inner_0.png)、[A 落定](E:/godot/beta-sprint-builds/l04_p1_l05_human_recheck_20261009T075359Z/screenshots/007_l04_inner_first_move_settled_0.png)
- [Reset](E:/godot/beta-sprint-builds/l04_p1_l05_human_recheck_20261009T075359Z/screenshots/011_l04_reset_after_inner_movement_view_0.png)
- [真实 L04 Goal](E:/godot/beta-sprint-builds/l04_p1_l05_human_recheck_20261009T075359Z/screenshots/030_l04_enter_exit_tile_0.png)
- [正常 L05 解锁](E:/godot/beta-sprint-builds/l04_p1_l05_human_recheck_20261009T075359Z/screenshots/031_l04_complete_return_level_select_0.png)
- [重新进入后的 EAST 移动](E:/godot/beta-sprint-builds/l04_p1_l05_human_recheck_20261009T075359Z/screenshots/036_l04_east_inner_forward_a_0.png)

BATCH02-P1-001 的旧报告不改写；本轮独立关闭记录见 BATCH02-P1-001_CLOSED_RECHECK.json。截图 26–28 的标签曾前瞻使用 goal，但那些画面尚未通关；真实完成仅为序号 30，progress_before_l04_actual_goal.json 也证明此前未产生完成记录。

## L05 首次盲玩

首次进入至 Goal 约 4.40 分钟，包含主动暂停/恢复、Reset 和重新探索。目标是借不同世界道路与视角连接到达出口，用 Surface 踏板开门；入口文字与分阶段提示能够支持独立推导。非共同落脚点切换会明确拒绝；共同落脚点、连接所属世界、EAST 对齐、Surface 踏板条件均有游戏内提示。没有观察到长时间无进展、无提示隐藏条件、不可恢复状态或非设计捷径。

Esc 暂停/恢复保持 Inner 当前位置。R 回到初始 Surface/NORTH，随后重新探索并完成。踩下 Surface 踏板时门有可见打开变化，向前翻滚通过门并触发 Goal。

[首次进入](E:/godot/beta-sprint-builds/l04_p1_l05_human_recheck_20261009T075359Z/screenshots/039_l05_first_blind_entry_0.png) · [Reset](E:/godot/beta-sprint-builds/l04_p1_l05_human_recheck_20261009T075359Z/screenshots/049_l05_reset_from_inner_midplay_0.png) · [连接成功并跨越](E:/godot/beta-sprint-builds/l04_p1_l05_human_recheck_20261009T075359Z/screenshots/063_l05_first_connection_cross_0.png) · [踏板开门](E:/godot/beta-sprint-builds/l04_p1_l05_human_recheck_20261009T075359Z/screenshots/066_l05_surface_plate_pressed_0.png) · [首次完成](E:/godot/beta-sprint-builds/l04_p1_l05_human_recheck_20261009T075359Z/screenshots/068_l05_enter_final_goal_0.png)

完成界面显示“当前 Beta 关卡已完成”；该后续关卡入口真实点击后仍禁用，无越界跳转。Tab 焦点可见，Return 正常返回选关；选关五项均显示已通关。再次进入 L05 回到关卡起点，门恢复初始关闭。

## Save / Cold Continue

真实完成后的存档包含 completed/unlocked L01–L05，recent=L05。主动将 L05 改为已移动的 Inner/EAST 状态，再用游戏菜单退出。旧 PID27168 已于 08:06:44.0426944Z 的检查中确认不存在；新 PID49660 启动于 16:07:09.672696+08:00。

新进程主菜单真实鼠标点击 Continue，返回 L05 Surface/NORTH 的初始落脚点，门关闭，五关完成与解锁值保留。9 份存档快照 checksum 均有效；退出前后存档字节一致。

[退出前 Inner/EAST 中途状态](E:/godot/beta-sprint-builds/l04_p1_l05_human_recheck_20261009T075359Z/screenshots/077_l05_cold_test_inner_east_0.png) · [新进程 Continue 返回起点](E:/godot/beta-sprint-builds/l04_p1_l05_human_recheck_20261009T075359Z/screenshots/082_cold_continue_real_click_0.png)

两次自然退出的 Godot 原始日志仅包含引擎和显卡信息，各147字节；stderr/包装器 stdout 均为空。本轮没有复测 L02 退出警告，既有状态保持。两个游戏 PID 和两个包装器均正常结束，GRAPHICAL_SLOT_RELEASED.json 已记录。

## PLAYER_CONFUSION

- L04：连接成立后先试 D 无位移，改 W 才跨越；视角变化后需要重新对应方向。
- L04：EAST 下出口转角不够直观；沿直路多走两格，转回 NORTH 后看清并到达 Goal。
- L05：第一步不能 World Shift 时短暂不确定；明确拒绝提示和下一格提示帮助找到共同落脚点。
- L05：Inner 桥转角被角色遮住，先试 D 无位移，试 W 后看清路径。

以上均为短暂、可自行解决的探索困惑；没有新增阻塞问题。只记录实际观察，不声称穷尽所有路线或代表所有首次玩家。

## 保留状态与 Owner handoffs

- 00：可接受本包聚焦 COMPLETE，解除 L04 P1 QA gate，继续 Beta；保留历史记录及新包独立身份。
- 01：移动、Reset、正式完成和冷重启 Continue 实测通过，无新 Runtime 缺陷。
- 06：L04_INNER_MOVEMENT_P1 CLOSED；L05 首次盲玩 Goal PASS。考虑上述方向/转角反馈；L03 首次理解性需真正新测试者。
- 05：保留出口转角与桥转角遮挡反馈供后续可读性工作；本轮冻结美术未修改。
- 07：自然解锁、最终完成禁用后续入口、键盘返回、Save/Continue 通过；保留既有非阻塞 P2。

P2 保留 VIS01-P2-001 / UI-08-K01（960 Pause 辅助文字裁切/重叠）、L03_STALE_HINT_EXISTING、FOCUS-3D02-P2-001（选关表现说明与实际3D不一致）。本轮不重复三尺寸矩阵，不将历史 PASS 转记为本包分辨率 PASS。

## 不可变核验

正式包1279文件及ZIP未变；1270个 manifest 源文件在运行前SHA匹配。运行副本1278个原文件保持不变，Godot自身导入自动重写一份 icons_source.svg.import 为 valid=false；SVG原资源未变，未观察到对应 UI 失败。该元数据差异的前后字节单独保留，供00检查；没有手动修改生产代码、美术或包。

538份旧封存证据及原始进度不变。本轮83张原生 Computer Use 截图，完整输入时间线见 actual_input_trace.json。首次鼠标操作前出现一次工具外部输入提示；重新观察后主菜单未变化，再执行成功，未将失败调用记为有效操作。没有绕过 Computer Use 或调用外部GUI自动化。

工作树：E:/godot/若叶睦/方块少女-若叶睦，HEAD13177bb713c229fd5691c1e53cf5ba4d45f2ff76；原有 ?? docs/art/BETA_UI_ART_DIRECTION_01/ 保留，和开始时相同。Production changes: NONE；Push: NOT_RUN。
