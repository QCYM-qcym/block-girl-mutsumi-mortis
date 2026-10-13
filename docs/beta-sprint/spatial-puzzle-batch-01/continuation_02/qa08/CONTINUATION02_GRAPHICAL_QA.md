# SPATIAL_PUZZLE_ACCEPTANCE_CONTINUATION_02 — 08 Graphical QA

2026-10-13 · 定向自动图形复测已完成；整体玩家验收仍 PARTIAL。

**SPATIAL-CARDINAL-01：图形复测 PASS，向 00 申请技术关闭。** 本报告不代替 00 的问题状态更新。Human QA / 首次理解 / OS 物理键盘均 NOT_RUN。

Build: beta_spatial_acceptance_input_fix_20261013_01
Source: 0bb0e01742eacf12272956111cd6b86fdc74f819
ZIP SHA256: 28bdef16329f8404c7e71851136fb09baa98c36066b5af8bc49f264f43b81285
任务基线: 295a4702aeb17d6fced11cfdaa221e0ffa90dd12
本地证据根: E:/godot/beta-sprint-builds/spatial_continuation02_08_20261013T135945Z

## 实际验证

Windows / Godot 4.7.2-stable (steam)，D3D12 Forward+，RTX 5060 Ti，实际渲染图像和 viewport 均 1280×720。Input.parse_input_event 通过正式菜单及 Host 输入链；位置准备只请求正式动作，等待真实 Presenter/Tween 完成。没有直接改 State、没有手工 finish、没有 doubles。Computer Use 另独立观察了本轮唯一命名窗口的真实 Inner/NORTH 画面，未向旧窗口发输入。

- Gate：Surface 起点/转换点、Inner 转换点/Goal 四位置 × 四 Camera × WASD，64 次独立动作。16 次合法 Roll，48 次正常边缘拒绝；每组四个 axis 均不同。北/东亦能走合法边，拒绝不改 StateKey。角色落定 transform 均与正式投影一致。
- 每次按键均记录 camera、input、face、action/result、前后 StateKey/pose，以及 before/motion/after 截图。16 张四按键对照页均由 08 查看，包括北/东 32 次动作的 96 张原始截图；图中翻滚、边缘前倾及归位与日志一致。
- Space 的合法 Shift、Q/E 中使用 E 循环切换四视角且不改角色姿态；Esc Pause/Resume、正式菜单进入/返回通过。Q 单独按键未测。
- Face Lock 错面保持 idle、正确面 latched，截图从“面4朝下”变为“已激活”；Reset 清 latch。此项通过正式已知动作到位，是技术条件回归，不是盲玩。
- Fork：北/西拒绝码 2101、StateKey 不变；东/南自然落到 target_a/target_b。落地后 D 能正常 Roll 到 Goal。
- 在实际 FALL phase 中 R 中断，等待旧动画时长后仍为起点且 IDLE；没有残留动画提交。

主运行 1355 checks / 0 failures，约 109.7 秒；定向补充 23 checks / 0 failures。checks 包含截图尺寸、自然完成及状态断言，不代表 1378 个不同玩法场景。两次进程自然 exit=0。共 224 张原始 PNG，尺寸/哈希已核对；16 张裁剪对照页仅便于检查，原始完整图保留。

首轮 GUI exe 启动器未等待进程，原 process.json 的 exit_code=null 原样保留；随后在进程存活时只读取得 handle 并等待自然退出，process_wait.json 确认 exit=0。首轮标准输出重定向为空，另复制实际 godot.log，含引擎/GPU与 1355/0 完成摘要，无 Error/Warning；不能只用空日志断言干净。补充运行 Wait/PassThru exit=0，实际 stdout 有引擎信息、stderr=0。

## 新 P2：R 重置后 Shell 终点文字残留

ID: QA08-C02-UI-RESET-LABEL-01；Owner: 07 Game Shell；OPEN。

复现（本包默认东视角）：正式菜单进入世界转换点，D → Space → S，每步等待落定，到达真实 Goal；按 R。角色正确回到 Surface/source/orientation0，但 ui.goal_seen 仍 true，底部仍为“世界转换点 · 已抵达终点”。再用鼠标点击“重置”，goal_seen=false，标题恢复“世界转换点”。主矩阵发现后，在全新补充 profile 独立复现。

证据：followup/goal_before_reset.png、keyboard_R_reset.png、mouse_reset.png 与 report.json。上方 HUD 与下方标题不一致，可能误导玩家；尚未发现阻断继续游玩，故列 P2。23 项补充检查通过包含复现所需状态和对照，不表示此 UI 缺陷已解决。

本轮新增确认问题：P0=0，P1=0，P2=1，P3=0；仅指本轮定向发现，不覆盖历史问题总数。已知 roof 可读性、生命周期警告及其他历史 P2 没有因此关闭。

## 边界与交付

Human QA / 首次理解 / OS 物理键盘：NOT_RUN。仅自动图形复测支持本次输入 P1 技术关闭申请，不宣称完整五图通过、全状态图无软锁或正式发布通过。1920×1080、960×720、Cold Continue 本轮未测。

原包及新副本各 1641 个清单文件在运行后仍一致；ZIP 不变。外部 harness/ 下 2 个 GDScript 与截图对照 Python 是新增测试文件，哈希见清单；正式项目源码无差异。测试 profile、运行缓存与旧存档均不交 Git。两个本轮进程自然退出，未关闭或控制旧用户进程。

08 未获专属 Git 分支，当前明确任务与 Owner scope 使用外部报告供 00 纳入；未为 Push 制度创建分支或改 00 工作树。开工 00 工作树 CLEAN；收尾只读看到其 HEAD 已推进到 af43e72bc1767880c55641fad19b41d749789935，另有 continuation_02/SOURCE_VERIFICATION.json 未跟踪，属并发工作，未触碰。

仅允许 00 审查后纳入 Git：delivery/CONTINUATION02_GRAPHICAL_QA.md、CONTINUATION02_GRAPHICAL_QA.json、EVIDENCE_MANIFEST.json。manifest 记录外部原始证据相对路径/大小/哈希，不意味着将原始日志、截图或存档整体上传。

Production changes: NONE
Commit / Push: NOT_RUN（08 外部交付，由 00 集成匿名文件）
