# PLAYABLE_ART_VERTICAL_SLICE_01_READY

主项目 `E:/godot/若叶睦/方块少女-若叶睦` 已默认从 Game Shell 进入正式 L-01《另一个世界》的 3D presentation，旧 Pixel Presenter 保留为回归参考。本轮只接入 L01；L02/L03 原字节保留，不开始推广。

已实际验收的实现提交：`7352002d7efc33318ee06c95231caea75b5cac50`。实现提交 `29bba3252d5a9661f7f59ff5d6fde66b2c2cee58` 后的 byte-preservation 提交只将批准资源的原始 CRLF 字节写入 Git，避免合入主项目时被换行转换。收口 receipt 提交仅包含本目录文档、证据与文件清单；最终 receipt SHA 由 Git HEAD 和交付消息给出，避免自引用。

## 正式主项目验收

证据根目录：`E:/godot/若叶睦/方块少女-若叶睦/.godot/beta-sprint/art-vertical/main_art01`。原始 run_report.json、entry/report.json、seed/report.json、restore/report.json、stdout/stderr 和截图均保留；本目录 FORMAL_MAIN_EVIDENCE.json 记录其 SHA-256 与最小验收数据，不引用 Gallery 运行结果作为主项目证据。

Godot 4.7.2 stable steam，D3D12 / Forward+，NVIDIA RTX 5060 Ti。运行时间为 2026-10-06 23:58:28–23:59:34（Asia/Shanghai）。

| 正式进程 | PID | 检查 | failures | exit | stderr |
|---|---:|---:|---:|---:|---|
| 主项目清洁导入 | 32528 | — | 无资源/脚本/shader错误 | 0 | empty |
| Headless L01 entry | 24952 | 6 PASS | [] | 0 | empty |
| Graphical Shell/Pixel/3D seed | 37556 | 6062 PASS | [] | 0 | empty |
| 新 OS 进程 Save/Continue restore | 31812 | 18 PASS | [] | 0 | empty |

合计 **6086 checks，0 failures**。实际跑通 Main Menu → Level Select → L01 → Move → Camera → World Shift → Reset → 再玩 → Goal → Level Complete → Shell；真实进程重新 Continue 回到 L01 初始态且默认 3D。检查 2 分辨率 × 2 世界 × 4 镜头共16组合、48张 seed 截图、84次动态门/出口遮挡采样。2324帧：p50 16.665ms、p95 16.769ms；该数据只覆盖此设备和 L01，没有发布包或其他硬件保证。

## 交付状态

| 项目 | 状态 |
|---|---|
| 3D Presenter / Wakaba 3D / Cube Roll | PASS |
| Six-face orientation / 4×90 Camera | PASS |
| Surface / Inner / World Shift VFX | PASS |
| Mechanism visuals / Reset / Goal / Shell flow | PASS |
| Pixel gameplay regression | PASS |
| Runtime StateKey parity | PASS — P01 observation SHA256 范围 |
| Art source changes | NONE |
| Foundation production changes | NONE，相对本轮冻结基线 |
| STAIR_CLEARANCE | PARTIAL_PASS，保持原证据 |
| STAIR_TRAVERSAL | NOT_RUN |
| Main-project QA | READY，08 黑盒试玩待执行 |
| P0 / P1 / P2 | 0 / 0 / 0，本轮自动化与代码/截图审查已确认问题数；非 Human QA 结论 |
| MAIN_PROJECT_INTEGRATION_REQUEST | NONE |
| Push | NOT_RUN |

## Runtime 与美术边界

实际 L01 运行链是现有 ContentLevel → P01 GridMovement/PerspectiveController。未修改或复制 Gameplay、World Shift、Perspective Connection、Cube Roll、Foundation 算法。新子类只调用既有入口并观察已有位置、orientation、phase、世界、机关和 Goal 状态；模型位置不能反向决定逻辑。Pixel 与 3D 使用同一运行链、同一输入路线，17次正式 commit 的全部观察记录及最终 Goal/机关结果逐项一致，六个物理方向均覆盖。

**此关卡没有实例化 Foundation RuntimeSession，也没有 APPLIED / finish_local / finish_global 生命周期或 Foundation statekey.v1。** Roll 自然姿态消费现有 runtime 的0.32秒 phase进度，由既有 Runtime commit；未增加第二个 Tween 完成回调。报告中的 StateKey parity 只指明确标注的 P01 observation SHA256，不能视为 Foundation statekey.v1 验收或 RuntimeSession 迁移。

World Shift 的既有正式 commit 在0.25秒，批准视觉 gate在60%；presentation 时间映射为0.25/0.60≈0.416667秒，保持旧逻辑提交时刻。提交前隐藏 incoming walk surface，保留旧支撑；视觉尾段不锁正式输入。相机仅四个90°状态，沿用既有鼠标/Q/E交互与 Perspective B-offset。

