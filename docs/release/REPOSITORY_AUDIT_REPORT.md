# REPOSITORY_AUDIT_REPORT

审计时间：2026-10-11T14:22:42.721801+08:00（Asia/Shanghai）。MODE：AUDIT → RELEASE PREPARATION。

## Summary

- Repository: `E:\godot\若叶睦\方块少女-若叶睦`。用户给定 cwd 是父目录，本身不是 Git 仓库；已在实际项目根目录审计。
- Current branch: `main`。
- Current HEAD: `13177bb713c229fd5691c1e53cf5ba4d45f2ff76`。
- Remote HEAD: `8a77874cc18ceb654664c3e9aeb10a2ccd318048`；远端 symbolic HEAD 为 `refs/heads/main`。
- Remote: `https://github.com/QCYM-qcym/block-girl-mutsumi-mortis.git`（fetch / push 相同）。
- GitHub API：`visibility=public`、`private=false`、`default_branch=main`、`license=null`。
- Branches: 50 local；Worktrees: 44。
- Ahead/Behind: local `main` vs `origin/main` = **150 / 0**；candidate vs `origin/main` = **325 / 0**。
- `main` vs candidate：main-only **1**，candidate-only **176**；共同祖先 `4c505e03f71f7269581078fc586cd8c43cd2701e`。
- Unpushed commits（对全部 origin refs）：main **115**；candidate **290**；全部 local heads 去重 **301**。main 的150 / candidate 的325是相对origin/main的领先数量，其中各35个提交已可从其它origin分支访问。
- `git fetch origin` 成功；其后 `git ls-remote --symref origin HEAD` 独立确认远端 HEAD。
- 所有指定参考 SHA 存在，但均不在 local `main` / `origin/main`，均在 candidate ancestry。
- Push / Merge / Rebase / Tag / branch creation / commit / LFS migration: **NOT_RUN**。

## Audit scope and checks

已执行 `git status`、`git branch -a`、`git worktree list --porcelain`、`git remote -v`、`git log --oneline --decorate -30`、`git fetch origin`，并追加全分支 ancestry / ahead-behind、全部 Worktree status、远端 HEAD、reachable blob size 与 `git fsck --connectivity-only --no-dangling`。Connectivity check exit 0；无诊断输出。无 Godot、Runtime、Gameplay、Scene、Art、测试逻辑或 project config 修改；不启动游戏测试。

`INCLUDED_COMMITS.tsv` 记录候选相对远端的完整 **325** 个提交（含 merge commits），保留 full SHA、parents、作者、作者时间、subject。该325是origin/main未纳入的提交，不等同于从未推送；真正全部origin refs不可达的301个local提交见 `UNPUSHED_COMMITS.tsv`。不推断其它remote / PR隐藏refs。不是325个普通线性提交。

`RELEASE_FILES_CHANGED.tsv` 是 `8a77874cc18ceb654664c3e9aeb10a2ccd318048..d1277ec90b5a739efd4862d314e6c29ac5ac1eda` 的完整文件差异清单。它描述已有候选历史，而不是本次审计修改。

## Current HEAD recent history (30)

