# Floating Cube Visual Acceptance Report

Task ID: `SPATIAL_FORMAL_CHAPTER_01_CONTINUATION_05`

Review Date: 2026-10-21T09:34:46.129718+00:00

Reviewer: Codex / 00 Integration Coordinator

Review Mode: ISOLATED_ART_PREVIEW

Project: Mutsumi Veilshift

Godot: 4.7.2 project; historical capture 4.7.2-stable (steam); not launched this review

Blender Version: NOT_ASSESSED / NOT_APPLICABLE — NOT_RUN / NOT_APPLICABLE: actual target is Godot procedural BoxMesh, no traced same-object .blend; unrelated design .blend not substituted.

**OVERALL_VISUAL_REVIEW = PARTIAL**；**FORMAL_ASSET_APPROVAL = NOT_GRANTED**。

Current material reference and A/B on the same real roof, historical isolated Surface/source static viewport frames; not new formal Shell screenshots.

User JSON Schema fragment ended inside review_mode ISOLATED; retained its supplied top-level fields and completed constraints from E1-E6. Not represented as a verbatim complete supplied schema.

E5 scoring-band text and E6.7 template were truncated; no missing acceptance thresholds invented. Missing V5 requires PARTIAL and null total under explicit E6.3.

## 资产身份与来源

Source: [core_lab.gd](E:/godot/worktrees/bg-formal01/experiments/game_feel_01/host/core_lab.gd)

Source SHA-256: `b5d7d6c19a65dd167b9ee4a32c1074912c547482e9ac11370dcfc6fd336cdf0b`

Authoring: [surface.tscn](E:/godot/worktrees/bg-formal01/experiments/spatial_puzzle_batch_01/maps/authoring/world_shift_gate_lab/surface.tscn)

Authoring SHA-256: `e8fbb0810ed282c824b664f402b145388fb881c70f5f26296e7c0600de7d5785`

Original Build manifest: [BUILD_IDENTITY.json](E:/godot/beta-sprint-builds/beta_spatial_acceptance_input_fix_20261013_01/BUILD_IDENTITY.json)

Manifest SHA-256: `67021752bfec7a05223aa12b3b447005bf486818e54983b4559d32b5a53393c0`

Six exact source hashes match current branch, historical preview and formal Build. Roof position (1,6,0), unit BoxMesh, six nonwalkable faces, occludes_light=true. Formal Shell background/HUD differ; old screenshots are not an entire current-Build visual certification.

Preview Source: `0bb0e01742eacf12272956111cd6b86fdc74f819`；Formal Build Source: `763f0132bc58360fab0e224d0e9c54e00c92ae90`；审查基线：`8a8745d4b840e46ab1be5068c26a93b424753539`。

| 字段 | 当前材质参照 | A | B |
|---|---|---|---|
| variant | ORIGINAL | A | B |
| model | roof: procedural Godot unit BoxMesh at (1,6,0), authoring 06c03444-c53b-49bb-6834-458cf9eb007a | roof: procedural Godot unit BoxMesh at (1,6,0), authoring 06c03444-c53b-49bb-6834-458cf9eb007a | roof: procedural Godot unit BoxMesh at (1,6,0), authoring 06c03444-c53b-49bb-6834-458cf9eb007a |
| material | StandardMaterial3D #424b5b | roof_coarse ShaderMaterial | roof_inset ShaderMaterial; painted inset, not modeled groove |
| blender_status | NOT_APPLICABLE_PROCEDURAL_GODOT_BOXMESH | NOT_APPLICABLE_PROCEDURAL_GODOT_BOXMESH | NOT_APPLICABLE_PROCEDURAL_GODOT_BOXMESH |
| geometry_and_role | Same unit silhouette, identity basis, Surface roof six nonwalkable faces; occludes_light=true. Same-group captured geometry/state verified. | Same unit silhouette, identity basis, Surface roof six nonwalkable faces; occludes_light=true. Same-group captured geometry/state verified. | Same unit silhouette, identity basis, Surface roof six nonwalkable faces; occludes_light=true. Same-group captured geometry/state verified. |
| same_pose | True | True | True |
| isolated | True | True | True |
| identity_status | PASS | PASS | PASS |

Blender file：三组均为 null；没有把相似的 Blender 设计灰模当作此实际 roof。源码与材质的完整文件 SHA 见末尾证据清单。

## 加权评分

完整总分需要六项均可评。V5 缺失，以下仅显示原始权重小计，不归一化，不替代100分总分。所有分数是 Codex 图像观察判断，不是真人理解率。

| 编号 | 项目 | 权重 | 当前分 | 当前加权 | A分 | A加权 | B分 | B加权 |
|---|---|---:|---:|---:|---:|---:|---:|---:|
| V1 | 非可行走物体辨识性 | 30% | 2 | 12.0 | 3 | 18.0 | 2 | 12.0 |
| V2 | 四视角辨识一致性 | 20% | 2 | 8.0 | 2 | 8.0 | 2 | 8.0 |
| V3 | 原有空间关系保持 | 15% | 5 | 15.0 | 5 | 15.0 | 5 | 15.0 |
| V4 | 材质符合度 | 15% | 3 | 9.0 | 4 | 12.0 | 3 | 9.0 |
| V5 | 世界美术风格一致性 | 10% | NOT_ASSESSED | NOT_ASSESSED | NOT_ASSESSED | NOT_ASSESSED | NOT_ASSESSED | NOT_ASSESSED |
| V6 | 非颜色线索有效性 | 10% | 1 | 2.0 | 4 | 8.0 | 3 | 6.0 |

舍入规则：Weighted scores, subtotals and displayed view means rounded to one decimal; A view mean is exactly 2.75, displayed and stored as 2.8.

| 汇总 | 当前材质参照 | A | B |
|---|---:|---:|---:|
| 完整总分 /100 | NOT_ASSESSED | NOT_ASSESSED | NOT_ASSESSED |
| 已评估小计 /90，未归一化 | 46.0 | 61.0 | 50.0 |
| 已评估权重 % | 90 | 90 | 90 |

### 当前材质参照：逐项依据

**V1 非可行走物体辨识性：2；加权 12.0。**

实图中悬空块与脚下道路均为平整立方体、平顶和硬直边；主要区别是灰蓝/蓝色与悬空间距。

2分：仍存在明显平台误读。 扣3分：没有明确的非可走表面类别线索；间距不等于不可走。

未解决：无首次真人理解性观察；不外推动态、其它站位或正式Shell。 主观判断：YES。

图片：[ORIGINAL_q0_1280x720.png](E:/godot/beta-sprint-builds/QA/art_preview_polish03/run_20261013T143919247369Z/captures/ORIGINAL_q0_1280x720.png) · [ORIGINAL_q0_960x720.png](E:/godot/beta-sprint-builds/QA/art_preview_polish03/run_20261013T143919247369Z/captures/ORIGINAL_q0_960x720.png) · [ORIGINAL_q1_1280x720.png](E:/godot/beta-sprint-builds/QA/art_preview_polish03/run_20261013T143919247369Z/captures/ORIGINAL_q1_1280x720.png) · [ORIGINAL_q1_960x720.png](E:/godot/beta-sprint-builds/QA/art_preview_polish03/run_20261013T143919247369Z/captures/ORIGINAL_q1_960x720.png) · [ORIGINAL_q2_1280x720.png](E:/godot/beta-sprint-builds/QA/art_preview_polish03/run_20261013T143919247369Z/captures/ORIGINAL_q2_1280x720.png) · [ORIGINAL_q2_960x720.png](E:/godot/beta-sprint-builds/QA/art_preview_polish03/run_20261013T143919247369Z/captures/ORIGINAL_q2_960x720.png) · [ORIGINAL_q3_1280x720.png](E:/godot/beta-sprint-builds/QA/art_preview_polish03/run_20261013T143919247369Z/captures/ORIGINAL_q3_1280x720.png) · [ORIGINAL_q3_960x720.png](E:/godot/beta-sprint-builds/QA/art_preview_polish03/run_20261013T143919247369Z/captures/ORIGINAL_q3_960x720.png)

**V2 四视角辨识一致性：2；加权 8.0。**

四向都保留平台式平顶；西向两侧近黑，顶部仍像可落脚平面。

2分：四向均有混淆，不能以稳定地混淆算一致性高分。 扣3分：没有任何一向可靠传达非可走用途。

未解决：无首次真人理解性观察；不外推动态、其它站位或正式Shell。 主观判断：YES。

图片：[ORIGINAL_q0_1280x720.png](E:/godot/beta-sprint-builds/QA/art_preview_polish03/run_20261013T143919247369Z/captures/ORIGINAL_q0_1280x720.png) · [ORIGINAL_q0_960x720.png](E:/godot/beta-sprint-builds/QA/art_preview_polish03/run_20261013T143919247369Z/captures/ORIGINAL_q0_960x720.png) · [ORIGINAL_q1_1280x720.png](E:/godot/beta-sprint-builds/QA/art_preview_polish03/run_20261013T143919247369Z/captures/ORIGINAL_q1_1280x720.png) · [ORIGINAL_q1_960x720.png](E:/godot/beta-sprint-builds/QA/art_preview_polish03/run_20261013T143919247369Z/captures/ORIGINAL_q1_960x720.png) · [ORIGINAL_q2_1280x720.png](E:/godot/beta-sprint-builds/QA/art_preview_polish03/run_20261013T143919247369Z/captures/ORIGINAL_q2_1280x720.png) · [ORIGINAL_q2_960x720.png](E:/godot/beta-sprint-builds/QA/art_preview_polish03/run_20261013T143919247369Z/captures/ORIGINAL_q2_960x720.png) · [ORIGINAL_q3_1280x720.png](E:/godot/beta-sprint-builds/QA/art_preview_polish03/run_20261013T143919247369Z/captures/ORIGINAL_q3_1280x720.png) · [ORIGINAL_q3_960x720.png](E:/godot/beta-sprint-builds/QA/art_preview_polish03/run_20261013T143919247369Z/captures/ORIGINAL_q3_960x720.png)

**V3 原有空间关系保持：5；加权 15.0。**

完整单位立方体轮廓、悬空位置、与转换点和道路的上下关系四向均可见。

5分：作为原始几何参照，静态轮廓/位置无异常。 本项未扣分；只覆盖静态源站位，不推断动态遮光。

未解决：无首次真人理解性观察；不外推动态、其它站位或正式Shell。 主观判断：YES。

