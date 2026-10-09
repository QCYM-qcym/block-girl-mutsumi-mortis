# L04_INNER_MOVEMENT_P1_FIXED — 交付回执

Production candidate commit：**2a2fd7ad06b5c139b51b77c8dae1a9289b0530e8**。Branch：fix/l04-inner-movement-p1。Baseline：991140292ac67e87d1751a062e7e96c7b9fee553。此候选已实际提交，提交后git status为空。当前回执与FILES_SHA256是后续docs提交，不改变被验收的生产内容或Godot fixture；最终delivery HEAD由提交后git rev-parse给出。

Root cause：L04 Inner包含Spawn(1,5)，却没有任何相邻落脚格，合法Shift后原Runtime正常拒绝四方向roll。Owner：**06**。Only production change：L04 Inner新增(0,5)，连接原岸(0,4)。L04资源SHA256：**10f7a6a69a5e42c3796a6d0546938c7378be10f705fff3e40baf27db24efa18a**。

Before：Input送达；world=graph_world=1 / NORTH / idle / 初始orientation；四方向短长8动作neighbor返回(1,5)，roll=false，commit=0，P01观察状态key不变。After：相同短按A，原neighbor=(0,5)，roll=true，commit=1，落定(0,5)，orientation正常滚转。Published Foundation StateKey/status/rejectioncode/Safetyissue不属于该正式p01入口；实际字段、动作表与前后key见DIAGNOSIS和原始report。

| 验收 | 实际结果 |
|---|---|
| L04正常完整通关 | PASS |
| Reset replay | PASS |
| Alternate camera replay | PASS |
| Goal | PASS，每条原Shell completed恰好1次 |
| Headless自然输入 | PID13392 / exit0 / 201checks / 3routes / 3Goals / 0fail |
| Graphical自然输入 | PID30536 / exit0 / 219checks / 3routes / 3Goals / 18原始截图 / 0fail |
| 原图Unit | PID43860 / exit0 / 45checks；L04 72/72可解，最少仍2次Shift |
| Shell精确问题回归 | PID28988 / exit0 / 59checks，短/长均GREEN |
| 独立Scene精确问题回归 | PID29152 / exit0 / 55checks，短/长均GREEN |
| L01–L03限定输入回归 | 修复后PID19592 / exit0 / 259checks / 48动作 / 0fail，源码/资源不变 |
| 独立只读审查 | 0 Critical / 0 Important；1 CLI Minor已修复并实测 |

QA保护：**3073项原字节与目录成员一致**，11次运行原日志SHA均核对，18图形截图原字节SHA均匹配。QA Build：IMMUTABLE。QA saves：UNCHANGED。旧截图/日志：PRESERVED。不得覆盖原beta_content_batch_02_20261009_01；本Owner只启动独立工作树，隔离PID test profile。

完整路径/状态/PID/源码SHA/日志/截图/保存校验见tests/beta_sprint/l04_inner_movement_p1/evidence及PROTECTION_VERIFICATION.json。FILES_SHA256覆盖唯一L04 Resource和两个Owner根的全部交付文件，自身显式排除。原wrapper源码副本保留，后续CLI guard只禁止误用standalone controls/playthrough；最终Godot fixture与被验收字节一致。

功能PASS不扩大为Human盲玩或完整五关链QA；旧三关仅限定输入回归。独立Scene及修复后controls退出的4 ObjectDB instances warning保留，原因未定位；正式Shell L04的最终自然验收stderr为空。unused冻结SVG导入错误保留，原.import恢复，Art源未改。报告不关闭既有P2或相关生命周期备注。

Foundation modifications：**NONE**。Art modifications：**NONE**。Shared Runtime/Presenter/Shell/Save、L01–L03与L05 modifications：**NONE**。Working tree on delivery：**CLEAN**。Push：**NOT_RUN**。Integration merge / QA原包更新：**NOT_RUN**。

QA：**READY_FOR_08_RECHECK**。00用此生产候选创建独立新Build，08在新的隔离存档上复检出生点Shift后的短按合法移动，并补L04→L05及五关链；旧Human QA PARTIAL仍原样保留。本回执为Owner代码与实际自动验收交付，未自行向其它聊天发消息或更新旧QA结论。
