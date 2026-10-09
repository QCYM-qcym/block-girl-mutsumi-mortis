# L06_DESIGN_READY —《交织的归途》预生产设计

2026-10-09 · 06 Game Content · Beta Phase 3 / Track C · DESIGN ONLY

本案让玩家把前五关的翻滚、共同落脚点、四视角投影连接、踏板与门组合成一次终章路线。玩家从 Surface 出生，借两种世界的道路抵达 Surface 的 EAST 连接，在另一岸再借 Inner 绕路，最后返回 Surface 压下踏板并到达出口。难度来自判断下一段道路所属世界，以及跨越连接后重新辨认方向。

本轮交付设计与原规则可表达性验证。没有 L06 生产 Scene / Resource、灰盒、3D、美术、菜单注册或存档接入。暂定 ID `mutsumi_l06` 和标题只用于设计候选；[CANDIDATE.json](CANDIDATE.json) 的 `data` 字段对应现有 ContentLevelData，`quality=GREYBOX` 是未来转换资源的拟用字段，不能解释为当前已有可玩灰盒。

## 基线与既有证据

基线为 `9e2e9c29a73272d431795f12db1fefaff2433b05`。五个正式入口使用现有 `adapter=p01`；L06 不加入该目录。

| 已有内容 | 本案复用的能力 |
| --- | --- |
| L01 | Cube Roll、90°视角、World Shift、投影连接、Surface 踏板与门 |
| L02 | 共同落脚点之间借另一世界道路 |
| L03 | Surface 的 EAST 连接；跨越前后提示应切换阶段 |
| L04 | Inner 借路；出生切换后必须存在可走后继 |
| L05 | 世界选择、连接与门的组合；人类首次盲玩已完成 |

08 的 [FIVE_LEVEL_ALPHA_QA_01_COMPLETE](E:/godot/beta-sprint-builds/l04_p1_l05_human_recheck_20261009T075359Z/FIVE_LEVEL_ALPHA_QA_01_COMPLETE.md) 绑定旧 hotfix 包：L04 P1 CLOSED、L05 First Human Playthrough PASS、P0/P1/P2=0/0/3。L05 仍为 GREYBOX_PLAYABLE，不能升级为正式美术完成。L03 新玩家理解性仍为 [RETEST_PENDING](E:/godot/beta-sprint-builds/phase3_l03_first_player_preflight_20261009T084239Z/L03_FIRST_TIME_COMPREHENSION_RETEST_PENDING.md)。这些历史结论不转记未来 L06 或五关新3D包。

08 实际反馈包括视角变化后的方向对应，以及出口/桥转角遮挡。本案把转角提示和可见落点列为未来验收项；没有修改 L04/L05。

## 方案选择

| 方案 | 收益 | 取舍 |
| --- | --- | --- |
| 延长 L05 的 Inner 连接路线 | 作者接口最熟悉 | 容易重复四次 Shift 的结构，终章主要增加步数 |
| **交替借路 + Surface 连接 + 远岸 Inner 绕路** | 六次必要世界选择；连接世界与 L05 不同；跨越后仍要判断道路 | 需要清楚说明连接所属世界与远岸转角；本案采用 |
| 多连接、锁存门或指定方块面开门 | 可以增加新的推理维度 | 当前资源没有这些机制；需要公共 Runtime/接口扩展，排除 |

本案不增加计时、消耗品、可搬物、检查点、特殊面要求或新输入。Cube orientation 仍由原翻滚更新，视角/世界切换不改变物理朝向；该内容适配器没有以方块面判定门或出口的条件。

## 当前接口能表达什么

| 来源 | 真实约束与本案用法 |
| --- | --- |
| `content_level_data.gd` / `content_state.gd` | 两组地板列表、Spawn/Goal、平台B列表、一组连接及世界许可、gate_enabled；候选全部使用现有字段 |
| `grid_movement.gd` | 合法邻格才启动翻滚；目标世界当前格有支撑才可 Shift；使用原计时与提交 |
| `perspective_controller.gd` / `perspective_link.gd` | 四个离散90°视角；当前连接只在 EAST，平台B偏移 `(-5,0)`；端点 `(3,0)` 和 `(9,0)` 的几何关系保留 |
| `p01_state.gd` | 踏板固定 `(11,0)`，门边固定 `(11,0)→(12,0)`；门只在 Surface 踏板落定时打开 |
| `l01_3d/presenter.gd` | 现有门 Presenter 在两世界固定画桥格 `(1,0)/(2,0)` 和踏板位置；本案两世界均声明这些支撑 |

这些是当前 Content / p01 的事实，不是 Foundation LevelDefinition。当前适配器没有 RuntimeSession 的 APPLIED/REJECTED、Kernel StateKey 或 Safety issue 输出；验证使用其原邻接、支撑、连接、翻滚和完成接口。Foundation Safety 验收本轮 NOT_RUN。未来迁移到另一 Runtime 时，01负责公共语义对照，06不能自行扩大许可或绕过判定。

## 谜题与难度

