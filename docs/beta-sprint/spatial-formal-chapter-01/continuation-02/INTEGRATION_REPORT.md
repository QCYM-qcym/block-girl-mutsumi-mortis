# SPATIAL_FORMAL_CHAPTER_01_CONTINUATION_REPORT

2026-10-19 / Asia/Shanghai。00 已核验并接收 03、05 的阶段成果及 QA08 receipt。本次只集成新增测试、审计和试玩准备文档；没有修改生产代码，不生成新 Build。

## 身份与交付范围

- 原 Build：`E:/godot/beta-sprint-builds/beta_spatial_formal_chapter_20261019_01`。
- Build Source：`763f0132bc58360fab0e224d0e9c54e00c92ae90`；ZIP SHA-256：`38213cdca4987aff17e39e734e8bf6e0ee2e7d3e5588c749cd4bb1ea7d189307`。
- QA08 receipt：`da78ba930332e6ed33ab1b86210eda0d80ca2adc`，通过正常 fast-forward 接收原四份文档，没有覆盖历史观察。
- 03 Quality：`22b5fc9077a24161e02cf4c87767a83dab63e2ee`，`test/spatial-formal-state-cont02`，5 个新增测试/报告文件。
- 05 Art：`a67f49987ab67ce57409bf8206a378b5f3508b62`，`docs/spatial-formal-art-cont02`，3 个新增审计文档。
- 00 试玩协议：`4adc0d063a970d048f7c6f7666ccb8cf2d47a3b8`，2 个新增协议/空白模板文件。

Owner 两个分支已普通 Push，00 独立查询的远端 SHA 分别匹配。最终集成 Commit 与远端核验在完成本次正常合并后记入外部 `E:/godot/beta-sprint-builds/spatial_formal_cont02_00_20261019_01/FINAL_DELIVERY.json`，避免自引用提交哈希。无 main / Release Tag 写入。

## State Graph：PARTIAL

本轮使用正式 saved Maps.bake、StateExplorer FULL_GRAPH 和同一内存图上的 SoftlockAnalyzer。图域是 **稳定公共动作、到首次 Goal 为止**；不是包含 UI、动画中断、Busy/Cancel 或任意非法字典的完整 Runtime 状态空间。

| 地图 | 已发现状态 | 转换边 | 动作评估 | 本轮结果 |
| --- | ---: | ---: | ---: | --- |
| S01 世界转换点 | 16 | 56 | 108 | 此 Goal 终止图完成；软锁 0 |
| S02 六面回环 | 51 | 246 | 480 | 此 Goal 终止图完成；软锁 0 |
| S03 接触之面 | 104 | 472 | 828 | 此 Goal 终止图完成；软锁 0 |
| S04 视角岔路 | 80 | 264 | 768 | 此 Goal 终止图完成；软锁 0 |
| S05 六面归位 | 418 | 1666 | 4035 | 200 秒搜索预算耗尽，PARTIAL |

S05：355 个已发现状态有到达 Goal 的证明，63 个已发现状态尚无证明；56 个非 Goal 前沿状态未展开。软锁总数、仅 Reset 可恢复总数、完整可达状态数和总体覆盖率均为 UNKNOWN，不能填 0 或 100%。已找到 7 步最短 Goal 路线不等于完整搜索通过。

每图限制 2500 状态、15000 边、30000 次动作评估；S01–S04 搜索时间各 110 秒，S05 为 200 秒，Analyzer 各 15 秒。全部 9 个 Godot 进程累计 407.141 秒（含准备和保留的失败尝试），低于 850 秒总预算。5 次采纳运行共 333 项断言通过；S01–S04 exit 0，S05 exit 3 表示预算 PENDING；五次 stderr 均为空。不能把 S05 exit 3 改写为完整验收 exit 0。

五图各完成一次实际 Runtime 最短路线 Goal 和该 Goal 的 Reset；不是每个状态的 Reset 穷举。已检查到的转换满足 World Shift 权限、Face Lock 接触面/锁存、Camera 物理状态不变、Fall 目标/Orientation/World 和 Fork 权限格不重叠。捷径检查只覆盖指定 target_a/goal 区域的非 Fall 入口，不代表所有设计捷径均排除。

167 个依赖绑定当前 Build/源提交及旧 Closure04。旧 908 状态 / 4300 边证书仅单列历史参考，不合计本轮断言，不冒充本轮完整图。00 另行核验 75 份原始证据哈希及图节点/边计数。见 [Quality 报告](quality/REPORT.md)、[结构化结果](quality/RESULTS.json)。

S02/S04 首轮在搜索完成后的测试属性检查中读取不存在的可选字段；已修复测试并在新目录复跑。原失败日志保留，无 Runtime 修改。未确认新的 Gameplay 缺陷；S05 未覆盖范围仍无法排除缺陷。

## Art Files：只读核验完成；Recovery：PENDING

三个当前文件及事故后备份与上轮一致，均不匹配原始 Manifest；没有原版字节可用于精确恢复。00 独立复算六个当前/备份文件哈希。

SVG 的说明文字及横闩位置变化有事故后生成脚本和当前 SVG 坐标佐证；两个 PNG 均可完整解码，但缺少原字节，无法区分像素/元数据/压缩差异。状态 PNG 来自 SVG，contact sheet 依赖 28 张索引图，27 张仍匹配原清单。不能据此断言 contact sheet 只有一个区域变化。

精确路径、原/现/备份 SHA、生成依赖和逐文件恢复前置条件见 [Art 审计](../art/continuation_02/ART_AUDIT.md)。事故后备份仅保护修改后的现状，不是原版来源。没有执行恢复、覆盖、删除备份或重新导出。正式 Build 的静态路径/内容哈希扫描未发现三项资源引用；静态检查不是运行时 I/O 的完整证明。

Floating Cube：**PENDING_USER_REVIEW / PROPOSAL_ONLY**。A/B/C 对照保持不变，未删除遮光体或改变通行规则。

## Human QA 与输入环境

**HUMAN_QA = NOT_RUN**，当前无合格独立玩家。[试玩协议](HUMAN_QA_PROTOCOL.md)和[空白会话模板](SESSION_TEMPLATE.json)已准备，沿用并保留 QA08 原五关观察表。不存在本轮玩家原话、规则发现时间或实际完成结论。

Input Environment：**QA08-ENV-INPUT-01 unresolved / 本轮图形诊断 NOT_RUN**。只读查询时原隔离 QA 进程 PID 32312 仍在运行；本轮未抢焦点、发送输入或关闭它。03 只启动隐藏 Headless 隔离测试，不属于图形输入排障或真人试玩。后续须按协议先建立可归因的独立窗口/输入时段，再恢复图形诊断；不能把历史工具干扰归类为 Gameplay 缺陷。

## 保留与下一步

本轮开始核验原 Build 1783/1783 项 Manifest、ZIP 哈希和 QA08 3 张交付截图一致；原包没有 qa-profile。最终保留核验记录在外部证据目录。旧包、QA 证据、玩家/测试原存档、冻结美术、main、Release Tag 保留。

New Build：**NOT_REQUIRED**。Production Changes：**NONE**。本次只是证据与测试交付，不能宣布 Beta 总验收完成。下一步分别处理 S05 未覆盖前沿、合格玩家实际观察、Art 原版候选和用户视觉方案选择；互不阻塞已独立完成的阶段。
