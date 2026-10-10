# PFALL_YELLOW_TARGET_LANDING_FIX_REPORT

**PFALL_YELLOW_PLATFORM_LANDING_PASS** — 新黄色目标/曲线版本的专项可玩修正已通过真实验收。范围是独立实验 MAP A/B；Human QA NOT_RUN，完整 Beta QA 不在本收据内。

Integration Commit / 冻结 Build source：`a741ee5e29dd2a849df13ff40100c08a9f1a2dc7`。
03 正常 merge：`bf7f2a51e2ad8a9c54a91199d61b1b12c4e5632c`，Owner delivery `4506b9b0896fc2d4b31b9a691afb3eb96bf929ef`。719个包内生产文件及主配置与 merge 后当前生产逐字节相同；后续03提交仅测试/docs。

## Root Cause

实际旧图形审计 `audit_red01`：27checks/6预期失败，stderr0/doubles[]。确认 **A + C + E**：作者 target 指向下方蓝块，黄色原位置是旧 exit；原允许路径没有实质水平离边；Landing压缩/回弹以中心变形，底部接触偏离承载面。B（错误目标投影）不成立：Presenter确实投影了旧正式target。D（角色与平台混淆）不成立：Actor/平台实体不同。旧Core/Logical/Graphical PASS证明旧作者数据，未用于冒充本次修正通过。

## Formal geometry and identity

Affected Map：正式实验MAP A/B，新schema3/foundation.game_feel.v2/foundation.rules.game_feel.v2；EAST camera1，原意图MOVE U_NEG（face_axis2）。

|字段|MAP A|MAP B|
|---|---|---|
|Source Face|source/TOP（face4）|source/TOP（face4）|
|Source Anchor2|`(0,5,0)`|`(0,5,0)`|
|Source actor center|`(0,3,0)`|`(0,3,0)`|
|Target Yellow Platform Face|target/TOP（face4）|target/TOP（face4）|
|Target Anchor2|`(-6,1,8)`|`(-6,9,8)`|
|Target support world point|`(-3,0.5,4)`|`(-3,4.5,4)`|
|Target actor center|`(-3,1,4)`|`(-3,5,4)`|
|Height|真实降低2world units|真实增加2world units，屏幕下降|
|Forward departure screen displacement|32.113px|31.394px|
|Rendered net descent|222.377px|86.452px|
|Landing最大支撑误差|5.96e-8world units|0|

Anchor2为加倍坐标，不把支撑面Anchor冒充角色中心。Actor Visual Root为 `AuthoritativeCubePose`，本体为其子Mesh `CubeBody`；独立地图根 `FormalPlatforms` 下有 source、target、blue_reference、exit四个可见平台。正式黄色实体 `FormalPlatforms/target`，蓝色参考实体 `FormalPlatforms/blue_reference`。蓝色参考所有Face不可走；黄色只作Host角色标识，不授予Runtime权限。无隐藏承载格。

完整原生session/run/generation/transaction/is_global身份、Source/Target Pose、授权轨迹、相机、完整StateKey、各帧Transform与最终姿态在 `evidence/natural_curve01/report.json` 及包内 `evidence/package_natural01/report.json`。正式target状态保持Orientation0；之后U_POS Roll到exit/TOP Goal为Orientation12。

## Owner changes

