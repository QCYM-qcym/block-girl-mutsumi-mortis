# VERTICAL_SLICE_ART_HANDOFF

交付日期：2026-10-06。范围：Batch 05 美术与运行呈现交接；本轮只生成本文档，不制作资产、不修改主游戏、不启动关卡集成。

## 1. 用户最终验收与证据优先级

本聊天用户最新明确结论为下列状态的批准依据：

```text
INNER_VISUAL_BASELINE_V01 = APPROVED
MECHANISM_ART_BASELINE_V01 = APPROVED
WORLD_SHIFT_VFX_BASELINE_V01 = APPROVED
WORLD_SHIFT_ROLL_VISUAL_CONTINUITY = PASS
VERTICAL_SLICE_ART_READY = YES
STAIR_CLEARANCE = PARTIAL_PASS
STAIR_TRAVERSAL = NOT_RUN
```

**ART READY 表示美术可移交，不表示完整 Gameplay PASS 或已完成原游戏接入。** 本轮未重跑引擎、物理或性能测试。本文引用的技术结果均保留原验证工程、日期阶段与范围。现有报告中的 VFX PENDING_USER_REVIEW / READY_FOR_REVIEW、Vertical Slice NOT_READY 是本次用户批准之前的历史状态；其视觉验收状态由本文上方用户结论取代，其技术事实不被更改。遵守“只执行 Handoff”，本轮不回写这些报告或资产 manifest。

正式发布根目录：`E:/Study/方块娘项目/若叶睦/model/art/production/releases/batch_05`。下文 `res://` 均相对此独立工程，不是原游戏的资源根。

## 2. 来源、目录与冻结边界

- Wakaba：v13，角色方向、尺度、六面与一格翻滚包络冻结。Mortis：已批准正式生产资产，与 Wakaba 共用逻辑占地、原点与枢轴。
- Surface：Composition v03 / Beauty v03 / Runtime approved；Inner 与机关：本次正式 V01 批准。不得因接入重新设计。
- 每资产目录：`<ID>/source/<ID>.blend` → `export/<ID>.glb` → `godot/<ID>.tscn`；配套 `textures/`、`showcase/`、`reports/asset_manifest.json`、`reports/validation.json`。
- 使用正式 wrapper 保留碰撞、锚点与状态脚本，不只拖入裸 GLB 后猜测逻辑尺寸。
- Source → Game Asset → Showcase 单向派生；不得另造展示专用模型。保留研发历史。
- 稳定身份为 asset_id；版本号只作修订信息。场景实例用 world_slot_id 维持同位置的两个 interpretation。

注册表：[registry/catalog.json](<E:/Study/方块娘项目/若叶睦/model/art/production/releases/batch_05/registry/catalog.json>)；完整元数据：[registry/runtime_catalog.json](<E:/Study/方块娘项目/若叶睦/model/art/production/releases/batch_05/registry/runtime_catalog.json>)；Schema：[schema/asset_manifest.schema.json](<E:/Study/方块娘项目/若叶睦/model/art/production/releases/batch_05/schema/asset_manifest.schema.json>)。

## 3. 正式角色 ID

| 角色 | 资产 ID | Godot wrapper |
|---|---|---|
| Wakaba | `BG_CH_WAKABA_CUBE_001` | [打开 wrapper](<E:/Study/方块娘项目/若叶睦/model/art/production/releases/batch_05/BG_CH_WAKABA_CUBE_001/godot/BG_CH_WAKABA_CUBE_001.tscn>) |
| Mortis | `BG_CH_MORTIS_CUBE_001` | [打开 wrapper](<E:/Study/方块娘项目/若叶睦/model/art/production/releases/batch_05/BG_CH_MORTIS_CUBE_001/godot/BG_CH_MORTIS_CUBE_001.tscn>) |

角色 Pair：Wakaba ↔ Mortis，是同一个逻辑角色的视觉解释，不生成第二个玩家。逻辑单位 1 m，Godot +Y 向上、+Z 向前，Blender 前向 -Y。底中心原点保持；实际 wrapper 一格 Box 碰撞中心位于局部 Y=0.5。不得把 visual bounds 当成逻辑占地或缩小碰撞以绕过净空问题。各自 manifest 的 logical / physics / roll 字段为具体契约依据。

