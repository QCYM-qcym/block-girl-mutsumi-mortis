# FLOATING_CUBE_A2_WEST_VIEW_REVIEW

**A2_MATERIAL_ONLY_LIMIT_REACHED** · 2026-10-23 · PREVIEW ONLY

本轮严格白名单A2的西视角仍为 **2/5**，未达到3分；北东南保持3分。已触发停止条件，未继续加大颜色/法线或改变其它表现参数。

Formal asset approval: NOT_GRANTED。Game integration: NOT_RUN。New formal Build: NOT_CREATED。Human QA: NOT_RUN。

## 实际固定条件渲染

**105 checks / 0 failures / exit0 / stderr0 / 12原始1280×720帧**。真实Godot4.7.2、Windows D3D12 Forward+。Root及独立评审分别实看全部12张；无人类首次理解性测试。

四组对照内场景、Camera transform、灯光、StateKey、Orientation、网格/位姿完全相同。四相机取景沿用正式Runtime已有Q0–Q3位置；没有为A2重定位。没有新增UI、用途说明、人工样张或几何。

| Camera | CURRENT | A1 | 严格A2 | 结果 | 图片 |
| --- | ---: | ---: | ---: | --- | --- |
| NORTH Q0 | 2 | 3 | 3 | 维持A1，未退化 | [CURRENT_q0](renders/current_vs_A1_vs_A2/CURRENT_q0.png), [A1_q0](renders/current_vs_A1_vs_A2/A1_q0.png), [A2_q0](renders/current_vs_A1_vs_A2/A2_q0.png) |
| EAST Q1 | 2 | 3 | 3 | 维持A1，未退化 | [CURRENT_q1](renders/current_vs_A1_vs_A2/CURRENT_q1.png), [A1_q1](renders/current_vs_A1_vs_A2/A1_q1.png), [A2_q1](renders/current_vs_A1_vs_A2/A2_q1.png) |
| SOUTH Q2 | 2 | 3 | 3 | 维持A1，未退化 | [CURRENT_q2](renders/current_vs_A1_vs_A2/CURRENT_q2.png), [A1_q2](renders/current_vs_A1_vs_A2/A1_q2.png), [A2_q2](renders/current_vs_A1_vs_A2/A2_q2.png) |
| WEST Q3 | 2 | 2 | 2 | 未达3分，STOP | [CURRENT_q3](renders/current_vs_A1_vs_A2/CURRENT_q3.png), [A1_q3](renders/current_vs_A1_vs_A2/A1_q3.png), [A2_q3](renders/current_vs_A1_vs_A2/A2_q3.png) |

[四视角总览](renders/current_vs_A1_vs_A2/OVERVIEW.html) · [固定条件清单](renders/current_vs_A1_vs_A2/RENDER_COMPARISON.json)

## 参数与来源

真实原物体来自Godot程序BoxMesh，作者场景roof位置(1,6,0)、六面不可走。原模型没有匹配的可信源.blend；本轮未重建/导入任何几何。

[FloatingCube_A2.blend](FloatingCube_A2.blend) 为可编辑的 **仅材质库**，0objects/0meshes，已保存后重开核验。它不交付可渲染原模型或Blender实景评分。Principled/Bump参数单独按实际读值记录，不声称等价于Godot SPECULAR/微法线。

| 属性 | A1 | 严格A2 |
| --- | --- | --- |
| Godot Roughness | 0.94 | 0.90 |
| Metallic | 0 | 0 |
| Godot SPECULAR | 0.5引擎默认（shader未显式设置） | 0.15 |
| 原线性ALBEDO | 原两色/原宽纹函数 | 统一×1.06，亮度+6%，低于8%上限 |
| 微法线 | 无 | 切向幅0.10，32cycles/local-unit，最大倾斜约5.71° |
| Blender参考Roughness/IOR Level | .94/.50 | .90/.15 |
| Blender Bump | 无 | Strength.10、Distance.005 Blender units、NoiseScale32 |

实际重开值保留浮点精度，详见 [材质参数JSON](A2_MATERIAL_PARAMETERS.json)、[源身份JSON](A2_SOURCE_IDENTITY.json)、[精确shader差异](A1_TO_A2.diff)、[白名单核验](MATERIAL_WHITELIST_CHECK.json)。

## 沿用原评分规范

