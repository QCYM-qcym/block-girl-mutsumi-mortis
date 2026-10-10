# PFALL_V2_QUALITY_MATRIX_REPORT

94项累计矩阵：54 PASS / 0 FAIL / 40 PENDING。逐项状态、范围、来源和证据见同目录 MATRIX_94.md/json。旧v2矩阵及历史证据保持封存。本次只升级 FORMAL_REPLAY、CORE_SAFETY_SOLVER_REPLAY、A_POSE_EDGE_RECOIL；51项既有PASS保留原执行身份。没有签发完整94项验收或 Human QA PASS。

正式接入与执行身份：

- Owner01正式交付：c60912b494baccb942e3f37f7c28d0c0c035dcc8。
- 00候选接入：f3bd68a3919b06c05294923b0cc6d17adbf8b3d4。
- 03正常合并后的实际执行HEAD：f43fd371d3cce266522eda62865aa97d1440e899。11份selected receipts共用此HEAD、相同579份已捕获非测试运行输入；WIP质量测试字节按每份process记录，不冒称全部来自clean commit。
- Engine：Godot4.7.2 Steam，Windows / D3D12 / Forward+ / RTX5060Ti。Graphical均为实际渲染进程、独立profile、真实PID；Solver/Safety等明确headless逻辑范围。所有selected exit0、stderr0、source_drift=[]、failures=[]、doubles=[]。
- 冻结公共合同SHA256：6224f8cd364f98da41822eabe7ba2973fa2db01d030373e7b3e94d69f35f23de。CONTRACT_MISMATCH: NONE。

| 独立运行 | 收据 | Checks |
|---|---|---:|
| FORMAL_GRAPHICAL TraceReplayer | c02_formal_green01 | 213 |
| Formal Replay生命周期 | c02_replay_lifecycle_green02 | 1015 |
| NATURAL_GRAPHICAL Presenter A/B/Camera | c02_g_natural01 | 62 |
| Native input spam | c02_g_spam01 | 22 |
| Fall/Landing原生输入/Reset/Pause | c02_g_lifecycle01 | 409 |
| Audio生命周期局部 | c02_g_audio01 | 36 |
| Existing Perspective Connection | c02_g_pconn01 | 66 |
| LOGICAL_SESSION original graph | c02_g_logical01 | 132 |
| 正式 swept Safety | c02_g_safety01 | 12 |
| L01-L05 focused regression | c02_g_legacy01 | 206 |
| 实际Shell/10B/Audio/UI normal/reduced A/B | c02_g_fullslice02 | 230 |
| 合计（独立收据各计一次） | | 2403 |

每份原始 process.json、report.json/matrix.json、stdout/stderr和SHA位于v2/evidence对应目录；最终矩阵直接引用其绝对文件路径。没有添加先前1311、Core69、Python Unit38、01总627或00检查到上述2403。

Core69的身份：原执行6074e48a8cfa98e34a2eb8533c37fa3aefdd97be、登记4b90a4bdb102550ad99cb3695fd49e394c1c447c；MAP A26、MAP B26、Camera rejection17，仅对应CORE_A_NATURAL_FALL、CORE_B_NATURAL_FALL、CORE_CAMERA_REJECT三个行，原始报告hash/PID/计数沿用封存矩阵。

Formal Graphical：PASS。消费唯一生产Replayer公开replay(mode1)/get_step_evidence，原始真实Solver UNFILTERED FULL_GRAPH selected witness先经Trace.validate与validate_semantics；A/B各重复两次，8 matched steps。原trace的 MOVE U_NEG实际触发 authored Fall→自然Landing，再MOVE U_POS普通Roll→Goal。没有改动作来替代原图trace，没有写Runtime状态/actor姿态或手动finish，没有加载Unit adapter。

每步核对完整session/run/generation/transaction/global身份、STARTED<COMMITTED<completion、唯一native commit、完整状态/StateKey、World/Orientation/Camera、正式数学独立投影，以及实际Fall/Landing/Roll中间帧和物理终点。重复trace语义终点一致，native身份全新。LOGICAL_SESSION另有A/B各2步，不替代Formal Graphical；Natural Presenter另有独立receipt。

