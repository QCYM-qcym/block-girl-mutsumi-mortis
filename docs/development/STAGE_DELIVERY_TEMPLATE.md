# Stage Delivery Template

按 [Git Workflow](GIT_WORKFLOW.md) 填写实际结果。`<...>` 是模板占位符，真实交付报告必须替换；与任务无关的项写 `N/A` 并说明。

```text
Task ID: <任务唯一ID>
Owner: <00/01/.../10A/10B/13及实际职责>
Worktree: <实际绝对路径>
Branch: <实际Owner Branch，不从聊天标题推断>
Base SHA: <实际40位SHA>
Local Commit SHA: <交付HEAD完整40位SHA>
Changed Files: <相对已声明Base SHA的实际路径清单；说明是否包含依赖>

Tests Executed: <实际命令、环境、Source/Build SHA及证据位置>
Tests PASS: <真实通过项/计数及覆盖范围>
Tests FAIL: <真实失败项/计数及原因>
Tests PENDING: <待依赖/待人工项，含依赖SHA或尚未交付说明>
Tests NOT_RUN: <未运行项及原因>
Human QA: <PASS/FAIL/PENDING/NOT_RUN/N/A，绑定实际Build与证据>
Stage Status: <COMPLETE/PARTIAL/WIP/BLOCKED>
Integration Status: <NOT_SUBMITTED/PENDING_00/INTEGRATED/FAILED及实际集成SHA>

Remote: <实际URL，不含凭据>
Push Status: <SUCCESS/BLOCKED/NOT_RUN>
Push Command or Client: <唯一目标引用或GitHub Desktop步骤>
Remote Branch: <refs/heads/实际分支>
Remote SHA: <查询到的完整40位SHA；失败或不存在写UNAVAILABLE/ABSENT>
Remote Verification Command: <实际独立查询命令>
Remote Verification Time: <含时区>
Remote SHA Verified: <YES/NO>
GitHub Delivery Status: <COMPLETE/GITHUB_DELIVERY_BLOCKED/NOT_RUN>

Working Tree: <CLEAN/DIRTY，列出既有及本轮残留的范围>
Known Risks: <未验收项、依赖、资产许可/大文件或管理风险>
Next Handoff: <交给00的提交、依赖顺序、专属范围、待集成验证及后续Owner>
```

GitHub Delivery COMPLETE 的条件是：正确 Owner Branch 已 Push、独立查询的远端 SHA 等于本地交付 HEAD；且本轮成果仍如实保留验证状态。它不代表整个任务、Integration 或正式 Release 已完成。

可独立验证的 PARTIAL 成果可同时填写 `Stage Status: PARTIAL`、`Push Status: SUCCESS`、`Remote SHA Verified: YES` 和 `GitHub Delivery Status: COMPLETE`，前提是明确交付的部分及未完成项。

Push 失败，或 Push 后核验失败/不一致，填写 `GitHub Delivery Status: GITHUB_DELIVERY_BLOCKED` 并说明可执行的恢复方式。Push 命令成功但核验失败时，`Push Status` 可保留 `SUCCESS`，`Remote SHA Verified` 必须为 `NO`；不得报告已确认同步。

当前任务明确禁止 Push 时填写 `NOT_RUN` 和限制来源；未提交成果的 Local Commit SHA 写 `NOT_CREATED`，不能把原基线伪装成本轮 Commit。本地 CLEAN、Desktop History、日志中的旧 PASS 不能推导新的远端状态或 Human QA。

计数单位（case/check/module）和验证层级必须明确；不要混合计数。文档任务使用文档与 Git 验证，Gameplay 矩阵填写 `NOT_RUN (documentation-only scope)`，Human QA 填写 `N/A (no gameplay changes)`，同时保留项目既有 Human QA PENDING 风险。
