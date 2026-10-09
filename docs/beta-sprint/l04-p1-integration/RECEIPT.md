# L04_P1_INTEGRATED_READY / QA_HANDOFF_READY

2026-10-09 · 00 Integration Coordinator · L04_INNER_MOVEMENT_P1_INTEGRATION

L-04 P1 内容修复已接入当前正式五关 Beta 分支，限定验收通过，独立新包已生成。**P1 保持 OPEN_PENDING_08_RECHECK**；**L-05 保持 READY_FOR_FIRST_HUMAN_QA**。没有将自动化结果升级为人类 QA 或整款 Beta 验收。

| 身份 | 实际值 |
| --- | --- |
| L04 Owner fix | 2a2fd7ad06b5c139b51b77c8dae1a9289b0530e8 |
| Delivery commit | a80a28b4edafda1faa5be4e890e0b61447afc716 |
| Normal merge | f059d7c17ad016a88cfac96a6f62715f44d13574 |
| 原集成基线 | ed180958dd9eb4b0d2c560074066eb92a5f9d139 |
| 冻结 Build 源 | 4267365d5d794a82dff4acc731073eb532ee40a1 |
| 分支 | integration/foundation-4-authoring |

正式收据提交是包含本文件的 Git 提交；最终00交付消息给出真实40位最终 Integration HEAD。该最终发布只增加文档与证据，不改变冻结 Build 源的生产行为。正常 merge 保留06完整 Git 历史，无冲突；没有 reset、rebase、squash 或 push。

唯一生产差异为 `game/levels/mutsumi/batch_02/l04_borrowed_path.tres` 的 Inner 落脚格新增 `(0,5)`，将正式 Spawn `(1,5)` 连到原岸 `(0,4)`。其实际 SHA256 为 **10f7a6a69a5e42c3796a6d0546938c7378be10f705fff3e40baf27db24efa18a**。其它关卡、Runtime、Foundation、美术、Presenter、Shell 与存档语义均不变。

## 聚焦验收

00 测试继承06已交付的自然输入 fixture，不复制解谜或移动算法。

| Case | 检查 | 实际结果 |
| --- | --- | --- |
| 00 Headless | **247** | PID17528，3路线/3正式Goal，exit0、stderr0、failures=[] |
| 00 Graphical | **267** | PID20036，Windows/D3D12，3路线/3正式Goal，20原始截图，exit0、stderr0、failures=[] |
| 新复制包 catalog | **68** | PID28232，正式五关 scene/resource 目录检查，exit0、stderr0、failures=[] |

两次最终自然测试绑定源 **0f1bea9d633f6446fd3ef93551bb637f39045197**，641份绑定监测文件 SHA 稳定。正常、Reset replay 和 alternate camera 路线都先从 Surface Spawn 切到 Inner，按住经过0.05秒timer等待及fixture帧等待的短按产生真实原生翻滚，落定 `(0,5)`，继续原连接谜题到 Surface Goal。每条路线只触发一次正式完成事件。动作中的 Reset、Goal后的 Reset、四视角、方块朝向以及既有不合法支撑/世界拒绝也由原fixture验证。

隔离测试存档只显式设定之前 L-01～L-03 的完成资格及 L-04 已可进入；**初始没有 L-05 解锁，也没有 L-04 完成**。真实 L-04 Goal 回调才保存完成并解锁 L-05。随后使用原生鼠标事件，从正式 Level Select 实际进入 L-05，确认正式 Spawn/world/view/idle；没有手改存档冒充 L-05 解锁或完成。新08包本身没有这些测试资格或预置存档。

UI/Save regression：**FOCUSED_PASS**。实际测试了 Esc Pause、鼠标 Resume、Settings Cancel、Esc Resume、选关与 Main、同进程 Continue；实际完成存档校验有效，解锁/最近关卡/设置保留。同进程 Continue 到 L-05 正式起点通过；**Cold Continue 本 Hotfix 未运行**，没有借用旧包的 Cold Continue PASS。

原始证据见 [Focused verification](FOCUSED_VERIFICATION.json) 与 [Graphical report](evidence/l04_p1_graphical_01/report.json)。截图包含短按后的新 Inner 落点、正式 Goal、L-05 原生进入和 Continue。