```text
13177bb (HEAD -> main, test/game-feel-quality-01) docs(qa): record partial UI QA and hand off pause text P2
4c505e0 Issue visual Beta Slice receipt and BLACK BOX QA handoff
8a7d339 Handle hidden file metadata in Daily Build and record MAIN acceptance
22dc728 Preserve visual validation source and upstream license bytes
42d290c Integrate approved Beta Shell UI with existing L01 presentation
7c0d8cc docs: issue L01 main-project 3D vertical slice receipt
7352002 build: preserve approved art and handoff bytes across checkouts
29bba32 feat: present formal L01 with approved 3D art and preserve gameplay parity
0162048 docs: freeze Foundation Core for Beta and defer advanced authoring
8bd49cb docs: record formal I2 vertical pass and current sprint state
689ef1d test: accept I2 through real jobs quality replay and runtime mechanics
96397ea docs: issue formal D_JOBS receipt and unlock I2
3dc92ca test: bind corrected project-local harness launch
5bb300a test: keep saved acceptance evidence inside disposable project
ca02a52 test: register harness version for exact D_JOBS final validation
752404b test: bind exact D_JOBS finalization candidate without formal delivery
5d73ccf merge: integrate exact D_JOBS finalization candidate for validation
7836de5 (feat/foundation-authoring-runtime) feat: finalize foundation jobs stage orchestration
c60774a docs: hand off verified Content Shell Beta slice to QA
e22d025 feat: integrate three-level Beta content and shell slice
c084e30 merge: integrate Beta Game Shell owner delivery
c4d67d0 merge: integrate Game Content Batch 01 owner delivery
87c3371 build: establish Beta daily smoke and coordinator baseline
7abf98d (feat/beta-game-shell) feat: add Beta game shell with safe progress and settings persistence
608a18a (feat/beta-game-content) docs(content): specify game shell catalog integration
e71cb41 chore(content): normalize evidence hashes for portable delivery
d430e81 test(content): verify batch playthroughs and record delivery evidence
4c80b55 feat(content): add formal first level and two playable greyboxes
9d23882 docs: register A_EDIT D_HOST and jobs core phase receipt
c06065c fix: append phase dependency evidence as an array
```

## Branches

Ahead/Behind 列以 `origin/main` 为参照；Unpushed 列以全部 origin remote-tracking refs 为参照。
Peer Behind/Ahead 以该 branch 的同名 origin ref 为参照；ABSENT 不代表远端未知，它表示 fetch 后不存在同名 remote-tracking ref。

