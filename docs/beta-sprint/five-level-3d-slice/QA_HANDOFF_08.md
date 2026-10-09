# QA_HANDOFF_READY — Beta Phase 3 五关 3D

08 的新验收对象只限 `beta_five_level_3d_20261009_01`。旧 QA 包、日志、截图和测试存档均不可覆盖。

- Build：`E:/godot/beta-sprint-builds/beta_five_level_3d_20261009_01`。
- Source：`942b6d4e0b3e30dc26fa4c276948fb68b548244e`。
- ZIP SHA256：`409cb38c4b43a1847ed0857e019265fb7ed26eec90fea4691760e2905a1c27c1`，61125565 bytes。
- 启动：该目录 `play.ps1`，Godot 4.7.2；隔离 `user://beta_sprint/beta_five_level_3d_20261009_01/qa_progress.json`。
- L01–L05 使用正式菜单身份进入，L04/L05 新 3D，谜题及 Save 字节未变。包内没有预置进度。

本轮重点：L04/L05 完整 3D 通关、Reset 后通关、Camera/World Shift、连接成立/失效/跨越、L04 Inner `(0,5)` 短 A 落脚、L05 Surface-only 踏板/门、Goal 回流；正常五关解锁、Save 和退出进程后 Cold Continue 恢复最近进入的已解锁关卡起点；Main/LevelSelect/Pause/Resume/Esc/Settings/Hint 的必要聚焦回归。不重复无影响的旧分辨率矩阵。

如果继承前三关进度作为测试起点，必须记录真实存档来源/校验值并标注限定范围；不能把 fixture 或修改存档写成五关从空进度自然解锁。新包没有人类 PASS，00 自动验证不能代替本轮试玩证据。

L03 首次理解：仅合格的全新玩家。当前 08 已确认无合格玩家，保持 RETEST_PENDING；不阻塞本包 QA。重点是端点、共同落脚点、连接成立/失效、实际跨越及跨越后提示生命周期。

P0/P1=0/0、P2=3 来自既有接受基线，待新版实际证据更新。三个既有项（暂停辅助文字重叠、L03 过期提示、菜单预览/灰盒标签）继续 backlog。Art/Foundation NONE；STAIR_CLEARANCE=PARTIAL_PASS、STAIR_TRAVERSAL=NOT_RUN。

00 自动证据：Owner 101/2276/27；集成 642/267；包目录 68、九阶段 exit0。包启动测试唯一旧 ObjectDB 强制退出警告仍按既有分类保留原文；真实玩法自然退出空 stderr。详细来源、SHA、限定范围与历史失败保留在 RECEIPT.md/JSON 和 Owner LEDGER。

请将实际新截图、viewport、日志、Save 校验和进程退出/重启证据放入新的独立 QA 根目录，报告 P0/P1/P2 与每个实际覆盖项。本交付不要求美术改向、Foundation 工具或任何已通过谜题重做。
