# MAIN PROJECT VISUAL INTEGRATION 01 — approved handoff execution

目标：真实主项目启动正式六页 UI，进入既有 L01 3D，完成 Pause/Settings/Resume、Reset、World Shift、Goal、Shell回流、Save和新进程Continue。主项目与Integration基线均为7c0d8ccb16df9d7b6ab7845512580b83ba44c34c。本轮不迁移L02/L03、不新建玩法或Foundation能力，不重开美术设计。

批准依据为用户REQUEST_20261007.txt以及主项目docs/art/BETA_UI_ART_DIRECTION_01内GAME_SHELL_UI_HANDOFF.md、UI_SCREEN_MANIFEST.md、UI_TOKEN_EXPORT_SUMMARY.md、UI_INTEGRATION_CHECKLIST.md。当前六页都已APPROVED，取代源tokens/历史规范的制作期Pending字段；批准不等于主项目测试通过。

## 接入边界与分工

- UI Owner仅修改game/shell/visual_01/**和production/ui/beta_shell_01/**（fonts由00准备）。新approved_shell_view保留原View signals、screen/buttons/sliders等接口。所有动作仍交给原game_shell；View不写Save、不负责解锁、完成或设置提交。
- Harness Owner仅修改tests/beta_sprint/visual_integration/**。写出真实入口RED并构建严格验收runner；主项目GPU测试由00串行调度，不与其他图形进程争抢focus。
- 00仅处理game/shell/game_shell.gd的View preload及原生窗口表现坐标设置、L01 l01_presented.gd的表现层HUD接线、任务文档/证据、字体依赖、正常提交/FF与Daily Build。Shell采用既有L01同样的CONTENT_SCALE_MODE_DISABLED，避免默认1152×648 canvas stretch缩小批准字号；native_red01已以真实进程记录两个预期RED，业务与窗口尺寸规则不改。
- 独立审查只读契约/批准源/实现/证据。459个冻结文件及77个UI源文件预先计算哈希；冻结Gameplay、原3D presenter、模型/材质/Blender来源不改。

原ShellView保留。新View消费相同data contract，Controls发送同action/id，Settings使用同preview_settings及settings_changed。焦点按批准阅读顺序：Settings master→music→sfx→muted→fullscreen→Apply→Cancel；离开Settings恢复来源可用入口，PLAYING释放menu focus。该变化限表现层。Settings不显示尚未存在的M快捷键，手柄不补绑定。

HUD模块只观察既有level.hints.text/alpha、objective、mover.world、view.current、feedback。旧Pixel HUD/Presenter节点和Runtime保留，3D启用时换视觉、回归Pixel时恢复。无新hint计时器/flags/提示内容，不处理L03 stale hint。

## 资产与布局

精确读取冻结tokens.json的11色、radius0、grid8、stroke1.5以及文档的字级/间距/版式/motion。从icons.svg提取单个32×32 symbol，不整页截图替代控件。Noto Sans SC/Serif SC可携带字体原字节复制，附OFL许可和来源哈希；运行不依赖Windows字体安装。Source字体family及许可来源见production/ui/beta_shell_01/fonts/font_manifest.json。

Main身份背景为批准原始Surface hero，不包含扁平UI；Source_manifest中hero SHA为f70f92ad5615e2ab5cd75927671c63ae8be526a2c29d638ac06ae86475cbf0cc。L01 preview来自真实L01 SubViewport，1280×585，PID24656，exit0/stderr0，SHA9a2b50f448ffeae560c90e012f99108135b1f746e847943667f3d4bc708fecc7。L02/L03仅标GREYBOX，不借用样例图冒充真实地图。Pause/Complete以及Pause来源Settings保留真实关卡viewport和批准单层约12%遮罩。

真实测试1920×1080、1280×720、960×720；原900×700最小窗口若有额外检查单独记录。保持适配字号下限，长标题/错误/目标优先换行和重排，不改输入动作/解法。只在目录超高时允许滚动，不另造页面。

## 验证与交付顺序

1. 入口RED：旧View绑定/颜色两项预期失败，原Shell/main动作/no-save可用性控制断言PASS；保留ui_red01及ur_8f9f9a历史。
2. UI local解析/RED→GREEN；real graph seed验证六页、导航、三尺寸、状态组合、长文本、Save失败与Settings预览/取消/提交、Hint共源。
3. 真实L01正式输入完整通关；Pause→Settings→Resume、Reset；L02解锁及既有灰盒next入口，随后回到L01以新OS进程Continue验证正式3D初始态。State parity仍是P01观察哈希，不能冒充Foundation statekey.v1。
4. 复跑既有正式art_vertical regression。独立审查，按真实行为判断P0/P1；单个case依赖问题只pending该case，metadata问题由00修复。
5. 459冻结/77UI源哈希不变，正常提交并FF真实MAIN；在MAIN重新生成formal evidence，随后制作并启动新的SOURCE_PLAYABLE_NOT_EXE Daily Build，保留版本/路径/日志/ZIP哈希。
6. 签发精确receipt/files SHA与BLACK_BOX_3D_UI_QA_01交接。Human QA READY而非自动填PASS。主工程预存77个untrackedUI文件保留并如实报告。Push NOT_RUN。

Foundation保持FROZEN_FOR_BETA；楼梯STAIR_CLEARANCE PARTIAL_PASS、STAIR_TRAVERSAL NOT_RUN；不纳入载客/旋转平台/死亡/任意PuzzleStateSave。非阻塞P2/P3进入POST_INTEGRATION_POLISH_BACKLOG。完成后停止。

00共享Harness补充边界：现有tests/beta_sprint/build_source_daily.ps1仅将复制文件大小的Get-Item加-Force。visual_daily_20261007_01真实打包在已复制/哈希一致的Hidden .editorconfig处读取Length失败，尚未启动Godot；保留该失败目录，另用新BuildName。此修复不改变包内容、验证门槛或Runtime，正式375个Runtime/Test/Asset源码哈希仍必须一致。
