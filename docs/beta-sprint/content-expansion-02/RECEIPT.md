# BETA_CONTENT_BATCH_02_READY

2026-10-09 · 00 Integration Coordinator · Beta Sprint Phase2 Content Expansion

第二批内容与 Game Shell 接入已经完成。L-04《借来的道路》、L-05《归途的门》均可灰盒完整通关；五关通过正式 Main Menu / Level Select 进入，并沿用既有完成、解锁和存档流程。现有前三关通过限定 3D 回归。

本轮在一个协调的 Integration 窗口内正常 merge。集成分支为 `integration/foundation-4-authoring`，工作区为 `E:/godot/worktrees/block-girl-foundation-4-integration`。最终收据身份是包含本文件的 Git 提交；00 最终交付消息记录实际 40 位 SHA。构建冻结源为 **991140292ac67e87d1751a062e7e96c7b9fee553**，后续收据提交只修改文档与证据。

## 关卡结果

| 关卡 | 状态 | 实际验证 |
| --- | --- | --- |
| L-01 / mutsumi_l01 | 3D LIMITED REGRESSION PASS | 66 项限定检查；此前完整通关批准保留 |
| L-02 / mutsumi_l02 | 3D LIMITED REGRESSION PASS | 82 项限定检查；此前三次完整 3D 通关批准保留 |
| L-03 / mutsumi_l03 | 3D REGRESSION PASS | 491 项检查，连接、跨越、失效、Inner EAST 阻挡、Goal、Reset |
| L-04 / mutsumi_l04 | GREYBOX_PLAYABLE | 正常、Reset 后、不同视角顺序三条完整自然输入路线；每次 11 步 |
| L-05 / mutsumi_l05 | DESIGN_COMPLETE / GREYBOX_PLAYABLE | 三条完整自然输入路线；每次 13 步；复用既有四视角、双世界、连接和压板/门 |

前三关另有 3 项准备检查，共 **642 项 PASS**。限定回归覆盖正式鼠标菜单入口、四视角、方块与世界呈现、Reset、Pause/Resume 和返回菜单。没有重新运行 L-01/L-02 的完整通关验收。

06 的新关卡消费既有 Content/P01 Runtime；没有引入新玩法规则、算法或通过 Mesh 坐标决定状态。这里的原生状态观察没有冒充 Foundation RuntimeSession / `statekey.v1` 验收。

## 实际证据

各次独立 case 的数量分别列出，不能相加当作一个新的全游戏 QA 套件。

| Case | 检查 | 结果与范围 |
| --- | --- | --- |
| 06 Unit | 45 | PASS；[Owner receipt](../content-batch-02/RECEIPT.json) |
| 06 Real | 206 | PASS；6 条自然路线、6 次原生完成事件；实际消费字节 SHA 绑定，不伪装预提交进程身份 |
| 00 新关卡 Graphical | 206 | Windows 原生渲染；PID 40620；6 条路线、6 次正式完成、23 张截图；[report](evidence/new_levels_graphical/report.json) |
| 00 当前前三关限定 3D | 642 | PID 45212；[report](evidence/old_three_focused_pass/report.json) |
| 07 正式目录、菜单、解锁与存档 | 319 | 68 + 33 + 94 + 102 + 11 + 11；[Owner receipt](../shell-batch-02/RECEIPT.json) |
| 00 集成后正式五关目录 | 68 | PASS；[run report](evidence/five_level_catalog/run_report.json) |
| 新复制构建内正式目录 | 68 | PASS；PID 20248；原始日志保留于 [build seal](evidence/daily_build/SEAL.json) |

上述 Gameplay 验证均为 exit 0、failures=[]、stderr 为空；Real/Graphical 没有替身。新关卡 Graphical 使用 Owner 的单关 Shell 目录 fixture，不能据此宣称五关正常解锁或人类 QA。正式五关接入另由 07 的真实 Runtime 完成、解锁、菜单和分进程 Continue 证据支持：PID 7488 完成 L-03→L-04→L-05，PID 48092 恢复 L-05 正式起点，PID 5548 验证旧 08 存档的隔离字节副本。

07 只追加真实可玩的两关目录，并在选关条目超过三项时增加滚动容器；原三项目录、存档 schema 和 SaveStore 源码不变。容量测试 fixture 与六组新关卡 headless 实测尺寸明示保留，不能代替人类矩阵测试。

原始失败历史没有删除：额外旧 L-02 graphical 超时尚无确定原因，不计 PASS；07 早期 96 项尺寸结果只作历史记录，正式尺寸证据是最终 102 项 case；00 初次限定回归存档 fixture 漏设 `recent`，被正式 Save 校验拒绝，仅修正测试后 642 项通过。没有据此修改生产 Runtime。

