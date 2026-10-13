# SPATIAL_PUZZLE_BATCH_01_ACCEPTANCE_01 · 05 原型可读性审查

2026-10-13。结论：**PARTIAL；Human QA = NOT_RUN；未批准 Art = PENDING_USER_REVIEW。** 本报告审核已有真实 Viewport PNG 和对应源码，不代表重新运行游戏或正式美术验收。

审查基线 `d3b131440600048006ccc7679962fb7fc546a63f`；Build 源码 `59531adcdffb7a8671bd6aab9a2abdc6fa830b04`，包名 `beta_spatial_puzzle_batch_01_full_20261012_01`。本分支只提交本目录文档。过程中的外部越界及有限恢复见 [范围偏离记录](SCOPE_DEVIATION.md)，不能据本分支差异为空就声称整个过程没有外部写入。

## 证据层级与覆盖

- **截图观察**：实际查看五张实验地图各 1920×1080、1280×720、960×720 的初始画面，共 15 张；另查看 11 张路线起止/关键帧。逐文件路径、尺寸、哈希及来源见 [清单](SOURCE_MANIFEST.json)。只读原图，没有重绘、生成或另做美化版本用于验收。
- **源码证据**：读取 Host、正式枚举/面坐标/锁存规则、保存作者资源及截图脚本；核验历史进程清单各 409 项来源与 Build 字节一致，当前 worktree 文本与 Build 在统一 CRLF/LF 后一致。该换行归一化检查不冒充逐字节相等。
- **历史技术记录**：[menu 报告](../../evidence/full_pkg_menu02/report.json) 219 checks、[routes 报告](../../evidence/full_pkg_routes01/report.json) 208 checks，均无 failures。两者是原记录，不计为本次重跑、独立玩家或新增 427 个唯一测试。
- **专家风险推断**：小字、遮挡、颜色歧义可能增加识别负担；没有观察数据时不能写成玩家已误解或卡关。
- **真人观察**：NOT_RUN。已知用户可安排符合条件的新玩家，但尚无可用原始观察记录。四项机制和综合关卡的理解、预测、探索时间、提示依赖、迁移均未验收。

本次只读重算 Build 清单全部 1,561 个文件哈希，无缺失或不符；不读写存档、不启动 Godot GUI、不修改 Build。完整四视角、错面/锁存/拒绝状态和时序体验仍有证据空缺。

## 四机制与综合关卡

| 项目 | 截图事实 | 源码/记录支持 | 可下结论与限制 |
| --- | --- | --- | --- |
| Gate | 三尺寸均看得到“转换点 · Space”；青色地面圆点提供落格定位，但在部分画面中被角色局部遮住 | Host 按 source_face_id 放置标记；静态颜色不宣称当前许可；拒绝原因有 HUD 文本分支 | 初始位置提示存在。未验证玩家能区分“有转换点”和“此刻可切换”；锁定/范围外拒绝画面待补 |
| Face Lock | “面 4 朝下”与橙色圆点可见；初始可见面为 5、3、1，要求面不在这三个面中 | required_local_face=3，角色与要求标签均以 index+1 显示；锁存由正式 Runtime 决定 | 数字映射自洽，不能把 3→4 误报为错一位。隐藏目标面的记忆负担是待测试假设；当前无原生六面符号正式接入证据 |
| Orientation Loop | 起点有数字面；两个已有 Goal 路线画面顶面数字分别为 2、3；部分侧面数字较暗 | 历史路线记录两条正式 solution，自然完成并校验最终姿态 | 图像具备区分姿态的线索；不能由通关记录推导玩家理解回环方法。暗面风险见 A02 |
| Perspective Fork | 所审初始图中两个承接区域均在画面内；出发边字样与角色局部相叠，960 高度为 720 的图尤为明显 | 源出发边的候选：Q1→target_a、Q2→target_b；实际权限还由正式 Fall 判定。黄色覆盖所有 authored 目标，包括回程目标 | 没看到所审视角完全隐藏两个候选的情况；未覆盖同一姿态四视角，不能判全视角合法目标可读性 PASS |
| 六面归位 | 初始 Surface 可见 Gate 与“面 4 朝下”；已有 Inner 落地帧显示分流空间 | 历史 east/south witness 分别为 8、13 步；其输入为 Runtime action API | 可串联机制的技术记录存在；缺乏从无提示观察到自主规划的真人证据，不作为整体解谜体验通过 |

代表原图：[Gate 960](../../evidence/full_pkg_menu02/world_shift_gate_lab_960x720.png)、[Lock 960](../../evidence/full_pkg_menu02/face_lock_lab_960x720.png)、[Loop 1280](../../evidence/full_pkg_menu02/orientation_loop_lab_1280x720.png)、[Fork 960](../../evidence/full_pkg_menu02/perspective_fork_lab_960x720.png)、[综合落地](../../evidence/full_pkg_routes01/rubik_spatial_puzzle_01_step6_landing.png)。

