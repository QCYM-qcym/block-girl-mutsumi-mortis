# UF002：方向反馈与技术控制缺陷分层

登记时间：2026-10-13 21:12:25（Asia/Shanghai，登记时间，不是用户操作发生时间）。继续保留 [UF001](USER_FEEDBACK_001.md) 中头顶块问题及未知上下文。本条不提供玩家解法，不修改机制设计。

## 用户原话与来源

> 北和东不行

来源：00转交，13已只读核对00聊天实际用户回复。source_thread_id=01a11125-280e-7403-98f9-98b92911c8f7；turn_id=01a13547-835b-7402-b23c-5884a7b30893；user_item_id=01a13561-3ca4-72c1-b799-81ed43532288。原提问是在询问Inner东视角四键都不动还是某方向不通；此回答本身只说明用户报告“北和东不行”，不能单靠它断言四键逐项均试过、地图名、资格或完成。

该原话为USER_REPORTED_OBSERVATION，不是自动测试记录。没有动作前预测、具体方向输入过程、机制解释或迁移的原话，H1–H6均不能确认。

## 独立技术证据：SPATIAL-CARDINAL-01

00已提交固定证据版本89ebf7a60e405d7617298e49a3f43e3461e38376。13读取真实 [report.json](E:/godot/worktrees/block-girl-spatial-puzzle-batch-01/docs/beta-sprint/spatial-puzzle-batch-01/acceptance_01/diagnostics/report.json)、[process.json](E:/godot/worktrees/block-girl-spatial-puzzle-batch-01/docs/beta-sprint/spatial-puzzle-batch-01/acceptance_01/diagnostics/process.json)、探针源码及日志，并按原始行汇总；没有由13重跑。SHA及范围见 [来源清单](SOURCES.json)。

| 技术字段 | 固定收据中的实际内容 |
|---|---|
| 探针执行身份 | process记录HEAD a9ecfb46f1a2d4efd20042586fbc690066cabfaa；89ebf7a为证据提交，不替换执行HEAD |
| 地图/状态身份 | world_shift_gate_lab；content_hash=7a636b38301dff74027b2d5e80364d30b943b24f961cd73a2179b9ee7798acd4；Inner的inner_gate与goal两处 |
| 调用链 | 正式保存作者地图/Baker→spatial Host→Facade.request_move屏幕方向向量→自然Presenter等待完成；非mock、无注入state或手动完成 |
| 运行方式 | --headless；report display=headless；不是OS键盘输入、真人试玩或实际渲染收据 |
| 尝试 | 2位置×4Camera×4方向=32次请求；NORTH0/EAST1的4组，每组W/A/S/D只覆盖face_axis0/2，全部拒绝2000，StateKey不变 |
| 对照 | SOUTH2/WEST3的每组覆盖0/1/2/3四轴，各有一个合法移动；不是四键都应合法，无效边仍由正式规则拒绝 |
| 失败与退出 | report.failures有4项zero accepted directions；exit_code=1，host_issues=[]，不能把空host_issues写成整个run PASS |
| 日志限制 | stderr133字节，原文警告为“8 ObjectDB instances were leaked at exit”；8是泄漏实例数，不是8条独立警告。原stderr、失败及探针均保留 |

字节身份分开：process记执行脚本的原始CRLF摘要及原始stderr133字节；Git证据为LF规范化blob，stderr131字节。探针Git blob按CRLF重建后摘要与process.script_sha256一致，stderr按CRLF重建后为133字节。来源清单保存Git blob摘要，不伪装为原始执行文件摘要。

技术判定：已复现输入映射控制缺陷SPATIAL-CARDINAL-01，00分级P1并交01定向修复。它解释特定技术条件下没有合法键盘方向请求的症状；不能归因于玩家不理解规则，也不能凭此证明正式动作状态图有不可恢复Softlock。实际根因/修复选择由01与00负责，本记录不替代实现诊断。

01的fix/spatial-cardinal-input-01修复中（00派发状态）；本次没有接收修复提交/新包复验，FIX_ACCEPTANCE=PENDING。旧包不修改，旧失败不能回填PASS。此故障也不要求重设计四机制或改地图解法。

## 环境关联与尚未确认的范围

00另报告：用户活跃进程命令行指向本轮isolated/run/project，profile近期level_id为world_shift_gate_lab并有completed记录。13本次没有独立读取用户进程或存档；保留为COORDINATOR_REPORTED_CONTEXT，而非用户明确回答或首次玩家独立通关证据。诊断process的工作树/独立profile与用户活跃进程是不同来源，不混为一次执行。

技术地图确有非walkable的roof（收据列于Surface）。用户仍未确认所说头顶块的对象，因此不将其指定为roof，不推定无法到达一定正常，也不认定此输入缺陷已解释全部头顶块疑问。该问题继续UNIDENTIFIED_TARGET。

玩家本人或首次玩家、解法/提示暴露、资格、操作时间、动作前预测及实际完成仍待确认。completed存档不能替代这些字段。当前Human QA=PARTIAL_USER_FEEDBACK，FIRST_TIME_COMPREHENSION=NOT_VERIFIED，H1–H6=NOT_OBSERVED。

认知报告原R6是专家风险假设；此次技术复现必须单列为控制缺陷，不能把受该故障影响的卡点记为认知失败。修复后若要重新评估首次理解，必须考虑已尝试/已暴露造成的学习历史，不能把重试自动当首次体验。

Godot changes=NONE，GUI=NOT_RUN；13本轮只读证据，Runtime/Solver/Safety/Replay/Graphical=NOT_RERUN。新增认知记录Integration=PENDING_00。