生命周期：18真实案例，36新运行matched steps。A/B×FALL/LANDING×原生R、remove→readd同栈新回放、菜单外Node退出、活动节点free，加两条真实in-flight step_timeout。18个旧记录各取消一次、完成0、旧matched0；4次真实Reset提交为spawn/count0/idle、同session/run generation+1；4次free确实释放旧Node。新运行36步独立身份均匹配原始trace；无旧完成污染。此证据不替代完整Shell Exit/Focus/VFX矩阵。

Runtime parity：PASS，限定原始A/B witness及上述原生生命周期。Graphical parity：PASS，限定真实Bridge/Presenter的Fall/Landing/Roll帧、终态与Camera；不扩张为Inner、六面新Art或完整94项。

失败尝试完整保留：

- c02_replay_lifecycle_green01：997 checks /14 failures。测试读已释放Bridge得到空记录；修为真实motion_cancelled信号当刻快照，green02通过。没有修生产模块。
- c02_g_fullslice01：230 checks /8 failures。Reduced Motion A在Roll中实际Pause；截图可见暂停界面，没有此收据的focus recorder，原因未证。同生产字节复跑fullslice02为230 PASS。不能据此认定Runtime或Reduced Motion缺陷，也不能删掉首轮。
- c02_native_gaps_red01：369 checks /22 failures、stderr250。过早采Edge、错误要求Edge native token、猜Space分类、质量观察回调自持有泄漏。已按实际合同修正；后续尝试stderr0。
- c02_native_gaps_green01：380 checks /3 failures；green02：431 /3；native_base_green01：121 /9。记录到真实FOCUS_OUT和Runtime/Audio Pause；最后一份还包含错误的四独立FaceAxis假设（已改消费正式Mapper）。这些不是严格GREEN，也不从其部分PASS行签Real PASS。

对应13个输入/反馈行仍PENDING。最新NativeMatrix护栏只做实际--check-only（exit0/stderr0），Real GREEN: NOT_RUN；将动作到达、跨帧held、Reset native commit、原Fall唯一commit/LANDING_SETTLED、Exit全生命周期取消互斥作为下次稳定执行的条件。没有自动Resume将被中断的原轮次转为PASS。

Owner handoff：没有新确认的Gameplay/StateKey或Presenter生产缺陷；00继续核对未知Pause/Focus集成环境，03后续在稳定窗口执行余下输入矩阵。00已报告direct Facade.reset取消诊断标签CANCEL/RESET差异，保留其非阻塞诊断范围；原生R实际RESET已验证。未修改01/00/10A/10B生产实现。

NOT_RUN/PENDING：完整40行验收；拖动的正式实验路径、完整Inner权限/24 Orientation端点、每种真实拒绝fixture、100轮/30分钟soak、阶段frame-time和独立L04冷暖加载、05新GLB/Shader/VFX生命周期、完整Audio/UI及Human听视验收。L06不在正式集成范围，条件性NOT_RUN。历史L04加载最低9FPS未归因于新Fall。

独立审查核对94唯一ID、差分仅3项、11份真实receipt身份/字节、失败保留及2403计数。38 Python测试为synthetic Unit，不算Real；正常/优化Python report重复构建须字节一致。文件清单/SHA见FILES_SHA256.json。

Owner阶段提交：9866cdd56ded37ed7da753d52eb183d11a3c748e、fac96d18037402f09988d3fdec9d11a4c5e45d4b、2d856d39344d76a5c6a26d4790092264a8c2fb9d、a5642e2f0dac52c11a1f13bce5b86523e14e538b、9663baf5bf6e67d56a1d1017085ef10b4af57a37、2f930aaa191daa93c8f6ff230e91beee90817c80、63c883fa8af70ac6f332b69cddd37b57b2576e42、28d7f3e4ae0cd420bcab37e486937546e4d23911。最终交付commit由包含本报告的03提交记录提供，执行SHA与交付SHA分开。

Push: NOT_RUN。未推进正式Integration ref、main或Core。
