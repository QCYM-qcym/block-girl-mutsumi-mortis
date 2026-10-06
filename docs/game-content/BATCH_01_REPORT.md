# GAME_CONTENT_BATCH_01_READY

项目：Mutsumi Veilshift / 方块少女-若叶睦。Beta Sprint，目标 2026-11-30。交付日期：2026-10-06。

工作树：`E:/godot/worktrees/block-girl-beta-game-content`。分支：`feat/beta-game-content`。基线：`main / 8a77874`。内容提交：`4c80b55`；验收、UID、文档和 SHA 清单在后续交付提交中。

## 关卡状态

| 顺序 | 关卡 / 独立 Scene | 职责 | 状态 |
| --- | --- | --- | --- |
| 1 | `game/levels/mutsumi/batch_01/l01_another_world.tscn` /《另一个世界》 | 升级 P-01；翻滚、四视角、双世界、透视连接、踏板门、出口 | **FORMAL_PLAYABLE_PASS** |
| 2 | `game/levels/mutsumi/batch_01/l02_between_shores.tscn` /《两岸之间》 | 必须在两处共同落脚点切换世界，跨越世界专属通路 | **GREYBOX_PLAYABLE** |
| 3 | `game/levels/mutsumi/batch_01/l03_lines_meet.tscn` /《视线相接》 | 在 Surface+EAST 对齐指定端点，实际翻滚通过连接 | **GREYBOX_PLAYABLE** |

没有开始第四关。第一关复用已有正式角色、地板和机关资产及 P-01 polish，不重新制造同功能谜题。所有关卡都有 Spawn、Surface/Inner、四视角、Goal、完成锁和 R Reset。第二、三关不实例化可见压力板/门，保留清晰灰盒品质标记。

## 实际路线

按世界网格方向描述，WASD 随视角旋转映射；按住可连续翻滚。

- L-01：Surface `(0,5)` 北三格 → `(0,2)` Shift Inner → 北两格 → 东三格到 `(3,0)` → E 到 EAST → 向世界东翻滚，经真实连接到 `(9,0)` → Shift Surface → 东两格压下 `(11,0)` 踏板 → 东两格穿门到 `(13,0)` Goal。
- L-02：Surface `(0,5)` 北两格 → `(0,3)` Shift Inner → 北两格到 `(0,1)` → 东一格到 `(1,1)` → Shift Surface → 东三格到 `(4,1)` Goal。
- L-03：Surface `(0,2)` 东三格到 `(3,2)` → E / 鼠标右拖到 EAST → 向世界东翻滚，经真实连接到 `(9,2)` → 东两格到 `(11,2)` Goal。

出生视角 NORTH 下最短按键路线见 [LEVEL_TEMPLATE.md](LEVEL_TEMPLATE.md)。模板明确既有 EAST 连接、平台偏移、固定门布局的限制，没有引入通用关卡系统或扩展公共规则。

## 使用机制与边界

直接复用原 runtime 的 `grid_movement.gd`、`perspective_controller.gd`、`perspective_link.gd`、`connectivity.gd`、`grid_input.gd`、24 态角色 Sprite presenter 和 P-01 polish。关卡局部 Resource 声明地图、出生点、出口和连接条件；局部继承脚本选择本关配置与文本。

当前可玩基线没有 LevelDefinition/Authoring scene runtime 管线。其它 Foundation 工作树中的 Authoring 声明不是当前主入口，因此没有合并或迁移 Foundation。三关可独立打开 Scene 后 F6 完整游玩；原 F5/P-01 入口保持原样。

## 验收证据

Godot `4.7.2.stable.steam.ed1daf0bf`，Windows 图形 display，D3D12 / Forward+，NVIDIA RTX 5060 Ti。

| 检查 | 结果 |
| --- | --- |
| 新批次状态验收 | 43 checks，0 failures |
| 可达状态均可抵达 Goal，无需 Reset | L-01 108/108；L-02 48/48；L-03 56/56 |
| 新批次真实输入图形验收 | 429 checks，0 failures，7 次完整通关 |
| L-01 通关模式 | normal、reset_replay、alternate_views，各一次 |
| L-02 / L-03 通关模式 | normal、alternate_views，各一次 |
| 编辑器资源导入 / UID | 成功，错误日志为空 |
| 原 P-01 状态回归 | 31 checks，0 failures |
| 原 P-01 图形输入回归 | 167 checks，0 failures |
| 透视/姿态逻辑回归 | 66 checks，24 orientations，0 failures |
| 早期原型状态回归 | 50 checks，94/94 状态可解 |
| 早期原型输入回归 | PASS |
| 独立只读代码审查 | 无 Critical / Important / Minor finding |

