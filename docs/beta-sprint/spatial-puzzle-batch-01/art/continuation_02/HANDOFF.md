# 05 → 00 · CONTINUATION_02 只读调查交接

Task：`SPATIAL_PUZZLE_ACCEPTANCE_CONTINUATION_02`；2026-10-13（Asia/Shanghai）。

| 项目 | 实际状态 |
| --- | --- |
| Owner / Worktree | 05 / `E:/godot/worktrees/bg-spatial-art-accept01` |
| Branch | `docs/spatial-art-continuation-02` |
| Base SHA | `295a4702aeb17d6fced11cfdaa221e0ffa90dd12` |
| 原分支 | `docs/spatial-art-acceptance-01` 保留，不重写历史 |
| 唯一写入范围 | `docs/beta-sprint/spatial-puzzle-batch-01/art/continuation_02/**` |
| B roof 两案研究 | COMPLETE_RESEARCH_ONLY；两案均未实现，Art=PENDING_USER_REVIEW |
| C 59 项事故调查 | COMPLETE_WITH_EXPLICIT_LIMITS；恢复仍 PARTIAL，未执行恢复 |
| 游戏代码/资产/地图修改 | NONE |
| Godot / Blender / 浏览器 GUI | NOT_RUN；未占用 08 窗口 |
| 新图形与真人理解验证 | NOT_RUN；沿用旧记录的提示曝光限制 |
| Integration | PENDING_00；不生成新 Build |

## B：roof 最小视觉方案

[ROOF_VISUAL_OPTIONS.md](ROOF_VISUAL_OPTIONS.md) 推荐 A 连续低频粗纹实体表皮，B 内收封闭边缘图案作为对照；均只提表面材质，不改变实体轮廓、透明度、通行、遮光、Gate 规则或四方向相机。两案均给出误导风险、制作估计与原生小尺寸/四视角/无提示观察要求。

关键约束：当前 roof 已是深色，单纯更深不保证解决误读；gate/source 也遮光，不能把“遮光”与“不可行走”等同。用户尝试登上 roof 是已确认的反馈，但用途说明后不能再算无提示首次理解。没有因此新增或关闭 Gameplay P1。

## C：外部导出版本调查

[EXTERNAL_EXPORT_INVESTIGATION.md](EXTERNAL_EXPORT_INVESTIGATION.md) 更正此前未找到原哈希的调查状态：找到原包 177 项 SHA256 清单并保留有来源限制的原字节快照。59 项逐项 [CSV](EXTERNAL_EXPORT_AUDIT.csv) / [JSON](EXTERNAL_EXPORT_AUDIT.json) 给出原/现/修改后备份哈希、格式和恢复可信度。

- 56 项与原清单一致，无需恢复；3 项不同：Face Lock 状态 SVG、状态 PNG、总览 PNG。
- 59 项均无缺失、格式检查通过、与事故后备份一致；不等于批准全部版式。
- 备份自身有 1 项引用缺口：HTML 链接的说明 Markdown 不在局部备份，当前原包中的该文件仍存在且哈希正确。备份不是完整独立图册，未尝试补文件。
- 177 项原包文件中 174 相等、0 缺失；已恢复脚本与原哈希相等。
- 在外部 model 根目录 4,558 个 PNG/SVG 和 4 个 ZIP 的 214 个图像成员中，未找到上述三项原字节副本；不声称永久丢失。
- 本轮严格没有外部写入。设计包 182 个文件、备份 62 个文件前后哈希一致；没有执行任何旧生成脚本、修复、恢复或资产导出。
- 恢复提案仅限定三项，要求候选哈希匹配、并发检查与用户独立授权。哈希清单的原始来源是本地交叉核验，未找到事故前独立签名锚点，此限制不能省略。

## 验证、Git 与接收建议

本次验证见 [VALIDATION.json](VALIDATION.json)：文档链接、JSON/CSV 对应、原清单快照字节、逐项统计、外部只读证明和 Git allowlist。未重跑旧 Gameplay checks；新的机制理解/完整四视角均 NOT_RUN。

Local Commit 是包含本交接的提交，可用 `git log -1 --format=%H -- docs/beta-sprint/spatial-puzzle-batch-01/art/continuation_02/HANDOFF.md` 查询；完整 SHA、Push 与独立远端核验时间在阶段最终回执给出，本文件不预写成功。

Remote：`https://github.com/QCYM-qcym/block-girl-mutsumi-mortis.git`；唯一推送引用 `refs/heads/docs/spatial-art-continuation-02`。无 main、force、tag、release、reset、clean 或跨 Owner 生产修改。

请 00 将研究与恢复状态分开接收：本轮调查可以完成，原始三文件恢复仍待授权/可信候选；roof 方案仅供用户审阅，不能集成材质或记为修复。此前事故文档保持历史，不覆写其当时 UNKNOWN 记录。