图片：[ORIGINAL_q0_1280x720.png](E:/godot/beta-sprint-builds/QA/art_preview_polish03/run_20261013T143919247369Z/captures/ORIGINAL_q0_1280x720.png) · [ORIGINAL_q0_960x720.png](E:/godot/beta-sprint-builds/QA/art_preview_polish03/run_20261013T143919247369Z/captures/ORIGINAL_q0_960x720.png) · [ORIGINAL_q1_1280x720.png](E:/godot/beta-sprint-builds/QA/art_preview_polish03/run_20261013T143919247369Z/captures/ORIGINAL_q1_1280x720.png) · [ORIGINAL_q1_960x720.png](E:/godot/beta-sprint-builds/QA/art_preview_polish03/run_20261013T143919247369Z/captures/ORIGINAL_q1_960x720.png) · [ORIGINAL_q2_1280x720.png](E:/godot/beta-sprint-builds/QA/art_preview_polish03/run_20261013T143919247369Z/captures/ORIGINAL_q2_1280x720.png) · [ORIGINAL_q2_960x720.png](E:/godot/beta-sprint-builds/QA/art_preview_polish03/run_20261013T143919247369Z/captures/ORIGINAL_q2_960x720.png) · [ORIGINAL_q3_1280x720.png](E:/godot/beta-sprint-builds/QA/art_preview_polish03/run_20261013T143919247369Z/captures/ORIGINAL_q3_1280x720.png) · [ORIGINAL_q3_960x720.png](E:/godot/beta-sprint-builds/QA/art_preview_polish03/run_20261013T143919247369Z/captures/ORIGINAL_q3_960x720.png)

**V4 材质符合度：3；加权 9.0。**

表面不透明，没有明显高光或发光；三个可见面是干净平涂，缺乏粗纹触感。

3分：低反射/不透明观感基本满足，粗糙视觉线索不足。 扣2分：平滑平面读感仍强；静态光照不能测量材质全部反射行为。

未解决：无首次真人理解性观察；不外推动态、其它站位或正式Shell。 主观判断：YES。

图片：[ORIGINAL_q0_1280x720.png](E:/godot/beta-sprint-builds/QA/art_preview_polish03/run_20261013T143919247369Z/captures/ORIGINAL_q0_1280x720.png) · [ORIGINAL_q0_960x720.png](E:/godot/beta-sprint-builds/QA/art_preview_polish03/run_20261013T143919247369Z/captures/ORIGINAL_q0_960x720.png) · [ORIGINAL_q1_1280x720.png](E:/godot/beta-sprint-builds/QA/art_preview_polish03/run_20261013T143919247369Z/captures/ORIGINAL_q1_1280x720.png) · [ORIGINAL_q1_960x720.png](E:/godot/beta-sprint-builds/QA/art_preview_polish03/run_20261013T143919247369Z/captures/ORIGINAL_q1_960x720.png) · [ORIGINAL_q2_1280x720.png](E:/godot/beta-sprint-builds/QA/art_preview_polish03/run_20261013T143919247369Z/captures/ORIGINAL_q2_1280x720.png) · [ORIGINAL_q2_960x720.png](E:/godot/beta-sprint-builds/QA/art_preview_polish03/run_20261013T143919247369Z/captures/ORIGINAL_q2_960x720.png) · [ORIGINAL_q3_1280x720.png](E:/godot/beta-sprint-builds/QA/art_preview_polish03/run_20261013T143919247369Z/captures/ORIGINAL_q3_1280x720.png) · [ORIGINAL_q3_960x720.png](E:/godot/beta-sprint-builds/QA/art_preview_polish03/run_20261013T143919247369Z/captures/ORIGINAL_q3_960x720.png)

**V5 世界美术风格一致性：NOT_ASSESSED；加权 NOT_ASSESSED。**

只有旧实验 Surface、调试数字角色与灰背景；缺少 Inner 及正式世界美术同屏。

证据不足，不能评分完整 Surface/Inner 风格一致性。 未评分，不把缺证据算0分或5分。

未解决：缺少Inner/正式世界美术同屏。 主观判断：YES。

图片：[ORIGINAL_q0_1280x720.png](E:/godot/beta-sprint-builds/QA/art_preview_polish03/run_20261013T143919247369Z/captures/ORIGINAL_q0_1280x720.png) · [ORIGINAL_q0_960x720.png](E:/godot/beta-sprint-builds/QA/art_preview_polish03/run_20261013T143919247369Z/captures/ORIGINAL_q0_960x720.png) · [ORIGINAL_q1_1280x720.png](E:/godot/beta-sprint-builds/QA/art_preview_polish03/run_20261013T143919247369Z/captures/ORIGINAL_q1_1280x720.png) · [ORIGINAL_q1_960x720.png](E:/godot/beta-sprint-builds/QA/art_preview_polish03/run_20261013T143919247369Z/captures/ORIGINAL_q1_960x720.png) · [ORIGINAL_q2_1280x720.png](E:/godot/beta-sprint-builds/QA/art_preview_polish03/run_20261013T143919247369Z/captures/ORIGINAL_q2_1280x720.png) · [ORIGINAL_q2_960x720.png](E:/godot/beta-sprint-builds/QA/art_preview_polish03/run_20261013T143919247369Z/captures/ORIGINAL_q2_960x720.png) · [ORIGINAL_q3_1280x720.png](E:/godot/beta-sprint-builds/QA/art_preview_polish03/run_20261013T143919247369Z/captures/ORIGINAL_q3_1280x720.png) · [ORIGINAL_q3_960x720.png](E:/godot/beta-sprint-builds/QA/art_preview_polish03/run_20261013T143919247369Z/captures/ORIGINAL_q3_960x720.png)

**V6 非颜色线索有效性：1；加权 2.0。**

无纹样、内收标记或独立轮廓类别，主要依赖灰蓝颜色与空间间隔。

1分：非颜色类别线索很弱。 扣4分：同样平顶/直边仍与路块相似。

未解决：无首次真人理解性观察；不外推动态、其它站位或正式Shell。 主观判断：YES。

图片：[ORIGINAL_q0_1280x720.png](E:/godot/beta-sprint-builds/QA/art_preview_polish03/run_20261013T143919247369Z/captures/ORIGINAL_q0_1280x720.png) · [ORIGINAL_q0_960x720.png](E:/godot/beta-sprint-builds/QA/art_preview_polish03/run_20261013T143919247369Z/captures/ORIGINAL_q0_960x720.png) · [ORIGINAL_q1_1280x720.png](E:/godot/beta-sprint-builds/QA/art_preview_polish03/run_20261013T143919247369Z/captures/ORIGINAL_q1_1280x720.png) · [ORIGINAL_q1_960x720.png](E:/godot/beta-sprint-builds/QA/art_preview_polish03/run_20261013T143919247369Z/captures/ORIGINAL_q1_960x720.png) · [ORIGINAL_q2_1280x720.png](E:/godot/beta-sprint-builds/QA/art_preview_polish03/run_20261013T143919247369Z/captures/ORIGINAL_q2_1280x720.png) · [ORIGINAL_q2_960x720.png](E:/godot/beta-sprint-builds/QA/art_preview_polish03/run_20261013T143919247369Z/captures/ORIGINAL_q2_960x720.png) · [ORIGINAL_q3_1280x720.png](E:/godot/beta-sprint-builds/QA/art_preview_polish03/run_20261013T143919247369Z/captures/ORIGINAL_q3_1280x720.png) · [ORIGINAL_q3_960x720.png](E:/godot/beta-sprint-builds/QA/art_preview_polish03/run_20261013T143919247369Z/captures/ORIGINAL_q3_960x720.png)


### 方案 A：逐项依据

**V1 非可行走物体辨识性：3；加权 18.0。**

低饱和宽条纹覆盖顶面与侧面，明显区别于无纹道路；平顶仍在。

3分：可区分材质类别，但需观察且不直接等于不可走。 扣2分：条纹可能像矿纹或可攀附表面，不能证明玩家理解遮光用途。

未解决：无首次真人理解性观察；不外推动态、其它站位或正式Shell。 主观判断：YES。

图片：[A_q0_1280x720.png](E:/godot/beta-sprint-builds/QA/art_preview_polish03/run_20261013T143919247369Z/captures/A_q0_1280x720.png) · [A_q0_960x720.png](E:/godot/beta-sprint-builds/QA/art_preview_polish03/run_20261013T143919247369Z/captures/A_q0_960x720.png) · [A_q1_1280x720.png](E:/godot/beta-sprint-builds/QA/art_preview_polish03/run_20261013T143919247369Z/captures/A_q1_1280x720.png) · [A_q1_960x720.png](E:/godot/beta-sprint-builds/QA/art_preview_polish03/run_20261013T143919247369Z/captures/A_q1_960x720.png) · [A_q2_1280x720.png](E:/godot/beta-sprint-builds/QA/art_preview_polish03/run_20261013T143919247369Z/captures/A_q2_1280x720.png) · [A_q2_960x720.png](E:/godot/beta-sprint-builds/QA/art_preview_polish03/run_20261013T143919247369Z/captures/A_q2_960x720.png) · [A_q3_1280x720.png](E:/godot/beta-sprint-builds/QA/art_preview_polish03/run_20261013T143919247369Z/captures/A_q3_1280x720.png) · [A_q3_960x720.png](E:/godot/beta-sprint-builds/QA/art_preview_polish03/run_20261013T143919247369Z/captures/A_q3_960x720.png)

**V2 四视角辨识一致性：2；加权 8.0。**

北东南纹样清楚；西向两侧很暗，主要靠顶部条纹辨识。

2分：西向仍有明显混淆，不满足四向稳定清楚。 扣3分：暗面线索衰减；最高分视角不能抵消最弱视角。

未解决：无首次真人理解性观察；不外推动态、其它站位或正式Shell。 主观判断：YES。

图片：[A_q0_1280x720.png](E:/godot/beta-sprint-builds/QA/art_preview_polish03/run_20261013T143919247369Z/captures/A_q0_1280x720.png) · [A_q0_960x720.png](E:/godot/beta-sprint-builds/QA/art_preview_polish03/run_20261013T143919247369Z/captures/A_q0_960x720.png) · [A_q1_1280x720.png](E:/godot/beta-sprint-builds/QA/art_preview_polish03/run_20261013T143919247369Z/captures/A_q1_1280x720.png) · [A_q1_960x720.png](E:/godot/beta-sprint-builds/QA/art_preview_polish03/run_20261013T143919247369Z/captures/A_q1_960x720.png) · [A_q2_1280x720.png](E:/godot/beta-sprint-builds/QA/art_preview_polish03/run_20261013T143919247369Z/captures/A_q2_1280x720.png) · [A_q2_960x720.png](E:/godot/beta-sprint-builds/QA/art_preview_polish03/run_20261013T143919247369Z/captures/A_q2_960x720.png) · [A_q3_1280x720.png](E:/godot/beta-sprint-builds/QA/art_preview_polish03/run_20261013T143919247369Z/captures/A_q3_1280x720.png) · [A_q3_960x720.png](E:/godot/beta-sprint-builds/QA/art_preview_polish03/run_20261013T143919247369Z/captures/A_q3_960x720.png)