- **09**：`ad8f4259df69a7e726762d6f42d95e00263eecf3`修正原黄色位置目标及独立可见exit；`36f46a1659db7339bd27a53338959adf57452e61`接入正式schema3闭合作者字段。source与蓝色参考、EAST、PRESERVE、两图高度反转和Fall→U_POS→Goal保留。旧v1/schema2输入按历史fixture验证，未迁移。
- **01**：`fd22434d3eb0de52a764cb98222371a39412635a`实现必要的显式新profile/Codec/Safety证明及纯Sampler。原冻结polyline证明不能授权自由曲线，因此按00补充合同 `ec826753435458abc41cc365e4b57dba27767fbd`注册新版本。精确有界dyadic cube sweep覆盖所有同World实体；未解返回UNPROVEN，不能帧采样SAFE。复用正式Kernel/Solver/Trace/Replay；原schema1/schema2规则保持。Owner4330检查与本次集成证据分别登记。
- **10A**：`07bb0afea4b327ca2d3c0bbc5d84c97204e39e7b`接触节奏；`f2ec5c08dbc3fb5b0fba0cce709376ddcd443e96`仅消费01正式Sampler及event.v2。正向Departure→C1连续Descent→COMMITTED Contact→压缩/回弹/Settle，不选择目标、不自行生成曲线。`09f1f681575674a49a75402e7ea4d922c6d8d72b`绑定实际正式Sampler依赖，生产代码未再改。其7556Unit/249私有预览保留明确doubles声明，不算集成Real。
- **00**：`9533f102095ed9ee011bfa2aa046d6f1f4504780`真实CubeBody角点支撑补偿；`dcdb36c94bf553058152e8041dc880968dfdc048`共享Presenter/Host严验版本、正式端点、原生identity及角色实体接线。只有Landing视觉形变补偿，最终全部偏移归零；不改变StateKey、权限或Cube Orientation。
- **11 / 07**：`2f98464f4d5349d3ab8463bd4de3c9532c480b0c` / `3e75c9b135a40f13c83af8f4bb9fe65f87b159e1`最小event.v2适配。Audio只在真实COMMITTED接触时播放一次Impact；Reset取消无幽灵声；UI仅清除同版本/identity反馈，沿用一个SaveStore。

Owner范围/提交blob SHA核验见 `RUNTIME_MAP_INTAKE.json`、`ANIMATION_FINAL_BINDING.json`、`CONSUMER_INTAKE.json`、`QUALITY_INTAKE.json`。基础冻结合同SHA256仍为 `6224f8cd364f98da41822eabe7ba2973fa2db01d030373e7b3e94d69f35f23de`。

## Actual acceptance

Forward Departure：PASS。Continuous Descent：PASS。Yellow TOP Landing：PASS。Wrong Blue Target：REJECTED（正式落点从未选blue_reference）。Landing/Rebound：PASS。Orientation：PRESERVE。Fall→Roll→Goal：PASS。MAP A/B：PASS。

|验证|实际|
|---|---|
|00新source图形/生命周期/Formal/UI/Audio|1000checks PASS；9个真实图形进程|
|00独立进程冷恢复|27checks PASS；2个真实进程|
|03独立正式专项|1703checks PASS；7份收据|
|03 Formal Graphical TraceReplayer|211checks PASS，8matched steps；与Logical分开|
|03 Logical Session Replay|PASS，4matched steps；同次完整原状态图及Fall边|
|03取消生命周期|1017checks PASS，18旧取消/0旧迟到完成/36新匹配步骤|
|03长按/快速输入|25checks PASS，A66/B68真实hold帧，每图仅1次Fall提交|
|旧Perspective Connection|本轮66checks PASS|
|旧schema1/schema2|16checks PASS，正式历史hash保持|
|L01–L05受影响图形回归|206checks PASS；未改谜题内容|
|1920×1080 /1280×720 /960×720|各230checks PASS；真实像素尺寸|
|包内真实执行|409checks PASS：natural51、formal101、matrix230、两次冷启动27|
|包内Formal matched steps|8|
|旧QA/美术/源绑定保留|16001checks PASS；旧包、截图、日志、存档及成员列表未覆盖|

所有接受的真实收据checks>0、exit0、failures=[]、stderr空、doubles=[]、source_drift=[]。这些是各证据链的断言数量，未将重复执行或文件哈希计为独立玩法案例。03 Unit52另列，不添加到1703Real。

