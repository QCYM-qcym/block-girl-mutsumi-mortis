# FOUNDATION-4 D3 Host dependency handoff

D3_ACTION_CAPABLE_SAVED_ARTIFACT_READY
STAGE_RESULT_SCHEMA_CLARIFICATION_REQUIRED
D_HOST_DELIVERY_READY: NOT_ISSUED

本轮仅提供动作能力产物与待审协议。未启动I1，未修改Owner源码/WIP，未触碰用户指定PID 7100/11176。

Source fixture: tests/foundation/authoring_integration/maps/d3_action_capable/level.tscn
Source fixture commit: 323891ec27859a60d33fe2d59c2633621b7f55d8
D_SAVED implementation: a8ac1d4e05d9b9ff4f5b0df0a400677e413d88e0
D_SAVED receipt: f4e8ccd7144084b2def96d1020026c7eefd9c9f6
A_BAKE: e0940278fe425d7f77eb6a5b4ea042067606258d

Fixture由现有作者声明profile扩展，新增独立相邻Cube六Face Resource，并声明Inner旋转状态/意图。没有复制旧Runtime产物或手写Level/canonical。

实际顺序由现有D2接口决定：capture_saved先封存authoring及执行源、最后写input.ready；随后只读取sealed authoring调用正式A_BAKE/Codec，materialize既有执行闭包。没有把后来canonical补写进已封存input.ready。canonical置于独立显式交付根，不能把它冒称input_manifest附件；正式阶段结果引用/最后发布规则待独立澄清批准。

run_dir:
E:/godot/worktrees/block-girl-foundation-4-integration/.godot/foundation-authoring/runs/4286c860-a388-42c9-ab64-d892553e747a

execution_project:
E:/godot/worktrees/block-girl-foundation-4-integration/.godot/foundation-authoring/runs/4286c860-a388-42c9-ab64-d892553e747a/execution/project

run_id: 4286c860-a388-42c9-ab64-d892553e747a
snapshot_id: 20a3bad6-2d91-42c0-9018-592818a17721
source_fingerprint: 45464787575bac5db6563352b21635910455cebaafe32a12e4a0cb77d342f8b5
execution_digest: e1882cf51fc2165bf5a809f9c7410c15c22b1049855c86d67a78669b25f4b5ea
source_intent_digest: null（指定旧D2实现真实行为，不用于I1）

完整SnapshotRef及实际动作结果见E:/godot/foundation-4-d3-unblock-20260927/delivery.json。该JSON是离线交接证据，不是formal stage_result或D3加载sidecar；Godot SnapshotRef的level_id为StringName，其余标量类型沿正式SnapshotRef，JSON仅展示值。

canonical根：E:/godot/foundation-4-d3-unblock-20260927
ArtifactRef：

```json
{"relative_path":"canonical.level","byte_length":4171,"sha256":"22f63447bc282029190d0c8b29a2016630c176b8dcce91dc2b1c94a9677484f9","format_version":"levelcanonical.v1"}
```

format_version为本次交接标识/待审协议提案，不宣称是既有D_PROTOCOL已批准枚举；字节完全由正式LevelCodec.encode生成并decode验证。
content_hash: 51aa7a4cf9b9328ed533434bf579b4ab9ae8393687f33fcc39a982f3f6d8a72e
input.ready: VERIFIED，byte_length=71419，sha256=e2a3d64ce2dceb1b86d1662e9e1da0a429e2f4ba2905845b2b5e6d0681aa0283。

## 实际预检

生成/预检PID 29388，exit0，stderr空，doubles=[]。
独立受控execution_project预检PID 15884，exit0，stderr空，doubles=[]；只调用Codec.decode和正式RuntimeSession，不重新Bake。

LOCAL：action={kind:0,face_axis:0}（MOVE），status=APPLIED，transition_started=YES，is_global=false，token=1，commit_count=0。
GLOBAL：action={kind:3,rotation_delta:22}（ROTATE_INNER），status=APPLIED，transition_started=YES，is_global=true，token=1，commit_count=0。

两次各自从同一canonical的初始Session开始，检查开始信号后reset丢弃未完成动作，没有调用finish_local/finish_global。Presenter/Tween/natural finished/Session转场commit: NOT_RUN，Owner=4D-3。

所有证据位于E:/godot/foundation-4-d3-unblock-20260927，包括preflight.gd、controlled-preflight.gd、原始stdout/stderr/process记录、sealed-inventory.json。完整包文件摘要清单用于交付后核验。input.ready与输入blob未修改；materialize只从sealed执行blob建立受控工程。交付前后不得修补该run包。

## 保留的失败证据

首次PID30140因项目尚无全局类导入缓存导致FoundationToolWire编译失败，未成功capture；仅核对其命令行后结束本轮自建失败进程。未结束用户列出的PID。
随后editor import进程退出码-1073741819，stderr空，缓存已生成；保留import原始日志，不将此过程计为通过。
第二次capture成功但正式Baker拒绝缺失rotation intents的fixture（code1502）；保留preflight2日志及其run，不修改失败密封包。
只修正Integration作者fixture补齐意图声明后新建独立run，最终上述两个新进程通过。没有放宽正式校验。

## 剩余阻塞

FORMAL_STAGE_RESULT_SCHEMA: NOT_READY，见FOUNDATION_4_STAGE_RESULT_SCHEMA_CLARIFICATION.md，待用户审阅，未自行批准。现有custom JSON sidecar不得成为最终协议。
D3_REVIEW_REQUIRED: SESSION_WRITE_EXPOSURE，4D内部处理，Coordinator未改源码。
受控包没有未交付whitebox_entry.gd；4D正式接入入口后必须创建新的完整执行闭包并实际启动入口，不能往本密封包塞WIP。提供路径不等于证明正式入口已启动。
I1仍等待已批准要求的D_PROTOCOL/D_SAVED更新；本轮NOT_STARTED。Push: NOT_RUN。