18个批准资产 ID、121条源文件绑定记录；14个 ID 实际用于 L01，Surface/Inner 的 Arch/Pillar 共4个为未实例化的批准依赖储备。GLB、贴图、材质设计与 Blender 源文件不改；wrapper/config 仅做 res:// 命名空间改写并保留源/目标哈希。未导入 Gallery controller 或 mechanism_runtime.gd。实例中的模型碰撞 layer/mask/Area 禁用，原 Grid occupancy 仍是唯一 Gameplay collision authority；不能声称完成独立3D Area机关系统。

遮挡仅处理实际前景 Gate/Exit，采用批准范围的 AABB margin、0.10秒滞回与alpha约0.16；运行时缓存的材质副本处理 fade，不修改源 shader。角色与地面不参与全场景透明。既有 Shell 保留，本轮不重做 UI Art，也不将未批准 UI extensions 当作已接入资产。

## Art handoff 重点在主项目的结果

| 重点 | 本轮新证据与边界 |
|---|---|
| 导入与资源 | PASS：真实主项目重新导入，路径/GLB/贴图/shader 可加载；发布包 NOT_RUN |
| 单位、滚动轴与六面 | PASS：N/S/E/W可用移动、早/中/晚姿态、中心/抬升/端点、六面保持；3D物理碰撞扫掠 NOT_APPLICABLE，逻辑格规则未变 |
| 压力板→门 | PASS：既有 L01 压板/门逻辑与视觉一致；进入/退出Area、锁存、opening phase与机关Puzzle存档 NOT_RUN/非本运行链 |
| World commit | PASS：两向逐运行帧观察，正式世界只提交一次、提交前支撑保留；独立3D物理归属 NOT_APPLICABLE |
| changed path | PASS：Inner-only支撑、unsafe shift拒绝、提交前incoming不可见、既有路线可达性；无新增拓扑算法 |
| 姿态连续性 | PASS：四滚动方向、早中晚采样、六面、连续镜头/世界切换和Reset，不回正 |
| 中断与持久化 | PASS：暂停/恢复、失焦、竞争输入、运动中Reset、退出重入与新进程Shell进度Continue；死亡/任意PuzzleStateSave NOT_RUN |
| 四镜头与遮挡 | PASS：16分辨率/世界/视角组合、移动中84次遮挡、VFX材料权限检查；人工可读性待08 |
| Perspective puzzle | PASS：实际L01路线、实际正式视角连通、两种Presenter最终状态相同 |
| Exit / Shell | PASS：现有世界条件、Goal一次完成、Shell回流与进度解锁；不增设旧Runtime没有的出口状态算法 |
| 楼梯与可选载体 | STAIR_CLEARANCE PARTIAL_PASS；traversal/移动载客/旋转平台 NOT_RUN，无L01依赖不扩范围 |
| 性能与稳定 | PASS限本设备：全流程帧时间、shader/资源无报错；其它硬件、发布包长期运行、Human QA NOT_RUN |

## 历史、保护检查与清单

保留失败历史，不把修复后的结果覆写旧证据：entry RED 为预期缺少3D入口；ig_art02 是文档CSV被Godot当翻译资源导入的 Harness metadata 问题（00用正确CSV与docs/.gdignore修复）；ig_art03 是 Harness 将alpha fade材质错认成VFX材质，修正精确材料权限断言。最终 ig_art04 与 main_art01 均 GREEN，未因此修改正式玩法。

FROZEN_GAMEPLAY_SHA256.json 记录本轮原始245个冻结 Gameplay 文件；主项目逐字节一致。PRESERVED_MAIN_FILES_SHA256.json 记录原有84个未跟踪文件，内容全部保留；其中7个已被既有规则忽略，Git仍列出77个预存 UI 文件。本轮未提交、删除或为清理状态而忽略这些用户资料。

Working tree：**Integration CLEAN；Main tracked task changes CLEAN；Main overall has 77 pre-existing UNTRACKED files，不能声称全树CLEAN。**

Files/SHA：FILES_SHA256.csv / FILES_SHA256.json 是本轮范围内最终物理文件的精确路径、字节数、SHA256；为避免自引用，只排除两个清单文件本身。原始艺术绑定、批准来源与命名空间改写见 ART_ASSET_BINDING_MANIFEST.csv / .json。最终 docs-only 收口后须核验这些清单在主项目全部匹配，且验收提交以来 game/production/tests/prototype/foundation/tools/project.godot 无额外变化。

08交接见 QA_HANDOFF_08.md。自动化不替代 Human QA。Foundation Freeze保持既有状态；本任务完成后停止，不开始L02。
