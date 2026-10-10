# PFALL_FORWARD_DROP_TO_YELLOW_REPORT

Root Cause: 旧 v2 在 600ms 动作前段保留 90ms 原地 anticipation，前倾在停留时达到峰值；后续使用均匀曲线参数，无法证明立即向前起步和加速下坠。新动画立即前进并前倾，沿正式出边线持续移动；中心越过源平台半单位支撑边界后离边，再进入带前向分量的连续坠落。390ms 前进段和210ms 坠落段共享正向 C1 接点，没有空中中继停顿。沿用正式 source/leave/target 轨迹和原生 transition identity。

Map Target: 01/09 只读核验确认原黄色 target/TOP 已正确。MAP A anchor2=(-6,1,8)，MAP B anchor2=(-6,9,8)。blue_reference 四面/六面均无正式可走目标，不是连接落点。未改 Map、Runtime、Baker、Safety、Solver、Replay、Host、Save、冻结美术或五关谜题。

| Required result | Actual |
|---|---|
| Forward Advance | PASS |
| Edge Leave | PASS |
| Descend | PASS，连续正式轨迹、正向参数推进、前后段 C1 |
| Land On Yellow TOP | PASS |
| Wrong Blue Target | REJECTED，当前两张正式实验地图 |
| Landing Feel | PASS，实际压缩、回弹、稳定与黄色支撑接触 |
| Orientation | PASS，Fall保留0，后续原生Roll为12 |
| StateKey | MATCH |
| Commit | EXACTLY ONCE |
| Fall → Roll → Goal | PASS |
| Reset / Held input / Illegal Camera | PASS |
| Human Feel / Human QA | NOT_RUN |

本次真正修改的生产文件只有10A的 fall_motion.gd 与 motion_parameters.gd，SHA见FINAL_SCOPE.json。新调参字段采用float64边界，旧v1行为、Reduced Motion权威状态和取消清理保持兼容。地图与Runtime无需视觉补丁。

| Fresh verification | Actual checks |
|---|---:|
| 10A Unit，声明DTO/Safety/native-commit doubles，单列 | 13222 PASS |
| 01只读API/legacy/runtime/kernel审计 | 704 PASS |
| 09实际地图Baker/geometry/Safety/Solver/logical审计 | 29 PASS |
| 00源工程真实图形+两进程冷设置验证 | 497+27 PASS |
| 03八个独立原生执行 | 2761 PASS |
| 新包本体自然图形、正式重放、1280×720 Shell/Reduced/Audio及冷设置 | 403+27=430 PASS |
| 03本轮十项专项 | 10 PASS / 0 FAIL / 0 PENDING |
| L01–L05实际Shell图形回归（包含在03中） | 206 PASS |
| 旧Fall profile / 旧Perspective Connection（包含在03中） | 16 / 66 PASS |

源工程、新包和03均真实调用 GRAPHICAL TraceReplayer mode1，各匹配8步骤。03逻辑重放单独核验；18个生命周期中断用例观察18取消、0晚到完成、36新步骤匹配。通过的Real执行均 exit0、checks>0、failures=[]、stderr空、doubles=[]、source_drift=[]。03引用的00自然71项不再计入2761。

新包第一次Shell矩阵在35.256秒真实失焦，Shell按规则暂停Roll，后续自动输入造成8个连锁失败；原日志保留。独占重跑package_matrix02为230 PASS，无FOCUS_OUT。没有改生产暂停规则、跳过断言或伪造完成事件。更早RED、重复/重叠执行也保留且不计入通过总数。

视觉证据：E:/godot/worktrees/block-girl-foundation-4-integration/docs/beta-sprint/game-feel/forward-drop-01/evidence/package_natural01。MAP A/B各六帧：起点、前进离边、中段、接触前最后实际FALL帧、黄色触地、稳定。图片来自真实Godot4.7.2 D3D12渲染。Body八角支撑接触、前倾方向和接点速度已实际检查。

量化的参数加速不宣称所有3D世界轴/投影速度都单调增加；MAP B仍保留实际高度增加的正式错视坠落。主观是否充分消除“飘”的感觉必须由08在本包试玩确认，Human Feel仍NOT_RUN。旧94矩阵、Art/UI/Human依赖不借本轮升级。

Integration Commit: fe370ad832bb62cd31a6d22909ce1a5bd1fe1311

Build source: 5d42600c29760a8082edf2a94754252772352846。03交付仅测试/证据，封存后集成HEAD与包内两个生产文件逐字节SHA一致，无需覆盖或重打包。

Build: E:/godot/beta-sprint-builds/beta_pfall_forward_drop_20261010_01

ZIP SHA-256: 01c23e309f4469c0985fa9884e866f84180b15a7c4db819aef281aa66c3766d9

Kind: SOURCE_PLAYABLE_REQUIRES_GODOT；需要外部Godot4.7.2，实际play.ps1已提供。1022个manifest文件和1025个ZIP成员逐字节校验通过。08专用qa-profile尚未创建，自动检查使用00独立profile。

旧QA包、日志、存档和批准美术共16999项保留检查PASS。新确认P0/P1=0；既有backlog保持。正式integration/foundation-4-authoring仍为99f2f1db9d9646d8fc7f3856fc4e64df81ff6cff，按每日Integration窗口政策待下一窗口接纳，不替换旧正式ref。

QA Handoff: READY_TO_08；专项试玩待执行。

Working Tree: CLEAN（closeout提交后核验）

Push: NOT_RUN
