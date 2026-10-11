# SPATIAL_PUZZLE_BATCH_01_DESIGN_SPEC

任务：SPATIAL_PUZZLE_BATCH_01_FULL_DEVELOPMENT，阶段1，Owner 13。核验日期：2026-10-11（Asia/Shanghai）。

基线：`feat/spatial-puzzle-batch-01@58a157ea9680159b76410c2929c1636b3ccdbe61`。本规格收束已有 Obsidian 设计及基线实际实现，供阶段2复用；不新增玩法，不替代原笔记及失败记录。来源内容身份见 [SHA清单](SPATIAL_PUZZLE_BATCH_01_DESIGN_SOURCES.json)。本轮交付仅此规格与清单，未更改 Godot、地图、正式关卡、测试或 Vault。

## 状态与输入合同

| 规划维度 | 正式含义 |
|---|---|
| Position | `player.location` 的 layer、cube_id、face；不同世界的同坐标不是同一位置 |
| Orientation | 角色 Cube24 整数物理姿态；由正式 Roll 改变 |
| World State | 所在 layer 及世界状态；角色 Shift 与世界旋转分别处理 |
| Camera State | 离散 quadrant 0–3；不改变角色物理姿态 |
| Mechanism State | 已声明机制状态；本批 `contact_lock` 从 idle 到 latched |

玩家用 WASD/方向键通过屏幕输入映射提出正式 MOVE；Q/E改变离散 Camera。Space 主动提出 SHIFT_WORLD，R完整 Reset，Esc Pause。F快捷键固定提出正式 U_NEG，不能把它等同所有视角的某个 WASD 键。以下路线用正式 FaceAxis 表述：U_POS=0、V_POS=1、U_NEG=2、V_NEG=3；执行时按当时 Camera 映射到屏幕输入。

World Shift 是角色跨世界；World Echo 是跨世界机关影响，不自动移动角色。自动 Shift、World Echo、六面拓印及其他候选不属于这四机制实现范围。UI、音效、动画只读取正式结果，不决定合法性、落点或成功。

采用既有 [正式合同](../CONTRACT.md) 与 [Runtime接口](../RUNTIME_INTERFACE.md)，以 [现有地图定义](../../../../experiments/spatial_puzzle_batch_01/maps/map_factory.gd) 和 [正式空间规则](../../../../foundation/rules/spatial_puzzle_rules.gd) 核对。Gate、Lock及综合图采用 schema4 / foundation.spatial_puzzle.v1 / cube24.v1 / foundation.rules.spatial_puzzle.v1，显式声明 shift_gates、face_locks 数组；独立Loop/Fork实验保留 schema3 / foundation.game_feel.v2。不得为统一文档把旧图写成 schema4，或给旧版本加入未声明新字段。

## 01 World Shift Gate

**玩家目标：**规划到达合法转换点的路线；必要时先取得机关权限，再主动转入另一世界。任意位置按 Space 自由切换不是本批规则。

**输入：**移动到 gate source Face 后按 Space。固定点无需机关条件；机关激活型先完成全部 required_flags / required_mechanism_states，再回合法点按 Space。姿态限定型在本批由 Face Lock 正确接触后锁存权限实现，传感器与转换点分开；不声称 Gate 本身每次检查 required_local_face。

**状态变化：**有效 Shift 改变 player layer/location，保留精确 Orientation 和 Camera。单向记录只授权 source→target；双向必须另声明反向 Gate。权限通过后仍需原始、未过滤的 UNIQUE SAME_NORMAL 映射，Surface离开需真实 SHADOW，退出/进入阻挡与正式 Safety 均有效。声明目标不能消除几何歧义或变成传送捷径。

**失败条件：**无 Gate 2010、条件未满足2011、声明目标与正式映射不符2012；映射、Shadow、阻挡及 Safety 错误保留上游原因。拒绝时 next_state=null、changed=false，不提交、不消耗权限、不改姿态。自动切换是后续显式例外设计，本批未提供该例外能力。