03的参考变体矩阵为12/12 PASS：第11项使用FORMAL_KERNEL_GAMEPLAY正式逐动作完整七字段StateKey/State参考，与真实3D完成一致。**按用户原始Pixel措辞登记：11项PASS /0FAIL /1项PENDING**，仅CASE11实际schema3 Pixel链对比缺正式入口；Pixel图形NOT_RUN_UNSUPPORTED_SCHEMA3_PIXEL_STACK。没有将正式Kernel参考或Logical Session冒充实际Pixel执行，缺依赖只保留该case，不阻止已通过的黄色目标可玩修正。逐项矩阵见03 `docs/beta-sprint/game-feel-owner-03/yellow-target-01/MATRIX_12.md`。原94矩阵继续54PASS/0FAIL/40PENDING，不把Art/Audio/UI/Human/性能未执行项强制升级。

新生产缺陷P0/P1：0/0。保留既有P2（EDGE人工跨版本Interrupt门禁及直接Facade Reset reason观察项），不阻塞自然Fall。失败/诊断执行保留并单列 `HARNESS_NOTES.md`；未覆盖raw或放宽正式断言。音效验证为真实COMMITTED接触回调及实际AudioStream播放；硬件A/V感知由08验证。

## Visual evidence

真实Godot4.7.2 / Windows / D3D12 Forward+。每图六阶段及逐帧数据由实际Baker/Runtime/Presenter驱动；未用修图、Mock事件、人工瞬移或固定计时器制造完成。包内自然执行重新采集了相同六阶段。

|阶段|包内MAP A|包内MAP B|
|---|---|---|
|出发前|a_01_source.png|b_01_source.png|
|离边|a_02_departure.png|b_02_departure.png|
|下坠中段|a_03_mid_descent.png|b_03_mid_descent.png|
|即将接触|a_04_pre_contact.png|b_04_pre_contact.png|
|黄色触地|a_05_yellow_contact.png|b_05_yellow_contact.png|
|回弹结束|a_06_settled.png|b_06_settled.png|

完整绝对目录：`E:/godot/worktrees/block-girl-foundation-4-integration/docs/beta-sprint/game-feel/yellow-target-01/evidence/package_natural01/`。源版独立目录为同级 `natural_curve01/`。Bridge直绑B时临时CoreLab标题仍默认MAP A；B身份由正式level hash、StateKey、Target Pose与路径绑定，未据此签UI验收。正式Shell A/B入口分别调用真实load_map。

## New Build and QA

真实独立目录：`E:/godot/beta-sprint-builds/beta_pfall_yellow_target_20261010_01`。
启动：`pwsh -File E:/godot/beta-sprint-builds/beta_pfall_yellow_target_20261010_01/play.ps1`。
类型：SOURCE_PLAYABLE_REQUIRES_GODOT；需要实际Godot4.7.2，不冒充独立EXE。

ZIP：`E:/godot/beta-sprint-builds/beta_pfall_yellow_target_20261010_01.zip`。
SHA256：`921b2c1bae7d9e8025ec47ca42a118530fe8dfee04969a2014121309141e961c`。

997个清单文件、1000个ZIP成员，测试后再次按原字节核验；719个生产文件与Quality merge后源码一致。QA `user://` 使用独立 `qa-profile`，08专用目录尚未创建；自动验证均用外部独立测试profile。正式菜单保留五关；右下角错视实验进入MAP A/B。A/Left为原合法前进Fall，F选相同作者连接；落地D/Right作U_POS Roll至可见exit Goal。Q/E、R、Esc和Settings沿用正式Host。

QA handoff：准备好实际路径、启动、源身份、全部关键阶段与针对性清单；发送及08状态单列 `QA_HANDOFF.md`。Human QA：NOT_RUN。05扩展Art仍PENDING_USER_REVIEW，实验BoxMesh不替换冻结美术。Runtime连接准备度Facade继续PENDING；STAIR_CLEARANCE=PARTIAL_PASS，STAIR_TRAVERSAL=NOT_RUN。

正式integration/foundation-4-authoring引用仍 `99f2f1db9d9646d8fc7f3856fc4e64df81ff6cff`。本日两次正式窗口已关闭；候选Build和验收完成，正式ref提升等待下个允许窗口。没有修改此政策或伪称已提升主分支。

Working tree：Build source a741ee5生成时CLEAN；最终closeout提交后另行核验。
Push：NOT_RUN。
