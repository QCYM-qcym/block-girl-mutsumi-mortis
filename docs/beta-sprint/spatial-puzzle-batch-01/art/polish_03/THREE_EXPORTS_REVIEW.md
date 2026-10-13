# 事故剩余三导出：只读补充调查与逐文件恢复提案

2026-10-13（Asia/Shanghai） · Owner 05 · `SPATIAL_PUZZLE_BATCH_01_POLISH_AND_ACCEPTANCE_03`

基线 `e4fe5365334e93138dc9b8856d09670478789abc`；分支 `test/spatial-art-polish-03`。本子任务仅写本报告与 [机器可读证据](THREE_EXPORTS_REVIEW.json)，没有执行美术脚本、重建、导出、恢复、删除、覆盖外部资产或启动 GUI。Input P1 保持 **CLOSED**；本调查不重开该问题。

**结论：三项当前字节与上轮调查及事故后备份仍相同，均可读取；它们仍不同于有依据的事故前本地清单。正式 Build 清单未包含这三项资产或其原/现内容哈希，项目文本命中均是审计文档提及，没有找到生产资源引用。** 原始三文件字节仍不可得，不能据此完成原 SVG 差分或原 PNG 像素差分。

## 原始依据与复核范围

复用 [continuation_02 调查](../continuation_02/EXTERNAL_EXPORT_INVESTIGATION.md)、[59 项结果](../continuation_02/EXTERNAL_EXPORT_AUDIT.json) 和 [177 项原清单快照](../continuation_02/ORIGINAL_PACKAGE_SHA256.json)。本轮不重复全盘副本搜索、不重新检查全部 59/177 文件。

本轮重新读取外部 `tests/PACKAGE_SHA256.json`，哈希仍为 `0a4eba41609a75ecda0dbdc33979da543968bf613f3f37a6dba4f77c10f62313`，与 Git 中原字节快照相同。它有事故前时间、未受事故写入、原生成流程和大量一致项等交叉证据，但没有独立不可变锚点或签名，仍定为 `CORROBORATED_LOCAL_PREINCIDENT_MANIFEST`，不升格为独立认证原版。

前轮在指定 model 根目录和四个 ZIP 中未找到三项原哈希副本；这是已有有界搜索结果，不表示永久丢失。本轮没有读取其他磁盘、云备份、系统还原点或删除记录，也没有重复搜寻。

## 三项精确身份

### 1. Face Lock 状态页 SVG

- 当前路径：`E:/Study/方块娘项目/若叶睦/model/art/production/work/GAME_ART_MECHANICS_BATCH_01/design/states/face_lock_D.svg`
- 事故后备份：`E:/Study/方块娘项目/若叶睦/model/art/production/work/GAME_ART_MECHANICS_BATCH_01_SCOPE_RECOVERY_20261013/design/states/face_lock_D.svg`
- 原清单 SHA256：`5482941575c67f1be0b5e83ff0dd3fde067c1b8b4bb31424b7a905d000aaa45b`
- 当前 SHA256：`8fe6caa92e1de5db0ea79e3e05b1fd8a341e625b4bb737544b07f8b71ebb14fc`
- 事故后备份 SHA256：`8fe6caa92e1de5db0ea79e3e05b1fd8a341e625b4bb737544b07f8b71ebb14fc`

当前 XML 可解析，根画布 1920×1080，90 个 XML 元素。没有重新渲染。当前 SVG 的真实坐标与事故后布局表达式相符（下节列明）；不能把它当成仅 mtime 或文件系统属性变化。没有原 SVG 字节，未完成“原文件与现文件元素全集差分”。

### 2. Face Lock 状态页 PNG

- 当前路径：`E:/Study/方块娘项目/若叶睦/model/art/production/work/GAME_ART_MECHANICS_BATCH_01/design/states/face_lock_D.png`
- 事故后备份：`E:/Study/方块娘项目/若叶睦/model/art/production/work/GAME_ART_MECHANICS_BATCH_01_SCOPE_RECOVERY_20261013/design/states/face_lock_D.png`
- 原清单 SHA256：`cb619b6d77cc838295fca8c57d36255dbcf4f0280895bda8056819465b680b69`
- 当前 SHA256：`f2fa9426f7a27552f2aa91af8714c29ff1cdeed516f78f257ae00ad19511e27d`
- 事故后备份 SHA256：`f2fa9426f7a27552f2aa91af8714c29ff1cdeed516f78f257ae00ad19511e27d`

当前 PNG 完整内存解码通过，1920×1080、RGBA。块结构为 IHDR、pHYs、23 个 IDAT、IEND；pHYs 对应读取值约 72.009 DPI。只读取，不生成或保存图片。原 PNG 的块结构、DPI、压缩流和解码像素不可得，所以**无法把总字节差异准确分解为元数据、编码和像素各占多少**。源码生成链与当前 SVG 支持内容布局变化的解释，不等同于原像素比较；不能声称“只变了文字区域”或“只有元数据改变”。

### 3. 图纸总览 PNG