**V3 原有空间关系保持：5；加权 15.0。**

所有对照中外缘、平顶尺寸、悬空间距与道路关系保持；纹样未伸出轮廓。

5分：实图与同组几何记录共同支持静态关系保持。 本项未扣分；没有增加台阶或改变位置。

未解决：无首次真人理解性观察；不外推动态、其它站位或正式Shell。 主观判断：YES。

图片：[A_q0_1280x720.png](E:/godot/beta-sprint-builds/QA/art_preview_polish03/run_20261013T143919247369Z/captures/A_q0_1280x720.png) · [A_q0_960x720.png](E:/godot/beta-sprint-builds/QA/art_preview_polish03/run_20261013T143919247369Z/captures/A_q0_960x720.png) · [A_q1_1280x720.png](E:/godot/beta-sprint-builds/QA/art_preview_polish03/run_20261013T143919247369Z/captures/A_q1_1280x720.png) · [A_q1_960x720.png](E:/godot/beta-sprint-builds/QA/art_preview_polish03/run_20261013T143919247369Z/captures/A_q1_960x720.png) · [A_q2_1280x720.png](E:/godot/beta-sprint-builds/QA/art_preview_polish03/run_20261013T143919247369Z/captures/A_q2_1280x720.png) · [A_q2_960x720.png](E:/godot/beta-sprint-builds/QA/art_preview_polish03/run_20261013T143919247369Z/captures/A_q2_960x720.png) · [A_q3_1280x720.png](E:/godot/beta-sprint-builds/QA/art_preview_polish03/run_20261013T143919247369Z/captures/A_q3_1280x720.png) · [A_q3_960x720.png](E:/godot/beta-sprint-builds/QA/art_preview_polish03/run_20261013T143919247369Z/captures/A_q3_960x720.png)

**V4 材质符合度：4；加权 12.0。**

实图呈不透明哑光灰纹，无镜面亮斑或大面积发光；宽带纹样提供粗材质印象。

4分：静态粗纹/低反射目标表现良好。 扣1分：纹样偏平面条带，暗面质感较弱；不是触感或动态高光验证。

未解决：无首次真人理解性观察；不外推动态、其它站位或正式Shell。 主观判断：YES。

图片：[A_q0_1280x720.png](E:/godot/beta-sprint-builds/QA/art_preview_polish03/run_20261013T143919247369Z/captures/A_q0_1280x720.png) · [A_q0_960x720.png](E:/godot/beta-sprint-builds/QA/art_preview_polish03/run_20261013T143919247369Z/captures/A_q0_960x720.png) · [A_q1_1280x720.png](E:/godot/beta-sprint-builds/QA/art_preview_polish03/run_20261013T143919247369Z/captures/A_q1_1280x720.png) · [A_q1_960x720.png](E:/godot/beta-sprint-builds/QA/art_preview_polish03/run_20261013T143919247369Z/captures/A_q1_960x720.png) · [A_q2_1280x720.png](E:/godot/beta-sprint-builds/QA/art_preview_polish03/run_20261013T143919247369Z/captures/A_q2_1280x720.png) · [A_q2_960x720.png](E:/godot/beta-sprint-builds/QA/art_preview_polish03/run_20261013T143919247369Z/captures/A_q2_960x720.png) · [A_q3_1280x720.png](E:/godot/beta-sprint-builds/QA/art_preview_polish03/run_20261013T143919247369Z/captures/A_q3_1280x720.png) · [A_q3_960x720.png](E:/godot/beta-sprint-builds/QA/art_preview_polish03/run_20261013T143919247369Z/captures/A_q3_960x720.png)

**V5 世界美术风格一致性：NOT_ASSESSED；加权 NOT_ASSESSED。**

只有旧实验 Surface 及调试角色；未见 Inner/正式世界母版环境中的A。

完整世界风格匹配不能评估。 未评分；不能凭配色或shader名称补分。

未解决：缺少Inner/正式世界美术同屏。 主观判断：YES。

图片：[A_q0_1280x720.png](E:/godot/beta-sprint-builds/QA/art_preview_polish03/run_20261013T143919247369Z/captures/A_q0_1280x720.png) · [A_q0_960x720.png](E:/godot/beta-sprint-builds/QA/art_preview_polish03/run_20261013T143919247369Z/captures/A_q0_960x720.png) · [A_q1_1280x720.png](E:/godot/beta-sprint-builds/QA/art_preview_polish03/run_20261013T143919247369Z/captures/A_q1_1280x720.png) · [A_q1_960x720.png](E:/godot/beta-sprint-builds/QA/art_preview_polish03/run_20261013T143919247369Z/captures/A_q1_960x720.png) · [A_q2_1280x720.png](E:/godot/beta-sprint-builds/QA/art_preview_polish03/run_20261013T143919247369Z/captures/A_q2_1280x720.png) · [A_q2_960x720.png](E:/godot/beta-sprint-builds/QA/art_preview_polish03/run_20261013T143919247369Z/captures/A_q2_960x720.png) · [A_q3_1280x720.png](E:/godot/beta-sprint-builds/QA/art_preview_polish03/run_20261013T143919247369Z/captures/A_q3_1280x720.png) · [A_q3_960x720.png](E:/godot/beta-sprint-builds/QA/art_preview_polish03/run_20261013T143919247369Z/captures/A_q3_960x720.png)

**V6 非颜色线索有效性：4；加权 8.0。**

纹样以灰阶明暗而非鲜艳色块区分道路，各向顶面都有纹样。

4分：非颜色纹理线索明确。 扣1分：西向侧面较弱；未进行灰度/色弱测试，不能声称无障碍通过。

未解决：无首次真人理解性观察；不外推动态、其它站位或正式Shell。 主观判断：YES。

图片：[A_q0_1280x720.png](E:/godot/beta-sprint-builds/QA/art_preview_polish03/run_20261013T143919247369Z/captures/A_q0_1280x720.png) · [A_q0_960x720.png](E:/godot/beta-sprint-builds/QA/art_preview_polish03/run_20261013T143919247369Z/captures/A_q0_960x720.png) · [A_q1_1280x720.png](E:/godot/beta-sprint-builds/QA/art_preview_polish03/run_20261013T143919247369Z/captures/A_q1_1280x720.png) · [A_q1_960x720.png](E:/godot/beta-sprint-builds/QA/art_preview_polish03/run_20261013T143919247369Z/captures/A_q1_960x720.png) · [A_q2_1280x720.png](E:/godot/beta-sprint-builds/QA/art_preview_polish03/run_20261013T143919247369Z/captures/A_q2_1280x720.png) · [A_q2_960x720.png](E:/godot/beta-sprint-builds/QA/art_preview_polish03/run_20261013T143919247369Z/captures/A_q2_960x720.png) · [A_q3_1280x720.png](E:/godot/beta-sprint-builds/QA/art_preview_polish03/run_20261013T143919247369Z/captures/A_q3_1280x720.png) · [A_q3_960x720.png](E:/godot/beta-sprint-builds/QA/art_preview_polish03/run_20261013T143919247369Z/captures/A_q3_960x720.png)


### 方案 B：逐项依据

**V1 非可行走物体辨识性：2；加权 12.0。**

内收闭合框与短刻线醒目，但顶面像压力板/可交互面板，仍可能邀请站上去。

2分：外观有区别，非可走含义仍明显混淆。 扣3分：框线可能强化平台或机关感；不因醒目提高语义分。

未解决：无首次真人理解性观察；不外推动态、其它站位或正式Shell。 主观判断：YES。

图片：[B_q0_1280x720.png](E:/godot/beta-sprint-builds/QA/art_preview_polish03/run_20261013T143919247369Z/captures/B_q0_1280x720.png) · [B_q0_960x720.png](E:/godot/beta-sprint-builds/QA/art_preview_polish03/run_20261013T143919247369Z/captures/B_q0_960x720.png) · [B_q1_1280x720.png](E:/godot/beta-sprint-builds/QA/art_preview_polish03/run_20261013T143919247369Z/captures/B_q1_1280x720.png) · [B_q1_960x720.png](E:/godot/beta-sprint-builds/QA/art_preview_polish03/run_20261013T143919247369Z/captures/B_q1_960x720.png) · [B_q2_1280x720.png](E:/godot/beta-sprint-builds/QA/art_preview_polish03/run_20261013T143919247369Z/captures/B_q2_1280x720.png) · [B_q2_960x720.png](E:/godot/beta-sprint-builds/QA/art_preview_polish03/run_20261013T143919247369Z/captures/B_q2_960x720.png) · [B_q3_1280x720.png](E:/godot/beta-sprint-builds/QA/art_preview_polish03/run_20261013T143919247369Z/captures/B_q3_1280x720.png) · [B_q3_960x720.png](E:/godot/beta-sprint-builds/QA/art_preview_polish03/run_20261013T143919247369Z/captures/B_q3_960x720.png)

**V2 四视角辨识一致性：2；加权 8.0。**

四向都有框线，东向最清楚，西向暗侧弱；顶面闭框误读跨视角存在。

2分：四向都未可靠区分可行走性。 扣3分：暗侧减弱和面板语义风险；不是因B缺少精细模型扣分。

未解决：无首次真人理解性观察；不外推动态、其它站位或正式Shell。 主观判断：YES。

图片：[B_q0_1280x720.png](E:/godot/beta-sprint-builds/QA/art_preview_polish03/run_20261013T143919247369Z/captures/B_q0_1280x720.png) · [B_q0_960x720.png](E:/godot/beta-sprint-builds/QA/art_preview_polish03/run_20261013T143919247369Z/captures/B_q0_960x720.png) · [B_q1_1280x720.png](E:/godot/beta-sprint-builds/QA/art_preview_polish03/run_20261013T143919247369Z/captures/B_q1_1280x720.png) · [B_q1_960x720.png](E:/godot/beta-sprint-builds/QA/art_preview_polish03/run_20261013T143919247369Z/captures/B_q1_960x720.png) · [B_q2_1280x720.png](E:/godot/beta-sprint-builds/QA/art_preview_polish03/run_20261013T143919247369Z/captures/B_q2_1280x720.png) · [B_q2_960x720.png](E:/godot/beta-sprint-builds/QA/art_preview_polish03/run_20261013T143919247369Z/captures/B_q2_960x720.png) · [B_q3_1280x720.png](E:/godot/beta-sprint-builds/QA/art_preview_polish03/run_20261013T143919247369Z/captures/B_q3_1280x720.png) · [B_q3_960x720.png](E:/godot/beta-sprint-builds/QA/art_preview_polish03/run_20261013T143919247369Z/captures/B_q3_960x720.png)

