# FOUNDATION-4 D3 Host Execution Binding Clarification

Status: D3_HOST_EXECUTION_BINDING_CLARIFICATION_REVIEW_READY
Date: 2026-09-27 (Asia/Shanghai)
本稿待批准，不授权实现或登记交付。

## 1. 前置批准与本轮审计

Stage Result Schema approval commit：74892ba39c283e24efbd0755e85e552b5a685784。
批准正文SHA：DBE2B5B4EA01F91160FD8E9F6D939766E5E0D2F319F84D6F26A80C0D06653AD0。
该批准明确排除D3_HOST_EXECUTION_BINDING，本稿只解决这一独立身份/运行绑定问题，不改动该批准正文或记录。

沿用已确认事实：materialize只能恢复input.ready绑定闭包，旧sealed input不可修改，每run固定execution/project/；模块变化改变execution_digest；ArtifactRef不可跨run；旧BAKE/source证明不得改写。

补充只读检查限Integration当前已登记源码：execution_project.gd prepare遍历modules时要求path.ends_with(".gd")并添加每个脚本的.uid；_closure只遍历gd文本引用，虽然识别gd/tscn/tres路径，但未提供把非gd资源纳入白名单的入口。4D Plan文件表及D3明确要求whitebox_host.tscn。因此现有代码可容纳新增gd模块，但不能完整封存计划中的宿主场景。这是本稿D_SAVED实现影响判断的直接证据，不来自Owner WIP推断。

## 2. 唯一选择：同保存源的新run

Selected execution model：从同一个已保存作者fixture重新执行正式D2 capture_saved，使用已交付且已登记的新D_PROTOCOL及完整D3宿主执行闭包，创建全新run/snapshot，再materialize，并在该新run执行正式A_BAKE→BAKE stage publication→MANUAL_RUNTIME。

不采用旧run中途换工程、不引入execution generation、不增加双执行身份字段、不设计跨run ArtifactRef。新run内BAKE与MANUAL_RUNTIME使用同一完整RunIdentity及execution_digest。旧run身份与最终run不同，不以相同content_hash假装同一identity。

这明确允许本轮提出的最终流程重新对同一保存源执行正式Bake，区别于此前禁止D3加载器在运行时偷偷Bake补缺。正式Bake仅在新run的BAKE阶段由4D编排调用唯一4A适配，不能在whitebox入口或canonical_loader中Bake。

## 3. 旧预检基准（不得升级成最终产品run）

Old action-capable run = PREFLIGHT_ONLY / COORDINATION EVIDENCE
run_id = 4286c860-a388-42c9-ab64-d892553e747a
snapshot_id = 20a3bad6-2d91-42c0-9018-592818a17721
source_fingerprint = 45464787575bac5db6563352b21635910455cebaafe32a12e4a0cb77d342f8b5
execution_digest = e1882cf51fc2165bf5a809f9c7410c15c22b1049855c86d67a78669b25f4b5ea
canonical content_hash = 51aa7a4cf9b9328ed533434bf579b4ab9ae8393687f33fcc39a982f3f6d8a72e
canonical byte SHA-256 = 22f63447bc282029190d0c8b29a2016630c176b8dcce91dc2b1c94a9677484f9
canonical byte_length = 4171
fixture commit = 323891ec27859a60d33fe2d59c2633621b7f55d8
fixture root = res://tests/foundation/authoring_integration/maps/d3_action_capable/level.tscn

旧run已证明MOVE/face_axis=0为LOCAL APPLIED、ROTATE_INNER/delta=22为GLOBAL APPLIED，均发出transition_started。此事实不要求重新设计地图，也不证明Tween自然完成。

旧协调canonical、JSON及旧ArtifactRef仅供比较/审计；不成为最终run的加载输入，不把旧SnapshotRef传给新宿主冒充新执行闭包。

## 4. Final run身份规则与同源证明

- run_id：由正式capture分配新UUID，与旧run不同。
- snapshot_id：由本次capture分配新UUID，与旧snapshot不同。SnapshotIdentity既有四字段不变。
- source_fingerprint：新capture实际计算，必须精确等于上述旧基准，不能赋旧字符串伪造相等。
- 作者语义：同一fixture及完整保存依赖保持一致；用实际封存authoring wire及source_manifest对照旧证据，核验作者源字节/声明闭包，不能仅依赖测试名称相同。
- canonical：新A_BAKE真实返回由正式Codec encode/decode；content_hash必须等于上述基准，并要求本fixturecanonical字节SHA及长度相等。任何差异停链，不更新预期值直到绿色，不用旧canonical回填。
- execution_digest：唯一Wire.digest("versions",新VersionsRecord)的实际结果，必须绑定新模块/资源清单及配置。不得复用旧e1882cf5…；closure确有变化而digest沿用旧值是错误。

