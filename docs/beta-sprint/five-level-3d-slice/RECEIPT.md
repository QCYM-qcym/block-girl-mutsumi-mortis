# BETA_FIVE_LEVEL_3D_SLICE_READY

2026-10-09 · 00 Integration Coordinator · Beta Phase 3

L04《借来的道路》与 L05《归途的门》已接入正式 3D 呈现。两关复用批准的 Generic/L01 Presenter、角色、Surface/Inner、Camera、翻滚与 World Shift；视觉仅观察原生 P01 Runtime。既有谜题、Save、Foundation 和 Art 源文件均未修改。

| 项目 | 实际结果 |
| --- | --- |
| L01 / L02 | 当前 3D 限定回归 PASS；完整通关保留历史证据 |
| L03 | 当前 3D 回归、连接成立/失效/跨越/Goal PASS |
| L04 / L05 | 3D_FORMAL_PLAYABLE；各正常、Reset、改变 Camera 顺序完成 |
| Pixel / 3D parity | 6 组逐事件、逐动作原生状态序列完全 MATCH |
| Goal / Game Shell | 12 次 Owner 实际 Goal/完成回调；菜单回流、实际 L05 解锁 PASS |
| Save / Continue | 自动验证原生持久化、同进程与不同 PID 冷启动恢复 PASS |
| Five-level progression | 前三关正式历史证据/明确 fixture + 本轮实际 L04 → L05；未声称新空存档五关全链试玩 |
| L06 | DESIGN_READY；设计及既有规则验证已合并，未注册生产关卡 |
| L03 first-time QA | RETEST_PENDING；08 已确认没有合格新玩家 |
| P0 / P1 / P2 | 0 / 0 / 3；承接已接受的人类 QA，三个既有 P2 保留，自动验证无新增失败 |
| Art / Foundation source changes | NONE / NONE |
| STAIR_CLEARANCE / STAIR_TRAVERSAL | PARTIAL_PASS / NOT_RUN |
| New-package Human QA | NOT_RUN；本交付是下一轮 08 验收候选 |
| QA handoff | READY_FOR_08；精确范围见 QA_HANDOFF_08.md |
| Push | NOT_RUN |

保留 L04 Inner `(0,5)` 与 L05 已经通过首次玩家试玩的全部资源字节。仅两处既有 Scene 的 Script 引用改变，新增两个 batch_02 局部 presentation 脚本。没有修改共享 Presenter、Main、project.godot、规则、提示或 UI 美术。

## 提交身份

- 基线：`9e2e9c29a73272d431795f12db1fefaff2433b05`。
- 3D Owner：`2cfc4d2ef221c450ad9024c8ea3a72d69e4fcf63`，保留生产提交 `4ffc5b9e2d6a8dd125b8354a29f7a97e00414cf8`。
- L06 Owner：`d2b78e183839e078c9a28074b2e25359a40608c4`，保留设计提交 `2276a7247251007686dd7409311e6d01258f86ce`。
- 正常合并：L06 `3734151670136c72675496418cf5c59afa7c1d0a`，3D `e7c99afdcae253e3bdad3eb4a6be93a3a5bdbf72`。没有 reset/rebase/squash。
- 冻结 Build source：`942b6d4e0b3e30dc26fa4c276948fb68b548244e`；之后仅更新 00 收据/日志/QA 登记文档。
- Integration receipt commit 为包含本收据的最终 Git 提交，由 00 最终交付消息提供真实 40 位 SHA；文件不伪造自身提交身份。

## 实际验证

Owner：原生入口 101 checks（PID27796）、默认 D3D12/Forward+ 完整 Pixel/3D 路线 2276 checks（PID22616）、独立进程 Cold Continue 27 checks（PID50820）。全部 exit0/stderr0/failures=[]/doubles=[]。保留 112 张截图与 18 roll、32 camera、8 Shift、6 gate-roll 自然样本。完整图形用例真实执行于 WIP baseline HEAD，其 358 项源码 SHA 与交付生产字节一致，原始身份未改写。

合并后 00：前三关 642 checks（PID47304，29 截图）；L04 三条完整路线、实际 L05 解锁/入口及 UI/Save/Continue 267 checks（PID4116，20 截图）。全部 exit0/stderr0，无运行期源码漂移。L01/L02 无影响的完整通关和旧 UI 矩阵没有重复运行。

L06：既有 Data/State/Movement/Perspective 的 500 checks（PID51476），四条 API 参考路线和 148/148 可完成状态；设计最少六次 Shift、28 动作。该证据不宣称完整关卡/3D/正式输入/人类 QA。

新包：1309 项复制源码匹配构建时的 Integration 快照及原始 manifest；1324 项包文件与 ZIP 逐字节一致。构建后 00 仅更新 QA 登记/计划文档，并将两份 00 JSON 换行规范化，四项文档字节差异记录于 FINAL_PROTECTION；包及生产源码没有变化。五关正式目录 68 checks；import、catalog、Main、Foundation boot、五关 boot 共九阶段 exit0。仅 L04 `--quit-after` 留下与既有基线 SHA 完全相同的 133-byte ObjectDB 退出警告，现有正式分类为 `PASS_WITH_KNOWN_BASELINE_P2`；原文保存在 evidence/build，不冒充空 stderr，也不新增玩法 PASS。

保护核验：635 项冻结生产源码、121 项批准 Art Source/Project 对、6146 项旧 QA 记录及五个目录成员集合一致；旧报告、截图、日志、存档和 QA 包保持原样。文件范围与 SHA 见 FILES_SHA256.json，实际保护结果见 FINAL_PROTECTION.json。

## 新构建

- Version：`beta_five_level_3d_20261009_01`。
- Path：`E:/godot/beta-sprint-builds/beta_five_level_3d_20261009_01`。
- 启动：运行该目录 `play.ps1`；需要 Godot `4.7.2.stable.steam.ed1daf0bf`，可用 `-Godot` 指定可执行文件。本包是 SOURCE_PLAYABLE_NOT_EXE。
- 独立存档：`user://beta_sprint/beta_five_level_3d_20261009_01/qa_progress.json`；发布时不存在预置进度。
- ZIP：同名 `.zip`，61125565 bytes，SHA256 `409cb38c4b43a1847ed0857e019265fb7ed26eec90fea4691760e2905a1c27c1`。

既有完整人类 QA、旧 UI matrix 和 Cold Continue 仅属于各自旧 Build。新版由 08 聚焦变更执行下一轮 QA；本收据不宣称整款 Beta QA 完成。