| Branch | Full HEAD | Ahead/Behind origin/main | Unpushed | In main | In candidate | Origin peer | Peer Behind/Ahead |
| --- | --- | --- | --- | --- | --- | --- | --- |
| debug/foundation-4-baseline-f2-graphical | bd393303d3a21ae3ddebc6643a94a114437365a3 | 35/3 | 0 | YES | YES | origin/debug/foundation-4-baseline-f2-graphical | 0 / 0 |
| docs/foundation-4-authoring-design | 55d1edbafcfa507cc55ef9c0dda79f3d57e80e82 | 33/3 | 0 | YES | YES | origin/docs/foundation-4-authoring-design | 0 / 0 |
| feat/beta-3d-integration-02 | b910167becee2194c0cfc724d8f0fe47578836a9 | 155/0 | 120 | NO | YES | ABSENT | - |
| feat/beta-content-batch-02 | 9482e7279acd2cc99af0f7b2211790ab2eace815 | 157/0 | 122 | NO | YES | ABSENT | - |
| feat/beta-content-batch-03 | 7d4a050c68dd6c9a6527486c1dbded5c61ec0c6d | 196/0 | 161 | NO | NO | ABSENT | - |
| feat/beta-five-level-3d | 2cfc4d2ef221c450ad9024c8ea3a72d69e4fcf63 | 185/0 | 150 | NO | YES | ABSENT | - |
| feat/beta-game-content | 608a18a8c0627bb8a8a57f3cde554e723016dbb7 | 4/0 | 4 | YES | YES | ABSENT | - |
| feat/beta-game-shell | 7abf98d1e184fda5801c9271ebf02951ed6ecadd | 1/0 | 1 | YES | YES | ABSENT | - |
| feat/beta-map-spatial-design | 8a80fbb64eca7e6d7449654f4ace39a35e0f6d41 | 195/0 | 160 | NO | NO | ABSENT | - |
| feat/beta-shell-batch-02 | d22e3999282ffb48b7c2047c4365623b3b1e32bb | 161/0 | 126 | NO | YES | ABSENT | - |
| feat/edge-recoil-animation | 285896da24b4f5ec223fe8bf3f75e29fa1d18381 | 197/0 | 162 | NO | YES | ABSENT | - |
| feat/foundation-authoring-data | 8a67282ac3022cb3d9b43e553424ed1aa3b2d7d2 | 111/3 | 76 | YES | YES | ABSENT | - |
| feat/foundation-authoring-quality | bb27f8c7cd6e2d9d94fbe3b8d3f98b99f86484d1 | 50/3 | 15 | YES | YES | ABSENT | - |
| feat/foundation-authoring-runtime | 7836de52866255dd6f9684214b014d9703e7854d | 123/3 | 88 | YES | YES | ABSENT | - |
| feat/foundation-celestial-lighting | 84781cc6b7e00b96c60c69f15ea16adbe06bd4ee | 2/3 | 0 | YES | YES | origin/feat/foundation-celestial-lighting | 0 / 0 |
| feat/foundation-core | 821bce29fc94dbed42fafbe3f4a720b4715d4aa3 | 33/3 | 0 | NO | NO | origin/feat/foundation-core | 0 / 0 |
| feat/foundation-data-contracts | 38894843c682be7f42be8fe4dad0c512d87ffebf | 2/3 | 0 | YES | YES | origin/feat/foundation-data-contracts | 0 / 0 |
| feat/foundation-editor-tools | 98db5f1fdef9b396d786225214d62d1216c17e62 | 144/0 | 109 | NO | NO | ABSENT | - |
| feat/foundation-level-baker | f5e72665f8f099f5103a49b9de58b72e45c90c66 | 13/3 | 0 | YES | YES | origin/feat/foundation-level-baker | 0 / 0 |
| feat/foundation-orientation-math | 10b1fb1a564c500d58b7d8ecc2343baef74942e3 | 2/3 | 0 | YES | YES | origin/feat/foundation-orientation-math | 0 / 0 |
| feat/foundation-puzzle-intent-ablation | 70500cbf576e9f21c9238a7728916b41bd45b4e7 | 23/3 | 0 | YES | YES | origin/feat/foundation-puzzle-intent-ablation | 0 / 0 |
| feat/foundation-rule-kernel | 384696f3708504d806c630b7e57a898139780695 | 13/3 | 0 | YES | YES | origin/feat/foundation-rule-kernel | 0 / 0 |
| feat/foundation-runtime-parity | e6f7083be9cccef05642a7fcdb7c9f3c2f5870b2 | 25/3 | 0 | YES | YES | origin/feat/foundation-runtime-parity | 0 / 0 |
| feat/foundation-runtime-prototype | aa5362f04dfb0477f7234c8f96bc48773a305de2 | 13/3 | 0 | YES | YES | origin/feat/foundation-runtime-prototype | 0 / 0 |
| feat/foundation-runtime-saved-closure | 7493ab31cf6a71ca9b4778bfe871f33bba2e586d | 110/3 | 75 | YES | YES | ABSENT | - |
| feat/foundation-runtime-stage-result | 8f7fb52f029053bda10b965da840c6763fc13bf0 | 97/3 | 62 | YES | YES | ABSENT | - |
| feat/foundation-softlock-analysis | f41fa732bb6e1a0f4e0be3c703e5364bc9aab2e2 | 24/3 | 0 | YES | YES | origin/feat/foundation-softlock-analysis | 0 / 0 |
| feat/foundation-spatial-model | ebeabef11adcc5aa588a74ef290748b14a455c3a | 2/3 | 0 | YES | YES | origin/feat/foundation-spatial-model | 0 / 0 |
| feat/foundation-state-explorer-bfs | f34dd271adabcc4b724eb55b5fff1cb35f532e59 | 23/3 | 0 | YES | YES | origin/feat/foundation-state-explorer-bfs | 0 / 0 |
| feat/foundation-static-validator | f530e2fe16c64880812b1b20a06504798a477b6b | 13/3 | 0 | YES | YES | origin/feat/foundation-static-validator | 0 / 0 |
| feat/game-feel-audio | 2f98464f4d5349d3ab8463bd4de3c9532c480b0c | 198/0 | 163 | NO | YES | ABSENT | - |
| feat/game-feel-full-slice-01 | d1277ec90b5a739efd4862d314e6c29ac5ac1eda | 325/0 | 290 | NO | YES | ABSENT | - |
| feat/game-feel-ui | 3e75c9b135a40f13c83af8f4bb9fe65f87b159e1 | 207/0 | 172 | NO | YES | ABSENT | - |
| feat/game-feel-ui-extension-01 | 2938d6e534f5b596bb320ce79d72b69f5923f3cd | 195/0 | 160 | NO | YES | ABSENT | - |
| feat/l06-preproduction | d2b78e183839e078c9a28074b2e25359a40608c4 | 185/0 | 150 | NO | YES | ABSENT | - |
| feat/pfall-animation | 5fdf11e79f0db7f70dbde0d3cbfe6fcee3be098a | 203/0 | 168 | NO | YES | ABSENT | - |
| feat/pfall-map | 12a16483c56557aa794a7c1b7f52b2b0a348236f | 202/0 | 167 | NO | YES | ABSENT | - |
| feat/pfall-runtime | fd22434d3eb0de52a764cb98222371a39412635a | 255/0 | 220 | NO | YES | ABSENT | - |
| feat/playable-puzzle-p01 | 549a2402089c4b4915f318c9ed29a50ed4a2256f | 0/4 | 0 | YES | YES | origin/feat/playable-puzzle-p01 | 0 / 0 |
| feat/playable-puzzle-p02 | 4643062e83a962000d14f0e1dbfbece6e310d4ed | 1/3 | 0 | YES | YES | origin/feat/playable-puzzle-p02 | 0 / 0 |
| fix/beta-pause-text-20261009 | 56b70f96be3a05bb45e20cf90f50d99826af3945 | 151/0 | 116 | NO | NO | ABSENT | - |
| fix/l04-inner-movement-p1 | a80a28b4edafda1faa5be4e890e0b61447afc716 | 176/0 | 141 | NO | YES | ABSENT | - |
| integration/foundation-2-kernel-safety | a0699debe42cf880d25ddda57d46c123bc912b4c | 16/3 | 0 | YES | YES | origin/integration/foundation-2-kernel-safety | 0 / 0 |
| integration/foundation-3-solver-quality | bfcc6c004db232ca2f4ea4d409c98bda0dc6d165 | 32/3 | 0 | YES | YES | origin/integration/foundation-3-solver-quality | 0 / 0 |
| integration/foundation-4-authoring | 99f2f1db9d9646d8fc7f3856fc4e64df81ff6cff | 244/0 | 209 | NO | YES | ABSENT | - |
| main | 13177bb713c229fd5691c1e53cf5ba4d45f2ff76 | 150/0 | 115 | YES | NO | origin/main | 0 / 150 |
| prototype/perspective-fall-01 | d5d63f37af8624f332ed4e9ab90b096cab891ff9 | 196/0 | 161 | NO | NO | ABSENT | - |
| test/beta-3d02-focused-qa | b910167becee2194c0cfc724d8f0fe47578836a9 | 155/0 | 120 | NO | YES | ABSENT | - |
| test/game-feel-quality | fd66bfa08099a0bdc7230b2399ee74766ceff3e2 | 319/0 | 284 | NO | YES | ABSENT | - |
| test/game-feel-quality-01 | 13177bb713c229fd5691c1e53cf5ba4d45f2ff76 | 150/0 | 115 | YES | NO | ABSENT | - |

