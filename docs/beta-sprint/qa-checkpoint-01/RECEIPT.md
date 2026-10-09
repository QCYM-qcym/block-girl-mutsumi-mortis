# BETA_3D_UI_QA_CHECKPOINT_ACCEPTED

2026-10-09 · Mutsumi Veilshift · 00 Integration Coordinator · BETA_3D_UI_QA_01_CLOSEOUT

UI-08-001：**CLOSED**。BLACK_BOX_3D_UI_QA_01：**COMPLETE（本轮授权补测范围）**。实际独立鼠标/键盘复测确认 L-02 暂停文字可读、可点击，Esc / Resume 保持位置和视角。

| 项目 | 正式登记 |
| --- | --- |
| UI Matrix | 3/3 PASS，保留既有非阻塞 P2 |
| 1920×1080 | 实际 client / viewport / render 全为 1920×1080 |
| 1280×720 | 实际 client / viewport / render 全为 1280×720 |
| 960×720 | 实际 client / viewport / render 全为 960×720 |
| Navigation / Settings / Hint / Focus | PASS |
| L-01 3D Playthrough | PREVIOUS_PASS_PRESERVED |
| L-02 Unlock | PREVIOUS_PASS_PRESERVED |
| Cold Continue | PREVIOUS_PASS_PRESERVED |
| P0 / P1 | 0 / 0（此固定 Build 的授权 QA 范围） |
| P2 Backlog / New P2 | 1 / 0 |
| Production changes | NONE |
| UI Art Direction | APPROVED / FROZEN，未重新打开 |
| Next | BETA-3D-INTEGRATION-02 / ALLOWED_TO_CONTINUE |
| L-03_FIRST_TIME_COMPREHENSION | RETEST_PENDING |
| FOUNDATION_4_FULL | DEFERRED（当前 Beta Scope；原 DEFERRED_POST_BETA 决定保持） |
| 整款游戏 Beta QA | 未全部完成 |
| Working tree | CLEAN（封存 metadata 提交后核验） |
| Push | NOT_RUN |

## 固定 Build 身份

- Build：`E:/godot/beta-sprint-builds/visual_ui08001_20261009_01`
- Build source SHA：`ca6b331dc7c819c2a01e23c49827c0bd6a9c43a3`
- 原 Integration receipt SHA：`dc0bd64b53a9ee3c0c12d4bd7f25ab1ab92df916`
- UI fix SHA：`81d9470c174bd67a73e7e8fedf4b92240ddfc2fd`
- ZIP：`E:/godot/beta-sprint-builds/visual_ui08001_20261009_01.zip`
- ZIP SHA256：`40afc81b0c5d5574b1bd688d6048ece4c1537da94905af30e32eca92b5456cb1`；59,716,624 bytes。
- QA 原证据：`E:/godot/beta-sprint-builds/ui_08_001_recheck_20261009_01`

本次只登记 QA 结果，未生成、替换或重新运行此包。1148 个包内项目文件与原 manifest SHA 全部匹配，140 个原 QA 目录文件（含 profile）冻结；50 张截图与完整实际尺寸历史、交互记录逐字节封存。当前00提交只改变仓库文档，以上 Build source、原 receipt 和 ZIP 身份保持。

## 实际证据

08 原报告：[UI_08_001_RECHECK_COMPLETE](E:/godot/beta-sprint-builds/ui_08_001_recheck_20261009_01/UI_08_001_RECHECK_COMPLETE.md)。独立操作进程 PID48204，Godot4.7.2 / Forward+；原实际测量记录及截图关联见 [interaction_log.jsonl](E:/godot/worktrees/block-girl-foundation-4-integration/docs/beta-sprint/qa-checkpoint-01/evidence/interaction_log.jsonl) 和 [完整 geometry_history.jsonl](E:/godot/worktrees/block-girl-foundation-4-integration/docs/beta-sprint/qa-checkpoint-01/evidence/geometry_history.jsonl)。

00只读复核原60个sealed文件全部 SHA/bytes 匹配，50条截图交互的实际 client、viewport、render 均匹配各自目标。完整 resize history 包含正常过渡样本；验收依据是截图当时的实测几何，不用截图像素或配置值替代 viewport。50张截图及实际证据在 [封存目录](E:/godot/worktrees/block-girl-foundation-4-integration/docs/beta-sprint/qa-checkpoint-01/evidence/screenshots)。

[Checkpoint JSON](E:/godot/worktrees/block-girl-foundation-4-integration/docs/beta-sprint/qa-checkpoint-01/CHECKPOINT.json) · [证据与 Build SHA 审计](E:/godot/worktrees/block-girl-foundation-4-integration/docs/beta-sprint/qa-checkpoint-01/EVIDENCE_AUDIT.json) · [当前正式 QA 登记](E:/godot/worktrees/block-girl-foundation-4-integration/docs/beta-sprint/QA_CHECKPOINTS.json)。旧 OPEN / NOT_RUN 文档作为原始交付时快照保留；本 closeout 正式关闭 UI-08-001。

## 剩余 P2 与继续开发

唯一剩余 UI P2：**VIS01-P2-001 / UI-08-K01**，Owner：07 Game Shell。Pause 板底辅助文字贴底，960×720 与底部操作说明重叠；主要按钮仍可操作。归并为一个既有问题，新增0，不重复计数，不重开批准的 UI Art Direction，登记到 [POST_INTEGRATION_POLISH_BACKLOG](E:/godot/worktrees/block-girl-foundation-4-integration/docs/beta-sprint/visual-integration-01/POST_INTEGRATION_POLISH_BACKLOG.md)。

BETA-3D-INTEGRATION-02 继续。现有独立分支候选 `b910167becee2194c0cfc724d8f0fe47578836a9` 已交付；其新包 `beta_3d02_20261009_01` 和后续 QA 保持单独身份。本 checkpoint 不把旧 UI 三尺寸通过注册成新 L-02/L-03 3D 玩家验收，L-03 首次理解仍 RETEST_PENDING。

本次00复核没有启动引擎，没有重跑通关、解锁、Cold Continue，也没有修改 Save / Foundation / Gameplay / 关卡几何 / 谜题 / Art。全仓3111个非文档已跟踪文件及主工程77个冻结UI源的SHA保持。COMPLETE仅表示本轮授权补测覆盖完成；Level Complete 三尺寸、Reset 激活、L-03完整试玩等08未测范围仍保留原状态，整款游戏 Beta QA 未全部完成。