**教学方式：**先显示合法锚点与 Space 提示，再展示锁定点及缺失条件。玩家停留、通过或开启机关都不替代确认。不可用反馈区分“无转换点”“未解锁”“目标不可用”；这是反馈要求，具体可理解性仍待 Human QA。

**谜题例子：**`world_shift_gate_lab`：source 经 U_POS 到 gate，Space 到 Inner 的 inner_gate，再 V_NEG 到 goal。另有 inner_gate→gate 反向记录。非可行走 roof 提供真实遮蔽，不能删去或改成隐藏补救地板。

**组合方式：**Face Lock 锁存开启返回起点的 Gate；Orientation Loop 决定接触前的姿态；Shift保留该姿态供后续路线使用。转换点限制使“先接触传感器→回锚点→确认→Inner分流”成为操作顺序，而非在传感器上随时换世界。

## 02 Orientation Loop

**玩家目标：**到达同一 Position 时主动选择不同 Orientation，为后续指定 local_face 接触准备姿态；位置到达不等于解谜成功。

**输入：**普通 MOVE/Roll；四角闭环使用 U_POS、V_NEG、U_NEG、V_POS。Camera只用于输入观察，不是姿态置换操作。

**状态变化：**每次真实 Roll 同时改变位置与 Cube24 姿态。相同起点下，[U_POS,V_NEG]与[V_NEG,U_POS]都到 corner，实际姿态分别20与14；闭环可回到 source而姿态变化。不可增加姿态 setter、动画补转或另一套旋转算法。

**失败条件：**选错路线可到对的位置但错误姿态；非法 MOVE 按正式规则拒绝。错误姿态本身不是掉落或死亡，也不能由 Camera“修正”。仍可逆向滚动或继续绕环调整；Reset恢复初始完整状态。

**教学方式：**用角色六面标记呈现两条路线到同一点后的差异，让玩家观察位置、Camera、物理姿态三者分别变化。起步提示不默认展开全部解法；H深层提示与解法需玩家主动请求。

**谜题例子：**`orientation_loop_lab`：从 source到 corner可选两条两步路。实验目标在环外，需要到 corner后在 NORTH Camera0执行 U_POS 的正式 Fall，而不是把 corner设为通关点。显示两种姿态对比再引出后续 Lock用途。

**组合方式：**Face Lock复用同一四角环，但只接纳其中正确接触路线。Gate位置固定在起点，迫使玩家从 sensor再滚回；综合图不能只记录“到过corner”而丢弃 Orientation 和机制状态。

## 03 Face Lock

**玩家目标：**以指定角色 local_face接触传感器，取得 latched权限。到达传感器位置或相同屏幕朝向不足以成功。

**输入：**普通成功 Roll进入 ENTER传感器；不新增 USE键或动作。第一次正确接触与该 MOVE原子提交；直接 USE此 ENTER-only机关被拒绝。

**状态变化：**采用抵达后姿态：`Orientation.apply(arrived.player.orientation, Geometry.face_frame(required_local_face).normal) == -host_anchor.frame.normal`。TOP支撑面传感器要求指定角色面物理向下；与屏幕DOWN、宿主FaceID、颜色无关。角色 local_face 为 FRONT0/BACK1/LEFT2/RIGHT3/TOP4/BOTTOM5；本图要求 RIGHT3。正确接触将 contact_lock 的 idle变 latched，一次提交；重复接触幂等，离开/Shift保持 latched，Reset恢复 idle。角色由显式 initial_state/latched_state确定，不依赖 allowed_states排列顺序。

**失败条件：**错误姿态的 MOVE仍成功，机制保持 idle，不能把它写成移动拒绝。未锁存时 Gate拒绝。第一配置只支持普通Roll到达；传感器不得兼作 Shift / FaceTransition / Fall落点，或混合其他 ENTER效果。空间投影看似贴合不能替代正式接触判断。

**教学方式：**传感器给出 RIGHT符号及接触方向，角色六面标记可对照；错误接触给原因，正确接触给锁存反馈。反馈消费真实结果，不由 UI检查Face。先允许错误路线和绕环重试，再提示离开后权限仍保留。

