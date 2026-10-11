# Owner Branch Policy

项目 Owner 是职责身份，不由聊天编号、分支前缀或 Worktree 文件夹名决定。每次新任务登记 Owner、真实 Worktree、Branch、Base SHA、允许路径、共享依赖和 Handoff 目标。

## 依据与适用范围

2026-10-11 审计实际 Git 分支/Worktree，并读取已提交的 Game Feel Owner Matrix 和 Foundation 合同。较新的合同尚不在本规范的 `origin/main` 基线里；本规范引用公开发布提交上的固定版本，避免为文档 PR 引入生产历史：

- [Game Feel Owner Matrix](https://github.com/QCYM-qcym/block-girl-mutsumi-mortis/blob/25de1f6202c764e4003634a387ae05e38bd387c4/docs/beta-sprint/game-feel/OWNER_MATRIX.md)
- [Game Feel 机器可读 allowlist](https://github.com/QCYM-qcym/block-girl-mutsumi-mortis/blob/25de1f6202c764e4003634a387ae05e38bd387c4/docs/beta-sprint/game-feel/OWNER_MATRIX.json)
- [Game Feel Contract](https://github.com/QCYM-qcym/block-girl-mutsumi-mortis/blob/25de1f6202c764e4003634a387ae05e38bd387c4/docs/beta-sprint/game-feel/GAME_FEEL_CONTRACT.md)
- [Foundation Authoring Editor §12](https://github.com/QCYM-qcym/block-girl-mutsumi-mortis/blob/25de1f6202c764e4003634a387ae05e38bd387c4/docs/superpowers/specs/2026-09-22-foundation-authoring-editor-design.md)
- [审计分支与 Worktree 快照](OWNER_WORKTREE_SNAPSHOT.json)

空间新线另核实本地 `feat/spatial-puzzle-batch-01` 的 `docs/beta-sprint/spatial-puzzle-batch-01/CONTRACT.md`（审计 HEAD `9386f4a084cbd1132c94ab9277a40106cd1d2cb7`）、03 的 `quality/PROGRESS.md` 和 07 的 `ui/PLAN.md`。这些依据未由本任务上传或标为公开发布；其中主实验 Host/集成属于 00，不能因分支带有 puzzle/content 字样归给 06。

下表是查找任务身份的入口，**不是新增生产写入权限**。当前任务的正式 allowlist 和合同优先；遇职责重叠由 00 明确登记。

## 当前开发线

表内路径相对 `E:/godot/worktrees/`，外部环境单独注明；完整 HEAD/分支/工作区快照在上方 JSON。

| Owner | 职责与边界 | 实际已观察 Branch → Worktree |
| --- | --- | --- |
| 00 Integration | 公共合同、Presenter/Host、共享接线、Merge/Cherry-pick、Focused Regression、Build Handoff | `feat/game-feel-full-slice-01` → `block-girl-foundation-4-integration`；空间实验协调线 `feat/spatial-puzzle-batch-01` → `block-girl-spatial-puzzle-batch-01`；历史 `integration/foundation-4-authoring` 引用仍保留 |
| 01 Runtime | 正式 Runtime/Kernel/Safety/Solver/Replay；具体路径以合同 allowlist 为准 | `feat/pfall-runtime` → `block-girl-game-feel-runtime`；新空间线 `feat/spatial-runtime-01` → `block-girl-spatial-runtime-01`；Foundation 4D 旧线 `feat/foundation-authoring-runtime` → `block-girl-foundation-authoring-runtime` |
| 02 Authoring | 作者数据、适配、唯一 Intent Binder、来源映射；不接管 4D 摘要/验收 | `feat/foundation-authoring-data` → `block-girl-foundation-authoring-data` |
| 03 Quality | 质量编排、Owner 测试与证据；不复制玩法算法，不把 doubles 当正式链路 | `test/game-feel-quality` → `block-girl-game-feel-quality`；`test/spatial-quality-01` → `block-girl-spatial-quality-01`；旧线 `feat/foundation-authoring-quality` → `block-girl-foundation-authoring-quality` |
| 04 Editor | 编辑器插件/Dock/Inspector/UndoRedo；按实际任务区分传统 4B 与独立 Editor Dev | `feat/foundation-editor-tools` → `block-girl-foundation-editor-tools`；`dev/godot-editor-playable` → `block-girl-editor-dev` |
| 05 Art | 批准的 Art 资产、许可与交付清单；共享场景接线由 00；新增实验素材与已批准 masters 分开 | 既有矩阵记录独立外部 Art 环境；本仓库未核实 05 专属 Git Worktree/Branch，不凭 `005` 聊天创建分支 |
| 06 Game Content | 关卡数据、谜题和 L06 预制作；公共 Runtime/Shell 不在默认权限内 | `feat/beta-game-content` → `block-girl-beta-game-content`；`feat/l06-preproduction` → `block-girl-l06-preproduction` |
| 07 Game Shell | 菜单、流程、批准 UI；Settings/HUD 不决定 Runtime 权限 | `feat/game-feel-ui` → `block-girl-game-feel-ui`；`feat/spatial-ui-01` → `block-girl-spatial-ui-01`；修复线 `fix/beta-pause-text-20261009` → `block-girl-beta-game-shell` |
| 08 QA | 对指定 immutable Build 的试玩、Bug、Human QA 和打包核验；不修改生产实现 | 当前证据采用独立 Build/QA 目录；本仓库未核实 08 独占分支。`test/*` 前缀不能证明属于 08 |
| 09 Map & Spatial Design | 作者地图/空间布局；不授予 Runtime 动作权限 | `feat/pfall-map` → `block-girl-game-feel-map`；`feat/spatial-map-01` → `block-girl-spatial-map-01`；历史 `prototype/perspective-fall-01` → `block-girl-map-spatial-design` |
| 10A Fall Animation | Fall/Landing 纯表现采样；`game/feel/animation/fall_landing/**` 及批准测试/文档；不写 Runtime 状态 | `feat/pfall-animation` → `block-girl-game-feel-fall-animation` |
| 10B Edge Animation | Edge/Recoil 表现；`game/feel/animation/edge_recoil/**` 及批准测试/文档；不把普通 blocked move 推断为 Edge | `feat/edge-recoil-animation` → `block-girl-game-feel-edge-animation` |
| 11 Audio | AudioDirector、批准音效及实验音频；不修改 Runtime 和正式共享接线 | `feat/game-feel-audio` → `block-girl-game-feel-audio` |
| 12 GitHub Release | 仓库审计、Git 制度、文档、分支发布、Tag/Release 核验；不改游戏内容 | 本规范 `docs/github-delivery-governance-20261011` → `block-girl-git-governance-12`；发布线 `release/beta-game-feel-20261010` → `release-12` |
| 13 Game Design & Mechanics Research | 机制研究、设计文档和原型方案；生产实现另由对应 Owner 获授权 | `design/rubiks-spatial-puzzles` → `block-girl-design-mechanics` |

同一 Owner 可以有多条分阶段分支，但每轮必须指定其中一条，不能混用另一条线的 QA 证据或未提交内容。未列出的历史 Foundation/Content/QA/修复分支保留原合同；完整枚举见快照，不强制重命名。

## 聊天编号与旧任务审计

检查了当前 50 条聊天列表与 12 条归档任务列表，并仅用它们辅助定位，Git 和正式 Owner 文档仍是身份依据。

- `05｜Art｜角色翻滚 + Inner World` 与 `005 | New Art` 并存；后者是否为新子线必须由 05/00 登记，不能把标题自动等同于 Git Owner Branch。
- `09｜Map & Spatial Design` 与 `009 | 地图与空间设计` 并存；后者列表摘要是查找前者内容，没有据此创建第二条分支。
- `001 | inter` 与 `01｜Runtime｜D_JOBS Final` 并存；`001` 名称不是 Runtime 或 Integration 权限证明。
- `07 | 梳理 Game Shell 菜单与流程` 的列表摘要出现 `TRACK: 06 Game Content`；采用 Git/Owner Matrix 的 07 UI 归属，后续任务以实际 allowlist 为准。
- `04｜Editor｜Dock & Authoring UI` 的历史 4B 与 `dev/godot-editor-playable` 并存；不将旧聊天中的 HEAD 或依赖状态当作当前分支状态。
- `Archive｜F4 Specs & Contracts`、`Archive｜D3 Materialization Review` 是当前列表中的标题，不能仅凭 “Archive” 推断应用归档状态。
- 实际归档列表包含 `集成 FOUNDATION-3 求解质量链`、`完成 FOUNDATION 四分支推送` 等历史任务；保留记录，不恢复或重新分配生产职责。

本轮没有改名、归档/恢复聊天，没有删除历史工作树，也没有按聊天标题新增开发分支。

## 交付职责

全部 Owner 使用 [Stage Delivery Template](STAGE_DELIVERY_TEMPLATE.md) 完成开发分支 Commit、Push 与远端 SHA 核验；00 负责集成，12 负责正式发布。05 外部环境或 08 独立 QA 目录中的成果，需先由对应 Owner/00 登记获准纳入仓库的路径、许可和交付分支，不能为满足 Push 制度直接上传整个外部目录。

规范是否已进入各分支以 [Rollout](GOVERNANCE_ROLLOUT.md) 的实际接收检查为准，表中出现某分支不代表已启用新 AGENTS.md。
