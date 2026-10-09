# GAME_FEEL_QUALITY_READY — 测试候选

03 Quality，2026-10-10。正式工作树 `E:/godot/worktrees/block-girl-game-feel-quality`，分支 `test/game-feel-quality`，来源 `2938d6e`。共享合同 SHA256 `6224f8cd364f98da41822eabe7ba2973fa2db01d030373e7b3e94d69f35f23de` 实际核验一致。

只写本 Owner 三个 allowlist 根：`tests/beta_sprint/game_feel/`、`tests/beta_sprint/game_feel_owner_03/`、本 docs 根。没有合并其它 Owner、扩展公共合同、写 Host/Presenter、Puzzle State、Solver 或 Replay 算法。原 FOUNDATION-4C工作树、`block-girl-game-feel-quality-01` 的 13177bb探索代码/index和原始运行证据保留；旧结果没有改记为新基线 PASS。

## 当前交付

94 项独立矩阵（matrix.py），含 12 项首轮 CORE_PLAYABLE；每项有依赖、准备、输入、预期及原始证据要求。缺实际依赖的行独立 case_pending、checks=0、source_sha/delivery_sha=null、natural_success=null。旧 Foundation正式 receipt gate 完全保留；未提供新 Real acceptance捷径。

Core执行只依赖实际01/09/10A + 00 Host/原生输入，不等待05/07/11；Core receipt在真实闭环GREEN后登记，单列registration_requirements，不成为循环运行门槛。覆盖 A/B真低/真高落点、非法camera/无作者连接/跨World、完整state/key/Orientation、连续Fall、Landing后移动、Reset/input/BUSY、Safety/Solver/Replay及普通 Roll/原PerspectiveConnection。音频、UI、Art/性能分别登记，不挤进 Core case阻塞独立开发。

Animation矩阵含Fall/Landing/Recoil Pose，3阶段×9类输入压力、24态端点/六面、迟到回调/新启动、Pause身份保留、100轮。Audio覆盖次数/触地/暂停/音量/冷启动/去重节流；UI覆盖设置preview/apply/cancel、Reduced Motion/Hint Strength独立presentation config、三尺寸HUD/焦点。Art/性能包括真GLB、资源/Shader/VFX生命周期、30分钟运行和分阶段帧分布；L04加载9FPS不归因Fall。Legacy L01-L05 focused；L06条件单独登记。

Python仅是观察断言：拒绝不改变完整状态；完整动作窗口提交/结束次数、模型起止Pose、Recoil不变、Tween/VFX残留和输入恢复；音频事件按Owner给出的次数与容差关联；Frame Time按阶段计算nearest-rank p50/p95/p99/max，没有捏造性能门槛。新合同断言检查真实port需满足的snapshot/identity/分类/授权path、cube24范围/PRESERVE与sample中性值，不生产事件、不判权限、不算路径/姿态。JSON测量数组只用于Quality序列化，不改native Vector3i/QuaternionABI。

UNIT人工样本明确fixture_kind=PRESENTATION_CONTRACT_UNIT、authoritative_runtime=false、doubles声明synthetic_observations/event_snapshot/motion_sample。它们不构成合法Fall、Real或Graphical PASS。

## 实际执行

| Execution | 实际结果与身份 |
|---|---|
| contract_red_20261010 | 新合同断言行为RED，24 methods/8 failures；坏分类/身份/path/样本未被初始断言识别。早期原始日志保留，Source未完整快照；不用于任何正式质量结论 |
| contract_unit_green_20261010 | 25 Unit methods通过，94矩阵更新前实际为82行，原JSON保持原身份 |
| contract_baseline_20261010 | 25 Unit methods + 409 Godot assertions，0 failures；五关模块146、音频23、settings14/12、正式Kernel/Safety161、正式Solver/Replay53；HEAD2938d6e、真实WIP source/hash记录 |
| core_pending_probe_20261010 | 实际加载Core候选脚本，缺00绑定/01port → checks0/source_sha=null/case_pending；不算Real/Graphical播放 |
| setup_20261010 | Editor import stderr有ThorVG错误，单独保留，不能因为exit0算import PASS |
| review_red_20261010 | 28 Python methods：3 failures/1 error，暴露拒绝authority/full-state、同world/type、malformed和Core循环门槛断言缺口 |
| flight_review_red_20261010 | 12合成观察断言/9 failures，静态Fall+后续Roll、瞬移、非player状态改变及伪接受拒绝不能通过 |
| reviewed_baseline_20261010 | 28 Python + 12合成轨迹/拒绝Godot + 409生产模块Godot = 449 checks，0 failures，Godot stderr全空，所有依赖矩阵仍pending |
| candidate_pending_final_20261010 | 真Windows/forward_plus进程，隔离profile；缺00候选绑定/01port → checks0/case_pending，stderr空，formal_result NOT_RUN |
| delivery_baseline_20261010 | 最终代码/UID候选：449 checks/0 failures；正式Solver14 blob完全匹配，所有生产算法doubles=[]，原始WIP HEAD未改写 |
| native_null_behavior_red_20261010 | 真实拒绝null-next-state进入Unit，28 methods/1 failure；原Quality错误假设被拒绝，另一个早期参数API失败仅作Harness故障保留 |
| structured_safe_red_20261010 | 真实structured SAFE/evidence_ref进入Unit，旧字符串SAFE假设出现行为失败；不改Owner结果 |
| final_native_contract_20261010 | 最终451 checks：28 Python +14合成Godot +409生产模块，0 failures/Godot stderr空；真实拒绝shape、actual Runtime前后快照、正式StateKey与SAFE引用接线准备完成 |

