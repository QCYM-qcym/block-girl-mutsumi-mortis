# 《方块少女》第一批空间魔方机制：全流程自主开发任务

**PROJECT：** Mutsumi Veilshift / 方块少女-若叶睦  
**ENGINE：** Godot 4.7.2  
**TASK：** `SPATIAL_PUZZLE_BATCH_01_FULL_IMPLEMENTATION`  
**MODE：** BUILD / AUTONOMOUS / PARALLEL / INTEGRATE / VERIFY  
**TARGET：** 2026-11-30 Beta

## 一、任务目标

本次任务要求你作为总开发协调者，完整推进第一批空间魔方式解谜机制。

不要只输出开发计划、接口设计或者 TODO。

在确认真实项目架构后，直接执行：

项目审计 → 机制设计 → 地图制作 → Runtime 扩展 → Solver/Safety/Replay → 3D 表现 → 自动化验证 → 集成 → 可玩 Build → 交接。

本次包含四个功能：

**STEP 0 — World Shift Gate**

世界转换点和机关权限。

**STEP 1 — Orientation Loop**

地图回环改变方块六面朝向。

**STEP 2 — Face Lock**

指定六面接触机关。

**STEP 3 — Perspective Fork**

四视角控制不同错视坠落目标。

完成上述功能后，还必须完成：

**STEP 4 — Combined Puzzle**

制作包含四项功能的独立综合实验关卡。

STEP 4 是集成验收，不是第五个新机制。

本轮目标状态：

`SPATIAL_PUZZLE_BATCH_01_PLAYABLE_READY`

只有通过正式集成验证，才能报告该状态。

## 二、执行授权与工作方式

这是一个已批准的开发任务。

允许你自主完成：

- 只读代码审计
- 独立 Worktree / Branch 创建
- 机制设计文档
- 独立实验场景
- 必要的正式机制实现
- Owner 范围内的测试
- Git Commit
- Integration 接线
- 独立可玩 Build
- 自动化验证
- QA 交接

不需要每个阶段都向我申请新的确认。

如果具备多 Agent / 子任务并发能力，按 Owner 划分并发执行。

如果无法真正同时运行多个 Agent，则按依赖顺序连续完成，但仍保持模块边界和独立提交记录。

禁止把不能执行的并发工作报告为已并发完成。

遇到普通测试夹具、文档格式或可修复的局部问题，直接处理并继续。

只有出现公共 Contract 冲突、未经授权的破坏性 Git 操作、数据损坏风险或无法安全判定的正式玩法规则冲突时，才暂停受影响部分。

其余独立工作继续。

## 三、真实项目基线审计

主项目：

`E:\godot\若叶睦\方块少女-若叶睦`

Integration Worktree：

`E:\godot\worktrees\block-girl-foundation-4-integration`

Godot Editor Dev：

`E:\godot\worktrees\block-girl-editor-dev`

Release Worktree：

`E:\godot\worktrees\release-12`

现有五关正式 3D 集成参考：

`d472885d7375ef73fd36e4abc1847a9ba36cac44`

Perspective Fall Forward Drop 参考：

`fe370ad832bb62cd31a6d22909ce1a5bd1fe1311`

Game Feel Contract：

`2938d6e534f5b596bb320ce79d72b69f5923f3cd`

以上是历史参考身份，不代表当前所有分支已经包含对应提交。

**首先必须检查：**

- `git worktree list`
- 各 Worktree 当前 Branch / HEAD
- 工作树是否干净
- Integration 最新已验证提交
- 五关正式 Game Shell
- Perspective Fall v2
- Cube Orientation
- World Shift
- Mechanism Authoring
- Baker
- Solver / Safety / Replay
- 3D Presenter
- 既有输入映射与 SaveStore
- 已有 16 类机关的真实能力

选取同时具备五关基本功能与已验证 Perspective Fall 的稳定集成基线。

如果这些能力分散在不同提交，先检查真实 Git 祖先与文件范围，制定最小非破坏性集成顺序。

不得直接从旧 `main@13177bb` 开发。

不得覆盖正在使用的 `block-girl-editor-dev`。

不得修改既有 Release 分支或 tag。

## 四、工作树和并发 Owner

使用现有 Owner 体系：

**00 Integration Coordinator**

