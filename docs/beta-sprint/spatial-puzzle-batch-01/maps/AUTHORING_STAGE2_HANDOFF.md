# Stage 2 — 五图正式作者资源候选（PARTIAL）

Task: SPATIAL_PUZZLE_BATCH_01_FULL_DEVELOPMENT / Owner 09。基线 `088d4ba815884a431f44e73d93cfb6881ff7faa3`，分支 `feat/spatial-authoring-maps-02`，工作树 `E:/godot/worktrees/block-girl-spatial-authoring-maps-02`。

**Stage Status: PARTIAL。五图保存入口仍 RED，不可替换现有可玩集成或交给玩家测试。** 00 已要求将可检查候选交给 01 进行 Stage 3 正式入口修复，09 随后复验。本文的诊断通过不等于生产链通过。

## 已交付内容

`experiments/spatial_puzzle_batch_01/maps/authoring/<level_id>/` 每图保存 `level.tscn`、独立 `surface.tscn` / `inner.tscn` 和 `intent.tres`。Face Lock / Combined 另有 `contact_lock.tres`。共 22 个正式作者文件，均使用已有 Foundation Authoring 脚本，稳定 authoring UUID；没有新增游戏规则或编辑器。

| 地图 | 保留 schema | 保存入口 | 同源资源 Node3D 诊断 |
|---|---:|---|---|
| world_shift_gate_lab | 4 | RED / Projector | canonical/hash、见证状态、Reset、SourceMap 一致 |
| orientation_loop_lab | 3 | RED / Projector + Schema | typed LEVEL 拒绝；未运行后续 bake |
| face_lock_lab | 4 | RED / Projector | canonical/hash、见证状态、Reset、SourceMap 一致 |
| perspective_fork_lab | 3 | RED / Projector + Schema | typed LEVEL 拒绝；未运行后续 bake |
| rubik_spatial_puzzle_01 | 4 | RED / Projector | canonical/hash、见证状态、Reset、SourceMap 一致 |

`map_factory.gd` 仅保留加载入口、既有教学文字和见证 Action；几何与规则 Dictionary 组装已删除。`saved_authoring.gd` 只编排真实 `DocumentProjector(SceneState/Resource, SAVED) → PayloadAssembler → AuthoringAdapter → Reader/Baker`，失败关闭。无直接 Baker 回退、无旧工厂回退、无诊断 Node3D 回退。Adapter 内部负责真实 Reader/Baker。

快照 fingerprint 绑定作者文件与允许的正式脚本文件 SHA256。`FILES_SHA256_AUTHORING_STAGE2.json` 列出本阶段生产资源、测试与冻结基线的实际文件摘要。

## RED 与局部验证证据

命令均从工作树运行 `python tests/beta_sprint/spatial_owner_09/run.py <case> <script>`。实际引擎是 Godot 4.7.2，独立 APPDATA/LOCALAPPDATA，隐藏进程；每个证据目录含源码快照、全 Foundation 摘要、PID、参数、时间、退出码、stderr 和漂移检查。

| case / script | 实际结果 |
|---|---|
| `authoring_baseline_capture_01 / capture_migration_baseline.gd` | PASS，五图旧工厂真实 bake 与全部见证 StateKey 冻结 |
| `authoring_migration_red_01 / authoring_migration.gd` | RED：206 checks，10 failures，仅保存入口与 Adapter SourceMap 缺失；旧数据/路线比对通过 |
| `authoring_saved_red_05 / authoring_migration.gd` | RED：15 checks，10 failures，五图真实 bake 与真实 SourceMap 均未产生 |
| `authoring_typed_diagnostic_06 / authoring_diagnostics.gd` | 156 checks，154 PASS / 2 FAIL：仅两个 schema3 LEVEL 投影失败；三图完整关卡/hash、见证 Action/state/key/orientation、Reset、精确 SourceMap 通过 |

