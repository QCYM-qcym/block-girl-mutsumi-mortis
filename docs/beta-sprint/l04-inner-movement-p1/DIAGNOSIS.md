# L04 Inner 起点阻断 — 根因与原Runtime证据

Root cause：L04的Inner内容包含Spawn `(1,5)`，却未提供任何相邻支撑格。原World Shift允许在共同Spawn落定到Inner；随后原GridMovement经ContentState.neighbor查询四方向，均得到当前格，正常拒绝启动roll。Owner：**06 Game Content**。这是可用R或切回Surface恢复的内容推进阻断；不能称为不可恢复软锁，也不能声称旧关卡所有路线均不可通关。

## 当前包与实际合同

冻结QA包：E:/godot/beta-sprint-builds/beta_content_batch_02_20261009_01。源提交991140292ac67e87d1751a062e7e96c7b9fee553，ZIP SHA256 dc7b92903f8b87d2b074531e680cc8bb9049ef123ef2ae9c697efd4ee59e7b5a。08报告与图形槽释放文件均只读。实际QA运行在其字节一致副本，本Owner没有启动/导入原包、执行副本或旧play.ps1。

L04生产Resource、Scene、实际batch_01/level_order.json在新诊断工作树与原QA包逐项SHA一致。原QA Resource SHA256：d679ad843428f2de42c655295d84ea9ee8c9ac032d835fecf02897668535155a；Scene：c63538cca67d022f68d4a24d1981d00bd5044ff141319a8fe1a5c8fe09072093；catalog：15993a6278e0901968232517a3cc4d9c8e5d8df266a36e932a7dfca2bf91df08。

正式catalog将L04登记为adapter=`p01`。真实链为Beta Shell / level_adapter → batch_02 scene →原ContentLevel →原GridInput / GridMovement / ContentState。此路径不调用Foundation RuntimeSession、Puzzle Kernel或Safety Queries。因此下面的StateKey是明确标记的原P01实际字段序列化，**不是Foundation StateKey**；published Runtime status/rejection enum为null，Safety issue为NOT_APPLICABLE。原路径也没有Face ID / FaceTransition / swept-enclosure / token / generation / finish_local / finish_global合同字段；不编造这些信息，不用Foundation Validator/Solver验证另一个域来替代实测。

## 紧密失败回归与最小化

正式Shell复现：`run.ps1 -Case probe -Entry shell -RunId before_shell`，PID32572，exit1，59checks，精确QA回归的两项失败。正式Scene、正式catalog、原GridInput、真实Input.parse_input_event；没有赋值mover/graph/world/view/pose。测试用原SaveStore在全新PID专属user:// profile设置选关资格；只用于Owner自动验收，不是人工进度链QA。

最小化去掉Shell/Save：同命令 `-Entry standalone -RunId before_standalone`，PID18004，exit1，55checks，同样两项失败。独立Scene仍经其原GridInput进入Runtime，复现结果相同；Shell不是必要条件。两次run均保存原始日志/源码SHA/动作前后快照。独立Scene退出附带4 ObjectDB instances warning，保留为诊断生命周期备注，未跨Owner修复。

请求短按0.05s（事件函数还经过正常frame边界）与持续0.75s分别测试四方向；不是以延长短按作为修复。Surface W两种时长都受理并提交1次，落定 `(1,4)`。Inner四方向八条记录均：

| Action / 世界方向 | 邻接目标 | Inner支撑 | 原neighbor返回 | Input送达 | roll开始 | commit |
|---|---|---|---|---|---|---:|
| W / 北 | (1,4) | 无，仅Surface存在 | (1,5) | 是 | 否 | 0 |
| D / 东 | (2,5) | 无 | (1,5) | 是 | 否 | 0 |
| S / 南 | (1,6) | 无 | (1,5) | 是 | 否 | 0 |
| A / 西 | (0,5) | 无 | (1,5) | 是 | 否 | 0 |

Before与After都为：

