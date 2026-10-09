# GAME_SHELL_BATCH_02_READY

Track: 07 Game Shell / Beta CONTENT EXPANSION。日期：2026-10-09。

生产候选已提交：`2ee64801d497df3acc909b4021b7325162cef2b5`。分支：`feat/beta-shell-batch-02`。工作树：`E:/godot/worktrees/block-girl-beta-shell-batch-02`。基线：`b910167becee2194c0cfc724d8f0fe47578836a9`。

06 生产依赖 `d4be39c76988e2face66d5f36be6e0c65fe9a169` 通过普通 no-ff merge `e6a6bc8c5a1b172ea89d75114315ca3df5c8bc92` 接入；最终 docs-only 依赖 `9482e7279acd2cc99af0f7b2211790ab2eace815` 通过普通 merge `b1d721db0c143ead99b1719e04d3568e5ae9bb2b` 接入。未 cherry-pick 或复制 Content 生产源码。

## 改动与边界

正式 `game/levels/mutsumi/batch_01/level_order.json` 仅追加 06 允许登记的两行：L04 / 借来的道路、L05 / 归途的门，均为 `GREYBOX_PLAYABLE`、`registration_allowed=true`、p01 adapter。原 L01/L02/L03 完整行字段和顺序与基线逐项相同；两条新行与 06 交付 catalog 相同。原 catalog reader、Main Scene、Flow、SaveStore 及 VERSION=1 保持不变。登记行的 `graphical` 字段保持交付元数据原样，不代表最终集成验收状态。

五条选关行在原布局下遮挡第五条及返回按钮：Owner Unit RED 94 项中 15 失败。`approved_shell_view.gd` 仅增加条件 ScrollContainer：选关条目超过三条时启用滚动及 follow_focus；原三条布局与其他页面保留既有分支和行样式。GREEN 94 项通过。既有 Art P2、灰盒预览文案、字体及 token 未修改。

旧 `test_content_shell.gd` 改为核验原三关前缀，以及真实 L03 successor 的解锁和 Next 状态；其三条真实路线范围仍为 L01/L02/L03，未把 L04/L05 传入旧路线。该图形测试未由 07 启动。

07 实际 Owner 路径：

- `game/levels/mutsumi/batch_01/level_order.json`
- `game/shell/visual_01/approved_shell_view.gd`
- `tests/beta_sprint/test_beta_catalog.gd`
- `tests/beta_sprint/test_content_shell.gd`
- `tests/beta_sprint/shell_batch_02/**`
- `docs/beta-sprint/shell-batch-02/**`

共享配置、SaveStore、Runtime/Puzzle/Foundation、旧三关场景和资源、Content 解法/提示、Art 生产源码及 00 builder/新 integration tests：07 改动 NONE。06 的三个 Owner 根仅来自上述依赖 merge。旧 Shell 工作树、08 包和原始证据未修改。

## 精确候选验证

最终 `evidence/b02_candidate_final_01/run_report.json` 的 head 为生产候选完整 SHA；140 个测试及依赖源文件的运行前后字节 SHA 相同。包含所有 Mutsumi 继承脚本、Shell、player/polish/perspective、Unit fixture，以及原三关和 Batch02 资源。六个阶段全部 exit 0、stderr 0、failures 空、pending 空。

| 阶段 | 检查数 | 证据范围 |
|---|---:|---|
| catalog | 68 | 原三行完整契约、正式五行、显式登记许可、PackedScene/资源身份、Next/末关/未知 ID |
| save_compat | 33 | VERSION=1、旧字段及可选设置、拒绝非法写入、旧真实存档只读与逐字节隔离复制 |
| menu_capacity | 94 | 五个明确人工 signal fixture 的解锁/保存、Pause/Settings/Reset、键盘与鼠标、三种逻辑布局 |
| runtime_seed | 102 | 真实 L03→L04→L05 Goal、解锁/保存/Next/正式选关、六次尺寸匹配断言及新关鼠标入口 |
| runtime_restore | 11 | PID 48092 从同一隔离存档 Continue 最近 L05、原生 Spawn、进度和设置保留 |
| legacy_restore | 11 | PID 5548 从旧 QA 真实存档的隔离副本 Continue L01、原生 Spawn、旧设置保留 |
| 总计 | 319 | Owner headless；Human acceptance NOT_RUN |