独立审查发现旧音频Reset检查缺“声音已播放”前置条件。迁入的新测试先确认roll/land实际player.playing且active_sfx_count=2，再验证Reset到0；旧探索证据不修改。音频释放后等待0.2秒让AudioServer线程回收voice，最终测试stderr空。

所有Baseline测试进程采用独立APPDATA/LOCALAPPDATA；Godot报告实际OS.get_user_data_dir并检查其在本轮profile下。Settings两个不同PID使用同一隔离Save路径及相同SHA256。运行记录实际HEAD/dirty、输入/fixture类别、engine/display/renderer/PID、完整命令/raw stdout/stderr、source SHA和漂移。正式Solver14个blob核对f34dd271；直接调用正式BFSSolver.solve→SolutionTrace.validate_semantics→TraceReplayer/RuntimeSession，无旧Trace double。

Baseline只运行已有production public API的headless Unit/控制；原生键鼠与新增Fallpipeline正式结果各自NOT_RUN。真实旧Kernel/Replay调用不填新Fall行。

## 命令与候选API

```powershell
pwsh -NoProfile -File tests/beta_sprint/game_feel/run_quality.ps1 -Mode Unit -EvidenceName <fresh-name>
pwsh -NoProfile -File tests/beta_sprint/game_feel/run_quality.ps1 -Mode Baseline -EvidenceName <fresh-name>
pwsh -NoProfile -File tests/beta_sprint/game_feel/run_quality.ps1 -Mode Candidate -Case CORE_A_NATURAL_FALL -EvidenceName <fresh-name>
pwsh -NoProfile -File tests/beta_sprint/game_feel/run_quality.ps1 -Mode Real -Case 'CORE_*' -EvidenceName <fresh-name>
```

当前Real/Graphical模式只报告选中的依赖pending行，exit0没有PASS含义。候选自然Core观察脚本的API是：

```text
Godot --path <actual integrated project> --script res://tests/beta_sprint/game_feel_owner_03/test_core_playable.gd --max-fps 60 --
  --case=CORE_A_NATURAL_FALL
  --bindings=res://docs/beta-sprint/game-feel/CORE_PLAYABLE_QUALITY_BINDINGS.json
  --execution-head=<actual HEAD>
  --evidence-dir=<fresh isolated evidence directory>
```

Candidate启动器隔离profile并记录实际HEAD/dirty/source，接受00的PHASE_EVIDENCE_ONLY/TEST_DEPENDENCY_ONLY绑定；自然原生输入驱动00Host，不加headless。它不依赖自己的正式Core receipt，也不签发Real；真实闭环GREEN后00再登记slot/receipt。A/B以外case绑定、版本化StateKey/Solver/Replay说明及shared metadata导入修复见INTEGRATION_REQUEST。观察器只读取实际01信号、角色/相机/坐标frame和执行Input.parse_input_event；不调用finish_local/global，不设置State，不插赢边。它保存动态真实actor中间点、接触/提交与完整Pose证据；目前只完成缺依赖路径实际测试。屏幕下降独立限制在每次STARTED→COMMITTED区间，后续普通Roll不能补足Fall下降；拒绝保留native next_state=null，另外验证实际get_state/官方StateKey前后不变，不从null推测after。

新Runtime/Fall/Graphical/Animation、Audio触地与Pause、UI/Reduced Motion、Art/VFX/performance、Fall-specificSolver/Replay/Safety和五关Graphical focused均NOT_RUN。没有Human QA或新Fall PASS。已知问题为当前SVG fresh-import错误；旧13177bb的UI-08-001/P2另作为历史未复测问题保留，不能推断新基线已关闭或仍复现。

最终候选commit/source SHA及最终未改写执行身份见交付索引。Push NOT_RUN。
