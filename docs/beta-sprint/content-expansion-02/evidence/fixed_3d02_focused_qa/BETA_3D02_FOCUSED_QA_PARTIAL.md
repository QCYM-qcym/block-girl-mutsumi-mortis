# BETA_3D02_FOCUSED_QA_PARTIAL

2026-10-09 · Mutsumi Veilshift · 08 QA & Build · 独立黑盒实测

**B 三尺寸 UI 矩阵已完成；C 本包 Cold Continue = PASS。整体保持 PARTIAL，唯一待补为 A：L-03 首次理解 = RETEST_PENDING。** 当前测试者已知路线，没有符合条件的首次玩家，未用重玩或 AI 代理替代。A 不阻塞 B/C 或内容开发。

结果仅绑定固定包 [beta_3d02_20261009_01](E:/godot/beta-sprint-builds/beta_3d02_focused_qa_20261009_01/../beta_3d02_20261009_01/project/project.godot)。ZIP SHA256：697070886818f1e437e9fd20444fe98684a60582eeb2b30bcea98bf8ab64c999；runtime source：7a95b28b155f5d32c4b559bdf90e0ea9beaad4ac；delivery：b910167becee2194c0cfc724d8f0fe47578836a9。后续 Daily/Integration 包不能继承本包 PASS。

真实鼠标、键盘和截图来自 Computer Use @oai/sky；没有使用 Owner 测试结果代替独立交互。Godot 4.7.2.stable.steam.ed1daf0bf，D3D12 Forward+，RTX 5060 Ti。本次无窗口激活失败。尺寸由生产项目外的 Godot 测试入口控制并实测，未修改生产 UI、系统显示分辨率或调用外部 GUI 自动化。

**B：实际尺寸与交互**

| 目标 | 实际客户区 | 实际 viewport / render | 实际外框 | 截图像素 | Interaction |
|---|---|---|---|---|---|
| 1920×1080 | 1920×1080 | 1920×1080 / 1920×1080 | 1938×1127 | 1538×895 | PASS，存在非阻塞 P2 |
| 1280×720 | 1280×720 | 1280×720 / 1280×720 | 1298×767 | 1026×607 | PASS，存在非阻塞 P2 |
| 960×720 | 960×720 | 960×720 / 960×720 | 978×767 | 770×607 | PASS，存在非阻塞 P2 |

先测客户区/viewport/render，再操作；截图像素包含装饰并经过工具缩放，不用来替代原生尺寸。65 条截图关联测量与各自目标相符。实测入口分别为 [1920](E:/godot/beta-sprint-builds/beta_3d02_focused_qa_20261009_01/screenshots/001_1920x1080_main_1920_size_verified_0.png)、[1280](E:/godot/beta-sprint-builds/beta_3d02_focused_qa_20261009_01/screenshots/019_1280x720_l03_1280_size_verified_0.png)、[960](E:/godot/beta-sprint-builds/beta_3d02_focused_qa_20261009_01/screenshots/034_960x720_l02_960_size_verified_0.png)。

| 检查 | 1920×1080 | 1280×720 | 960×720 |
|---|---|---|---|
| Navigation | 主菜单→选关→实际 L-02/L-03 | 主菜单/选关→实际 L-02/L-03 | 主菜单/选关→实际 L-03；L-02 是已进入场景缩放 |
| Pause / Resume | 鼠标暂停、鼠标继续、Esc 恢复；Inner 移动状态保持 | 鼠标暂停、鼠标继续、Esc 恢复 | 鼠标暂停、鼠标继续、Esc 恢复 |
| Settings | Master 99% 预览 / Cancel | Tab 到 Music、99%→End 100%、Apply | Tab / Shift+Tab、Master 99% 预览 / Cancel |
| Hint | L-02 移动/World Shift 提示可读；L-03 顶部文字可见 | L-02/L-03 提示可见 | L-02/L-03 提示可见 |
| Focus / Button accessibility | 鼠标与键盘焦点可用 | 鼠标与键盘焦点可用 | 鼠标与正反向键盘焦点可用 |
| Text overflow / Clipping | 核心文字和按钮可用；Pause 辅助文字贴边保留 P2 | 核心文字和按钮可用；Pause 辅助文字贴边保留 P2 | 核心文字和按钮可用；Pause 辅助文字重叠保留 P2 |

