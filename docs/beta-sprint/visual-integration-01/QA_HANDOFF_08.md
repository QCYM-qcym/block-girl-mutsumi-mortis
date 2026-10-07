# BLACK_BOX_3D_UI_QA_01

状态：PENDING_MAIN_PROJECT_ACCEPTANCE。正式验收和Daily Build完成后由00填写真实版本/路径并标记READY；Human QA尚未执行。本交接不包含解法或内部状态修改步骤。

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

边界：实际L01沿现有P01 Content/GridMovement，不是Foundation RuntimeSession迁移；Parity是P01观察哈希。Pixel保留回归。STAIR_CLEARANCE=PARTIAL_PASS，STAIR_TRAVERSAL=NOT_RUN；楼梯、载客/旋转平台、死亡、任意PuzzleStateSave不纳入本轮。
