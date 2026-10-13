# 主持专用：全部盲测结束后的核对表

**含规则和路线答案。禁止给首次玩家。** 不附在玩家启动说明，不共享屏幕打开，不用于中途暗示。2026-10-13 / SPATIAL_PUZZLE_BATCH_01_ACCEPTANCE_01。Build source59531adcdffb7a8671bd6aab9a2abdc6fa830b04。

使用时机：所有计划中的首次单机制、综合题迁移任务已结束或玩家决定终止整个会话；先收集 [编码表](../BLIND_OBSERVATION_CODEBOOK.md) 中开放追问，后静默对照本表。若尚有盲测任务，不进行规则核对式问答。此表不得为玩家补造动作前预测。

## 开始核对前

- 确认匿名session、Build、实际题序、既有暴露和资格；USER_CONFIRMED_AVAILABLE不等于已经完成试玩。
- 保留原话/时间，先分辨自发、P1开放追问、P2提示辅助和P3答案污染。
- 核对是否真正有理解/迁移机会；没有机会记UNASSESSED，不能因未展示策略记失败。
- 正确解释不要求说出Cube24数字、枚举或代码术语；用自身语言描述可见因果即可。操作串记忆不自动支持理解。

## 正确规则参考（主持静默使用）

| 对象 | 应理解的因果 | 反事实核对点 | 不能误计为理解 |
|---|---|---|---|
| Gate | 到合法锚点主动Space；锁定型先满足权限；反向记录独立 | 不在锚点/未解锁会拒绝；正确接触不自动换世界 | 按Space碰巧成功，或只记固定位置 |
| Loop | 移动路线决定物理姿态；同位置可有不同姿态 | Camera变化不替代物理Roll；相同终点不保证相同接触面 | 记某按键串，不能区分位置/姿态 |
| Face Lock | 普通Roll抵达后的指定角色local_face接触；正确才锁存 | 错Face移动仍成功但idle；latched离开/Shift后保留，Reset清除 | 把宿主TOP/屏幕朝下/颜色当角色local_face；以为自动Shift |
| Fork | 同一正式source edge/MOVE在不同Camera下选不同合法落点；Roll仍优先 | 无匹配拒绝；Fall保持世界与物理姿态；黄色仅候选 | 同时改输入和视角却归因唯一因素；认为错视会自动跨世界 |
| 综合 | Loop求姿态→接触锁存→回锚点确认Shift→Inner分流，支路可恢复 | 未锁不能到Inner；只能在声明Gate回世界；Goal没有额外完整姿态/拓印条件 | 只把七步/八项完成或动作数多当“魔方式规划” |

角色面FRONT0/BACK1/LEFT2/RIGHT3/TOP4/BOTTOM5；当前传感器要求RIGHT3物理接触支撑面。先确认玩家描述的实际面标记对应，不要求背这些编号。

## 正式路线参考：仅定位证据，不让玩家照做

以下使用正式FaceAxis而非屏幕方向：U_POS0、V_POS1、U_NEG2、V_NEG3。F固定U_NEG，WASD映射随Camera变。不得把不同视角相同屏幕键自动当相同正式边。

| 地图 | 作者参考 |
|---|---|
| world_shift_gate_lab | U_POS到gate，Space到inner_gate，V_NEG到goal；反向Gate另有记录 |
| orientation_loop_lab | [U_POS,V_NEG]与[V_NEG,U_POS]到同corner，姿态不同；NORTH0下从corner U_POS正式Fall到环外goal |
| face_lock_lab | 错[U_POS,V_NEG]不锁存；正确[V_NEG,U_POS]锁存；[V_POS,U_NEG]回source后Space到Inner goal |
| perspective_fork_lab | EAST1下U_NEG到A，U_POS到goal；SOUTH2下U_NEG到B，U_POS到return，NORTH0下U_POS回source，再EAST1走A |
| rubik_spatial_puzzle_01 | 公共[V_NEG,U_POS,V_POS,U_NEG]→Space到inner_source，再走Fork A或恢复B；作者A含显式Camera noop计8项，Solver可删noop为7步；作者B计13项 |

这些路线只是现有witness，不要求唯一解、不以偏离作者路径判玩家失败，也不代表本轮完整图已运行。使用现有地图作者定义核对；实际UI显示与正式状态不一致时记BUG候选给对应Owner，不修改代码。

## 逐项证据核对与失败设计登记

| 项目 | 主持核对（只填真实记录） | 当前状态 |
|---|---|---|
| 观察 | 哪条原话/指示明确相关状态？是否主持先提醒？ | NOT_OBSERVED |
| 预测 | 预测是否在动作前？预测对/错与实际结果分别是什么？ | NOT_OBSERVED |
| 顺序 | 是否先说依赖并验证？还是通关后复述按键？ | NOT_OBSERVED |
| 调姿复用 | 是否主动比较、修正，并在新机会复用？ | NOT_OBSERVED |
| 成功解释 | 能否给因果/反事实？答案暴露之前说了什么？ | NOT_OBSERVED |
| 组合迁移 | 之前学了什么、后题新颖性、第一次复用时间、帮助曝光？ | NOT_OBSERVED |

对 [专家风险R1–R6](../COGNITIVE_ACCEPTANCE.md) 分别标SUPPORTED / CONTRADICTED / INCONCLUSIVE / UNASSESSED，附原始证据，不预填设计FAIL。失败登记含：情境、玩家预测、实际反馈、错误归因、帮助/恢复、对下一题影响、限制及小范围改进候选。后来解释正确或通关不删除首次误解。

## 收束边界

当前记录0份，H1–H6全NOT_OBSERVED，Human QA=NOT_RUN。本轮合适玩家可安排，不声称已招募/已试玩。完整图与技术PASS独立，不能签认认知PASS。首次理解失败、机制信息不足、操作性故障和主持污染分列；记录足够后由08提供实际QA收据、13作限定设计判读、00统一接收。

参与者个人数据/原始音视频按08获得的同意范围保管；Git仅交付空白协议与去标识必要摘要，不主动上传原始记录。盲测结束后的讲解/重试单列，不回填首次体验。
