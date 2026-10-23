# Floating Cube A — continuation 06 实图评审

2026-10-23（Asia/Shanghai）。当前集成基线 `995121588d9e4aa8afe607cc594fd4c29ba3cdef`。用户已选 A，本轮只完成隔离改进与评审。

**OVERALL_VISUAL_REVIEW = PARTIAL**。西视角辨识 A1 **2 → A2 3**；四向 A2 均为 3。材质仍不能单独明确传达“不可踩”。

最终 run03：**346 checks / 0 failures / exit 0 / stderr 0 / 36 原始 PNG**。实际 Godot 4.7.2 Windows D3D12 Forward+ 渲染，1280×720。Codex 实看全部36张最终图片；独立复核实看8张最终A2图。这不是首次玩家理解性验证。

## 分数与口径

沿用 V1–V6 正式权重 30/20/15/15/10/10，`score / 5 × weight`。旧05任务JSON/schema不修改；本轮单独schema只用于06数据结构核验。

| 候选 | 已评估原权重 | 小计 | 完整总分 |
| --- | ---: | ---: | --- |
| CURRENT | 90% | 46.0 | NOT_ASSESSED |
| A1 | 90% | 61.0 | NOT_ASSESSED |
| A2 | 90% | 65.0 | NOT_ASSESSED |

同一90%权重下 A2 比 A1 **+4.0**、比 CURRENT **+19.0**。没有归一化到100；V5缺证据，完整总分及完整总分差均为null。

## CURRENT

| 项 | 权重 | 评分 | 加权分 | 观察与扣分 | 图片依据 |
| --- | ---: | --- | --- | --- | --- |
| V1 | 30 | 2 | 12.0 | 与道路同为平顶立方体；灰蓝色只能提供颜色差别。 平顶和方正体量容易被读成可到达平台。 | [FORMAL_SURFACE_CURRENT_q0](evidence/FORMAL_SURFACE_CURRENT_q0.png), [FORMAL_SURFACE_CURRENT_q1](evidence/FORMAL_SURFACE_CURRENT_q1.png), [FORMAL_SURFACE_CURRENT_q2](evidence/FORMAL_SURFACE_CURRENT_q2.png), [FORMAL_SURFACE_CURRENT_q3](evidence/FORMAL_SURFACE_CURRENT_q3.png) |
| V2 | 20 | 2 | 8.0 | 四方向均保留相似的平顶平台轮廓，未出现稳定非颜色用途线索。 转向不能消除其可踩平台外观。 | [FORMAL_SURFACE_CURRENT_q0](evidence/FORMAL_SURFACE_CURRENT_q0.png), [FORMAL_SURFACE_CURRENT_q1](evidence/FORMAL_SURFACE_CURRENT_q1.png), [FORMAL_SURFACE_CURRENT_q2](evidence/FORMAL_SURFACE_CURRENT_q2.png), [FORMAL_SURFACE_CURRENT_q3](evidence/FORMAL_SURFACE_CURRENT_q3.png) |
| V3 | 15 | 5 | 15.0 | 四图中的主体轮廓、悬空高度、相对转换点位置保持。 在该静态同对象范围内未发现位置或轮廓问题。 | [FORMAL_SURFACE_CURRENT_q0](evidence/FORMAL_SURFACE_CURRENT_q0.png), [FORMAL_SURFACE_CURRENT_q1](evidence/FORMAL_SURFACE_CURRENT_q1.png), [FORMAL_SURFACE_CURRENT_q2](evidence/FORMAL_SURFACE_CURRENT_q2.png), [FORMAL_SURFACE_CURRENT_q3](evidence/FORMAL_SURFACE_CURRENT_q3.png) |
| V4 | 15 | 3 | 9.0 | 四图呈不透明哑光表面，没有透明或大面积发光。 表面平滑，缺少目标要求的粗纹。 | [FORMAL_SURFACE_CURRENT_q0](evidence/FORMAL_SURFACE_CURRENT_q0.png), [FORMAL_SURFACE_CURRENT_q1](evidence/FORMAL_SURFACE_CURRENT_q1.png), [FORMAL_SURFACE_CURRENT_q2](evidence/FORMAL_SURFACE_CURRENT_q2.png), [FORMAL_SURFACE_CURRENT_q3](evidence/FORMAL_SURFACE_CURRENT_q3.png) |
| V5 | 10 | NOT_ASSESSED | null | 正式场景实拍仍为 GREYBOX 方块与正式 HUD；未接入冻结 Surface/Inner 美术母版。 缺少正式世界美术资产语境，V5 不评估。 | [FORMAL_SURFACE_CURRENT_q0](evidence/FORMAL_SURFACE_CURRENT_q0.png), [FORMAL_SURFACE_CURRENT_q1](evidence/FORMAL_SURFACE_CURRENT_q1.png), [FORMAL_SURFACE_CURRENT_q2](evidence/FORMAL_SURFACE_CURRENT_q2.png), [FORMAL_SURFACE_CURRENT_q3](evidence/FORMAL_SURFACE_CURRENT_q3.png) |
| V6 | 10 | 1 | 2.0 | 当前仅有平面光照明暗，表面无纹理、边缘或功能线索。 区分主要依赖颜色，非颜色线索不足。 | [FORMAL_SURFACE_CURRENT_q0](evidence/FORMAL_SURFACE_CURRENT_q0.png), [FORMAL_SURFACE_CURRENT_q1](evidence/FORMAL_SURFACE_CURRENT_q1.png), [FORMAL_SURFACE_CURRENT_q2](evidence/FORMAL_SURFACE_CURRENT_q2.png), [FORMAL_SURFACE_CURRENT_q3](evidence/FORMAL_SURFACE_CURRENT_q3.png) |

