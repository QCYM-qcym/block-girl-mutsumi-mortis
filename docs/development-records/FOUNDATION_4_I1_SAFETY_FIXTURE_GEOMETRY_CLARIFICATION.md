# FOUNDATION-4 I1 Safety Fixture Geometry Clarification

Status: REVIEW_READY — NOT_APPROVED
Classification: I1_FIXTURE_CONTRACT_MISMATCH
PRODUCTION_REGRESSION: NOT_PROVEN

## 原冻结fixture与实际RED

当前Integration基线为155fd179d20cc86884e0c974adb4c050c0b60ed1。I1计划原fixture：Surface floor=(0,0,0)、middle=(1,0,0)、exit=(2,0,0)，TOP均walkable=true；Spawn=floor/TOP，Goal=exit/TOP。固定MOVE为kind=MOVE、face_axis=0，即floor→middle。

真实Graphical RED：75 checks / 9 failures，exit1，stderr empty，doubles=[]。Before的正式capture、Bake、Codec与Host加载均成功，但MOVE REJECTED（status1、rejection_code2000），issue1601，path=safety.motion，entity_ids=[exit]：`Roll swept enclosure is not separated from an unrelated Cube.` 没有transition_started或提交。其余RED还包括尚未实现保存步骤造成的指纹/hash未变化，不能把全部九项失败归因于Safety。

原始证据：`E:/godot/worktrees/block-girl-foundation-4-integration/.godot/foundation-authoring-tests/integration_i1_red_20260929/I1/run/results.json`、`vertical-evidence.json`；拒绝详情见`.godot/i1-probe.log`。

## 正式Safety行为与责任归属

foundation/validation/safety_queries.gd的_roll仅豁免源/目标两个已证明共面、等高支撑Cube；其余同层Cube与正式滚动扫掠包络相交则返回UNPROVEN（SafetyStatus2、issue1601）。Kernel将不能证明安全的动作fail-safe拒绝。exit在紧邻destination的前进方向之后，正好触发这一正式分支。

因此本次证明的是fixture假设与现有Safety合同不相容，不是Runtime、Kernel或Safety回归。不得改Safety阈值、扫掠包络、1601语义，不得把UNPROVEN当SAFE，不得关闭或mock Safety。

## 候选探测方法

只读使用前次真实D_SAVED封存的作者payload，经Execution.verify正式wire解码取得有类型值；在内存深副本中只替换authoring CUBE exit的transform.origin。每个候选均由正式A_SCHEMA.validate_authoring和A_BAKE.bake_authoring重新校验/Bake，经默认RuntimeSession（正式KernelPort和Safety）load_level及request_action执行。APPLIED候选再用正式Safety.validate_motion验证返回的实际前后状态。未手写LevelDefinition，未写Session.state，未替换算法，未改fixture文件或封存包。

这是临时候选值探测，不是新的saved run、正式发布产物或I1 GREEN；借用原SnapshotIdentity仅作此内存Bake调用所需输入，不为候选声明新snapshot/fingerprint。未发布任何候选ArtifactRef，也未将其作为可信来源交付。正式I1须在澄清批准后保存选定fixture、重新capture再完整纵向验证。

探测为headless正式Runtime提案/信号检查；不声明新的Graphical/Tween/commit验收。transition_started来自真实RuntimeSession信号，之后用reset释放待处理活动。未手动finish。

## 正式探测结果

所有候选floor=(0,0,0)、middle=(1,0,0)，middle.TOP.walkable=true。Spawn、Goal身份、Inner、Intent、policy和MOVE均不变。

| exit logical position | A_SCHEMA | A_BAKE / Validator | Runtime load | MOVE | Safety | issue/entity | transition_started |
| --- | --- | --- | --- | --- | --- | --- | --- |
| (2,0,0)，原位置负对照 | PASS | PASS / VALID0；24 configurations，1012 checks | PASS | REJECTED1 / code2000 | UNPROVEN，由正式1601返回及源码分支确认 | 1601 / exit | NO |
| (3,0,0)，选择 | PASS | PASS / VALID0；24 configurations，1012 checks | PASS | APPLIED0 | SAFE0，issues=[]，正式validate_motion返回 | 无 | YES；token1/generation1/local |
| (1,0,2)，备选 | PASS | PASS / VALID0；24 configurations，1012 checks | PASS | APPLIED0 | SAFE0，issues=[]，正式validate_motion返回 | 无 | YES；token1/generation1/local |

选择exit=(3,0,0)：它是本次已探测的、保留原X轴排列且只将原exit沿X移动一个逻辑单位的候选；选择依据是正式Safety SAFE及Runtime APPLIED/transition_started，不是视觉距离猜测。不声称穷举所有可用坐标。

探测进程exit0、stderr0 bytes；三候选均只改变一个作者记录。原位置保留为负对照，明确证实调整针对扫掠几何冲突。证据目录：`E:/godot/worktrees/block-girl-foundation-4-integration/.godot/i1-geometry-probe/`，包含probe.gd、results.json、stdout.log、stderr.log与before-files.json。

## 拟批准变更与冻结不变量

仅申请将I1基线fixture中exit的逻辑坐标由(2,0,0)改为(3,0,0)。保留独立exit Goal Cube；Spawn仍floor/TOP，Goal仍exit/TOP。floor/middle相邻关系不变。现有fixture本轮没有应用该变更。

批准后的Before→After唯一玩法字段变化仍是middle.TOP.walkable true→false。两轮动作同为floor→middle，Spawn、Goal、其余Face、Runtime policy、Baker和Host均不变。After必须重新保存/capture/Bake/canonical/Host，形成新run/snapshot，要求Before APPLIED+自然Tween单次commit、After REJECTED且无commit，并验证准确产物与拒绝历史fallback。测试结束恢复walkable=true并重新验证作者/Bake。

本次候选探测只证实Before提案与Safety，不替代后续After单字段变化及完整Graphical纵向验收。

## Scope与Owner影响

I1证明Saved Authoring→Runtime的单字段因果链，不是完整Acceptance。exit移动后与middle之间有一格空隙；不在本澄清中承诺完整Goal路线可达、Solver SOLVED或零Softlock。原计划中“恢复可解源”的措辞不能由本次Bake有效性推断为已验证可解性；本澄清拟将本I1 fixture验收限定为恢复合法基线，后续质量/I2/I3需各自正式验收。

影响仅Integration的I1 fixture/test。A_SCHEMA/A_BAKE/D_PROTOCOL/D_SAVED/D_HOST及正式Safety/Kernel/RuntimeSession均不变。Design Spec、Tool Contracts、五份Plans原字节不变。本澄清待批准，不能自行覆盖冻结坐标或宣布I1通过。

I1: BLOCKED_PENDING_CLARIFICATION_APPROVAL
Commit: NOT_RUN
Push: NOT_RUN

Recorded at: 2026-09-29T00:50:33.851658+08:00

Evidence SHA-256:
- probe.gd: `e3436483e20a597460e7008cd23799c71c4287139e72c63b534fbfdce368b1fa`
- results.json: `22743179f7ea3b28cc927b22b7d9aa646742482b1348d07351002f54a033c93e`
- stdout.log: `d83ff98926f5a15e206de132167274b146ea50522c6149aae8db2cb582770611`
- stderr.log: `e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855`