## 4. Surface / Inner 正式环境与 Pair 映射

| 类型 | Surface asset_id | Inner asset_id |
|---|---|---|
| FLOOR | `BG_ENV_SURFACE_FLOOR_001` | `BG_ENV_INNER_FLOOR_001` |
| BRIDGE | `BG_ENV_SURFACE_BRIDGE_001` | `BG_ENV_INNER_BRIDGE_001` |
| ARCH | `BG_ENV_SURFACE_ARCH_001` | `BG_ENV_INNER_ARCH_001` |
| PILLAR | `BG_ENV_SURFACE_PILLAR_001` | `BG_ENV_INNER_PILLAR_001` |
| STAIR | `BG_ENV_SURFACE_STAIR_001` | `BG_ENV_INNER_STAIR_001` |

只有这五组成对环境是当前目录中的正式生产资产。注册表中 `BG_ENV_SURFACE_RAILING_001`、`BG_ENV_SURFACE_EXIT_001` 等 reserved ID 为 NOT_PRODUCED，不能视为可交付模块；当前出口使用下节正式 MEC EXIT。

## 5. 正式机关 ID 与 Pair 映射

| 类型 | Surface asset_id | Inner asset_id |
|---|---|---|
| PRESSURE_PLATE | `BG_MEC_SURFACE_PRESSURE_PLATE_001` | `BG_MEC_INNER_PRESSURE_PLATE_001` |
| GATE | `BG_MEC_SURFACE_GATE_001` | `BG_MEC_INNER_GATE_001` |
| MOVING_PLATFORM | `BG_MEC_SURFACE_MOVING_PLATFORM_001` | `BG_MEC_INNER_MOVING_PLATFORM_001` |
| ROTATING_PLATFORM | `BG_MEC_SURFACE_ROTATING_PLATFORM_001` | `BG_MEC_INNER_ROTATING_PLATFORM_001` |
| WORLD_SWITCH | `BG_MEC_SURFACE_WORLD_SWITCH_001` | `BG_MEC_INNER_WORLD_SWITCH_001` |
| EXIT | `BG_MEC_SURFACE_EXIT_001` | `BG_MEC_INNER_EXIT_001` |
| PATH_MARKER | `BG_MEC_SURFACE_PATH_MARKER_001` | `BG_MEC_INNER_PATH_MARKER_001` |
| RESET_MARKER | `BG_MEC_SURFACE_RESET_MARKER_001` | `BG_MEC_INNER_RESET_MARKER_001` |

配对契约：[registry/mechanism_pair_contracts.json](<E:/Study/方块娘项目/若叶睦/model/art/production/releases/batch_05/registry/mechanism_pair_contracts.json>)。每对保持 logical footprint、occupied/walkable cells、connection points、height contract、origin、pivot、clearance、state IDs 和 activation semantics 的兼容。Inner-only / changed path 由关卡 world-slot 可用性与拓扑控制，不得通过偷偷改写 Pair 逻辑契约实现。

## 6. Mechanism State Contract

以下从 Surface manifest 逐项读取；Inner 使用同名状态映射。collision_state 是契约语义，实际行为须由 Runtime 与主项目物理共同落实。

