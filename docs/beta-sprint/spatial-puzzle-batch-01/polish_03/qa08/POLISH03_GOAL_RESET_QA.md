# POLISH03 — 08 Goal/Reset 图形复测

Task: SPATIAL_PUZZLE_BATCH_01_POLISH_AND_ACCEPTANCE_03
2026-10-13（Asia/Shanghai）

**QA08-C02-UI-RESET-LABEL-01：定向图形复测 PASS，建议 00 关闭该 P2。** 最终问题状态仍由 00 登记。SPATIAL-CARDINAL-01 保持 CLOSED，未重跑方向矩阵。Human QA、首次理解性、OS 物理键盘均 NOT_RUN。

Build: beta_spatial_polish_03_20261013_01
Source: f26ea4b19da836d65eb7d981dbf22f4022045b01
ZIP SHA256: 463ad3429910e8b5c765164b4ca3658cb6ffd245284d52690574afe9fafd50dc
External evidence: E:/godot/beta-sprint-builds/spatial_polish03_08_graphical_20261013T144725Z

## GR01–GR08 实际结果

| 项目 | 实际结果 |
|---|---|
| GR01 Goal→R | PASS：角色回到 Surface 起点，HUD 与底部完成标题同步清除，goal_seen=false；历史完成进度保留 |
| GR02 再次 Goal | PASS：真实动作再次到 Goal，标题/HUD 恢复；每次运行只有一次自然 Goal 信号 |
| GR03 鼠标 Reset 对照 | PASS：与 R 一致；鼠标 Reset 后键盘仍可再次完成 Goal |
| GR04 连续/快速 Reset | PASS：静止时六次快速 R、两组 R/鼠标交替；另在 Roll/Fall 进行中各六次 R，随后均能重新通关。补充按键间隔实测 44–90ms |
| GR05 返回与重入 | PASS：Goal 后、Reset 后返回菜单再进，新 Host、起点和标题正确 |
| GR06 Shift/Camera | PASS：真实 Shift/Camera 完成后 Reset，世界、姿态和相机恢复正式起点 |
| GR07 动作取消 | PASS（有限观察）：Roll/Shift/Camera/Fall 各做 Reset 和返回，共八例，确认动作 pending；每例随后观察 1 秒，无旧状态回写、虚假 Goal 或残留标题 |
| GR08 收尾 | PASS：正式菜单返回，成功运行自然 exit0；原包与副本正式文件及 ZIP 不变 |

GR07 的实际“旧过期回调到达”未观察到，记 NOT_OBSERVED；没有注入假 Goal、人工 finish 或改 State 来制造覆盖。只声明自然取消和有限等待范围通过，不声称全部回调时序已穷举。日志显示 R 在 ROLL/FALL、活动 Shift、活动 Camera 时到达，并使 generation 从 1 增至 2。主运行四次自然 Goal；两条明确的 Shift cancel 通知另列，不把它们当作全部八例的统一回调计数。

## 图形与运行证据

Godot 4.7.2-stable (steam)，Windows，D3D12 Forward+ / RTX 5060 Ti。实际 viewport 及全部原始 PNG 为 1280×720。Input.parse_input_event 经过正式菜单/Host，真实动画自然完成；所有测试入口在副本外。

- 主成功运行：279 checks、0 failures、37 原始截图；PID28620 自然 exit0，约 26.2 秒，stderr0。
- 动作中快速重置补充：34 checks、0 failures、6 原始截图；PID24660 自然 exit0，stderr0。
- 共 43 原始截图，哈希与尺寸核验一致。已查看原问题的完整 Goal/R/再Goal 图片，以及 Shift/Camera、八例取消和连续 Reset 的四张对照页。
- 首次 QA 入口存在类型推断 Parse Error，PID34424 自然 exit1，未执行 Gameplay/未截取游戏图。失败入口和日志原样保留；只修正外部 QA 脚本，另开空 profile 重试，不计为游戏 Bug。

关键图：evidence_v2/GR01_first_goal.png、GR01_R_start.png、GR02_second_goal.png；rapid_evidence/ 下保留两种动作连续 R 后的起点与再次 Goal。每个观察记录保留 StateKey、face/world/Camera、visual transform、scope/generation、Host 身份、UI/HUD、自然事件与输入时刻。

Computer Use 对本轮窗口的一次抓取出现了无关文件对话框遮挡，已排除，未向其发送输入、未保存或上传那张无关窗口图。验收依据为本轮真实 Godot viewport 的渲染截帧和日志，不是该桌面抓取。

## 保护与范围

启动前已确认 05 释放 GUI。测试使用新包独立副本和三份分开的空 profile（失败尝试、成功主运行、补充）；成功运行实际 user_data_dir 验证位于本次隔离根。隔离进度文件 JSON 可解析，payload SHA256 与 checksum 一致。未关闭或修改用户旧进程、存档或旧证据。

新包和副本各 1707 个清单文件（1555 Git source、150 imports、2 UID 文件）运行后仍匹配，原 ZIP 哈希不变。新增仅 harness/ 下 QA 脚本及外部证据。

本轮未发现新的 P0/P1/P2/P3；此计数仅覆盖定向范围，不关闭历史可读性等其它问题。没有合格独立玩家，Human QA 保持 NOT_RUN。未重跑旧五关、完整方向矩阵、其他分辨率、Cold Continue 或完整状态空间。

只允许 00 收纳 delivery/POLISH03_GOAL_RESET_QA.md、POLISH03_GOAL_RESET_QA.json、EVIDENCE_MANIFEST.json；不上传 profile、截图/日志整包或整个 QA 目录。哈希清单列出外部证据，不扩大上传范围。

08 未写 Git 工作树。00 引用工作树从开始的 CLEAN/9bb64bc 推进到 e8d4048，三个 polish_03 JSON 未跟踪文件为并发成果，均未触碰。08 外部交付由 00 接收，不创建未登记分支或宣称已 Push。

Production changes: NONE
Commit / Push: NOT_RUN（外部匿名 QA 交付）
