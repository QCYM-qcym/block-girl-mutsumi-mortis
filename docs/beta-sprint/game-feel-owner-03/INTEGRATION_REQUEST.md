# 03 Quality — CORE_PLAYABLE 接线需求

基线 `2938d6e534f5b596bb320ce79d72b69f5923f3cd`，合同 SHA256 `6224f8cd364f98da41822eabe7ba2973fa2db01d030373e7b3e94d69f35f23de`。

首轮 CORE_PLAYABLE 不依赖 05/07/11；03 已准备 A/B 原生输入观察入口 `tests/beta_sprint/game_feel_owner_03/test_core_playable.gd` 和 12 项独立 Core case。入口不实现 Host、Presenter、Runtime、Safety、Solver、Replay，不写权威 State，不手动完成 Runtime transition。

## 00 首轮 Build 提供

请在 00 保留目录登记测试绑定文件，建议 `res://docs/beta-sprint/game-feel/CORE_PLAYABLE_QUALITY_BINDINGS.json`。这是 03 观察器的配置，不扩展 production port 或原 receipt schema：

- `contract_sha256`；候选 `registration_status: PHASE_EVIDENCE_ONLY` 或 `TEST_DEPENDENCY_ONLY`，也兼容后续 `REGISTERED_00_CORE_PLAYABLE`。候选运行不依赖自己的正式 Core receipt；receipt 是真实闭环 GREEN 后登记结果的门槛。每轮仍记录实际 HEAD/dirty/source；不能仅凭 JSON 状态文字签发 Real。
- `cases` 按 Core case ID 索引，每项提供实际 `host_scene`（00 的 `experiments/game_feel_01/host/` PackedScene）、`runtime_node`（01 明确的 `game_feel_event` signal）、`body_node`（实际角色中心 Node3D）、`camera_node`（实际 Camera3D）、`canonical_root`（把 body.global_position 转回正式坐标的实际 Node3D）。这些都是读取现有 Node 的路径，不要求新增 Host 方法。
- `native_inputs`：明确的实际键/鼠标序列及等待时间。观察器支持 key `{kind:key,key:W|A|S|D|Q|E|F|Space|R|Escape,pressed:bool}`，mouse_button `{kind:mouse_button,x:number,y:number,pressed:bool}`、mouse_motion `{kind:mouse_motion,x:number,y:number,dx:number,dy:number}`、wait `{kind:wait,seconds:number}`。它调用真实 `Input.parse_input_event`，不调用权限或 finish API。
- 若01 Facade是RefCounted而非Node，runtime_node指向实际持有它的Host节点，runtime_property指定已存在的Facade属性名。观察器只读取并连接该真实Object，不要求新Node wrapper。
- 若Camera是Host动态建立且没有稳定Node名，camera_node同样指向持有它的节点，camera_property读取已有Camera属性。
- 可在 Landing 后插入 `checkpoint`，提供 label、center2、preserve_initial_basis，用于继续移动前的落地检查；继而发送下一次移动。`settle_seconds` 由实际动画时序确定。
- `expected`：fall_count、connection_id、camera_quadrant、source_center2、target_center2。落地后移动可另外声明 final_center2 和 preserve_final_basis=false；负例必填 required_reason。连续 Fall 可先复用同一地图通过自然 Reset/reload执行两轮。

09 的实际作者输入交付为 `54ea24cd50c4bd45b083dc26487ff2b7afd2a703`。已从该提交读取其 Integration Request；尚未在 03 工作树 merge，也没有复制 09 production：

| Map | Connection | Source actor center2 | Target actor center2 | Camera |
|---|---|---|---|---|
| A | pfall_a | [0,6,0] | [-8,2,8] | EAST=1 |
| B | pfall_b | [0,6,0] | [-8,10,8] | EAST=1 |

09 当前 connection 明确 authorizes_traversal=false、Safety UNPROVEN、runtime schema PENDING_OWNER01。不能用它或静态落点 SAFE 代替合法完整 Fall。01 若经正式完整路径 Safety 得出地图需要修订，保持对应 case_pending，交回 09，不由 03 修改地图。

随后00提供09 exit增量 `82a8a7dc85205e9391551f24267f35f5abe53393`、10A交付 `4781dfcf`（完整SHA需正式receipt补全）。首轮A/B路线更新为Fall→target/TOP→普通MOVE U_POS→exit/TOP Goal；请在native_inputs中先记录Landing checkpoint，再送真实U_POS对应原生键，expected.final_center2使用实际exit数据，preserve_final_basis=false允许普通Roll的合法姿态变化。不要把Fall的PRESERVE要求错误套到随后普通Roll。03本次没有接入这些生产提交。