负责公共接口协调、共享文件接线、最终集成和 Build。

**13 Game Design**

负责四项机制的规则设计、谜题教学方案、Obsidian 文档。

**09 Map & Spatial Design**

负责 Orientation Loop、Perspective Fork 和综合关卡的地图拓扑与作者数据。

**01 Runtime**

负责必要的机制能力、World Shift 条件、Face Lock、正式状态转换和 Solver 适配。

**03 Quality**

负责独立测试矩阵、真实 Runtime 验证、图形回归和缺陷归属。

**07 UI**

只在需要时接入最小机制反馈。

**05 Art**

保留现有已批准美术体系。实验阶段允许使用现有资产，不要求重新制作角色与整套地图。

**08 QA**

只对实际集成 Build 开展独立 QA，不把自动化测试当真人测试。

建议开发分支：

`feat/spatial-puzzle-batch-01`

实际工作树路径、分支所有权和共享文件归属，由 00 检查后确定。

如果某个 Owner 已经有相同任务，不重复初始化。

不得让多个 Owner 同时修改同一个生产文件。

## 五、STEP 0 — World Shift Gate

### 目标

世界切换只能发生在合法转换点。

玩家在普通地图位置按 Space，不能自由切换 Surface / Inner。

支持两种首批规则：

**A. 固定转换点**

玩家站在指定 Face / Anchor 上，按 Space 转换世界。

**B. 机关解锁转换点**

玩家必须先激活对应机关，再到指定转换点按 Space。

姿态限定的高级转换点留给 Face Lock 联动验证。

### 先审计

检查当前正式 World Shift 是否已经具备：

- 转换点身份
- Source / Target Face
- 双世界 Anchor 映射
- 可用权限条件
- 机关绑定
- Orientation 保持
- 单向 / 双向转换
- Runtime 拒绝原因

如果已有完整能力，优先使用作者数据，不新增 Runtime 功能。

如果缺失，进行最小扩展。

### 实现要求

合法位置：

Space → World Shift。

非法位置：

Space → 正式拒绝，StateKey 不变。

机关未激活：

禁止转换。

机关已激活：

允许使用对应合法转换点。

切换之后：

- 目标 Face 合法
- World 更新正确
- Orientation 保持
- Camera 语义保持
- 无非法瞬移
- 无不可恢复软锁

**兼容要求：**

不要把新规则强制覆盖到 L01–L05。

已有正式关卡继续使用其当前合同。

如果需要更严格的权限配置，使用显式 opt-in 的新作者数据。

### 验收

至少验证：

- 固定转换点成功
- 非转换点拒绝
- 机关锁定拒绝
- 机关解锁成功
- 双世界目标映射正确
- Reset 正确
- Solver 正确
- Replay 确定性
- Orientation 不回正
- 旧五关 World Shift 不回归

完成状态：

`WORLD_SHIFT_GATE_READY`

## 六、STEP 1 — Orientation Loop

### 目标

制作一种地图回环，让玩家通过移动路线改变方块的最终姿态。

关键规则：

**同一个位置，不一定是同一个 Orientation。**

第一版尽量不修改 Cube Roll Runtime。

### 地图原型

建立独立实验地图：

`ORIENTATION_LOOP_LAB`

包含：

- 起始平台
- 两条不同路线
- 一个完整可回环区域
- 一个共同目标平台
- 必要的六面方向可视化

### 必须验证

场景 A：

从相同起点，经路线 A 到达目标格。

记录：

`Position_A`

`Orientation_A`

场景 B：

从相同起点，经路线 B 到达相同目标格。

记录：

`Position_B`

`Orientation_B`

要求：

`Position_A == Position_B`

但：

`Orientation_A != Orientation_B`

至少建立一个能回到原位置、同时改变 Orientation 的正式可执行闭环。

如果最初设计的路线不能产生目标变化，依据真实 Cube Orientation 结果调整地图。

不得伪造六面状态。

不得假设特定移动序列一定产生某个朝向，必须用正式 Runtime 验证。

### 重点测试

- 四视角输入映射
- 六面 local_face 身份
- 同位置不同姿态
- Q/E 不重置 Orientation
- World Shift 保持姿态
- Reset 恢复初始姿态
- Solver 可区分同位置不同姿态
- Replay 确定性

