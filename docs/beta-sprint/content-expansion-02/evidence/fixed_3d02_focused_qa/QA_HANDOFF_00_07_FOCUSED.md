# 00 / 07 Focused QA handoff

固定包 beta_3d02_20261009_01，ZIP SHA256 697070886818f1e437e9fd20444fe98684a60582eeb2b30bcea98bf8ab64c999。

B 三尺寸已完成，客户区/viewport/render 分别实际为 1920×1080、1280×720、960×720；C 新进程同 profile 的 Cold Continue = PASS（40064→34448，回到 L-03 authored spawn）。A 没有合格首次玩家，RETEST_PENDING，因此整体 BETA_3D02_FOCUSED_QA_PARTIAL。

07 请处理 FOCUS-3D02-P2-001：选关 L-02/L-03 仍写“灰盒试玩 · 尚无正式环境预览”，但实际是 3D。仅修正当前状态表达；Art Direction FROZEN。本轮不做生产修复。

既有 Pause 辅助文字重叠与 L-03 过期 Hint 继续开放。P0=0，P1=0，新增 P2=1，既有 P2=2，合计=3。

GRAPHICAL_SLOT_RELEASED 已于 2026-10-09T04:50:16.9601638Z 留证；QA 进程均正常退出。后续 Daily/Integration 不继承本固定包 PASS。

[正式报告](E:/godot/beta-sprint-builds/beta_3d02_focused_qa_20261009_01/BETA_3D02_FOCUSED_QA_PARTIAL.md)；[新 P2](E:/godot/beta-sprint-builds/beta_3d02_focused_qa_20261009_01/FOCUS-3D02-P2-001.json)；[Cold Continue](E:/godot/beta-sprint-builds/beta_3d02_focused_qa_20261009_01/cold_continue_evidence.json)。