没有删除、重命名或复位任何分支。已纳入 candidate 的 owner branches 无需再次 merge；未纳入分支并不自动具有可发布资格。

## Worktrees

状态快照见 [raw JSON](REPOSITORY_AUDIT_DATA.json)。当前项目根目录的初始 tracked 状态 CLEAN，但预存 **77** 个未跟踪 Art 文件，因此整个工作树不为 CLEAN。JSON 在文档准备过程中采集，包含本任务的未跟踪审计输出；README 在其后修改。

| Path | Branch | Full HEAD | Status |
| --- | --- | --- | --- |
| E:/godot/若叶睦/方块少女-若叶睦 | main | 13177bb713c229fd5691c1e53cf5ba4d45f2ff76 | 77 pre-existing Art files + audit outputs; README changed later |
| E:/godot/worktrees/block-girl-beta-3d-integration-02 | feat/beta-3d-integration-02 | b910167becee2194c0cfc724d8f0fe47578836a9 | CLEAN (tracked + untracked) |
| E:/godot/worktrees/block-girl-beta-3d02-focused-qa | test/beta-3d02-focused-qa | b910167becee2194c0cfc724d8f0fe47578836a9 | CLEAN (tracked + untracked) |
| E:/godot/worktrees/block-girl-beta-content-batch-02 | feat/beta-content-batch-02 | 9482e7279acd2cc99af0f7b2211790ab2eace815 | CLEAN (tracked + untracked) |
| E:/godot/worktrees/block-girl-beta-content-batch-03 | feat/beta-content-batch-03 | 7d4a050c68dd6c9a6527486c1dbded5c61ec0c6d | CLEAN (tracked + untracked) |
| E:/godot/worktrees/block-girl-beta-game-content | feat/beta-game-content | 608a18a8c0627bb8a8a57f3cde554e723016dbb7 | CLEAN (tracked + untracked) |
| E:/godot/worktrees/block-girl-beta-game-shell | fix/beta-pause-text-20261009 | 56b70f96be3a05bb45e20cf90f50d99826af3945 | CLEAN (tracked + untracked) |
| E:/godot/worktrees/block-girl-beta-shell-batch-02 | feat/beta-shell-batch-02 | d22e3999282ffb48b7c2047c4365623b3b1e32bb | CLEAN (tracked + untracked) |
| E:/godot/worktrees/block-girl-five-level-3d | feat/beta-five-level-3d | 2cfc4d2ef221c450ad9024c8ea3a72d69e4fcf63 | CLEAN (tracked + untracked) |
| E:/godot/worktrees/block-girl-foundation-3-integration | integration/foundation-3-solver-quality | bfcc6c004db232ca2f4ea4d409c98bda0dc6d165 | CLEAN (tracked + untracked) |
| E:/godot/worktrees/block-girl-foundation-4-integration | feat/game-feel-full-slice-01 | d1277ec90b5a739efd4862d314e6c29ac5ac1eda | CLEAN (tracked + untracked) |
| E:/godot/worktrees/block-girl-foundation-authoring-data | feat/foundation-authoring-data | 8a67282ac3022cb3d9b43e553424ed1aa3b2d7d2 | CLEAN (tracked + untracked) |
| E:/godot/worktrees/block-girl-foundation-authoring-design | docs/foundation-4-authoring-design | 55d1edbafcfa507cc55ef9c0dda79f3d57e80e82 | CLEAN (tracked + untracked) |
| E:/godot/worktrees/block-girl-foundation-authoring-quality | feat/foundation-authoring-quality | bb27f8c7cd6e2d9d94fbe3b8d3f98b99f86484d1 | CLEAN (tracked + untracked) |
| E:/godot/worktrees/block-girl-foundation-authoring-runtime | feat/foundation-authoring-runtime | 7836de52866255dd6f9684214b014d9703e7854d | CLEAN (tracked + untracked) |
| E:/godot/worktrees/block-girl-foundation-baker | feat/foundation-level-baker | f5e72665f8f099f5103a49b9de58b72e45c90c66 | CLEAN (tracked + untracked) |
| E:/godot/worktrees/block-girl-foundation-celestial | feat/foundation-celestial-lighting | 84781cc6b7e00b96c60c69f15ea16adbe06bd4ee | CLEAN (tracked + untracked) |
| E:/godot/worktrees/block-girl-foundation-contracts | feat/foundation-data-contracts | 38894843c682be7f42be8fe4dad0c512d87ffebf | CLEAN (tracked + untracked) |
| E:/godot/worktrees/block-girl-foundation-editor-tools | feat/foundation-editor-tools | 98db5f1fdef9b396d786225214d62d1216c17e62 | CLEAN (tracked + untracked) |
| E:/godot/worktrees/block-girl-foundation-f2-baseline-debug | debug/foundation-4-baseline-f2-graphical | bd393303d3a21ae3ddebc6643a94a114437365a3 | CLEAN (tracked + untracked) |
| E:/godot/worktrees/block-girl-foundation-intent | feat/foundation-puzzle-intent-ablation | 70500cbf576e9f21c9238a7728916b41bd45b4e7 | CLEAN (tracked + untracked) |
| E:/godot/worktrees/block-girl-foundation-kernel-safety | integration/foundation-2-kernel-safety | a0699debe42cf880d25ddda57d46c123bc912b4c | CLEAN (tracked + untracked) |
| E:/godot/worktrees/block-girl-foundation-orientation | feat/foundation-orientation-math | 10b1fb1a564c500d58b7d8ecc2343baef74942e3 | CLEAN (tracked + untracked) |
| E:/godot/worktrees/block-girl-foundation-parity | feat/foundation-runtime-parity | e6f7083be9cccef05642a7fcdb7c9f3c2f5870b2 | CLEAN (tracked + untracked) |
| E:/godot/worktrees/block-girl-foundation-rule-kernel | feat/foundation-rule-kernel | 384696f3708504d806c630b7e57a898139780695 | CLEAN (tracked + untracked) |
| E:/godot/worktrees/block-girl-foundation-runtime | feat/foundation-runtime-prototype | aa5362f04dfb0477f7234c8f96bc48773a305de2 | CLEAN (tracked + untracked) |
| E:/godot/worktrees/block-girl-foundation-runtime-saved-closure | feat/foundation-runtime-saved-closure | 7493ab31cf6a71ca9b4778bfe871f33bba2e586d | CLEAN (tracked + untracked) |
| E:/godot/worktrees/block-girl-foundation-runtime-stage-result | feat/foundation-runtime-stage-result | 8f7fb52f029053bda10b965da840c6763fc13bf0 | CLEAN (tracked + untracked) |
| E:/godot/worktrees/block-girl-foundation-softlock | feat/foundation-softlock-analysis | f41fa732bb6e1a0f4e0be3c703e5364bc9aab2e2 | CLEAN (tracked + untracked) |
| E:/godot/worktrees/block-girl-foundation-solver | feat/foundation-state-explorer-bfs | f34dd271adabcc4b724eb55b5fff1cb35f532e59 | CLEAN (tracked + untracked) |
| E:/godot/worktrees/block-girl-foundation-spatial | feat/foundation-spatial-model | ebeabef11adcc5aa588a74ef290748b14a455c3a | CLEAN (tracked + untracked) |
| E:/godot/worktrees/block-girl-foundation-validator | feat/foundation-static-validator | f530e2fe16c64880812b1b20a06504798a477b6b | CLEAN (tracked + untracked) |
| E:/godot/worktrees/block-girl-game-feel-audio | feat/game-feel-audio | 2f98464f4d5349d3ab8463bd4de3c9532c480b0c | CLEAN (tracked + untracked) |
| E:/godot/worktrees/block-girl-game-feel-edge-animation | feat/edge-recoil-animation | 285896da24b4f5ec223fe8bf3f75e29fa1d18381 | CLEAN (tracked + untracked) |
| E:/godot/worktrees/block-girl-game-feel-fall-animation | feat/pfall-animation | 5fdf11e79f0db7f70dbde0d3cbfe6fcee3be098a | CLEAN (tracked + untracked) |
| E:/godot/worktrees/block-girl-game-feel-map | feat/pfall-map | 12a16483c56557aa794a7c1b7f52b2b0a348236f | CLEAN (tracked + untracked) |
| E:/godot/worktrees/block-girl-game-feel-quality | test/game-feel-quality | fd66bfa08099a0bdc7230b2399ee74766ceff3e2 | CLEAN (tracked + untracked) |
| E:/godot/worktrees/block-girl-game-feel-quality-01 | test/game-feel-quality-01 | 13177bb713c229fd5691c1e53cf5ba4d45f2ff76 | 13 entries; see JSON |
| E:/godot/worktrees/block-girl-game-feel-runtime | feat/pfall-runtime | fd22434d3eb0de52a764cb98222371a39412635a | CLEAN (tracked + untracked) |
| E:/godot/worktrees/block-girl-game-feel-ui | feat/game-feel-ui | 3e75c9b135a40f13c83af8f4bb9fe65f87b159e1 | CLEAN (tracked + untracked) |
| E:/godot/worktrees/block-girl-game-feel-ui-extension-01 | feat/game-feel-ui-extension-01 | 2938d6e534f5b596bb320ce79d72b69f5923f3cd | 40 entries; see JSON |
| E:/godot/worktrees/block-girl-l04-inner-movement-p1 | fix/l04-inner-movement-p1 | a80a28b4edafda1faa5be4e890e0b61447afc716 | CLEAN (tracked + untracked) |
| E:/godot/worktrees/block-girl-l06-preproduction | feat/l06-preproduction | d2b78e183839e078c9a28074b2e25359a40608c4 | CLEAN (tracked + untracked) |
| E:/godot/worktrees/block-girl-map-spatial-design | prototype/perspective-fall-01 | d5d63f37af8624f332ed4e9ab90b096cab891ff9 | CLEAN (tracked + untracked) |