seed PID 7488 与 restore PID 48092 是不同 OS 进程，使用同一新鲜 `user://beta_sprint/b02_candidate_final_01/runtime_progress.json`。setup 仅写入明确声明的 L01/L02 已通关、L03 已解锁存档夹具；没有写入 Runtime 状态。之后使用 `Input.parse_input_event` 自然抵达三个真实 Goal，各产生一次真实 adapter.completed：L03 `(11,2)` / 6 moves，L04 `(11,1)` / 11 moves，L05 `(13,0)` / 13 moves。最后五关 unlocked/completed，recent=L05，末关 Next disabled。

L04、L05 各在 1920×1080、1280×720、960×720 的实际 headless viewport 中通过键盘焦点/滚动裁剪可见性和原生鼠标事件进入真实关卡。每次测量先恢复请求尺寸，并断言 Window 与 viewport 都匹配；这是逻辑布局证据，Human 窗口验收 NOT_RUN。Continue 验证重建关卡原生 Spawn、world/view=0、moves=0、phase=idle、Goal 未完成，未恢复中途棋盘快照。

## 真实旧存档保护

原始存档出处为 `E:/godot/beta-sprint-builds/black_box_3d_ui_qa_01_20261007/BLACK_BOX_3D_UI_QA_01.md` 第 17 行的旧 08 QA clean_profile。原件：`E:/godot/beta-sprint-builds/black_box_3d_ui_qa_01_20261007/clean_profile/Roaming/Godot/app_userdata/方块少女-若叶睦/beta_sprint/black_box_3d_ui_qa_01/progress.json`，及 `.bak`。

两者均为 valid v1；前后 SHA256 均为 `5fa81aa99da5497ad5e7391eae101b4c91f1f932e674eb9958aec1501613ab18`。原件仅 READ_ONLY；先检查规范化源、证据与写入目录互不重叠，再逐字节复制到新 `user://beta_sprint/.../save_compat.actual-copy.json`。Continue 只使用副本；旧 completed L01、unlocked L01/L02、recent L01、master 0.55 保留。生产 Save 算法无改动。当前普通 profile 默认存档缺失的早期检查保留为 PENDING，未冒充真实旧存档结果。

## 历史失败与审查

原始日志均保持字节并封存：初次字体重导入进程崩溃；重试仅有已知冻结 defs-only SVG 导入 P2；旧五行菜单 RED；测试入口误用内建 seed() 的 parse failure；Dummy headless audio 的 WAV playback 退出泄漏；旧 Runtime 菜单测量在关卡重置窗口后没有重新维持 L05 请求尺寸。以上均不计入最终 PASS。

最终 Runtime 仅以测试命令行 `--headless --audio-driver WASAPI` 运行，未修改生产音频配置。Godot 未在 OS args 暴露驱动参数时，脚本明确提示以 runner stage args 为准。冻结 `icons_source.svg.import` 在 import 的 finally 中恢复原字节，最终 SHA `c7911c2c43b002f31f1f245405f17fa1c6f086d342f831f4f643fb9b91af7b05`；未修复/重导入提交冻结 Art。三条已知 SVG 错误仅在 import 阶段记录为 P2，实际测试 stderr 必须为空。

独立只读审查未发现生产阻塞、存档损坏或 Runtime 语义冲突。提出的源哈希覆盖遗漏已修复：纳入 Mutsumi 继承源和 tests/shell fixture，再于精确候选运行最终 319 项。

## 集成与交付状态

00 已通知其完成 Content L04/L05 Graphical 206 项 / 6 routes / 23 PNG 和 08 Focused QA 封存；这些属于 00/08 的报告，07 未重跑、未声明 Human PASS。00 在最终集成候选继续执行旧三关限定 3D/menu 回归和新 Daily Build。07 所有进程均 headless，没有 Win32/PowerShell/AHK GUI 自动化。

候选提交后 Working tree CLEAN 已核实；本回执、原始日志与清单为后续 docs-only 封存提交，生产/测试源 SHA 与候选相同。最终 docs SHA 见交付时 git log。Push NOT_RUN。既有两个 P2 与灰盒预览文案仍留 Backlog，无新增生产 P0/P1 阻塞。

完整文件/SHA 见 `FILES_SHA256.json`；候选 140 项测试依赖源 SHA 与边界记录见 `SOURCE_SHA256.json`；可机器读取的结果见 `RECEIPT.json`。