| Camera | 辨识分 | 观察 / 扣分 | 图片 |
| --- | ---: | --- | --- |
| NORTH | 2 | 灰蓝平顶立方体与脚下道路形态接近。 平顶与立方体体量保留，不能仅从材质推出不可踩用途；本分数不是玩家理解率。 | [FORMAL_SURFACE_CURRENT_q0](evidence/FORMAL_SURFACE_CURRENT_q0.png) |
| EAST | 2 | 灰蓝平顶立方体与脚下道路形态接近。 平顶与立方体体量保留，不能仅从材质推出不可踩用途；本分数不是玩家理解率。 | [FORMAL_SURFACE_CURRENT_q1](evidence/FORMAL_SURFACE_CURRENT_q1.png) |
| SOUTH | 2 | 灰蓝平顶立方体与脚下道路形态接近。 平顶与立方体体量保留，不能仅从材质推出不可踩用途；本分数不是玩家理解率。 | [FORMAL_SURFACE_CURRENT_q2](evidence/FORMAL_SURFACE_CURRENT_q2.png) |
| WEST | 2 | 灰蓝平顶立方体与脚下道路形态接近。 平顶与立方体体量保留，不能仅从材质推出不可踩用途；本分数不是玩家理解率。 | [FORMAL_SURFACE_CURRENT_q3](evidence/FORMAL_SURFACE_CURRENT_q3.png) |

## A1

