# QA08 本轮文件边界

Task: SPATIAL_FORMAL_CHAPTER_01_HUMAN_QA_01

Owner: 08 QA & Build。当前用户明确授权新 QA 报告 / 工具的适用验证、Commit、Push 与远端 SHA 核验；不授权生产修改。

- Base SHA: 763f0132bc58360fab0e224d0e9c54e00c92ae90
- Worktree: E:/godot/worktrees/bg-formal-qa08-20261019
- Branch: test/spatial-formal-human-qa08-20261019
- Origin: https://github.com/QCYM-qcym/block-girl-mutsumi-mortis.git
- Handoff: 00 Integration Coordinator；未工具发送外部消息。

本轮只允许新增 docs/beta-sprint/spatial-formal-chapter-01/qa08-human-01/ 下四个文件：REPORT.md、BUILD_EVIDENCE.json、HUMAN_OBSERVATION_TEMPLATE.md、TASK_SCOPE.md。

生产代码、共享合同 / Harness、玩法、场景、美术、存档、project 配置、其他 Owner 工作树、原 Build 和旧证据保持不变。原始截图 / 日志 / profile 不上传。00 工作树只读。新分支从核验的正式集成 SHA 创建，创建前已确认本地与远端无同名分支、目标路径不存在。

适用验证：JSON 解析及状态检查、Build 清单与 Git 内容比对、限定路径差异、git diff --check、无敏感或大文件 / 二进制提交、Commit 路径审计、普通精确分支 Push、独立远端 SHA 对比。仅新增报告，不重跑 gameplay 自动化套件；文档检查不能替代 Human QA。

Stage: PARTIAL。Human QA: NOT_RUN。Integration: PENDING_00。Git 交付成功与游戏验收分开报告。
