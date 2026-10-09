# GAME_FEEL_INTEGRATION_QUALITY_01 — 03 交付索引

GAME_FEEL_QUALITY_READY 表示测试候选可交付，不表示新Fall已集成PASS。

工作树 `E:/godot/worktrees/block-girl-game-feel-quality`，分支 `test/game-feel-quality`，测试基线实际HEAD `2938d6e534f5b596bb320ce79d72b69f5923f3cd`。仅添加03三个allowlist根；不push、不merge其它Owner、不修改共享合同/Presenter/Host/Runtime/图形/音频/UI production。正式合同SHA256 `6224f8cd364f98da41822eabe7ba2973fa2db01d030373e7b3e94d69f35f23de`。

## 实测结果

| 范围 | 实际结果 |
|---|---|
| 独立矩阵 | 94项，12项CORE_PLAYABLE；实际Owner产物未接入的行独立case_pending/checks0/null SHA |
| Python观察/事件/矩阵Unit | 28方法通过；synthetic fixture明确声明无Runtime authority |
| Godot轨迹/拒绝观察Unit | 14断言通过；只消费合成记录，不构造Runtime/Host |
| Runtime/Legacy | 正式P01 public API控制146断言通过，L01-L05全部走既有路线；headless Unit，不是新Fall或原生Graphical回归 |
| Audio | 实际既有Audio/player/stream控制23断言通过；没有新增AudioDirector集成结论 |
| Settings | 实际Settings/Save/AudioServer，两个独立进程14+12断言，同一隔离Save路径/SHA |
| Safety | 既有正式Kernel/Safety161断言通过；新增Fall swept Safety NOT_RUN |
| Solver/Replay | 既有正式BFSSolver→Trace.validate_semantics→TraceReplayer/RuntimeSession 53断言通过；f34dd271的14源blob一致；Fall版本NOT_RUN |
| Candidate启动器 | 真Windows/forward_plus进程实际跑缺绑定路径，case_pending/checks0/null source_sha/authority，stderr空，不是播放PASS |
| Graphical/Animation/UI/Art/性能 | 新增正式集成均NOT_RUN；L06未进入范围，不测试 |

最终代码检查为451 checks/0 failures：28 Python方法 + 14合成Godot断言 + 409生产模块Godot断言。各次执行身份、profile、PID、命令、原始stdout/stderr、source SHA分别保留，不把WIP运行改标为最终commit。Settings冷启动仅证明已有设置；Reduced Motion/pause音频/新Landing触地时机NOT_RUN。

独立审查的两个Important已解决并复审：拒绝必须保持完整实际Runtime状态且没有接受authority；屏幕正下降必须在每个STARTED→COMMITTED区间内，不准由随后Roll补足。随后00指出真实Rules.rejected/error的next_state=null，已读正式源码并修正：保留null，通过输入前与下一帧get_state及官方StateKey.build验证不变，不能从null猜after。真实structured SAFE及evidence_ref保持原值，并校验官方版本化key/profile关联。原449历史记录不改写；native shape/structured SAFE另做RED/GREEN，最终451。Core候选只记录OBSERVATIONS_RECORDED，不输出acceptance verdict。

## 候选消费

```powershell
pwsh -NoProfile -File tests/beta_sprint/game_feel/run_quality.ps1 -Mode Candidate -Case CORE_A_NATURAL_FALL -Bindings res://docs/beta-sprint/game-feel/CORE_PLAYABLE_QUALITY_BINDINGS.json -EvidenceName <fresh-name>
```

本Owner `CORE_BINDINGS_EXAMPLE.json` 说明完整字段；00在自己的保留目录放实际绑定。允许PHASE_EVIDENCE_ONLY/TEST_DEPENDENCY_ONLY测试运行，Core正式receipt在真实闭环GREEN后登记，不成为循环依赖。具体接线/既有Host动态属性/后续退出路线见INTEGRATION_REQUEST。每轮自动隔离profile、捕获当前HEAD/dirty/source、禁止重写旧证据。Real/Graphical正式入口当前只报告pending；Unit不得冒充Real。

## 文件/证据

`FILES_SHA256.json`记录所有本次测试文件及主要文档SHA；排除自身、交付索引与复制的证据目录以避免循环hash。文件hash对应实际文件字节，不是虚构commit。

`evidence/20261010/final_native_contract/` 是最终代码实测原始产物副本；execution保留2938d6e + 实际staged/WIP身份与原始日志路径。额外保留先前449、review/flight/native-null/structured-SAFE行为RED、candidate pending以及setup导入stderr/恢复记录。全量append-only运行目录在本worktree `.godot/game-feel-quality/`。最终提交后另跑新名字验证，实际最终SHA/clean状态写最终回复及该轮ignored execution，不回写旧执行身份。

Known failure：新worktree首次editor import的冻结icons_source.svg出现ThorVG errorcode1，exit0不算导入通过；不是新Fall回归。未修改冻结素材，共享修复交00。旧13177bb UI-08-001/P2是历史未复测事项。L04历史加载最低9FPS未归因新动画。

Push: NOT_RUN。
