# BETA_3D_INTEGRATION_02_READY

2026-10-09 · Mutsumi Veilshift · Beta Sprint · Main Project 3D Integration

L-02《两岸之间》：**3D_FORMAL_PLAYABLE**。L-03《视线相接》：**3D_FORMAL_PLAYABLE**。已完成独立 feature 候选；交给 00 正常 merge，再由 08 对本次新 Build 做独立 QA。

- Branch：`feat/beta-3d-integration-02`
- Worktree：`E:/godot/worktrees/block-girl-beta-3d-integration-02`
- Runtime / Build source commit：`7a95b28b155f5d32c4b559bdf90e0ea9beaad4ac`
- L-02 先行交付 commit：`0abb91610d28d967b1e9883318e9b5fa4b6de972`
- 起始正式 Integration HEAD：`dc0bd64b53a9ee3c0c12d4bd7f25ab1ab92df916`，本轮未改动。
- Main HEAD：`13177bb713c229fd5691c1e53cf5ba4d45f2ff76`，本轮未改动。
- Final receipt commit：由该分支的 `git rev-parse HEAD` 返回；相对 Build source 只增加本轮文档和封存证据。
- Contract mismatch：**NONE**。

## 实际交付状态

| 项目 | 状态 | 证据范围 |
| --- | --- | --- |
| L-02 | 3D_FORMAL_PLAYABLE | 正常、Reset 后、不同视角顺序各完整 3D 通关一次 |
| L-03 | 3D_FORMAL_PLAYABLE | 三次完整 3D 通关；连接前、转视角、连接成立、跨越、失效、Reset、Goal |
| L-01 regression | PASS | 原 3D 路线、plate/gate、Goal；原 Presenter 兼容扩展回归 |
| Surface / Inner | PASS | 原 authored 支撑格和平台 ID；切换中及完成后的真实视图 |
| 3D Cube Roll | PASS | 四方向实际滚动、early/mid/late 共 12 个自然过程样本 |
| Six-face orientation | PASS | 原 L-01 Runtime 路线实际覆盖六面；L-02 仅可达四面，L-03 原直线路线一面，不伪造关卡可达状态 |
| 4×90 Camera | PASS | 每关两个世界各正反向四个 90° 视角，共 16 个实测样本 |
| World Shift | PASS | 原 Runtime commit；位置/物理朝向保持；既有重建 VFX；Reset 消除旧过渡 |
| Perspective Connection | PASS | Surface EAST 真正成立；3→9 原连接滚动跨越；Inner EAST 和未连接方向拒绝跨越 |
| Reset | PASS | R 重置；roll/view/shift 中重置；旧过渡不得晚提交；Goal 后通过原 Shell Reset |
| Goal / Level Complete | PASS | 原 Runtime Goal；每次只一次 Shell 完成事件；原 SaveStore 写入隔离存档 |
| Game Shell | PASS | 原 Main/Level Select 加载稳定 level_id、Pause/Resume、HUD 世界与完成页；未新增完整 UI 矩阵或 Cold Continue 测试 |
| StateKey parity | PASS / MATCH | 同输入、每次 commit 与 settled view 的 Native/P01 Gameplay observation SHA256；cell/world/orientation/mechanism/link/Goal 一致 |
| Art source modifications | NONE | 18 个批准资产 / 121 绑定文件行；全部 SHA 保持 |
| Foundation modifications | NONE | Kernel、RuntimeSession、规则、Solver/Baker/Validator、D_JOBS/A_EDIT 等冻结范围 SHA 保持 |
| QA baseline | UNCHANGED | 旧 08 Build、ZIP、1148 个项目文件、140 个 QA 证据/存档文件保持 |
| Human QA for new Build | NOT_RUN | 08 下一轮独立 QA；自动化和 Owner 结果不替代 Human QA |
| Working tree | CLEAN at sealed delivery | 最终提交后使用 verify_delivery.ps1 -RequireClean 核验 |
| Push | NOT_RUN | 仅本地分支及新 Build |
| STAIR_CLEARANCE | PARTIAL_PASS | 保留批准资产原状态 |
| STAIR_TRAVERSAL | NOT_RUN | 无新实测，不升级 |

本项目现有已验收 L-01 主项目玩法使用 ContentLevel / ContentState / GridMovement / PerspectiveController（P01）链。以上 StateKey parity 是该真实链的逐动作观察 SHA256，未声称 Foundation `statekey.v1` 或 RuntimeSession 迁移验收。既有 `.tres` 和 catalog 的 GREYBOX quality 是原 06 content 声明，字节保持；本回执登记的是新 presentation 的正式可玩状态。

## 正式验证