**V3 原有空间关系保持：5；加权 15.0。**

边框绘制在原有面内；外轮廓、位置及悬空间距与当前版本一致。

5分：轻量材质概念保持静态空间关系。 本项未扣分；没有要求B制作真实凹槽或额外模型。

未解决：无首次真人理解性观察；不外推动态、其它站位或正式Shell。 主观判断：YES。

图片：[B_q0_1280x720.png](E:/godot/beta-sprint-builds/QA/art_preview_polish03/run_20261013T143919247369Z/captures/B_q0_1280x720.png) · [B_q0_960x720.png](E:/godot/beta-sprint-builds/QA/art_preview_polish03/run_20261013T143919247369Z/captures/B_q0_960x720.png) · [B_q1_1280x720.png](E:/godot/beta-sprint-builds/QA/art_preview_polish03/run_20261013T143919247369Z/captures/B_q1_1280x720.png) · [B_q1_960x720.png](E:/godot/beta-sprint-builds/QA/art_preview_polish03/run_20261013T143919247369Z/captures/B_q1_960x720.png) · [B_q2_1280x720.png](E:/godot/beta-sprint-builds/QA/art_preview_polish03/run_20261013T143919247369Z/captures/B_q2_1280x720.png) · [B_q2_960x720.png](E:/godot/beta-sprint-builds/QA/art_preview_polish03/run_20261013T143919247369Z/captures/B_q2_960x720.png) · [B_q3_1280x720.png](E:/godot/beta-sprint-builds/QA/art_preview_polish03/run_20261013T143919247369Z/captures/B_q3_1280x720.png) · [B_q3_960x720.png](E:/godot/beta-sprint-builds/QA/art_preview_polish03/run_20261013T143919247369Z/captures/B_q3_960x720.png)

**V4 材质符合度：3；加权 9.0。**

不透明无镜面亮斑；框线呈整洁硬表面，粗纹读感弱。

3分：不透明低反射基本可见，粗糙视觉不足。 扣2分：面板式平涂感，基于实际图像而非建模精度。

未解决：无首次真人理解性观察；不外推动态、其它站位或正式Shell。 主观判断：YES。

图片：[B_q0_1280x720.png](E:/godot/beta-sprint-builds/QA/art_preview_polish03/run_20261013T143919247369Z/captures/B_q0_1280x720.png) · [B_q0_960x720.png](E:/godot/beta-sprint-builds/QA/art_preview_polish03/run_20261013T143919247369Z/captures/B_q0_960x720.png) · [B_q1_1280x720.png](E:/godot/beta-sprint-builds/QA/art_preview_polish03/run_20261013T143919247369Z/captures/B_q1_1280x720.png) · [B_q1_960x720.png](E:/godot/beta-sprint-builds/QA/art_preview_polish03/run_20261013T143919247369Z/captures/B_q1_960x720.png) · [B_q2_1280x720.png](E:/godot/beta-sprint-builds/QA/art_preview_polish03/run_20261013T143919247369Z/captures/B_q2_1280x720.png) · [B_q2_960x720.png](E:/godot/beta-sprint-builds/QA/art_preview_polish03/run_20261013T143919247369Z/captures/B_q2_960x720.png) · [B_q3_1280x720.png](E:/godot/beta-sprint-builds/QA/art_preview_polish03/run_20261013T143919247369Z/captures/B_q3_1280x720.png) · [B_q3_960x720.png](E:/godot/beta-sprint-builds/QA/art_preview_polish03/run_20261013T143919247369Z/captures/B_q3_960x720.png)

**V5 世界美术风格一致性：NOT_ASSESSED；加权 NOT_ASSESSED。**

B只有同一旧 Surface 背景，无 Inner/正式母版同屏。

完整世界风格匹配不能评估。 未评分；不虚构B正式模型或世界渲染。

未解决：缺少Inner/正式世界美术同屏。 主观判断：YES。

图片：[B_q0_1280x720.png](E:/godot/beta-sprint-builds/QA/art_preview_polish03/run_20261013T143919247369Z/captures/B_q0_1280x720.png) · [B_q0_960x720.png](E:/godot/beta-sprint-builds/QA/art_preview_polish03/run_20261013T143919247369Z/captures/B_q0_960x720.png) · [B_q1_1280x720.png](E:/godot/beta-sprint-builds/QA/art_preview_polish03/run_20261013T143919247369Z/captures/B_q1_1280x720.png) · [B_q1_960x720.png](E:/godot/beta-sprint-builds/QA/art_preview_polish03/run_20261013T143919247369Z/captures/B_q1_960x720.png) · [B_q2_1280x720.png](E:/godot/beta-sprint-builds/QA/art_preview_polish03/run_20261013T143919247369Z/captures/B_q2_1280x720.png) · [B_q2_960x720.png](E:/godot/beta-sprint-builds/QA/art_preview_polish03/run_20261013T143919247369Z/captures/B_q2_960x720.png) · [B_q3_1280x720.png](E:/godot/beta-sprint-builds/QA/art_preview_polish03/run_20261013T143919247369Z/captures/B_q3_1280x720.png) · [B_q3_960x720.png](E:/godot/beta-sprint-builds/QA/art_preview_polish03/run_20261013T143919247369Z/captures/B_q3_960x720.png)

**V6 非颜色线索有效性：3；加权 6.0。**

封闭边框/短刻线无需鲜艳颜色可见，但与其它机关标记的含义冲突。

3分：非颜色线索存在，类别含义不足。 扣2分：更像交互面板，暗侧框线易消失。

未解决：无首次真人理解性观察；不外推动态、其它站位或正式Shell。 主观判断：YES。

图片：[B_q0_1280x720.png](E:/godot/beta-sprint-builds/QA/art_preview_polish03/run_20261013T143919247369Z/captures/B_q0_1280x720.png) · [B_q0_960x720.png](E:/godot/beta-sprint-builds/QA/art_preview_polish03/run_20261013T143919247369Z/captures/B_q0_960x720.png) · [B_q1_1280x720.png](E:/godot/beta-sprint-builds/QA/art_preview_polish03/run_20261013T143919247369Z/captures/B_q1_1280x720.png) · [B_q1_960x720.png](E:/godot/beta-sprint-builds/QA/art_preview_polish03/run_20261013T143919247369Z/captures/B_q1_960x720.png) · [B_q2_1280x720.png](E:/godot/beta-sprint-builds/QA/art_preview_polish03/run_20261013T143919247369Z/captures/B_q2_1280x720.png) · [B_q2_960x720.png](E:/godot/beta-sprint-builds/QA/art_preview_polish03/run_20261013T143919247369Z/captures/B_q2_960x720.png) · [B_q3_1280x720.png](E:/godot/beta-sprint-builds/QA/art_preview_polish03/run_20261013T143919247369Z/captures/B_q3_1280x720.png) · [B_q3_960x720.png](E:/godot/beta-sprint-builds/QA/art_preview_polish03/run_20261013T143919247369Z/captures/B_q3_960x720.png)

## 四固定视角道路辨识

方位来自正式 Host 与 view_contract，Q0/1/2/3 对应北/东/南/西；不是按一般世界轴猜测。每行同时查看1280×720与960×720原帧。

[view_contract.gd](E:/godot/worktrees/bg-formal01/foundation/game_feel/view_contract.gd) · [spatial_lab.gd](E:/godot/worktrees/bg-formal01/experiments/spatial_puzzle_batch_01/host/spatial_lab.gd) · [report.json](E:/godot/beta-sprint-builds/QA/art_preview_polish03/run_20261013T143919247369Z/captures/report.json)

| 视角 | 当前 | A | B | 当前证据 | A证据 | B证据 |
|---|---:|---:|---:|---|---|---|
| 北 / NORTH | 2 | 3 | 2 | [ORIGINAL_q0_1280x720.png](E:/godot/beta-sprint-builds/QA/art_preview_polish03/run_20261013T143919247369Z/captures/ORIGINAL_q0_1280x720.png) · [ORIGINAL_q0_960x720.png](E:/godot/beta-sprint-builds/QA/art_preview_polish03/run_20261013T143919247369Z/captures/ORIGINAL_q0_960x720.png) | [A_q0_1280x720.png](E:/godot/beta-sprint-builds/QA/art_preview_polish03/run_20261013T143919247369Z/captures/A_q0_1280x720.png) · [A_q0_960x720.png](E:/godot/beta-sprint-builds/QA/art_preview_polish03/run_20261013T143919247369Z/captures/A_q0_960x720.png) | [B_q0_1280x720.png](E:/godot/beta-sprint-builds/QA/art_preview_polish03/run_20261013T143919247369Z/captures/B_q0_1280x720.png) · [B_q0_960x720.png](E:/godot/beta-sprint-builds/QA/art_preview_polish03/run_20261013T143919247369Z/captures/B_q0_960x720.png) |
| 东 / EAST | 2 | 3 | 2 | [ORIGINAL_q1_1280x720.png](E:/godot/beta-sprint-builds/QA/art_preview_polish03/run_20261013T143919247369Z/captures/ORIGINAL_q1_1280x720.png) · [ORIGINAL_q1_960x720.png](E:/godot/beta-sprint-builds/QA/art_preview_polish03/run_20261013T143919247369Z/captures/ORIGINAL_q1_960x720.png) | [A_q1_1280x720.png](E:/godot/beta-sprint-builds/QA/art_preview_polish03/run_20261013T143919247369Z/captures/A_q1_1280x720.png) · [A_q1_960x720.png](E:/godot/beta-sprint-builds/QA/art_preview_polish03/run_20261013T143919247369Z/captures/A_q1_960x720.png) | [B_q1_1280x720.png](E:/godot/beta-sprint-builds/QA/art_preview_polish03/run_20261013T143919247369Z/captures/B_q1_1280x720.png) · [B_q1_960x720.png](E:/godot/beta-sprint-builds/QA/art_preview_polish03/run_20261013T143919247369Z/captures/B_q1_960x720.png) |
| 南 / SOUTH | 2 | 3 | 2 | [ORIGINAL_q2_1280x720.png](E:/godot/beta-sprint-builds/QA/art_preview_polish03/run_20261013T143919247369Z/captures/ORIGINAL_q2_1280x720.png) · [ORIGINAL_q2_960x720.png](E:/godot/beta-sprint-builds/QA/art_preview_polish03/run_20261013T143919247369Z/captures/ORIGINAL_q2_960x720.png) | [A_q2_1280x720.png](E:/godot/beta-sprint-builds/QA/art_preview_polish03/run_20261013T143919247369Z/captures/A_q2_1280x720.png) · [A_q2_960x720.png](E:/godot/beta-sprint-builds/QA/art_preview_polish03/run_20261013T143919247369Z/captures/A_q2_960x720.png) | [B_q2_1280x720.png](E:/godot/beta-sprint-builds/QA/art_preview_polish03/run_20261013T143919247369Z/captures/B_q2_1280x720.png) · [B_q2_960x720.png](E:/godot/beta-sprint-builds/QA/art_preview_polish03/run_20261013T143919247369Z/captures/B_q2_960x720.png) |
| 西 / WEST | 2 | 2 | 2 | [ORIGINAL_q3_1280x720.png](E:/godot/beta-sprint-builds/QA/art_preview_polish03/run_20261013T143919247369Z/captures/ORIGINAL_q3_1280x720.png) · [ORIGINAL_q3_960x720.png](E:/godot/beta-sprint-builds/QA/art_preview_polish03/run_20261013T143919247369Z/captures/ORIGINAL_q3_960x720.png) | [A_q3_1280x720.png](E:/godot/beta-sprint-builds/QA/art_preview_polish03/run_20261013T143919247369Z/captures/A_q3_1280x720.png) · [A_q3_960x720.png](E:/godot/beta-sprint-builds/QA/art_preview_polish03/run_20261013T143919247369Z/captures/A_q3_960x720.png) | [B_q3_1280x720.png](E:/godot/beta-sprint-builds/QA/art_preview_polish03/run_20261013T143919247369Z/captures/B_q3_1280x720.png) · [B_q3_960x720.png](E:/godot/beta-sprint-builds/QA/art_preview_polish03/run_20261013T143919247369Z/captures/B_q3_960x720.png) |