V1–V6权重仍为30/20/15/15/10/10，`score/5×weight`，不归一化。新任务schema通过$ref复用旧06的candidate/metric/view/evidence定义；旧05/06 JSON、MD、schema、validator和历史B结果均未改写。历史结果按原路径与SHA保留于本轮JSON的history。

| 候选 | 共同已评估原权重 | 小计 | 完整总分 |
| --- | ---: | ---: | --- |
| CURRENT | 90% | 46.0 | NOT_ASSESSED |
| A1 | 90% | 61.0 | NOT_ASSESSED |
| 本轮严格A2 | 90% | 61.0 | NOT_ASSESSED |

历史05 B为50/90；历史06宽松A2为65/90、WEST3，**不是本轮候选或本轮结果**。本轮A2与A1小计差0，与CURRENT差15；完整总分差null。V5仍无Inner/冻结正式世界同屏证据，不评估。

### CURRENT

| 项 | 权重 | 分数 | 加权 | 观察/扣分 | 具体图片 |
| --- | ---: | --- | --- | --- | --- |
| V1 | 30 | 2 | 12.0 | 与道路同为平顶立方体；灰蓝色只能提供颜色差别。 平顶和方正体量容易被读成可到达平台。 | [CURRENT_q0](renders/current_vs_A1_vs_A2/CURRENT_q0.png), [CURRENT_q1](renders/current_vs_A1_vs_A2/CURRENT_q1.png), [CURRENT_q2](renders/current_vs_A1_vs_A2/CURRENT_q2.png), [CURRENT_q3](renders/current_vs_A1_vs_A2/CURRENT_q3.png) |
| V2 | 20 | 2 | 8.0 | 四方向均保留相似的平顶平台轮廓，未出现稳定非颜色用途线索。 转向不能消除其可踩平台外观。 | [CURRENT_q0](renders/current_vs_A1_vs_A2/CURRENT_q0.png), [CURRENT_q1](renders/current_vs_A1_vs_A2/CURRENT_q1.png), [CURRENT_q2](renders/current_vs_A1_vs_A2/CURRENT_q2.png), [CURRENT_q3](renders/current_vs_A1_vs_A2/CURRENT_q3.png) |
| V3 | 15 | 5 | 15.0 | 四图中的主体轮廓、悬空高度、相对转换点位置保持。 在该静态同对象范围内未发现位置或轮廓问题。 | [CURRENT_q0](renders/current_vs_A1_vs_A2/CURRENT_q0.png), [CURRENT_q1](renders/current_vs_A1_vs_A2/CURRENT_q1.png), [CURRENT_q2](renders/current_vs_A1_vs_A2/CURRENT_q2.png), [CURRENT_q3](renders/current_vs_A1_vs_A2/CURRENT_q3.png) |
| V4 | 15 | 3 | 9.0 | 四图呈不透明哑光表面，没有透明或大面积发光。 表面平滑，缺少目标要求的粗纹。 | [CURRENT_q0](renders/current_vs_A1_vs_A2/CURRENT_q0.png), [CURRENT_q1](renders/current_vs_A1_vs_A2/CURRENT_q1.png), [CURRENT_q2](renders/current_vs_A1_vs_A2/CURRENT_q2.png), [CURRENT_q3](renders/current_vs_A1_vs_A2/CURRENT_q3.png) |
| V5 | 10 | NOT_ASSESSED | null | 本轮严格材质专项只实拍正式GREYBOX Surface；没有新增Inner或冻结世界Art同屏证据。 V5与完整总分保持NOT_ASSESSED/null，不借历史人工样张补分。 | [CURRENT_q0](renders/current_vs_A1_vs_A2/CURRENT_q0.png), [CURRENT_q1](renders/current_vs_A1_vs_A2/CURRENT_q1.png), [CURRENT_q2](renders/current_vs_A1_vs_A2/CURRENT_q2.png), [CURRENT_q3](renders/current_vs_A1_vs_A2/CURRENT_q3.png) |
| V6 | 10 | 1 | 2.0 | 当前仅有平面光照明暗，表面无纹理、边缘或功能线索。 区分主要依赖颜色，非颜色线索不足。 | [CURRENT_q0](renders/current_vs_A1_vs_A2/CURRENT_q0.png), [CURRENT_q1](renders/current_vs_A1_vs_A2/CURRENT_q1.png), [CURRENT_q2](renders/current_vs_A1_vs_A2/CURRENT_q2.png), [CURRENT_q3](renders/current_vs_A1_vs_A2/CURRENT_q3.png) |

