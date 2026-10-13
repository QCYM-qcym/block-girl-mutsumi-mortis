# 09 地图语义与 roof 可读性审查

2026-10-13，`SPATIAL_PUZZLE_ACCEPTANCE_CONTINUATION_02`。基线 `295a4702aeb17d6fced11cfdaa221e0ffa90dd12`。结论：**roof 是当前谜题必要的非行走遮光体；可读性方案待用户选择/审核，未实施。** 本报告不关闭玩家验收或输入缺陷复验。

## 正式语义核验

权威地图是 `experiments/spatial_puzzle_batch_01/maps/authoring/world_shift_gate_lab/{level,surface,inner}.tscn`，不是旧 `prototype/perspective-fall-01` 或旧脚本工厂。22 个作者文件所在的已集成空间线沿用本轮固定基线；没有从旧附件恢复生产资源。

| 对象 | 正式位置 / 属性 | 用途 |
|---|---|---|
| roof | Surface / layer 0；center2 `(2,12,0)`；orientation 0；`occludes_light=true`；face 0–5 全部 `walkable=false` | 遮光，不是目标或承接台 |
| gate | Surface；center2 `(2,4,0)`；TOP 可行走 | 正式 `enter` 的起点 |
| inner_gate | Inner；与 gate 的 TOP anchor 对应 | `enter` 落点及 `leave` 起点 |
| source → gate → inner_gate → goal | 既有见证 MOVE 0 → SHIFT_WORLD → MOVE 3 | 不包含向 roof 攀登或坠落 |

`surface.tscn:171` 的 roof 原始 transform 平移为 `(1,6,0)`，cell_size=1，对应双精度格单位 center2 `(2,12,0)`。实际解析六个 Face subresource 引用，面编号集合精确为 0–5 且全部不可行走；不是只看节点名。作者 root layer=0，天空 Slot 的 position2 为 `(0,30,0)`。精确摘要和解析结果见 [SOURCE_REVIEW.json](SOURCE_REVIEW.json)。

### 为什么需要遮光

`puzzle_rule_kernel.gd:130–151` 先检查 Gate、映射、出入面阻挡，再在 Surface 出发时要求 `Derived.light(...).light_state == SHADOW`，否则 `SHIFT_REQUIRES_SHADOW`。阴影是必要条件，不代替 Gate、映射或 Safety。Inner 返回没有这条 Surface 光照前置条件，不能把 roof 推广成两个世界共同的通行障碍。

`logical_lighting.gd:28` 只取 anchor 同层且 `occludes_light` 的 cube；`surface_geometry.gd:83` 以 center2+normal 得出 gate/TOP anchor `(2,5,0)`。光源 `(0,30,0)` 到此 anchor 的线段为 `(2t,30−25t,0)`。roof 的正式遮挡盒为 x `[1,3]`、y `[11,13]`、z `[-1,1]`；当 y 在 13→11 时，t 在 17/25→19/25、x 在 34/25→38/25，线段穿过盒内部。其余 Surface cube 是 source 与 gate，不能在这段光路上替代 roof：source 的 x 范围止于 1，gate 的顶部只是接收端点。

因此在当前固定光源、世界姿态和几何下，roof 提供 gate/TOP 所需的遮挡。移除 roof 或关闭 occludes_light 会使该出发面的光路变为 FRONT_CLEAR，破坏现有 Surface→Inner 正式解法。这是根据实际规则与精确坐标作出的静态因果推导；本轮未运行删 roof 的 Runtime 消融实验，未将推导冒充新的引擎测试。旧地图设计文件也明确要求此物体可见，不得用隐藏遮光体解释规则。

## 画面观察及证据边界

实际查看两张历史 Surface EAST / 1280×720 原图：`evidence/package_graphical_01/world_shift_gate_lab_1280x720.png` 和较新的 `evidence/full_pkg_menu02/world_shift_gate_lab_1280x720.png`。后者来源为 Build Source `59531adcdffb7a8671bd6aab9a2abdc6fa830b04`，不是新输入修复 Build 的截图。原图未修改、未复制成新渲染验收。

可见一个完整灰蓝立方体悬在道路上方，其完整顶面与三面轮廓仍像平台；下方是青色“转换点 · Space”和道路。没有看到 roof 专属用途文字或连接其遮光因果的提示。这只描述所查看的初始帧，不宣称其他状态没有反馈。

源码解释了视觉相似来源：父 Host `core_lab.gd:151` 对 cube 统一创建 BoxMesh；子 Host `spatial_lab.gd:105–110` 将无可行走面的物体设为 `#424b5b` 并标记 `NON_WALKABLE_OCCLUDER`，保留同样的立方体轮廓。已有颜色区分不能等同于玩家知道用途。`spatial_lab.gd:136` 的青色 Gate marker 只表示作者连接点存在，不宣称当前满足全部许可。