| 项 | 权重 | 评分 | 加权分 | 观察与扣分 | 图片依据 |
| --- | ---: | --- | --- | --- | --- |
| V1 | 30 | 3 | 18.0 | 顶面与侧面有宽波纹，能与无纹道路区分。 仍是完整平顶立方体；材质差别并不直接说明不可踩。 | [FORMAL_SURFACE_A1_q0](evidence/FORMAL_SURFACE_A1_q0.png), [FORMAL_SURFACE_A1_q1](evidence/FORMAL_SURFACE_A1_q1.png), [FORMAL_SURFACE_A1_q2](evidence/FORMAL_SURFACE_A1_q2.png), [FORMAL_SURFACE_A1_q3](evidence/FORMAL_SURFACE_A1_q3.png) |
| V2 | 20 | 2 | 8.0 | 北东南波纹可见，西侧暗面的细纹明显较弱。 WEST 仍需仔细观察，四方向辨识不稳定。 | [FORMAL_SURFACE_A1_q0](evidence/FORMAL_SURFACE_A1_q0.png), [FORMAL_SURFACE_A1_q1](evidence/FORMAL_SURFACE_A1_q1.png), [FORMAL_SURFACE_A1_q2](evidence/FORMAL_SURFACE_A1_q2.png), [FORMAL_SURFACE_A1_q3](evidence/FORMAL_SURFACE_A1_q3.png) |
| V3 | 15 | 5 | 15.0 | 只换材质后，四图中的轮廓、高度和空间关系保持。 该同对象静态范围未发现主要轮廓或位置问题。 | [FORMAL_SURFACE_A1_q0](evidence/FORMAL_SURFACE_A1_q0.png), [FORMAL_SURFACE_A1_q1](evidence/FORMAL_SURFACE_A1_q1.png), [FORMAL_SURFACE_A1_q2](evidence/FORMAL_SURFACE_A1_q2.png), [FORMAL_SURFACE_A1_q3](evidence/FORMAL_SURFACE_A1_q3.png) |
| V4 | 15 | 4 | 12.0 | 四图均不透明、哑光，宽纹没有反光高光或发光轮廓。 条纹较规则，粗糙石质感仍有不足。 | [FORMAL_SURFACE_A1_q0](evidence/FORMAL_SURFACE_A1_q0.png), [FORMAL_SURFACE_A1_q1](evidence/FORMAL_SURFACE_A1_q1.png), [FORMAL_SURFACE_A1_q2](evidence/FORMAL_SURFACE_A1_q2.png), [FORMAL_SURFACE_A1_q3](evidence/FORMAL_SURFACE_A1_q3.png) |
| V5 | 10 | NOT_ASSESSED | null | 仅取得正式 GREYBOX/Inner 隐藏及人工样张，未取得冻结 Art 的世界语境。 V5 仍缺少可评估的正式美术证据。 | [FORMAL_SURFACE_A1_q0](evidence/FORMAL_SURFACE_A1_q0.png), [FORMAL_SURFACE_A1_q1](evidence/FORMAL_SURFACE_A1_q1.png), [FORMAL_SURFACE_A1_q2](evidence/FORMAL_SURFACE_A1_q2.png), [FORMAL_SURFACE_A1_q3](evidence/FORMAL_SURFACE_A1_q3.png) |
| V6 | 10 | 4 | 8.0 | 波纹提供非颜色区别，西视角顶面依然可辨。 西侧暗面纹理变弱；没有明确用途符号。 | [FORMAL_SURFACE_A1_q0](evidence/FORMAL_SURFACE_A1_q0.png), [FORMAL_SURFACE_A1_q1](evidence/FORMAL_SURFACE_A1_q1.png), [FORMAL_SURFACE_A1_q2](evidence/FORMAL_SURFACE_A1_q2.png), [FORMAL_SURFACE_A1_q3](evidence/FORMAL_SURFACE_A1_q3.png) |

| Camera | 辨识分 | 观察 / 扣分 | 图片 |
| --- | ---: | --- | --- |
| NORTH | 3 | 宽波纹能与光滑道路区分，但仍是平顶立方体。 平顶与立方体体量保留，不能仅从材质推出不可踩用途；本分数不是玩家理解率。 | [FORMAL_SURFACE_A1_q0](evidence/FORMAL_SURFACE_A1_q0.png) |
| EAST | 3 | 宽波纹能与光滑道路区分，但仍是平顶立方体。 平顶与立方体体量保留，不能仅从材质推出不可踩用途；本分数不是玩家理解率。 | [FORMAL_SURFACE_A1_q1](evidence/FORMAL_SURFACE_A1_q1.png) |
| SOUTH | 3 | 宽波纹能与光滑道路区分，但仍是平顶立方体。 平顶与立方体体量保留，不能仅从材质推出不可踩用途；本分数不是玩家理解率。 | [FORMAL_SURFACE_A1_q2](evidence/FORMAL_SURFACE_A1_q2.png) |
| WEST | 2 | 宽波纹可见；西侧两个暗面纹理明显变弱。 平顶与立方体体量保留，不能仅从材质推出不可踩用途；本分数不是玩家理解率。 | [FORMAL_SURFACE_A1_q3](evidence/FORMAL_SURFACE_A1_q3.png) |

## A2