## 固定 3D02 QA 登记

结果绑定旧包 `E:/godot/beta-sprint-builds/beta_3d02_20261009_01`，ZIP SHA256 为 `697070886818f1e437e9fd20444fe98684a60582eeb2b30bcea98bf8ab64c999`。没有把旧 UI Build 的历史结果冒充本轮结果，也没有转移到新 Daily Build。

- Latest 3D02 UI Matrix：**3/3 PASS_WITH_NONBLOCKING_P2**，实际 viewport 为 1920×1080、1280×720、960×720。
- Latest 3D02 Cold Continue：**PASS**，PID 40064 正常退出后新 PID 34448 启动，Continue 恢复最近关卡正式起点。
- L-03 First-time Comprehension：**RETEST_PENDING**，没有满足条件的新测试者。
- UI-08-001：**CLOSED**；旧 UI Matrix 3/3 和以前的通关批准继续保留。
- 本轮固定包有 65 张新截图、尺寸记录、输入记录与独立进程证据，见 [QA registration](QA_STATUS.json)。

P0 **0**，P1 **0**，P2 **3**（保留 2 + 新发现 1）。暂停板辅助文字重叠、L-03 过期提示，以及选关仍称 L-02/L-03 为灰盒的文案进入 [Backlog](BACKLOG.json)，本轮没有重开美术方向或修改旧提示。

## 新 Daily Build

**E:/godot/beta-sprint-builds/beta_content_batch_02_20261009_01**

- [启动脚本](E:/godot/beta-sprint-builds/beta_content_batch_02_20261009_01/play.ps1) / [说明](E:/godot/beta-sprint-builds/beta_content_batch_02_20261009_01/README.md)
- [ZIP](E:/godot/beta-sprint-builds/beta_content_batch_02_20261009_01.zip)：60,405,480 字节。
- ZIP SHA256：`dc7b92903f8b87d2b074531e680cc8bb9049ef123ef2ae9c697efd4ee59e7b5a`。
- **SOURCE_PLAYABLE_NOT_EXE**，需要 Godot **4.7.2**；没有冒充独立导出 EXE。
- 独立存档：`user://beta_sprint/beta_content_batch_02_20261009_01/qa_progress.json`。
- 1241 份复制源文件 SHA 与构建源一致，另有 3 份 import 自动生成的测试 UID；ZIP 1248 条文件内容与物理包一致。
- 9 个复制包检查：import、catalog、Main、既有 Foundation 场景启动、五关启动，均有实际进程、exit 0、无超时。Foundation 仅为启动检查，未升级其完整验收状态。
- 8 个阶段 stderr 为空；L-02 的 standalone `--quit-after` 启动阶段保留 133 字节既有 ObjectDB 退出警告，精确 SHA `bf8149e7a4c220bbef9c5eac13cd97f17ae895e5fff5a7befa152e30319f4d9d`。构建状态为 **PASS_WITH_KNOWN_BASELINE_P2**，没有宣称全部 stderr 为空。
- 新 Daily Build 人类 QA：**NOT_RUN**。08 下一轮应针对该具体包验收，旧固定 3D02 矩阵与 Cold Continue 只属于旧包。

## 边界和封存

[Integration verification](INTEGRATION_VERIFICATION.json) 核验 537 份冻结文件、324 份旧 QA 对象、1173 份固定 3D02 payload、180 份新 08 证据、64 份 06 交付及 80 份 07 交付，全部原字节不变。[Build review](BUILD_REVIEW.json) 同时核验旧 UI Build 的 1148 份 payload 与历史 ZIP。之前的 Build、截图、日志、测试存档与报告均保留。

Foundation changes：**NONE**；Art source modifications：**NONE**；Save schema changes：**NONE**；旧三关谜题规则/内容：**NONE**。Owner 独立工作区的原始交付保留。实际 Main Git 根目录 `E:/godot/若叶睦/方块少女-若叶睦` 仍为 `13177bb713c229fd5691c1e53cf5ba4d45f2ff76`，77 份既有未跟踪文件未清理。

`FOUNDATION_4_FULL=DEFERRED`；D5/D6=`POST_FREEZE_BACKLOG`；`STAIR_CLEARANCE=PARTIAL_PASS`；`STAIR_TRAVERSAL=NOT_RUN`。没有宣称整款游戏 Beta QA 完成。

实际文件与 SHA 见 [FILES_SHA256.json](FILES_SHA256.json)。最终交付必须在提交本收据后核验 Integration `git status --short` 为空；最终 00 回执提供真实结果。Push：**NOT_RUN**。
