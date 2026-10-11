# GITHUB_GOVERNANCE_INTEGRATION_REPORT

Task: `GITHUB_GOVERNANCE_INTEGRATION_01`，2026-10-11。此收据更新本次接收范围；源文件中的 Track 12 快照保留其历史时间含义。

Governance source: `01d51343dd032e15d80b702f04072c7e3e96754c`，实时 origin 引用核验一致。
00 Target Branch: `feat/spatial-puzzle-batch-01`。工作树：`E:/godot/worktrees/block-girl-spatial-puzzle-batch-01`。
00 Base: `1c995a7ad70fc72e35eb864023835669fdf1e31d`。
规范接收 Integration Commit: `199a255b6831399066039521fb85ea89620dbfc1`，普通 Push SUCCESS，Remote SHA Verified YES。
随后仅追加传播收据；最终交付 HEAD 在提交并再次 Push/远端核验后报告，不在文件内伪造自引用 SHA。

## POLICY_ACTIVE_BRANCHES

| Owner | Branch | 已提交、已推送且远端核验一致的接收 SHA |
|---|---|---|
| 00 | `feat/spatial-puzzle-batch-01` | `199a255b6831399066039521fb85ea89620dbfc1` |
| 01 | `feat/spatial-runtime-01` | `19af09d09233cc168e428683f8d8645f514dc216` |
| 07 | `feat/spatial-ui-01` | `340b88b078833f38678b423b61503944c3e66e2e` |
| 09 | `feat/spatial-map-01` | `c2cbcac02399ac60bb1445385507d218a87cd5d8` |
| 10A | `feat/pfall-animation` | `96f54e5ecfe68f23d6cf54edcbfcda5fec968670` |
| 10B | `feat/edge-recoil-animation` | `de110711c1a8508b343de74fbc644e7c80629f33` |
| 11 | `feat/game-feel-audio` | `66885052790b215b83d005aaed26bf7011ae1b63` |
| 12 source | `docs/github-delivery-governance-20261011` | `01d51343dd032e15d80b702f04072c7e3e96754c` |

每个新接收分支原先均无根 AGENTS.md 或同名治理文件，受控 `cherry-pick -x` 只接收原7个文档；初次接收7/7 Git blob与源完全相同。没有合入源分支祖先、切换main或覆盖其他Owner生产文件。已通知6个Owner重新读取AGENTS，后续阶段按验证→Commit→Push→远端SHA→Handoff执行。

## POLICY_PENDING_BRANCHES / HISTORICAL_FROZEN

以下冻结来自Owner明确回复或固定发布基线；保持原HEAD，不要求追补。Dirty与生命周期分别记录。

- `feat/pfall-runtime`：01 confirmed superseded Runtime line。
- `feat/foundation-authoring-runtime`：01 confirmed frozen Foundation delivery。
- `test/spatial-quality-01`：03 confirmed delivered and integrated; no ongoing task。
- `feat/beta-game-content`：06 confirmed frozen。
- `feat/beta-content-batch-02`：06 confirmed frozen。
- `fix/l04-inner-movement-p1`：06 confirmed frozen。
- `feat/l06-preproduction`：06 confirmed frozen。
- `feat/beta-content-batch-03`：06 confirmed frozen; delivered L06 still pending integration; no push retroactively claimed。
- `feat/game-feel-ui`：07 confirmed superseded UI line。
- `feat/pfall-map`：09 confirmed superseded map line。
- `prototype/perspective-fall-01`：09 confirmed historical prototype。
- `design/rubiks-spatial-puzzles`：13 confirmed frozen Git line; current work is external Obsidian。
- `release/beta-game-feel-20261010`：Fixed published baseline; user prohibits release changes。

其余未确认活跃的分支保持 PENDING，不能只凭名称判定冻结或启用。全部53个工作树的实际分支、基线SHA、dirty数量和分类见 [机器收据](GOVERNANCE_ADOPTION_20261011.json)。main、Editor Dev及未确认的旧Foundation/测试线未传播；不自动合并main。

## DIRTY / EXTERNAL

| 工作树 | 分支 | 原有状态 |
|---|---|---|
| `E:/godot/若叶睦/方块少女-若叶睦` | `main` | 162项；保留，未Stash/Reset/覆盖 |
| `E:/godot/worktrees/block-girl-design-mechanics` | `design/rubiks-spatial-puzzles` | 1项；保留，未Stash/Reset/覆盖 |
| `E:/godot/worktrees/block-girl-game-feel-quality-01` | `test/game-feel-quality-01` | 13项；保留，未Stash/Reset/覆盖 |
| `E:/godot/worktrees/block-girl-game-feel-ui-extension-01` | `feat/game-feel-ui-extension-01` | 40项；保留，未Stash/Reset/覆盖 |

05：外部Art源 `E:/Study/方块娘项目/若叶睦/model`，研究文档位于脏main；无05独占分支。仅明确许可的清单/文档按批准路径交付，不上传整个Art目录。
08：`E:/godot/beta-sprint-builds`，无08独占分支。后续由00指定文档分支接收脱敏报告、截图清单和哈希；原始截图、日志、Build、存档保留本地。
13：Obsidian `E:/obsdian/青澄的水泥房/方块娘/若叶睦/核心机制/13-游戏设计与机制研究`，非Git。后续仅三篇批准专题Markdown及SHA清单进入指定文档分支；不上传整个Vault。
外部三线均为PENDING，已确认最小交付方式，本轮没有创建外部AGENTS或声称已启用。

## 实际验证

- 源提交与实时远端一致；初次接收仅7文档、7/7源blob一致。Markdown/JSON完整性、18个内部链接、15个Owner覆盖检查通过。
- 原正式合同、Runtime/Foundation/Owner权限保持；Gameplay/Art/Runtime/Save变动均为0。Godot全矩阵NOT_RUN（纯文档任务）。
- 未发布历史执行高置信凭据特征、文件大小与来源复核，无命中或新增超50MiB文件。历史profile是自动测试隔离日志/生成夹具，不是真人存档；未用删除或历史重写隐藏它们。
- 6个Owner接收后工作树均CLEAN；00接收提交已Push并独立SHA核验。01首次TLS握手失败，保持原提交普通重试成功，未更改TLS设置。
- main 162项既有文件逐字节SHA保持，main/所有Release Branch/所有Tag引用保持；旧QA包及历史报告未改。

## 剩余管理风险与后续

- 规范是仓库执行约定，不是服务器分支保护或自动Push服务；未修改GitHub权限、Hooks或CI。
- 旧工作树不会自动获得政策；Dirty先由Owner处理，历史冻结线在将来新任务重新登记后再接收。未确认活跃线继续PENDING。
- 06最新L06交付仍待独立集成，03阶段已封存，Human QA未因治理任务升级。
- 历史Push NOT_RUN保留原事实；本次发布的开发分支不等于正式Release完成。main与Release Tag均未修改。
- 后续接收继续使用原源提交的文档范围；已有AGENTS必须逐段兼容合并，不以整个Integration历史传播文档。

详细规则保持在 [Git Workflow](GIT_WORKFLOW.md)、[Owner Policy](OWNER_BRANCH_POLICY.md) 和 [阶段模板](STAGE_DELIVERY_TEMPLATE.md)。