- 当前路径：`E:/Study/方块娘项目/若叶睦/model/art/production/work/GAME_ART_MECHANICS_BATCH_01/reports/DRAWING_CONTACT_SHEET.png`
- 事故后备份：`E:/Study/方块娘项目/若叶睦/model/art/production/work/GAME_ART_MECHANICS_BATCH_01_SCOPE_RECOVERY_20261013/reports/DRAWING_CONTACT_SHEET.png`
- 原清单 SHA256：`8a503ee044ccbd54210754c840ddb957be6d1bace43096b66f1dfec46b5cc51e`
- 当前 SHA256：`30bba2f66d99031b4fb027e9e2f17d0e14136908b58165ee098aeeddfaefcad3`
- 事故后备份 SHA256：`30bba2f66d99031b4fb027e9e2f17d0e14136908b58165ee098aeeddfaefcad3`

当前 PNG 完整内存解码通过，1920×1890、RGBA。块结构为 IHDR、pHYs、185 个 IDAT、IEND；读取 DPI 为 25.4。`DRAWING_INDEX.json` 仍与原清单相同，Face Lock 状态页为零起算第 3 项；生成源码第 120–121 行将每页缩至 480×270，按每行四项合成，因此该页对应总览首行第四格 `(1440,0)`。这是**生成链定位**，没有原总览像素，不能声称只有该矩形内像素改变或其他像素完全一致。

## 已证实的源布局差异与未知部分

只读比较两份 `scripts/build_boards.cjs`：当前恢复后的源 SHA256 为 `bf4351a481015c2ad347c1d429d62a69a2437a4e3fe8526b63e5532df2c39fcb`，与原清单相同；事故后脚本备份 SHA256 为 `16af8db73d935af9f839f2446c9008781946da17b6260c6f272c345777027d14`。差分只显示第 53–54 行两处表达式改变，完整 diff 保存在 JSON。**未执行这两份脚本。**

| 项目 | 已恢复原源表达式 | 事故后表达式 / 当前 SVG 证据 |
|---|---|---|
| 说明文字首行基线 | `y+211` | Face Lock 专用 `y+233`，下移 22 设计像素；第一排当前基线 408/453/498，第二排 788/833/878。第一排原源可推导为 386/431/476，属于源码推导而非原 SVG 实读。 |
| 横闩起点 | `x+100,y+146` | `x+124,y+128`，右移 24、上移 18；当前六处 transform 横坐标 172/792/1412，纵坐标 303/683。 |
| 横闩整体宽度 | 385 | 340；辅助函数按 `w/120` 统一缩放，当前 SVG 六处 scale 为 2.8333333333333335，原源计算为 3.2083333333333335；属于示意图整体缩放，不是 Blender 模型或 Runtime 行程变更。 |

状态标题、文案/状态数组与图标调用在两份脚本差分中没有改变；这仅覆盖源文本比较。脚本第 29 行把同一 SVG 字符串交给 Sharp 生成 PNG，第 120–121 行再以各 PNG 合成总览，解释了两张 PNG 随状态页传播变化的路径。恢复后的源与当前三导出仍版本不一致。

SHA256 比较不使用 mtime，因此三项差异不是仅文件系统时间改变。但对 PNG，原字节缺失使“内容像素变化 vs 文件内部元数据/压缩变化”的严格分解仍为 `UNKNOWN`。本轮不进行反向编辑当前 SVG、不重构原 SVG、不在内存试渲染来弥补缺失证据。

## 正式 Build 的纳入与引用检查

检查对象是 `E:/godot/beta-sprint-builds/beta_spatial_acceptance_input_fix_20261013_01`，不是本轮隔离 roof 预览工程。

| 检查 | 本轮结果与边界 |
|---|---|
| BUILD_IDENTITY | SHA256 `67021752bfec7a05223aa12b3b447005bf486818e54983b4559d32b5a53393c0`；source `0bb0e01742eacf12272956111cd6b86fdc74f819`；清单 1641 项。 |
| 资产纳入 | 对清单路径匹配三文件 basename、相对路径、旧工作包名/图册名和外部根；并匹配三文件原始/当前/备份内容 SHA256。资产命中 **0**。因此清单没有把它们以同名或相同字节改名纳入。 |
| 主入口 | `project/project.godot` 第 14 行与 identity 一致：`res://experiments/spatial_puzzle_batch_01/ui/main.tscn`；该场景第 3 行绑定本项目 `ui/main.gd`。 |
| 清单内文本搜索 | 读取并校验 1292 个 UTF-8 文本文件与各自 manifest 哈希，差异 0。检索三路径/文件名、工作包名/图册名及外部根，共 15 行命中，全部属于下述 3 份文档，非文档命中 **0**。二进制和未识别扩展名的跳过清单在 JSON，不把该搜索称为二进制解码/运行追踪。 |
| 静态资源入口追踪 | 从主场景和 project.godot 跟随现存 `res://` 字面量，闭包 196 个文件；上述关键词命中 **0**。这是保守文本引用闭包（可含注释），不是 Godot 实际运行可达性证明。 |
| 动态路径已知限制 | 静态闭包有目录前缀/拼接路径，如 `saved_authoring.gd` 第 7–10 行列举五图并拼成 authoring 目录的 level.tscn，第 20–22 行只枚举该目录 tscn/tres、第 41 行加载。项目清单内文本已整体搜索，但未对全部任意动态路径、UID 解析、原生扩展外部读取建立证明。 |
| 与当前基线兼容 | project.godot、main.tscn/main.gd、Spatial Host、Core Host、MapFactory、LogicalLighting、PuzzleRuleKernel 共 8 文件，Build 字节与基线 Git blob SHA256 全部相同；这不等于本轮重新完成全部 Runtime QA。 |

