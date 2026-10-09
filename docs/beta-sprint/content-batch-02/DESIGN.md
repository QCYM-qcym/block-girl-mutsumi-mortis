# Batch02 — L04 / L05 内容设计

2026-10-09，基线 `b910167becee2194c0cfc724d8f0fe47578836a9`。用户 BUILD / PARALLEL 明确授权独立生产；不等待设计批准。已在指定 `feat/beta-content-batch-02` 工作树，原06工作树和主工程不变。

CONTENT_OWNER_ROOTS：`game/levels/mutsumi/batch_02/`、`docs/beta-sprint/content-batch-02/`、`tests/beta_sprint/content_batch_02/`。

## 现有接口及复用

Resource 仍用 batch_01/content_level_data.gd，图和目标用原 ContentState，移动/旋转/切换用原 P01 Runtime。不复制算法，不修改旧三关 .tres、提示、3D Presenter、Shell/Save/Art 或 Foundation。

L04复用无门 generic 3D Presenter；L05复用已有 L01 gate Presenter。批次局部 Scene 子类只选已有 Presenter factory、关卡提示；没有新增3D布局算法。灰盒复用冻结美术，quality=GREYBOX。沿用 EAST 端点 +6x、平台 B -5x 展示偏移、PressurePlate `(11,0)` / Gate edge `(11,0)↔(12,0)`、Surface Goal 的冻结限制。

## L04《借来的道路》— GREYBOX_PLAYABLE

Spawn `(1,5)`，Goal `(11,1)`，Surface。路线：Surface 北到 `(1,4)`、西到共同岸边 `(0,4)`；Shift Inner，北两格到 `(0,2)`，东三格到 `(3,2)`；EAST + Inner 启用连接 `(3,2)→(9,2)`；前进到共同落脚点 `(10,2)`，Shift Surface，东到 `(11,2)`，北到出口 `(11,1)`。

核心决策不是只打开一个开关：第一岸必须借里世界通路，连接也属于里世界；另一岸出口通路只在表世界。Surface 旋转不能造出第一段地板；Surface+EAST不能启用连接；Inner不能走最后出口道路。可以在共同岸边回退/调整，不以 Reset 掩盖死路。

NORTH出生最短键序：`W, A, Space, W×2, D×3, E, W×2, Space, W, A`。世界网格方向为准，键位随视角变化。Goal 与门无关；不用 PressurePlate/Gate。

## L05《归途的门》— GREYBOX_PLAYABLE

Spawn `(0,5)`，Goal `(13,0)`，Surface。路线：北两格到 `(0,3)`；Shift Inner，北到 `(0,2)`、东到 `(1,2)`；Shift Surface，北两格到 `(1,0)`、东两格到 `(3,0)`；Shift Inner，EAST连接到 `(9,0)`，东两格到 `(11,0)`；Shift Surface 激活已有 PressurePlate，东两格穿 Gate 到 Goal。

四次世界选择分别承担：第一段通路、桥的入口、连接许可、踏板许可。Surface缺少 `(0,2)`，Inner缺少 `(1,1)`，Surface无连接许可，Inner无踏板许可；四次切换不能省略。每个安全共同格允许反悔；连接前的视角和最后门处的视角可以改变，只需自然输入仍走对世界方向。

复用的 L01 Presenter 在两世界固定画出 `(1,0)`、`(2,0)` 两格桥。本地图在两世界均声明真实支撑；Inner桥与第一段通路被 `(1,1)` 缺口隔开，因此不会产生跳过第二次切换的捷径。独立审查发现旧地图未声明这些可见桥格；新增四项失败断言后，以上 Owner-local 地图修正消除呈现与逻辑冲突，不改共享 Presenter。

NORTH出生最短键序：`W×2, Space, W, D, Space, W×2, D×2, Space, E, W×3, Space, W×2`。Gate仍由真实占格提交开/关；Goal只能真实落定到Surface出口完成。

## 本轮验收与交付限度

Unit：缺 Scene 的 RED；实际 Resource / ContentState / 原 mover 的路线和机制阻断、复位，另以明确标记的拓扑枚举检查所有可达状态。不把枚举时选择抽象状态当作自然通关。最终45项通过；L04 68/68、L05 100/100可达状态可完成；最少切换次数分别2、4。

Real：独立 Scene + 真实 `Input.parse_input_event` 经原 GridInput，正常、Reset后、不同视角路线；检查每次正式 committed、一次性原 Shell level_adapter.completed、拒绝错误操作、动作中R、全四视角和数据/源码SHA。自然通关中不直接设置 mover/graph/world/view/pose，不调用测试替身。

当前图形窗口由00占用，本Owner默认只运行headless。提供同一Real脚本的 `-Case graphical` 给00，禁止默默宣称图形验收通过。若尚未得到图形窗口释放，图形样例为明确 pending，不阻塞独立逻辑交付。已知unused defs-only icons_source.svg导入P2只保留失败日志并恢复原.import；不改冻结SVG。

稳定ID最初以DESIGN_COMPLETE/registration_allowed=false发布；real_03最终206项检查、六条自然路线及六次正式回调全部通过，现已更新GREYBOX_PLAYABLE并允许07登记。图形仍PENDING。07独占batch_01/level_order.json，本批目录只提供交付catalog；不修改保存/加载实现或现有玩家进度数据。