图形验收验证连续翻滚、Q/E 双向四视角严格 90°、鼠标右拖、Shift 保留格位/物理朝向、缺失落脚点拒绝 Shift 并反馈、真实定时连接翻滚、开门时序、Goal 锁定及动作中 Reset。截图覆盖 1280×900 与 900×700 的所有视角；按实际 alpha 绘制范围检查地板与 HUD 不重叠，独立审查也检查了全部 12 张最小窗口截图。

状态枚举使用这批地图的真实可落脚/门边/连接规则，没有修改或调用公共 Solver/Softlock。因为这三关的门控不依赖物理姿态，所以按 cell/world/view 状态枚举；姿态行为由原有测试与图形验收覆盖。

最终证据：`tests/playtest/evidence/batch_01/state_report.json` 和 `runtime_report.json`。`initial_harness_report.json` / `initial_harness.stderr.log` 仅保留第一轮验收脚本误报记录，不代表当前失败：透明 atlas 留白曾被当成图形足迹，L-03 曾用无路的 W 键触发 Reset 前滚动；两者均已修正后重跑。

复现命令（先导入，再状态、再真实图形）：

```powershell
cd 'E:\godot\worktrees\block-girl-beta-game-content'
.\tests\playtest\run_batch_01.ps1
```

未执行会重新保存既有 tileset sample 的全套 visual harness；遵守 Owner 边界，运行上述不修改公共生产文件的相关回归。没有将已知解法的自动通关声称为真人首次试玩。

## 接入请求

**GAME_SHELL_INTEGRATION_REQUEST / INTEGRATION_REQUEST**

- Owner：07 Game Shell / 00 Integration。
- 最小内容：把 `game/levels/mutsumi/batch_01/level_order.json` 的三个稳定 id 与 Scene 路径加入 Owner 的选关/关卡目录，顺序 L-01 → L-02 → L-03。
- 如需改 `project.godot` 或主入口，只由 00/07 在其集成分支处理。06 无需新增 Autoload/InputMap，三关已能独立 F6。
- 本批无需存档格式变更。Shell 若记录完成状态，使用上述稳定 id；具体保存/加载仍归 07。

**ART_INTEGRATION_REQUEST**

- Owner：05 Art；第二、三关需要最终环境美术，替换灰盒呈现时保留占格、端点与世界路径语义。
- 现有 TEMP SFX/环境循环后续替换；本批沿用批准资源，无资产生产源码修改。

## 不阻塞 backlog 和审查裁定

- 首次玩家对桥、端点与世界切换的理解及实际用时，需要不知解法的人试玩。
- L-02/L-03 最终美术、正式声音与 Shell 菜单/选关接入由对应 Owner 完成。
- 任意未来 Resource、移动门坐标、非 EAST 连接不在本批支持范围；模板记录现有坐标/轴向限制。未来内容误用会造成不可解地图，必须重新完成相同内容验收，不能把当前三关通过当成通用配置保证。
- Foundation integration 是另一个基线迁移任务；当前交付是已验证的 P-01 runtime 内容。若以后切换公共 runtime，需要重新检验全部路线和输入语义。

审查没有发现需延期的 Minor 问题。BUILD 继续、路径限定及验收脚本修正的决定记录在 `BATCH_01_PLAN.md`，没有因 Harness、美术或 Shell 未接入停线。

## 修改文件 / SHA / 最终状态

完整新增交付文件、字节数和 SHA-256 见 [BATCH_01_FILES.json](BATCH_01_FILES.json)。为避免自引用，清单自身不在清单内；它是 Git 提交的一部分。PNG、日志、UID 和验收 JSON 一并保留。

CONTENT_OWNER_ROOTS：`game/levels/mutsumi/`、`docs/game-content/`、`tests/playtest/`。交付 diff 只涉及这些路径；生产 Foundation、公共 runtime、输入、美术、`project.godot`、原主入口、菜单和存档均无修改。

- Production Foundation changes：**NONE**。
- Working tree：**CLEAN**，指 `feat/beta-game-content` 交付工作树。
- Push：**NOT_RUN**。
- 原 `main` 工作区原有的 7 个 README 图片 import sidecar 保留；该原工作区并非 CLEAN，本轮没有清理用户文件。隔离工作树导入临时产生的同名 sidecar 单独移除以恢复基线，不纳入内容提交。
