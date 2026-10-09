# BETA-3D02 Focused QA preparation

当前状态：WAITING_GRAPHICAL_SLOT_RELEASED。未打开图形窗口。

固定候选：E:/godot/beta-sprint-builds/beta_3d02_20261009_01。1173个生产文件与上轮after哈希一致；ZIP SHA256697070886818f1e437e9fd20444fe98684a60582eeb2b30bcea98bf8ab64c999。

新profile仅复制前轮真实三关通关存档，来源SHA A90F426688509A684DE370F47ED8EA5342DA82633D0208AD29FD28D62BD442FC。原存档/旧证据不写。

A — L03 first-time comprehension：RETEST_PENDING。当前测试者已有解法经验，不使用重玩/AI子代理替代新测试者。

B — 1920×1080、1280×720、960×720：先由外部Godot测试入口设置，再读取client/viewport/render关联每张实际截图；实操Main/Select、新3D02L02/L03入关画面、Pause、鼠标Resume、Esc、Settings、Hint、键盘Focus、文字/裁切/重叠和关键按钮。已知P2不阻止其余测试。只做必要前置，不重复三次L02/L03完整路线。

C — 同新profile实际进入L03，保存基准authored spawn截图；正常移动、转视角和切世界改变状态；通过Main Quit正常退出并记录PID结束/存档checksum。新进程同入口同profile启动，实际Continue；对照关卡身份、起点位置、Surface/NORTH和初始朝向；记录第二PID、边界、截图和校验。只在原进程结束后启动第二进程。

测试专用脚本window_matrix.gd在QA目录外置，不改生产Main/project.godot/UI/Art。尺寸控制使用Godot窗口API，输入与截图仅Computer Use @oai/sky，不使用Win32或外部GUI自动化。

生产文件/ZIP/原profile/旧99+60个封存文件在本轮结束后再次核验。

预期输出：BETA_3D02_FOCUSED_QA_COMPLETE或PARTIAL；B/C仅实测后判定；A保持RETEST_PENDING；ProductionChangesNONE；既有P2两项保留；Foundation full DEFERRED。
