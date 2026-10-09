# GAME_CONTENT_BATCH_02_READY

2026-10-09；Owner分支 `feat/beta-content-batch-02`；基线 `b910167becee2194c0cfc724d8f0fe47578836a9`。

| 关卡 | 稳定ID | 状态 | 职责 | 自然通关 |
|---|---|---|---|---|
| L04《借来的道路》 | mutsumi_l04 | GREYBOX_PLAYABLE | World Shift + Inner EAST Perspective Connection；返回Surface出口 | 正常 / Reset重玩 / 不同视角各1次 |
| L05《归途的门》 | mutsumi_l05 | GREYBOX_PLAYABLE | 四次必要Shift + EAST连接 + 原踏板/门 | 正常 / Reset重玩 / 不同视角各1次 |

两关 Unit / headless Real 已通过，可供07登记。Graphical：`PENDING_00_INTEGRATION`。使用现有批准资产的灰盒，不声称最终美术或图形验收通过。此前Batch01的L01–L03资源和提示均未改动。

## 实际路线

L04：Surface `(1,5)→(1,4)→(0,4)`；切Inner，经 `(0,3)→(0,2)→(1,2)→(2,2)→(3,2)`；EAST连接到 `(9,2)`，前进 `(10,2)`；切Surface，经 `(11,2)` 到Goal `(11,1)`。NORTH出生键序：`W, A, Space, W×2, D×3, E, W×2, Space, W, A`。

L05：Surface `(0,5)→(0,4)→(0,3)`；切Inner，经 `(0,2)` 到 `(1,2)`；切Surface，经 `(1,1)→(1,0)→(2,0)→(3,0)`；切Inner、EAST连接到 `(9,0)`，前进 `(10,0)→(11,0)`；切Surface压踏板，原门允许落定 `(12,0)`，再到Goal `(13,0)`。NORTH出生键序：`W×2, Space, W, D, Space, W×2, D×2, Space, E, W×3, Space, W×2`。

方向键始终由原GridInput随当前视角映射。验收中的不同视角路线使用Q绕转再对齐EAST，并在连接落定后转向SOUTH继续，均由真实InputEvent驱动。

## 验收证据

最终 `unit_final`：PID **32756**，exit **0**，**45** checks，0 failures。L04 68/68、L05 100/100可达状态可完成；原图邻接查询证明最少Shift次数2/4。这部分是明确隔离的拓扑审计，不代替自然输入。

最终 `real_03`：PID **48780**，exit **0**，**206** checks，**6** natural InputEvent routes，**6**正式 `level_adapter.completed`，0 failures；Godot **4.7.2.stable.steam.ed1daf0bf**，display=headless。正式回调均观察到Surface Goal、phase=complete；每次恰好一次。R验证含移动/切换/旋转中、方向按住时及通关后，原Shell Reset重新启用正式完成观察器。门保持原有落定时序；错误世界不能绕过道路、连接或Gate。

Real报告包含21个实际消费源码/资源的字节SHA256、原mover.committed轨迹、正式回调快照、PID专属测试存档及校验结果。默认玩家存档与备份SHA不变。历史RED、失败夹具与旧地图逻辑结果全部保留，版本说明见PLAN.md和测试README；最终判断只采用unit_final / real_03。

## 独立审查与修复

只读审查发现一项Important：旧L05地图没有声明复用L01 Presenter在两世界固定画出的桥格 `(1,0)` / `(2,0)`。桥支撑断言先实际RED（PID11584，exit1，4失败），再调整本批地图和提示，修正后GREEN（PID48660，exit0，43检查）；最终又确认四次Shift没有桥/视角捷径。共享Presenter与公共规则未改动。

审查未报告其他Critical/Important/Minor。此次修正的证据为Owner的RED/GREEN及自然输入复验；未把它说成第二轮独立审查。视觉辨识、布局与首次玩家理解仍需00图形验收。

## 最小接入请求

`GAME_SHELL_INTEGRATION_REQUEST`：07将本批 `game/levels/mutsumi/batch_02/level_order.json` 两条记录追加到自己负责的实际Shell catalog；稳定ID、scene、resource和adapter=p01以STABLE_LEVEL_IDS.json为准。本Owner未修改 `batch_01/level_order.json`、菜单、存档或任何共享入口。无需新增全局输入、Autoload或registry。

`INTEGRATION_REQUEST`：00在最终集成工作树、图形槽可用时执行测试README中的 `-Case graphical`。验收报告与截图保留真实PID/退出码/源码SHA；人工检查桥的可见位置、两世界地板、EAST相接、门/出口、HUD。当前图形PENDING与逻辑GREEN分别记录。

`ART_REQUEST`：后续05/00按已冻结接口为L04/L05完成最终场景美术和可读性验收；本批引用已有资产，未改源模型、材质、动画或SVG。冻结的unused SVG导入P2本轮未发生。

Production Foundation changes：**NONE**。公共Runtime/Presenter/Shell/Save、旧三关资源/提示、Art、project.godot及全局输入改动：**NONE**。只写入三个授权Owner根；无合并Integration、无推送。

文件/SHA与候选commit见交付RECEIPT及FILES_SHA256.json。图形验收为剩余集成待办，未将其列为Owner-local内容构建失败。