| 类型 | 状态 | collision_state | interaction_enabled | activation_semantic |
|---|---|---|---|
| PRESSURE_PLATE | `inactive` | `carrier_support` | `True` | `pressure_plate.inactive` |
| PRESSURE_PLATE | `pressed` | `carrier_support` | `True` | `pressure_plate.pressed` |
| PRESSURE_PLATE | `activated` | `carrier_support` | `True` | `pressure_plate.activated` |
| GATE | `closed` | `closed_blocker` | `True` | `gate.closed` |
| GATE | `opening` | `closed_blocker` | `False` | `gate.opening` |
| GATE | `open` | `open_passage` | `True` | `gate.open` |
| MOVING_PLATFORM | `idle` | `carrier_support` | `True` | `moving_platform.idle` |
| MOVING_PLATFORM | `moving` | `carrier_support` | `False` | `moving_platform.moving` |
| MOVING_PLATFORM | `arrived` | `carrier_support` | `True` | `moving_platform.arrived` |
| ROTATING_PLATFORM | `default` | `carrier_support` | `True` | `rotating_platform.default` |
| ROTATING_PLATFORM | `rotating` | `carrier_support` | `False` | `rotating_platform.rotating` |
| ROTATING_PLATFORM | `rotated_90` | `carrier_support` | `True` | `rotating_platform.rotated_90` |
| ROTATING_PLATFORM | `rotated_180` | `carrier_support` | `True` | `rotating_platform.rotated_180` |
| ROTATING_PLATFORM | `rotated_270` | `carrier_support` | `True` | `rotating_platform.rotated_270` |
| WORLD_SWITCH | `inactive` | `pedestal` | `True` | `world_switch.inactive` |
| WORLD_SWITCH | `available` | `pedestal` | `True` | `world_switch.available` |
| WORLD_SWITCH | `switching` | `pedestal` | `False` | `world_switch.switching` |
| WORLD_SWITCH | `completed` | `pedestal` | `True` | `world_switch.completed` |
| EXIT | `locked` | `open_passage` | `True` | `exit.locked` |
| EXIT | `available` | `open_passage` | `True` | `exit.available` |
| EXIT | `activated` | `open_passage` | `True` | `exit.activated` |
| EXIT | `complete` | `open_passage` | `False` | `exit.complete` |
| PATH_MARKER | `surface_only` | `carrier_support` | `True` | `path_marker.surface_only` |
| PATH_MARKER | `inner_only` | `carrier_support` | `True` | `path_marker.inner_only` |
| PATH_MARKER | `shared` | `carrier_support` | `True` | `path_marker.shared` |
| PATH_MARKER | `inactive` | `carrier_support` | `True` | `path_marker.inactive` |
| RESET_MARKER | `idle` | `pedestal` | `True` | `reset_marker.idle` |
| RESET_MARKER | `available` | `pedestal` | `True` | `reset_marker.available` |
| RESET_MARKER | `triggered` | `pedestal` | `False` | `reset_marker.triggered` |

实现与配置：

- [registry/mechanism_states.json](<E:/Study/方块娘项目/若叶睦/model/art/production/releases/batch_05/registry/mechanism_states.json>)
- [mechanisms/mechanism_visual.gd](<E:/Study/方块娘项目/若叶睦/model/art/production/releases/batch_05/mechanisms/mechanism_visual.gd>)
- [mechanisms/mechanism_runtime.gd](<E:/Study/方块娘项目/若叶睦/model/art/production/releases/batch_05/mechanisms/mechanism_runtime.gd>)
- [mechanisms/mechanism_config.gd](<E:/Study/方块娘项目/若叶睦/model/art/production/releases/batch_05/mechanisms/mechanism_config.gd>)
- 各类型配置：[configs/](<E:/Study/方块娘项目/若叶睦/model/art/production/releases/batch_05/mechanisms/configs>)，8 个 `.tres`；manifest 的 `config_resource` 指向具体文件。
- 锚点/节点：Visual、LogicalCarrier、GateBlocker（门）、InteractionArea、InteractionAnchor、AnimationAnchor、MotionStart/End、ConnectionPoints、StateViews、StateAnimations。按实际 wrapper 和 manifest 获取，禁止另猜位置。
- `bind_visual()` 初始化状态并连接 Area；`fulfill_condition()` 接外部条件；`transition()` 驱动中间态；`export_state()/import_state()` 保留 state_id、phase、activated。主项目仍需管理跨世界共享权威状态和 occupants 重建，不能只复制外观。
- Gate 的 closed/opening 均保持 blocker，只有 open 释放。Pressure Plate 的 pressed 与 activated 不同；条件/锁存来自 config。移动载客、随转、完成生命周期与完整复位不能因外观状态存在就判定通过。

## 7. World Shift Runtime 文件与接入依赖