### 当前材质参照：逐视角问题

- 北 / NORTH：平顶/直边与脚下平台同类，文字靠近角色。 扣3分：平顶/直边与脚下平台同类，文字靠近角色。 此为评审判断，不是玩家理解率。
- 东 / EAST：悬空距离更清楚，但平顶仍像目标平台。 扣3分：悬空距离更清楚，但平顶仍像目标平台。 此为评审判断，不是玩家理解率。
- 南 / SOUTH：平顶与道路几何语言相同，暗侧无独立标记。 扣3分：平顶与道路几何语言相同，暗侧无独立标记。 此为评审判断，不是玩家理解率。
- 西 / WEST：两侧近黑，主要剩平顶轮廓；仍像路块。 扣3分：两侧近黑，主要剩平顶轮廓；仍像路块。 此为评审判断，不是玩家理解率。

已评 4/4；最低 2；平均 2.0。最易混淆：西 / WEST，Q3暗侧最弱；其它方向也存在平台语义风险。 覆盖 COMPLETE，仅 四固定90度、Surface/source、原生1280×720与960×720；未覆盖Inner/动态。。

### 方案 A：逐视角问题

- 北 / NORTH：顶面与亮侧条纹可见，暗侧弱，仍需辨认用途。 扣2分：顶面与亮侧条纹可见，暗侧弱，仍需辨认用途。 此为评审判断，不是玩家理解率。
- 东 / EAST：双亮侧纹样清楚，与素色道路区别最大，但可走含义未明确。 扣2分：双亮侧纹样清楚，与素色道路区别最大，但可走含义未明确。 此为评审判断，不是玩家理解率。
- 南 / SOUTH：顶面和右侧条纹可见，左暗侧弱。 扣2分：顶面和右侧条纹可见，左暗侧弱。 此为评审判断，不是玩家理解率。
- 西 / WEST：两侧条纹低对比，主要依赖顶部；未达到稳定清楚。 扣3分：两侧条纹低对比，主要依赖顶部；未达到稳定清楚。 此为评审判断，不是玩家理解率。

已评 4/4；最低 2；平均 2.8。最易混淆：西 / WEST，Q3暗侧最弱；其它方向也存在平台语义风险。 覆盖 COMPLETE，仅 四固定90度、Surface/source、原生1280×720与960×720；未覆盖Inner/动态。。

### 方案 B：逐视角问题

- 北 / NORTH：边框像可站立/可激活面板，右暗侧刻线较弱。 扣3分：边框像可站立/可激活面板，右暗侧刻线较弱。 此为评审判断，不是玩家理解率。
- 东 / EAST：框线最清楚，但箱体/机关面板读感更强。 扣3分：框线最清楚，但箱体/机关面板读感更强。 此为评审判断，不是玩家理解率。
- 南 / SOUTH：顶面闭框像落脚区域，左侧暗。 扣3分：顶面闭框像落脚区域，左侧暗。 此为评审判断，不是玩家理解率。
- 西 / WEST：两侧近黑框线弱，顶面闭框仍像踏板。 扣3分：两侧近黑框线弱，顶面闭框仍像踏板。 此为评审判断，不是玩家理解率。

已评 4/4；最低 2；平均 2.0。最易混淆：西 / WEST，Q3暗侧最弱；其它方向也存在平台语义风险。 覆盖 COMPLETE，仅 四固定90度、Surface/source、原生1280×720与960×720；未覆盖Inner/动态。。

## 同条件核验

Same-condition historical static Surface/source material comparison ONLY; not current formal Shell or both worlds.

| 条件 | 当前 / A / B 的实际共同条件 | 状态 | 证据 | 限制 |
|---|---|---|---|---|
| 场景背景 | Same historical experiment gray background / debug actor | PASS | [roof_preview.gd](E:/godot/worktrees/bg-formal01/tests/beta_sprint/spatial_art/polish_03/roof_preview.gd) · [project.godot](E:/godot/beta-sprint-builds/QA/art_preview_polish03/run_20261013T143919247369Z/project/project.godot) · [spatial_level.gd](E:/godot/worktrees/bg-formal01/game/levels/mutsumi/spatial_chapter/spatial_level.gd) | 正式Shell有水色背景和不同HUD，未外推。 |
| Camera身份 | Same real Host Camera3D, orthographic | PASS | [view_contract.gd](E:/godot/worktrees/bg-formal01/foundation/game_feel/view_contract.gd) · [core_lab.gd](E:/godot/worktrees/bg-formal01/experiments/game_feel_01/host/core_lab.gd) · [report.json](E:/godot/beta-sprint-builds/QA/art_preview_polish03/run_20261013T143919247369Z/captures/report.json) | 不是自由相机。 |
| 相机位置与朝向 | Exact same recorded transform per quadrant and size group | PASS | [report.json](E:/godot/beta-sprint-builds/QA/art_preview_polish03/run_20261013T143919247369Z/captures/report.json) · [view_contract.gd](E:/godot/worktrees/bg-formal01/foundation/game_feel/view_contract.gd) | 每个q定义不同，不能声称四向transform相同。 |
| 灯光配置 | Shared DirectionalLight3D rotation (-45,-30,0), energy 1.5 | PASS | [core_lab.gd](E:/godot/worktrees/bg-formal01/experiments/game_feel_01/host/core_lab.gd) · [roof_preview.gd](E:/godot/worktrees/bg-formal01/tests/beta_sprint/spatial_art/polish_03/roof_preview.gd) | 源码固定配置；report未实测灯光字段。 |
| 渲染引擎 | Same historical Godot4.7.2-stable steam / Forward+ / D3D12 | PASS | [godot.log](E:/godot/beta-sprint-builds/QA/art_preview_polish03/run_20261013T143919247369Z/godot.log) · [report.json](E:/godot/beta-sprint-builds/QA/art_preview_polish03/run_20261013T143919247369Z/captures/report.json) | 历史单进程，未重启渲染。 |
| 输出分辨率 | 1280x720 and 960x720, compared within equal-size groups | PASS | [report.json](E:/godot/beta-sprint-builds/QA/art_preview_polish03/run_20261013T143919247369Z/captures/report.json) | KEEP_HEIGHT保持物体像素尺寸；不是更小机关测试。 |
| 色彩管理 | Same engine defaults; no custom WorldEnvironment/CameraAttributes override | PASS | [core_lab.gd](E:/godot/worktrees/bg-formal01/experiments/game_feel_01/host/core_lab.gd) · [roof_preview.gd](E:/godot/worktrees/bg-formal01/tests/beta_sprint/spatial_art/polish_03/roof_preview.gd) · [project.godot](E:/godot/beta-sprint-builds/QA/art_preview_polish03/run_20261013T143919247369Z/project/project.godot) | 无数值实录，不虚构tonemap或色彩参数。 |
| 曝光 | Shared defaults; no per-variant exposure change | PASS | [core_lab.gd](E:/godot/worktrees/bg-formal01/experiments/game_feel_01/host/core_lab.gd) · [roof_preview.gd](E:/godot/worktrees/bg-formal01/tests/beta_sprint/spatial_art/polish_03/roof_preview.gd) | 无数值实录；不能填曝光=1等猜值。 |
| 取景范围 | size=10, KEEP_HEIGHT=1, fixed source pose | PASS | [report.json](E:/godot/beta-sprint-builds/QA/art_preview_polish03/run_20261013T143919247369Z/captures/report.json) | 仅静态Surface/source。 |
| 其他参数 | Same recorded geometry/state/roof screen center; only material and label differ | PASS | [report.json](E:/godot/beta-sprint-builds/QA/art_preview_polish03/run_20261013T143919247369Z/captures/report.json) · [roof_preview.gd](E:/godot/worktrees/bg-formal01/tests/beta_sprint/spatial_art/polish_03/roof_preview.gd) | variant标识文字有意不同，不用于评分。 |

未覆盖：INNER and formal world art context；Current formal Shell new rendering；Gate standing position / animated intermediate frames；Human comprehension / actual input diagnostic；Smaller object pixel size / grayscale or color-vision simulation。

## 硬性门槛

