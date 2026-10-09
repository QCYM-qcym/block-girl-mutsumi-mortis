# UI_08_001_RECHECK_COMPLETE

日期：2026-10-09（Asia/Shanghai） · PROJECT：Mutsumi Veilshift · TRACK：08 QA & Build · MODE：FOCUSED BLACK-BOX RECHECK

Bug：**UI-08-001 = CLOSED**  
L-02 Pause：**PASS**  
BLACK_BOX_3D_UI_QA_01：**COMPLETE（本轮授权的补测范围）**  
Production changes：**NONE**

**独立测试结论**

在实际集成包中进入 L-02《两岸之间》，暂停入口“暂停 Esc”在深色关卡背景上清晰可读。鼠标能打开暂停菜单、选择设置和继续，Esc 可以恢复。1920×1080 在实际移动后核对位置保持；960×720 在移动并转到 EAST 后核对位置、视角和世界状态保持。原复现场景通过，不需要升级 P1。此结论来自本轮 Computer Use 的实际操作及截图，没有使用 07 Owner checks 或 00 自动化结果替代 Human QA。

**测试包与边界**

- Build：[visual_ui08001_20261009_01](E:/godot/beta-sprint-builds/visual_ui08001_20261009_01/project/project.godot)
- ZIP：[visual_ui08001_20261009_01.zip](E:/godot/beta-sprint-builds/visual_ui08001_20261009_01.zip)
- ZIP SHA256：40afc81b0c5d5574b1bd688d6048ece4c1537da94905af30e32eca92b5456cb1
- 打包源码快照：ca6b331dc7c819c2a01e23c49827c0bd6a9c43a3；00 最终整合回执：dc0bd64b53a9ee3c0c12d4bd7f25ab1ab92df916；07 修复：81d9470c174bd67a73e7e8fedf4b92240ddfc2fd。
- 引擎：Godot 4.7.2.stable.steam.ed1daf0bf；D3D12 12_0 Forward+；NVIDIA GeForce RTX 5060 Ti。
- 真实鼠标/键盘及截图：Computer Use @oai/sky。本轮无窗口激活失败，无外部 GUI 自动化。
- 尺寸控制仅使用生产项目外的 Godot 测试入口，加载正式 main scene，再由 Godot 窗口 API 设置尺寸。未修改生产 UI、系统显示分辨率或冻结 Art Direction。

**三尺寸实测矩阵**

| 目标 | 实际客户区 | 实际 viewport / render | 实际外框 | 截图像素（含装饰） | Interaction |
|---|---|---|---|---|---|
| 1920×1080 | 1920×1080 | 1920×1080 / 1920×1080 | 1938×1127 | 1538×895 | PASS，保留既有 P2 |
| 1280×720 | 1280×720 | 1280×720 / 1280×720 | 1298×767 | 1026×607 | PASS，保留既有 P2 |
| 960×720 | 960×720 | 960×720 / 960×720 | 978×767 | 770×607 | PASS，保留既有 P2 |

每个尺寸先读取 DisplayServer.window_get_size()、root.get_visible_rect() 与 root.get_texture().get_size()，再记录交互。截图尺寸与原生客户区不同，不能用截图分辨率代替客户区。50 条截图关联记录的客户区、viewport、render 均与当时目标一致；没有只依据配置值判 PASS。

| 检查 | 1920×1080 | 1280×720 | 960×720 |
|---|---|---|---|
| Navigation | 鼠标主菜单→选关→L-02 | 暂停→主菜单，键盘焦点/Enter 选关，鼠标进 L-02 | 暂停→主菜单，鼠标选关，Down/Enter 进 L-02 |
| Pause | 鼠标打开、Esc 恢复、鼠标继续，移动状态保持 | 鼠标打开、Esc 恢复 | 鼠标打开、Esc/鼠标恢复，位置及 EAST 保持 |
| Settings | 键盘打开，Left 调整，鼠标 Cancel | 鼠标打开，Tab/Left 调整，鼠标 Apply | 鼠标打开，Tab/Shift+Tab、End，鼠标 Apply |
| Hint | L-02 顶部文字、底部键位可读 | L-02 顶部文字、底部键位可读 | 顶部文字可读，Space 后世界标签/提示更新 |
| Focus | Pause 按钮与 Settings 滑条可见 | Main/Select、Settings 焦点可见 | Select、Settings 正/反向焦点可见 |
| Button accessibility | 关键按钮可点击/键盘选择 | 关键按钮可点击/键盘选择 | 关键按钮可点击/键盘选择 |
| Text overflow / Clipping | 核心文字及按钮通过；板底辅助文字贴边保留 | 核心文字及按钮通过；板底辅助文字贴边保留 | 核心文字及按钮通过；板底辅助文字重叠保留 |