| 入口/依赖 | 文件 |
|---|---|
| 运行场景 | [world_shift/runtime.tscn](<E:/Study/方块娘项目/若叶睦/model/art/production/releases/batch_05/world_shift/runtime.tscn>) |
| 切换控制及评审驱动 | [world_shift/runtime.gd](<E:/Study/方块娘项目/若叶睦/model/art/production/releases/batch_05/world_shift/runtime.gd>) |
| 重建材质 shader | [world_shift/reconstruction.gdshader](<E:/Study/方块娘项目/若叶睦/model/art/production/releases/batch_05/world_shift/reconstruction.gdshader>) |
| 继承的布局/相机光照基础 | [art_review/hero.gd](<E:/Study/方块娘项目/若叶睦/model/art/production/releases/batch_05/art_review/hero.gd>) |
| 工程渲染配置 | [project.godot](<E:/Study/方块娘项目/若叶睦/model/art/production/releases/batch_05/project.godot>) |
| 重新验证入口 | [ValidateWorldShift.ps1](<E:/Study/方块娘项目/若叶睦/model/art/production/releases/batch_05/ValidateWorldShift.ps1>) |
| Gallery 控件验证 | [tools/world_shift_gallery_validator.gd](<E:/Study/方块娘项目/若叶睦/model/art/production/releases/batch_05/tools/world_shift_gallery_validator.gd>) |

依赖所有被实例化正式资产的 wrapper、GLB、textures、manifest 和对应机关脚本；不得遗漏动态 load 引用。Gallery 默认场景资源设 `gallery_mode=true`，正式 Gameplay 必须关闭。

**当前代码是已批准视觉的独立运行验证场景，不是可直接替换主项目 World Manager 的完整系统：**

- `hero.gd.build()` 固定演示布局/slot ID，Gate 为 open、Plate 为 activated、Exit 为 complete；`prepare_assets()` 将 GateBlocker 禁用。接入时必须由真实机关状态决定，不能复制此初始开门设置。
- 当前 persistent 碰撞体来自 Surface 角色，Inner 体不启用；两视觉共用 actor 容器。接入时映射到主项目唯一玩家，不依赖“角色名字等于当前世界”的假设。
- `R` 的 1.2 秒连续 roll 是独立数学测试驱动，`review()` 还会安排姿态与截图；不能作为正式输入/移动/存档控制器。
- floor 分类依赖演示 slot 名，遮挡仅检查 gate/exit，射线坐标也来自固定布局；集成时改为正式 slot/碰撞/遮挡元数据适配，保持批准视觉行为，不重设计资产。
- 原验证只证明相同 Pair 几何契约的碰撞实例归属切换。新路径开放/消失、玩家落脚安全、机关跨世界持久化仍须主项目实现并重新测试。

## 8. Commit point 与视觉 / 逻辑 / 碰撞时序

`WORLD_SWITCH_COMMIT_POINT = 0.60`。Normal 目标 0.50 s；First Discovery 目标 0.80 s。物理 tick 中一次性提交，浮点阈值容差 0.00001。

| normalized progress | visual_state / 可见行为 | logical_state | collision_state |
|---|---|---|---|
| 0，稳定 | 旧世界完整 | 旧世界 | 旧世界 |
| 0–0.60 | 支撑/非行走结构退去与重建，短暂 overlap；新行走面 reveal=0 | 旧世界 | 旧世界 |
| 0.60，commit | 原行走面视觉开始让位，新解释取得逻辑权威 | 一次切为目标 | 同 tick 切为目标 |
| 0.60–0.93 | 新行走面按 smoothstep 展开 | 目标 | 目标 |
| 0.93–1.00 | 目标稳定，恢复正式材质并隐藏旧视觉 | 目标 | 目标 |

非行走重建前沿 smoothstep(0.08,0.96,p)，色彩/灯光过渡 smoothstep(0.16,0.95,p)；8 个小碎片只在约 0.12–0.90 可见，无碰撞，角色不受顶点位移。反向同规则。不得强白闪、黑场、震屏、RGB split 或大量粒子。

