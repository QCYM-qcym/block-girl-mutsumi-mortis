# UI-08-001 / READY_FOR_08_RECHECK

产品问题仍OPEN，Human QA NOT_RUN。只提供新QA版本，本交接不自动启动Human复测。原WINDOW_ACTIVATION_FAILURE、部分验收记录和已有通关/解锁/Cold Continue结论保持。

实际新包：E:/godot/beta-sprint-builds/visual_ui08001_20261009_01；源码快照ca6b331dc7c819c2a01e23c49827c0bd6a9c43a3，包含正常merge的fix81d9470c174bd67a73e7e8fedf4b92240ddfc2fd。play.ps1先导入再启动project/project.godot，需Godot4.7.2；不是EXE。ZIP同名.zip，SHA40afc81b0c5d5574b1bd688d6048ece4c1537da94905af30e32eca92b5456cb1。

只用新QA包，不要从尚未接入本修复的MAIN运行来判定新包。使用08既有独立QA存档路径（可通过既有--shell-save=user://...参数），保留此前已解锁L02；默认玩家存档及旧Build不可删除/覆盖。没有可用档时仅pendingL02该依赖，不要求再完整通关。

窗口稳定后真实操作Main Menu、Level Select、L02暂停入口、Resume、Esc继续、Settings、Hint。1920×1080、1280×720、960×720分别记录实际尺寸和截图。暂停文字应完整、可读，底面不截获鼠标；离开PLAYING后底面隐藏。Settings仍按原preview/Cancel/Apply，Hint仍跟随原text/alpha并随Pause冻结。不要重复已经通过的三关全通关、解锁与Cold Continue，除非出现新回归证据。

00自动focused127 PASS、exit0、stderr空，支持交付而不构成Human PASS。包六项启动检查均PASS；L03限时退出的旧ObjectDB warning保留到工具backlog，不扩修Core。仅08实际Human recheck完成后才可关闭UI-08-001。报告真实版本、输入、尺寸、steps、Expected/Actual、截图与影响；不修改冻结Art、Save、Foundation、Gameplay或关卡内容。
