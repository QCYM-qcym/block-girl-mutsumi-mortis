# RELEASE_PREPARATION_REPORT

Status: **PUSH_CONFIRMATION_REQUIRED**.
Version positioning: **Beta Vertical Slice**.
Prepared: 2026-10-11T14:46:47.101301+08:00 (Asia/Shanghai).

## Confirmed branch and immutable base

- Project: Mutsumi Veilshift / 方块少女-若叶睦.
- Repository common Git directory: `E:/godot/若叶睦/方块少女-若叶睦/.git`.
- Release Worktree: `E:\godot\worktrees\release-12`.
- Target branch: `release/beta-game-feel-20261010`.
- Base / production source: `d1277ec90b5a739efd4862d314e6c29ac5ac1eda`.
- Remote: `https://github.com/QCYM-qcym/block-girl-mutsumi-mortis.git`.
- Fetched `origin/main`: `8a77874cc18ceb654664c3e9aeb10a2ccd318048`; live remote HEAD verified at that SHA.
- Remote target branch: absent at preparation preflight.
- Branch strategy / base / documentation commit: authorized by user on 2026-10-11.
- Push / tag creation: **not authorized; NOT_RUN / NOT_CREATED**.

新release分支从固定base创建，checkout baseline CLEAN，base ancestry确认，起始base..HEAD为0。
本轮只新增一个README / docs/release文档提交。提交后的最终full SHA在任务最终输出及common `.git/release-preflight/FINAL_PUSH_CONFIRMATION.json`记录；它不写回自身提交以避免自引用SHA。
现有owner/main/integration分支保持原refs，不merge其它分支、不rebase、不squash、不删除branch。

原Codex native worktree创建工具因任务cwd为项目父目录返回Not a git repository；Git fallback首次长路径checkout失败但release ref已创建且保留。之后在较短路径 `E:\godot\worktrees\release-12` checkout同一release ref成功，使用命令级 `-c core.longpaths=true`，未修改项目或全局配置。原长路径失败Worktree已由Git创建失败处理清理，不删除任何branch。

## Included Beta Vertical Slice scope

- **Five Level 3D Slice**: existing L01–L05 content and 3D slice receipt in base ancestry.
- **Surface/Inner**: inherited dual-world gameplay and approved presentation.
- **Perspective Connection**: inherited authored connections and regression scope.
- **Perspective Fall**: scoped experimental MAP A/B, registered Runtime/Kernel/Safety and formal trajectory.
- **Forward Drop**: continuous forward departure, yellow TOP landing, Fall→Roll→Goal; focused ten-case receipts.
- **Game Feel基础**: existing Full Slice host, Edge Recoil, animation, scoped Audio/UI and shared settings.

Included source milestones, all verified ancestors of base:

| Milestone | SHA |
| --- | --- |
| Five Level 3D Slice | d472885d7375ef73fd36e4abc1847a9ba36cac44 |
| Game Feel Full Slice / Edge Recoil | 1938096d48f5edcfc247923a4badf13877c3eb1b |
| Perspective Fall Runtime | 26387d6c34a869ad7035ee13ee77d8d5c24d796a |
| PFALL Integration handoff | 99f2f1db9d9646d8fc7f3856fc4e64df81ff6cff |
| UI Host | e12d3931cdd482bd970bb07b1db12cd81acfc5b2 |
| Yellow curve build source | a741ee5e29dd2a849df13ff40100c08a9f1a2dc7 |
| Forward Drop animation merge | c89a87584d8d5db0916d4b0e516c449860063223 |
| Forward Drop quality merge | fe370ad832bb62cd31a6d22909ce1a5bd1fe1311 |
| Source closeout / release base | d1277ec90b5a739efd4862d314e6c29ac5ac1eda |

`a741ee5`是yellow curve source receipt；`fe370ad`是真实Forward Drop十项质量merge，保留原审计中的标签澄清。

## Explicitly incomplete

- **Human QA / Human Feel**: latest Forward Drop package NOT_RUN; human listening / visual QA not inferred from automated evidence.
- **Graphical TraceReplayer剩余项**: latest scoped mode1 paths have PASS receipts; the broader 94-case matrix remains 54 PASS /40 PENDING. Focused ten-case PASS does not complete all input / lifecycle / pose / presentation coverage.
- **L06**: playable greybox implementation and delivery are outside this release ancestry. Historical design-only preproduction is inherited; it is not delivered L06 gameplay.
- **完整Audio/UI/Art收口**: Art review / formal replacement, Connection readiness interface, broader audio/UI coverage, human review and soak work remain incomplete.

Version wording is **Beta Vertical Slice**, a source-playable development/QA preview requiring external Godot. No complete Beta acceptance, standalone executable, new playtest certification or all-platform support is claimed. Existing game evidence is cited rather than rerun by this Git maintenance task.

## Retained history and exclusions

