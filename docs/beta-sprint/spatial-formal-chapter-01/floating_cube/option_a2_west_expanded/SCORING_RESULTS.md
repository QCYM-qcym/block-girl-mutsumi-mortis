# Floating Cube A2 — expanded preview review

**A2_PREVIEW_READY** · `A2_EXPANDED_01` · 2026-10-23

用户已扩大“非颜色粗纹和材质响应”授权。本轮西视角达到3，北东南均保持3，四方向使用同一材质实例。整体完整美术评审仍为PARTIAL，V5/完整总分仍未评估。

**105 checks / 0 failures / exit0 / stderr0 / 12张实际原始PNG**，1280×720，Godot4.7.2 Windows D3D12 Forward+。Root与独立评审分别查看全部12张新帧。

| 视角 | CURRENT | A1 | 本轮扩展A2 |
| --- | ---: | ---: | ---: |
| NORTH | 2 | 3 | 3 |
| EAST | 2 | 3 | 3 |
| SOUTH | 2 | 3 | 3 |
| WEST | 2 | 2 | **3** |

[四视角总览与全部原图](renders/current_vs_A1_vs_A2/OVERVIEW.html) · [固定条件记录](renders/current_vs_A1_vs_A2/RENDER_COMPARISON.json)

## 材质改变与边界

沿用既有粗石预览的对象空间不规则层理、断续暗槽和矿物斑块，采用roughness相关的包裹漫反射。A1两色锚点(.23,.28,.33)/(.48,.53,.55)原样保留；暗槽取原暗色×.32，斑块改变明暗。这里是低饱和灰蓝色系，不是字面上的纯灰。辨识依靠粗纹明暗及材质响应，不是改成醒目对比色。

A2 Roughness=.96、Metallic=0、SPECULAR=0；无alpha、发光、法线位移或相机条件。顶点函数仅传递局部位置/法线，四向共享材质。原几何、姿态、比例、灯光、相机、背景、曝光和规则保持；原Scene仅在新副本运行。

本轮已获准改变粗纹与漫反射响应，不沿用旧严格B2“原纹理/漫反射不变及8%局部明暗”限制声明。真实参数、源SHA和完整diff见 [参数](A2_MATERIAL_PARAMETERS.json)、[身份](A2_SOURCE_IDENTITY.json)、[A1→扩展A2差异](A1_TO_A2.diff)。

## 评分

Schema与严格B2原字节一致，校验器复用旧实现、旧V1–V6权重30/20/15/15/10/10及原始算式；新包装仅绑定新目录、授权身份及不可变旧分数快照。没有为本轮改变门槛或算法。

| 候选 | 已评估原权重 | 小计 | 完整总分 | 图片 |
| --- | ---: | ---: | --- | --- |
| CURRENT | 90% | 46.0 | NOT_ASSESSED | [NORTH](renders/current_vs_A1_vs_A2/CURRENT_q0.png), [EAST](renders/current_vs_A1_vs_A2/CURRENT_q1.png), [SOUTH](renders/current_vs_A1_vs_A2/CURRENT_q2.png), [WEST](renders/current_vs_A1_vs_A2/CURRENT_q3.png) |
| A1 | 90% | 61.0 | NOT_ASSESSED | [NORTH](renders/current_vs_A1_vs_A2/A1_q0.png), [EAST](renders/current_vs_A1_vs_A2/A1_q1.png), [SOUTH](renders/current_vs_A1_vs_A2/A1_q2.png), [WEST](renders/current_vs_A1_vs_A2/A1_q3.png) |
| 本轮扩展A2 | 90% | 65.0 | NOT_ASSESSED | [NORTH](renders/current_vs_A1_vs_A2/A2_q0.png), [EAST](renders/current_vs_A1_vs_A2/A2_q1.png), [SOUTH](renders/current_vs_A1_vs_A2/A2_q2.png), [WEST](renders/current_vs_A1_vs_A2/A2_q3.png) |

