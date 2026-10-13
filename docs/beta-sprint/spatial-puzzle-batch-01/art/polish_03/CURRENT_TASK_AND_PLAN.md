# 当前唯一任务：SPATIAL_PUZZLE_BATCH_01_POLISH_AND_ACCEPTANCE_03

2026-10-13。基线 e4fe5365334e93138dc9b8856d09670478789abc；Owner 05；工作区 E:/godot/worktrees/bg-spatial-art-accept01；分支 test/spatial-art-polish-03。

本文件优先于旧附件、旧生产任务或恢复任务。Input P1 已 CLOSED，不重新打开。

当前授权：B 实际制作隔离视觉预览，原版/A 不透明低频粗纹/B 内收边缘/C 必要用途说明，四固定 Camera 供用户审核；ART_CHANGE=PROPOSAL_ONLY。C 只读核验事故剩余三文件及正式 Build 引用，复用此前清单，不扫整盘、不执行恢复、不运行 build_boards.cjs。

允许写入仅 tests/beta_sprint/spatial_art/polish_03/** 与本目录。图片、独立工程、缓存、日志只写新建的 QA/art_preview_polish03 子目录。保护全部外部原美术包、备份、现有 QA/Build、用户进程与存档。允许本人第一 GUI 时段；完成关闭本人进程后立即记录释放。

## 隔离预览实施计划

> 实施采用 executing-plans 流程；已有明确用户授权 A/B/C 隔离对照，不等待重复批准。正式接入和资源恢复仍未授权。

问题：同一 roof 在不改变实体和规则时，哪种表现更容易与道路区分？只制作供审批候选，不宣布改善比例。

- [x] 从当前基线核验生产来源，建立全新外部工程副本和独立 profile；不改正式 project.godot。
- [x] 在允许测试目录新增预览脚本/两种不透明材质 shader 和单命令启动器；实例化正式 Menu/Host，不复制 Runtime 判断。
- [x] 通过正式 CAMERA 动作切换 Q0–Q3，固定初始 Surface/source 姿态；原版与 A/B/C 均保留 mesh、transform、camera、walkable、occludes_light 和 StateKey。
- [x] 真实 Godot Viewport 捕获 1280×720 与 960×720：4 版本×4 视角×2 尺寸；实际记录状态、尺寸、来源哈希、renderer、PID 和自然退出。
- [x] 检查像素与遮挡，必要时只在独立预览内修正；完成后关闭本人 GUI，记录释放，不终止任何他方进程。
- [x] C 独立只读调查：精确三路径原/现/备份 SHA，结构变化/未知像素边界、正式 Build 引用和按文件恢复提案。
- [x] 验证允许路径、外部源与备份限定清单哈希未变化。Commit/普通Push/独立远端SHA结果以本轮最终答复和外部DELIVERY_RECEIPT.json为准，不预写成功。

计划文件：测试目录内 roof_preview.gd、roof_coarse.gdshader、roof_inset.gdshader、run_preview.py；本目录内预览报告、证据清单、三文件调查与交接。预览不是正式 UI 或资产管线，不发布 GLB/Blender 源，不改地图、InputMap、Runtime、Save、L01–L05 或冻结母版。

关键检查：材质无顶点位移/透明/丢弃；C 说明不落在 roof–gate 间隙、不暗示新可用性；相机从正式动作获得；所有候选使用同一原版角色和位置；图形结果与真人理解分开。失败尝试留存，不覆盖旧证据。
