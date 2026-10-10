# 08 QA handoff — forward then drop to yellow

实际新包：E:/godot/beta-sprint-builds/beta_pfall_forward_drop_20261010_01

Build源身份：5d42600c29760a8082edf2a94754252772352846。集成收据：fe370ad832bb62cd31a6d22909ce1a5bd1fe1311。ZIP SHA-256：01c23e309f4469c0985fa9884e866f84180b15a7c4db819aef281aa66c3766d9。

启动：PowerShell执行 `& "E:/godot/beta-sprint-builds/beta_pfall_forward_drop_20261010_01/play.ps1"`。需要Godot4.7.2；这是真实可运行source package，不是独立EXE。正式菜单右下实验入口进入MAP A/B；A/B按钮切换实验地图。初始EAST视角，A/Left向前触发正式Fall，F也可调用精确作者连接；落黄后D/Right执行原生Roll U_POS到Goal。Q/E Camera，R Reset，Esc Pause/Resume。

重点观察真实起步前倾/位移，中心离开源蓝块支撑边界后坠落，连续前向惯性，无空中蓝块停顿，黄色TOP接触、压缩、回弹、稳定。MAP B正式物理高度增加但在合法视角下呈现下坠；不得把它改成新规则。检查Normal/Reduced、Reset、长按、非法Camera、Landing后输入和Goal。

量化10/10专项、03独立2761、00源524和包本体430均PASS；mode1正式图形重放每条2步骤，四条共8匹配。实际六阶段图像：E:/godot/worktrees/block-girl-foundation-4-integration/docs/beta-sprint/game-feel/forward-drop-01/evidence/package_natural01。

本包Human Feel/Human QA为NOT_RUN，请用本包新qa-profile和独立新报告/截图/日志执行，不复用或覆盖旧yellow package和五关QA。旧通过证据保留。新反馈按Owner定位，普通P2不阻塞其余线。

首次包矩阵真实失焦自动Pause的日志保留；独占复测230 PASS。新的试玩如果失焦，请通过正常Esc/Resume恢复，不改Runtime或Save冒充结果。

05扩展Art仍PENDING_USER_REVIEW，连接准备度Facade仍PENDING_RUNTIME_INTERFACE，旧94、L03首次理解性、Foundation Full不借本轮标PASS。正式ref下一允许Integration窗口再接纳。

Push: NOT_RUN