## 稳定 local_face 与当前显示数字

| Runtime 枚举 | local_face | 原生局部法线 | 原型显示数字 |
| --- | ---: | --- | ---: |
| FRONT | 0 | +Z | 1 |
| BACK | 1 | −Z | 2 |
| LEFT | 2 | −X | 3 |
| RIGHT | 3 | +X | 4 |
| TOP | 4 | +Y | 5 |
| BOTTOM | 5 | −Y | 6 |

依据 `foundation/contracts/foundation_types.gd:5`、`foundation/spatial/surface_geometry.gd:14`、`experiments/spatial_puzzle_batch_01/host/spatial_lab.gd:62`。Host 绑定局部面法线与 index；锁要求来自 `maps/authoring/face_lock_lab/contact_lock.tres:11`。`foundation/rules/spatial_puzzle_rules.gd:31` 使用正式 orientation 和接触面法线计算锁存。美术不复制该算法。

数字属于当前实验展示，不能据此批准 Wakaba 原生特征→六符号词典，也不把六色 BoxMesh 当正式角色；其与理想美术的差异不构成 Gameplay P1。

## P0–P3 记录

分级只用于本次可读性审查：P1 需有阻止必要进展且缺少替代信息的复现证据；P2 为有事实支持的局部表现问题；P3 为轻微整理问题。**确认项 P0=0、P1=0、P2=3、P3=0**，不代表全游戏没有 P0/P1。另有未分级假设，不混入缺陷计数。

| ID / 等级 | 事实与复现依据 | 影响推断 | 建议交由 00 处理与验收条件 |
| --- | --- | --- | --- |
| A01 / P2 | Fork 初始 PNG 的“F 边缘”字样与角色左侧数字面局部重叠；三个尺寸均可检查，以 960 图最明显。源码 `_marker` 对 MOVE_EDGE 使用低位 billboard | 可能混淆标签所属的边或干扰面号读取；尚无玩家误判记录 | 00/07 审核锚点或文字偏移，保持实际出发边绑定。补同姿态四视角与三尺寸，要求不遮数字、不指向另一条边；本轮不改 Host |
| A02 / P2 | Loop 1280 初始图右侧紫色面上的深色数字 4 明显弱于顶面 5；同类差异可见于已有其他帧 | 可能拖慢姿态辨认。这里是视觉比较，未测量对比率、未证明数字完全不可读 | 00/05 评估实验面号的描边/底板或受光表现；不要因此重做冻结角色。补四向、正反明暗面及真实大小辨认记录 |
| A03 / P2 | **SOURCE_CONFIRMED / GRAPHICAL_NOT_CAPTURED**：Host:144 锁存后把“面 N 朝下”整体替换为“已激活”。这是既有表现缺口，非新发现的 Runtime 错配 | 丢失屏上目标身份可能使成功原因难以复述；尚未看到匹配后 Surface 特写 | 先补仍在 Surface 的新匹配、锁存重入、复位帧；若复现，00 保留目标数字并追加状态，不改 required_local_face 或锁存条件 |

Face Lock 的 `goal_0.png` 已在 Inner；Surface 锁不在该世界画面中，不能用它证明锁存后符号消失。路线动态截帧只由 `test_capture.gd:49` 的 route_index=0 生成，不能冒充第二支路的动作证据。

未分级、待验证假设：

- Gate 的青色不随完整许可改变，玩家可能把“锚点存在”当作“现在可用”。源码已有“机关尚未激活”“请到标记的转换点确认”等拒绝反馈，不能误报为完全无拒绝提示。
- Fork 的黄色是所有作者目标的并集，起点也可能因回程成为黄色；不能按黄色给出当前合法答案。两个承接台缺乏稳定文字身份是否影响预测，需真人观察。若需增强辨识，先用中性身份标识或结构差异，不能加答案高亮连线或让美术选落点。
- 初始 Face Lock 要求的 4 不可见可能增加翻看/记忆需求；这本身也是姿态谜题的一部分，不能直接列为缺陷。

## 后续验收与状态

补证和真人观察需求见 [CAPTURE_AND_HUMAN_QA.md](CAPTURE_AND_HUMAN_QA.md)。只读资料整理已完成；**完整原型可读性验收 PARTIAL，任何美术修复 NOT_IMPLEMENTED，新的游戏运行 NOT_RUN**。

`FACE_LOCK_ART_ACCEPTANCE=PENDING_USER_REVIEW`；`SIX_FACE_SYMBOL_SET=PENDING_USER_REVIEW`；扩展包与其他未批准 Art 均 `PENDING_USER_REVIEW`。没有冻结、正式生产、资源接入、Gameplay PASS 或新 Build 的批准结论。
