# L06 后续生产与验收规格

2026-10-09 · DESIGN_ONLY · 下列生产/图形/人类步骤当前 NOT_RUN

设计入口：[DESIGN.md](DESIGN.md)。机器可读地图与路线：[CANDIDATE.json](CANDIDATE.json)。当前可表达性证据：[VALIDATION.md](VALIDATION.md)。本文件供00评审及未来另行授权的 L06 任务使用，不登记第六关，不要求等待五关3D或L03新玩家。

## 未来最小生产顺序

1. **06 作者内容**：在00指定的新生产Owner路径创建独立 L06 Resource/Scene/局部提示；字段转换自候选 `data`，保留一组 Surface/EAST 连接、既有桥/踏板/门/Goal 条件。不能继承 L04/L05 的关卡专属提示。复用现有 ContentState / Movement / View，先跑同样的原规则路线和查询审计。
2. **05/00 3D场景**：在既有接口与批准资产内制作视觉表达，实际检查25坐标两世界支撑、桥面、转角、端点、门和出口；不可见地板不能由装饰碰撞补成道路。若实现需动共享Presenter，由01/00负责，06不越Owner修改。
3. **07 Shell接入**：由07登记稳定ID、正常scene/resource/adapter与L05→L06进度规则，00确认接入顺序。保留既有存档兼容、Continue起点和最终关卡按钮语义，不由06手写完成/解锁存档。
4. **00/08 新包验收**：绑定具体Source/ZIP/SHA、独立执行副本、隔离存档、原始操作与日志；通过真实 L05 Goal 自然解锁 L06。沿用旧包只能作历史证据，不授予本关或新3D包 PASS。

## 作者规则验收

| 检查 | 通过条件 |
| --- | --- |
| 地板转换 | 候选的 Surface 15格、Inner 22格、平台B7格及Spawn/Goal精确一致；没有重复或额外通行格 |
| 出生 / 立即 Shift | Surface `(0,7)`；切 Inner 后至少一个合法方向；八种出生world/view组合均能前进 |
| 支撑拒绝 | Surface `(0,6)`、Surface `(9,0)` 等无目标世界支撑的格子拒绝 Shift，当前位置/朝向不变 |
| 连接 | 仅 Surface/EAST active；其他世界/视角不跨越；端点 `(3,0)↔(9,0)`；跨越是原翻滚提交 |
| 世界组合 | 所有摄像机顺序的最少Shift为6；正常路线21翻滚、6Shift、1旋转；出生Inner替代路线23翻滚、6Shift、1旋转 |
| 门 | Inner Plate不能过门；Surface Plate允许原门边；落定门后正常关闭；没有门旁替代边 |
| Goal | 仅 Surface `(13,0)` 触发原完成；Inner出口切换到Surface也合法完成 |
| 无捷径 / 恢复 | 原查询拓扑全部可完成；移除Shift、连接或门边均不可达Goal；门后不必能原路返回，但可正常前进或R |
| 物理姿态 | 原roll更新24态朝向；Shift/视角不改变cell或orientation；不新增面条件 |

当前设计已执行上述核心原API与查询检查，但没有生产资源转换。未来资源需以实际消费SHA重复验证，不能引用本轮候选JSON替代。

## 正式完整路线

每条路线实际从正式 L06 起点开始，以当前正式输入驱动，经过可见动画和自然提交；禁止直接写cell/world/phase、强制Tween结束或编辑存档制造完成。记录当前Content原快照 `(cell,world,view,orientation,phase,moves)`；若未来改用RuntimeSession，01另补实际StateKey/status/rejection/safety与transition证据，不伪造旧适配器没有的字段。

1. **正常通关**：Surface起点→A/B/C借路→共享桥切Surface→EAST连接→远岸E/F借路→Surface Plate→门后→Goal。正式完成回调只发生一次，完成UI/保存符合07接口。
2. **Reset重玩**：先走到远岸或Inner Plate；R恢复Surface/NORTH起点、初始朝向、门关闭。之后完整执行正常路线至Goal；通关后再R确认可开始重玩。
3. **不同视角顺序**：出生Q到WEST；到连接A后E经NORTH至EAST；真实跨越后E到SOUTH；按当前方向映射完成后半段，Goal/物理姿态一致。
4. **出生立即切Inner**：Space后短按A，原翻滚到`(-1,7)`；沿Inner支路到A后完整完成。正常持续按也能走；不通过延长按键掩盖短按失败。

每条保存真实动作轨迹、源码SHA、Goal事件、截图/日志。图形检查覆盖连接成立、跨越落定、远岸转角、Surface踏板、门后和Goal；不能只以画面静止推断Runtime拒绝，也不能以原API验证宣布Presenter PASS。

## Reset、界面与可读性

| 场景 | 验收要求 |
| --- | --- |
| Roll/Shift/视角动画中R | pending动作、held输入和旧动画清除；重置后动作正常；数据与视觉一致 |
| 暂停 / Resume | 按07现有语义恢复，世界/位置/朝向不意外改变 |
| 完成后重进 / Cold Continue | 按既有正式起点语义启动，解锁与完成进度保留；非临时中间状态冒充保存点 |
| 相接后提示 | A端active时撤销“继续旋转”；B端显示远岸问题；回到A重新依据当前世界/视角提示 |
| 非共同落脚点 | 拒绝提示可理解，无隐藏面/时间条件；合法下一动作仍能执行 |
| E/F/Plate转角 | 下一格边缘与道路方向在至少两个视角能看清；角色/门遮挡处理由场景Owner落实 |
| UI尺寸 | 在正式最低尺寸及1280、1920构建规格检查文案不遮关键格；具体尺寸沿用07/08矩阵，不新增窗口政策 |

## 08首次试玩

对象应完成或理解L01–L05基本操作，但没有看过L06作者地图、路线或此验收文档。先给游戏内目标和正常提示，不发键序答案。记录实际首次时长、各停滞点、尝试的世界/视角、提示是否足够，以及玩家能否解释连接所属世界与Surface踏板条件。

设计估计6–9分钟不作为硬超时失败线；若出现持续困惑，按事实记录新P2/P1并交06/05/07相应Owner。出现无法完成、输入/提交公共冲突或存档风险时按Owner交接，不由06修改全局规则。

`L06_DESIGN_READY` 只表示设计可评审。生产启动、GREYBOX_PLAYABLE、3D_READY、FORMAL_PLAYABLE、Human QA PASS、L05→L06自然解锁及新包Save/Continue均须未来独立证据，本轮状态全部 NOT_RUN / NOT_REGISTERED。
