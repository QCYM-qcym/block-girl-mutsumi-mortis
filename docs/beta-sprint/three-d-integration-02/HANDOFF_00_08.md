# BETA-3D-INTEGRATION-02 → 00 / 08

00 integration status：READY_FOR_NORMAL_MERGE。

候选分支 `feat/beta-3d-integration-02`，独立 worktree `E:/godot/worktrees/block-girl-beta-3d-integration-02`。Runtime / 新 QA Build source commit `7a95b28b155f5d32c4b559bdf90e0ea9beaad4ac`。最终分支 HEAD 只比它增加任务文档及封存证据，使用 `git rev-parse feat/beta-3d-integration-02` 得到真实 final delivery SHA。

00 本次接入从正式 `dc0bd64b53a9ee3c0c12d4bd7f25ab1ab92df916` 开始，正常 merge 本分支；本任务没有修改共享 Main Scene/project.godot，无此类 INTEGRATION_REQUEST，也没有不可接入的 Runtime contract 冲突。冻结 Art、Runtime、Save/Load、06 提示和谜题资源全部保持。若 06 后续交付提示，仅由其独立提交接入，不扩本轮 presentation 职责。

同一正式输入序列原 Pixel 与新 3D 逐 commit/settled-view观察 MATCH，L02/L03 各三次完整 3D 通关。当前源测试：L02 9+483、L03 9+1349、L01 9+279，2138 checks、failures=[]、exit0、stderr empty。独立源码 review 0/0/0。

新 Build：`E:/godot/beta-sprint-builds/beta_3d02_20261009_01`。源包而非 EXE，使用 Godot 4.7.2。1173 个复制源码 SHA 全部一致；import/Main/Foundation/三关 boot 全 GREEN。ZIP SHA256 `697070886818f1e437e9fd20444fe98684a60582eeb2b30bcea98bf8ab64c999`。

08 next QA status：READY_FOR_08_RECHECK；Human QA 新包 NOT_RUN。

08 请对上述新 Build 做独立实操 QA，重点：

1. L02 三种完整通关顺序（正常、Reset 后、不同视角顺序），Surface/Inner、四向滚动与物理六面系统、世界 VFX、Reset 和完成页。
2. L03 玩家理解连接前/转视角/连接成立/真实跨越/断开；Inner EAST 与未连接视角不能误导成可通行；Reset 和 Goal；旧过期提示保留 Owner06 P2。
3. L01 兼容回归；Game Shell Main / Level Select / Pause → Resume / Esc → Resume / Settings / Hint；UI-08-001 原已关闭的结论和三尺寸矩阵独立保留。
4. 同一动作的正式玩法状态来自既有 P01 链，不用 Mesh 坐标判断通行。测试模式/Owner 自动化不作为 Human QA。

使用新 QA evidence/profile 目录，例如 `E:/godot/beta-sprint-builds/beta_3d02_qa_20261009_01`；若已有则换新后缀。启动器默认新 `user://beta_sprint/beta_3d02_20261009_01/qa_progress.json`；独立 APPDATA profile 可再隔离。需要已解锁关卡时，仅复制旧实际解锁存档到新 profile 的新文件，保留原源存档哈希；不要写原08 profile，不制造新解锁 PASS，不重跑已通过 Cold Continue 除非新回归。

新源包和 ZIP 是固定验收对象；引擎缓存留在项目 `.godot`，截图/日志/QA报告放项目外；不得修改候选生产文件。旧 `visual_ui08001_20261009_01`、旧截图/日志/存档/报告全部冻结。

STAIR_CLEARANCE=PARTIAL_PASS；STAIR_TRAVERSAL=NOT_RUN。没有新楼梯实测不得升级。Art FROZEN，P2/P3 进入 backlog；只有真实 P0/P1 资产表达问题形成 MAIN_PROJECT_INTEGRATION_REQUEST → 05 Art。

无需等待未来 Foundation stage、框架重构或06 P2修复；本次接受范围是新主项目 presentation。当前 Main / Integration HEAD 保持旧值，等待00正常合并，不把 feature candidate 冒充已整合 receipt。