代表证据：1920 [9](E:/godot/beta-sprint-builds/beta_3d02_focused_qa_20261009_01/screenshots/009_1920x1080_pause_1920_mouse_entry_0.png)、[10](E:/godot/beta-sprint-builds/beta_3d02_focused_qa_20261009_01/screenshots/010_1920x1080_settings_1920_mouse_open_0.png)、[13](E:/godot/beta-sprint-builds/beta_3d02_focused_qa_20261009_01/screenshots/013_1920x1080_pause_1920_esc_resume_same_state_0.png)、[15](E:/godot/beta-sprint-builds/beta_3d02_focused_qa_20261009_01/screenshots/015_1920x1080_pause_1920_mouse_resume_0.png)、[18](E:/godot/beta-sprint-builds/beta_3d02_focused_qa_20261009_01/screenshots/018_1920x1080_l03_1920_entry_3d_actual_0.png)；1280 [20](E:/godot/beta-sprint-builds/beta_3d02_focused_qa_20261009_01/screenshots/020_1280x720_pause_1280_mouse_entry_0.png)、[21](E:/godot/beta-sprint-builds/beta_3d02_focused_qa_20261009_01/screenshots/021_1280x720_settings_1280_mouse_open_0.png)、[22](E:/godot/beta-sprint-builds/beta_3d02_focused_qa_20261009_01/screenshots/022_1280x720_focus_1280_settings_music_0.png)、[25](E:/godot/beta-sprint-builds/beta_3d02_focused_qa_20261009_01/screenshots/025_1280x720_settings_1280_apply_return_0.png)、[26](E:/godot/beta-sprint-builds/beta_3d02_focused_qa_20261009_01/screenshots/026_1280x720_pause_1280_esc_resume_0.png)、[28](E:/godot/beta-sprint-builds/beta_3d02_focused_qa_20261009_01/screenshots/028_1280x720_pause_1280_mouse_resume_0.png)、[33](E:/godot/beta-sprint-builds/beta_3d02_focused_qa_20261009_01/screenshots/033_1280x720_l02_1280_entry_3d_actual_0.png)、[63](E:/godot/beta-sprint-builds/beta_3d02_focused_qa_20261009_01/screenshots/063_1280x720_l03_1280_entry_after_metadata_check_0.png)；960 [35](E:/godot/beta-sprint-builds/beta_3d02_focused_qa_20261009_01/screenshots/035_960x720_pause_960_mouse_entry_0.png)、[36](E:/godot/beta-sprint-builds/beta_3d02_focused_qa_20261009_01/screenshots/036_960x720_settings_960_mouse_open_0.png)、[37](E:/godot/beta-sprint-builds/beta_3d02_focused_qa_20261009_01/screenshots/037_960x720_focus_960_settings_music_0.png)、[38](E:/godot/beta-sprint-builds/beta_3d02_focused_qa_20261009_01/screenshots/038_960x720_focus_960_settings_master_reverse_0.png)、[40](E:/godot/beta-sprint-builds/beta_3d02_focused_qa_20261009_01/screenshots/040_960x720_settings_960_cancel_0.png)、[41](E:/godot/beta-sprint-builds/beta_3d02_focused_qa_20261009_01/screenshots/041_960x720_pause_960_mouse_resume_0.png)、[43](E:/godot/beta-sprint-builds/beta_3d02_focused_qa_20261009_01/screenshots/043_960x720_pause_960_esc_resume_0.png)、[49](E:/godot/beta-sprint-builds/beta_3d02_focused_qa_20261009_01/screenshots/049_960x720_cold_l03_authored_spawn_before_change_0.png)。

未新增验证：Settings 全屏切换、听觉响度、Level Complete 页三尺寸、完整通关路线。Hint 的可见性 PASS 不关闭既有 L-03 提示语义问题。历史 UI-08-001 暂停文字不可见 CLOSED 证据保持；本包暂停文字和关键控件亦可读可用，未升级 P1。

**C：本包 Cold Continue**

实际进入 L-03 后移动、切到 Inner、转为 EAST，随后暂停→主菜单→鼠标退出。旧 PID 40064 在 2026-10-09T04:46:53.0821838Z 已结束；新 PID 34448 于 2026-10-09T04:47:08.3639970Z 启动，使用同一独立 profile。实际点击 Continue 进入最近关卡 L-03 的 authored spawn：Surface / Mutsumi、NORTH、初始位置与朝向，未恢复退出前的中途状态；继续后的输入有效。

对照：[初始起点](E:/godot/beta-sprint-builds/beta_3d02_focused_qa_20261009_01/screenshots/049_960x720_cold_l03_authored_spawn_before_change_0.png) → [退出前移动后的 Inner/EAST](E:/godot/beta-sprint-builds/beta_3d02_focused_qa_20261009_01/screenshots/052_960x720_cold_l03_midlevel_inner_east_before_quit_0.png) → [新进程主菜单](E:/godot/beta-sprint-builds/beta_3d02_focused_qa_20261009_01/screenshots/055_960x720_cold_new_process_main_continue_available_0.png) → [实际 Continue 返回起点](E:/godot/beta-sprint-builds/beta_3d02_focused_qa_20261009_01/screenshots/056_960x720_cold_continue_actual_l03_authored_spawn_0.png) → [继续后输入响应](E:/godot/beta-sprint-builds/beta_3d02_focused_qa_20261009_01/screenshots/057_960x720_cold_continue_input_responsive_0.png)。

退出前、退出后、Continue 后存档 checksum 均有效，recent=mutsumi_l03，completed/unlocked 保持。三份快照 SHA256 均为 a91046633aafb2ee602b3b73f44c72b8a26408db55b2c3ff63a2a09ba7abe856。[完整冷重启证据](E:/godot/beta-sprint-builds/beta_3d02_focused_qa_20261009_01/cold_continue_evidence.json)保存 distinct PID、旧进程结束/新进程启动时间、同 profile 和存档校验。

