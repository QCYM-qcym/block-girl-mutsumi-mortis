PROJECT:
Mutsumi Veilshift / 方块少女-若叶睦

TRACK:
00 Integration Coordinator

TASK:
SPATIAL_PUZZLE_BATCH_01_FULL_DEVELOPMENT

MODE:
BUILD / PARALLEL DEVELOPMENT / SAFE INTEGRATION

TARGET:
建立第一批空间魔方式解谜机制原型。

==================================================
一、背景
==================================================

GitHub Governance 已完成：

main:
7775d67c33e991e1db0f12f1c24df58d85786c69

治理规范已进入：

AGENTS.md
GIT_WORKFLOW.md
OWNER_BRANCH_POLICY.md

活跃Owner已开始遵循：

开发
→验证
→Commit
→Push
→Remote SHA Verify
→Integration Handoff


本阶段必须继续遵守该流程。

==================================================
二、开发目标
==================================================

建立：

SPATIAL_PUZZLE_BATCH_01


目标不是增加大量机关。

目标：

让玩家从：

“寻找道路”

升级到：

“规划空间状态”。

核心体验：

类似解魔方。

玩家需要考虑：

Position
Orientation
World State
Camera State
Mechanism State


==================================================
三、本阶段范围
==================================================

只开发：

四项机制：

--------------------------------------------------

01 World Shift Gate

世界转换限制。

规则：

不能任意地点Space切换。

必须：

合法转换点

或：

机关解锁后的转换点。


--------------------------------------------------

02 Orientation Loop

姿态置换环。

规则：

不同移动路线可以：

到达相同位置

但产生不同Orientation。


核心：

Position相同

Orientation不同。


--------------------------------------------------

03 Face Lock

六面机关锁。

规则：

到达机关位置不等于成功。

必须：

指定local_face

满足机关条件。


--------------------------------------------------

04 Perspective Fork

错视分流。

规则：

同一个Source Edge。

不同Camera。

不同合法Fall Target。


--------------------------------------------------

最终：

制作综合实验关卡：

RUBIK_SPATIAL_PUZZLE_01

《六面归位》

==================================================
四、Owner分工
==================================================


==============================
13 Game Design
==============================

职责：

定义玩法规则。

输出：

SPATIAL_PUZZLE_BATCH_01_DESIGN_SPEC


必须包含：

World Shift Gate规则

Orientation Loop规则

Face Lock规则

Perspective Fork规则


每个机制：

玩家目标

输入

状态变化

失败条件

教学方式

谜题例子

组合方式


禁止：

直接修改Godot生产代码。


完成后：

Commit

Push

Remote SHA Verify


==============================
09 Map & Spatial Design
==============================

职责：

制作实验地图。


建立：

ORIENTATION_LOOP_LAB

FACE_LOCK_LAB

PERSPECTIVE_FORK_LAB

RUBIK_SPATIAL_PUZZLE_01


要求：

独立实验地图。

禁止修改：

L01-L05。


地图必须使用：

正式地图作者系统。

禁止：

临时脚本硬编码。


验收：

地图可玩。

路线明确。

存在真正解谜。


==============================
01 Runtime
==============================

职责：

提供必要Runtime能力。


优先复用：

已有：

Cube Roll

Orientation

World Shift

Perspective Fall

Mechanism Kernel

Safety

Solver

Replay


禁止：

重复实现第二套机制系统。


------------------------------

World Shift Gate:

支持：

转换点身份

权限判断

机关条件

非法拒绝


------------------------------

Face Lock:

支持：

local_face条件

正式事件

Reset

Replay

Solver


------------------------------

Perspective Fork:

优先复用：

Perspective Fall v2


增加：

Camera条件化连接。


禁止：

随机选择目标。


完成：

Runtime tests。


Commit

Push

Remote SHA Verify


==============================
03 Quality
==============================

建立专项质量矩阵。


覆盖：

World Shift:

合法转换

非法转换

Reset


Orientation Loop:

同位置不同姿态

Replay

Save


Face Lock:

错误Face

正确Face

重复触发


Perspective Fork:

Camera A

Camera B

非法Camera


综合关：

完整路线。


输出：

SPATIAL_PUZZLE_BATCH_01_MATRIX


==============================
05 Art
==============================

本阶段只提供支持。


研究：

转换点视觉

Face Lock符号

落点提示

机关反馈


不得重新设计：

若叶睦角色

Surface/Inner母版

冻结资产。


==============================
07 UI
==============================

仅提供必要反馈：

World Shift不可用提示

Face Lock激活反馈

Perspective连接反馈


不得：

UI自行判断Gameplay。


==============================
10A / 10B
==============================

提供：

Fall表现复用

Edge Recoil反馈


不得：

修改Gameplay状态。


==============================
11 Audio
==============================

提供：

机制反馈音效：

World Shift

Face Lock

Perspective Fall


==================================================
五、开发顺序
==================================================


严格顺序：


阶段1：

13设计完成

↓

阶段2：

09地图原型

↓

阶段3：

01 Runtime能力

↓

阶段4：

03自动化验证

↓

阶段5：

00 Integration

↓

阶段6：

08 Human QA



不要并行开发存在强依赖的部分。


==================================================
六、技术限制
==================================================


禁止：

修改：

main

release tag

L01-L05正式内容


禁止：

硬编码：

关卡脚本判断

UI判断

动画判断


所有正式Gameplay：

必须进入：

Runtime

Safety

Solver

Replay


==================================================
七、Git要求
==================================================


每个Owner：

完成阶段后必须：

1.
git status


2.
确认branch


3.
Commit


4.
Push Owner Branch


5.
验证remote SHA


6.
提交Integration Handoff


报告：

Branch

Commit SHA

Push

Remote SHA


禁止：

Push main

Force Push

修改Release Tag


==================================================
八、Build要求
==================================================


完成集成后生成：

SPATIAL_PUZZLE_BATCH_01_BUILD


要求：

Godot 4.7.2

独立实验入口。


包含：

Orientation Loop Lab

Face Lock Lab

Perspective Fork Lab

Rubik Puzzle


支持：

F5启动。


==================================================
九、验收标准
==================================================


最终必须达到：

SPATIAL_PUZZLE_BATCH_01_READY


包含：


World Shift Gate:

PASS


Orientation Loop:

PASS


Face Lock:

PASS


Perspective Fork:

PASS


综合关：

RUBIK_SPATIAL_PUZZLE_01

PASS


自动验证：

Runtime PASS

Solver PASS

Safety PASS

Replay PASS


Graphical:

PASS/PENDING


Human QA:

NOT_RUN 或 PASS


==================================================
十、最终报告
==================================================


输出：

SPATIAL_PUZZLE_BATCH_01_FINAL_REPORT


包含：

Git:

Integration Branch:

Commit:

Remote SHA:


13 Design:

Status:


09 Map:

Status:


01 Runtime:

Status:


03 Quality:

Status:


05 Art:

Status:


07 UI:

Status:


10A:

Status:


10B:

Status:


11 Audio:

Status:


Build:

Path:


Known Issues:


Human QA:


Push:

SUCCESS/BLOCKED


禁止扩大PASS范围。

如果未完成：

输出：

SPATIAL_PUZZLE_BATCH_01_PARTIAL


说明：

已完成

未完成

阻塞原因

下一步动作。


现在开始执行。