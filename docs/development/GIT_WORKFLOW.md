# Git Workflow

项目：Mutsumi Veilshift / 方块少女-若叶睦。Policy：`GITHUB_DEVELOPMENT_GOVERNANCE_01`，2026-10-11（Asia/Shanghai）。

核心规则见 [AGENTS.md](../../AGENTS.md)。阶段成果的默认终点是 **验证 → Commit → Push Owner Branch → 远端 SHA 核验 → Integration Handoff**。本制度适用于全部 Owner；当前用户任务的明确限制仍优先。

## A. 分支管理

| 前缀 | 内容 | 所有者 |
| --- | --- | --- |
| `feat/*` | 功能开发 | 对应功能 Owner：01/02/04/06/07/09/10A/10B/11；具体范围由任务矩阵登记 |
| `fix/*` | 缺陷修复 | 缺陷所属模块 Owner；跨模块由 00 协调 |
| `art/*` | 美术资源开发 | 05；资源接线与公共场景由 00 协调 |
| `design/*` | 设计、机制研究 | 13；地图设计可由 09 按任务登记 |
| `docs/*` | 文档 | 对应文档 Owner；仓库制度和 Release 管理由 12 |
| `test/*` | 测试、QA 工具 | 03 Quality / 08 QA；真实职责及写入范围分别登记 |
| `integration/*` | 集成、公共接线 | 00 |
| `release/*` | 版本准备 | 12 |

前缀不是授权；以 [Owner Branch Policy](OWNER_BRANCH_POLICY.md) 和当前任务的 Owner、Base SHA、文件清单为准。旧 `dev/*`、`prototype/*`、`debug/*` 和历史分支保留，不为统一命名改写历史或删除分支。现有 00 工作树可能检出 `feat/*`，也不能据名称转移其集成职责。

新任务先检查本地和远端同名分支、Worktree 路径以及合并目标；名称冲突时选择新名字并报告，不覆盖。分支从已核实的合同或集成基线创建，不把“最新”当兼容证明。文档 PR 优先使用合并目标的远端基线，避免携带无关实验提交。

## B. Worktree 管理

每个 Owner 使用独立工作树和明确分支。开工记录 `git status`、`git branch --show-current`、`git rev-parse HEAD`、`git worktree list` 和 `git remote -v`。Detached HEAD 先停止交付并登记实际状态。

多个 Owner 不得未经协调同时修改共享生产文件。公共合同、Presenter/Host、project.godot、InputMap/Autoload、共享 Harness 和正式接线由 00 协调。新增子任务也不能借文档制度扩大原生产 allowlist。

Dirty Worktree 先辨认本轮成果和他人 WIP，显式选择文件；不自动 `add -A`、Stash、Checkout、Reset、Clean 或覆盖未跟踪 Art。不得强制删除其他 Owner Worktree。清理本任务工作树也应在交付可恢复、已获清理授权后进行。

## C. Commit 规范

一个阶段成果对应明确 Commit，正文记录必要依赖、验证范围、待完成项和 Handoff。采用 Conventional Commits，例如：

```text
feat(runtime): deliver perspective fall permission checks
feat(gameplay): add owner-scoped level content
fix(game-shell): correct pause text
test(quality): record focused regression evidence
docs(game-design): document mechanism research
art(environment): deliver licensed environment assets
chore(release): record release verification
```

提交前查看实际暂存差异，使用明确路径 `git add -- <本轮文件>`。保留作者、时间、依赖与审计记录；无需为了减少 Commit 数量改写共享历史。WIP / PARTIAL 必须在正文或交付报告中明确，不能以标题暗示全项目完成。

## D. Push 规范

每个已授权阶段按 AGENTS.md 的十步流程交付：

1. 核验当前 Owner Branch、origin、Base SHA 及实际差异。
2. 检查公开范围、敏感数据、大小、资源许可和 LFS 状态。
3. 执行适用验证，记录命令、环境、证据和真实结果。
4. 显式暂存并 Commit 本轮成果，再核验提交路径和完整 SHA。
5. 查询远端同名分支。存在时核实其 SHA 是本地交付 HEAD 的祖先；无法证明就停止同步写入。
6. 对该分支执行普通 Push，禁止强制覆盖，禁止顺带推送 main 或 Release Tag。
7. 用 `git ls-remote --heads origin refs/heads/<Owner Branch>` 查询完整远端 SHA，与本地 `git rev-parse HEAD` 比较。
8. 填写 [阶段报告](STAGE_DELIVERY_TEMPLATE.md)，把确切提交、验证范围、风险及依赖交给 00。

Git CLI 示例只适用于已确认的 Owner 开发分支。下列 PowerShell 变量应由执行者填为实际分支，不含尖括号占位符：

```powershell
$deliveryBranch = git branch --show-current
if (-not $deliveryBranch -or $deliveryBranch -eq 'main' -or $deliveryBranch -like 'release/*') {
    throw 'Owner stage delivery requires a named non-main, non-release branch'
}
git remote -v
git rev-parse HEAD
git ls-remote --heads origin "refs/heads/$deliveryBranch"
# 完成祖先关系检查、范围审查和 Commit 后，普通推送唯一分支。
git -c push.followTags=false -c remote.origin.mirror=false push --no-follow-tags --set-upstream origin "refs/heads/${deliveryBranch}:refs/heads/${deliveryBranch}"
if ($LASTEXITCODE -ne 0) { throw 'GITHUB_DELIVERY_BLOCKED: push failed' }
$deliveryLocalSha = git rev-parse HEAD
$deliveryRemoteRow = git ls-remote --heads origin "refs/heads/$deliveryBranch"
if ($LASTEXITCODE -ne 0 -or -not $deliveryRemoteRow) { throw 'GITHUB_DELIVERY_BLOCKED: remote verification failed' }
$deliveryRemoteSha = ($deliveryRemoteRow -split '\s+')[0]
if ($deliveryLocalSha -ne $deliveryRemoteSha) { throw 'GITHUB_DELIVERY_BLOCKED: SHA mismatch' }
```