用户在 USER_FEEDBACK_05 中已明确确认 roof 身份并尝试登上它，因此这是有来源的可达性误读反馈；尚未定级为新的通行 Bug。00 已向用户解释用途，此后的 roof 理解属于辅助理解，不能算盲玩自发理解。

覆盖：历史 Surface EAST 初始画面已看；Surface NORTH/SOUTH/WEST 同状态 roof 读图、Inner 返回时恢复可读性、移动/转视角过程、其他分辨率和新 Build 图形复验均 UNKNOWN / NOT_RUN。本轮不启动 GUI，也不从技术四方向输入 PASS 推导画面四方向 PASS。

## 最小候选方案（均未实施）

共同约束：不改 BoxMesh 外形尺寸/位置、地图 geometry、Face/Anchor、walkable、occludes_light、连接、光源、正式解法或四向 Camera。只谈后续经批准的表现；由 00 安排 Host 接线、05 审核表现资产，09 不代写其文件。

| 方案 | 轮廓 / 材质 | 透明度 | 反馈影响与代价 |
|---|---|---|---|
| A：不透明遮光体表面语汇（推荐先试） | 保持完整轮廓；在顶面及侧面加连续斜纹/粗糙暗面，明确区别于道路平整顶面；以明暗和纹理双重区分，避免只换颜色。边缘不使用落脚台高亮线或可攀爬梯纹 | 保持不透明 | 被动观察即可识别“非道路”，最少新增 UI；未必独立解释遮光功能。图案必须在 960/1280 下仍可辨、不与角色六面符号混淆；不伪造光照许可 |
| B：用途标识与按需因果说明 | 保持现有轮廓和材质，在 roof 自身侧旁增加中性身份标签“遮光体 · 不可站立”；启用 H 提示时补充“遮挡光线形成转换点所需阴影”，归属于 roof 与地面 gate 各自位置 | 保持不透明 | 语义明确，适合教学；会增加文字、重叠和剧透风险。不要把标签放进 roof–gate 空隙造成新台阶/竖直通路错觉；普通玩家提示不暴露 cube_id。提示后理解必须记为辅助。若显示“当前可切换”，必须来自正式 Runtime 查询结果，而非颜色/距离推算 |

A 与 B 是可分别批准的方案，不默认叠加。建议先审核 A 的两张固定视角静态提案，再选择是否需要 B 的按需解释；本轮未创建这些图稿。用户也可选择 B 优先来直接降低教学歧义。

透明化评估：全体透明/隐藏不是本轮推荐方案。即便只改渲染 alpha、保持正式遮挡不变，也可能制造“光能穿过却判定阴影”的矛盾，削弱物体存在感和非道路识别。仅在将来证实 roof 遮住角色时，才讨论短暂局部淡化；须保留可辨轮廓与遮光身份并复核深度排序、透明面重叠及四视角。不能用透明处理替代材质/用途反馈，更不能修改 logical occlusion 来追随透明度。

轮廓改造如薄板、镂空、移动屋顶或添加支柱，可能改变视觉光路、可达性承诺或几何，本轮排除。特别是屋顶连接地面的线/柱容易被理解为可走路线。

## 待审批后的验证建议

用户选定方案后再由对应 Owner 实施：对固定四视角、两世界/返回、Reset、不同分辨率及角色处于 gate 时保存对比画面；核对改动前后正式关卡 hash / StateKey / witness 不变，合法 Shift 和非法输入仍按现有规则处理。盲玩向新参与者只问“哪些地方能站？上方物体做什么？”先记预测，不先教答案；提示使用和未经提示理解分开。没有新玩家数据前，不报告改善率或 roof 问题已关闭。

## 交付状态

只读地图语义审查：COMPLETE。静态作者属性检查：PASS。视觉改进：PENDING_USER_SELECTION / NOT_IMPLEMENTED。Gameplay / Solver / 新 Runtime 消融 / GUI / Human QA：NOT_RUN（本轮只读审查）。接受 `acceptance_01/FINAL_REPORT.md` 的 PARTIAL 边界：历史 908-state / 3916-edge 图只覆盖 GOAL_TERMINAL_FORMAL_ACTION_API，post-Goal domain UNKNOWN；P1 仍待图形/真人复查，不因本报告关闭。

工作树审计见 [WORKTREE_AUDIT.json](WORKTREE_AUDIT.json)。复用干净的 `block-girl-spatial-authoring-maps-02`，新建 `docs/spatial-map-continuation-02` 于指定基线；保留旧分支。其它 Dirty 工作树只读取 Git 状态，无覆盖、恢复、清理或导入。05 并行 Art 目录和外部资产完全不写。

本阶段仅新增 `docs/beta-sprint/spatial-puzzle-batch-01/map/continuation_02/**`。生产地图/Runtime/Foundation/Art 改动 NONE。普通 Push 文档分支后核验完整 SHA，00 决定接收；具体提交与远端收据由交付消息提供。方案审批属于后续动作，本次未请求或获得实施许可。
