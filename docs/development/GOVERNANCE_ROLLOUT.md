# Governance Rollout / 00 Integration Handoff

Task：`GITHUB_DEVELOPMENT_GOVERNANCE_01`。日期：2026-10-11（Asia/Shanghai）。

## 本次交付身份

- 文档分支：`docs/github-delivery-governance-20261011`。
- 独立 Worktree：`E:/godot/worktrees/block-girl-git-governance-12`。
- Base SHA：`8a77874cc18ceb654664c3e9aeb10a2ccd318048`，审计后的 `origin/main`。
- 目标文档 PR：`main`；只比较该远端基线到本规范分支的文档差异。
- 交付 Commit 是本分支中题为 `docs(git): establish GitHub stage delivery workflow` 的提交；Push 后报告其完整 SHA，并用 `git ls-remote` 独立核验。此文件不填入无法自引用的本提交 SHA，也不预先声称 Push SUCCESS。
- 本轮没有自动合并 main、Integration 或任何 Owner Branch，没有创建/移动 Release Tag。

源依据和分支/工作树清单见 [Owner Policy](OWNER_BRANCH_POLICY.md)、[审计报告](GOVERNANCE_AUDIT_REPORT.md) 和 [快照](OWNER_WORKTREE_SNAPSHOT.json)。

## 为什么从 origin/main 开始

本地 main 在 `13177bb713c229fd5691c1e53cf5ba4d45f2ff76`，比远端 main 领先 150 个提交，并有 README 修改和未跟踪文件。00 当前 Worktree 名为 foundation-4-integration，实际检出 `feat/game-feel-full-slice-01`，HEAD 是 `d1277ec90b5a739efd4862d314e6c29ac5ac1eda`；相对 origin/main 有 325 个提交。发布分支在 `25de1f6202c764e4003634a387ae05e38bd387c4`，相对 origin/main 有 326 个提交。

若从上述最新线建立面向 main 的文档 PR，会夹带生产与实验历史。本次从 origin/main 建立独立分支，使用固定提交链接引用较新合同；不复制生产树，也不假定 Integration 可直接合并 main。

## 00 正式接收

1. 获取规范分支并独立确认交付 SHA，审查相对已声明 Base SHA 的文件与提交。当前批次只有 AGENTS.md 与 `docs/development/*`。
2. 对目标 `main` PR 检查实时 merge-base、提交数和文件列表；远端 main 若已前进，重新审查差异和兼容性，不自动改写规范分支历史。本轮未自动创建/合并 main 上的新提交。
3. 在 00 自己的干净集成环境审阅当前合同和目标分支的 AGENTS.md；如已有约定，按段落合并保留 Godot、Runtime、测试和 Owner 文件边界。
4. 00 根据依赖和历史选择普通 Merge 或有记录的文档 Cherry-pick；只接收规范，不把本地 main WIP/Art 或其他实验分支并入。
5. 执行本批次文档检查、范围检查与合同兼容审查。文档接收本身不运行全部 Gameplay 矩阵，也不改变 QA 状态。
6. 创建可追溯 Integration Commit，Push 00 的实际集成分支并核验 SHA。规范 main PR 的最终合并由既有审阅流程决定，12 不自动合并。
7. 报告接收提交 SHA、主分支/集成线覆盖范围，以及每个 Owner 的接收批次。保留未完成的 QA 与相关历史报告。

如果 GitHub CLI 可用，12 创建面向 main 的文档专用 PR 并报告真实 URL；当前环境未找到 `gh`，不安装额外工具、不声称 PR 已创建。可使用 [预填文档 PR 的比较入口](https://github.com/QCYM-qcym/block-girl-mutsumi-mortis/compare/main...docs/github-delivery-governance-20261011?expand=1) 人工创建。00 应先核实实际差异后再提交 PR。

## 向其他 Owner 安全传播

规范进入 main 不会自动更新已有 Worktree。00 维护接收清单，Owner 在完成自身阶段并保存可追溯成果后，选择协调好的时间获取治理提交。

干净 Owner Worktree 的接收步骤：

1. 确认实际所属分支、HEAD、工作区、合同依赖和 00 指定的规范交付 SHA。
2. Fetch 治理/已接收集成引用；只读审查该提交路径。不要以整个较新的 Integration 为文档更新载体。
3. 由 00 统一处理或安排具有明确授权的文档 Merge / Cherry-pick；若 Owner 分支已接收对应集成提交，不重复应用。
4. AGENTS.md 同路径已存在时逐段合并，保留原约定；有冲突交给 00 与该 Owner 处理，不覆盖。
5. 复查生产路径无变化、内部链接有效、Owner allowlist 保留，然后 Commit、Push 接收分支并核验远端 SHA。
6. 在新的任务会话中确认根目录 AGENTS.md 已读取；旧会话若已加载旧约定，明确要求重新读取。磁盘文件变化不保证所有运行中的会话立即刷新。

Dirty Owner Worktree：保持工作和未跟踪资源原状，由 Owner 自行提交/保存本轮成果并约定接收窗口，或用新的专属 Worktree 在同一 Owner 基线上准备文档接收。不得自动 Stash、Checkout、Reset、覆盖 AGENTS.md 或删除 Worktree。仅 Fetch/阅读政策不等于正式接收。

05/08 的外部工作环境必须登记其真实仓库/任务交付方式；本仓库 AGENTS.md 不会自动传到外部目录。对现有 Release 分支不追补规范，不移动其 Tag；后续 Release 从已接受制度的候选基线按授权准备。

## 实际覆盖范围

本节是本规范分支创建时的审计状态；后续接收必须重新查实际分支文件、提交和远端状态。

`POLICY_ACTIVE_BRANCHES`：

- `docs/github-delivery-governance-20261011`：本批次交付 AGENTS.md 和完整治理文档；是否远端同步以最终交付报告的 SHA 核验为准。

`POLICY_PENDING_BRANCHES`：

- 审计前的全部 58 个本地分支，完整名称列在 [快照](OWNER_WORKTREE_SNAPSHOT.json) 的 `policy_pending_branches`。
- 其中 main、00 当前 `feat/game-feel-full-slice-01`、Editor `dev/godot-editor-playable` 以及所有 Owner 开发线均未由本任务接收。
- `release/beta-game-feel-20261010` 保留固定发布基线，状态为历史发布线未接收、无本轮追补计划。
- 审计前的 52 个 Worktree 均未由本任务写入规范；05/08 的外部环境另待实际注册，不算作已启用。

这里的 pending 是制度覆盖状态，不表示每条历史分支都需要追补。00 可以把不再开发的线登记为 `HISTORICAL_FROZEN`，但必须有明确接收记录，不能仅凭名称/聊天状态推断。

## 仍待处理的管理风险

- 远端 main 仍滞后于本地开发，00 需单独审查后续生产集成；本治理 PR 不解决该差距。
- 历史报告中的 `Push: NOT_RUN` 保留原事实，旧 Owner Commit 不由 12 批量上传。各 Owner 需要审计自己的待推送阶段。
- 当前 Owner/合同矩阵含历史分支名，例如 00 的历史 `integration/foundation-4-authoring` 与实际检出分支不同；不得按文件夹名操作。
- 05/005、09/009、001 等聊天命名有歧义，新增任务要登记 Git 身份；不凭标题迁移职责。
- root AGENTS.md 是执行约定，不是 GitHub Branch Protection、CI 强制门禁或自动 Push 服务。本轮未更改仓库权限、服务器保护或 Hooks。
- Human QA、Graphical TraceReplayer 剩余项、L06 和最终 Audio/UI/Art 收口维持原状。