| 编号 | 门槛 | 状态 | 观察 | 证据 | 范围限制 |
|---|---|---|---|---|---|
| G1 | 源资产身份 | PASS | 同一真roof源码、作者场景、preview/formal/current六项来源字节一致；不是Blender替代模型。 | [core_lab.gd](E:/godot/worktrees/bg-formal01/experiments/game_feel_01/host/core_lab.gd) · [spatial_lab.gd](E:/godot/worktrees/bg-formal01/experiments/spatial_puzzle_batch_01/host/spatial_lab.gd) · [surface.tscn](E:/godot/worktrees/bg-formal01/experiments/spatial_puzzle_batch_01/maps/authoring/world_shift_gate_lab/surface.tscn) · [BUILD_IDENTITY.json](E:/godot/beta-sprint-builds/beta_spatial_formal_chapter_20261019_01/BUILD_IDENTITY.json) · [BUILD_IDENTITY.json](E:/godot/beta-sprint-builds/beta_spatial_acceptance_input_fix_20261013_01/BUILD_IDENTITY.json) · [roof_preview.gd](E:/godot/worktrees/bg-formal01/tests/beta_sprint/spatial_art/polish_03/roof_preview.gd) | 对象同源不等于整个入口画面同版。 |
| G2 | 独立预览 | PASS | A/B只在隔离副本替换roof材质，正式Build未包含预览脚本/shader。 | [process.json](E:/godot/beta-sprint-builds/QA/art_preview_polish03/run_20261013T143919247369Z/process.json) · [roof_preview.gd](E:/godot/worktrees/bg-formal01/tests/beta_sprint/spatial_art/polish_03/roof_preview.gd) · [roof_coarse.gdshader](E:/godot/worktrees/bg-formal01/tests/beta_sprint/spatial_art/polish_03/roof_coarse.gdshader) · [roof_inset.gdshader](E:/godot/worktrees/bg-formal01/tests/beta_sprint/spatial_art/polish_03/roof_inset.gdshader) | 独立预览不要求创造一套正式Blender资产。 |
| G3 | 同条件对比 | PASS | 八个q×尺寸组内camera/state/geometry精确相同；源码与同进程证据支持共同灯光与默认色彩。 | [report.json](E:/godot/beta-sprint-builds/QA/art_preview_polish03/run_20261013T143919247369Z/captures/report.json) · [core_lab.gd](E:/godot/worktrees/bg-formal01/experiments/game_feel_01/host/core_lab.gd) · [roof_preview.gd](E:/godot/worktrees/bg-formal01/tests/beta_sprint/spatial_art/polish_03/roof_preview.gd) · [project.godot](E:/godot/beta-sprint-builds/QA/art_preview_polish03/run_20261013T143919247369Z/project/project.godot) | 仅旧组内PASS；色彩/曝光无数值采样，不外推正式Shell。 |
| G4 | 四视角覆盖 | PASS | 当前材质/A/B各四向两尺寸实图已逐张检查；B确有实图。 | [report.json](E:/godot/beta-sprint-builds/QA/art_preview_polish03/run_20261013T143919247369Z/captures/report.json) · [ORIGINAL_q0_1280x720.png](E:/godot/beta-sprint-builds/QA/art_preview_polish03/run_20261013T143919247369Z/captures/ORIGINAL_q0_1280x720.png) · [ORIGINAL_q1_1280x720.png](E:/godot/beta-sprint-builds/QA/art_preview_polish03/run_20261013T143919247369Z/captures/ORIGINAL_q1_1280x720.png) · [ORIGINAL_q2_1280x720.png](E:/godot/beta-sprint-builds/QA/art_preview_polish03/run_20261013T143919247369Z/captures/ORIGINAL_q2_1280x720.png) · [ORIGINAL_q3_1280x720.png](E:/godot/beta-sprint-builds/QA/art_preview_polish03/run_20261013T143919247369Z/captures/ORIGINAL_q3_1280x720.png) · [A_q0_1280x720.png](E:/godot/beta-sprint-builds/QA/art_preview_polish03/run_20261013T143919247369Z/captures/A_q0_1280x720.png) · [A_q1_1280x720.png](E:/godot/beta-sprint-builds/QA/art_preview_polish03/run_20261013T143919247369Z/captures/A_q1_1280x720.png) · [A_q2_1280x720.png](E:/godot/beta-sprint-builds/QA/art_preview_polish03/run_20261013T143919247369Z/captures/A_q2_1280x720.png) · [A_q3_1280x720.png](E:/godot/beta-sprint-builds/QA/art_preview_polish03/run_20261013T143919247369Z/captures/A_q3_1280x720.png) · [B_q0_1280x720.png](E:/godot/beta-sprint-builds/QA/art_preview_polish03/run_20261013T143919247369Z/captures/B_q0_1280x720.png) · [B_q1_1280x720.png](E:/godot/beta-sprint-builds/QA/art_preview_polish03/run_20261013T143919247369Z/captures/B_q1_1280x720.png) · [B_q2_1280x720.png](E:/godot/beta-sprint-builds/QA/art_preview_polish03/run_20261013T143919247369Z/captures/B_q2_1280x720.png) · [B_q3_1280x720.png](E:/godot/beta-sprint-builds/QA/art_preview_polish03/run_20261013T143919247369Z/captures/B_q3_1280x720.png) | 四向证据覆盖PASS不是四向语义辨识PASS。 |
| G5 | 主要轮廓 | PASS | A不改变边界、悬空间距与主要位置；实图和同组网格记录一致。 | [A_q0_1280x720.png](E:/godot/beta-sprint-builds/QA/art_preview_polish03/run_20261013T143919247369Z/captures/A_q0_1280x720.png) · [A_q1_1280x720.png](E:/godot/beta-sprint-builds/QA/art_preview_polish03/run_20261013T143919247369Z/captures/A_q1_1280x720.png) · [A_q2_1280x720.png](E:/godot/beta-sprint-builds/QA/art_preview_polish03/run_20261013T143919247369Z/captures/A_q2_1280x720.png) · [A_q3_1280x720.png](E:/godot/beta-sprint-builds/QA/art_preview_polish03/run_20261013T143919247369Z/captures/A_q3_1280x720.png) · [report.json](E:/godot/beta-sprint-builds/QA/art_preview_polish03/run_20261013T143919247369Z/captures/report.json) | 静态几何和正式规则保持；没有新动态遮光测试。 |
| G6 | 材质目标 | PASS | A实图不透明、哑光灰纹，无镜面亮斑或大面积发光；shader实现仅辅助证据。 | [A_q0_1280x720.png](E:/godot/beta-sprint-builds/QA/art_preview_polish03/run_20261013T143919247369Z/captures/A_q0_1280x720.png) · [A_q1_1280x720.png](E:/godot/beta-sprint-builds/QA/art_preview_polish03/run_20261013T143919247369Z/captures/A_q1_1280x720.png) · [A_q2_1280x720.png](E:/godot/beta-sprint-builds/QA/art_preview_polish03/run_20261013T143919247369Z/captures/A_q2_1280x720.png) · [A_q3_1280x720.png](E:/godot/beta-sprint-builds/QA/art_preview_polish03/run_20261013T143919247369Z/captures/A_q3_1280x720.png) · [roof_coarse.gdshader](E:/godot/worktrees/bg-formal01/tests/beta_sprint/spatial_art/polish_03/roof_coarse.gdshader) | 静态低反射目标PASS，不代表质感满分或所有照明下通过。 |
| G7 | 非颜色依赖 | PASS | A的灰阶条纹、B的内收框线提供形状/纹理线索；不是鲜艳色块或发光。 | [A_q1_1280x720.png](E:/godot/beta-sprint-builds/QA/art_preview_polish03/run_20261013T143919247369Z/captures/A_q1_1280x720.png) · [A_q3_1280x720.png](E:/godot/beta-sprint-builds/QA/art_preview_polish03/run_20261013T143919247369Z/captures/A_q3_1280x720.png) · [B_q1_1280x720.png](E:/godot/beta-sprint-builds/QA/art_preview_polish03/run_20261013T143919247369Z/captures/B_q1_1280x720.png) · [B_q3_1280x720.png](E:/godot/beta-sprint-builds/QA/art_preview_polish03/run_20261013T143919247369Z/captures/B_q3_1280x720.png) · [roof_coarse.gdshader](E:/godot/worktrees/bg-formal01/tests/beta_sprint/spatial_art/polish_03/roof_coarse.gdshader) · [roof_inset.gdshader](E:/godot/worktrees/bg-formal01/tests/beta_sprint/spatial_art/polish_03/roof_inset.gdshader) | 存在非颜色线索不等于正确传达不可行走；未测试色弱。 |
| G8 | 生产安全 | PASS | 本轮只读原图/源码并新增评分文档与验证工具；正式Build1783项、旧预览1759项、历史证据及存档前后清单哈希一致。 | [PRESERVATION_BEFORE.json](E:/godot/beta-sprint-builds/floating_cube_scoring05_20261021_01/PRESERVATION_BEFORE.json) · [BUILD_IDENTITY.json](E:/godot/beta-sprint-builds/beta_spatial_formal_chapter_20261019_01/BUILD_IDENTITY.json) · [PRESERVATION_AFTER.json](E:/godot/beta-sprint-builds/floating_cube_scoring05_20261021_01/PRESERVATION_AFTER.json) | 已对明确基线清单执行结束比对，非全磁盘声明；只有本轮评分文档/验证工具变更，未改主干/tag。 |

所有门槛的限定PASS不覆盖缺失的V5，也不抵消低于3分的最弱视角；整体保持PARTIAL。

## 候选比较与建议

A−当前完整总分：NOT_ASSESSED；B−当前：NOT_ASSESSED；A−B：NOT_ASSESSED。

共同90%权重小计差值：A−当前 **15.0**；B−当前 **4.0**；A−B **11.0**。仅V1/V2/V3/V4/V6共同90%权重小计，未归一化；完整总分与完整差值均NOT_ASSESSED。

A优势：宽条纹比原版提供更多非颜色材质类别线索，保留轮廓。

A不足：西向暗侧弱；条纹不自动说明不可站立，可能产生攀附/矿纹联想。

B优势：内收框线在亮面清楚，轻量概念已有四向实图，无需精细模型才能比较。

B不足：闭合顶框像压力板/可激活面板，非可行走含义仍混淆。

A可优先继续隔离验证，尚未达到正式视觉接受；先补Inner/正式世界同屏并验证最弱西向与首次玩家语义。B需要降低交互面板误读。保持生产原样，等待用户批准。

## 输入、真人QA与安全

- 输入诊断准备完整性：PASS；执行就绪：PARTIAL；实际执行：NOT_RUN。协议包含独立环境、PID/start/session/window、时钟/ACK/接收连续性和停止条件。 未完成：独立可控环境、支持的native工具、approved接收通道未建立；原因UNKNOWN。 证据：[CORRELATED_INPUT_PROTOCOL.md](E:/godot/worktrees/bg-formal01/docs/beta-sprint/spatial-formal-chapter-01/continuation-04/input/CORRELATED_INPUT_PROTOCOL.md) · [EVENT_TEMPLATE.json](E:/godot/worktrees/bg-formal01/docs/beta-sprint/spatial-formal-chapter-01/continuation-04/input/EVENT_TEMPLATE.json) · [REPORT.md](E:/godot/worktrees/bg-formal01/docs/beta-sprint/spatial-formal-chapter-01/continuation-04/input/REPORT.md)
- 真人QA准备完整性：PASS；执行就绪：PARTIAL；实际执行：NOT_RUN。组合协议覆盖资格、隔离存档、无作者解法、发现时间/预测/提示/卡点/原话；旧模板身份须更新。 未完成：合格首次玩家NONE；未来实际核验新Build、source/package/manifest及新会话副本。 证据：[HUMAN_QA_PROTOCOL.md](E:/godot/worktrees/bg-formal01/docs/beta-sprint/spatial-formal-chapter-01/continuation-02/HUMAN_QA_PROTOCOL.md) · [SESSION_TEMPLATE.json](E:/godot/worktrees/bg-formal01/docs/beta-sprint/spatial-formal-chapter-01/continuation-02/SESSION_TEMPLATE.json) · [HUMAN_QA_EXECUTION_ADDENDUM.md](E:/godot/worktrees/bg-formal01/docs/beta-sprint/spatial-formal-chapter-01/continuation-03/HUMAN_QA_EXECUTION_ADDENDUM.md) · [REPORT.md](E:/godot/worktrees/bg-formal01/docs/beta-sprint/spatial-formal-chapter-01/continuation-04/input/REPORT.md)

