# Owner09 作者资源复验 — GREEN

Task: `SPATIAL_PUZZLE_BATCH_01_FULL_DEVELOPMENT`。日期：2026-10-12（Asia/Shanghai）。Owner：09 Map & Spatial Design。

工作树：`E:/godot/worktrees/block-girl-spatial-authoring-maps-02`。分支：`feat/spatial-authoring-maps-02`。

已按 00 授权，从冻结候选 `a2a716734dab0a63ff8de397087665ef704337fd` 正常 fast-forward 接收 01 Stage 3 依赖 `859c5ac9601d624eb0666f4c333336ec1774ab47`。依赖远端 `fix/spatial-authoring-entry-02` 的完整 SHA 已独立核验。没有修改 01 代码、地图资源、地图机制或 Owner09 测试脚本；本次仅增加本报告、结果清单与 append-only 证据。

## 本次实际运行

在本工作树执行以下命令，使用既有 Godot 4.7.2、每次独立 APPDATA/LOCALAPPDATA 和隐藏进程：

```powershell
python tests/beta_sprint/spatial_owner_09/run.py authoring_owner09_green_01 authoring_migration.gd
python tests/beta_sprint/spatial_owner_09/run.py authoring_owner09_typed_01 authoring_diagnostics.gd
python tests/beta_sprint/spatial_owner_09/run.py authoring_owner09_fork_01 fork_matrix.gd
```

| case | checks | 结果 | PID |
|---|---:|---|---:|
| authoring_owner09_green_01 | 236 | PASS | 38940 |
| authoring_owner09_typed_01 | 264 | PASS | 46308 |
| authoring_owner09_fork_01 | 37 | PASS | 17276 |

**本次共 537 checks，0 failures。** 三个进程 exit 0、stderr 0 bytes、source_drift 为空。证据位于本目录 `evidence/<case>/`，含正式输出、完整过程记录和源码快照。复验后逐项核验 process.json 中所有源码 SHA256 仍与当前文件一致。

五图生产路径均已真正通过保存的 SceneState / Resource → DocumentProjector → PayloadAssembler → AuthoringAdapter → Reader/Baker。完整 canonical level 与冻结旧工厂 oracle 相等，保留 schema3 / schema4、content_hash、全部见证逐步 Action status / state / StateKey / orientation 和 Reset。SourceMap 的 UUID、URI、node/resource 身份、entity/field、canonical path、level hash、fingerprint、snapshot_id 检查通过。

| 地图 | schema | content_hash |
|---|---:|---|
| world_shift_gate_lab | 4 | `7a636b38301dff74027b2d5e80364d30b943b24f961cd73a2179b9ee7798acd4` |
| orientation_loop_lab | 3 | `45bc655f778ae214e8ca830c4e8be59b618b2b854c808f3741d4e6f277d56a70` |
| face_lock_lab | 4 | `8bcd1b0708c8dca145ea67e5559e216745135c0a34bac41f16f99b1167a7e1e5` |
| perspective_fork_lab | 3 | `8b485492113fec9f1ee74d347b88d31a6012f50359b97f9d26fee4c1e603054a` |
| rubik_spatial_puzzle_01 | 4 | `5b4de9ca172f39ea537ceb00f3f56074d83f136cc768c66b9f4669764187d2c8` |

Fork 专项验证四向 Camera、同边 U_NEG 的确定落点、orientation / layer 保持、Reset；不允许视角仍返回 CAMERA_NOT_ALLOWED，跨世界与不可行走落面仍被 Runtime 拒绝且无 transition / StateKey 改变，重复相机授权连接仍被 Baker 拒绝。

## 历史证据与范围

Combined 完整规范关卡及其 hash 已证明与旧版本完全相同；01 依赖只修三个 Authoring 入口，未修改 Runtime/Kernel/Safety/Solver 规则。因此按 00 要求引用旧 `evidence/combined_runtime_02` 的 908 states / 3916 edges、0 softlocks / 0 bypasses 结果，**仅为历史 reference，本次没有重新搜索、没有增加 assertions**。本次也不计入 01 的 901 checks。

地图文件与 Owner09 测试相对于冻结候选的 Git diff 为空，`FILES_SHA256_AUTHORING_STAGE2.json` 中的所有文件摘要仍一致。旧 RED 报告保持原样；本报告记录接收真实依赖后的 GREEN，不回填历史。

09 新增 Foundation changes: NONE。分支继承已授权 01 的三个 Foundation Authoring 修复，不能将整个分支误报为无 Foundation 依赖。旧五关、Host/Presenter、Audio、Art 源资产均未改变。

Tests FAIL / PENDING（本次三项）：NONE。Combined 新全图、图形构建、图形 Replay、Human QA：NOT_RUN。逻辑 GREEN 不代表图形或玩家验收。

Owner09 作者迁移复验阶段：COMPLETE / GREEN。Integration：PENDING_00；03 正在独立 Stage 4 验收，仍需处理其旧 `Maps.authoring` 调用依赖。最终可玩集成与 08 玩家验证由 00 继续安排。

本次提交仅包含 `docs/beta-sprint/spatial-puzzle-batch-01/maps/**` 新文档/证据。GitHub 交付按 Commit → 普通 Push 本 Owner 分支 → 独立远端 SHA 核验；最终完整 SHA 与核验结果在交付消息提供，不在提交自身中伪造。
