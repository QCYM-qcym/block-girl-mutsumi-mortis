# L04_INNER_MOVEMENT_P1_FIXED

2026-10-09，Asia/Shanghai。Owner：**06 Game Content**。基线991140292ac67e87d1751a062e7e96c7b9fee553；独立工作树E:/godot/worktrees/block-girl-l04-inner-movement-p1；分支fix/l04-inner-movement-p1。

Root cause：L04的Inner Spawn `(1,5)` 是没有四邻支撑的孤立格。正式Shift合法落定后，所有方向输入都到达原Runtime；原graph.neighbor返回原格，GridMovement没有启动roll，提交数为0。不是根据画面静止推测；正式Shell与独立Scene、短按与持续均有失败回归。实际合同与逐方向证据见DIAGNOSIS.md及原始report.json。

唯一生产修复：L04 `inner_cells` 增加 `(0,5)`，把Spawn接到原岸边 `(0,4)`。原Runtime正常允许短按A到新格，继续原Inner道路、EAST连接与Surface Goal。旧其它三方向仍按支撑规则拒绝。没有改公共移动、Shift/连接/Safety/Kernel规则、传送或强制动画提交；没有改其它关卡。

Before：world=graph_world=1、view=NORTH、phase=idle、pose原值；四方向短/长8条均input_received=true，neighbor=(1,5)，transition_started=false，commit_count=0，Before/After实际P01状态序列化相同。PID32572（正式Shell）、PID18004（独立Scene），两条精确回归均exit1。

After：相同短按A、相同原输入链，neighbor=(0,5)、roll开始、1次原committed，落定cell=(0,5)，物理orientation正常滚转。PID28988（正式Shell）59checks / exit0 / 0失败；PID29152（独立Scene）55checks / exit0 / 0失败。状态键与published字段限制明确见DIAGNOSIS，不冒充Foundation StateKey或Safety verdict。

## 完整实际验收

| 项目 | 结果与证据 |
|---|---|
| L04正常完整通关 | PASS；headless与图形各一次，从正式Spawn先Shift |
| Reset后完整通关 | PASS；headless与图形各一次，另检查移动/Shift/视角中、按住方向时及Goal后R |
| 不同camera顺序通关 | PASS；出生先转SOUTH，按当前视角映射世界方向；用Q回到EAST连接，落定后再次转SOUTH |
| Goal | PASS；每次真实Surface落定phase=complete，原Shell level_adapter.completed恰好1次 |
| 正式Shell进度保存 | PASS；新PID测试profile校验有效，真实完成回调保存L04并解锁L05；非Human五关链 |
| 最终headless自然输入 | PID13392，exit0，201checks，3routes / 3formalGoals，0失败 |
| 图形自然输入 | PID30536，exit0，D3D12 Forward+ / RTX5060Ti，219checks，3routes / 3formalGoals，18截图，0失败 |
| World Shift / Perspective / Reset | 原条件与动作锁保持，错误世界/缺支撑仍拒绝，四视角严格90°且保持物理pose |
| 3D Presenter | 原Presenter收到roll，动作中actor位置改变，落定basis匹配原cube；已人工查看新增格与Goal原始截图 |
| 无意捷径 / 可恢复性 | 既有原图Unit45项PASS，L04 72/72可达状态可到Goal，minShift仍2；原Surface路线保留 |
| Foundation / Art修改 | NONE |
| L01–L03 | LIMITED_INPUT_REGRESSION_PASS；修复前PID6748、修复后PID19592各259项/48短长方向对照PASS，源码和资源不变；未重跑全面旧通关 |

三条路线世界坐标：Spawn `(1,5)` Shift Inner → `(0,5)→(0,4)→(0,3)→(0,2)→(1,2)→(2,2)→(3,2)` → Inner EAST连接 `(9,2)` → `(10,2)` Shift Surface → `(11,2)→(11,1)` Goal。NORTH起点最短键序：`Space, A, W×3, D×3, E, W×2, Space, W, A`。自然验收额外测试错误世界与操作锁，不依靠Reset跳过路线。

旧Unit的状态查询是明确隔离的query-only原图审计，不是自然输入证明。Owner完整通关使用真实InputEvent，经原GridInput/Runtime，未直接赋值游戏state或复制玩法判定。全新测试profile设选关资格明确标记测试设置；没有操作QA旧profile或伪装盲玩。

## QA冻结与独立审查

QA_PROTECTED_BEFORE.json封存3073项，包括原包、ZIP、人工QA目录/执行副本/截图日志/profile及默认存档缺席状态。保护终检逐文件SHA/长度及目录成员一致，QA Build IMMUTABLE、QA Save UNCHANGED、旧证据PRESERVED。原QA包及其play.ps1从未被本Owner执行或覆盖；仅新工作树启动Godot。

独立Reviewer结论可交付08：0 Critical / 0 Important；1个CLI测试入口Minor已修复并实测拒绝。范围与执行者裁定见REVIEW.md。最终生产SHA、交付commit、CLEAN、FILES_SHA256与原始保护/进程/源码核验见RECEIPT及PROTECTION_VERIFICATION.json。

非阻断原始备注：独立Scene probe修复前后退出均保留4 ObjectDB instances warning；修复后的旧三关controls退出也出现4 instances warning，checks通过/exit0，原因未定位，不据此关闭或推定公共生命周期Bug。正式Shell L04 probe、最终headless/graphical完整验收stderr为空。新工作树首次import出现既有unused icons_source.svg错误，Godot exit0但runner因错误日志判FAIL；冻结SVG未改，原.import元数据精确恢复，四个import生成的非Owner测试UID在保留记录后清理。所有失败与历史成功证据保留，不把这些记录冒充最终绿色。

## 集成交接

QA：**READY_FOR_08_RECHECK**。00采用本Owner commit，在独立新候选Build中复检此生产Resource；不得覆盖beta_content_batch_02_20261009_01或旧QA存档/截图/日志。08重点复检出生点立即Shift后的合法短按移动、原路线与Reset，再继续L04→L05及剩余五关链。原Human QA PARTIAL保留，不由自动结果升级。

Foundation modifications：NONE。Art modifications：NONE。L01–L03 / L05 / Shell / Save / Presenter / Shared Runtime modifications：NONE。Push：NOT_RUN。Integration merge / QA原包更新：NOT_RUN。
