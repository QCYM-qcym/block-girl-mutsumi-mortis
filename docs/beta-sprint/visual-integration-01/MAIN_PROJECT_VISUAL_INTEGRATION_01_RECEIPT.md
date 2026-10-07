# MAIN_PROJECT_VISUAL_INTEGRATION_01_READY

交付日期：2026-10-07。实际MAIN：E:/godot/若叶睦/方块少女-若叶睦，branch main。正式测试SHA：22dc7281a54250db93f6d70e607fa0a00e206f78；Daily Build source SHA：8a7d339994f68cf15727bf7dc5b75c36110184b5。最终receipt提交只更新任务交付文档，375个正式Runtime/Test/Asset文件保持与测试SHA一致。最终40位receipt提交由git log及00正式输出/08交接标识。

| 正式验收 | 实际结果 |
| --- | --- |
| Gameplay Art | L01 3D、Wakaba、Roll、六面Orientation、4×90 camera、Surface、Inner、World Shift VFX、Mechanisms：PASS |
| Game Shell UI | 正式handoff接入、Main Menu、Level Select、Pause、Settings、Level Complete、Hint：PASS |
| Resolution | 1920×1080、1280×720、960×720原生窗口：PASS；关键按钮/文字可读可操作，所属按钮文字包含检查通过；辅助文字P2单列 |
| Navigation | Mouse PASS；Keyboard PASS；Controller NOT_SUPPORTED（现有正式Gameplay映射不支持，未新增绑定） |
| Game Flow | Save、Continue、Reset、Cold Restart、Pause→Settings→Resume、L01 Goal→L02 unlock/原灰盒Next：PASS |
| Pixel reference | PRESERVED；既有Pixel presenter/HUD保留为回归参照 |
| 3D StateKey parity | PASS，17个实际动作观察状态与Pixel一致，最终SHA256 0c2618ccdfe10b65fa4adef539260f24722f403f673c94aa356e1a6fbec898b9；P01观察哈希，不是Foundation statekey.v1 |
| Source Art | ART_SOURCE_CHANGES NONE；UI_ART_SOURCE_CHANGES NONE；MAIN_PROJECT_INTEGRATION_REQUEST NONE |
| Stairs | STAIR_CLEARANCE PARTIAL_PASS；STAIR_TRAVERSAL NOT_RUN，保持原边界 |
| Foundation changes | NONE；FROZEN_FOR_BETA |
| 当前接入缺陷 | P0 0；P1 0；新增P2 1，compact panel底部辅助文字定位，Backlog only；Human QA尚未完成 |
| QA | READY_FOR_BLACK_BOX_3D_UI_QA_01；交08 QA & Build真实盲测，不将自动PASS冒充Human PASS |
| Push | NOT_RUN |

## MAIN正式证据

全部八个正式进程exit0、stderr empty、stdout无ERROR/WARNING/FAIL；六个计数case checks>0，failures=[]，合计8860 PASS。真实Windows Forward+ / NVIDIA GeForce RTX 5060 Ti，Godot 4.7.2.stable.steam.ed1daf0bf，engine SHA256 12310c74bdda7dcd43f28e971f33047dcecadd436b68169d61ce41009006df38。

| MAIN Evidence | Actual PID | Checks |
| --- | --- | --- |
| main_ui01 import | 25588 | Import PASS |
| main_ui01 entry | 26272 | 7 PASS |
| main_ui01 graphical real seed | 15284 | 2727 PASS |
| main_ui01 independent cold restore | 25204 | 13 PASS |
| main_uiart01 import | 6344 | Import PASS |
| main_uiart01 entry | 2788 | 6 PASS |
| main_uiart01 graphical real seed | 26924 | 6089 PASS |
| main_uiart01 independent restore | 21264 | 18 PASS |

Raw证据真实路径：MAIN/.godot/beta-sprint/visual-integration/main_ui01以及MAIN/.godot/beta-sprint/art-vertical/main_uiart01，包含过程日志、report.json、实际屏幕截图、物理/逻辑坐标、自然动画采样、动作状态和同Save新进程恢复。精确source fingerprints及进程数据副本见FORMAL_MAIN_UI_EVIDENCE.json、FORMAL_MAIN_ART_REGRESSION_EVIDENCE.json。Integration ui_graph03 2747 PASS与ui_art01 6187 PASS保留为候选证据；不替代MAIN正式运行。

CASE A cold menu→select→L01真实鼠标；B真实move/camera/world/reset；C原Goal触发、保存、完成页与L02解锁/Next；D不同OS PID同隔离Save冷Continue正式L01起点；E真实Pause/Settings preview/Cancel/Apply/Resume；F六页三种真实窗口及长标题/长错误组合、disabled/focus导航、40px目标/16px原生文字、实际全屏preview及Cancel恢复：PASS。完整Hint链观察原text/alpha/flags；新HUD没有第二个Hint计时器。人工complete状态组合仅标为表现contract；真实Goal另外验证，不用组合fixture冒充通关。

正式art regression完整验证自然roll、六面姿态、四相机、Surface/Inner及shift、原机关状态、Reset、Goal、Pixel/3D17观察状态一致、同档冷Continue。2个实际Goal事件（Pixel/3D各一次），当前设备frame p95 16.769ms；不是任意硬件性能承诺。L02/L03不做3D迁移，L03完整游玩、楼梯通行、载客/旋转平台、死亡和任意Puzzle快照Save未纳入。

## Daily Build与保存边界

实际目录：E:/godot/beta-sprint-builds/visual_daily_20261007_02。入口play.ps1，project/project.godot。包种类SOURCE_PLAYABLE_NOT_EXE，需已有Godot；1206文件与manifest零SHA差异，375正式源码与MAIN测试零差异。独立复制工程六个import/boot阶段均exit0/PASS，Main/L01/Foundation stderr空。L02/L03限时单场景退出各133bytes的4 ObjectDB warning与旧Beta Slice e22d0255e8a974c1f87445516b16ddcb71af465e逐字节一致，已有工具问题进入Backlog，不修改冻结Runtime。全部实际检查/警告来源在DAILY_BUILD_VERIFICATION.json。

ZIP：E:/godot/beta-sprint-builds/visual_daily_20261007_02.zip；84649034 bytes；SHA256 562a824cdea42985077f99677fd3a5bc982676748470d843dafc7992c1b57164。首个隐藏文件metadata失败包visual_daily_20261007_01原地保留，未冒充成功版本。

原459冻结文件、77批准UI源文件零变化；runtime资产从批准源提取/绑定，字体可携带且保留原许可字节，不能把派生图标当成改Source Art。Save/GameFlow/解锁/Settings算法未改，主场景/project.godot/InputMap/Autoload/Core未改；只接入新View与L01 HUD/原生表现坐标/已卸载表现回调guard。Daily Harness仅Get-Item加-Force读取Hidden复制文件Length。绑定/许可/源保护证据见ASSET_BINDING_MANIFEST.json、font_manifest.json、PRESERVATION_VERIFICATION.json。

工作树：本轮交付/Integration及MAIN tracked CLEAN；MAIN预存77个untracked批准UI文档/源图仍原样保留。因此MAIN整个工作树不冒充CLEAN，也不删除/忽略/擅自纳入这些用户文件。FILES_SHA256.json/CSV覆盖本轮全部交付文件及两个接线入口，仅排除这两个自指清单。Push NOT_RUN。

完成本次交付后停止。不开始L02/L03 3D迁移、L04、新美术设计或新Foundation开发。