目标：从 Surface `(0,7)` 到 Surface `(13,0)`。必须经过一组投影连接及原 Surface 门边。终章的情绪意图是把之前分开掌握的操作组合起来，不添加剧情事实或新结局系统。

预估首次游玩 **6–9分钟**，已熟悉路线约 **45–90秒**；这是设计估计，尚无人类 L06 样本。L05 已有首次盲玩约4.40分钟可作参考。若未来合格玩家多数超过10分钟且依赖完整答案，优先改善转角可读性与分阶段提示，再评估地图复杂度。

最短动作路线：**21次翻滚 + 6次 Shift + 1次90°旋转 = 28动作**。动画本身约8.62秒，不设动作时限。出生即切 Inner 的合法支路增加2次翻滚，共30动作；它是允许的替代解，不视为捷径。

六次世界选择不是六个唯一坐标考点。桥格 `(1,0)/(2,0)/(3,0)` 都可作为第四次切换点；最后也可先在 Inner 走到踏板，再切 Surface。它们保留相同的必要机制，不要求玩家照抄作者路线。

## 作者数据与空间

坐标为逻辑 `(x,z)`，`z` 减小为世界北。完整地板列表以 [CANDIDATE.json](CANDIDATE.json) 为准。Surface 15格、Inner 22格，合计25个不同坐标；平台B由资源明确声明，不由屏幕视觉推断。

| 区段 | 地标 / 世界 | 下一步推理 |
| --- | --- | --- |
| 出生 | Surface `(0,7)→(0,6)→A(0,5)` | Surface 道路到 A 截止；同格可借 Inner |
| 第一段借路 | Inner `A→(1,5)→B(2,5)` | B 的北侧只在 Surface |
| 折返岸 | Surface `B→(2,4)→C(2,3)` | C 的西侧只在 Inner |
| 内侧回廊 | Inner `C→(1,3)→(0,3)→(0,2)→(0,1)→(0,0)→D(1,0)` | 当前回廊抵达共享桥；连接属于 Surface |
| 固定桥 / 连接A | Surface `D→(2,0)→(3,0)` | 在 Surface 转 EAST，对齐唯一连接 |
| 连接B / 远岸 | Surface `(3,0)→(9,0)→E(9,1)` | 没有 Surface 直达踏板的沿岸道路；借 Inner 绕行 |
| 远岸回廊 | Inner `E→(10,1)→F(11,1)` | 从 F 返回 Surface，北侧踏板可达 |
| 归途 | Surface `F→Plate(11,0)→(12,0)→Goal(13,0)` | 压踏板、按原门判定通过、触发原完成条件 |

出生 Inner 支路：`(0,7)→(-1,7)→(-1,6)→(-1,5)→A(0,5)`，随后接上述 Inner 第一段。两世界出生格在每个视角都有一个合法移动方向；其他三方向被正常拒绝。

平台B坐标：`(9,0),(9,1),(10,1),(11,1),(11,0),(12,0),(13,0)`。其余平台为A。中间 `(4,0)…(8,0)` 没有地板；只有既有 Connection 可越过逻辑间隔。Inner 的 `(9,0)` 没有支撑，抵达 Surface 连接B后不能原地切 Inner，须先走到 E。

桥、踏板、门后和出口在两世界保留真实作者支撑，避免继承 Presenter 出现看得见却站不住的地板。Inner 踏板不打开门。门在 Surface 穿过后关闭，原规则不保证从门后退回踏板；玩家可继续到邻近出口，或用 R 回到起点。

## 作者参考路线

| 步骤 | 落点 / 状态 | 翻滚 | 切换 / 旋转 |
| --- | --- | --- | --- |
| 1 | A `(0,5)`, Surface | 北×2 | Shift→Inner |
| 2 | B `(2,5)`, Inner | 东×2 | Shift→Surface |
| 3 | C `(2,3)`, Surface | 北×2 | Shift→Inner |
| 4 | D `(1,0)`, Inner | 西×2、北×3、东×1 | Shift→Surface |
| 5 | Connection A `(3,0)`, Surface | 东×2 | 转 EAST |
| 6 | Connection B `(9,0)`、E `(9,1)`, Surface | 东×1跨越、南×1 | Shift→Inner |
| 7 | F `(11,1)`, Inner | 东×2 | Shift→Surface |
| 8 | Plate→门后→Goal, Surface | 北×1、东×2 | 正式完成条件成立 |

NORTH 出生、在连接A按一次 E、之后保持 EAST 的参考键序：

```text
W W Space D D Space W W Space A A W W W D Space D D E W D Space W W Space A W W
```

每次按键待原动作落定；验收须同时覆盖短按与正常持续按，不把延长按键作为修复。世界方向依当前视角映射，不把 `D` 固定解释为世界东。

不同视角参考：出生先 Q 到 WEST；到连接A后 E 经 NORTH 到 EAST；跨越后 E 到 SOUTH，再走远岸与门。该路线31动作，仍为21翻滚、6 Shift。允许其他90°视角顺序，真正连接跨越仍须 Surface/EAST。原 API 已验证此路线，实际3D与输入待后续验收。

## 提示与辨识规格