此外，`block-girl-game-feel-quality-01` 有 **13 个 staged 测试文件**；`block-girl-game-feel-ui-extension-01` 有 **40 个未跟踪文件**。不擅自纳入、不 stash、不 reset、不清理；它们不在 release candidate 的 Git tree。其余 41 个 Worktree 在快照时无 tracked / untracked 差异（共3个dirty Worktree，其中一个是当前项目根目录）。忽略文件如 `.godot` 缓存不用于判定 Git CLEAN。

## Candidate-external commits

按所有 local branch tips 与 `d1277ec90b5a739efd4862d314e6c29ac5ac1eda` ancestry 比较，去重 **12** 个提交在候选之外。它们仍完整保存在现有 refs；本次不删除也不整合。

| Excluded SHA | Subject | Containing audited branches |
| --- | --- | --- |
| 4c038fa8862322e433a7b19f5db9f4f1b5ced615 | feat(content): build independent L06 greybox from approved design | feat/beta-content-batch-03 |
| 7d4a050c68dd6c9a6527486c1dbded5c61ec0c6d | docs(content): seal L06 greybox validation and integration receipt | feat/beta-content-batch-03 |
| 8a80fbb64eca7e6d7449654f4ace39a35e0f6d41 | fix(map): explain L03 reverse connection world restriction | feat/beta-map-spatial-design, prototype/perspective-fall-01 |
| 821bce29fc94dbed42fafbe3f4a720b4715d4aa3 | docs: add public project readme | feat/foundation-core |
| 7870924423a505eb080b14934489ed50c46a9013 | feat: add foundation 4B-1 editor ports and dock | feat/foundation-editor-tools |
| b6a8064404306851b4ec7d4f61bb39b13ed28361 | feat: connect editor dock to surviving task service lifecycle | feat/foundation-editor-tools |
| 1dab16406bf3c06a48e4e80b6e76324cf73f382b | chore: sync 120 authorized foundation dependency paths | feat/foundation-editor-tools |
| 5a70d13748989c40cf530b1b019e62264dc4b828 | fix(editor): show busy state and retain real acceptance evidence | feat/foundation-editor-tools |
| 98db5f1fdef9b396d786225214d62d1216c17e62 | fix(editor): guard deferred Beta authoring actions | feat/foundation-editor-tools |
| 56b70f96be3a05bb45e20cf90f50d99826af3945 | Document pause text P2 root cause and owner recheck evidence | fix/beta-pause-text-20261009 |
| 13177bb713c229fd5691c1e53cf5ba4d45f2ff76 | docs(qa): record partial UI QA and hand off pause text P2 | main, test/game-feel-quality-01 |
| d5d63f37af8624f332ed4e9ab90b096cab891ff9 | prototype(map): audit perspective fall and request runtime extension | prototype/perspective-fall-01 |