### Gameplay要求

玩家应该能通过观察和实验理解：

某些道路用于移动。

某些道路用于调整姿态。

不要一开始显示完整答案。

完成状态：

`ORIENTATION_LOOP_PLAYABLE`

## 七、STEP 2 — Face Lock

### 目标

把立方体六面姿态正式转化为机关条件。

角色到达正确位置，不代表机关自动激活。

必须满足指定局部面条件。

### 规则定义

Face Lock 绑定：

- 稳定机制 ID
- 目标 Face / Anchor
- 需要的 local_face
- 需要的世界朝向或接触方向
- 激活状态
- Reset 规则

首批只实现一种最容易理解的机关：

**指定局部面朝下并接触感应台，激活机关。**

第一版使用：

`LATCH_ON_SUCCESS`

正确触发后机关保持激活，直到 Reset 或正式重置。

避免首批就加入复杂的站立保持和时间限制。

### Runtime 要求

必须从正式 Cube Orientation 和 local_face 身份读取接触条件。

不能通过：

- 3D 模型当前颜色
- Sprite 外观
- Visual Root 临时旋转
- UI 提示状态

决定机关是否激活。

优先复用现有：

MechanismAuthoringNode

Resource Binding

Mechanism Kernel

现有状态及事件体系。

如果当前机制系统已有等价条件，复用即可。

如果没有，新增最小可复用的 Face Lock 机制条件。

不得在具体关卡脚本里硬编码第二套 Gameplay 判定。

### 地图原型

建立：

`FACE_LOCK_LAB`

包含：

- 起点
- 姿态调整路线
- Face Lock 感应台
- 受机关控制的目标通路
- Goal

要求至少存在：

一条能到达机关位置但姿态错误的路线。

一条能到达相同机关位置并满足指定面条件的路线。

### 验收

- 错误 Face 拒绝激活
- 正确 Face 激活
- 机关状态确定
- 重复接触不重复触发
- 离开后符合 LATCH 规则
- Reset 复原
- World Shift 不丢失姿态
- Solver 包含姿态与机关状态
- Replay 一致
- Save/Continue 按现有合同处理机关状态
- Graphical 反馈与正式状态一致

完成状态：

`FACE_LOCK_PLAYABLE`

## 八、STEP 3 — Perspective Fork

### 目标

基于已有 Perspective Fall，开发同一个 Source Edge 的视角分流。

玩家在不同 Camera 方向下，能够抵达不同目标平台。

### 正式规则

同一个 Source：

`Source Face + Source Edge`

Camera A：

连接 Target A。

Camera B：

连接 Target B。

A、B 是不同的正式目标。

允许目标真实高度高于或低于 Source，但必须满足当前视角下的错视连接和视觉下降条件。

### 地图原型

建立：

`PERSPECTIVE_FORK_LAB`

包含：

- 一个合法出发边缘
- Target A
- Target B
- 两个不同的 Camera 资格
- 两条不同的后续路线
- 一个最终 Goal 或明确的恢复路线

### 关键条件

相同：

Source

World

Orientation

Input

但 Camera 不同，产生不同合法目标。

必须检查：

当前相机方向下目标唯一。

禁止：

同一个状态和输入随机选择目标。

禁止：

无作者连接时自动吸附平台。

禁止：

将普通 Perspective Fall 的安全条件关闭。

### 动画

复用正式 Forward Drop：

Forward Advance

→ Edge Leave

→ Descend

→ Landing

→ Roll

优先复用 10A 当前正式动画。

不为 Perspective Fork 重写另一套坠落系统。

### 验收

- Camera A → Target A
- Camera B → Target B
- 非法 Camera → REJECTED
- 非法目标 → REJECTED
- 目标选择确定性
- Source/Target StateKey 正确
- Orientation 按正式 Fall 规则保持
- Landing 正确
- Fall 后继续普通 Roll
- 两条路线均可到达 Goal 或合法恢复点
- Solver 正确处理两种有向边
- Reset / Replay 正确
- 旧 Perspective Fall A/B 不回归

完成状态：

`PERSPECTIVE_FORK_PLAYABLE`

## 九、STEP 4 — 综合实验谜题

以上四个功能分别完成后，必须实际制作一张组合谜题。