Inherited range: `8a77874cc18ceb654664c3e9aeb10a2ccd318048..d1277ec90b5a739efd4862d314e6c29ac5ac1eda`, **325** commits ahead of origin/main, of which **290** are unreachable from any origin remote-tracking ref. One documentation commit extends that base; final intended range is **326** commits vs origin/main / **291** not in any origin refs if the verified remote refs remain unchanged.

[INCLUDED_COMMITS.tsv](INCLUDED_COMMITS.tsv) preserves the 325 inherited full SHAs / parents / authors / author dates. [UNPUSHED_COMMITS.tsv](UNPUSHED_COMMITS.tsv) preserves the earlier 301-commit all-local snapshot; it predates this new documentation commit. [REPOSITORY_AUDIT_REPORT.md](REPOSITORY_AUDIT_REPORT.md) and [raw audit data](REPOSITORY_AUDIT_DATA.json) are explicitly historical audit snapshots, not fresh counts for the newly created release Worktree. The earlier [verification](PREPARATION_VERIFICATION.json) likewise documents the prior main-only preparation.

The inherited source file range has **9,449** changed paths vs origin/main; [RELEASE_FILES_CHANGED.tsv](RELEASE_FILES_CHANGED.tsv) is that original source-baseline manifest. The new release commit changes only README.md and docs/release/. Final Git file list/count and full SHA are captured after commit in the local preflight receipt.

No source/test/art/scene/runtime/config edits are added to base. However, publishing this branch necessarily publishes the existing candidate's gameplay, configuration and art changes relative to old origin/main, including `experiments/`, `production/experimental/`, audio and substantial docs/tests source evidence. The history has not been stripped or rewritten.

The previous 12 unique candidate-external local commits remain excluded: L06 greybox, advanced editor work, separate map/prototype changes, public README old commit, local-main-only partial QA and pause-owner documentation. Uncommitted owner work remains excluded: main's77 Art files, quality-01 staged tests, UI-extension untracked files. Only the approved prior audit documentation is copied into this independent Worktree; original main files remain untouched.

No merge of `13177bb` or `56b70f9` has been performed. No aggregate staging from other Worktrees.

## Large-file preflight

Prior reachable-history audit maximum: **23.97 MiB**, four blobs ≥10 MiB, none reaching50 MiB. Candidate source tree about541.02 MiB; new text documentation adds only a few MiB. Git LFS migration is not needed to address a single-file limit in the audited range and has not been run. No .gitattributes / project config modification.

This preflight checks Git object sizes and the intended new branch, not credential write access, server-side protection or acceptance of an actual push.

## TAG_CONFIRMATION_REQUIRED

- Suggested tag: **`v0.3-beta-game-feel`**.
- Suggested type: annotated tag, preserving the release-documentation commit as its target.
- Suggested meaning: Beta Vertical Slice / development preview; keep incomplete QA and presentation scope visible.
- Target: the final full release HEAD emitted after documentation commit.
- Current status: **NOT_CREATED**. Local and remote exact tag name absent at preparation preflight.
- Tag creation and tag push are separate actions requiring explicit confirmation. No tag, GitHub Release or Release asset is created by this task.

## PUSH_CONFIRMATION_REQUIRED

| Field | Prepared push review |
| --- | --- |
| Target branch | `refs/heads/release/beta-game-feel-20261010` on origin; intended new branch only |
| Commit range | `8a77874cc18ceb654664c3e9aeb10a2ccd318048..` final release HEAD; 325 inherited commits plus1 documentation commit |
| Final SHA | Resolve `refs/heads/release/beta-game-feel-20261010` after the documentation commit; exact full SHA emitted in final output / local preflight receipt |
| Files changed | Existing source manifest9,449 paths plus this commit's README / docs/release changes; exact final list/count checked after commit |
| Risk | Existing public repository; experimental MAP A/B, audio and evidence sources become public; Human QA,40 broader matrix items,L06 and full Audio/UI/Art closure remain incomplete; source-playable requires Godot |
| Rollback | Before push: keep branch and commit locally and withhold push. After a future push: preserve refs/history and propose targeted revert commits; this task does not delete branches or rewrite public history. Already published history cannot be withdrawn by a revert |

Push before this explicit checkpoint is prohibited. **No `git push`, force push, dry-run push, branch deletion or public rebase is run.** A future approved push must name only this branch with a non-force refspec and disable automatic tag following; main and tags are not part of the target. This task stops after local commit, exact SHA / diff / size / ref verification and confirmation output.

## Verification boundary

Git checks cover clean base, exact branch/parent ancestry, staged path allowlist, whitespace and local documentation links, preserved owner/main refs and bytes, unchanged protected source tree, final clean release Worktree, live remote HEAD / absent target branch and absent tag, and large blobs needed for the proposed branch. They do not claim fresh Godot/graphical/Human QA results.

The immutable precommit record is [RELEASE_BRANCH_PRECOMMIT.json](RELEASE_BRANCH_PRECOMMIT.json); final full-SHA receipt is Git metadata in the common directory.
