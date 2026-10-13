# SPATIAL_PUZZLE_BATCH_01_POLISH_REPORT

2026-10-13 · 00 Integration · branch `feat/spatial-puzzle-batch-01`.

| 项目 | 实际结果 |
|---|---|
| Input P1 | CLOSED，保留前轮关闭决定，未重开方向矩阵 |
| Goal Reset P2 | **CLOSED** — QA08-C02-UI-RESET-LABEL-01 |
| UI Regression | 07 headless 196 PASS；00集成 headless 196 PASS；08新包真实图形 279+34=313 PASS、43张原帧 |
| Floating Cube | 原版/A/B/C × 四视角 × 两尺寸，32张真实静态对照；提案已审阅，PROPOSAL_ONLY |
| Art User Approval | PENDING；A优先继续评审，B暂不推荐，C作为显式教学备选 |
| Art 3 Changed Files | 精确身份已核验，当前均等于事故后备份但不等于原清单；无缺失，均可解码/解析 |
| Art Recovery | PENDING；没有执行恢复、覆盖或重新导出 |
| State Graph | PARTIAL；新335项有界恢复检查通过，保留历史908 states / 3916 edges证据范围 |
| Human QA | NOT_RUN，用户确认暂时没有合格独立玩家 |
| New Defects | 本轮定向范围未发现新增生产缺陷；旧可读性问题保留 |
| Foundation / Save / L01–L05 / frozen Art changes | NONE |
| Main / Release Tag | 未修改，本地与远端受保护引用核验一致 |

## 修复与实际验证

根因：键盘R直接进入Host/Runtime Reset，而菜单只通过鼠标Reset入口清理完成标记；原Goal回调缺少正式run/generation校验。唯一生产差异在 `experiments/spatial_puzzle_batch_01/ui/main.gd`：订阅Runtime committed，根据正式session/run/generation改变清理本轮完成展示并重新绑定Goal回调；拒绝旧Host/scope/state回调。未按文案内容硬编码隐藏，未实现第二套Goal判定，未改正式持久完成记录。

[07交付](../ui/polish_03/HANDOFF.md)保留真实RED：30检查/4预期失败；最终196检查通过，exit0/stderr0。其他初始Harness假设失败和修正均保留，未算作生产Bug。[00集成收据](UI_INTEGRATION_TEST.json)再次在合并源码实际执行196检查，0 failures/doubles/stderr/source drift。

[08新包图形报告](qa08/POLISH03_GOAL_RESET_QA.md)：1280×720、Windows/D3D12 Forward+，实际Input.parse_input_event经过正式菜单/Host，自然动画；不是真人或OS物理键盘验收。Goal→R清除→再次Goal、鼠标Reset、连续Reset、退出重入、Shift/Camera以及Roll/Shift/Camera/Fall各自Reset/退出的八例取消通过。两成功进程PID28620/24660均自然exit0/stderr0。Roll/Fall中分别六次R补测通过。

自然取消后每例观察1秒；真实过期回调到达是NOT_OBSERVED，未用伪Goal或手工finish填补。旧scope拒绝另由07负向技术探针证明，不能混成图形迟到回调穷举。初次08入口类型解析失败、未执行Gameplay，日志保留。00核验[67项外部清单](qa08/EVIDENCE_MANIFEST.json)，查看Goal/R/再Goal原帧及取消、快速Reset对照；仅收纳三份匿名交接文件，未上传profile或整包截图。

正式关闭决定见[DISPOSITION](DISPOSITION.json)。不扩展为旧五关全验收、其他分辨率、Cold Continue或首次玩家理解PASS。

## 悬空方块提案与资源调查

[32张原帧浏览页](E:/godot/beta-sprint-builds/QA/art_preview_polish03/run_20261013T143919247369Z/REVIEW.html)，[05报告](../art/polish_03/ROOF_PREVIEW_REPORT.md)，[09实际审阅](../map/polish_03/ACTUAL_SOURCE_COMPARISON_REVIEW.md)。05真实预览261检查通过，09只读复核，二者不重复累计；[00绑定](ART_REVIEW_BINDING.json)核验同一运行收据、32图摘要、3份预览脚本。

A的不透明粗纹区分于道路，但暗侧偏弱，材质不同仍不等于玩家知道不可走。B封闭顶框更像机关/踏板，暂不推荐正式采用。C说明用途且当前帧未挡主要物体，但属于辅助教学。没有删除roof、修改walkable或增加道路。两尺寸均高720，同一正交尺度，不能宣称已验证更小物体尺寸。只覆盖Surface/source静态状态；gate站位、Shift/返回、Reset、连续动态过程与真人理解仍未验收。Q0/Q3标签压住角色及暗面数字难读属于原样已有观察，保留可读性风险，不列为新P1。