名称：

`RUBIK_SPATIAL_PUZZLE_01`

暂定中文名：

《六面归位》

这是一个独立实验关卡。

不得直接覆盖 L06，也不得改写 L01–L05。

### 谜题流程

**第一阶段：观察**

玩家在 Surface 起点观察：

Face Lock

世界转换机关

Perspective Fork

目标位置。

**第二阶段：调整姿态**

通过 Orientation Loop，让角色指定 local_face 进入正确方向。

**第三阶段：激活机关**

以正确 Face 接触 Face Lock。

Face Lock 激活世界转换点。

**第四阶段：World Shift**

玩家到达合法转换点。

按 Space 进入 Inner。

保持正式 Orientation。

**第五阶段：错视分流**

玩家在 Inner 的指定边缘观察不同视角。

Camera A 对应错误但合法的支路，或可恢复的探索支路。

Camera B 对应目标路线。

玩家需要基于已有线索选择合理视角。

不能通过无反馈的随机分流制造难度。

**第六阶段：归位**

角色完成正式 Forward Drop。

落地后继续 Roll。

抵达 Goal。

### 设计要求

至少需要一次真正的路线规划。

不能仅靠连续随机切换 Q/E 和 Space 就轻易绕过机关。

玩家应该能够解释：

为什么要先调整姿态。

为什么需要激活转换点。

为什么从该位置切换世界。

为什么要选择指定视角坠落。

### 玩家体验

给出：

基础提示

进阶提示

失败反馈

但不直接在默认 HUD 显示完整解法。

### 必须实际验证

完整路线：

Spawn

→ Orientation Loop

→ Face Lock

→ World Shift Gate

→ Perspective Fork

→ Forward Drop

→ Roll

→ Goal

验证：

正常通关。

Reset 后通关。

至少一种不同合法路线或不同操作顺序。

错误姿态不激活机关。

未解锁不能 World Shift。

错误 Camera 不通向预期目标。

不存在未授权捷径。

不存在无法恢复的非设计软锁。

正式 Solver 能提供至少一条合法解决路径。

自然图形演示与 Runtime 状态一致。

完成状态：

`RUBIK_SPATIAL_PUZZLE_01_PLAYABLE`

## 十、设计和 Obsidian 交付

13 Game Design 必须将本轮成果记录到已有 Obsidian Vault：

`E:\obsdian\青澄的水泥房`

先检查既有文件，使用项目现有目录结构。

记录：

1. 四项功能的最终规则
2. 每个功能的最小原型
3. 机制之间的依赖关系
4. 综合谜题的关卡设计
5. 玩家应该掌握的知识
6. 失败过的设计方案
7. 实际技术限制
8. 本轮实现与原始构想的差异
9. Solver 与 QA 结果
10. 下一批机制的建议

禁止将尚未实现或未验收的能力写为 PASS。

保留问题与思考过程。

如果 Obsidian Vault 未找到，先保留版本管理下的 Markdown 交付，报告路径阻塞；不要创建另一个未经确认的 Vault。

## 十一、并发执行与集成策略

推荐并行安排：

**13 Design**

输出正式规则和教学方案。

**09 Map**

先实现 Orientation Loop 和 Perspective Fork 地图。

Face Lock 实验地图先使用正式合同约定的数据结构准备，等待机制接口接入。

**01 Runtime**

审计 World Shift Gate 和 Face Lock。

只有确认缺少能力时才做最小实现。

Perspective Fork 优先复用 Perspective Fall v2。

**03 Quality**

同时建立专项测试。

先测试现有能力，后测试新增能力。

**00 Integration**

持续接收小批量交付。

不要等待所有 Owner 完成后才第一次合并。

顺序：

基础规则与合同

→ 独立地图

→ 最小 Runtime 扩展

→ 机制接线

→ 综合实验谜题

→ 自动化验证

→ 独立 Build

如已存在相同能力或测试，不重复开发。

## 十二、质量门禁

每项机制分别报告：

UNIT

REAL_RUNTIME

SOLVER

SAFETY

REPLAY

GRAPHICAL

INTEGRATION

HUMAN_QA

明确区分各类证据。

Real 和 Graphical 不允许使用模拟 Gameplay 结果冒充正式 PASS。