稳定世界由逻辑提交决定，不能由动画是否播放完、按钮文本或画面颜色决定。`request_shift()` 在 active 或请求当前世界时拒绝启动；正式玩法必须对取消、暂停、存档/重载、连续输入和提交事件幂等性重新验证。切换不得重置 position、orientation、current cube face、roll state、logical transform。

## 9. Camera / Lighting / Occlusion 要求

- 正式四方向离散正交镜头 0/90/180/270，相邻偏航差 90°；不是 Gameplay 自由相机。当前演示偏航起始 -28°，camera size=11.5，near=.01，far=100；target=(-.1,2,-.3)，偏移=(sin(a)*14,11,cos(a)*14)。这些世界坐标适用于该片段，主项目可适配 target/size，但需保持相近角色占屏尺度并重审四视角。
- 当前 Forward+、ACES；环境光 energy=.52，颜色(.76,.83,.92)；主光 energy=.52、rotation=(-48,-32,0)、angular distance=3；补光 energy=.22、rotation=(-28,145,0)。主光色从(1,.98,.91)到(.86,.93,1)，背景与底面随世界低饱和渐变。白石不过曝、暗部保留桥下结构、角色面部与出口可读。
- 遮挡采用 camera→actor+(0,.52,0) 与 Gate/Exit AABB（外扩.15）的相交判断；命中后可见 alpha≈.16，关闭该视觉投影，不改碰撞。当前只在 set_camera 时刷新，**正式移动角色时必须重新测试/适配动态更新与滞回，不能宣称已有通用遮挡系统**。
- 相机遮挡消隐与重建 shader 同时工作，不得让地面、角色或大量建筑持续透明；碎片不得挡脸、桥和出口。TAA/MSAA、透明排序、输出分辨率变化须实机重测。

## 10. Production Gallery 入口

- [Launch.ps1](<E:/Study/方块娘项目/若叶睦/model/art/production/releases/batch_05/Launch.ps1>)：启动 Gallery；`-WorldShift` 直达转场；`-ArtReview` 静态 A/B；`-Playground` 既有机关测试。
- [art_gallery/gallery.tscn](<E:/Study/方块娘项目/若叶睦/model/art/production/releases/batch_05/art_gallery/gallery.tscn>) / [art_gallery/gallery.gd](<E:/Study/方块娘项目/若叶睦/model/art/production/releases/batch_05/art_gallery/gallery.gd>)；点击 WORLD SHIFT VFX。
- PLAY SURFACE → INNER / PLAY INNER → SURFACE，Gallery-only LOOP，FIRST DISCOVERY；W 切换、1–4 相机、R 测试滚动、H 隐藏 UI、Esc 返回。
- 正式 Gameplay 禁止自动 LOOP。Gallery 使用同一套生产资产，Gallery 按键、测试布局与相机自由展示能力不定义正式玩法。

## 11. Game Shell UI Art Baseline 位置

目录：`E:/godot/若叶睦/方块少女-若叶睦/docs/art/BETA_UI_ART_DIRECTION_01`（本轮只读核实）。