共同90%原权重小计A2相对A1+4，相对CURRENT+19；没有归一化为百分制完整总分。

### CURRENT

| 项 | 权重 | 分数 | 加权 | 实际观察/扣分 | 图片 |
| --- | ---: | --- | --- | --- | --- |
| V1 | 30 | 2 | 12.0 | 与道路同为平顶立方体；灰蓝色只能提供颜色差别。 平顶和方正体量容易被读成可到达平台。 | [CURRENT_q0](renders/current_vs_A1_vs_A2/CURRENT_q0.png), [CURRENT_q1](renders/current_vs_A1_vs_A2/CURRENT_q1.png), [CURRENT_q2](renders/current_vs_A1_vs_A2/CURRENT_q2.png), [CURRENT_q3](renders/current_vs_A1_vs_A2/CURRENT_q3.png) |
| V2 | 20 | 2 | 8.0 | 四方向均保留相似的平顶平台轮廓，未出现稳定非颜色用途线索。 转向不能消除其可踩平台外观。 | [CURRENT_q0](renders/current_vs_A1_vs_A2/CURRENT_q0.png), [CURRENT_q1](renders/current_vs_A1_vs_A2/CURRENT_q1.png), [CURRENT_q2](renders/current_vs_A1_vs_A2/CURRENT_q2.png), [CURRENT_q3](renders/current_vs_A1_vs_A2/CURRENT_q3.png) |
| V3 | 15 | 5 | 15.0 | 四图中的主体轮廓、悬空高度、相对转换点位置保持。 在该静态同对象范围内未发现位置或轮廓问题。 | [CURRENT_q0](renders/current_vs_A1_vs_A2/CURRENT_q0.png), [CURRENT_q1](renders/current_vs_A1_vs_A2/CURRENT_q1.png), [CURRENT_q2](renders/current_vs_A1_vs_A2/CURRENT_q2.png), [CURRENT_q3](renders/current_vs_A1_vs_A2/CURRENT_q3.png) |
| V4 | 15 | 3 | 9.0 | 四图呈不透明哑光表面，没有透明或大面积发光。 表面平滑，缺少目标要求的粗纹。 | [CURRENT_q0](renders/current_vs_A1_vs_A2/CURRENT_q0.png), [CURRENT_q1](renders/current_vs_A1_vs_A2/CURRENT_q1.png), [CURRENT_q2](renders/current_vs_A1_vs_A2/CURRENT_q2.png), [CURRENT_q3](renders/current_vs_A1_vs_A2/CURRENT_q3.png) |
| V5 | 10 | NOT_ASSESSED | null | 本轮只实拍正式GREYBOX Surface；没有新增Inner或冻结世界Art同屏证据。 V5与完整总分保持NOT_ASSESSED/null，不借历史人工样张补分。 | [CURRENT_q0](renders/current_vs_A1_vs_A2/CURRENT_q0.png), [CURRENT_q1](renders/current_vs_A1_vs_A2/CURRENT_q1.png), [CURRENT_q2](renders/current_vs_A1_vs_A2/CURRENT_q2.png), [CURRENT_q3](renders/current_vs_A1_vs_A2/CURRENT_q3.png) |
| V6 | 10 | 1 | 2.0 | 当前仅有平面光照明暗，表面无纹理、边缘或功能线索。 区分主要依赖颜色，非颜色线索不足。 | [CURRENT_q0](renders/current_vs_A1_vs_A2/CURRENT_q0.png), [CURRENT_q1](renders/current_vs_A1_vs_A2/CURRENT_q1.png), [CURRENT_q2](renders/current_vs_A1_vs_A2/CURRENT_q2.png), [CURRENT_q3](renders/current_vs_A1_vs_A2/CURRENT_q3.png) |

### A1