观察器保存 event 原始深快照、原生输入、真实 body/camera 逐帧位置与 basis、帧间隔和 CPU process 时间。验证自然 STARTED→COMMITTED、完整身份、唯一提交、完整 canonical next_state 一致、cube24 PRESERVE、实际中间位置和屏幕下降、落地端点；不以 ghost/静态连线证明播放。屏幕测量允许 0.25 像素噪声。记录原始 event 引用与快照以发现之后被生产者修改。

当前没有候选绑定时，该候选实际执行返回 case_pending、checks=0、source_sha=null。即使未来采集到观测值，也只输出 OBSERVATIONS_RECORDED；03/00 完成真实源、default pipeline 与完整 case assertion 核对后才登记Core receipt，再登记正式 Real/Graphical 结果。测试matrix的CORE_PLAYABLE_RECEIPT仅属于registration_requirements，不是execution dependencies。

## 准确候选启动入口

00的Host候选 `61ac470983d41ebd8a81ee44b01996ca185ae305` 已只读核对；没有在03树接入。其现有节点/属性可直接绑定，不需Host新接口。完整字段示例见本目录 `CORE_BINDINGS_EXAMPLE.json`；示例仅TEST_DEPENDENCY_ONLY，不能作为实际Build receipt，也未在缺01的03树播放。camera_property读取Host.camera，runtime_property读取Host.runtime，canonical_root为Host本身。A默认加载；B由00补实际原生按钮点击坐标，不能调用load_map代替自然输入。

在00已按受控流程接入各Owner后的实际工程运行：

```powershell
pwsh -NoProfile -File tests/beta_sprint/game_feel/run_quality.ps1 -Mode Candidate -Case CORE_A_NATURAL_FALL -Bindings res://docs/beta-sprint/game-feel/CORE_PLAYABLE_QUALITY_BINDINGS.json -EvidenceName <fresh-name>
```

Candidate启动器自动隔离APPDATA/LOCALAPPDATA，记录真实HEAD/dirty与Host/Presenter/animation/maps/01源SHA，使用真实图形进程，不加headless，不验证尚未存在的Core receipt，不输出PASS。每次只选一个Core case。该命令已实际验证缺绑定路径为checks0/case_pending且stderr空。Real/Graphical正式模式仍只报告尚未交付的case_pending。

## 01 正式版本消费说明

已从00正式集成提交63eb5b3385cf3eff9c97a0c5991378e8115575a9只读核对01接口：Facade.get_state/get_level；正式foundation/contracts/state_key.gd的StateKey.build按schema_version2输出statekey.game_feel.v1。03候选直接消费该路径，绝不自行拼key；在旧03树没有接入01生产实现，不把原v1控制结果冒充v2。拒绝按RuleRecords正式next_state=null，保存输入前/回调/下一帧get_state，并通过官方key验证不变。Fall structured safety_verdict/status/issues/evidence_ref原样保留，以正式key/profile核对proof引用。01显式kind8的intended_move_direction=null保持合法；03不强制它为MOVE FaceAxis。

请随交付提供Fall Solver、Replay与剩余Safety调用证据；这些独立case_pending，不阻止A/B候选执行。00自报Headless54/Graphical62尚未在03树重新执行，不复制签发。

原普通 Roll 与 PerspectiveConnection 另保留 Alpha 原生输入控制；P01 observation hash 不能冒充 formal StateKey。03 仅消费实际原 pipeline，不写第二份 P01算法。

## 冻结资源导入问题

2938d6e 新工作树首次 Godot 4.7.2 editor import 记录 `icons_source.svg` ThorVG canvas/error code1，import exit0 但 stderr 有错误。这是导入阶段失败，不能记为行为 RED或新动画回归。日志在 `.godot/game-feel-quality/setup_20261010/`。

Importer 自动将既有 `production/ui/beta_shell_01/icons_source.svg.import` 改成 valid=false，并生成旧测试/场景 UID、证据图片 import sidecars。03 保存该次输出和变动 SHA 后，把自己这次生成的 sidecars 移入 ignored evidence，并逐字节恢复该 .import 的原 HEAD blob；没有修复/提交冻结素材或修改其它 Owner源码。请 00 处理正确的 fresh-import 元数据/排除方式；03 不自行改变冻结 SVG、共享 .import 或项目配置。原测试矩阵与旧 QA 包没有更改。
