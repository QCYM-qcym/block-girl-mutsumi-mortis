# PFALL_V2_QUALITY_MATRIX_REPORT

正式新黄色目标曲线候选：984f275913b1495fc09f92743fb0f665715f50c1。03 本轮只修改测试与证据文档。CONTRACT_MISMATCH: NONE。公共基础合同与历史94项矩阵均逐字节保持。

独立03真实执行：7份收据、1703项断言，全部checks>0、exit0、failures=[]、stderr0、doubles=[]、source_drift=[]，PID/HEAD/隔离用户目录核验通过。52个Unit是收据分类与临时Git输入校验，不计入Real。每份收据保留自己的实际执行HEAD、生产候选、源文件SHA和完整原始日志。

|执行|Checks|实际结果|
|---|---:|---|
|正式Sampler/Kernel/Safety/Explorer/Softlock/Trace/Logical Replay|162|PASS，A/B完整原图和同次活graph；原图选中的两步trace先validate及validate_semantics|
|Formal Graphical TraceReplayer|211|PASS，mode1，A/B各两次，8个真实匹配步骤|
|Reset/取消/节点及超时生命周期|1017|PASS，18场景；旧取消18、旧迟到完成0；新运行36匹配步骤|
|原生WASD按住与快速重复输入|25|PASS，A66/B68个真实按住帧，覆盖Fall/Landing/Idle；每图一次Fall提交；释放、Reset、重新输入可用|
|既有Perspective Connection|66|PASS，真实正式旧模块，本轮重新执行|
|历史schema1/schema2|16|PASS，原历史hash和两步Logical Replay保持|
|L01–L05重点图形回归|206|PASS，真实Shell、生产Runtime/3D Presenter、Native输入、Pause/Reset/Goal/退出|

69 Core checks：原始A26、B26、Camera17，登记收据4b90a4b，实际执行源6074e48；在94矩阵中只对应CORE_A_NATURAL_FALL、CORE_B_NATURAL_FALL、CORE_CAMERA_REJECT三个唯一ID。本轮不把69当作69个矩阵项，也不把原来证据认作新曲线执行。

94-case matrix：**54 PASS /0 FAIL /40 PENDING**。逐项见MATRIX_94.md及JSON，保留原01bf8c交付和完整证据身份；仅在适用的既有PASS行追加新候选收据。没有升级旧pending、改写旧结果或重复计数。新黄色目标12项另列MATRIX_12.md/JSON：**12 PASS /0 FAIL /0 PENDING（明确限定的验收范围）**。第11项采用协调明确接受的FORMAL_KERNEL_GAMEPLAY参考实现与实际3D完整七字段StateKey/State逐动作比对；真实Pixel图形渲染仍NOT_RUN_UNSUPPORTED_SCHEMA3_PIXEL_STACK。

Formal Graphical TraceReplayer：**PASS**。唯一正式生产TraceReplayer mode1，原完整图选中的MOVE U_NEG（Fall）→自然Landing→MOVE U_POS（Roll）→Goal。每步检查STARTED<COMMITTED<自然完成，五字段Transition identity、提交/完成次数、完整StateKey/State、World、Camera、Orientation、实际呈现帧和最终Transform。A/B重复产生新native identity并保持相同语义结果。

Logical Replay：**PASS**，mode0，A/B各两步，共4匹配步骤。它与图形结果分别登记。

Natural Presenter：**共享00实际范围PASS，独立03未冒充再次运行**。消费00 natural_curve01的51项真实检查，209个生产文件SHA与本轮03执行快照一致，A/B正式level hash相同，12张真实截图全部查看，Source/Departure/Mid-descent/Pre-contact/Contact/Settled及逐帧数据已按原始字节复制到yt_natural_reference_02。该消费贡献0项独立03 Gameplay断言。A/B屏幕净下降222.377/86.452px，落地support误差≤5.96e-8；target和blue_reference Mesh身份不同，实际Actor落在target/TOP。B截图临时CoreLab HUD保留默认MAP A标题，B由完整正式hash/StateKey/目标Pose绑定；这些截图不签UI验收。

Runtime parity：**MATCH**。Fall到target/TOP保留Orientation0，随后Roll到exit/TOP为12；World orientations=[0,0]、Camera1；正式参考Gameplay每个原始动作的完整状态/key与真实3D完成证据一致。

Graphical parity：**MATCH**。A目标actor center=(-3,1,4)，B=(-3,5,4)，来自正式Spatial Anchor+normal；最终Basis与cube24 Orientation一致。自然落地、正式Graphical完成和逻辑原图是不同证据链，均绑定当前正式黄色目标。

新失败：**未发现本轮已确认的Runtime/Presenter生产缺陷**。保留03测试错误yt_legacy_profile_01（误读09fixture外包装而未取.spec），仅修正03消费后同候选GREEN16；另保留离线自然证据读者误写DESCENT阶段名的attempt，实际正式阶段为FALL_MOVING，修正后209个源hash/逐帧/截图核对通过。这两项不交作生产缺陷，失败原文没有删改。

Owner handoff：03测试/矩阵/原始证据可由00受控接入并继续包内真实启动验证。GRAPHICAL_WINDOW_RELEASED：本轮03四个图形进程都已退出。没有启动新Build、修改生产、实现新Fall或Solver。无01/10A新增修复请求。

NOT_RUN：真实schema3 Pixel图形、完整Art/Audio/UI矩阵、GLB/Shader/VFX全面验收、Human QA、性能长跑/Frame Time、OS鼠标拖动、L06、新profile Inner权限与全部24方向。本轮不把00 Audio/UI局部结果自动升级为完整94矩阵通过，也不把历史L04加载最低9FPS归因于Fall。

Changed files：仅03 allowlist；见CHANGED_FILES.txt。文件SHA见FILES_SHA256.json；真实执行源333f185和18b7206，各原始收据独立保留。正式生产候选984f275，所有后续03改动仅测试/docs，最终提交SHA见本聊天交付与git HEAD。

Working tree：提交后检查clean；最终验证写入FINAL_VERIFICATION.json。
Push：NOT_RUN。
