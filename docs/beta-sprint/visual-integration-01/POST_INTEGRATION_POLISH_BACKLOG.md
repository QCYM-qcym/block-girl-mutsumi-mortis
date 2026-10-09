# POST_INTEGRATION_POLISH_BACKLOG

仅记录本轮真实发现的非阻塞P2/P3。不得因未来可选功能或仅有猜测的新问题重开美术/工具线。

已确认P2：VIS01-P2-001，compact panel底部辅助文字按Window而非panel bottom定位。ui_graph03/seed/pause_1280x720.png中导航footnote稍越过石板边；contract_complete_960x720_false_false.png中人工注入长存档错误的最后一句次要说明跨到较深背景。主要动作、真实键鼠导航、错误原因、原档安全说明和Retry均可读/可操作。独立审查确认不阻塞，按用户冻结规则仅进入Backlog，不修改已批准Art，不重开工具/美术线。位置：game/shell/visual_01/approved_shell_view.gd的status/footnote定位。初始交付时Human QA尚未执行；本轮正式补测现已完成，剩余P2及当前范围见下面2026-10-09关闭登记。

保留范围：高级水体、可选环境微动画/次要装饰、非阻塞字体微调均不属于本轮接入必需交付；没有真实缺陷证据时不计为已发现P2。

已有工具问题（不计新增UI P2）：Daily Build L02/L03单场景--quit-after120退出各报4 ObjectDB实例WARNING，stderr133bytes/SHA bf8149e7a4c220bbef9c5eac13cd97f17ae895e5fff5a7befa152e30319f4d9d，逐字节匹配20261006旧Beta Slice e22d0255e8a974c1f87445516b16ddcb71af465e。复制工程boot exit0，正式MAIN UI/L01流程及冷Continue stderr空。沿用既有Boot门槛，保留警告到工具Backlog；不退回Owner、不改冻结Core。详情见DAILY_BUILD_VERIFICATION.json。

## 2026-10-09 independent UI QA closeout

正式来源：[BETA_3D_UI_QA_CHECKPOINT_ACCEPTED](../qa-checkpoint-01/RECEIPT.md)，绑定 Build `visual_ui08001_20261009_01` / source `ca6b331dc7c819c2a01e23c49827c0bd6a9c43a3` / ZIP SHA256 `40afc81b0c5d5574b1bd688d6048ece4c1537da94905af30e32eca92b5456cb1`。

UI-08-001=CLOSED；三尺寸授权 UI Matrix 3/3 PASS；Navigation/Settings/Hint/Focus PASS；P0/P1=0/0。剩余P2 **1**，新增P2 **0**。

唯一剩余项 **VIS01-P2-001 / UI-08-K01**（两个历史编号合并为同一个问题），Owner07 Game Shell，OPEN / P2 / NON_BLOCKING：Pause板底辅助文字贴底，960×720与底部操作说明重叠；主要按钮仍可操作。保留布局修正到后续polish，不修改已批准Art，不重开UI Art Direction，不阻塞BETA-3D-INTEGRATION-02。

L-01通关、L-02解锁、Cold Continue只保留历史通过，本closeout未重跑。L-03_FIRST_TIME_COMPREHENSION=RETEST_PENDING；FOUNDATION_4_FULL=DEFERRED（当前Beta Scope）。旧自动化交付、旧Human QA证据及当前新3D候选包各自保留精确身份。本登记不声称全游戏Beta QA完成。