[三文件精确恢复建议](../art/polish_03/THREE_EXPORTS_REVIEW.md)及JSON保留全部原/现/备份SHA：

- `E:/Study/方块娘项目/若叶睦/model/art/production/work/GAME_ART_MECHANICS_BATCH_01/design/states/face_lock_D.svg`
- `E:/Study/方块娘项目/若叶睦/model/art/production/work/GAME_ART_MECHANICS_BATCH_01/design/states/face_lock_D.png`
- `E:/Study/方块娘项目/若叶睦/model/art/production/work/GAME_ART_MECHANICS_BATCH_01/reports/DRAWING_CONTACT_SHEET.png`

SVG坐标与事故后的两处脚本布局修改一致；PNG原字节不可得，无法严格分离像素/压缩/元数据变化。不能把三项差异都称为仅元数据或资源损坏。事故后备份不是原版恢复源；原哈希副本在前轮有界搜索中未找到。旧正式包清单无三项同名/相同字节资产，生产文本和已检查静态入口闭包未找到引用；文档里的审计路径不等于资源加载。新包生产资源未改变，亦未纳入三项导出。优先寻找匹配原哈希的可靠来源；重建候选和覆盖原文件均需针对清单授权，本轮未执行。

## 有界状态图

[03最终报告](../quality/polish_03/FINAL_REPORT.md)：实际错误FaceLock状态由正式Solver找到9步恢复；Fork禁止视角状态3步恢复；Reset后同一Runtime实例7步到Goal。20次显式Safety查询，3次正式LogicalReplay匹配27步。最终335检查/exit0/stderr0/doubles[]，不重复累计首轮335或旧2225。2项Harness护栏Unit使用明确tests-only double，单列，不计Real。

每次局部搜索预算512 states / 5000 edges / depth32 / 10000 action evaluations / 120s，分别89和21 visited states，找到首条最短路径后停止，图不完整；本轮实际重放11个原图StateKey/13条不同原图边。历史908/3916仅在Goal-terminal正式动作域内穷尽并无软锁，整体Runtime/post-Goal分母、所有Reset-only状态、全部非设计捷径仍UNKNOWN。03只改测试和文档；[00核验2189项Git输入绑定](QUALITY_BINDING.json)，集成侧仅UI修复与包metadata不同，均不由该Runtime恢复Harness加载。

## 构建与Git身份

新包：`E:/godot/beta-sprint-builds/beta_spatial_polish_03_20261013_01`。

启动：在该目录PowerShell执行 `./play.ps1`，需要Godot4.7.2；默认使用包内独立qa-profile。SOURCE_PLAYABLE，不冒充独立exe导出。与08自动QA使用的副本/profile分离。

Build Source：`f26ea4b19da836d65eb7d981dbf22f4022045b01`。
ZIP SHA256：`463ad3429910e8b5c765164b4ca3658cb6ffd245284d52690574afe9fafd50dc`。
[Build核验](BUILD_VERIFICATION.json)：1707文件、1555精确Git blobs、150imports；候选Art预览代码未打入包。

Owner交付已正常Merge，未squash/rebase/cherry-pick：

| Owner | 已核验远端交付SHA |
|---|---|
| 07 | 827dc0f18998df41438a8951428051b2baf28b5b（生产修复3ec21b52e8407bc7a7ceeb89493a075a22325552） |
| 09 | aa7f49738f329c10daabcc75cf595b5180762f77 |
| 05 | 0cd36840466bc50e03d7c793eb4decfc478f16ef |
| 03 | f91eb0c94b6318ccd838aab010da233c4c50bb73 |

全部Owner合并后、此关闭收据之前的Integration内容提交：`c1c1dc3f5b8c9f9531cb871d765cab6e10cf677d`。Build在后续文档/测试证据合并前已固定，后续没有改变任何包内生产代码。

此文件是Push前生成的关闭收据，不预填尚未发生的Push成功。最终收据Commit、正常Push和独立远端SHA验证见最终聊天交付及 [实际发布记录](E:/godot/beta-sprint-builds/spatial_polish03_00_delivery_20261013_01/PUBLICATION.json)，该记录仅在操作成功后生成。绝不Push main、force或改Release Tag。

[保护检查](PROTECTION_CHECK.json)：61项事故路径无新变化，旧QA包1641文件及ZIP不变，main/release/tag引用不变。旧存档、截图、日志、用户进程未改动；本次只向所属集成分支交付。Human QA仍NOT_RUN；部分状态图和未批准视觉方案保持原边界。