06 原交付 84 文件 SHA/长度验证一致：Headless201/PID13392、Graphical219/PID30536/18图均PASS；旧三关259/PID19592限定输入回归PASS。原进程真实 HEAD991140 与实际预提交消费 SHA 保留，没有将原日志身份改写成2a2fd7a。旧三关259项的133字节 ObjectDB退出警告仍保留，不冒充 stderr0 或旧三关完整通关重测。

00 首次 wrapper 把 stdout 中 `failures=[]` 误匹配为失败。实际247项/exit0/stderr0记录和原runner封存在 `evidence/l04_p1_headless_01`；仅修正00测试运行器的 FAIL词边界后，以新case重跑通过。生产修改没有因此扩大。

## 新08 QA包

**E:/godot/beta-sprint-builds/beta_l04_p1_20261009_01**

版本身份：`beta_l04_p1_20261009_01 / 4267365d5d794a82dff4acc731073eb532ee40a1`。

- [启动脚本](E:/godot/beta-sprint-builds/beta_l04_p1_20261009_01/play.ps1)，[包说明](E:/godot/beta-sprint-builds/beta_l04_p1_20261009_01/README.md)。PowerShell执行 `& 'E:/godot/beta-sprint-builds/beta_l04_p1_20261009_01/play.ps1'`；需要 Godot4.7.2，可用 `-Godot` 指定安装路径。
- **SOURCE_PLAYABLE_NOT_EXE**；含L-01～L-03当前3D、L-04固定灰盒、L-05原灰盒与当前Shell/Save/Continue，五关正式菜单注册。
- 独立存档：`user://beta_sprint/beta_l04_p1_20261009_01/qa_progress.json`。主文件与备份在交付前均未创建。
- [ZIP](E:/godot/beta-sprint-builds/beta_l04_p1_20261009_01.zip)：**60,643,786字节**；SHA256 **0e45be5e2fe21767bc0e72ddf0017d7013a93a6b25c3fb2eec2bcafb6a14c3b9**。
- 1270份复制源逐文件 SHA 一致，另有5份import生成的测试UID；物理project为1275文件，ZIP1279文件条目与物理包一致，无预置存档。
- 9个实际构建检查均exit0、无超时；8个stderr为空。本次唯一非空stderr为 **content_mutsumi_l04_boot** 的已知133字节 ObjectDB强制退出警告，SHA **bf8149e7a4c220bbef9c5eac13cd97f17ae895e5fff5a7befa152e30319f4d9d**。状态保留 **PASS_WITH_KNOWN_BASELINE_P2**；自然输入通关case stderr为空。
- 构建/日志/原始归档身份见 [Build seal](evidence/new_build/SEAL.json)。base archive原件与最终QA archive身份分开保留，未覆盖任何旧QA包。

## 保护与08交接

独立只读 Reviewer `/root/l04_p1_review`：Critical0、Important0、未解决Minor0；已修复runner及收据措辞Minor2。新通关、真实解锁、图形/源SHA、最终ZIP与构建stage均核验通过。

[Protection verification](PROTECTION_VERIFICATION.json) 确认636份其它生产源文件、旧QA3073项、两个保护根目录成员及4个原本缺席的存档仍精确一致。旧 `beta_content_batch_02_20261009_01`、人类QA执行副本、截图、日志与存档均保留。

Foundation changes：**NONE**；Art changes：**NONE**；Runtime changes：**NONE**；其它关卡 changes：**NONE**；Save semantic changes：**NONE**。Foundation full、D5/D6 backlog 与 stair既有状态不升级。

08接收上述具体包、Source/ZIP身份与限定证据，复检出生Shift后的A短按、完整路线/Reset和真实L04→L05解锁，并对L-05开始首次人类QA。旧包与证据只读；不能手改存档制造解锁。**P1=OPEN_PENDING_08_RECHECK，L05=READY_FOR_FIRST_HUMAN_QA，Human QA=NOT_RUN**。

实际交付文件SHA见 [FILES_SHA256.json](FILES_SHA256.json)。最终提交后必须确认 Integration `git status --short` 为空，00最终交付给出真实CLEAN结果；Push：**NOT_RUN**。
