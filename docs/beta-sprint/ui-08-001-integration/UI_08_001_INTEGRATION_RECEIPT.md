# UI_08_001_INTEGRATED_READY

日期：2026-10-09。目标分支：integration/foundation-4-authoring，工程E:/godot/worktrees/block-girl-foundation-4-integration。精确fix commit：81d9470c174bd67a73e7e8fedf4b92240ddfc2fd；正常快进merge，cherry-pick0次。Build source / integration candidate commit：ca6b331dc7c819c2a01e23c49827c0bd6a9c43a3。最终receipt提交仅包含交付文档、截图和文件清单，最终40位SHA见00输出/git log；668个正式运行源码与新包一致。

实际差异：1个生产文件game/shell/visual_01/approved_shell_view.gd新增8行，增加批准face颜色底面，与原暂停按钮共位置/尺寸/显隐，MOUSE_FILTER_IGNORE。其余3个fix文件是07定向验收脚本/UID。未合并Owner分支后续56b70f9报告提交；00新增仅focused Harness、计划与证据。本轮没有改变MAIN，MAIN保持13177bb713c229fd5691c1e53cf5ba4d45f2ff76及原77个untrackedUI源文件。

| Focused regression | 实际结果 |
| --- | --- |
| Main Menu | PASS；真实入口、Tab跳过disabledContinue、Enter/鼠标菜单动作及返回 |
| L02 Pause | PASS；原生1920×1080、1280×720、960×720，实际文字像素与12.235962:1对比度 |
| Pause → Resume | PASS；真实鼠标操作，保持同一个L02及原Gameplay/Hint状态 |
| Esc → Resume | PASS；真实引擎按键事件，恢复同一状态，无额外移动 |
| Level Select | PASS；键盘进入、真实鼠标选择已解锁L02、L03保持禁用、Esc返回 |
| Settings | PASS；Pause/Main入口、原焦点顺序、音量preview、Cancel恢复、Apply沿原隔离Save，Gameplay输入不泄漏 |
| Hint presentation | PASS；真实keycap绘制、原text/alpha绑定、Pause冻结、Resume保持，未添加第二套Hint生命周期 |

正式focused evidence：Integration/.godot/ui-08-001/int_focus03。import PID13428；graphical focused PID48452；127 checks、failures=[]、exit0、stderr empty、stdout clean。Windows Forward+ / NVIDIA GeForce RTX5060Ti，Godot4.7.2。使用原Input.parse_input_event触发真实控件与Shell；不是Computer Use/Human验收。原Owner个案在int_focus01中40 PASS仅作补充，不将整轮早期FAIL冒充PASS。早期错误及resize触发原focus-loss Pause的前置问题见VALIDATION_HISTORY.md，所有旧证据保留。

测试使用明确“L02已解锁”的隔离存档fixture，只验证已有交互。实际Goal events0；未重复三关完整通关、解锁或Cold Continue。先前接受的完整流程结论仅保留历史，不在本轮新增PASS。

## 新QA Build

目录：E:/godot/beta-sprint-builds/visual_ui08001_20261009_01。入口play.ps1，项目project/project.godot。SOURCE_PLAYABLE_NOT_EXE，需已有Godot4.7.2。

ZIP：E:/godot/beta-sprint-builds/visual_ui08001_20261009_01.zip。59716624 bytes；SHA256：40afc81b0c5d5574b1bd688d6048ece4c1537da94905af30e32eca92b5456cb1。

1148个复制文件、668个focused源码文件零SHA差异。复制工程import/Main/Foundation/L01/L02/L03 boot均exit0/PASS，只做启动检查、不重放通关路线。此次仅L03限时退出有133bytes既有4 ObjectDB warning，与旧Build同stage逐字节一致；其它五个stage stderr为空，不退回Owner改冻结Core。

旧Build visual_daily_20261007_02完整保留，ZIP SHA256仍为562a824cdea42985077f99677fd3a5bc982676748470d843dafc7992c1b57164；新目录在创建前不存在，不覆盖旧版本。具体source版本、Boot日志、SHA与已知警告在BUILD_VERIFICATION.json。

## 状态与边界

UI-08-001：OPEN / READY_FOR_08_RECHECK。Human QA：NOT_RUN。此receipt不关闭产品问题，不把自动化PASS冒充08 Human PASS，也不声称原WINDOW_ACTIVATION_FAILURE已解决。本轮不自动触发08原生窗口复测。

后续08复核使用新包及已有独立QA档，保留已解锁L02；不要覆盖默认玩家存档或旧Build。按原缩小范围在窗口稳定时复核L02文字、菜单、Pause/Resume、Settings、Hint及三个尺寸；无现成档依赖时只pending该case，不以重新全通关作为本次整合门槛。详情见QA_BUILD_HANDOFF.md。

Foundation changes：NONE。Art / UI Art source changes：NONE。Save / Gameplay / Geometry / Puzzle content changes：NONE。660个受保护文件、77个批准UI源零变化；生产差异仅为精确07 UI修复。Working tree：CLEAN（Integration交付后核验）；Push：NOT_RUN。MAIN预存untracked源文件不清理、不忽略、不擅自纳入。