| 项 | 权重 | 评分 | 加权分 | 观察与扣分 | 图片依据 |
| --- | ---: | --- | --- | --- | --- |
| V1 | 30 | 3 | 18.0 | 破碎块状颗粒与断续暗槽在四方向均可见，区别于光滑道路。 完整平顶仍可能被理解为石台，未证明玩家理解其不可踩用途。 | [FORMAL_SURFACE_A2_q0](evidence/FORMAL_SURFACE_A2_q0.png), [FORMAL_SURFACE_A2_q1](evidence/FORMAL_SURFACE_A2_q1.png), [FORMAL_SURFACE_A2_q2](evidence/FORMAL_SURFACE_A2_q2.png), [FORMAL_SURFACE_A2_q3](evidence/FORMAL_SURFACE_A2_q3.png) |
| V2 | 20 | 3 | 12.0 | 北东南西均能辨认块状颗粒，西侧两个暗面不再近似纯色。 四视角均仅达到基本可区分，轮廓用途歧义仍在。 | [FORMAL_SURFACE_A2_q0](evidence/FORMAL_SURFACE_A2_q0.png), [FORMAL_SURFACE_A2_q1](evidence/FORMAL_SURFACE_A2_q1.png), [FORMAL_SURFACE_A2_q2](evidence/FORMAL_SURFACE_A2_q2.png), [FORMAL_SURFACE_A2_q3](evidence/FORMAL_SURFACE_A2_q3.png) |
| V3 | 15 | 5 | 15.0 | 四图保持原单位立方体轮廓、原位置及与转换点的关系。 仅在正式 Surface 同对象静态范围内未发现问题。 | [FORMAL_SURFACE_A2_q0](evidence/FORMAL_SURFACE_A2_q0.png), [FORMAL_SURFACE_A2_q1](evidence/FORMAL_SURFACE_A2_q1.png), [FORMAL_SURFACE_A2_q2](evidence/FORMAL_SURFACE_A2_q2.png), [FORMAL_SURFACE_A2_q3](evidence/FORMAL_SURFACE_A2_q3.png) |
| V4 | 15 | 4 | 12.0 | 最终图片出现中灰断续槽纹和可见块状斑驳；表面哑光、不透明，无发光或高光。 仍是程序纹理，局部重复和侧面明暗变平，未达到自然石材精度。 | [FORMAL_SURFACE_A2_q0](evidence/FORMAL_SURFACE_A2_q0.png), [FORMAL_SURFACE_A2_q1](evidence/FORMAL_SURFACE_A2_q1.png), [FORMAL_SURFACE_A2_q2](evidence/FORMAL_SURFACE_A2_q2.png), [FORMAL_SURFACE_A2_q3](evidence/FORMAL_SURFACE_A2_q3.png) |
| V5 | 10 | NOT_ASSESSED | null | 正式 Shell/HUD 与 Inner 四图已补齐，但正式场景本身仍未消费冻结 Art。 不将 GREYBOX 或人工 Inner 样张冒充正式世界美术验收。 | [FORMAL_SURFACE_A2_q0](evidence/FORMAL_SURFACE_A2_q0.png), [FORMAL_SURFACE_A2_q1](evidence/FORMAL_SURFACE_A2_q1.png), [FORMAL_SURFACE_A2_q2](evidence/FORMAL_SURFACE_A2_q2.png), [FORMAL_SURFACE_A2_q3](evidence/FORMAL_SURFACE_A2_q3.png) |
| V6 | 10 | 4 | 8.0 | 明暗颗粒与破碎槽纹在四方向均可见，没有借助鲜艳颜色或发光。 缺少明确功能标记，完整立方体仍保留平台联想。 | [FORMAL_SURFACE_A2_q0](evidence/FORMAL_SURFACE_A2_q0.png), [FORMAL_SURFACE_A2_q1](evidence/FORMAL_SURFACE_A2_q1.png), [FORMAL_SURFACE_A2_q2](evidence/FORMAL_SURFACE_A2_q2.png), [FORMAL_SURFACE_A2_q3](evidence/FORMAL_SURFACE_A2_q3.png) |

