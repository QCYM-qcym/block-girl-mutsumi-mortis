# Floating Cube A2 Expanded — 最终视觉审批决定

2026-10-23 · 00 Integration Coordinator · 审批对象 `A2_EXPANDED_01`

**决定：本轮不批准正式资产替换（NOT_APPROVED）。A2 Expanded 继续保持 PREVIEW_ONLY。**

用户已授权由 00 完成视觉评审并作出审批决定。本记录是该决定，不是再次请求用户审批。评审决定已完成；完整视觉证据覆盖仍为 PARTIAL。正式游戏、美术母版和旧 QA 包保持原状，不生成新正式 Build。

## 对象与证据

评审基线：`b6b7c5d50acb41f15ccebe76dc3bbcca177b6083`，分支 `feat/spatial-formal-chapter-01`。审批仅针对当前扩展 A2 shader，不扩大到旧严格 B2、B 或其他资源。

- [实际源身份](../option_a2_west_expanded/A2_SOURCE_IDENTITY.json)：正式遮光体为原 Host 生成的 BoxMesh；并非某个 Blender 模型。
- 当前候选 shader SHA-256：`9e0887cf3b968ecde6197f702d4a8bb37e737f705ad3d2e4ffb0b5de9465b57c`。
- [12 张同轮原图与四视角总览](../option_a2_west_expanded/renders/current_vs_A1_vs_A2/OVERVIEW.html)：CURRENT、A1、A2 各四向；1280×720；正式 Camera 定义 NORTH / EAST / SOUTH / WEST。
- [渲染条件](../option_a2_west_expanded/renders/current_vs_A1_vs_A2/RENDER_COMPARISON.json)与[原评分数据](../option_a2_west_expanded/SCORING_RESULTS.json)保持不变。本次重新查看 A2 四张原图、CURRENT/A1 的 WEST 原图及旧 L01 Surface/Inner 原图；独立视觉评审查看全部 12 张候选原图。
- [正式 Art 绑定清单](../../../playable-art-vertical-01/ART_ASSET_BINDING_MANIFEST.json)证实批准的世界资产存在。L01 的历史原图没有 A2，使用不同灯光和分辨率，只能作风格参照，不能冒充本候选的同屏验证。

全部引用的精确路径与实际 SHA 见 [DECISION.json](DECISION.json)，本轮只读验证见 [VERIFICATION.json](VERIFICATION.json)。

## 视觉判断

**改善成立。** 西视角的粗纹从 A1 的顶面线条扩展到了可见侧面，暗面不再近似无纹理。四方向都与光滑道路形成差异；同一套材质的四向预览门槛成立。

**用途仍存在歧义。** A2 四图仍具有完整平顶、笔直边界和实心立方体体量。粗石纹让它更像“另一种石台”，没有清楚消除可站立平台的联想。3/5 表示基本可区分、仍需观察，不等于玩家能据此推断不可踩。这是本次实际图片的美术判断，不是将美术审批转交给未进行的真人 QA。

**正式世界协调性没有足够证据。** 当前候选原图来自 S01 正式 Shell 中的 GREYBOX Surface。现有冻结 Surface / Inner 美术虽已在 L01 使用，但不与当前 A2 同屏。不能从两套不同灯光、不同分辨率的图片推导 V5。真实 Inner 地图没有该 roof；不得为补齐评分新增 Inner 遮光体或改动其世界归属。

**材质方向基本符合。** 不透明、低反射、低饱和灰蓝粗石和非颜色纹理线索均可见。程序层理略有重复和褶皱感，包裹漫反射令部分面间明暗趋平。它在简洁 GREYBOX 中突出，尚不足以确认与冻结正式世界美术协调。

## 原评分复核

沿用既有权重和计算，不增加新阈值，不改写历史评分。

| 正式视角 | CURRENT | A1 | A2 Expanded | 本轮依据 |
| --- | ---: | ---: | ---: | --- |
| NORTH | 2 | 3 | 3 | [A2_q0.png](../option_a2_west_expanded/renders/current_vs_A1_vs_A2/A2_q0.png)：粗纹明确，仍为完整平顶方块。 |
| EAST | 2 | 3 | 3 | [A2_q1.png](../option_a2_west_expanded/renders/current_vs_A1_vs_A2/A2_q1.png)：侧面纹理稳定，石台联想仍在。 |
| SOUTH | 2 | 3 | 3 | [A2_q2.png](../option_a2_west_expanded/renders/current_vs_A1_vs_A2/A2_q2.png)：主体与道路能区分，用途线索不足。 |
| WEST | 2 | 2 | 3 | [A2_q3.png](../option_a2_west_expanded/renders/current_vs_A1_vs_A2/A2_q3.png)：暗面改善可见，未消除可踩表面的联想。 |

| 项 | 权重 | A2 分数 | 加权分 | 依据 |
| --- | ---: | ---: | ---: | --- |
| V1 非可行走辨识 | 30 | 3 | 18.0 | A2 四图；材质能区别，非行走用途仍有歧义。 |
| V2 四向一致性 | 20 | 3 | 12.0 | A2 四图；四向基本可区分，未达到清楚无歧义。 |
| V3 空间关系 | 15 | 5 | 15.0 | 四图及固定条件记录；原轮廓、位置、尺寸和空间作用保持。 |
| V4 材质目标 | 15 | 4 | 12.0 | A2 四图；粗石哑光成立，层理重复及部分面明暗趋平。 |
| V5 世界风格 | 10 | NOT_ASSESSED | null | 缺当前候选与冻结正式世界 Art 的同屏证据。 |
| V6 非颜色线索 | 10 | 4 | 8.0 | A2 四图；粗纹明暗有效，仍缺明确用途语义。 |

已评估原权重小计 **65.0 / 90**；完整总分 **null / NOT_ASSESSED**。CURRENT 46.0、A1 61.0 同样只覆盖 90% 原权重。不得将小计归一化为完整百分制总分。

既有 G1–G8 在隔离 Surface 预览范围内的 PASS 保留；它们不覆盖缺失的正式世界联合验证，也不自动授予正式资产批准。没有因本次审批改变评分门槛。

## 复审需要与安全边界

下次复审的最小补证是：在新的隔离预览中，让**同一 shader 身份的 A2 与冻结正式 Surface 道路、角色、转换点同屏**，保留四个正式 Camera 的原生截图及完整条件记录。目标世界灯光须明确记录，不能与现有 GREYBOX 同条件对照混算。Inner 应如实保留该对象隐藏/不适用的地图事实，不能添加对象来制造证据。

补证后仍需直接评定非行走语义和风格；如仍像可踩石台，不能仅靠补齐图片或提高分数获得批准。本轮不继续修改材质，不转入几何、提示文字或正式场景生产。

Human QA：NOT_RUN。现有图像评审不代表真人理解率。没有本轮新增的 Gameplay 缺陷；平台用途歧义及 V5 缺口为保留问题。

本轮仅增加本审批记录、结构化决定与只读验证记录。正式 shader、生产代码、通行规则、遮光逻辑、美术母版、旧截图、旧存档、main、Release Branch / Tag 均不修改；Game Integration：NOT_RUN；New Formal Build：NOT_CREATED。GitHub 交付身份在提交后独立核验，旧评分及审批记录保持历史原值。