| 项 | 权重 | 分数 | 加权 | 实际观察/扣分 | 图片 |
| --- | ---: | --- | --- | --- | --- |
| V1 | 30 | 3 | 18.0 | 顶面与侧面有宽波纹，能与无纹道路区分。 仍是完整平顶立方体；材质差别并不直接说明不可踩。 | [A1_q0](renders/current_vs_A1_vs_A2/A1_q0.png), [A1_q1](renders/current_vs_A1_vs_A2/A1_q1.png), [A1_q2](renders/current_vs_A1_vs_A2/A1_q2.png), [A1_q3](renders/current_vs_A1_vs_A2/A1_q3.png) |
| V2 | 20 | 2 | 8.0 | 北东南波纹可见，西侧暗面的细纹明显较弱。 WEST 仍需仔细观察，四方向辨识不稳定。 | [A1_q0](renders/current_vs_A1_vs_A2/A1_q0.png), [A1_q1](renders/current_vs_A1_vs_A2/A1_q1.png), [A1_q2](renders/current_vs_A1_vs_A2/A1_q2.png), [A1_q3](renders/current_vs_A1_vs_A2/A1_q3.png) |
| V3 | 15 | 5 | 15.0 | 只换材质后，四图中的轮廓、高度和空间关系保持。 该同对象静态范围未发现主要轮廓或位置问题。 | [A1_q0](renders/current_vs_A1_vs_A2/A1_q0.png), [A1_q1](renders/current_vs_A1_vs_A2/A1_q1.png), [A1_q2](renders/current_vs_A1_vs_A2/A1_q2.png), [A1_q3](renders/current_vs_A1_vs_A2/A1_q3.png) |
| V4 | 15 | 4 | 12.0 | 四图均不透明、哑光，宽纹没有反光高光或发光轮廓。 条纹较规则，粗糙石质感仍有不足。 | [A1_q0](renders/current_vs_A1_vs_A2/A1_q0.png), [A1_q1](renders/current_vs_A1_vs_A2/A1_q1.png), [A1_q2](renders/current_vs_A1_vs_A2/A1_q2.png), [A1_q3](renders/current_vs_A1_vs_A2/A1_q3.png) |
| V5 | 10 | NOT_ASSESSED | null | 本轮只实拍正式GREYBOX Surface；没有新增Inner或冻结世界Art同屏证据。 V5与完整总分保持NOT_ASSESSED/null，不借历史人工样张补分。 | [A1_q0](renders/current_vs_A1_vs_A2/A1_q0.png), [A1_q1](renders/current_vs_A1_vs_A2/A1_q1.png), [A1_q2](renders/current_vs_A1_vs_A2/A1_q2.png), [A1_q3](renders/current_vs_A1_vs_A2/A1_q3.png) |
| V6 | 10 | 4 | 8.0 | 波纹提供非颜色区别，西视角顶面依然可辨。 西侧暗面纹理变弱；没有明确用途符号。 | [A1_q0](renders/current_vs_A1_vs_A2/A1_q0.png), [A1_q1](renders/current_vs_A1_vs_A2/A1_q1.png), [A1_q2](renders/current_vs_A1_vs_A2/A1_q2.png), [A1_q3](renders/current_vs_A1_vs_A2/A1_q3.png) |

### A2