| Camera | 辨识分 | 观察 / 扣分 | 图片 |
| --- | ---: | --- | --- |
| NORTH | 3 | 顶面及两侧块状颗粒/破碎槽纹可见，暗面保留明暗区别。 平顶与立方体体量保留，不能仅从材质推出不可踩用途；本分数不是玩家理解率。 | [FORMAL_SURFACE_A2_q0](evidence/FORMAL_SURFACE_A2_q0.png) |
| EAST | 3 | 顶面及两侧块状颗粒/破碎槽纹可见，暗面保留明暗区别。 平顶与立方体体量保留，不能仅从材质推出不可踩用途；本分数不是玩家理解率。 | [FORMAL_SURFACE_A2_q1](evidence/FORMAL_SURFACE_A2_q1.png) |
| SOUTH | 3 | 顶面及两侧块状颗粒/破碎槽纹可见，暗面保留明暗区别。 平顶与立方体体量保留，不能仅从材质推出不可踩用途；本分数不是玩家理解率。 | [FORMAL_SURFACE_A2_q2](evidence/FORMAL_SURFACE_A2_q2.png) |
| WEST | 3 | 顶面及两侧块状颗粒/破碎槽纹可见，暗面保留明暗区别。 平顶与立方体体量保留，不能仅从材质推出不可踩用途；本分数不是玩家理解率。 | [FORMAL_SURFACE_A2_q3](evidence/FORMAL_SURFACE_A2_q3.png) |

## 正式 Inner 与人工样张

真实 Runtime 路径是 Roll `face_axis=0` → World Shift `kind=1`，并等待正式动画完成。正式 Inner 没有 roof 作者对象；Surface roof 按层保持隐藏。正式 Inner 四向图片均已交付，但不可见材质的辨识分保持 **NOT_ASSESSED/null**。

人工样张复制原 roof 的 mesh 与原世界姿态，置于 Host geometry 之外，不含可走 Face、碰撞或逻辑遮光数据；同组相机仅在隔离样张中沿世界 UP +2，以避开正式 HUD，结束后恢复自然相机。它不代表真实 Inner 有该平台。

| Camera | 正式 Inner | CURRENT样张纹理 | A1样张纹理 | A2样张纹理 | 图片 |
| --- | --- | ---: | ---: | ---: | --- |
| NORTH | NOT_ASSESSED（roof隐藏） | 1 | 3 | 4 | [FORMAL_INNER_CURRENT_q0](evidence/FORMAL_INNER_CURRENT_q0.png), [FORMAL_INNER_A1_q0](evidence/FORMAL_INNER_A1_q0.png), [FORMAL_INNER_A2_q0](evidence/FORMAL_INNER_A2_q0.png), [INNER_MATERIAL_STUDY_CURRENT_q0](evidence/INNER_MATERIAL_STUDY_CURRENT_q0.png), [INNER_MATERIAL_STUDY_A1_q0](evidence/INNER_MATERIAL_STUDY_A1_q0.png), [INNER_MATERIAL_STUDY_A2_q0](evidence/INNER_MATERIAL_STUDY_A2_q0.png) |
| EAST | NOT_ASSESSED（roof隐藏） | 1 | 3 | 4 | [FORMAL_INNER_CURRENT_q1](evidence/FORMAL_INNER_CURRENT_q1.png), [FORMAL_INNER_A1_q1](evidence/FORMAL_INNER_A1_q1.png), [FORMAL_INNER_A2_q1](evidence/FORMAL_INNER_A2_q1.png), [INNER_MATERIAL_STUDY_CURRENT_q1](evidence/INNER_MATERIAL_STUDY_CURRENT_q1.png), [INNER_MATERIAL_STUDY_A1_q1](evidence/INNER_MATERIAL_STUDY_A1_q1.png), [INNER_MATERIAL_STUDY_A2_q1](evidence/INNER_MATERIAL_STUDY_A2_q1.png) |
| SOUTH | NOT_ASSESSED（roof隐藏） | 1 | 3 | 4 | [FORMAL_INNER_CURRENT_q2](evidence/FORMAL_INNER_CURRENT_q2.png), [FORMAL_INNER_A1_q2](evidence/FORMAL_INNER_A1_q2.png), [FORMAL_INNER_A2_q2](evidence/FORMAL_INNER_A2_q2.png), [INNER_MATERIAL_STUDY_CURRENT_q2](evidence/INNER_MATERIAL_STUDY_CURRENT_q2.png), [INNER_MATERIAL_STUDY_A1_q2](evidence/INNER_MATERIAL_STUDY_A1_q2.png), [INNER_MATERIAL_STUDY_A2_q2](evidence/INNER_MATERIAL_STUDY_A2_q2.png) |
| WEST | NOT_ASSESSED（roof隐藏） | 1 | 2 | 4 | [FORMAL_INNER_CURRENT_q3](evidence/FORMAL_INNER_CURRENT_q3.png), [FORMAL_INNER_A1_q3](evidence/FORMAL_INNER_A1_q3.png), [FORMAL_INNER_A2_q3](evidence/FORMAL_INNER_A2_q3.png), [INNER_MATERIAL_STUDY_CURRENT_q3](evidence/INNER_MATERIAL_STUDY_CURRENT_q3.png), [INNER_MATERIAL_STUDY_A1_q3](evidence/INNER_MATERIAL_STUDY_A1_q3.png), [INNER_MATERIAL_STUDY_A2_q3](evidence/INNER_MATERIAL_STUDY_A2_q3.png) |

