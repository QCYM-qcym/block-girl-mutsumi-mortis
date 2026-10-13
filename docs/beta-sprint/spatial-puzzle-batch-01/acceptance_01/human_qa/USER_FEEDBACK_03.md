# USER_FEEDBACK_03 — 原话与技术复现分层追加

Human QA: PARTIAL_USER_FEEDBACK
First-time comprehension: NOT_VERIFIED

## 真人原话层

00 于 2026-10-13（Asia/Shanghai）转达用户：

> 北和东不行

08 未直接观察本次操作。结合前条记录保留用户所述 Inner 视角问题，但本句本身不能证明地图、具体按键或测试范围。玩家资格与发生时间未确认；首次发现、预测正确数/总数、乱试、卡点时长、失败理解、提示和完成仍 NOT_OBSERVED。

## 00 技术复现层

证据提交：89ebf7a60e405d7617298e49a3f43e3461e38376
目录：docs/beta-sprint/spatial-puzzle-batch-01/acceptance_01/diagnostics/

08 已只读核对提交及 OWNER_BUG_HANDOFF.md、process.json，未自行重跑。正式保存地图/Baker → spatial Host → Facade.request_move 屏幕方向 → 自然 Presenter/Tween 完成，为 headless 技术复现，不是真人键盘交互通过证据。

- world_shift_gate_lab，Inner 的 gate 与 Goal 位置：NORTH/EAST 下 W/A/S/D 对应的四个输入只映射 face_axis 0/2，四方向均被 2000 拒绝，无 StateKey 变化。
- 对照 SOUTH/WEST 覆盖四方向。共 32 次方向尝试，4 个相机/位置组合没有合法方向。
- 进程 exit=1；8 条 ObjectDB 退出警告按 Owner 证据保留，不能写成无警告运行。
- probe 运行工作树 HEAD=a9ecfb46f1a2d4efd20042586fbc690066cabfaa，human_profile_written=false；不得混称它就是玩家本人的图形会话。

确认问题登记：SPATIAL-CARDINAL-01 / P1。状态 OPEN，01 Runtime 在 fix/spatial-cardinal-input-01 定向修复中，修复后待独立复测。具体数学根因仍在调查；不预判 tie、basis 或 lifecycle 假说为结论。

这是已复现的方向控制功能缺陷，不归为玩家认知失败；尚未证明不可恢复软锁，也不能替代正式状态图 softlock 结论。本追加确认 P1=1；其余级别 NOT_ASSESSED，非整包缺陷总表。

## 会话身份与完成记录层

00 报告只读进程命令行指向本轮隔离 run/project；profile 最近 level_id=world_shift_gate_lab，并有 completed 记录。08 尚未独立核对这些运行时信息。地图关联来自进程/profile，不冒充用户明确确认地图。completed 不能证明操作者资格、无提示或首次独立通关。

头顶方块身份仍未经用户确认。地图存在非 walkable roof 的技术信息不能用于替用户指认目标，也不能据此关闭其到达困难反馈。

## 后续与保护

等待 01 修复和 00 新包，再针对受影响方向执行真实输入复测；不得以修复提交或 Owner 自动结果直接关闭 Human QA。08 本次未启动 GUI、未改 Build、未改存档，未给玩家解法。前两条记录和准备快照保持原样。

00 可审查后复制至 docs/beta-sprint/spatial-puzzle-batch-01/acceptance_01/human_qa/ 的新增匿名文件：

1. USER_FEEDBACK_03.md
2. USER_FEEDBACK_03.json
3. USER_FEEDBACK_03_HASH_MANIFEST.json

不覆盖已有同名文件；不复制存档或整包 QA。清单覆盖两个载荷文件，不自包含。

Production changes: NONE
Push: NOT_RUN
