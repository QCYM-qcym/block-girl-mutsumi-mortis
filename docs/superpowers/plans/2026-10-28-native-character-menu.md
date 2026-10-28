# Native Character Menu Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [x]`) syntax for tracking.

**Goal:** 接入用户已批准的 V4 放大方块少女动态菜单和表里配色，保留正式流程及存档。

**Architecture:** 新的表现类继承现有 Shell View，复用其动作/关卡目录/焦点合同；设置继续用原有 GameFeel UI 的事务路径。角色背景是原生 SubViewport 的纯展示，正式世界整数只读传递到 UI。

**Tech Stack:** Godot 4.7.2，Control/Theme/SubViewport/Tween，现有批准 GLB 与 Noto 字体；浏览器 Three.js 不进入产品。

**Spec:** `docs/superpowers/specs/2026-10-28-ui-motion-character-showcase-v4-design.md`；用户本轮已明确批准 V4 角色大小、小动作和配色并要求 Godot 接入。

## Global Constraints

- Foundation/Runtime/SaveStore/关卡谜题/冻结美术母版/旧 Build 与证据不得修改。
- 现有隔离工作树 `E:/godot/worktrees/bg-formal01`，分支 `feat/spatial-formal-chapter-01`，基线 `8f849a4b2eb8cdfc43ba89c4fcd84e9d9a63f8a0`；不重复创建工作树。
- Owner 并发但文件独占；00 最后只正常 Push 此开发分支并独立核验远端，不动 main/Release Tag。
- 设置仍由既有 SaveStore/AudioDirector 负责；所有按钮沿用既有 action id，失败、取消、暂停恢复合同不变。
- 模型没有骨骼/表情动画，只作小幅整体转身/接地侧倾；减少动态关闭循环运动；游玩时关闭菜单背景渲染。
- 表里配色消费整数权威世界快照，不解析文字或 Space 输入；Reset/入关/暂停均重新同步。

## Review Focus

- 进入游玩/离开菜单后展示动画不得继续耗渲染或接收输入；Task 1 测试可见/active/静止。
- 设置预览、失败重试与取消仍恢复音频和辅助选项；Task 3 沿用现有事务测试。
- 旧回调/旧关卡不得让暂停或菜单恢复错误配色；Task 4 真实 Shift/Reset/离关测试。
- 无 Continue/只读存档/锁定关卡仍正确禁用；Task 2 保留实际目录和 focus 合同。
- 960×720 与长错误文本不能挡脸、截断或挤出应用/取消；Task 3/4 图形检查。

### Task 1: Native character backdrop（独立 Owner A）

**Files:** Create `game/shell/visual_02/character_backdrop.gd`; Test `tests/beta_sprint/ui_motion_native/test_backdrop.gd`。
**Interfaces:** extends SubViewportContainer; `set_world_layer(layer:int)`, `set_reduced_motion(value:bool)`, `set_active(value:bool)`, `request_motion(kind:String)`, `debug_state()->Dictionary`。角色仅载入批准 GLB 的视觉节点，无物理体或 Runtime 引用。

- [x] 测试先验证背景类缺失/行为未实现为 RED；不以复制正弦公式作断言。
- [x] 实现 Surface/Inner 两模型、接地小动作、低反射地面与影子；按窗口适配模型完整轮廓。
- [x] 验证两世界身份、减少动态时姿态不变、active=false 停止处理/渲染、反复切换/销毁；记录 headless 与真实渲染范围区别。

### Task 2: Palette、菜单和已有流程合同（00）

**Files:** Create `game/shell/visual_02/palette.gd`, `menu_row.gd`, `menu_view.gd`; Modify `game/shell/game_shell.gd` 的 View preload only。
**Interfaces:** Palette `colors(layer:int,contrast:bool=false)->Dictionary`, `panel(colors:Dictionary)->StyleBoxFlat`, `white_icon(texture:Texture2D)->Texture2D`; MenuRow extends existing MotionRow, `set_palette(value:Dictionary)`；MenuView extends ApprovedView，增加 `set_world_layer`, `set_accessibility`, `set_settings_overlay`，保留所有既有 View 公共接口与 IDs。

- [x] 使用实际 Shell 的无存档/锁定关卡/确认新游戏测试，新增对背景初始隐藏和界面 palette 的 RED 检查。
- [x] 同一 Controller 接入新表现类；主菜单头像居中右、左侧真实按钮，选择关卡为滚动侧栏；Pause/Complete 保留正式玩法画面。
- [x] 确认按钮/焦点和消息链仍工作，不改正式 Save 或进度判定。

### Task 3: Settings native drawer（独立 Owner B）

**Files:** Modify `game/feel/ui/game_feel_ui.gd`, `game/shell/visual_01/stone_check.gd`, `stone_slider.gd`; Test `tests/beta_sprint/ui_motion_native/test_settings.gd`。
**Interfaces:** UI `set_presentation(world_layer:int,contrast:bool=false)`；Check/Slider `set_palette(value:Dictionary)`。复用 Task 2 Palette/MenuRow，不修改设置函数的事务语义。保留 settings_scroll→fields 与 settings_panel→margin→column 的 Host 访问关系。

- [x] 新 palette API 和抽屉边界检查为 RED；现有设置事务作为回归依据。
- [x] 设置抽屉左侧 clamp(width×0.30,330,440)，底部保留 88 像素工具区域；标题/字段滚动，应用取消固定且可聚焦。使用原生 Theme 和继承控件，不另造状态或存档。
- [x] 世界色切换所有文本/轨道/勾选/焦点；减少动态沿用真实设置入口；长错误可换行，应用取消不被挤出。

### Task 4: Shared wiring、正式验证和交付（00）

**Files:** Modify `game/shell/game_feel_host.gd`; add read-only `get_presentation_world()->int` to `game/levels/mutsumi/p01_another_world.gd` and `game/levels/mutsumi/spatial_chapter/spatial_level.gd`; Create `tests/beta_sprint/ui_motion_native/test_integration.gd` and focused native graphical runner; evidence/docs under `docs/beta-sprint/ui-motion-native-01/`。

- [x] 核验 baseline catalog/settings，写 Shift/Reset/菜单展示与设置失败路径 RED 集成用例。
- [x] Host 只读同步世界和辅助选项到 View/UI；Menu 自选世界只是展示，不触发 World Shift；真实关卡优先。
- [x] 执行 backdrop/settings/integration 和现有 catalog/settings/landing focused 回归；真实图形 1920×1080、1280×720、960×720，隔离配置/存档与独立进程，不操作用户原游戏。
- [x] 全分支独立审阅，修正实际问题；记录通过范围、未运行项与已知 P2，不扩大 Human QA。
- [ ] Commit，使用现有打包流程生成新的独立 source-playable Build，验证复制身份和实际启动；不覆盖旧包。
- [ ] 正常 Push 此开发分支并 `ls-remote` 核验；报告新包路径、真实 Commit、检查结果、CLEAN。