source_manifest及authoring_payload_digest不应因单纯工具模块变更而变化；execution版本身份独立。如果新的已批准源schema改变了canonical source编码导致fingerprint不同，本流程不能自行豁免“same source fingerprint”要求，应停链报告合同差异，另行审阅迁移，不在本稿引入兼容投影。

如当前批准source_intent_digest更新已登记，新SnapshotIdentity按其正式规则产生摘要，不能为了复刻旧run而强行填null；它不进入本fixtureformal Level或source_manifest结构。本稿不撤销该独立批准要求。

交接记录应使用明确表述：same source content, different execution run。旧/新两套真实ID、源摘要、canonical摘要、执行摘要可在协调审计记录并列；这不是产品跨run ArtifactRef。

## 5. 新execution closure与精确D_SAVED影响

新run创建之前，VersionsRecord.modules/configuration必须实际覆盖：最新D_PROTOCOL stage_result及其依赖、canonical_loader.gd、whitebox_host.gd、whitebox_entry.gd、计划中的whitebox_host.tscn、RuntimeSession、PrototypePresenter、InputMapper、所有显式动态及静态依赖、脚本UID、有效工程配置和依赖声明本身。engine身份沿正式合同验证。不得从活动4D工作树临时补文件。

D_SAVED implementation = UPDATE_REQUIRED。

精确缺失能力：当前execution_dependencies modules仅准许gd，prepare自动为所有模块添加.uid，_closure不会从tscn/tres进一步遍历依赖，因此不能封存并完整验证D3计划中的whitebox_host.tscn及其可能资源依赖。把tscn放modules会被拒绝；把它只放dynamic又因不在modules而拒绝。仅重跑现有D2或增加gd白名单不能解决。

最小更新范围归4D：execution_dependencies.json声明/登记完整宿主闭包；execution_project.gd支持显式白名单中的受控场景/资源文件、按文件种类处理UID、遍历并验证其依赖，并在VersionsRecord.modules登记每个实际文件SHA。保留未知类型/路径逃逸/缺文件/动态补洞拒绝，不把整个项目打包。声明格式如需演进须显式版本校验，不静默把旧gd-only声明解释为任意文件列表。

capture_saved的“新run、一次封存、input.ready最后写”生命周期无需改变；materialize仍从本run封存文件生成本runexecution/project，不新增跨run/中途升级API。SnapshotRef、SnapshotIdentity、RunIdentity、ArtifactRef及input.ready外层schema均不因本模型扩字段。功能更新是闭包覆盖能力，不是输入身份模型变更。

如果未来4D提出删去计划宿主场景、改成纯脚本生成来避免资源支持，那是另一实施范围选择，不能未经审阅把本稿UPDATE_REQUIRED改成NONE。当前结论按已批准计划需要的真实场景闭包确定。

4D需补真实D2回归：脚本/场景/资源缺失、修改SHA、UID不一致、静态/动态引用未声明均拒绝；活动源移走仍可materialize；实际新增入口/资源进入versions及execution_digest。仅D3替身通过不构成此交付。

## 6. 同run正式BAKE发布与禁止跨run引用

最终run必须自行从本run封存authoring输入执行正式A_BAKE，获得本runBakeProvenance及真实validation/source_map，再经已批准publication顺序发布：

- artifacts/stages/BAKE/canonical.level
- artifacts/stages/BAKE/stage_result.wire

全部ArtifactRef相对新run root，不接受指向旧run/协调目录的绝对路径、..、symlink/junction或隐式外部查找。新canonical由新BAKE产生，内容与旧预检一致是验收条件，不是复制旧产物取代作者链的许可。

stage_result.run_identity必须等于新input.ready的identity，BAKE provenance run_id/snapshot_id/source_fingerprint等于本次捕获值。WorkerMessage按已批准协议仅引用该新run stage_result ArtifactRef并核验完整identity、sequence、stage_id与hash。input.ready不回写；stage输出位于artifacts，manifest仍最后发布。

## 7. BAKE → MANUAL_RUNTIME绑定