`main` 的 `13177bb` 是四文件 QA 文档提交；不在 candidate 内，需单独决定是否通过 merge commit 保留。Pause P2 owner 记录 `56b70f9` 也在候选之外。L06 **design-only preproduction** 已在 candidate 历史，但 L06 greybox 的两个实现 / 收据提交尚未纳入。不能声称所有 L06 工作都被排除。

## Large-file audit

范围：`git rev-list --objects --all` 的 reachable Git objects；blob 去重；候选 tree 文件计数不去重，因为相同 blob 可能出现在多个证据副本中。这里不扫描 unreachable / reflog-only 历史。扩展名统计按 Git 枚举给出的路径，可能有跨路径复用；未跟踪、忽略、本地外置 build / ZIP 不属于可推送 Git tree。

| Measurement | Size |
| --- | --- |
| Common .git disk usage (metadata + objects) | 219.02 MiB (229659395 bytes) |
| Objects, packed | 173.10 MiB |
| Objects, loose | 23.72 MiB |
| Reachable unique blob logical size, all refs | 421.10 MiB |
| local main tracked tree, all paths | 134.94 MiB |
| candidate tracked tree, all paths | 541.02 MiB |
| Actual primary project disk snapshot, includes .git / .godot / untracked | 598.59 MiB |