实际命中的文档是：

- `project/docs/beta-sprint/spatial-puzzle-batch-01/art/acceptance_01/EXTERNAL_WRITE_MANIFEST.json`：5 行，记录事故路径与备份。
- `project/docs/beta-sprint/spatial-puzzle-batch-01/art/acceptance_01/SCOPE_DEVIATION.md`：4 行，描述事故经过与外部包位置。
- `project/docs/beta-sprint/spatial-puzzle-batch-01/full-development/SUPPORT_AUDIT.json`：6 行，提及更早研究包路径。

这些**文档本身被打包**，所以不能说“Build 中完全没有外部包字符串”；它们不是三项图像被导入或加载的证据，且没有进入上述静态主入口引用闭包。最稳妥结论为 `NO_ASSET_MANIFEST_MATCH_AND_NO_PRODUCTION_LITERAL_REFERENCE_FOUND`。没有启动正式 Build，没有检查运行期文件访问日志、缓存、用户存档或未列入 manifest 的附加文件，不能扩张成对所有运行环境绝对无引用的数学证明。

## 逐文件恢复提案：待按文件授权，本轮不执行

三项当前都存在且格式可读，无需进行紧急删除、替换或再次全包导出。事故后备份只用于保留现状，绝不能充当原始恢复候选。对每项的精确接受条件如下：

| 恢复对象 | 候选优先来源与验收哈希 | 如仍无原始字节 | 替换前锁定的当前 SHA256 |
|---|---|---|---|
| `design/states/face_lock_D.svg` | 所有者提供的原交付/可信备份；必须匹配 `5482941575c67f1be0b5e83ff0dd3fde067c1b8b4bb31424b7a905d000aaa45b`。 | 另行批准后才能在全新候选目录重建单页；源脚本匹配不保证重建字节匹配。禁止直接编辑现 SVG 伪称恢复。 | `8fe6caa92e1de5db0ea79e3e05b1fd8a341e625b4bb737544b07f8b71ebb14fc` |
| `design/states/face_lock_D.png` | 原交付/可信备份；必须匹配 `cb619b6d77cc838295fca8c57d36255dbcf4f0280895bda8056819465b680b69`。 | 另行批准后，以已核验的原 SVG 候选、原字体/Sharp 环境在新候选目录仅生成该 PNG；编码差异也会造成哈希不等，不预承诺精确复原。 | `f2fa9426f7a27552f2aa91af8714c29ff1cdeed516f78f257ae00ad19511e27d` |
| `reports/DRAWING_CONTACT_SHEET.png` | 原交付/可信备份；必须匹配 `8a503ee044ccbd54210754c840ddb957be6d1bace43096b66f1dfec46b5cc51e`。 | 另行批准后，在新候选目录用核验的原状态页 PNG 和其余原清单匹配的页、既有原索引仅合成总览，不重导出全部 28 页。 | `30bba2f66d99031b4fb027e9e2f17d0e14136908b58165ee098aeeddfaefcad3` |

候选准备与覆盖原目录必须分开：先只读计算候选哈希和来源清单，匹配原清单才称“精确原字节候选”；不匹配则保持 `RECONSTRUCTED_DIFFERENT`，等待用户决定是否另立新版本。按文件获得替换授权后，才检查目标当前哈希仍等于表中值，任何并发变化立即停止；保留事故后备份和全部来源证据，逐文件替换后复核原哈希。不能更新原清单来掩盖事故，不能连带覆盖另外 56 个已相等导出。以上所有候选准备、重建和覆盖动作本轮均未执行。

## 本轮执行证据

使用只读 Python `-B`，对三项现文件、三项事故后备份、两份脚本、外部原清单和图纸索引共 **10** 文件作读取前后 SHA256，差异为空；JSON 保存全部前后值。PNG 仅用 Pillow verify/内存解码，SVG 仅 XML 解析。对命名 Build 只读 identity、manifest 内相关文本及主入口，未写其工程、QA 或存档。本结论只覆盖这 10 个外部文件的本轮稳定性，不假装重新审计整个目录。

`RECOVERY_PERFORMED=NO`；`THREE_CURRENT_EQUALS_POST_BACKUP=3/3`；`THREE_CURRENT_EQUALS_ORIGINAL=0/3`；`ORIGINAL_BYTES=NOT_FOUND_IN_PREVIOUS_BOUNDED_SEARCH`；`EXTERNAL_SCOPE_RECOVERY=PARTIAL`；`FORMAL_ART=PENDING_USER_REVIEW`；`INPUT_P1=CLOSED_UNCHANGED`。
