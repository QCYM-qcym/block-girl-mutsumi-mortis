# L04_INNER_MOVEMENT_BLOCKER — P1诊断与修复

2026-10-09，Asia/Shanghai。QA冻结源991140292ac67e87d1751a062e7e96c7b9fee553；独立分支fix/l04-inner-movement-p1。桌面create_worktree返回Not a git repository；回退到指定项目仓库git worktree add，无QA包写入。

CONTENT_OWNER_PATHS：

- game/levels/mutsumi/batch_02/l04_borrowed_path.tres（仅定位为内容问题后修改）
- docs/beta-sprint/l04-inner-movement-p1/**
- tests/beta_sprint/l04_inner_movement_p1/**

1. 封存QA Build / ZIP / 人工QA目录 / 存档当前字节SHA；新工作树初始CLEAN。
2. 在实际正式Shell和独立Scene各复现出生点Shift后四方向短按/持续输入。记录输入是否进入原mover.held、原graph.neighbor返回、原phase/committed、Presenter状态。
3. 根据证据区分输入未送达、原规则拒绝、显示/提交故障、合法等待。ranked hypotheses及逐项排除见诊断报告；不根据画面静止推定。
4. 先有精确失败回归，再最小Owner-local内容修复；若公共Runtime/Presenter冲突则不跨Owner改动，输出01 handoff。
5. 起点直接Shift进入Inner后的正常、Reset、不同视角三完整通关；原图查询检查无捷径/可达死路，旧三关短/长输入限定回归和源码保护。
6. 图形槽已由08留证释放；独立工作树图形自然输入复验与截图。最终再核对QA全体原字节，提交Files/SHA与真实commit，CLEAN / Push NOT_RUN / READY_FOR_08_RECHECK。

实际adapter=p01，其GridMovement + ContentState没有Foundation RuntimeSession StateKey / status / rejection enum / Safety issue / token generation。证据使用实际字段并标明不适用，不虚构这些公共合同字段。输入与规则沿用冻结实现，不新增判定系统。

## 完成记录

- [x] 初始工作树CLEAN；3073项QA保护库存，未启动原包。
- [x] before_shell PID32572 / before_standalone PID18004 精确RED；输入/状态/原邻接/原Presenter证据确定06内容根因。
- [x] 唯一生产改动：L04 Inner新增(0,5)；after_shell PID28988 / after_standalone PID29152 GREEN，短按与持续均可动。
- [x] 原Unit PID43860 45 PASS，72/72可解、minShift2，无算法变动。
- [x] 最终headless PID13392 201 PASS；graphical PID30536 219 PASS、18截图；各三自然路线/三正式Goal；实际查看相关图形。
- [x] 旧三关修复前PID6748、修复后PID19592各259 PASS / 48输入；明确限定范围及退出warning。
- [x] 独立只读审查无Critical/Important；CLI入口Minor修复并实测拒绝，历史wrapper来源保留。
- [ ] 最终原字节保护/FilesSHA、实际候选commit及回执commit，提交后CLEAN / PushNOT_RUN。