| 项 | 权重 | 分数 | 加权 | 实际观察/扣分 | 图片 |
| --- | ---: | --- | --- | --- | --- |
| V1 | 30 | 3 | 18.0 | 不规则粗纹提供可见表面差异，WEST不再主要依赖顶面。 保留平顶立方体轮廓，不能仅凭材质明确禁止踩踏。 | [A2_q0](renders/current_vs_A1_vs_A2/A2_q0.png), [A2_q1](renders/current_vs_A1_vs_A2/A2_q1.png), [A2_q2](renders/current_vs_A1_vs_A2/A2_q2.png), [A2_q3](renders/current_vs_A1_vs_A2/A2_q3.png) |
| V2 | 20 | 3 | 12.0 | 四方向均达到基本可区分的3分，WEST从2升至3。 可踩平台用途联想仍在，未达到无需观察的明确程度。 | [A2_q0](renders/current_vs_A1_vs_A2/A2_q0.png), [A2_q1](renders/current_vs_A1_vs_A2/A2_q1.png), [A2_q2](renders/current_vs_A1_vs_A2/A2_q2.png), [A2_q3](renders/current_vs_A1_vs_A2/A2_q3.png) |
| V3 | 15 | 5 | 15.0 | 原轮廓、尺寸、位置、遮光作用和与道路/角色关系保持，记录逐组一致。 在该同对象静态范围内未发现几何或空间改变。 | [A2_q0](renders/current_vs_A1_vs_A2/A2_q0.png), [A2_q1](renders/current_vs_A1_vs_A2/A2_q1.png), [A2_q2](renders/current_vs_A1_vs_A2/A2_q2.png), [A2_q3](renders/current_vs_A1_vs_A2/A2_q3.png) |
| V4 | 15 | 4 | 12.0 | 图片呈不透明哑光粗石层理，暗槽和矿物斑块可见，无大面积高光或发光。 程序纹理仍有重复，包裹漫反射使部分面间明暗变平。 | [A2_q0](renders/current_vs_A1_vs_A2/A2_q0.png), [A2_q1](renders/current_vs_A1_vs_A2/A2_q1.png), [A2_q2](renders/current_vs_A1_vs_A2/A2_q2.png), [A2_q3](renders/current_vs_A1_vs_A2/A2_q3.png) |
| V5 | 10 | NOT_ASSESSED | null | 本轮只新增正式GREYBOX Surface固定条件图片。 Inner/冻结正式世界Art同屏证据未新增，V5和完整总分保持null。 | [A2_q0](renders/current_vs_A1_vs_A2/A2_q0.png), [A2_q1](renders/current_vs_A1_vs_A2/A2_q1.png), [A2_q2](renders/current_vs_A1_vs_A2/A2_q2.png), [A2_q3](renders/current_vs_A1_vs_A2/A2_q3.png) |
| V6 | 10 | 4 | 8.0 | 粗层、断槽与斑块通过明暗变化区分光滑道路，四向稳定。 依然缺少明确用途符号；色系虽保留，完整石块形态仍可联想为平台。 | [A2_q0](renders/current_vs_A1_vs_A2/A2_q0.png), [A2_q1](renders/current_vs_A1_vs_A2/A2_q1.png), [A2_q2](renders/current_vs_A1_vs_A2/A2_q2.png), [A2_q3](renders/current_vs_A1_vs_A2/A2_q3.png) |

## 保留的限制与历史

粗纹改善了暗面差异，但完整平顶立方体仍可能被理解为可踩石台；本轮不支持4分或“玩家完全理解”的结论。未进行HumanQA。正式S01仍是GREYBOX，不是冻结Art同屏；本轮未新增Inner评分，V5与完整总分保持null。

旧05 CURRENT/A1/B、旧06粗石A2、旧严格B2失败均以原路径/hash保留，未回填旧分数。严格B2仍为[3,3,3,2]、WEST未达标；本轮新授权/新shader/新渲染得到独立[3,3,3,3]，两者不能混用。

文件保护：6601个既有文件哈希、旧profile和保护refs一致；[保护摘要](PRESERVATION_SUMMARY.json)。四组候选条件一致，未新增UI/辅助几何、未改Runtime/通行规则、未覆盖正式资产或旧QA包。

Formal asset approval: NOT_GRANTED。Game integration: NOT_RUN。HumanQA: NOT_RUN。New formal Build: NOT_CREATED。

本轮交付原生Godot材质shader和新预览证据；旧Blender仅材质库保留为旧严格B2历史文件，不冒充当前扩展shader的对应材质库。

文件哈希清单：[SHA256SUMS.json](SHA256SUMS.json)。实际Commit/Push/远端SHA在提交后独立核验，避免自引用提交身份。

最终[只读验证记录](evidence/VALIDATION.json)：12图、2份原历史报告、10个来源配对、旧严格B2快照及4组固定条件均匹配；原20项与新增7项故意损坏的数据均被拒绝。结构验证不代表正式美术批准。
