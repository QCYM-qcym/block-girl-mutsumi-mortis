# Owner07 — Spatial feedback / Orientation Continue 专项

Task ID: SPATIAL_PUZZLE_BATCH_01_FULL_DEVELOPMENT / Owner07 feedback02

Worktree: `E:/godot/worktrees/block-girl-spatial-ui-feedback-02`
Branch: `feat/spatial-ui-feedback-02`
Base: `088d4ba815884a431f44e73d93cfb6881ff7faa3`
Design dependency: `19c3b4be1a443051d2c8e7498d06d39a282e4075`（基线已包含）

## 实际修改与边界

只增加 `tests/beta_sprint/spatial_owner_07/feedback_02/` 中的专项测试与本目录的计划、报告、原始证据和绑定工具。没有修改 Main、Host、SaveStore、Runtime、地图、project.godot 或正式 UI Tokens。现有生成式 Factory 是本次实际来源；09 的最终作者资源迁移尚待集成复测。

## 已验证的反馈

| 情况 | 实际正式结果与界面表现 |
| --- | --- |
| 普通位置提出 Shift，无 Gate | 2010 / WORLD_NOT_ALLOWED；HUD“请到标记的转换点确认”；完整 StateKey、提交数不变 |
| 有 Gate 但锁未激活 | 2011 / MECHANISM_LOCKED；HUD“机关尚未激活”；Hint / Reduced Motion 开启后仍拒绝，状态不变 |
| 合法 Gate | 原生 Space 经真实 Facade 成功；自然 Presenter 完成；改变世界，保持物理 Orientation / Camera |
| FaceLock 错误接触 | 成功 MOVE 到同一传感位置，Orientation20，正式锁 idle；标记仍“面 4 朝下”，没有虚构激活 |
| FaceLock 正确接触 | 第二次 MOVE 在同一提交内 idle→latched，Orientation14；标记“已激活”；离开和 Shift 后保持 latch；Reset 恢复 idle |
| Fork 非法 Camera | q0 / q3 下同一原生 F 边，2101 / CAMERA_NOT_ALLOWED；HUD“当前视角没有合法连接”；状态、提交数不变 |
| Fork 合法 Camera | q1 下同一原生 F，PERSPECTIVE_FALL_APPLIED；自然过渡到正式 target_a，Orientation / 世界保持 |

UI/Host 已检查不调用已知 Gate/contact 资格计算入口，实际许可来自正式事件和 Runtime。这是所读入口与真实行为的证据，不宣称任意程序的完整静态证明。世界标记只表达作者身份 / 已提交机制状态。

**反馈限制交给 00 / 13：** 错误 FaceLock 接触目前只有不变的朝下脸要求标记，没有专门的错误接触原因文本。成功 MOVE 本身没有拒绝事件；本次没有伪造拒绝或跨 Owner 修改 Host。专项通过不等于已实现比当前表现更强的设计反馈。

## Orientation Loop 真正冷进程证据

最终 seed PID29240：真实菜单选择 Loop，实际执行四次 closed_loop MOVE，自然完成四次正式提交；回到同一 Position，Orientation0→15，完整 StateKey 改变，Camera / world / mechanism 不变，无 Goal。

原 Store 在移动及退出后字节不变：SHA256 `bd4cc21f753132562abd55d5f33544b3c4b93b5370fdc541aea4edaaf5cf1142`。只保留 recent level / 既有进度字段，没有增加中途 pose / Orientation / StateKey 保存合同。

另一个实际 OS 进程 PID38764，用同一隔离 APPDATA/LOCALAPPDATA 冷启动正式菜单；原生点击 Continue。恢复正式 level spawn Orientation0、初始完整 StateKey，区别于闭环后的 StateKey，提交数0，level content hash 一致。不是同进程 Reset / reload。

## 验证与保留的失败

实际命令：`./tests/beta_sprint/spatial_owner_07/feedback_02/run.ps1 -EvidenceName feedback02_final_01`。
Godot4.7.2.stable.steam.ed1daf0bf，实际 headless，3进程，104+32+14 = **150 checks PASS**，全部 exit0 / stderr0，source/cache 无漂移。另有新工作树上的原存储 baseline35 checks PASS，单独报告，不混作机制检查。

原始文件保留在 `evidence/`：baseline_store_01、feedback02_first_01、feedback02_green_01、feedback02_final_01。初次 cold 1项失败是测试诊断 JSON 字典与原生字典直接比较的 StringName/int→String/float 类型差异；完整 canonical StateKey 已正确。已改为字段比较，独立完整 StateKey 断言保留。第一次 green 各阶段150项通过，但 PowerShell OrderedDictionary 的聚合字段 null；只修正 runner 聚合，再执行最终150项。两份旧证据没有改写。

SourceCommit 及测试字节→live→Git blob 的323文件绑定见 `DELIVERY_BINDING.json`；实际执行时 HEAD 为上述 base、测试文件未提交，此事实保留。后续只提交绑定与报告元数据。18份批准缓存与引擎 SHA 单列，不伪装为 Git 源码。只归档原始日志 / 诊断报告，不归档隔离 profile 或玩家存档。

Stage Status: COMPLETE（本次 Owner07 headless 专项）
Integration Status: PENDING_00（09最终作者资源迁移及00集成）
Graphical / 3-resolution / Visual Regression: NOT_RUN（未获本阶段GUI时隙；不继承旧PASS）
Human QA: NOT_RUN
Push / 最终完整交付 SHA / 远端独立核验时间：以提交后当前聊天的实际 Stage Handoff 为准；绑定创建时尚未 Push。

00 接收次序：本分支专项测试与文档；09最终资源集成后，在新的最终来源运行该专项（新的 evidence name），核验 Factory witnesses / full StateKey / 原 Store；分配图形时隙后补实际截图与视觉检查。当前无正式 Host 运行错误；上述 wrong-contact 反馈限制需要单独设计判定。全 Batch / Release 验收仍由00 / QA负责。
