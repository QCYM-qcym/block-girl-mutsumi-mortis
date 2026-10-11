# OWNER_BUG_HANDOFF → 01 Runtime：正式作者入口缺口

基线：`088d4ba815884a431f44e73d93cfb6881ff7faa3`。候选分支：`feat/spatial-authoring-maps-02`。09 未修改 Foundation。这是既有 schema3/4 的作者入口支持，不是新增空间规则。

## 1. 保存的 SceneState 拒绝全部五图 LEVEL 扩展字段

入口：`experiments/spatial_puzzle_batch_01/maps/authoring/<level_id>/level.tscn`。

真实证据：`maps/evidence/authoring_saved_red_05/report.json`。`INVALID_FIELD` 路径 `..camera_initial_quadrant`、`..perspective_falls`，schema4 另有 `..shift_gates`；之后 LEVEL `INVALID_RECORD`，World instance override 报错是根节点失败造成的级联。

`foundation/authoring/document_projector.gd` `_scene` 约 265 行只通过 `Schema.FIELDS[kind]` 选取存储属性，没有纳入版本声明对应的扩展字段。相同保存文件经公开 Node3D overload 投影时三张 schema4 通过，独立 World 文档投影通过；并非地图私自覆盖实例。

最小要求：保存场景的属性收集与正式版本字段合同一致；保留闭合字段校验、脚本摘要白名单和实例 override 拒绝。不能忽略未知属性或接受任意 runtime Dictionary。

## 2. schema3 的 typed LEVEL 本身被拒绝

Loop / Fork 保留 `schema_version=3`、`foundation.game_feel.v2`、`foundation.rules.game_feel.v2`。真实 typed 字段来自保存节点 `declared_fields`，资源引用由正式投影处理；诊断 `typed_level_valid=false`，公开 Node3D 投影报 `INVALID_RECORD`。

`foundation/authoring/authoring_schema.gd` 约 77 行仅为 `Feel.spatial` 加入扩展字段；约 140–141 行只接受 legacy1 或 spatial4。需要承认现有 schema3 Camera / Perspective Fall 字段及既有版本元组。schema3 不应要求或添加 schema4 的 `shift_gates` / `face_locks`，不能升级地图版本绕过故障。

## 3. Adapter 会丢掉 schema3 camera/falls（静态可达性缺口）

`foundation/authoring/authoring_adapter.gd` 约 53 行只在 `Feel.spatial(level_fields)` 时复制 `camera_initial_quadrant`、`perspective_falls`。即使前两处放行，schema3 模板仍缺少既有 Reader/Baker 所需字段。

最小要求：按已支持的版本传递 camera/falls，schema4 再传递 gates 与派生 locks。禁止修改数值、曲线、权限或状态转换。此项在当前基线被 Schema 拦截，09 未伪造一次运行至 Adapter 的 schema3 PASS/FAIL；由代码审计指出，须在 Stage 3 真正端到端验证。

## 验收合同

- 保持公开 `project_document` / `assemble_payload` / `bake_authoring` 形状；仅恢复已有版本的表达能力。
- 使用候选真实资源让 `authoring_migration.gd` 五图 GREEN；真实 SourceMap 可追溯至 LEVEL / World node / Face / Config 的稳定 UUID 与文件。
- 原 schema3 / schema4 完整 canonical level、content_hash、Camera、World Shift、orientation、同边分岔/返程和见证逐步 StateKey 不变。
- 继续拒绝不受支持脚本、属性、版本、不合法实例 override 和非法落点。不要全局放宽 Safety 或 Face 匹配。
- Kernel / Runtime Action / StateTransition / Safety / Solver / Replay / Presenter 合同变更：NOT_REQUIRED by this evidence。

执行（从候选工作树，使用新 case 名，不覆盖历史）：

```powershell
python tests/beta_sprint/spatial_owner_09/run.py authoring_stage3_green_01 authoring_migration.gd
python tests/beta_sprint/spatial_owner_09/run.py authoring_stage3_typed_01 authoring_diagnostics.gd
python tests/beta_sprint/spatial_owner_09/run.py authoring_stage3_fork_01 fork_matrix.gd
```

09 的 `migration_baseline/*.gdvar` 是从基线旧工厂的真实 bake/Runtime 捕获的测试 oracle；生产从不加载。不要重生成基线来让错误迁移通过。