未来只为 L06 创建局部提示，沿用现有 `update/objective/reset` 接口，不改全局输入/规则，也不复制 L05 的“连接属于里世界”文案。提示依据当前 `cell/world/view/phase/link.active`，回走、Reset 和重进入后重新判断，不用“曾到过右岸”永久锁住阶段。

| 条件 | 关卡提示文案草案 |
| --- | --- |
| 初始且未前进 | “借两个世界的道路前进，回到表世界的出口。”；操作提示 WASD |
| A / Surface | “这里在两个世界都有落脚点。前方的路在里世界。” |
| B / Inner | “北侧的道路在表世界。先站稳，再切换。” |
| C / Surface | “这段岸边还没有相接。借里世界的回廊继续。” |
| D或连接A / Inner | “这对连接标记属于表世界。共同桥面可以切换。” |
| 连接A / Surface / 非EAST | “转动视角，让两个连接标记相接。”；操作提示 Q/E |
| 连接A / Surface / EAST / active | “连接已成立。向相接的另一端翻滚。”；移除旋转提示 |
| 连接B / Surface | “已到另一岸。沿岸转角前进，寻找共同落脚点。” |
| E / Surface | “通往踏板的绕路在里世界。” |
| F / Inner | “表世界的踏板就在转角后。这里可以安全切换。” |
| Plate / Inner | “里世界的踏板不能开门。在这里返回表世界。” |
| Plate / Surface | “踏板已压下。向门后的道路翻滚。” |
| Goal / Inner | “出口属于表世界。此处可以切换。” |
| complete | “已到达出口。按 R 再次游玩。”；清除世界/旋转引导 |

提示只告诉当前问题与已有操作，不默认显示完整路线。按回退方向走时提示要反映当前状态；跨越后不再残留连接A的旋转引导。暂不添加新提示按钮、动态方向箭头或新的存档字段。

未来场景的可读性要求：E、F、Plate 三处转角和下一格边缘在至少两个视角清楚可见；共享桥和单世界地面能区分；链接成功/失效有既有状态反馈。若当前镜头构图达不到要求，05/00负责场景可读性处理，不能以添碰撞捷径或修改全局投影规则补偿。

## 失败与恢复

| 情况 | 预期原判定 | 可继续操作 / Reset |
| --- | --- | --- |
| 出生立即切 Inner | 合法 Shift；西向支路可走 | 沿支路到 A；或切回 Surface |
| 单世界格按 Space，例如 Surface `(0,6)` | 无目标支撑，Shift 不启动 | 仍在原格、原世界；继续到共同落脚点 |
| A/B/C 选错下一段世界 | 缺地板，翻滚不启动 | 同格 Shift 或沿来路回退 |
| Inner / EAST 站连接A | wrong world，连接 inactive，不跨越 | 在共享桥/端点切 Surface |
| Surface / 非EAST 站连接A | wrong view，连接 inactive | 单次90°旋转至 EAST |
| Surface 连接B按 Space | Inner 无 `(9,0)` 支撑，拒绝 | 向 E `(9,1)` 前进再切换 |
| 远岸保持 Surface 试向东 | 缺 `(10,1)`，拒绝 | 在 E Shift→Inner |
| Inner 踏板试过门 | 门关闭，边拒绝 | 同格 Shift→Surface，原踏板开门 |
| 门后想退回踏板 | 原门已关闭，不能反向通过 | 继续到出口；要重走前半段用 R |
| Inner 出口 | 不完成 | Shift→Surface，原 Goal 成立 |
| 翻滚、Shift、视角进行中或按住方向时按 R | 原 Reset 清除 pending/held、世界、视角与完成状态 | Surface/NORTH/初始朝向、出生格、门关闭；重新完整游玩 |
| Goal 后 R / 重进入 | 完成状态清空，场景从正式出生恢复 | 完整重玩；存档仍按07既有语义处理 |

原查询审计确认148/148个可达 `(cell,world,view)` 状态存在继续到 Surface Goal 的路径。该结论包含门后前进及 Inner 出口切换，不等于每个状态都能原路返回出生。没有死亡/掉落系统，也没有为了恢复而新增传送或自动回位。

## 当前验证与生产边界

[VALIDATION.md](VALIDATION.md) 给出真实进程、日志和保护结果；[ACCEPTANCE.md](ACCEPTANCE.md) 给出未来灰盒/3D/正式输入与人类验收步骤。最终原规则验证为500 checks、0 failures、148/148可完成、最少6 Shift、最短28动作。去掉 Shift、连接或门边中的任意一种，当前图均不能到达 Goal。

这证明候选设计可由基线规则表达；没有证明当前存在 L06 正式可玩关卡。Foundation、Runtime、Presenter、美术、Shell、Save、L01–L05生产改动均为 NONE。

未来生产任务由00另行确定时，06只新增 L06 作者资源/场景/局部提示，并先重复原规则验证；05/00负责3D与可读性，07负责正常目录/解锁接入，08在具体新包上执行实际试玩。若需要第二连接、锁存门、指定方块面或公共判定变更，应退回设计或交对应 Owner，不在本案内扩展 Runtime。
