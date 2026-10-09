# L06 原规则可表达性验证

2026-10-09 · 基线 `9e2e9c29a73272d431795f12db1fefaff2433b05` · Godot 4.7.2.stable.steam.ed1daf0bf

这是隔离工作树里的设计验证。只把候选JSON转换成内存中的原 ContentLevelData，调用原 ContentState / GridMovement / PerspectiveController。没有保存.tres、实例化生产关卡或Presenter、发送原生InputEvent、读写玩家/QA存档、修改Shell目录或Foundation代码。

## 最终结果

| 项目 | 实际结果 |
| --- | --- |
| Run | `native_02`，PID **51476**，exit **0**，无超时 |
| 检查 | **500**，failures=[] |
| stderr | **0字节** |
| 正常 / Reset重玩 / 视角替代 | 各21 roll + 6 Shift commit，原Surface完成条件成立 |
| 出生即Inner替代路线 | 23 roll + 6 Shift commit，原Surface完成条件成立 |
| 四个视角 | 单次90°snap调用、提交后的方向映射；两个出生world×四view均有合法移动 |
| 拓扑 | **148可达 / 148可完成**；最少Shift **6**；最少总动作 **28** |
| 移除Shift / 连接 / 门边 | 均无Goal路径；只过滤原查询返回的边，不新建规则 |
| Inner Gate | 四视角均拒绝；错误世界/非EAST连接均拒绝 |
| Reset probe | roll、shift、view、held中Reset均恢复并取消pending；路线间原Reset后继续完成 |
| 保护 | 两次运行各核验 **3963** 个已有跟踪文件，before/after字节与SHA一致，changed=[] |

原始报告与日志：[report.json](../../../tests/beta_sprint/l06_preproduction/evidence/native_02/report.json)、[process.json](../../../tests/beta_sprint/l06_preproduction/evidence/native_02/process.json)、[stdout.log](../../../tests/beta_sprint/l06_preproduction/evidence/native_02/stdout.log)、[stderr.log](../../../tests/beta_sprint/l06_preproduction/evidence/native_02/stderr.log)、[protection.json](../../../tests/beta_sprint/l06_preproduction/evidence/native_02/protection.json)。

报告中的route trace分别记录原API动作前后cell/world/view/orientation/phase、commit计数、plate/door/complete。翻滚使用press/release与两个自然时间步，Shift和视角同样等待原计时提交；没有路线状态注入或强行完成transition。该执行没有Presenter和正式level_adapter，`graph.complete` 成立不是正式Shell完成回调，也不是人类/图形通关证据。

拓扑审计单独标为 `native_query_only_not_playthrough`。它复用基线 `neighbor/can_stand/settle/recalculate` 查询，枚举 `(cell,world,view)`；只在该审计部分设置查询状态，不混入timed路线。当前adapter不按orientation筛选合法边，因此使用姿态商空间；四条timed路线另确认每次提交的实际朝向有效及Shift/视角保留姿态。148/148不能外推为Foundation24态/全Safety搜索，也不能解释为每个状态均能原路回出生。

## 来源身份与历史

候选JSON SHA256：`c6599a5ef256729f6861854ac970a075a487e0387766000d00cdcfb4f7fa174f`。最终消费的验证脚本及运行器SHA由 `native_02/process.json` 实际记录。进程HEAD仍为未提交的基线；消费源码SHA保留，不能改写日志HEAD成后续提交SHA。

首轮 `native_01` PID47168：485 checks、exit0、stderr0；原证据保留。其后只扩展设计验证，增加门边不可绕过、所有非EAST视角拒绝和门动画时序断言，得到 `native_02` 500 checks。候选地图未改变。没有RED、失败或缺失进程被包装成PASS。

3963文件保护涵盖基线全部跟踪文件，包括L01–L05作者资源、L04修复、L05人类PASS对应内容、Runtime、Foundation、Presenter、美术、Shell/Save及旧文档/证据。它是精确字节保护检查，不是重新试玩五关。外部QA包、日志、截图和存档未运行或写入；仅只读读取两份08报告，其来源SHA见交付收据。

## 重现

从本工作树运行，指定新的RunId避免覆盖已封存证据：

```powershell
& 'E:/godot/worktrees/block-girl-l06-preproduction/tests/beta_sprint/l06_preproduction/run.ps1' -RunId native_recheck_03
```

运行器将启动隐藏headless进程，只写本测试Owner目录的新证据；保留PID、args、HEAD、消费SHA、exit/timeout及原stdout/stderr，并对所有非L06授权根的跟踪文件做前后保护核验。无需编辑器import、图形槽或预置存档。基线`.gitattributes`采用LF，交付会检查Git对象和工作树证据字节一致。

## 未执行与边界

生产资源转换、Scene boot、3D/Presenter、正式InputEvent、Shell完成回调、真实L05→L06解锁、Save/Continue、Foundation Safety和Human QA：**NOT_RUN**。没有以本设计验证升级五关既有状态。只允许状态 **L06_DESIGN_READY / DESIGN_NATIVE_RULE_VALIDATION**。