| 状态 | 实际 |
|---|---|
| overall_visual_review | PARTIAL |
| road_recognition | PARTIAL |
| preview_integrity | PASS |
| input_environment | UNKNOWN |
| graphical_diagnostic | NOT_RUN |
| human_qa | NOT_RUN |
| qualified_player | NONE |
| first_time_comprehension | NOT_OBSERVED |
| authorization_and_file_safety | PASS |
| formal_asset_approval | NOT_GRANTED |
| art_change | PROPOSAL_ONLY |
| game_integration | NOT_RUN |
| production_changes | NONE |
| new_build | NOT_REQUIRED |
| preview_completeness | PARTIAL |

未完成事项：

- V5缺Inner/正式世界美术证据，三个完整总分均NOT_ASSESSED
- 所有候选最弱四向辨识分低于3；不能报告语义辨识完整PASS
- 未执行动态图形、输入诊断或首次真人理解测试
- Floating Cube正式方案仍需用户批准，三个原始Art文件恢复仍有独立来源阻塞

## 可追溯证据

24张评分图片由本轮实际打开观察；32张历史捕获重新核验哈希，另外8张C未纳入评分。历史261项图形检查不是本轮新增执行。所有路径在本机核实存在，SHA由实际字节计算。

| ID | 文件 | SHA-256 | 本轮检查 |
|---|---|---|---|
| ORIGINAL_Q0_1280 | [ORIGINAL_q0_1280x720.png](E:/godot/beta-sprint-builds/QA/art_preview_polish03/run_20261013T143919247369Z/captures/ORIGINAL_q0_1280x720.png) | `c68952e40a18f01e2fdfce373026acef0607df0785546a062c532a495a4bbeae` | ACTUALLY_VIEWED_BY_CODEX_2026_10_21; PNG_HEADER_AND_SHA_VERIFIED |
| ORIGINAL_Q0_960 | [ORIGINAL_q0_960x720.png](E:/godot/beta-sprint-builds/QA/art_preview_polish03/run_20261013T143919247369Z/captures/ORIGINAL_q0_960x720.png) | `077ec3fc1374bfa5cf2e0683528358b6fee22e8ab316f28678c47e85ed467294` | ACTUALLY_VIEWED_BY_CODEX_2026_10_21; PNG_HEADER_AND_SHA_VERIFIED |
| ORIGINAL_Q1_1280 | [ORIGINAL_q1_1280x720.png](E:/godot/beta-sprint-builds/QA/art_preview_polish03/run_20261013T143919247369Z/captures/ORIGINAL_q1_1280x720.png) | `e83d2fd16fb96fbb0abc79b04a36c8b7fc9f307d7e4973412f66ff7496a8bd56` | ACTUALLY_VIEWED_BY_CODEX_2026_10_21; PNG_HEADER_AND_SHA_VERIFIED |
| ORIGINAL_Q1_960 | [ORIGINAL_q1_960x720.png](E:/godot/beta-sprint-builds/QA/art_preview_polish03/run_20261013T143919247369Z/captures/ORIGINAL_q1_960x720.png) | `1a5c3b1626e4fd5e18c271a218b9e8aae8d57f16ac155511ea1428349fd72daf` | ACTUALLY_VIEWED_BY_CODEX_2026_10_21; PNG_HEADER_AND_SHA_VERIFIED |
| ORIGINAL_Q2_1280 | [ORIGINAL_q2_1280x720.png](E:/godot/beta-sprint-builds/QA/art_preview_polish03/run_20261013T143919247369Z/captures/ORIGINAL_q2_1280x720.png) | `10f6c9fb801f9417328ebf06f834c49e3905764fc99271edfe74dea1665749c9` | ACTUALLY_VIEWED_BY_CODEX_2026_10_21; PNG_HEADER_AND_SHA_VERIFIED |
| ORIGINAL_Q2_960 | [ORIGINAL_q2_960x720.png](E:/godot/beta-sprint-builds/QA/art_preview_polish03/run_20261013T143919247369Z/captures/ORIGINAL_q2_960x720.png) | `048c26e80fa19ce9a377cb4554a5a100c648ba35c31469bbaad6f5d7290638a0` | ACTUALLY_VIEWED_BY_CODEX_2026_10_21; PNG_HEADER_AND_SHA_VERIFIED |
| ORIGINAL_Q3_1280 | [ORIGINAL_q3_1280x720.png](E:/godot/beta-sprint-builds/QA/art_preview_polish03/run_20261013T143919247369Z/captures/ORIGINAL_q3_1280x720.png) | `d5d79478ab1c1951708fbbc08d3aeee68da44547c662173118436ec832b7bec5` | ACTUALLY_VIEWED_BY_CODEX_2026_10_21; PNG_HEADER_AND_SHA_VERIFIED |
| ORIGINAL_Q3_960 | [ORIGINAL_q3_960x720.png](E:/godot/beta-sprint-builds/QA/art_preview_polish03/run_20261013T143919247369Z/captures/ORIGINAL_q3_960x720.png) | `ec1e9901fc9d1aef2dafe788a14ae631cc11da560f3887d9559e362cce410477` | ACTUALLY_VIEWED_BY_CODEX_2026_10_21; PNG_HEADER_AND_SHA_VERIFIED |
| A_Q0_1280 | [A_q0_1280x720.png](E:/godot/beta-sprint-builds/QA/art_preview_polish03/run_20261013T143919247369Z/captures/A_q0_1280x720.png) | `0c0c1649eccc5c12ab51dff2d70c598e39af772d387503de298622ba4c4be1cf` | ACTUALLY_VIEWED_BY_CODEX_2026_10_21; PNG_HEADER_AND_SHA_VERIFIED |
| A_Q0_960 | [A_q0_960x720.png](E:/godot/beta-sprint-builds/QA/art_preview_polish03/run_20261013T143919247369Z/captures/A_q0_960x720.png) | `82c640dd7da816ea8b39baf55f8dd36ce500c8f28e1a05656547186b642cb5db` | ACTUALLY_VIEWED_BY_CODEX_2026_10_21; PNG_HEADER_AND_SHA_VERIFIED |
| A_Q1_1280 | [A_q1_1280x720.png](E:/godot/beta-sprint-builds/QA/art_preview_polish03/run_20261013T143919247369Z/captures/A_q1_1280x720.png) | `08102fb727e47156340e82376de141c1775589d5ccf3499fc82f8333ad21630a` | ACTUALLY_VIEWED_BY_CODEX_2026_10_21; PNG_HEADER_AND_SHA_VERIFIED |
| A_Q1_960 | [A_q1_960x720.png](E:/godot/beta-sprint-builds/QA/art_preview_polish03/run_20261013T143919247369Z/captures/A_q1_960x720.png) | `f5c8529d97e11a64bfa226dd4fe40998b901168ecb1882aeee16087647e31fe4` | ACTUALLY_VIEWED_BY_CODEX_2026_10_21; PNG_HEADER_AND_SHA_VERIFIED |
| A_Q2_1280 | [A_q2_1280x720.png](E:/godot/beta-sprint-builds/QA/art_preview_polish03/run_20261013T143919247369Z/captures/A_q2_1280x720.png) | `8a9b9a5f8094a55a4371285b6bc357a13b46f4f94f0f681e177079403db9de7c` | ACTUALLY_VIEWED_BY_CODEX_2026_10_21; PNG_HEADER_AND_SHA_VERIFIED |
| A_Q2_960 | [A_q2_960x720.png](E:/godot/beta-sprint-builds/QA/art_preview_polish03/run_20261013T143919247369Z/captures/A_q2_960x720.png) | `08a74b68f40ca5a693774dbf67dea38d3cf8158a007d980e547f305af1a78286` | ACTUALLY_VIEWED_BY_CODEX_2026_10_21; PNG_HEADER_AND_SHA_VERIFIED |
| A_Q3_1280 | [A_q3_1280x720.png](E:/godot/beta-sprint-builds/QA/art_preview_polish03/run_20261013T143919247369Z/captures/A_q3_1280x720.png) | `2e50986f9eeb45b7dcabdbefc70e9bf090aebfee2cd8ea20332932b2c545d968` | ACTUALLY_VIEWED_BY_CODEX_2026_10_21; PNG_HEADER_AND_SHA_VERIFIED |
| A_Q3_960 | [A_q3_960x720.png](E:/godot/beta-sprint-builds/QA/art_preview_polish03/run_20261013T143919247369Z/captures/A_q3_960x720.png) | `48ded409da83487c6bd6b9333dc7f4c74ff17ea9e6727afca8b041873a7d892e` | ACTUALLY_VIEWED_BY_CODEX_2026_10_21; PNG_HEADER_AND_SHA_VERIFIED |
| B_Q0_1280 | [B_q0_1280x720.png](E:/godot/beta-sprint-builds/QA/art_preview_polish03/run_20261013T143919247369Z/captures/B_q0_1280x720.png) | `acec9184afc91d856d296df2d87cf8e219819b900af3079314f7bdb26d0bd57e` | ACTUALLY_VIEWED_BY_CODEX_2026_10_21; PNG_HEADER_AND_SHA_VERIFIED |
| B_Q0_960 | [B_q0_960x720.png](E:/godot/beta-sprint-builds/QA/art_preview_polish03/run_20261013T143919247369Z/captures/B_q0_960x720.png) | `69b76a5a3bf6465423e2a2fd6a11e01a4c241e0768de6f43d4942c6358221112` | ACTUALLY_VIEWED_BY_CODEX_2026_10_21; PNG_HEADER_AND_SHA_VERIFIED |
| B_Q1_1280 | [B_q1_1280x720.png](E:/godot/beta-sprint-builds/QA/art_preview_polish03/run_20261013T143919247369Z/captures/B_q1_1280x720.png) | `daf0cf24f0ffba3474267855f04fd9cf8b538fdaa457c4a49e910ca7147cfd27` | ACTUALLY_VIEWED_BY_CODEX_2026_10_21; PNG_HEADER_AND_SHA_VERIFIED |
| B_Q1_960 | [B_q1_960x720.png](E:/godot/beta-sprint-builds/QA/art_preview_polish03/run_20261013T143919247369Z/captures/B_q1_960x720.png) | `c3f6993385efa5c0c063fe4617fee2851b0fc784e9de48e96b8203a1384d529a` | ACTUALLY_VIEWED_BY_CODEX_2026_10_21; PNG_HEADER_AND_SHA_VERIFIED |
| B_Q2_1280 | [B_q2_1280x720.png](E:/godot/beta-sprint-builds/QA/art_preview_polish03/run_20261013T143919247369Z/captures/B_q2_1280x720.png) | `8cb2cde9afd5cd859cc51299e4b65504d40b958265e1f2ba163cc9d09d002f2b` | ACTUALLY_VIEWED_BY_CODEX_2026_10_21; PNG_HEADER_AND_SHA_VERIFIED |
| B_Q2_960 | [B_q2_960x720.png](E:/godot/beta-sprint-builds/QA/art_preview_polish03/run_20261013T143919247369Z/captures/B_q2_960x720.png) | `1be333d73981c71fe71b34b7a2bb2f5d5e23c47ac5df640ed253a49c3378ac1f` | ACTUALLY_VIEWED_BY_CODEX_2026_10_21; PNG_HEADER_AND_SHA_VERIFIED |
| B_Q3_1280 | [B_q3_1280x720.png](E:/godot/beta-sprint-builds/QA/art_preview_polish03/run_20261013T143919247369Z/captures/B_q3_1280x720.png) | `a0495645f127fb71af36d48fc51704bc3467df02b7705e76df82d6e4a81d6b4a` | ACTUALLY_VIEWED_BY_CODEX_2026_10_21; PNG_HEADER_AND_SHA_VERIFIED |
| B_Q3_960 | [B_q3_960x720.png](E:/godot/beta-sprint-builds/QA/art_preview_polish03/run_20261013T143919247369Z/captures/B_q3_960x720.png) | `76e74bf9461e4510a6bd08bc9a347a2de791c68bc35571e4766a4b0fd49e8430` | ACTUALLY_VIEWED_BY_CODEX_2026_10_21; PNG_HEADER_AND_SHA_VERIFIED |
| core | [core_lab.gd](E:/godot/worktrees/bg-formal01/experiments/game_feel_01/host/core_lab.gd) | `b5d7d6c19a65dd167b9ee4a32c1074912c547482e9ac11370dcfc6fd336cdf0b` | READ_AND_HASHED |
| host | [spatial_lab.gd](E:/godot/worktrees/bg-formal01/experiments/spatial_puzzle_batch_01/host/spatial_lab.gd) | `7906c6917f861df420abf2b260ed5c849d5a89418eb4caa4f353ea20097304b7` | READ_AND_HASHED |
| camera | [view_contract.gd](E:/godot/worktrees/bg-formal01/foundation/game_feel/view_contract.gd) | `76feb612222ca061f64d702c080b060ec834d3454cfccabfde34f7e0a0e05231` | READ_AND_HASHED |
| surface | [surface.tscn](E:/godot/worktrees/bg-formal01/experiments/spatial_puzzle_batch_01/maps/authoring/world_shift_gate_lab/surface.tscn) | `e8fbb0810ed282c824b664f402b145388fb881c70f5f26296e7c0600de7d5785` | READ_AND_HASHED |
| inner | [inner.tscn](E:/godot/worktrees/bg-formal01/experiments/spatial_puzzle_batch_01/maps/authoring/world_shift_gate_lab/inner.tscn) | `7418bfb3a7f3b18bf8c0a55b1a2f8bcb38fab81437f161c96bc64f8c5bf086d1` | READ_AND_HASHED |
| map_factory | [map_factory.gd](E:/godot/worktrees/bg-formal01/experiments/spatial_puzzle_batch_01/maps/map_factory.gd) | `71e86e95f2605a47bd67b8fb20be1c0a5aba91606504174ee0991a3b25099839` | READ_AND_HASHED |
| preview_script | [roof_preview.gd](E:/godot/worktrees/bg-formal01/tests/beta_sprint/spatial_art/polish_03/roof_preview.gd) | `bdb843a0897e6ecab809430a85fd7457fb32d003ced857c98a72ea50efd58af4` | READ_AND_HASHED |
| A_shader | [roof_coarse.gdshader](E:/godot/worktrees/bg-formal01/tests/beta_sprint/spatial_art/polish_03/roof_coarse.gdshader) | `d86a48af1c7947ba629d6dca5959b40c8dd16e3aaf05034c728d7d344762d627` | READ_AND_HASHED |
| B_shader | [roof_inset.gdshader](E:/godot/worktrees/bg-formal01/tests/beta_sprint/spatial_art/polish_03/roof_inset.gdshader) | `68ec63ff75b1db217e4de607323f2cdf7b6c9e132ced757a11cf5791b1f9bf7d` | READ_AND_HASHED |
| formal_shell | [spatial_level.gd](E:/godot/worktrees/bg-formal01/game/levels/mutsumi/spatial_chapter/spatial_level.gd) | `412fdf966662f524799df4af325967beaf07e50615496cf849a5eea686cf5ba6` | READ_AND_HASHED |
| capture_report | [report.json](E:/godot/beta-sprint-builds/QA/art_preview_polish03/run_20261013T143919247369Z/captures/report.json) | `60c4a1cc7fc53251757863ae5ff4ee15cf5b4431d8add80334aa96b3b4c30c93` | READ_AND_HASHED |
| preview_process | [process.json](E:/godot/beta-sprint-builds/QA/art_preview_polish03/run_20261013T143919247369Z/process.json) | `e7adc7c97f461b7203fa7064e7288725f54e4674c84e4a14c9b195365501eb5a` | READ_AND_HASHED |
| preview_review | [REVIEW_EVIDENCE.json](E:/godot/beta-sprint-builds/QA/art_preview_polish03/run_20261013T143919247369Z/REVIEW_EVIDENCE.json) | `d1dacc3da59417c76f4ff82af7c25e87133a94827c96d875501e64c571a3dcf7` | READ_AND_HASHED |
| preview_log | [godot.log](E:/godot/beta-sprint-builds/QA/art_preview_polish03/run_20261013T143919247369Z/godot.log) | `366c8c5ad83f290a48c6e7b9bb72066a8607fdb97bbc6a15f416973fe017d493` | READ_AND_HASHED |
| preview_project | [project.godot](E:/godot/beta-sprint-builds/QA/art_preview_polish03/run_20261013T143919247369Z/project/project.godot) | `6075f841f67c1269c119f2fef1996ce68565fb70dd204a4635067069d3bdafb2` | READ_AND_HASHED |
| formal_manifest | [BUILD_IDENTITY.json](E:/godot/beta-sprint-builds/beta_spatial_formal_chapter_20261019_01/BUILD_IDENTITY.json) | `1c6fdc2baa4c058733cd2c2ede3532d41d569f7d7236be78689acf8c8d7b5336` | READ_AND_HASHED |
| original_build_manifest | [BUILD_IDENTITY.json](E:/godot/beta-sprint-builds/beta_spatial_acceptance_input_fix_20261013_01/BUILD_IDENTITY.json) | `67021752bfec7a05223aa12b3b447005bf486818e54983b4559d32b5a53393c0` | READ_AND_HASHED |
| input_protocol | [CORRELATED_INPUT_PROTOCOL.md](E:/godot/worktrees/bg-formal01/docs/beta-sprint/spatial-formal-chapter-01/continuation-04/input/CORRELATED_INPUT_PROTOCOL.md) | `93cc0d9e368038b5e8f3224b6131fe36728ac29bca801fdd957a04913123269d` | READ_AND_HASHED |
| input_template | [EVENT_TEMPLATE.json](E:/godot/worktrees/bg-formal01/docs/beta-sprint/spatial-formal-chapter-01/continuation-04/input/EVENT_TEMPLATE.json) | `5a497aa688fe47dac408871cb23e3006ff5737e7999852549567c768c483d720` | READ_AND_HASHED |
| input_report | [REPORT.md](E:/godot/worktrees/bg-formal01/docs/beta-sprint/spatial-formal-chapter-01/continuation-04/input/REPORT.md) | `39f9d1479045332503d158a77cac7c8fa34b294dc0edd7898ed4577c55f0327a` | READ_AND_HASHED |
| human_protocol | [HUMAN_QA_PROTOCOL.md](E:/godot/worktrees/bg-formal01/docs/beta-sprint/spatial-formal-chapter-01/continuation-02/HUMAN_QA_PROTOCOL.md) | `10d816dea2ad3aa4289085026fc23e89b28f8a08475daaa797d9b7fda46adc3a` | READ_AND_HASHED |
| human_template | [SESSION_TEMPLATE.json](E:/godot/worktrees/bg-formal01/docs/beta-sprint/spatial-formal-chapter-01/continuation-02/SESSION_TEMPLATE.json) | `e4f08e1c676e80895dfe143a7f7dac0239e063195250baf514bd956f6abbf921` | READ_AND_HASHED |
| human_addendum | [HUMAN_QA_EXECUTION_ADDENDUM.md](E:/godot/worktrees/bg-formal01/docs/beta-sprint/spatial-formal-chapter-01/continuation-03/HUMAN_QA_EXECUTION_ADDENDUM.md) | `e6991aa67b78b046fbe8e2cbb17f356fc015da0a606fb8cacdc97049df9331ab` | READ_AND_HASHED |
| preservation_before | [PRESERVATION_BEFORE.json](E:/godot/beta-sprint-builds/floating_cube_scoring05_20261021_01/PRESERVATION_BEFORE.json) | `39216699a1f4df4525e5efc4a404d3350c464045f0921bf7f762b5a03acbd587` | READ_AND_HASHED |
| preservation_after | [PRESERVATION_AFTER.json](E:/godot/beta-sprint-builds/floating_cube_scoring05_20261021_01/PRESERVATION_AFTER.json) | `bd1a1a65c7a9f6dcd5f385ac63ced9728c66cb62dfd9359cb793a6bad88e199a` | FRESH_BEFORE_AFTER_HASH_COMPARISON |

## 结构与复核

[结构规范](SCORING_RESULTS.schema.json) · [实际评分JSON](SCORING_RESULTS.json) · [验证工具](validate_scoring.py)

Schema为Draft 2020-12；语义验证另检查权重、算式、NA传播、比较范围、证据路径/哈希及本Markdown一致性。Schema通过不代表正式资产批准。
