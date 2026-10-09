# Content Batch02 implementation plan and ledger

Spec: DESIGN.md. Inline执行 writing-plans / executing-plans / test-driven-development；用户直接BUILD覆盖二次批准门槛。使用已存在隔离Owner工作树，无需创建新树。

## Tasks

1. [x] Unit RED: 两个目标Scene缺失；保留实际PID/退出码/错误报告。
2. [x] 创建L04/L05 .tres/.tscn，复用现有ContentLevel/data/state和两个现有Presenter；只新增本批提示/工厂选择。
3. [x] Unit GREEN：真实mover路线、mandatory blockers、Reset和每个可达状态可解。
4. [x] Real headless：真实Input→GridInput→原Runtime→Goal committed及原adapter.completed；正常/Reset后/视角不同三条路线，动作中R和数据SHA。
5. [x] 提供graphical同脚本执行入口；实际图形验收PENDING，由00在最终集成执行。
6. [x] 独立只读代码审查、修复唯一Important；Stable IDs/catalog已发布。
7. [x] 生产候选已提交d4be39c，提交后CLEAN；FilesSHA/receipt随交付记录提交，最终状态由receipt提交后的git status核验；PushNOT_RUN。

## Review focus

两次/四次Shift与连接/门必须真有必要；Surface/Inner缺地面不可绕过。提示不把Inner连接说成Surface。门维持原占格开关时序。R清空转场/held输入和Goal；Goal事件必须来自落定并且每次一次。所有3D/旧资源保持原hash，灰盒不声称最终美术或图形验证通过。

## Ledger

Baseline只读：HEAD匹配指定b910167，工作树初始CLEAN，未发现本工作树AGENTS.md。公开Runtime仍P01，不是Foundation RuntimeSession。定义/提示/Presenter对四关前接口兼容，本批只按冻结坐标制作。

| Run | PID | Exit | 实际结果 |
|---|---:|---:|---|
| unit_red | 19968 | 1 | 2项Scene缺失，预期RED |
| unit_green_01 | 14028 | 0 | 旧地图39项通过；非最终依据 |
| import_01 | 31016 | 0 | headless导入通过，精确恢复冻结SVG的.import |
| real_01 | 32660 | -1 | typed Array夹具配置错误；核对进程路径后只终止该PID，未用于验收 |
| real_02 | 14000 | 0 | 旧地图206项/六路线通过；审查后被替代 |
| unit_bridge_red | 11584 | 1 | 两世界各两桥格，共4项真实支撑失败 |
| unit_bridge_green | 48660 | 0 | 地图修正后43项通过，68/68与100/100可解 |
| unit_final | 32756 | 0 | 45项通过，额外证明最少切换次数2/4 |
| real_03 | 48780 | 0 | 206项/六自然路线/六正式回调通过，0失败 |

独立Reviewer只读审查发现一项Important：L05复用L01 Presenter，但旧地图未声明其固定桥的 `(1,0)` / `(2,0)` 支撑。按 receiving-code-review 验证了源码行为，先加断言复现RED，再只调整本批地图、出生点与提示，保留四次必须的切换。最终Unit/Real均GREEN；不将此前无图形的逻辑通过当作视觉正确的证明。

00后续明确允许Owner-local候选在Unit/Real GREEN后交付并供07登记，不因图形槽等待阻塞；图形仍由00/08独占，本工作树未启动图形用例。生产Foundation、共享Runtime/Presenter、旧三关、Shell/Save及冻结Art改动为NONE。
