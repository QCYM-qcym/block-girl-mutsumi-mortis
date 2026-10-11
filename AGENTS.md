# Mutsumi Veilshift — 项目约定

适用于本分支及正式接收本规范的分支。用户当前任务中的明确限制优先；本文件不扩大 Owner 的生产文件权限。

## Owner 与合同

- 开工先核验实际仓库、Worktree、Owner Branch、HEAD 和工作区；聊天标题不是 Git 身份。
- 按当前任务批准的文件清单工作，保留其他 Owner 的修改、未跟踪资源和证据。跨 Owner 文件先交给 00 协调。
- Godot、Runtime、测试和资源的既有合同、版本、文件边界及已批准 QA 证据继续有效；本规范只改变阶段交付流程。
- 公共合同、Presenter/Host 接线、project.godot、InputMap/Autoload 和共享 Harness 由 00 协调；Owner Local PASS 只覆盖实际运行的范围。
- 建立或核验 Owner 分配时，阅读 [Owner Branch Policy](docs/development/OWNER_BRANCH_POLICY.md)，并核实目标分支上的最新任务矩阵。

## GitHub Stage Delivery Policy

每个已授权开发任务使用明确的 Owner Branch。阶段交付默认依次完成以下十步：

1. 核验所属 Worktree、当前分支、基线 SHA 和 origin。
2. 确认本阶段修改范围及与其他 Owner 的边界。
3. 完成本阶段代码或文档，保留范围外工作。
4. 执行适用验证，分别记录 PASS、FAIL、PENDING、NOT_RUN 和 Human QA。
5. 检查实际差异中的敏感文件、大文件和资源许可；只选择可交付文件。
6. 创建对应阶段成果的可追溯 Commit，保留作者和历史。
7. 普通、非强制 Push 所属开发分支；这是已授权开发任务的默认交付步骤，无需重复询问同一授权。
8. 查询远端对应分支的完整 SHA。
9. 确认远端 SHA 与本地交付 HEAD 一致。
10. 按 [Stage Delivery Template](docs/development/STAGE_DELIVERY_TEMPLATE.md) 输出 Integration Handoff 给 00。

执行交付或处理 Git 故障前，阅读 [Git Workflow](docs/development/GIT_WORKFLOW.md)。如当前任务明确禁止 Push，遵守该限制并据实报告 `NOT_RUN`，不得声明 GitHub 已交付。

- 未成功 Push 并核验 SHA，不能报告 `GitHub Delivery Complete`；失败报告 `GITHUB_DELIVERY_BLOCKED`、原因和恢复步骤。
- 可独立验证的部分成果可 Push 开发分支，保留 `PARTIAL` / `PENDING`。未完成成果可保留 WIP Commit，但不能标记阶段 `COMPLETE`。
- 本地 CLEAN、Desktop 中可见 Commit、Owner Local PASS 均不等于远端同步或 Integration PASS。
- 不直接 Push main，不 Force Push，不重写公开共享历史，不未经批准创建、移动或删除 Release Tag。
- 所有 Integration Merge / Cherry-pick、冲突协调及集成验收由 00 统一处理；正式 Release Branch、Tag、Release Notes 和 GitHub Release 由 12 统一管理。
- 未通过适用 Human QA 的功能不得冒充正式发布验收完成；开发分支 Push 与正式公开发布分别报告。

## 规范传播

Worktree 使用各自分支的文件；本分支提交不会自动更新其他 Worktree。接收或传播本规范前，阅读 [Governance Rollout](docs/development/GOVERNANCE_ROLLOUT.md)。保留目标分支已有约定；Dirty Worktree 等待 Owner 整理，不自动 Checkout、Reset、覆盖或删除。