**谜题例子：**`face_lock_lab`：source→corner的[U_POS,V_NEG]抵达姿态20，idle不变；[V_NEG,U_POS]抵达姿态14，锁存。正确后[V_POS,U_NEG]回 source，在此 Space到 Inner goal。反向 Gate无锁存要求，保证已换世界可以返回；初始在source按Space不能绕过传感器。

**组合方式：**Loop准备姿态，Lock授予权限，固定 Gate消费权限但不重置姿态。这是“姿态接触机关后解锁转换点”的已实现方案；接触即自动 Shift或必须在Gate保持某姿态属于未交付语义，不加入本规格。

## 04 Perspective Fork

**玩家目标：**在同一个 source Face/edge通过 Camera选择合法 Fall target；规划直接到目标或先到恢复支路再返回。不靠随机目标或 UI选择落点。

**输入：**Q/E选择 Camera，再提出同一正式 U_NEG MOVE。EAST1选 target_a；SOUTH2选 target_b；NORTH0/WEST3无此合法落点。屏幕方向随 Camera变化，核心比较必须保持同一正式 Source Edge和MOVE。

**状态变化：**普通 Roll有合法邻居时仍优先；无普通Roll才解析 Camera条件化 Fall。正式 ForwardAdvance→EdgeLeave→Descend→Landing，保留物理 Orientation和所在 layer；只改变合法落点 Position。角色世界不随错视投影改变。

**失败条件：**无匹配Camera目标2101、跨世界目标2102、非行走目标2100等按正式规则拒绝；资格重叠应在Baker拒绝，而非运行时挑一个。真实 Safety检查轨迹/落点；Camera只参与合法连接条件。不能用隐藏地板、动画瞬移或自动 Shift救援。

**教学方式：**保持source位置与姿态，先切 Camera比较连接/落点提示，再执行同一边动作。非法 Camera显示原因；合法反馈和拒绝回弹均来自正式提案结果。B支路显式展示回到source的方法，避免玩家把非目标支路理解为必死。

**谜题例子：**`perspective_fork_lab`初始EAST1：U_NEG到 target_a，再 U_POS到 goal。SOUTH2：U_NEG到 target_b，U_POS到 return平台，改NORTH0后 U_POS正式Fall回 source；再改EAST1走A。Camera转换不改变姿态，因此B支路不会替代Loop求姿态。

**组合方式：**《六面归位》把Fork放在Inner，只有正确Lock并在source确认Shift后才能访问；Surface没有这套Fall连接。B支路保留局部回退，再由双向Gate提供跨世界回退。UI不得直接把Camera按钮当作跨世界移动。

## 《六面归位》：已实现的完整操作顺序

level_id=`rubik_spatial_puzzle_01`。Surface四角环、corner/RIGHT传感器、source固定Gate；Inner的 inner_source和Fork两支路；单一声明的 goal。目标没有新增完整姿态匹配、六面拓印或World Echo条件。门槛是机制锁存与正式Gate，不因“归位”名称扩大Goal判定。

1. Surface在source走[V_NEG,U_POS]到corner，正确RIGHT接触锁存；另一顺序到同位置但不会授予权限。
2. 走[V_POS,U_NEG]回source。锁存保留，Gate解锁；Space主动转到 inner_source，Orientation/Camera精确保留。
3. A路线：EAST1下 U_NEG Fall到 target_a，U_POS Roll到goal。现有作者路线计8项，其中EAST设置在初始Camera1时是noop；Solver删除该noop，FIRST_SHORTEST为7步。不能把作者步骤数当 Solver失败或重复计数。
4. B恢复路线：在 inner_source设SOUTH2，U_NEG到target_b，U_POS到return；设NORTH0，U_POS Fall回 inner_source；设EAST1，U_NEG到target_a，U_POS到goal。含共同前缀的作者记录13项。Inner→Surface反向Gate无锁存要求，必须在 inner_source按Space，不能任意B支路位置返回世界。

两个完整概念解法分别是A的“求姿态→接触→回锚点→跨世界→选直接分流”和B的“同前缀→选非目标分流→回source→改Camera→直接分流”。它们均复用现有地图，不生成新正式关卡。固定Gate使跨世界路线与滚动求姿态成为一体；Lock的锁存避免每次返回都必须重触；Fork提供局部恢复而不是靠Reset强制解谜。