```text
p01|mutsumi_l04|cell=[1, 5]|world=1|view=0|pose=(1, 0, 0)|(0, 1, 0)|(0, 0, 1)|phase=idle
```

graph_world=1，view_busy=false，destination=(1,5)，moves=0，physical face direction=(0,0,1)。Presenter displayed_worlds=[false,true]、shift_committed=true、shift_progress=0、phase=idle；actor_basis与物理basis一致。所有方向press后held/order出现真实key token，release后清空。观测分类为B_NATIVE_NEIGHBOR_GUARD_REJECTED，指向原实现 `try_held: if next == cell: return` 与P01State的 `can_stand(next, world)` 保护；不是原API发布的REJECTED enum。

## 假设与排除

1. 作者数据把Inner Spawn隔离：预测两入口、两按键时长均被同一原邻接判定挡回当前格。实际一致；原.tres四邻支撑缺失，根因确认。
2. Shift未同步或遗留合法等待：预测phase/view忙或mover.world与graph.world不同。实际均idle / view0 / world=graph_world=1，Presenter已完成切换，排除。
3. 输入或Presenter故障：预测held/order缺key，或roll已启动/commit与显示脱节。实际输入送达、roll没有开始；Surface同进程可受理，排除本次根因。未声称证明所有Runtime/Presenter行为无Bug。

旧三关对照：PID6748，exit0，259checks / 48动作。每关Surface/Inner四方向分别短按和持续；48/48输入到达，有支撑的边都启动并提交，无支撑的边都按原规则拒绝。L01合法短/长方向2/2、L02 1/1、L03 2/2；持续输入可产生多次正常连续翻滚。没有观察通用短按丢失。此为限定输入回归，不升级旧三关为全面Human QA PASS。

修复后同旧三关对照再次运行：PID19592，exit0，259checks / 48动作 / 0失败；case只实例化实际Shell catalog的L01–L03。退出附带4 ObjectDB instances warning，未定位其生命周期原因，保留原stderr，不扩大功能PASS为生命周期无问题。原L01–L03/共享源码字节不变。

## 最小修复

只在L04 `inner_cells` 增加 `(0,5)`，连接 `(1,5)→(0,5)→(0,4)`。Spawn、Surface地板、Goal、平台归属、Inner EAST连接条件、Reset、共享提示与其它关卡不变。原generic Presenter按Resource为新格实例化既有Inner floor；无需改Presenter或冻结美术。

相同probe在修正后：PID28988，exit0，59checks，0失败。Inner A短按/持续都原生受理：native_neighbor=(0,5)、phase=roll、commit_count=1，After：

```text
p01|mutsumi_l04|cell=[0, 5]|world=1|view=0|pose=(0, 1, 0)|(-1, 0, 0)|(0, 0, 1)|phase=idle
```

最小独立Scene同命令亦GREEN：PID29152，exit0，55checks / 0失败，短/长A各1次原committed；保留与修复前相同的4 instances退出warning。

其它三方向仍缺支撑并正常拒绝；没有把非法方向变成APPLIED。Resource直接由原ContentState.configure加载，无本路径的Foundation Baker产物；重新运行原资源/原图测试为对应的生产验证。没有禁用Safety、传送、强制Tween提交或修改公共规则。

既有内容Unit重新运行：PID43860，exit0，45checks。原图查询L04 72/72可达状态能到Goal，minimum_shifts_to_goal=2；L05仍100/100、4次，未改内容。原Unit采用明确隔离的query-only拓扑枚举，不能冒充自然输入。它证明新增格只把既有起点接到岸边，没有省略核心Shift决策。

原自动路线先沿Surface到 `(0,4)` 再Shift，遗漏玩家在Spawn直接Shift的正常顺序。本次精确失败回归及三条完整路线均从Spawn先Shift、短按向西进入新格，再沿原Inner道路/EAST连接返回Surface出口。

最终图形、完整路线、保护终检及交付commit结果见REPORT / RECEIPT；本诊断不替代08重新检查完整五关链。