Human QA 需要真实玩家操作证据。

如果没有符合条件的试玩者：

`HUMAN_QA = NOT_RUN`

不因此伪造验收结果。

重点保护：

- 旧五关真实玩法
- 六面 Orientation
- World Shift
- Perspective Connection
- Perspective Fall
- Forward Drop 黄色 TOP 落地
- Save / Continue
- Game Shell
- 现有正式机制合同

只运行受影响范围的回归。

不要无理由重跑全部 Foundation 测试。

## 十三、构建要求

完成技术集成后生成独立实验 Build。

Build 应有：

- 正式 Godot 4.7.2 项目
- 可直接打开的 project.godot
- 正确的 Main Scene
- 四项机制独立实验入口
- 综合谜题入口
- 实际启动脚本
- Build Source SHA
- QA Handoff
- 测试报告
- 已知限制

最好在 Godot 编辑器中直接按 F5 就能够进入该实验项目的测试入口。

但不得为了实现这点直接覆盖：

`E:\godot\worktrees\block-girl-editor-dev`

也不得修改已冻结的五关 Beta Build。

不得将新实验关卡直接注册为正式 L07 或 L08。

新机制通过验收后，再考虑正式内容编排。

## 十四、Git 与版本保护

允许在本任务专用开发分支提交成果。

每个 Owner 按其文件范围提交。

00 最后进行正式集成提交。

禁止：

- 修改 main
- 修改已发布 Release 分支
- 移动或覆盖发布 Tag
- Force Push
- 重写已有共享历史
- 删除旧 Worktree
- 覆盖旧 QA Build
- 删除用户现有 Art 文件

本轮：

`Push = NOT_RUN`

`Merge to main = NOT_RUN`

不要将实验性新机制直接推送 GitHub。

## 十五、最终交付报告

任务完成后输出：

`SPATIAL_PUZZLE_BATCH_01_FINAL_REPORT`

**Git / Baseline**

Development Worktree:  
&lt;实际&gt;

Branch:  
&lt;实际&gt;

Base SHA:  
&lt;实际&gt;

Integration Commit:  
&lt;实际SHA&gt;

Working Tree:  
&lt;实际&gt;

**四项功能**

World Shift Gate:  
PASS / PARTIAL / BLOCKED

Orientation Loop:  
PASS / PARTIAL / BLOCKED

Face Lock:  
PASS / PARTIAL / BLOCKED

Perspective Fork:  
PASS / PARTIAL / BLOCKED

**综合关卡**

RUBIK_SPATIAL_PUZZLE_01:  
PLAYABLE / PARTIAL / BLOCKED

Full Playthrough:  
&lt;实际&gt;

Reset:  
&lt;实际&gt;

Solver:  
&lt;实际&gt;

Safety:  
&lt;实际&gt;

Replay:  
&lt;实际&gt;

Graphical:  
&lt;实际&gt;

Human QA:  
&lt;实际或NOT_RUN&gt;

**回归**

L01–L05:  
&lt;实际&gt;

Perspective Fall:  
&lt;实际&gt;

World Shift:  
&lt;实际&gt;

Orientation:  
&lt;实际&gt;

Game Shell:  
&lt;实际&gt;

**交付**

Godot Project:  
&lt;绝对路径&gt;

Playable Build:  
&lt;绝对路径&gt;

Launch Script:  
&lt;绝对路径&gt;

Obsidian Notes:  
&lt;实际路径&gt;

Design Documents:  
&lt;实际&gt;

Visual Evidence:  
&lt;实际&gt;

New Defects:  
&lt;实际&gt;

Known Limitations:  
&lt;实际&gt;

Push:  
NOT_RUN

最终只有满足真实集成门禁时，才声明：

`SPATIAL_PUZZLE_BATCH_01_PLAYABLE_READY`

如果存在未完成部分，输出：

`SPATIAL_PUZZLE_BATCH_01_PARTIAL`

详细说明：

已完成什么；
没有完成什么；
为什么未完成；
受影响的 Owner；
下一步最小修复动作。

**不要为了得到漂亮的报告而虚构 PASS。**

本轮目标是交付一个真正可以在 Godot 中操作的空间魔方式谜题，而不是一份规划文档。

请现在开始执行，不要停留在方案讨论阶段。