远端祖先检查：先只 Fetch 对应引用到远端跟踪引用，再运行 `git merge-base --is-ancestor <远端完整SHA> HEAD`；exit 0 才能按快进推送。远端不存在则首次 Publish。查询到 Fetch 之间、检查到 Push 之间都可能发生并发变化，普通 Push 被拒绝时重新审计，不升级为 Force Push。已知远端分歧不能通过删远端分支、重建分支或强制覆盖解决。

GitHub Desktop 与 CLI 都是合法客户端。Desktop 中确认正确仓库/Worktree 和 Current Branch，查看 Changes / History 并 Commit，然后首次 **Publish branch** 或后续 **Push origin**。禁止选择 main、自动 Pull 合并不明历史或顺带发布 Tag；若该版本 Desktop 无法排除待推送 Tag，改用精确 CLI 分支引用。最后仍用独立远端查询核验 SHA；看到 Commit 或显示 CLEAN 不能证明 Push SUCCESS。

阶段 Push 默认已随授权开发任务获准；遇当前明确禁推、凭据问题、远端分歧或不应公开内容，报告实际阻塞，不重复询问已获准的普通 Push，不绕过安全限制。

## E. Integration 规范

Owner 交付后向 00 提供报告。若当前任务明确授权通知指定的 00 聊天，可以发送确切 Handoff；否则保留可交接报告，不自行联系其他人或任务。

00 核实提交和依赖、审查文件所有权，选择正常 Merge 或有记录的 Cherry-pick，协调冲突，执行 Focused Regression，创建 Integration Commit，Push Integration Branch 并核验远端 SHA，随后交付 Build 与 QA。

Owner 不能自行合并共享 Integration；00 的操作也需满足其任务授权和文件边界。Local PASS、Integrated PASS、Graphical QA 和 Human QA 分开报告，并绑定实际 Source/Build SHA。历史证据不得覆盖或改标。本制度不授权自动合并 main。

## F. Release 规范

12 统一负责 Release Branch、Release Notes、明确提交上的 annotated Tag、GitHub Release 和版本核验。00 提供集成候选和 QA 证据，12 核实来源、适用 QA、已知问题、资产许可和发布状态。

Release Branch Push、Tag Push、GitHub Release 页面发布及附件上传是不同操作，分别取得当前任务所需授权并核验；开发分支的默认 Push 授权不包含正式发布。保留完整 Target SHA；Tag 已存在或目标不一致时停止，不覆盖。未经批准不得创建、移动或删除 Release Tag。

未完成 Human QA 的 Beta Vertical Slice 保留已知问题和预发布定位，不能宣称 Beta Release Ready。源码分支存在不代表发布页已创建；Tag 存在也不代表下载附件已交付。

## G. 故障处理

| 情况 | 处理原则与恢复条件 |
| --- | --- |
| Push 认证失败 | `GITHUB_DELIVERY_BLOCKED`，保留 Commit；由用户恢复正常 Git 凭据后重试同一分支。报告不得含 Token、密码或凭据输出 |
| Remote Ahead / Diverged | Fetch 后记录双方 SHA 和祖先关系，交给 00/对应 Owner 协调。保留本地成果，不 Force Push、不重写共享历史 |
| Merge Conflict | 暂停该集成，记录冲突路径和负责 Owner，由 00 决定解决方案；不凭文档任务更改生产内容 |
| Untracked Assets | 保留来源不明及其他 Owner 资产；只纳入已批准、许可明确的本轮文件；不 Clean 或批量暂存 |
| 大文件 | 检查现有 .gitignore、.gitattributes、LFS 规则、文件与新增历史 blob 大小，提出拆分/LFS 方案；不自动迁移历史 |
| Working Tree Dirty | 分辨任务内差异和既有 WIP，记录残留；不得用自动 Reset、Checkout、Stash 或覆盖获得 CLEAN |
| Detached HEAD | 停止提交/推送，记录真实 HEAD；在 Owner 明确认领并核实名称不存在后建立所属开发分支，保留原引用 |
| Git LFS 问题 | 检查 `git lfs status`、规则及对象可用性；缺工具/对象/额度或上传失败则阻塞交付。指针文件上远端不能替代对象上传验证 |

按 2026-10-11 核实的 [GitHub 官方资料](https://docs.github.com/en/repositories/working-with-files/managing-large-files/about-large-files-on-github)，普通 Git 文件超过 50 MiB 会收到警告，超过 100 MiB 被阻止；浏览器上传单文件限制为 25 MiB。后续交付在需要时重新核实限制，LFS 配额和资源许可也单独核查。不要把 .gitignore 当作会自动移除已跟踪文件的规则。本制度不授权照搬官方文档中的历史清理或重写步骤。

## 报告与制度接收

报告真实的 Tests PASS / FAIL / PENDING / NOT_RUN，不把未运行自动改为通过。Push 成功但远端核验失败仍为 `GITHUB_DELIVERY_BLOCKED`，保留两个独立结果。只有 SHA 一致才能声明 GitHub Delivery Complete；阶段、集成和 Release 状态各自判断。

制度传播见 [Governance Rollout](GOVERNANCE_ROLLOUT.md)。旧阶段报告保留 `Push: NOT_RUN` 的历史事实；新制度生效后按新流程交付，不回填伪造的 Push 或 QA。旧计划中一般性的“需单独授权 push”由本默认政策更新，但当前用户明确禁推或限制发布的指令仍有效。