### A1

| 项 | 权重 | 分数 | 加权 | 观察/扣分 | 具体图片 |
| --- | ---: | --- | --- | --- | --- |
| V1 | 30 | 3 | 18.0 | 顶面与侧面有宽波纹，能与无纹道路区分。 仍是完整平顶立方体；材质差别并不直接说明不可踩。 | [A1_q0](renders/current_vs_A1_vs_A2/A1_q0.png), [A1_q1](renders/current_vs_A1_vs_A2/A1_q1.png), [A1_q2](renders/current_vs_A1_vs_A2/A1_q2.png), [A1_q3](renders/current_vs_A1_vs_A2/A1_q3.png) |
| V2 | 20 | 2 | 8.0 | 北东南波纹可见，西侧暗面的细纹明显较弱。 WEST 仍需仔细观察，四方向辨识不稳定。 | [A1_q0](renders/current_vs_A1_vs_A2/A1_q0.png), [A1_q1](renders/current_vs_A1_vs_A2/A1_q1.png), [A1_q2](renders/current_vs_A1_vs_A2/A1_q2.png), [A1_q3](renders/current_vs_A1_vs_A2/A1_q3.png) |
| V3 | 15 | 5 | 15.0 | 只换材质后，四图中的轮廓、高度和空间关系保持。 该同对象静态范围未发现主要轮廓或位置问题。 | [A1_q0](renders/current_vs_A1_vs_A2/A1_q0.png), [A1_q1](renders/current_vs_A1_vs_A2/A1_q1.png), [A1_q2](renders/current_vs_A1_vs_A2/A1_q2.png), [A1_q3](renders/current_vs_A1_vs_A2/A1_q3.png) |
| V4 | 15 | 4 | 12.0 | 四图均不透明、哑光，宽纹没有反光高光或发光轮廓。 条纹较规则，粗糙石质感仍有不足。 | [A1_q0](renders/current_vs_A1_vs_A2/A1_q0.png), [A1_q1](renders/current_vs_A1_vs_A2/A1_q1.png), [A1_q2](renders/current_vs_A1_vs_A2/A1_q2.png), [A1_q3](renders/current_vs_A1_vs_A2/A1_q3.png) |
| V5 | 10 | NOT_ASSESSED | null | 本轮严格材质专项只实拍正式GREYBOX Surface；没有新增Inner或冻结世界Art同屏证据。 V5与完整总分保持NOT_ASSESSED/null，不借历史人工样张补分。 | [A1_q0](renders/current_vs_A1_vs_A2/A1_q0.png), [A1_q1](renders/current_vs_A1_vs_A2/A1_q1.png), [A1_q2](renders/current_vs_A1_vs_A2/A1_q2.png), [A1_q3](renders/current_vs_A1_vs_A2/A1_q3.png) |
| V6 | 10 | 4 | 8.0 | 波纹提供非颜色区别，西视角顶面依然可辨。 西侧暗面纹理变弱；没有明确用途符号。 | [A1_q0](renders/current_vs_A1_vs_A2/A1_q0.png), [A1_q1](renders/current_vs_A1_vs_A2/A1_q1.png), [A1_q2](renders/current_vs_A1_vs_A2/A1_q2.png), [A1_q3](renders/current_vs_A1_vs_A2/A1_q3.png) |

### A2