Disk usage 是审计过程中的快照，不等于 clone transfer 大小，也不合计其它 43 个 Worktree 的副本与缓存。

| Extension | Candidate paths | Candidate path bytes | Historical unique blob versions | Historical blob bytes |
| --- | --- | --- | --- | --- |
| .blend | 0 | 0.00 MiB | 0 | 0.00 MiB |
| .glb | 28 | 38.22 MiB | 18 | 12.73 MiB |
| .png | 3503 | 187.22 MiB | 1573 | 99.25 MiB |
| .wav | 62 | 64.63 MiB | 62 | 64.63 MiB |
| .mp4 | 0 | 0.00 MiB | 0 | 0.00 MiB |
| .zip | 0 | 0.00 MiB | 0 | 0.00 MiB |

“Large”清单阈值为 **10 MiB**；共 4 个 reachable blobs。全部在候选未远端可达对象中：

| Representative path | Blob SHA | Bytes | MiB |
| --- | --- | --- | --- |
| production/ui/beta_shell_01/fonts/NotoSerifSC.ttf | ae5fdf20ec9c89a3e911dba59f901ba3927bb9de | 25129160 | 23.97 MiB |
| production/ui/beta_shell_01/fonts/NotoSansSC.ttf | cc79aef4ca2dc72d3880c59909d1259596c24eb5 | 17773244 | 16.95 MiB |
| production/experimental/game_feel_01/audio/source/pcm24/bgm_inner.wav | da22399c311a4611eb6634703c3a2b31609afa38 | 10584044 | 10.09 MiB |
| production/experimental/game_feel_01/audio/source/pcm24/bgm_surface.wav | 11418e7a25aaffca1a343d15e7828934dd3bbb3b | 10584044 | 10.09 MiB |