- 批准依据：[ART_ACCEPTANCE_RECORD.md](<E:/godot/若叶睦/方块少女-若叶睦/docs/art/BETA_UI_ART_DIRECTION_01/ART_ACCEPTANCE_RECORD.md>)；`GAME_SHELL_UI_VISUAL_BASELINE = APPROVED`，Main Menu / Level Select / Pause ART PASS。
- 系统：[UI_DESIGN_SYSTEM.md](<E:/godot/若叶睦/方块少女-若叶睦/docs/art/BETA_UI_ART_DIRECTION_01/UI_DESIGN_SYSTEM.md>)；资源：[tokens.json](<E:/godot/若叶睦/方块少女-若叶睦/docs/art/BETA_UI_ART_DIRECTION_01/tokens.json>)、[icons.svg](<E:/godot/若叶睦/方块少女-若叶睦/docs/art/BETA_UI_ART_DIRECTION_01/icons.svg>)。
- 原三页：[10_main_menu.svg](<E:/godot/若叶睦/方块少女-若叶睦/docs/art/BETA_UI_ART_DIRECTION_01/10_main_menu.svg>)、[20_level_select.svg](<E:/godot/若叶睦/方块少女-若叶睦/docs/art/BETA_UI_ART_DIRECTION_01/20_level_select.svg>)、[30_pause.svg](<E:/godot/若叶睦/方块少女-若叶睦/docs/art/BETA_UI_ART_DIRECTION_01/30_pause.svg>)；同名 PNG 为评审稿。
- 扩展：[extensions/EXTENSION_SPEC.md](<E:/godot/若叶睦/方块少女-若叶睦/docs/art/BETA_UI_ART_DIRECTION_01/extensions/EXTENSION_SPEC.md>)；Settings / Level Complete / Hint 当前是 ACCEPTANCE_PENDING，不得把父基线批准自动扩展为三页 PASS。
- 「石拱之间」：象牙白底、海军蓝字、低饱和 sage/cyan、中文标题/克制英文小型大写、大留白、细线、selected/focus bracket；Inner 只做同系统世界状态变体，不另改布局。
- 这些是 UI 美术稿，不是已接入运行截图。GAME_SHELL_INTEGRATION = NOT_RUN；主项目须重新验证 Continue 存档状态、World State 共源、暂停、键盘/手柄 focus、16:9 及必要适配。

## 12. 当前 ART / PRODUCTION / GAMEPLAY Matrix

以下按当前 28 份正式 manifest 逐项转录。PRODUCTION/GAMEPLAY 的 PASS 只限原验证工程与其证据范围，不继承为主项目 PASS。

| asset_id | ART | PRODUCTION | GAMEPLAY |
|---|---|---|---|
| `BG_CH_WAKABA_CUBE_001` | PASS | PASS | PARTIAL_PASS |
| `BG_CH_MORTIS_CUBE_001` | PASS | PASS | PARTIAL_PASS |
| `BG_ENV_SURFACE_FLOOR_001` | PASS | PASS | PASS |
| `BG_ENV_SURFACE_BRIDGE_001` | PASS | PASS | PASS |
| `BG_ENV_SURFACE_ARCH_001` | PASS | PASS | PASS |
| `BG_ENV_SURFACE_PILLAR_001` | PASS | PASS | PASS |
| `BG_ENV_SURFACE_STAIR_001` | PASS | PASS | PARTIAL_PASS |
| `BG_ENV_INNER_FLOOR_001` | PASS | PASS | PASS |
| `BG_ENV_INNER_BRIDGE_001` | PASS | PASS | PASS |
| `BG_ENV_INNER_ARCH_001` | PASS | PASS | PASS |
| `BG_ENV_INNER_PILLAR_001` | PASS | PASS | PASS |
| `BG_ENV_INNER_STAIR_001` | PASS | PASS | PARTIAL_PASS |
| `BG_MEC_SURFACE_PRESSURE_PLATE_001` | PASS | PASS | PASS |
| `BG_MEC_INNER_PRESSURE_PLATE_001` | PASS | PASS | PASS |
| `BG_MEC_SURFACE_GATE_001` | PASS | PASS | PASS |
| `BG_MEC_INNER_GATE_001` | PASS | PASS | PASS |
| `BG_MEC_SURFACE_MOVING_PLATFORM_001` | PASS | PASS | PARTIAL_PASS |
| `BG_MEC_INNER_MOVING_PLATFORM_001` | PASS | PASS | PARTIAL_PASS |
| `BG_MEC_SURFACE_ROTATING_PLATFORM_001` | PASS | PASS | PARTIAL_PASS |
| `BG_MEC_INNER_ROTATING_PLATFORM_001` | PASS | PASS | PARTIAL_PASS |
| `BG_MEC_SURFACE_WORLD_SWITCH_001` | PASS | PASS | PARTIAL_PASS |
| `BG_MEC_INNER_WORLD_SWITCH_001` | PASS | PASS | PARTIAL_PASS |
| `BG_MEC_SURFACE_EXIT_001` | PASS | PASS | PARTIAL_PASS |
| `BG_MEC_INNER_EXIT_001` | PASS | PASS | PARTIAL_PASS |
| `BG_MEC_SURFACE_PATH_MARKER_001` | PASS | PASS | PARTIAL_PASS |
| `BG_MEC_INNER_PATH_MARKER_001` | PASS | PASS | PARTIAL_PASS |
| `BG_MEC_SURFACE_RESET_MARKER_001` | PASS | PASS | PARTIAL_PASS |
| `BG_MEC_INNER_RESET_MARKER_001` | PASS | PASS | PARTIAL_PASS |

