# SPATIAL_FORMAL_CHAPTER_01_HUMAN_QA_REPORT

Stage: PARTIAL. Human QA: NOT_RUN. 用户已确认暂无合格首次玩家。下列 agent Computer Use 观察不属于真人理解性证据。

## Build 身份

- Build: E:/godot/beta-sprint-builds/beta_spatial_formal_chapter_20261019_01
- Actual Build Source / Integration SHA: 763f0132bc58360fab0e224d0e9c54e00c92ae90。
- ZIP SHA-256: 38213cdca4987aff17e39e734e8bf6e0ee2e7d3e5588c749cd4bb1ea7d189307。
- 1783 个清单文件的字节数及 SHA-256 全部匹配；其中 1631 个 git_source 文件独立比对该提交 Git blob ID 全部匹配。首次树导出对三个中文文件名进行了转义，导致查找未命中；使用 core.quotepath=false 重新导出后全部匹配，未修改任何源码。这是证据解析问题，不是构建差异。
- 观察后再次核验原包与副本，各 1783/1783 匹配；原 ZIP 哈希未变。
- 入口：play.ps1 → project/project.godot → res://game/shell/game_feel_shell.tscn。包的 source_receipt 为 null；本次通过独立 Git 内容比对确认来源。
- 实际启动日志：Godot Engine v4.7.2.stable.steam.ed1daf0bf；D3D12 Forward+；NVIDIA GeForce RTX 5060 Ti。
- 原 play.ps1 只读检查，未原地运行，避免在原包内生成 qa-profile。启动外部完整副本的同一 project，APPDATA / LOCALAPPDATA / TEMP / TMP 全部指向新的外部 profile。未复制、删除或编辑真实玩家存档，未制造解锁。
- 外部证据目录：E:/godot/beta-sprint-builds/spatial_formal_qa08_20261018T174440Z。UTC 时间对应北京时间 2026-10-19。

## 实际观察及停止原因

Computer Use 已观察新存档主菜单，并成功点击关卡选择。L01 可试玩，L02–L05 锁定，Continue 无可继续进度。后续截图可见 S02–S05 名称及锁定状态；第 06 行锁图标可见，S01 标题位于当前滚动可见区域上方。仅确认这些菜单显示，不证明章节进入或解锁正确性。

两次滚动调用均报告：`user input was detected in this window; call get_window_state before continuing`。两次之间已重新观察。列表位置变化无法可靠归因于 agent。重复报告后已停止输入。最后一次截图混入无关前台应用，排除出 QA 结论和 Git 交付，未操作该应用。

最后进程查询确认本轮 PID 32312 仍在运行；出现干扰后未操作或强制关闭该窗口。退出、保存进度、冷重启均未测试。后续应在窗口交互稳定后恢复隔离测试；不得把外部改变的状态当作已完成 QA。

启动请求 1280×720，但截图包含窗口装饰，不是客户区 / viewport 实测。三个尺寸均不标 PASS；1920×1080 与 960×720 未启动。工具返回的 JPEG 初始使用了 .png 后缀，已另存字节相同的 .jpg 副本用于证据引用，未修改图像。混入其他窗口的截图不在可交付证据清单内。

## 正式结果

| 项目 | 结果与边界 |
| --- | --- |
| L05 → S01 | NOT_RUN；未达到正常通关后的章节入口 |
| S01–S05 Progression | NOT_RUN；仅观察锁定菜单 |
| Human QA | NOT_RUN；无合格玩家 |
| First-time Comprehension | 五图全部指标均为“未观察” |
| 章节 Pause / Resume / Reset / 返回菜单 | NOT_RUN |
| Save / Cold Continue | NOT_RUN；未测试进度保存与第二个进程 |
| Softlocks / Shortcuts | NOT_ASSESSED；无章节 gameplay 覆盖 |
| P0 / P1 / P2 / P3 | NOT_ASSESSED / NOT_ASSESSED / NOT_ASSESSED / NOT_ASSESSED；不写零缺陷 |
| Art Approval | PENDING；08 未进行美术批准 |
| State Graph | NOT_RUN by 08；继续由 03 单独负责 |
| Production changes | NONE |

## Known Issues 与 Owner Handoff

QA08-ENV-INPUT-01：TEST_TOOL_ENVIRONMENT，不属于游戏 P0–P3。

- Build SHA：763f0132bc58360fab0e224d0e9c54e00c92ae90。
- 步骤：启动隔离副本 → 正式 Level Select → 尝试滚动列表。
- 预期：一次可归因的窗口输入与刷新截图。
- 实际：两次输入调用均检测到外部输入，随后截图出现无关窗口覆盖。
- 证据：截图 01–03、PROCESS.json、本报告记录的原始工具错误。
- 频率：本轮两次滚动调用均报告；未声明其他会话必现。
- Owner：08 / 执行环境。待窗口交互稳定后继续；不得因工具问题转交为 gameplay bug。

00 保留正式章节候选包待验收状态，接收本 PARTIAL 报告。08 补测正常进度链及真人观察。03 将状态图结论独立绑定本次实际来源。05 的美术审批与 Handoff 中的外部资源恢复事项继续独立 PENDING。没有新 gameplay 复现，不向 01/07 提交游戏缺陷；旧 Input P1 / Goal Reset P2 关闭记录保留，不重新打开，也不自动扩大到新包。

未读取作者解法或通关路线，未重跑或采用 Owner 自动检查充当 Human QA。旧五关与实验地图结果不转记本包。

## Git 交付

Owner 分支、明确文件边界见 TASK_SCOPE.md。仅交付报告、结构化结果和空白观察表；原包、存档、原始日志、截图、缓存及无关窗口截图均不上传。Commit / Push / 远端 SHA 独立查询结果在实际执行后写入外部 FINAL_DELIVERY.json。Integration 保持 PENDING_00，不合并 main、不创建 Tag 或 Release。