MANUAL_RUNTIME.run_identity == 最终新run正式RunIdentity == 本runBAKE stage_result.run_identity。MANUAL_RUNTIME内存StageRecord十四字段保持；本稿为其input_refs冻结以下唯一封闭绑定值：

```text
{
 bake_stage_result: ArtifactRef,
 canonical_content_hash: String,
 snapshot_id: String,
 source_fingerprint: String
}
```

bake_stage_result路径固定artifacts/stages/BAKE/stage_result.wire；长度/hash/format_version按批准stage_result ArtifactRef规则。其余三个字段分别等于该BAKE中正式Codec验证的Level.content_hash及本runidentity对应值；不能从协调JSON取值。canonical具体路径只能从通过校验的BAKE native_result.level取得，不能由UI/参数任意指定。

先校验input.ready、BAKE wire及完整RunIdentity，再核验canonical ArtifactRef/bytes/Codec/content_hash，最后才加载Session；任何失败不产生可运行旧level。宿主真实engine/module/configuration必须匹配同一execution_digest。

此处只冻结MANUAL_RUNTIME的输入绑定，不冒称其完整native_result/evidence_refs持久化schema已交付。已批准stage_result注册表目前仅支持BAKE分支，不能把MANUAL_RUNTIME当BAKE编码；若D3需要发布MANUAL_RUNTIME wire，其完整stage-specific storage branch必须另行冻结/注册并真实实现，不能放宽任意Dictionary。本稿的执行身份模型不依赖提前伪造该wire能力。

## 8. 真实受控入口与验收边界

最终D3必须使用capture/materialize真实返回路径，从<new_run>/execution/project/启动：

```text
Godot --path <new_run>/execution/project/ --script res://tools/foundation/authoring_acceptance/whitebox_entry.gd -- --run-dir=<new_run>
```

这沿既有4D Plan入口参数，不新增直接canonical路径参数。路径为本地进程启动上下文，不进入stage_result wire。记录新PID、engine、命令行、受控project路径、run身份、输入/输出摘要、exit/stdout/stderr；不能复用旧PID或主项目preload结果。使用真实图形运行方式，不能以headless开始信号证明Tween。

4D负责证明原动作实际APPLIED/transition_started、真实Presenter/Tween、natural finished、正确finish_local/finish_global、Session commit、reset/late callback，以及SESSION_WRITE_EXPOSURE的RED→GREEN审查。Coordinator现有预检只证明地图动作能力。本轮不运行这些测试，不修改Owner九个WIP。

## 9. 前置交付、启动顺序及无循环交付要求

1. 本稿精确审批完成前，身份合同仍pending。
2. 4D交付新的D_PROTOCOL stage_result update；Integration核验并登记正式receipt。旧6176a45不可冒充包含新协议。
3. 4D完成并交付本稿所需闭包支持与宿主源码依赖，保持Owner路径；Integration按实际更新范围登记D_SAVED更新/复验。不能先登记D_HOST最终通过。
4. D3 Owner可在其受控候选版本中将已完成待验宿主模块列入执行闭包，先获得可审计的精确源码版本及依赖证据，再新capture/materialize完成验收；不要求先有D_HOST最终slot才能测试自身，否则形成循环。但最终接收D_HOST必须核验测试所用源码与Owner最终交付一致，不能靠未记录活动WIP。
5. 同fixture新capture → 新BAKE publication → 同run受控whitebox入口 → Tween/commit等真实证据 → Owner review → D_HOST交付 → Coordinator另行验收登记。

D_PROTOCOL: WAIT_FOR_UPDATED_RECEIPT。
D_SAVED implementation: UPDATE_REQUIRED（具体闭包缺口见§5；不扩大输入包schema）。
D_HOST: BLOCKED_PENDING_APPROVAL_AND_PROTOCOL，仍须完成真实实现/验收。
I1: NOT_STARTED；未来消费更新后正式D_PROTOCOL/D_SAVED/D_HOST，正式Authoring→Runtime语义不变。本稿不授权提前I1。

本方案取消“旧run原BAKE身份与新宿主执行身份混放一个run”的需要；旧Stage Result澄清中对该做法的警告保持正确，但本稿不选择该路径。不改已批准文件字节，不创建跨run产品绑定record。

## 10. 本轮交付限制

仅新增此待审澄清，SHA在外部报告计算以避免自引用。未产生最终run、新receipt或虚构ID，未启动A4/D3实现或I1，未修改封存预检run与任何Owner WIP。Commit: NOT_RUN。Push: NOT_RUN。不得把REVIEW_READY解释为已批准或D_HOST完成。