矩阵来源：[reports/ARTAcceptanceMatrix.json](<E:/Study/方块娘项目/若叶睦/model/art/production/releases/batch_05/reports/ARTAcceptanceMatrix.json>)；各资产 gameplay_evidence / warnings / clearance 见 manifest。Wakaba/Mortis、移动/旋转平台、World Switch、Exit、Path/Reset 等现有 PARTIAL_PASS 保持，不因 ART 批准提升。

World Shift 专项：用户视觉基线 APPROVED、ROLL_VISUAL_CONTINUITY PASS；工程记录仍是限定场景的提交/物理归属、两向姿态与四镜头测试，完整 Gameplay roll regression 和 topology 接入 NOT_RUN。

## 13. 明确 blockers 与未覆盖范围

- **STAIR_CLEARANCE = PARTIAL_PASS**：不能宣称所有滚动姿态和净空都成立。
- **STAIR_TRAVERSAL = NOT_RUN**：不能把阶梯模型美术通过当成角色跨高度可玩。
- 第一条可交付玩法链应先采用已验证的平面连续行走面；若依赖楼梯，则在可玩验收前解决并实测上述两项，不能通过缩小 cube、扩大逻辑落点或跳过碰撞绕过。
- 其他主项目未覆盖项：Inner-only/changed topology、Perspective/route puzzle、移动载客/随转、机关持久化、完整 reset/exit 生命周期、存档与 UI 接入。它们不是新增 ART blocker，但属于 Gameplay 接入验收责任。

## 14. 原游戏接入禁止事项

1. 不重做 Wakaba / Mortis，不改变已冻结角色视觉方向。
2. 不重新设计 Surface baseline，不重新设计 Inner baseline。
3. 不修改 Pair logical contract、occupied/walkable cells、连接点、枢轴、单位/原点或状态含义来迁就接入。
4. 不改变 Cube roll envelope，不缩碰撞体逃避 clearance。
5. 不让 World Shift 重置 orientation/current face/roll state/position；不以替换玩家节点实现回正。
6. 不把 Gallery 固定开门、预激活、循环或测试滚动驱动搬成正式规则。
7. 不用 ART approval 或技术原型截图替代完整 Gameplay PASS；不复制旧日志作为本项目执行结果。
8. 本次 Handoff 不授权修改原游戏、重构 Foundation、制作新资产或自动开始正式关卡集成；设计方向若需大改应先报告。

## 15. Vertical Slice 推荐最小链（仅建议，未执行）

Wakaba → 翻滚 → Pressure Plate → Gate → World Shift → Mortis → Inner-only / changed path → Perspective / route puzzle → Exit。

采用一个小型单房间/连续小片段：同一玩家触发压力板外部条件，门先 opening 后 open；设备切世界，60% 提交 world-slot 可用性，保留滚动姿态；用一处明确变化的路径和一次离散视角识路形成最小解谜，最终 Exit 完成状态接正式关卡生命周期。镜头变化本身不能被误当成改变碰撞拓扑。不要引入完整机关库或强依赖尚未验证的楼梯/移动载客。该段是接入建议，不是已实现玩法。

## 16. 主项目必须重新执行的测试