人工样张“纹理可见性”只是补充观察，不参与 V1–V6、总分或正式 Inner Gameplay 评分。

## 真实正式场景和仍缺少的证据

正式入口 `game/shell/game_feel_shell.tscn`，使用既有单条真实S01 catalog的测试seam，实际实例化正式spatial_level、Runtime、Camera、HUD。未声称十关自然解锁回归。本场景标记GREYBOX，角色/平台仍为程序BoxMesh，尚未消费冻结美术母版，因此补齐正式场景与Inner截图仍不能将V5改为PASS。

同候选对照限定同world/context/q的相机、光照、StateKey、Orientation、网格及位姿一致；Surface和Inner本来的自然取景中心不同，没有宣称跨world相机transform相同。

道路观察：Surface四向道路与遮光体间有清楚间隙；Inner北东道路可见，南西Goal标记仍部分贴近或被角色遮挡。旧转换点文字重叠也仍存在。这些是已存在的静态可读性限制，本次未改UI或登记新Gameplay缺陷。

## 硬门槛与保护

| 门槛 | 结果 | 适用范围与证据 |
| --- | --- | --- |
| G1 | PASS | Existing procedural roof identity, source hashes, source face nonwalkability and original position verified. |
| G2 | PASS | New A2 shader/test only, in copied project/profile; original A1 and production files unchanged. |
| G3 | PASS | Same context/world/q/resolution/camera/light/state across candidates. Artificial study uses declared camera offset; not cross-world matching. |
| G4 | PASS | Four native views for every variant in formal Surface, formal Inner-hidden and separately labelled study. |
| G5 | PASS | Formal Surface original mesh/outline/pose/shadow preserved; artificial study not part of official geometry. |
| G6 | PASS | Actual four-view matte opaque appearance with coarse broken pattern; no alpha/emission or specular dependency. |
| G7 | PASS | Coarse grayscale grains and grooves remain visible across directions, including WEST. |
| G8 | PASS | Protected files and profiles unchanged, copied production hashes unchanged, refs unchanged; no Runtime/authoring/collision/rules edits. |

以上PASS仅覆盖已说明的隔离静态预览，不代表正式美术批准。样张额外几何与camera offset均仅用于标注的人工对照，不进入Gameplay数据或正式文件。

保护核验：4615 个既有文件哈希逐一复核，包含原Build manifest文件、旧预览文件、生产源文件、旧评分与美术工作包/备份；变化0。旧profile和受保护refs均一致。详见 [保护摘要](PRESERVATION_SUMMARY.json)、[真实过程收据](evidence/PROCESS.json)、[原始Capture记录](evidence/NATIVE_CAPTURES.json)。保护范围以记录中的清单为界。

## 迭代与交付

run01：341checks，36帧，显示早期A2偏白/规则纹；run02：342checks，补齐viewport GUI输入隔离；独立复核发现早期Inner样张被HUD裁切。run03：346checks，压低亮部、加入断续颗粒，并对人工样张单独取景，最终完整入镜。三个独立输出目录均保留，未覆盖。

当前4向材质暗面改善已由实际图片确认；V5、真人QA、正式资产集成仍未完成。没有新Build，正式资产、通行规则、旧QA包及存档不变。

交付包含新预览shader/runner、完整36张原PNG、结构化评分/新schema/只读校验器和本报告。新schema验证成功不授予美术批准。

全部图片对照见 [REVIEW.html](REVIEW.html)，结构化数据见 [SCORING_RESULTS.json](SCORING_RESULTS.json)。

最终只读校验：[VALIDATION.json](evidence/VALIDATION.json)。36张PNG与16个来源哈希复核通过，10项故意损坏的数据均被拒绝；12组真实条件一致，187个报告/预览链接可解析。校验不评价图片本身或授予美术批准。