Settings 的 Cancel 在 1280 打开后显示恢复的 master 55%；Apply 实际生效。测试结束前将 music 用 End 恢复 100%，最终独立 QA 存档 settings 为 master 0.55、music 1、sfx 1、muted false、fullscreen false。未测试全屏切换，不宣称此项通过。

**UI-08-001 复现与对照截图**

- 1920 移动后→鼠标暂停→Esc 恢复：[004 l02_before_pause_move](E:/godot/beta-sprint-builds/ui_08_001_recheck_20261009_01/screenshots/004_1920x1080_l02_before_pause_move_0.png)；[005 l02_pause_mouse_visible_label](E:/godot/beta-sprint-builds/ui_08_001_recheck_20261009_01/screenshots/005_1920x1080_l02_pause_mouse_visible_label_0.png)；[006 l02_esc_resume_state_preserved](E:/godot/beta-sprint-builds/ui_08_001_recheck_20261009_01/screenshots/006_1920x1080_l02_esc_resume_state_preserved_0.png)。
- 1920 Settings 键盘打开/Cancel：[010 settings_1920_keyboard_open](E:/godot/beta-sprint-builds/ui_08_001_recheck_20261009_01/screenshots/010_1920x1080_settings_1920_keyboard_open_0.png)；[012 settings_1920_mouse_cancel](E:/godot/beta-sprint-builds/ui_08_001_recheck_20261009_01/screenshots/012_1920x1080_settings_1920_mouse_cancel_0.png)。
- 1280 实际尺寸/Settings/Hint：[015 l02_1280_size_measured](E:/godot/beta-sprint-builds/ui_08_001_recheck_20261009_01/screenshots/015_1280x720_l02_1280_size_measured_0.png)；[017 settings_1280_mouse_open](E:/godot/beta-sprint-builds/ui_08_001_recheck_20261009_01/screenshots/017_1280x720_settings_1280_mouse_open_0.png)；[022 hint_1280_reset_visible](E:/godot/beta-sprint-builds/ui_08_001_recheck_20261009_01/screenshots/022_1280x720_hint_1280_reset_visible_0.png)。
- 960 实际尺寸→移动/EAST→暂停→Esc 恢复：[029 l02_960_size_measured](E:/godot/beta-sprint-builds/ui_08_001_recheck_20261009_01/screenshots/029_960x720_l02_960_size_measured_0.png)；[031 l02_960_pre_pause_camera](E:/godot/beta-sprint-builds/ui_08_001_recheck_20261009_01/screenshots/031_960x720_l02_960_pre_pause_camera_0.png)；[032 pause_960_mouse_entry](E:/godot/beta-sprint-builds/ui_08_001_recheck_20261009_01/screenshots/032_960x720_pause_960_mouse_entry_0.png)；[033 pause_960_esc_resume_same_state](E:/godot/beta-sprint-builds/ui_08_001_recheck_20261009_01/screenshots/033_960x720_pause_960_esc_resume_same_state_0.png)。
- 960 Settings 焦点/Apply 与 Hint 世界切换：[038 settings_960_music_max_keyboard](E:/godot/beta-sprint-builds/ui_08_001_recheck_20261009_01/screenshots/038_960x720_settings_960_music_max_keyboard_0.png)；[039 settings_960_reverse_focus](E:/godot/beta-sprint-builds/ui_08_001_recheck_20261009_01/screenshots/039_960x720_settings_960_reverse_focus_0.png)；[040 settings_960_apply_restore](E:/godot/beta-sprint-builds/ui_08_001_recheck_20261009_01/screenshots/040_960x720_settings_960_apply_restore_0.png)；[043 hint_960_world_label_update](E:/godot/beta-sprint-builds/ui_08_001_recheck_20261009_01/screenshots/043_960x720_hint_960_world_label_update_0.png)。
- 960 选关焦点及实际键盘进入 L-02：[047 navigation_960_focus_l02](E:/godot/beta-sprint-builds/ui_08_001_recheck_20261009_01/screenshots/047_960x720_navigation_960_focus_l02_0.png)；[048 navigation_960_keyboard_enter_l02](E:/godot/beta-sprint-builds/ui_08_001_recheck_20261009_01/screenshots/048_960x720_navigation_960_keyboard_enter_l02_0.png)。
- 正常退出前的真实主菜单：[050 final_main_before_quit](E:/godot/beta-sprint-builds/ui_08_001_recheck_20261009_01/screenshots/050_960x720_final_main_before_quit_0.png)。之后实际点击“退出游戏”，窗口列表不再有游戏窗口，PID 48204 已结束。