## Reset、Softlock、Solver、Replay与反馈边界

R恢复完整初始 Position/Orientation/World/Camera/Mechanism，取消pending并退休旧身份；重复/延迟完成不得再次提交。Pause冻结待完成表现，退出卸载取消旧动作。Continue沿用实验最近关卡入口，恢复正式spawn，不能声称保存中途姿态/锁存快照。

Solver、Safety、Replay复用正式Kernel、Codec、StateKey及Trace，不复制BFS或另造状态表。内容身份包含Gate/Lock条件；完整状态包括姿态、机制状态和Camera。Replay按实际动作顺序重演，不能只比较终点。Safety消费真实候选运动。Gate失败、错误接触、Camera非法、重复锁存及Reset都需在对应状态检查。

基线已有09完整图证据：Gate16状态/56边、Loop51/246、Lock104/472、Fork80/264、综合908/3916，均softlock0；Lock/综合的未锁Inner绕过0。这是固定版本有限图验证，不外推为任意未来地图。03综合selected Safety / FIRST_SHORTEST不是独立全边权限census。保留03原完整图超时、stderr失败和所有修正前收据。

反馈要求为锚点身份、解锁条件、角色六面接触符号、锁存结果、Camera连接/合法落点、拒绝原因及可恢复路线。现有技术图形与输入验证覆盖其选定布局；适格玩家首次理解、符号可读性及提示学习效果未跑，不能写Human PASS。

## 可复用证据与下一阶段门禁

| 证据范围 | 基线实际结果及限制 |
|---|---|
| Runtime | [01最终交付](../runtime/FINAL_DELIVERY.md)：最终b78d07c，253新+1140旧断言；本轮未重跑 |
| Map/Solver/Softlock | [09地图报告](../maps/MAP_DELIVERY_REPORT.md)：五图290检查及上述完整图；完整图有自己的源版本，不改记最终Runtime重新全图运行 |
| Safety/Replay/QA | [03最终报告](../quality/FINAL_REPORT.md)：选定2547断言；五图正式Windows Replay487，选定natural947、mechanics500；只覆盖对应收据 |
| 矩阵 | 原98项：80PASS、8REFERENCE_PASS、10NOT_RUN；五项human、四项冗余selected_trace、一项combined.graph_permissions仍未跑，不把外部图引用改成03独立PASS |
| 最终可玩包 | [Build交接](../QA_HANDOFF.md)：源26603d5；复制包启动、三尺寸219、冷Continue11、旧五关206已有收据。是需Godot的源码可玩包，不是独立exe |
| 本轮13 | 文档范围、链接、来源SHA、字段及保留检查；Runtime/Solver/Safety/Replay/Graphical均NOT_RERUN，Human QA=NOT_RUN |

阶段1交付收束现有设计，阶段2由09保留拓扑/解法迁移正式Authoring资源及Adapter入口。当前 map_factory.gd按level_id拼作者Dictionary再经LevelBaker，并不满足本次“保存的正式地图作者资源入口”交付要求；能力接口已有不等于本批地图已经迁移。阶段3由01核验正式消费者，阶段4由03验证，阶段5由00集成并补空间Host到既有AudioDirector路由，阶段6由08运行Human QA。当前空间Host的音效接线仍待交付；本规格不记其PASS。

未解决项目：地图作者资源迁移及来源映射验收、Host音效接线及真实反馈验收、03未跑的独立census与冗余trace是否按本轮范围执行、Human首次理解与可读性。直接Gate姿态谓词、自动Shift、Echo/拓印不在本批，若以后立项需单独合同。00接收本设计提交前，Integration=PENDING_00；本规格不声明 SPATIAL_PUZZLE_BATCH_01_READY 或整个Beta验收完成。

Git交付采用独立 `design/spatial-puzzle-batch-01-spec`；最终Commit、Push及实查Remote SHA在阶段交付报告登记，避免文档伪造自引用SHA。历史脏设计树及三个Vault源文件保持原样，不回填原记录的Push NOT_RUN。