| 测试 | 主项目执行与通过依据 |
|---|---|
| 导入与资源 | 清洁导入/打包运行，所有 wrapper、GLB、textures、shader、动态 load、配置和 GUID/路径存在；无 missing resource、script/shader error |
| 单位/碰撞 | 单位、原点、逻辑一格、滚动轴、六面、四向翻滚扫掠及角落净空；不得只测静态 AABB |
| 压力板→门 | 两角色真实进入/退出 Area、条件/锁存、重复触发、门 opening 阻挡/open 释放、状态映射与存档复原 |
| World commit | 两方向在 commit 前后逐 physics tick 检查 world_slot、visual/logical/collision 归属；提交仅一次，无双重碰撞/空窗、触发器重复事件 |
| changed path | 新路不得在提交前可走/误导；旧路在提交前保留；提交时玩家占格、落脚、边缘和被移除支撑的规则明确且实测 |
| 姿态连续性 | 六种朝向、四滚动方向、滚动早/中/晚阶段、连续切换，验证 position/orientation/current face/roll progress/逻辑变换；不只比截图 |
| 中断/持久化 | 暂停、输入竞争、取消/重入、死亡/复位、存档加载、切关与首次发现标记；恢复后世界和机关状态一致 |
| 四镜头/遮挡 | 正式 Gameplay 分辨率/占屏下角色、桥、路线和出口；移动中 occlusion 更新/滞回，与 VFX 同时运行，不依赖单镜头 |
| Perspective puzzle | 主项目逻辑连通、可达/不可达与视觉识路一致；按正式规则测路线，不沿用 Gallery 的固定布局 |
| Exit / Shell | locked→available→activated→complete，与胜利只触发一次、关卡顺序/存档/Continue、Pause/焦点与 UI World State 同源 |
| 楼梯及可选载体 | 楼梯 clearance 与 traversal 独立验收；如纳入移动/旋转平台，重新测载客、随转、边缘与停靠 |
| 性能/稳定 | 目标硬件/renderer、连续高频切换、shader 编译卡顿、透明排序、内存/GC、暂停恢复和发布包时长；不将 RTX 5060 Ti 单场景数据视为所有设备保证 |

主项目应生成自己的版本/提交号、测试场景、输入步骤、日志、截图/视频和逐项结果。任何未执行项写 NOT_RUN；本表不能被自动填写 PASS。

## 17. 既有证据与本次交接核验

- [reports/world_shift/validation.json](<E:/Study/方块娘项目/若叶睦/model/art/production/releases/batch_05/reports/world_shift/validation.json>)
- [reports/world_shift/WorldShiftRuntimeReport.md](<E:/Study/方块娘项目/若叶睦/model/art/production/releases/batch_05/reports/world_shift/WorldShiftRuntimeReport.md>)
- [reports/world_shift/runtime_validation.json](<E:/Study/方块娘项目/若叶睦/model/art/production/releases/batch_05/reports/world_shift/runtime_validation.json>)
- [reports/world_shift/live_timing.json](<E:/Study/方块娘项目/若叶睦/model/art/production/releases/batch_05/reports/world_shift/live_timing.json>)
- [reports/world_shift/gallery_validation.json](<E:/Study/方块娘项目/若叶睦/model/art/production/releases/batch_05/reports/world_shift/gallery_validation.json>)
- [reports/world_shift_protection_after.json](<E:/Study/方块娘项目/若叶睦/model/art/production/releases/batch_05/reports/world_shift_protection_after.json>)
- [reports/stair_clearance.json](<E:/Study/方块娘项目/若叶睦/model/art/production/releases/batch_05/reports/stair_clearance.json>)
- [reports/mechanism_runtime.json](<E:/Study/方块娘项目/若叶睦/model/art/production/releases/batch_05/reports/mechanism_runtime.json>)
- [reports/mechanism_clearance_states.json](<E:/Study/方块娘项目/若叶睦/model/art/production/releases/batch_05/reports/mechanism_clearance_states.json>)

既有阶段证据包括 23 次序列/姿态测试、310 帧、24 次实时计时、3,805 次物理归属查询；这些是上一阶段结果，本轮未重跑。本次仅核实注册表 28 资产、5 环境 Pair、8 机关 Pair、状态契约、运行依赖与 UI 批准记录，并校验本文引用文件存在及技术验收值转录一致。

本轮唯一新增文件为本文。现有 manifest、矩阵、运行代码及读取的 UI 批准记录内容哈希在生成前后相同。未修改原游戏；完成后停止，等待另行授权正式集成。