上述最终两次运行 stderr 为空、source_drift 为空。失败退出码仍保留为 1，未把预期 RED 改标成 PASS。中间证据保留；`authoring_export_01` 只证明一次性文件导出成功，不是作者链验收。其首次 PackedScene 输出中冗余实例属性与内嵌 Intent/Config 已在最终候选中清理为独立文件引用，后续诊断证实 World 与资源投影有效。一次性导出工具仅保存在历史证据源码快照，不是生产依赖。

三图诊断的精确 content hash：

- Gate: `7a636b38301dff74027b2d5e80364d30b943b24f961cd73a2179b9ee7798acd4`
- Face Lock: `8bcd1b0708c8dca145ea67e5559e216745135c0a34bac41f16f99b1167a7e1e5`
- Combined: `5b4de9ca172f39ea537ceb00f3f56074d83f136cc768c66b9f4669764187d2c8`

诊断使用正式公开 Node3D overload 读取同一批已保存资源，只隔离 frozen SceneState 故障。生产 factory 始终使用 SceneState。两个 schema3 原版本未升级；其 typed fields 与拒绝记录见诊断 report.json。

SourceMap 检查包含根字段、Cube、Face、Lock Config 的 UUID、文件 URI、节点/资源身份、entity/field、canonical path、level_hash 和 fingerprint。见证比对逐步覆盖 Camera、World Shift、orientation、同边 U_NEG 岔路与返程的既有组合路线；仅三张 schema4 的诊断运行到此阶段。

## 01 最小修复请求

详见 [AUTHORING_OWNER_01_EXTENSION_REQUEST.md](AUTHORING_OWNER_01_EXTENSION_REQUEST.md)。需要修复 Projector、Schema、Adapter 三处正式作者入口；不需要新增 Kernel、Action、Safety、Solver 或 Replay 规则。

01 从此候选建立 Stage 3 分支后，09 执行新的 append-only case：

1. `authoring_migration.gd`：五图保存链、完整关卡/hash、逐步 StateKey/orientation、Reset、SourceMap 必须 GREEN。
2. `authoring_diagnostics.gd`：schema3 / schema4 均 GREEN，保持版本。
3. `fork_matrix.gd`：四相机、同边分岔、非法跨世界/落面/重叠拒绝。
4. 若完整规范关卡与原哈希一致且 Foundation Runtime 语义未变，可引用原 Combined 908 states / 3916 edges 图证据；当前仅诊断等价，尚未把该历史证据改标为迁移验收。若不一致，先查差异再决定专项验证。

本阶段新 Solver / Replayer 大矩阵、3D build、Human QA 均 NOT_RUN，等 Stage 3 GREEN 后由后续 Owner 执行。已有构建、历史验收、旧五关和盲玩结果未改写。原 Perspective Fall 盲玩包继续由 08 安排，真人结果仍待执行。

## 范围与交接

兼容依赖：旧非公开 `Maps.authoring(id)` 已删除。00 发现 `tests/beta_sprint/spatial_quality/test_mechanics.gd` 中仍有 7 处调用；由 03 在 Stage 4 适配，09 未越权修改。负例建议从 `Maps.bake(id)` 的真实 `baked.level.duplicate(true)` 开始，移除 `content_hash` 后仅在测试中改变目标字段再调用正式 Baker；先检查 `baked.ok`。Owner09 自己的 `fork_matrix.gd` 已采用此方式。不恢复旧生产几何工厂，不让 Harness 绕开保存作者链。

只改三条授权目录：地图资源、Owner09 测试、maps 文档/证据。Foundation changes: NONE；Host/Presenter/Audio changes: NONE；Existing level changes: NONE；Art source changes: NONE。

只读独立审查未发现 Critical；发现的 schema3 诊断脚本对 schema4 字段的错误假设已修复，并新增精确 SourceMap 验证。Integration Status: PENDING_00 / Stage 3 dependency。00 不应将 RED 候选合入可玩 HEAD；可用候选分支供 01 修复，之后依序回到 09/03/00/08。

本报告随候选提交。提交完整 SHA、普通 Push 结果和远端核验由交付消息提供，避免在提交自身内伪造其 SHA。开发分支交付成功不表示 Stage 2 COMPLETE 或 Integration PASS。