**开放问题与 Owner handoff**

- P0：0；P1：0；新增 P2：1；保留 P2：2；开放 P2 合计：3；新增 P3：0。
- 新增 FOCUS-3D02-P2-001，Owner 07 Game Shell（关联 06 菜单内容）：L-02/L-03 选关显示“灰盒试玩 · 尚无正式环境预览”、空预览，与实际 3D 入关不一致。L-02 文案实测于 1920/1280，L-03 文案实测于 1280；960 只确认空预览，caption 未展示，不能宣称在 960 看到了该文字。核心入关可用，维持 P2。
- 保留 VIS01-P2-001 / UI-08-K01，Owner 07：Pause 板底辅助文字贴边，960 与底部操作说明重叠。本轮复现，但关键控件仍可操作；不重复计新 Bug。
- 保留 L03_STALE_HINT_EXISTING，Owner 06：上轮实际跨越后仍显示过期提示。本轮没有重跑完整跨越路线，不关闭，也不冒充新复现。

新 P2 文案证据 [4](E:/godot/beta-sprint-builds/beta_3d02_focused_qa_20261009_01/screenshots/004_1920x1080_select_1920_l02_preview_after_wait_0.png)、[32](E:/godot/beta-sprint-builds/beta_3d02_focused_qa_20261009_01/screenshots/032_1280x720_focus_1280_select_l02_0.png)、[61](E:/godot/beta-sprint-builds/beta_3d02_focused_qa_20261009_01/screenshots/061_1280x720_p2_l02_select_preview_1280_0.png)、[62](E:/godot/beta-sprint-builds/beta_3d02_focused_qa_20261009_01/screenshots/062_1280x720_p2_l03_select_preview_1280_0.png)；实际 3D 对照 [5](E:/godot/beta-sprint-builds/beta_3d02_focused_qa_20261009_01/screenshots/005_1920x1080_l02_1920_entry_3d_actual_0.png)、[33](E:/godot/beta-sprint-builds/beta_3d02_focused_qa_20261009_01/screenshots/033_1280x720_l02_1280_entry_3d_actual_0.png)、[63](E:/godot/beta-sprint-builds/beta_3d02_focused_qa_20261009_01/screenshots/063_1280x720_l03_1280_entry_after_metadata_check_0.png)。[问题登记](E:/godot/beta-sprint-builds/beta_3d02_focused_qa_20261009_01/FOCUS-3D02-P2-001.json)。期待菜单准确表达当前 3D 状态；若只是预览未完成，文案应准确限定为预览。

**回归与完整性**

Production changes：NONE。固定项目 1173 个文件（排除引擎生成 .godot）前后 SHA256 新增/删除/修改均为 0。Art FROZEN；Foundation full DEFERRED。原 L-01 通关、解锁及 Cold Continue PASS 保留；旧 3D02 完整路线的 88 张截图没有重跑。原 3D02 QA 封存的 99 个文件和 UI-08-001 recheck 封存的 60 个文件均未变更。源 profile 字节哈希未变。两个 QA 会话 stderr 均为空。

两个 QA 进程均通过真实菜单正常退出；在 2026-10-09T04:50:16.9601638Z 核实 PID 40064/34448 不运行并写入 [GRAPHICAL_SLOT_RELEASED](E:/godot/beta-sprint-builds/beta_3d02_focused_qa_20261009_01/GRAPHICAL_SLOT_RELEASED.json)。00 已接管图形时段；本报告封存阶段没有重新打开游戏。该时间点的退出证据不表示其他轨道后来未启动进程。

初始离线 PARTIAL 快照单独保留为 [OFFLINE_PREPARATION_PARTIAL_SNAPSHOT.md](E:/godot/beta-sprint-builds/beta_3d02_focused_qa_20261009_01/OFFLINE_PREPARATION_PARTIAL_SNAPSHOT.md)。Release recommendation：CONTINUE_BETA；只对本固定包的本轮覆盖范围成立，A 继续 RETEST_PENDING。

证据索引：[结构化报告 / 65 张截图索引](E:/godot/beta-sprint-builds/beta_3d02_focused_qa_20261009_01/BETA_3D02_FOCUSED_QA_PARTIAL.json)；[实际输入记录](E:/godot/beta-sprint-builds/beta_3d02_focused_qa_20261009_01/actual_input_trace.json)；[截图与测量关联](E:/godot/beta-sprint-builds/beta_3d02_focused_qa_20261009_01/interaction_log.jsonl)；[原生尺寸历史](E:/godot/beta-sprint-builds/beta_3d02_focused_qa_20261009_01/geometry_history.jsonl)；[完整性核验](E:/godot/beta-sprint-builds/beta_3d02_focused_qa_20261009_01/verification_audit.json)；[封存 SHA256 清单](E:/godot/beta-sprint-builds/beta_3d02_focused_qa_20261009_01/evidence_manifest.json)。
