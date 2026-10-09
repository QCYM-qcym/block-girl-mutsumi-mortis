# PFALL_INCREMENTAL_INTEGRATION_STATUS

2026-10-10，00 Integration Coordinator。首轮自动验收登记 **PERSPECTIVE_FALL_CORE_PLAYABLE / CORE_PLAYABLE: PASS**，范围为独立 A/B 实验场景的真实 Runtime → Fall → Landing → 普通 Roll → Exit/Goal，以及对应权限、状态和生命周期验证。完整 Game Feel 与 Human QA 尚未完成。

合同2938d6e534f5b596bb320ce79d72b69f5923f3cd、Bootstrap48a0e1791e7715722e38a1a01ab229535e2efb10均保留；未重复建合同、Worktree或分配Owner。八条已有线在原范围交付；本轮所有正常merge集中于2026-10-10第1个Integration窗口，窗口已关闭，无冲突、无push。

| Owner | 实际交付 / 集成状态 |
|---|---|
| 01 Runtime | 26387d6c34a869ad7035ee13ee77d8d5c24d796a正常合入；显式opt-in正式Fall、Safety、schema2 StateKey/Trace、原生事件和只读接口已实际消费。旧schema1保持原规则。 |
| 09 Map | 54ea24cd50c4bd45b083dc26487ff2b7afd2a703、Exit增量82a8a7dc85205e9391551f24267f35f5abe53393、opt-in adapter e4bcdfc6459f587cb26c25494dd5b57b76ccdca4正常合入；A/B真实Fall和后续移动到Goal均PASS。 |
| 10A Fall Animation | 4781dfcf16757ccbde13e54ee449f1cf00174944正常合入；真实FallMotion/LandingMotion由00唯一Actor writer自然执行，匹配COMMITTED后才Landing。 |
| 10B Edge Recoil | 285896da24b4f5ec223fe8bf3f75e29fa1d18381模块正常合入；原生Edge → 00 Presenter正式接线PENDING，首包不包含。 |
| 05 Art | 20模块/10对Surface/Inner及Fall VFX已在独立Art环境技术验证；asset1.0.0、metadata1.0.1，ART_PENDING_USER_REVIEW。主项目接入NOT_RUN。首包使用隔离BoxMesh与面标记。 |
| 11 Audio | 4afbd068fae74a826dae4db04c2c612af23fa861及真实DTO兼容7363e9e7d7849018cc456ae866a60e23472591d6正常合入；79 Unit +48实际播放 +16真实Facade DTO +10设置=153 Owner检查。完整自然Host播放/人工试听PENDING。 |
| 07 UI | d9dd3317e558f0d8380a2e6635452308d49240f1及结构化Safety兼容6d3bf4b7f5120b44dad4790b657a4be953dd4954正常合入；180 Owner检查及172源码绑定核验通过。完整Host HUD/Reduced Motion/设置接线PENDING。 |
| 03 Quality | 9f378d0f29694686f41eb605640dcd35e09de26a正常合入；94矩阵/12 Core case保留独立pending。00已执行独立真实图形A26、B26、Camera拒绝17，共69检查并单独登记3个正式结果；没有把全矩阵升级为PASS。 |

## 实际自动验证

| 证据 | 结果和边界 |
|---|---|
| bridge_bound_01 | 54 Unit PASS，真实10A；01 DTO/Safety及finish/commit double明确标注，不是实际Fall权限证据。 |
| core_real_01 | 54 PASS，默认正式Facade/Kernel/Safety、09作者数据、10A和00自然闭环；doubles=[]。 |
| core_graphical_01 | 62 PASS，实际Windows/forward_plus图形进程，1152×648，8张PNG及实际连续帧轨迹；doubles=[]。 |
| i_core_rules_01 | 59 PASS，真实01规则/Safety，包含非法Camera、无连接、跨World和24朝向等专项；doubles=[]。 |
| i_core_replay_01 | 24 PASS，正式Baker/Validator/Explorer/Kernel/Softlock/TraceReplayer；LOGICAL_SESSION。v2 Graphical TraceReplayer专项仍PENDING，其fail-closed负例不记成Graphical成功。 |
| quality_i_a_01 / quality_i_b_01 / quality_i_cam_01 | 原始状态OBSERVATIONS_RECORDED保留；26/26/17、全部exit0/stderr0/failures=[]/doubles=[]。每轮1221实际文件SHA一致，1152 tracked Git blob一致；69项派生shader cache仅核物理字节，不冒充Git生产源码。 |
| Core包fresh startup | 原包真实进程34996，54 PASS、exit0/stderr0/doubles=[]；163源文件全部匹配Build及当前正式生产Git blob。 |
| main_startup_01 | 默认Main Scene实际10个headless frame启动，1检查、exit0/stderr0。没有重复旧通关/解锁/Cold Continue。 |

