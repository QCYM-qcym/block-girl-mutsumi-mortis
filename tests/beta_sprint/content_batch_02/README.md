# Batch02 自然输入验收

工作树根目录执行：

```powershell
& './tests/beta_sprint/content_batch_02/run.ps1' -Case unit -RunId unit_new
& './tests/beta_sprint/content_batch_02/run.ps1' -Case real -RunId real_new
```

新环境先运行 `-Case import`。RunId 必须唯一，脚本拒绝覆盖任何历史证据。Godot 默认使用本机 Steam 4.7.2，可通过 `-Godot` 指定安装路径。脚本只等待或终止自己启动的 PID，写入真实启动参数、PID、退出码和日志 SHA256；不触碰其他 Godot 窗口。

`unit` 用原 Resource / ContentState / mover 执行有时长的路线，检查错误世界阻断、门时序和 Reset。拓扑部分独立标记 `query_only_not_input_playthrough`；它枚举原图的邻接规则，检查所有可达状态能完成以及最少切换次数 L04=2 / L05=4，不作为自然输入证明。

`real` 使用正式 Shell、原 level_adapter 和原 GridInput，发送真实 InputEvent，经 Runtime 落定至 Goal。每关正常、Reset 后、不同视角顺序三次；含动作中 R、按住方向时 R、通关后 R、四个严格 90° 视角、错误世界拒绝、连接过渡和门开关时序。脚本不赋值游戏 graph/mover/world/view/pose。测试保存到 PID 专属 user:// profile；保存封装副本进入 evidence，默认玩家存档及备份的字节 SHA 保持不变。

## 图形验收交接给00

当前图形槽仍由00/08占用，本批没有运行图形窗口。获得明确窗口时段后，在最终集成工作树运行同一自然输入脚本：

```powershell
& './tests/beta_sprint/content_batch_02/run.ps1' -Case graphical -RunId graphical_integration_01
```

图形用例检查非 headless 显示模式，并保存两关的出生点、连接成立、连接落定、L05开门、每次Goal等截图。00还需人工查看：可见地板与可走网格一致、两世界辨识、EAST端点相接、方块落定、桥/门/出口位置以及HUD可读性。截图数量本身不能证明这些视觉标准通过。

`run.ps1` 默认隐藏启动窗口，图形渲染及截图仍由 Godot 正常显示服务器完成；交互式 F6 试玩可直接打开各关 .tscn。

冻结的 unused icons_source.svg 若触发既有导入问题，保留错误日志，Owner不改SVG；import case只恢复运行前精确的 .import 字节。此次 import_01 实际退出0，没有该导入错误。

## 证据版本

`unit_red` 为缺关卡Scene的预期RED。`real_01` 为测试夹具 typed Array 配置错误后终止的失败运行，未用于验收。`real_02` 为桥修正前逻辑结果；独立审查发现可见桥缺支撑后，它被替代。`unit_bridge_red` 记录四项桥支撑失败；`unit_bridge_green` 为地图修正后通过。最终依据 `unit_final`、`real_03`，图形仍为 PENDING。
