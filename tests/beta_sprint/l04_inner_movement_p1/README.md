# L04 Inner P1复现与验收

在本独立工作树根目录运行：

```powershell
& './tests/beta_sprint/l04_inner_movement_p1/run.ps1' -Case probe -Entry shell -RunId probe_new
& './tests/beta_sprint/l04_inner_movement_p1/run.ps1' -Case probe -Entry standalone -RunId scene_probe_new
& './tests/beta_sprint/l04_inner_movement_p1/run.ps1' -Case playthrough -Entry shell -RunId playthrough_new
& './tests/beta_sprint/l04_inner_movement_p1/run.ps1' -Case playthrough -Entry shell -Graphical -RunId graphical_new
& './tests/beta_sprint/l04_inner_movement_p1/run.ps1' -Case unit_regression -RunId unit_new
& './tests/beta_sprint/l04_inner_movement_p1/run.ps1' -Case controls -Entry shell -RunId controls_new
```

RunId必须全新，脚本拒绝覆盖历史证据。默认Steam Godot4.7.2，可通过-Godot指定。playthrough使用正式Shell，standalone仅适用于probe。图形运行前确认没有占用中的图形会话；诊断期间08已留存GRAPHICAL_SLOT_RELEASED，本Owner也检查了Godot进程。

`probe` 精确复现：每次R到正式Spawn，World Shift落定，再四方向短按/持续。它直接观察原GridInput是否填入mover.held/order、原graph.neighbor、phase、committed、pose与Presenter快照；断言Inner至少存在短按与持续输入可达后继。未修复基线的shell/standalone均RED，新增一格内容后GREEN。

`controls` 是L01–L03原Scene / 原catalog的Surface/Inner、四方向、短按/持续48组限定输入对照，不是全面通关回归。所有输入均使用Input.parse_input_event，不直接调用mover.press；有支撑才启动翻滚，没有支撑仍被拒绝。

`playthrough` 每条从Spawn先Shift到Inner，短按进入(0,5)，自然翻滚/世界切换/四视角/EAST连接至Surface Goal；正常、Reset后、不同camera顺序各一次。含动作中R、按住方向时R、通关后R、合法锁、错误世界/无支撑拒绝、实际3D动作观察、原Shell completed与L05解锁。未手动赋值graph/mover/world/view/pose，没有测试替身、传送或强制提交。

正式Shell测试用原SaveStore在新PID专属 `user://l04_inner_movement_p1/...` profile设选关资格，明确是Owner自动测试；不是盲玩、首次理解或真实从L01开始的Human QA进度链。它不打开任何08存档。旧QA包、ZIP、旧报告、截图、日志与profile由QA_PROTECTED_BEFORE.json全量保护，最终验证结果另存Owner docs。

`unit_regression` 原封不动运行已交付batch02/test_state.gd，以原ContentState邻接审计可达状态/最少Shift；没有新增玩法判定，也不把query-only状态枚举当自然输入证据。

所有case写真实PID/启动参数/退出码、源码与日志SHA、原始Godot报告；只终止自己启动的PID。graphical保存真实渲染截图；人工阅读截图不能由截图数量代替。import_baseline记录了既有unused icons_source.svg导入错误，exit0但错误日志被runner正确判FAIL；只恢复变化的原.import元数据，并保留/清理本次import新生成的四个非Owner测试UID，冻结美术源没有改动。

P01实际合同没有Foundation RuntimeSession StateKey/status/rejection code/Safety issue；报告published字段null，状态序列化与observed guard分类均明确标记实际来源。详情见DIAGNOSIS.md。