A真实高度降低；B真实高度增加；两者都连续屏幕向下。源/目标正式StateKey、same World、cube24 PRESERVE、自然单次提交、落地后普通移动/Goal、Pause/Busy、半空Reset旧身份失效和新动作恢复均验证。旧Roll/Perspective Connection由01的3557项既有回归及源码绑定保留。截图或静态投影不用于代替运行判定。

core_real/core_graphical及01专项原始执行HEAD为63eb5b3385cf3eff9c97a0c5991378e8115575a9，00测试WIP字节保留并随后提交；没有将原证据重标为最新提交重跑。03独立观察器实际CLEAN源为6074e48a8cfa98e34a2eb8533c37fa3aefdd97be。正式注册单独写在CORE_PLAYABLE_RECEIPT.json；原Candidate绑定仍TEST_DEPENDENCY_ONLY，receipt gate未删除。

## 第一轮独立Build与08

Build：`E:/godot/beta-sprint-builds/beta_pfall_core_20261010_01`。

冻结源码集成身份：**ee1ea27c292132a090e4294d6a18718a3d654086**。ZIP SHA256：`a5e9daf415c2c89a17c7cc56bab932b847b8fee6cef3f2532c9b61e980863024`。目录、ZIP及08副本均未覆盖旧QA对象；后续合并没有改变本包163个源Git blob。

启动：`pwsh -NoProfile -File E:/godot/beta-sprint-builds/beta_pfall_core_20261010_01/play.ps1`，需要现有Godot4.7.2；user数据落在包内独立qa-profile。F为作者Fall，WASD/方向键为普通移动，D可在落地后到Exit，Q/E转Camera，R Reset，Esc Pause，A/B按钮切地图。Space Shift不属于本独立实验场景。

08：**QA_HANDOFF_READY / RECEIVED**；已核163清单和ZIP、建立171文件一致隔离副本。Human QA **NOT_RUN / WAITING_FOR_ACTUAL_PLAYER**；首次理解性NOT_RUN。本轮08 P0/P1/P2/P3 **NOT_ASSESSED**。准备报告位于`E:/godot/beta-sprint-builds/pfall_core_focused_qa_20261009T172150Z/GAME_FEEL_HUMAN_QA_01_PARTIAL.md`；不得将自动输入记成人工体验。

首包不是五关新QA Build；正式Art/VFX/Audio/HUD/Edge未包含。第二轮完整Game Feel Build **NOT_READY**，待相应正式接线与专项证据，继续在已有Owner范围增量推进。

## 保全与余项

14,440项原五关生产、旧QA、Build payload/ZIP、Art pairs/UI/master字节及完整QA成员检查通过。Foundation仅消费用户授权的01 opt-in Fall交付，20个变动路径精确绑定26387d6；未开展通用Foundation开发。已验收L01-L05谜题、Shell/Save语义、冻结Art/合同不变，L06继续独立。STAIR_CLEARANCE=PARTIAL_PASS；STAIR_TRAVERSAL=NOT_RUN；L03首次理解性RETEST_PENDING。

自动Core当前未解决P0/P1：**0/0**；原五关历史P0/P1=0/0、P2/P3=3/1保留，本轮人工数量不填0。余项：v2 Graphical TraceReplayer单case、其余质量矩阵、Edge/VFX/Audio/HUD正式接线、Art review、人工试玩及第二轮Build。Owner03冻结SVG fresh-import ThorVG错误保留为Harness问题；Core包未消费该SVG，fresh startup stderr为空，不退回Runtime或修改冻结素材。

Working tree：封存提交后核验CLEAN。Push：NOT_RUN。