最大 blob **23.97 MiB**；**0** 个 ≥50 MiB，**0** 个 >100 MiB。前30大blob（包含JSON证据与GLB）保存在raw JSON。`.blend` / `.mp4` / `.zip` 在reachable历史与候选tree均为0；外置QA ZIP不应因此被误认为不存在。

GitHub 对普通 Git 超过50 MiB文件发出警告，超过100 MiB阻止提交；本审计没有触及该文件门槛。[GitHub official file limits](https://docs.github.com/en/repositories/working-with-files/managing-large-files/about-large-files-on-github)。这不验证branch protection、credential权限或secret scanning，不保证push必然成功。

### Git LFS proposal — NOT_EXECUTED

本机 Git LFS 3.7.0 已安装；当前 `git lfs ls-files` 为空，root `.gitattributes` 未配置 LFS filter。当前体量不要求为单文件门槛迁移。后续若新增大型 `.blend` / `.glb` / `.wav` / `.mp4` 等素材，可由相关Owner提出新文件的LFS追踪范围，并按账号配额 / 下载需求评估。不要对现有源素材自动转换。

配置LFS会改变 `.gitattributes`，迁移现有历史可能改变SHA；与本任务允许路径和禁止改写共享历史的约束需单独协调。本次没有 `git lfs track`、`git lfs install`、`git lfs migrate` 或任何历史转换。[Official LFS configuration](https://docs.github.com/en/repositories/working-with-files/managing-large-files/configuring-git-large-file-storage)，[existing-file migration](https://docs.github.com/en/repositories/working-with-files/managing-large-files/moving-a-file-in-your-repository-to-git-large-file-storage)。

## Local documentation preparation

本次只更新 `README.md` 和 `docs/release/`，均未stage / commit。原有77个Art文件不纳入审计提交。README纠正旧“Foundation不在main”的描述，并区分 local main、remote main 与 candidate；没有把候选功能说成已同步GitHub。

后续如需整理提交，优先 merge commit 保留既有作者、时间与历史。禁止force-push、公共历史rebase、filter-repo、删除历史以及把多Owner成果重新squash后冒充原交付。

下一步范围与确认边界见 [RELEASE_PREPARATION_REPORT](RELEASE_PREPARATION_REPORT.md)。