**问题统计与残留**

P0：0  
P1：0  
P2：1（既有未关闭问题；本轮新增 0）

保留 VIS01-P2-001 / UI-08-K01，Owner：07 Game Shell。Pause 板底辅助文字贴底，960×720 与关卡底部操作说明重叠；继续、设置、返回等关键按钮仍可操作。归并到原问题，不重复报新 Bug。UI-08-001 已关闭，不计入开放 P2。

L-02 仍是灰盒/像素关卡，记录 PIXEL_BASELINE_PRESENT；其表现属于本包已知范围，不将其再次报成未知 3D Bug。本轮没有新增 PLAYER_CONFUSION；没有进行新的解法或捷径验证。

**回归边界与证据完整性**

L-01 3D 完整通关、L-02 解锁、Cold Continue 的历史 PASS 保持，未重新执行。原 PARTIAL 记录继续作为历史证据保留：[正式 PARTIAL 回执](E:/godot/若叶睦/方块少女-若叶睦/docs/beta-sprint/visual-integration-01/BLACK_BOX_3D_UI_QA_01_PARTIAL_RECEIPT_2026-10-09.md)。本轮仅补齐当前授权的三尺寸 Navigation/Pause/Settings/Hint/Focus/文字/裁切/可操作性矩阵。Level Complete 页三尺寸、Reset 激活、L-03 完整试玩未新增测试，未补写 PASS。COMPLETE 表示本轮覆盖完成，既有 P2 仍需修复。

独立 QA profile 从此前实际解锁的 clean_profile 存档复制，未制造新的解锁状态。原来源存档字节哈希保持；本轮 profile 的 recent 正常更新为 L-02，completed/unlocked 保持原值。没有将新的冷重启测试冒充历史 Cold Continue。

1148 个生产项目文件（排除引擎生成 .godot 缓存）前后 SHA256 相同，新增/删除/修改均 0。MAIN HEAD 保持 13177bb713c229fd5691c1e53cf5ba4d45f2ff76，原 77 个未跟踪 Art Direction 文件哈希不变。stderr 为空，stdout 仅引擎/设备信息。QA 进程通过实际菜单退出，无遗留测试窗口。

所有本轮报告、尺寸入口、测量日志、截图均在生产项目外：

- [截图目录](E:/godot/beta-sprint-builds/ui_08_001_recheck_20261009_01/screenshots)
- [完整结构化报告及 50 张截图索引](E:/godot/beta-sprint-builds/ui_08_001_recheck_20261009_01/UI_08_001_RECHECK_COMPLETE.json)
- [原始交互记录](E:/godot/beta-sprint-builds/ui_08_001_recheck_20261009_01/interaction_log.jsonl)
- [尺寸测量历史](E:/godot/beta-sprint-builds/ui_08_001_recheck_20261009_01/geometry_history.jsonl)
- [最终核验](E:/godot/beta-sprint-builds/ui_08_001_recheck_20261009_01/verification_audit.json)
- [测试专用 Godot 入口](E:/godot/beta-sprint-builds/ui_08_001_recheck_20261009_01/window_matrix.gd)
- [退出后窗口列表](E:/godot/beta-sprint-builds/ui_08_001_recheck_20261009_01/quit_windows.json)
