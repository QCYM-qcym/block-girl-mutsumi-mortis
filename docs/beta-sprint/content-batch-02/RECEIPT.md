# GAME_CONTENT_BATCH_02_READY — Owner交付回执

生产候选：`d4be39c76988e2face66d5f36be6e0c65fe9a169`。Owner分支：`feat/beta-content-batch-02`。基线：`b910167becee2194c0cfc724d8f0fe47578836a9`。生产候选已实际提交，提交后git status为空；回执与文件清单为后续docs提交，未改变被验收的生产资源、夹具或证据。

| 关卡 | 结果 | Unit | Real自然输入 | Graphical |
|---|---|---|---|---|
| mutsumi_l04 / 借来的道路 | GREYBOX_PLAYABLE，允许07登记 | 68/68可解，最少2次Shift | 3/3通关，每次1正式回调 | PENDING_00_INTEGRATION |
| mutsumi_l05 / 归途的门 | GREYBOX_PLAYABLE，允许07登记 | 100/100可解，最少4次Shift | 3/3通关，每次1正式回调 | PENDING_00_INTEGRATION |

最终Unit：45项、PID32756、exit0、0失败。最终headless Real：206项、PID48780、exit0、六路线、六正式回调、0失败。图形窗口仍由00/08占用，未运行。L05独立审查的桥支撑Important已按Owner-local RED/GREEN修正；旧逻辑PASS保留但不作为最终证据。

登记信息：STABLE_LEVEL_IDS.json。仅用于本Owner交付的目录：game/levels/mutsumi/batch_02/level_order.json；07负责实际batch_01目录接入。自然路线、冻结边界和最小Art/Shell/Integration请求见REPORT.md。实际PID、退出码、日志SHA、原始状态/回调轨迹见tests/beta_sprint/content_batch_02/evidence。最终测试报告source_hashes与交付内容的21项字节SHA已逐项核对；夹具SHA和默认保存保护记录见SOURCE_SHA256.json。

FILES_SHA256.json包含三个Owner根中所有交付文件的路径、字节数和SHA256，自身为显式排除项。Owner局部.gitattributes保留日志/源码字节，允许原始Windows CRLF及Godot失败启动banner的末尾空行；不规范化或改写历史日志。

Production Foundation changes：NONE。共享Runtime / Presenter、旧三关资源与提示、Shell / Save、Art、project.godot、全局输入改动：NONE。Working tree on delivery：CLEAN。Push：NOT_RUN。Integration merge：NOT_RUN。

00：在最终集成工作树、图形槽可用时运行tests/beta_sprint/content_batch_02/README.md中的graphical case并人工核验截图。图形验收是明确剩余待办，与本次内容构建的Unit/Real GREEN分别记录。
