# GitHub Development Governance Audit

Task：`GITHUB_DEVELOPMENT_GOVERNANCE_01`。日期：2026-10-11（Asia/Shanghai）。

## 基线与隔离

| 项目 | 实际审计结果 |
| --- | --- |
| Repository | `E:/godot/若叶睦/方块少女-若叶睦` |
| Remote | `https://github.com/QCYM-qcym/block-girl-mutsumi-mortis.git` |
| main HEAD | `13177bb713c229fd5691c1e53cf5ba4d45f2ff76`，DIRTY |
| origin/main | Fetch 后 `8a77874cc18ceb654664c3e9aeb10a2ccd318048` |
| main 相对 origin/main | Ahead 150 / Behind 0 |
| 00 当前 Worktree | `E:/godot/worktrees/block-girl-foundation-4-integration` |
| 00 实际 Branch / HEAD | `feat/game-feel-full-slice-01` / `d1277ec90b5a739efd4862d314e6c29ac5ac1eda`，CLEAN |
| Editor Dev | `dev/godot-editor-playable` / `2cadbb134459d5384741607c14bd6d42b393708d`，CLEAN |
| Release | `release/beta-game-feel-20261010` / `25de1f6202c764e4003634a387ae05e38bd387c4`，CLEAN |
| Release Tag object | `29c573a54aaa11def8c7001a7e78d291df82d8ce` |
| Release Tag peeled commit | `25de1f6202c764e4003634a387ae05e38bd387c4` |
| 原有本地 Branch / Worktree | 58 / 52，快照含全部名称和 SHA |
| 新治理分支 | `docs/github-delivery-governance-20261011`，从 origin/main 创建 |
| 新治理 Worktree | `E:/godot/worktrees/block-girl-git-governance-12`，创建时 CLEAN |
| 本次 PR 目标 | main，独立纯文档差异 |

创建前确认本地/远端治理分支与目标 Worktree 均不存在，没有复用或覆盖。使用 Git Worktree，不 Checkout main；命令级 `core.longpaths=true` 未写入仓库配置。

## 既有规则兼容性

审计前全部 52 个 Git Worktree 的根目录均未发现 AGENTS.md；排除证据中复制的项目后，跟踪文件清单也未发现其他 AGENTS.md。主项目与工作树的适用父目录未发现额外磁盘 AGENTS.md。

Godot、Runtime、测试和 Owner 正式规定主要分散在合同、Spec 和矩阵内。本轮新增根 AGENTS.md，明确保留这些合同、文件权限和 QA 含义，引用 [Owner Policy](OWNER_BRANCH_POLICY.md) 的固定版本依据；不修改这些既有文件、不推断新生产权限。

Foundation 4A/4B/4C/4D 历史职责与当前 02/04/03/01 入口分别登记；Game Feel Runtime/Maps/Motion/Audio/UI/Quality 的排他范围维持既有矩阵。旧 Spec 中单独审批 Push 的一般流程由新阶段默认政策更新，用户当前明确禁令仍优先。

## 保护范围

开始时 main 的 README 已修改，另有 129 个未跟踪文件：121 个 Art 文档文件、8 个 Release 文档文件。对这 130 项文件、main/Release HEAD、工作区状态与 index 记录本地保护摘要；不上传其私人内容，也不把它们纳入治理 Commit。

本地所有既有分支、Tag 和 Worktree 状态已记录。本任务不写入原有 Worktree，不改 main、Release 或生产文件；结束时独立复核。并发 Owner 若自行产生新变化，按前后快照据实区分，不能掩盖为本轮 CLEAN。

## 公开范围与大文件

`origin/main` 的 .gitignore 忽略 `.godot/`、`/android/`、`tests/gameplay/evidence/`；.gitattributes 为 `* text=auto eol=lf`，没有根 LFS tracking 规则。Integration 的较新 ignore 额外排除部分文档 importer sidecar；本轮不修改任何 ignore 或 LFS 配置。

本机 Git LFS 可用：`git-lfs/3.7.0`。本轮只新增 Markdown 和治理 JSON，不带入游戏资产、原始存档、缓存或未经许可第三方资源；提交前审查新增 blob 大小和敏感数据。没有 LFS 历史迁移、Hooks/Branch Protection 配置或额外工具安装。

## 检查项目

交付前实际检查下列项目，并在最终报告记录结果，不预填未执行的 PASS：

1. UTF-8、非空文件、Markdown 标题和 code fence 完整性。
2. AGENTS.md 的十步交付策略、Owner 范围与既有合同兼容性。
3. 内部文档链接存在，固定提交依据路径存在于公开发布树。
4. 15 个 Owner 的职责和已观察 Git Branch/Worktree 对应关系。
5. JSON 快照字段、58 个原分支和 52 个原 Worktree 的一致性。
6. Git 暂存与提交差异仅含 AGENTS.md / docs/development 文档。
7. 私钥、Token、密码、私人配置与大文件扫描；不输出疑似秘密原文。
8. main、Release Tag 及生产树不变；PR 差异不夹带实验 Commit。
9. 普通 Push 后以精确远端分支引用核验完整 SHA。

Gameplay 全矩阵：`NOT_RUN (documentation-only scope)`。Human QA：`N/A (no gameplay changes)`；项目既有 Human QA PENDING 保留。

## 接收范围

本次仅治理分支正式包含新 AGENTS.md，全部旧分支仍为未接收。详见 [Governance Rollout](GOVERNANCE_ROLLOUT.md) 的 `POLICY_ACTIVE_BRANCHES` / `POLICY_PENDING_BRANCHES`；不能声称所有 Worktree 自动启用。

GitHub CLI：`NOT_AVAILABLE`（未找到 gh）；本轮不安装。PR 若未创建，使用 Rollout 中的 compare 入口由 00 审查后创建。普通 Push 的结果与完整远端 SHA 在提交后报告，不用本地 CLEAN 替代远端证据。
