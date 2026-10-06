# Batch 01 内容生产模板

生产基线为 `8a77874` 上的 P-01 runtime。这里的 `content_level_data.gd` 是关卡局部配置，不是 Foundation LevelDefinition。不要把它写入 Foundation registry，或声称已接入 Authoring/Baker。

## 文件职责

- 一个 `.tres`：标题、稳定 id、品质标记、出生点、表/里世界地板、出口和已有连接配置。
- 一个 `.tscn`：Node2D + `content_level.gd` + `content` Resource；可独立 F6。
- `level_order.json`：供 00/07 接入参考的内容顺序元数据，不负责菜单、加载或存档。
- `tests/playtest/`：真实输入路线、Reset、强制机制、可达状态及图形截图验收。

## 可填写字段

| 字段 | 约束 |
| --- | --- |
| level_id | 稳定、唯一；本批为 `mutsumi_l01` 到 `mutsumi_l03` |
| display_title / intent | 面向玩家的关卡标题和简短目标 |
| quality | `FORMAL` 或 `GREYBOX` |
| spawn | 必须在 Surface 中存在；Reset 固定恢复 Surface + NORTH |
| goal | 必须在 Surface 中存在；现有出口语义固定 Surface 完成 |
| surface_cells / inner_cells | 整数 `(x,z)`；两个世界分别声明可落脚格子 |
| platform_b_cells | 上述地板的子集，属于远端平台 B；其余平台 A |
| link_enabled | 不用连接时为 false |
| link_a / link_b | 复用朝东的 A 端点与朝西的 B 端点，A 在平台 0、B 在平台 1 |
| link_worlds | 启用连接的世界 0=Surface、1=Inner |
| gate_enabled | 只用于本批 L-01 的既有门配置，不是可自由移动的门系统 |

## 已有机制限制

四个视角是离散二维等距投影，不是任意三维光学连接。连接只在 EAST 启用，远端平台使用既有 `(-5,0)` 展示偏移。因此本模板的 A/B 端点同 z，B 的 x 比 A 大 6，几何接缝对应正常一格。两端都必须在允许世界存在；画面重合不自动创建其它连接。

压力板固定 `(11,0)`，门边固定 `(11,0)` 与 `(12,0)` 之间，仅 Surface 压板开门，授权的完整翻滚落定后关闭。开启 gate 时沿用 L-01 配置；关闭时不得在另一关使用这条隐含受门控制的边。涉及新位置、新轴向、新连接条件时先交给相应机制 Owner，不能扩公共算法。

翻滚、视角、Shift、输入锁、姿态及 Reset 来自现有 runtime。局部图形层只呈现状态。L-01 复用正式角色、地板与机关资产；灰盒只给既有地板着色，不生产最终美术。声音沿用现有 TEMP 资源。

## 本批实际路线

方向以下用世界网格表达；玩家 WASD 会随视角改变，Q/E 每次转 90°。

| 关卡 | 路线 |
| --- | --- |
| L-01 | Surface `(0,5)` 向北三格到 `(0,2)` → Shift Inner → 北两格到 `(0,0)` → 东三格到 `(3,0)` → E 到 EAST → 向世界东翻滚，经连接到 `(9,0)` → Shift Surface → 东两格踩 `(11,0)` 压力板 → 东两格经门到 `(13,0)` Goal |
| L-02 | Surface `(0,5)` 北两格到 `(0,3)` → Shift Inner → 北两格到 `(0,1)` → 东一格到共同落脚点 `(1,1)` → Shift Surface → 东三格到 `(4,1)` Goal |
| L-03 | Surface `(0,2)` 东三格到 `(3,2)` → E 或鼠标右拖到 EAST → 向世界东翻滚，经连接到 `(9,2)` → 东两格到 `(11,2)` Goal |

按键最短示例：L-01 `W×3, Space, W×2, D×3, E, W, Space, W×4`；L-02 `W×2, Space, W×2, D, Space, D×3`；L-03 `D×3, E, W×3`。等待每次翻滚/Shift/旋转落定；WASD 可按住连续翻滚。R 可在动作中或完成后重置。

## 生产验收

1. 新 Scene 独立启动；出生点、目标及所有世界占格正确。
2. 使用真实输入完整通关，记录每个关键决定。
3. 验证缺失地板、错误视角/世界不可绕过教学机制。
4. 在滚动、切换、旋转、完成时 Reset，确认没有残留输入。
5. 从所有可达的 cell/world/view 状态搜索出口；本批姿态不参与门控，因此不用扩大到 24 倍姿态状态。
6. 检查两个窗口尺寸、全部视角的图形。自动化已知解法通过不等于新玩家理解；安排首次玩家试玩。

本轮只交付前三关，不开始第四关。