| 项 | 权重 | 分数 | 加权 | 观察/扣分 | 具体图片 |
| --- | ---: | --- | --- | --- | --- |
| V1 | 30 | 3 | 18.0 | 北东南宽纹可辨，西侧仍主要依赖顶面；完整立方体仍像可踩石台。 材质区别没有解决不可踩语义，V1不提高。 | [A2_q0](renders/current_vs_A1_vs_A2/A2_q0.png), [A2_q1](renders/current_vs_A1_vs_A2/A2_q1.png), [A2_q2](renders/current_vs_A1_vs_A2/A2_q2.png), [A2_q3](renders/current_vs_A1_vs_A2/A2_q3.png) |
| V2 | 20 | 2 | 8.0 | 北东南均保持3，WEST仍为2。 西视角弱项未解决，不能用其它方向抵消。 | [A2_q0](renders/current_vs_A1_vs_A2/A2_q0.png), [A2_q1](renders/current_vs_A1_vs_A2/A2_q1.png), [A2_q2](renders/current_vs_A1_vs_A2/A2_q2.png), [A2_q3](renders/current_vs_A1_vs_A2/A2_q3.png) |
| V3 | 15 | 5 | 15.0 | 四个固定视角下几何、位置、大小与主轮廓保持；真实网格、相机和阴影记录相同。 仅此同对象静态范围未发现轮廓/位置问题。 | [A2_q0](renders/current_vs_A1_vs_A2/A2_q0.png), [A2_q1](renders/current_vs_A1_vs_A2/A2_q1.png), [A2_q2](renders/current_vs_A1_vs_A2/A2_q2.png), [A2_q3](renders/current_vs_A1_vs_A2/A2_q3.png) |
| V4 | 15 | 4 | 12.0 | 仍是不透明哑光灰纹，未出现大面积高光或发光。 新增细栅格偏机械，不支持粗石观感改善；本项不优于A1。 | [A2_q0](renders/current_vs_A1_vs_A2/A2_q0.png), [A2_q1](renders/current_vs_A1_vs_A2/A2_q1.png), [A2_q2](renders/current_vs_A1_vs_A2/A2_q2.png), [A2_q3](renders/current_vs_A1_vs_A2/A2_q3.png) |
| V5 | 10 | NOT_ASSESSED | null | 本轮严格材质专项只实拍正式GREYBOX Surface；没有新增Inner或冻结世界Art同屏证据。 V5与完整总分保持NOT_ASSESSED/null，不借历史人工样张补分。 | [A2_q0](renders/current_vs_A1_vs_A2/A2_q0.png), [A2_q1](renders/current_vs_A1_vs_A2/A2_q1.png), [A2_q2](renders/current_vs_A1_vs_A2/A2_q2.png), [A2_q3](renders/current_vs_A1_vs_A2/A2_q3.png) |
| V6 | 10 | 4 | 8.0 | 原灰度宽纹仍提供非颜色线索，未引入鲜艳色。 WEST侧面依然弱，新增微纹未产生明确用途线索。 | [A2_q0](renders/current_vs_A1_vs_A2/A2_q0.png), [A2_q1](renders/current_vs_A1_vs_A2/A2_q1.png), [A2_q2](renders/current_vs_A1_vs_A2/A2_q2.png), [A2_q3](renders/current_vs_A1_vs_A2/A2_q3.png) |

## 停止原因与未解决问题

WEST的两个暗面仍主要呈现原A1暗宽纹；微法线在较亮顶面/侧面增加密线与栅格感，未明显增强遮光体与可踩平台的区别。平顶立方体的用途歧义仍在。没有证据支持将WEST提高至3。

本轮只验证了记录中的一组参数，没有穷尽整个允许参数空间；按用户“WEST仍低于3即停止”的规则收口。继续需要另行批准扩大非颜色材质响应/粗纹或边缘标记的设计范围。本轮未转入几何、灯光、相机、文字或正式生产修改。

文件保护：4668个既有文件哈希未变，旧profile和保护refs一致；[保护摘要](PRESERVATION_SUMMARY.json)。Blender材质库重开通过，stderr保留215bytes的use_nodes未来弃用警告（非渲染失败）；[重开记录](evidence/BLENDER_REOPEN.json)。

本轮目标验收FAIL与技术渲染检查PASS分别记录；高加权小计不能覆盖WEST门槛失败。

文件SHA清单见 [SHA256SUMS.json](SHA256SUMS.json)。Git阶段交付的真实Commit/Push/Remote SHA在提交后单独核验，不回填虚构状态。

A1省略的SPECULAR默认0.5，漫反射默认Burley；参数语义来源：[Godot官方空间shader文档](https://docs.godotengine.org/en/stable/tutorials/shaders/shader_reference/spatial_shader.html)。Godot实际渲染和Blender材质库的参数分别记录，没有声明跨引擎像素等价。

最终结构/哈希/算术校验：[VALIDATION.json](evidence/VALIDATION.json)：12张PNG、两份原历史报告、12项来源配对核验通过，20项故意损坏的结果均被拒绝。Schema成功仅证明数据结构及一致性；目标验收仍为FAIL。
