# Roof 四向实际对照：提案交付

任务 `SPATIAL_PUZZLE_BATCH_01_POLISH_AND_ACCEPTANCE_03`；Owner 05；2026-10-13。

**32 张实际 Godot Viewport 原帧已完成，261 项图形收集及不变性断言通过。正式美术仍是 PROPOSAL_ONLY，未选定方案、未接入生产；Human QA NOT_RUN。** 本轮只覆盖 Surface/source 静止状态，额外覆盖要求如 gate、Shift、Reset 仍 PENDING。Input P1 保持 CLOSED。

## 固定产物与来源

- 外部目录：`E:/godot/beta-sprint-builds/QA/art_preview_polish03/run_20261013T143919247369Z`。
- [交互原帧索引](E:/godot/beta-sprint-builds/QA/art_preview_polish03/run_20261013T143919247369Z/REVIEW.html)：版本、Q0–Q3、960/1280 窗口切换；默认原生像素，窗口不足时滚动。
- [完整图形收据](E:/godot/beta-sprint-builds/QA/art_preview_polish03/run_20261013T143919247369Z/captures/report.json)、[进程/源文件收据](E:/godot/beta-sprint-builds/QA/art_preview_polish03/run_20261013T143919247369Z/process.json)、[离线校验](E:/godot/beta-sprint-builds/QA/art_preview_polish03/run_20261013T143919247369Z/REVIEW_EVIDENCE.json)。仓库保存 [启动结果](RUN_20261013T143919247369Z.json) 和 [32 图索引](CAPTURE_INDEX.json)。
- 任务基线 `e4fe5365334e93138dc9b8856d09670478789abc`。复制的固定 Build 为 `beta_spatial_acceptance_input_fix_20261013_01`，Source `0bb0e01742eacf12272956111cd6b86fdc74f819`；生产目录与基线 Git diff 为空，不用不同来源的历史截图混入本轮。
- Godot `4.7.2-stable (steam)`、Windows DisplayServer、Forward+ / D3D12、RTX 5060 Ti。音频 Dummy，非音效验收。未启动编辑器、未改正式 project.godot。
- GUI PID 24004 已于 14:39:37 UTC / 22:39:37 +08 自然退出，GUI 时段释放；详见 [释放记录](GUI_SLOT_RELEASED.md)。

## 实际方法与保护范围

启动器核验原 Build 1641 个 manifest 文件后，复制到新的 project/，另设 APPDATA/LOCALAPPDATA/TEMP/TMP 和用户存档目录。向副本添加本轮预览脚本与两个 shader，实例化未改写的正式 Menu/Host/Runtime，通过 Menu.start_lab 加载地图，再调用正式 CAMERA 动作并等待自然完成。没有模拟 OS 键盘输入，因此不把这些截图称为新的输入 QA。

所有版本均使用该实验 Host 的历史六色数字调试角色，**不是 Wakaba v13 正式角色或 Face Lock 美术验收**。本轮不借 roof 对照替换角色。相机保持现有四向正交投影，camera.size=10、KEEP_HEIGHT；没有自由相机重构图。

只对 roof.material_override 做 A/B 替换；C 保留原版材质，添加独立说明框。每版均有明确实验标识，O/A/B/C 没有叠加。运行结束后恢复原材质并正常退回菜单释放节点。

每个相机/尺寸组内，四版本完整 Runtime state 与完整 level 字典相等；因此 walkable、occludes_light、合法区域等正式数据未被视觉改变。StateKey 包含 `level_hash=7a636b38301dff74027b2d5e80364d30b943b24f961cd73a2179b9ee7798acd4`，`rule_version=foundation.rules.spatial_puzzle.v1`，player=`SURFACE/source/TOP`、orientation=0。跨相机 camera_quadrant 按正式动作改变，**不声称跨相机 StateKey 相同**。

几何检查覆盖 geometry_root 直接子节点中的五个 MeshInstance3D：gate、goal、inner_gate、roof、source，比较 mesh RID、顶点摘要、AABB、transform、visible、cast_shadow。顶点摘要为 PackedVector3Array 字节转 hex 文本后的 SHA256。没有递归断言 actor/LocalFaceMarks/ActionMarkers 的全部网格；这些生产源未修改，原帧保留供观察。两 shader 无位移、透明、discard、发光或逻辑判断。B 的内收是实体表面画法，没有几何凹槽。

结束后原 Build 清单 1641 项、副本生产清单 1640 项再次核验，无漂移；不将此扩大为所有磁盘文件不变。旧外部美术包及备份的另行限定核验见三文件报告。

## 观察结论：不等于玩家理解通过

32 张原帧已逐张打开查看。A/B/C 的 24 张在两个尺寸、四个视角均检查；O 的 8 张作为原样对照。

