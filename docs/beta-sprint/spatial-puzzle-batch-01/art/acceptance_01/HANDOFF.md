# 05 → 00 · 原型可读性验收交接

- Task：`SPATIAL_PUZZLE_BATCH_01_ACCEPTANCE_01`
- Owner：05 Art，当前原型只读审查。
- Worktree：`E:/godot/worktrees/bg-spatial-art-accept01`
- Branch：`docs/spatial-art-acceptance-01`
- Base SHA：`d3b131440600048006ccc7679962fb7fc546a63f`
- Build Source SHA：`59531adcdffb7a8671bd6aab9a2abdc6fa830b04`
- Remote：`https://github.com/QCYM-qcym/block-girl-mutsumi-mortis.git`
- 唯一交付范围：`docs/beta-sprint/spatial-puzzle-batch-01/art/acceptance_01/**`。
- Local Commit：包含本交接文档的提交；精确完整 SHA 在阶段最终回执给出，可用 `git log -1 --format=%H -- docs/beta-sprint/spatial-puzzle-batch-01/art/acceptance_01/HANDOFF.md` 查询。

## 可接收成果

1. [ART_READABILITY_ACCEPTANCE_REPORT.md](ART_READABILITY_ACCEPTANCE_REPORT.md)：四机制、综合图、local_face→数字映射、P0–P3及证据分层。
2. [CAPTURE_AND_HUMAN_QA.md](CAPTURE_AND_HUMAN_QA.md)：补证需求与真人观察项，供 00/08 使用；观察者资料包含答案，不能直接发给首玩玩家。
3. [SOURCE_MANIFEST.json](SOURCE_MANIFEST.json)：26 张已查看 PNG、9 项直接引用源码及历史记录来源、只读哈希核验。
4. [VALIDATION.json](VALIDATION.json)：本次文档、来源、路径及范围检查结果。
5. [SCOPE_DEVIATION.md](SCOPE_DEVIATION.md) 与 [EXTERNAL_WRITE_MANIFEST.json](EXTERNAL_WRITE_MANIFEST.json)：外部越界和未完全恢复的残留，必须单独阅读；不是验收资产。

## 验证与边界

本次 PASS：immutable Build 的 1,561 项清单哈希；两个历史进程各 409 项来源哈希；menu 24 张原始 capture 记录哈希和尺寸；26 张审图 PNG 与基线 Git 原字节；文档链接/JSON/提交路径检查。精确检查时间见 VALIDATION.json。

历史 219/208 checks 仅作来源证据，未重跑。Godot GUI、完整四视角状态矩阵、真实玩家理解、自动图遍历和 Gameplay 回归在本 Owner 本轮均 NOT_RUN。真人可安排但尚无观察结果，Human QA 不得填 PASS。

Stage Status：**PARTIAL**（证据审查文档完成；完整可读性与真人验收待补）。Integration Status：**PENDING_00**。

审图/源码确认 P0=0、P1=0、P2=3、P3=0，不等于全游戏故障总数。A01 边缘标签与面号相叠；A02 暗侧面数字弱；A03 锁存替换目标文字仅有源码确认，待 Surface 状态截图。没有产品修复提交，不要求因本次文档单独生成新 Build。

所有未批准 Art：**PENDING_USER_REVIEW**。没有接入旧设计包、生成新正式美术或改 Runtime/Map/UI。**过程存在外部越界**，有限恢复后仍需处理 59 个导出文件，不能笼统写“全程仅文档无外部修改”。当前 Build 与本分支生产文件不受该外部排版操作影响。

## Git 交付与下一步

采用普通唯一分支 Push：

```powershell
git -c push.followTags=false -c remote.origin.mirror=false push --no-follow-tags --set-upstream origin refs/heads/docs/spatial-art-acceptance-01:refs/heads/docs/spatial-art-acceptance-01
git ls-remote --heads origin refs/heads/docs/spatial-art-acceptance-01
```

本文件在提交前编写，不预先声明 Push 或远端核验成功；完整本地/远端 SHA、核验时间和最终工作区状态以本阶段最终回执为准。没有 PR、main、Tag、Release 或集成分支修改。

请 00 审查证据与范围偏离记录后选择是否正常集成文档；补证安排由 00 协调，不占用玩家 GUI。实际缺陷需复现并明确归属后才安排 00/07/05 的最小修复。01/09 的 Runtime/地图合法性无需因本报告重写。真实玩家结果由 08 提供，13/00 再结合观察作机制理解结论。
