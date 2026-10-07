# BLACK_BOX_3D_UI_QA_01

状态：READY_FOR_BLACK_BOX_3D_UI_QA_01。Human QA尚未执行；READY不等于Human PASS。本交接不包含解法或内部状态修改步骤。

实际MAIN正式测试SHA：22dc7281a54250db93f6d70e607fa0a00e206f78。源码Daily Build SHA：8a7d339994f68cf15727bf7dc5b75c36110184b5（只增加打包隐藏文件读取修复与证据，375个正式Runtime/Test/Asset文件与测试SHA完全一致）。Main随后仅更新交付文档；正式receipt见同目录MAIN_PROJECT_VISUAL_INTEGRATION_01_RECEIPT.md，完整文件清单见FILES_SHA256.json。

实际包：E:/godot/beta-sprint-builds/visual_daily_20261007_02，入口play.ps1，项目project/project.godot，ZIP为E:/godot/beta-sprint-builds/visual_daily_20261007_02.zip。SOURCE_PLAYABLE_NOT_EXE，需要已有Godot 4.7.2。ZIP SHA256：562a824cdea42985077f99677fd3a5bc982676748470d843dafc7992c1b57164，84649034 bytes。1206个复制文件和375个正式源码文件均零SHA差异，独立复制工程import/Main/Foundation/L01/L02/L03 boot全PASS。

MAIN UI 2747 PASS（entry7、real seed2727、独立restore13），art_vertical 6113 PASS（entry6、real seed6089、独立restore18），正式进程均exit0、stderr空、failures=[]。证据在实际MAIN .godot/beta-sprint/visual-integration/main_ui01及art-vertical/main_uiart01；此为00自动验收，不代替08盲测。

保护现有玩家档案：盲测使用既有Shell支持的独立参数--shell-save=user://beta_sprint/black_box_3d_ui_qa_01/progress.json，跨进程保持同一路径。不要删除或覆盖默认玩家存档。复制项目初次先import；从该Daily Build启动真实场景，正常退出/重启。

正式项目：E:/godot/若叶睦/方块少女-若叶睦/project.godot，Godot 4.7.2，F5从真实Game Shell启动。Main Menu、Level Select、Pause、Settings、Level Complete、Hint应使用已批准“石拱之间”UI；L01默认为正式3D若叶睦及Surface/Inner。L02/L03仍是原灰盒，不属于本轮3D迁移。

从独立的本轮Daily Build启动。先不看解法，用鼠标和键盘在菜单选择L01，自行完成关卡；至少操作Pause、Settings预览与Cancel/Apply、Resume、Reset、镜头、World Shift、完成回流，再正常退出进程、重启并Continue。Continue应从最近进入关卡的正式起点开始，不声称恢复中途Puzzle快照。

- 冷启动没有进度时，Continue应不可用且原因可读；已有进度时按原Save可用性启用。既有新游戏覆盖确认、禁用关卡、完成/解锁标记保持。
- Tab/Shift+Tab、上下、Enter、Escape与真实鼠标操作应无死路、重复动作或disabled误触；Settings起始焦点为总音量，回Pause后恢复来源设置入口，Resume释放menu焦点。
- 音量即时预览，Music沿原Ambience bus；Mute不把slider归零；Cancel恢复原设置，Apply沿原Save；全屏预览及取消恢复可操作。
- Pause/Complete及从Pause进入Settings保留真实当前viewport、玩家姿态/世界/相机；菜单输入不泄漏进Gameplay，移动中暂停/恢复不多走一步。
- Hint与世界标签跟随实际状态，显示/淡出/Reset/完成沿原生命周期；Hint不获取焦点或遮住核心角色、路径和出口。L03 stale hint内容由06/07另行处理，本轮不修内容。
- 真正玩通L01后显示完成页，保存状态准确，L02解锁，原next/select/reset/main及失败时retry_save可达。不要把完成勾线当作磁盘保存成功。
- 1920×1080、1280×720、960×720三个真实窗口分别记录核心UI有无重叠、裁切、不可操作或关键文字溢出；观察中文、长标题/错误、细线焦点、角色与世界可读性。
- 记录实际硬件/renderer、资源或Shader错误、卡顿及UI透明排序；不能只看截图。当前正式Gameplay只支持键鼠，手柄占位稿不构成控制器支持。

报告包含版本SHA、Daily Build路径、真实场景、输入/分辨率、Steps、Expected、Actual、Screenshot、Gameplay impact与P0/P1/P2。批准Art的真实P0/P1用MAIN_PROJECT_INTEGRATION_REQUEST回交05；P2/P3进入POST_INTEGRATION_POLISH_BACKLOG。不得由QA重做资产或改Foundation/Save/谜题。

已知本轮P2：compact panel的辅助导航footnote稍越板边，人工注入很长错误的末句次要说明跨到深背景；主要动作/错误原因/Retry可用。已有工具警告：复制包L02/L03的--quit-after120单场景boot各有4 ObjectDB exit warning，stderr133bytes，与20261006旧Beta Slice逐字节一致。正常MAIN及本轮L01正式UI/玩法进程stderr为空，不据此重开冻结Core；不要把旧警告记成新UI回归。

边界：实际L01沿现有P01 Content/GridMovement，不是Foundation RuntimeSession迁移；Parity是P01观察哈希。Pixel保留回归。STAIR_CLEARANCE=PARTIAL_PASS，STAIR_TRAVERSAL=NOT_RUN；楼梯、载客/旋转平台、死亡、任意PuzzleStateSave不纳入本轮。