| Case | Entry | Graphical | 实际进程 | 结果 |
| --- | --- | --- | --- | --- |
| l02_final | 9 | 483 | 21260 / 32256 | PASS |
| l03_g01 | 9 | 1349 | 36536 / 33684 | PASS |
| l01_g01 | 9 | 279 | 29008 / 26816 | PASS |

总计 **2138 checks / 0 failures**。六个阶段全部 exit 0、stderr empty、stdout clean；实际图形进程为 Windows / Forward+，Godot 4.7.2。L-02 与 L-03 各 3 组原 Pixel / 新 3D 相同动作序列 MATCH，分别 6 个原生完成事件；L-01 1 组 MATCH、2 个完成事件。所有实际图形场景消费真实 Runtime，无 double。

L-02 必须先 GREEN 的顺序已满足：`l02_g02` 9+445 PASS 后提交 Task1，随后才接入 L-03。最终 `l02_final` 验证全部当前公共 presentation/test 代码。失败过的 RED、首次图形 harness、初次 SVG 导入证据保留，未覆盖或补写 PASS。[执行记录](E:/godot/worktrees/block-girl-beta-3d-integration-02/docs/beta-sprint/three-d-integration-02/PROGRESS.md) 说明具体原因。

[完整 case 汇总](E:/godot/worktrees/block-girl-beta-3d-integration-02/docs/beta-sprint/three-d-integration-02/FORMAL_CASE_SUMMARY.json) · [实际逐动作及源码哈希报告](E:/godot/worktrees/block-girl-beta-3d-integration-02/docs/beta-sprint/three-d-integration-02/evidence) · [14 张关键截图索引](E:/godot/worktrees/block-girl-beta-3d-integration-02/docs/beta-sprint/three-d-integration-02/SCREENSHOT_INDEX.json) · [独立审查：0 Critical / 0 Important / 0 Minor](E:/godot/worktrees/block-girl-beta-3d-integration-02/docs/beta-sprint/three-d-integration-02/FINAL_REVIEW.md)。

## 新 QA Build

[新 Build 启动器](E:/godot/beta-sprint-builds/beta_3d02_20261009_01/play.ps1) · [项目](E:/godot/beta-sprint-builds/beta_3d02_20261009_01/project/project.godot) · [独立新 ZIP](E:/godot/beta-sprint-builds/beta_3d02_20261009_01.zip)

- Build：`E:/godot/beta-sprint-builds/beta_3d02_20261009_01`
- Package：SOURCE_PLAYABLE_NOT_EXE，使用现有 Godot 4.7.2；本次未生成 Windows executable。
- Source SHA：`7a95b28b155f5d32c4b559bdf90e0ea9beaad4ac`
- ZIP SHA256：`697070886818f1e437e9fd20444fe98684a60582eeb2b30bcea98bf8ab64c999`
- 新 launcher 默认存档：`user://beta_sprint/beta_3d02_20261009_01/qa_progress.json`。
- QA_BUILD_VERIFICATION：**PASS**，1173 个复制文件全部精确匹配候选，全部非 doc payload 与当前交付相同。
- Copied-project import、main_scene_boot、foundation_boot、L01/L02/L03 boot：全部 PASS、exit0、stderr empty。未使用导入 P2 例外；manifest 原始阶段记录保留。
- 不覆盖旧 `visual_ui08001_20261009_01`、旧08 QA profile 或报告。新 QA 要使用独立 profile 和新截图/日志目录。

## 集成边界

只改四个既有文件：L-01 attachment 默认 presenter factory、L-01 occlusion 缺机关两行 guard、L-02/L-03 scene 的 Script 引用。新增 `levels_3d` subclass 仅布置正式资产与观察真实状态；roll/camera/shift/occlusion/Reset 沿用原 Presenter 算法。

Main Scene、project.godot、Game Shell/Save/Load、原 Pixel Runtime、正式连接/世界切换规则、谜题资源/解法、06 提示、冻结 Art 均未修改。830 个保护文件精确匹配初始正式 SHA，未因表现模型改规则。

L-03 stale hint 仍为 Owner06 已知 P2，未收到新交付，不与06编辑同一资源。其他既有 P2/P3 和楼梯状态在 [Backlog](E:/godot/worktrees/block-girl-beta-3d-integration-02/docs/beta-sprint/three-d-integration-02/BACKLOG.md) 保留。

[Files / SHA256](E:/godot/worktrees/block-girl-beta-3d-integration-02/docs/beta-sprint/three-d-integration-02/FILES_SHA256.json) · [保护范围和旧08完整核验](E:/godot/worktrees/block-girl-beta-3d-integration-02/docs/beta-sprint/three-d-integration-02/DELIVERY_VERIFICATION.json) · [00 / 08 交接](E:/godot/worktrees/block-girl-beta-3d-integration-02/docs/beta-sprint/three-d-integration-02/HANDOFF_00_08.md)。