| 版本 | 原帧可见结果 | 仍需判断的风险 |
|---|---|---|
| ORIGINAL | 灰蓝完整方块，Q3 两侧很暗，顶面仍可见；现有转换点文字/角色关系未改。 | 玩家此前误读不能靠原样图宣告解决。 |
| A 不透明粗纹 | 大尺度弯斜条纹在顶面和四个视角的可见侧面出现；Q1 明亮，Q0/Q2/Q3 的暗侧线条较弱。条纹没有做成真实台阶。 | 可能像矿纹、缠绕纹或攀爬表面；面交界处方向有转折，未证明连续运动中无跳纹。保留为优先讨论候选，不选为赢家。 |
| B 内收边框 | 顶面封闭边框和短划、侧面相同结构在四向可见；Q3 暗侧较弱。 | 看起来更像箱体、压力板或锁的面板，邀请交互的误读风险较高。用户/09 审查 PENDING，不能只因醒目判通过。 |
| C 用途说明 | 原材质 + “上方灰蓝色方块：遮光体 / 不可站立；它会遮挡光线。/ 切换位置仍以‘转换点’为准。”。四向两尺寸均未遮住角色、roof、道路或 Gate 字样；框位于右上，未落在 roof–gate 间隙。 | 明示说明，属于辅助解释；未接 H 键，未验证按需触发与目标指认，不是盲测。不能推出“有阴影必能切换”。 |

A/B 在 y≥150 区域相对原版的像素差异包围框都是 101×122 px，只落在 roof 的渲染位置。该数值是材质影响像素范围，不是网格轮廓的精确测量或最低识别阈值。C 说明框固定于 x=width−388、y=166，字体19px。

**960×720 与 1280×720 保持相同高度。KEEP_HEIGHT 导致物体像素大小基本一致，主要验证窄屏布局，没有验证更小的机关占屏像素。** 不用截图缩放代替原生小尺寸测试。HTML 默认不缩图；浏览器缩放、系统 DPI 仍需审阅者留意。

原版 Gate 浮动文案在 Q0/Q3 与调试角色上半部分投影接近/交叠，这在四个版本中均保留。本轮不修 UI，不把原有问题归因于候选材质。

## 与 09 标准的覆盖对应

参考 09 `bf9187a5a91ab7713d3fa6733e5f780716520c27`，`docs/beta-sprint/spatial-puzzle-batch-01/map/polish_03/ROOF_COMPARISON_ACCEPTANCE.md`。未为标准另开场景或大矩阵。

| 项目 | NORTH Q0 | EAST Q1 | SOUTH Q2 | WEST Q3 |
|---|---|---|---|---|
| O/A/B/C source 原生1280与960全画面捕获 | CAPTURED | CAPTURED | CAPTURED | CAPTURED |
| 相同q/尺寸内state、level、五方块几何、相机不变 | PASS | PASS | PASS | PASS |
| A/B纹样可见；C说明布局离线观察 | OBSERVED | OBSERVED | OBSERVED | OBSERVED |
| gate站位的完整对照 | PENDING | PENDING | PENDING | PENDING |
| 动态旋转过程浮纹/跳属审阅 | NOT_RUN | NOT_RUN | NOT_RUN | NOT_RUN |
| 玩家判定不可走、理解遮光、无机关误读 | NOT_RUN | NOT_RUN | NOT_RUN | NOT_RUN |

本轮 CAMERA 动画自然完成，但只保存稳定帧；中间帧没有作为动态视觉验收。MOVE 0 → SHIFT_WORLD → MOVE 3、Inner 返回、Reset、非Gate/非法边缘拒绝并未在候选下重跑，保持 **PENDING**；旧正式动作域证据只引用当前基线 continuation_02/FINAL_REPORT.md，不增加本轮 checks。H 前后、灰度/色弱、正式角色同屏为 NOT_RUN。合格新玩家未参与，Human QA=NOT_RUN。

## 失败记录、独立复核与交接

首次运行 `run_20261013T143455138516Z` 失败，0 图。正式 Host 在 CAMERA committed 时重建 geometry，旧 roof 引用失效；隔离脚本修为每次 camera 稳定后重新获取节点及当组几何基准。180 秒超时只终止本人 PID34384，失败目录和日志保留；没有修正式 Host。随后成功运行 exit0、261 checks、0 failures、32图、stderr0。未把失败改写为 PASS。

独立只读审查者复核32 PNG摘要、当前/副本3脚本摘要、8组StateKey/几何/相机参数、PID和日志一致，未发现本成功预览范围内阻断问题；其关于几何与manifest覆盖边界的意见已纳入本报告。

离线索引首次系统 Python 缺 Pillow，未生成输出；切换已配套的 bundled Python 后生成成功。索引只读取原PNG，没有重画、裁切或替换实机图。

给00/09的下一步：读取固定原帧和收据，按现有标准做只读语义审阅；用户可选A、B、C、保持原样或要求调整。正式接入及额外GUI测试由00按批准方向安排，本轮停止视觉修改。C事故恢复仍须按文件明确授权；详见 [三文件报告](THREE_EXPORTS_REVIEW.md)。

`PREVIEW_CAPTURE=PASS`；`ART_CHANGE=PROPOSAL_ONLY`；`ART_ACCEPTANCE=PENDING_USER_REVIEW`；`HUMAN_QA=NOT_RUN`；`INTEGRATION=PENDING_00`；`EXTERNAL_SCOPE_RECOVERY=PARTIAL`。
