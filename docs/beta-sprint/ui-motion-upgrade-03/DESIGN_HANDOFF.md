# UI 与动效设计 V3 交付

日期：2026-10-28。分支：`feat/spatial-formal-chapter-01`。
基线：`a800c4c83deacd84c8ea6bfa3eb3a4ca06eae881`。
状态：**DESIGN_REVIEW_READY / PENDING_USER_APPROVAL**。

## 可直接检查的成果

打开 [交互预览](design_preview/index.html)，或本地服务地址 `http://127.0.0.1:8766/docs/beta-sprint/ui-motion-upgrade-03/design_preview/index.html`。

- [闭合 HUD](design_preview/review_closed_surface.jpg)：全幅场景，右侧工具与小型四视角圆盘，底部操作提示。
- [设置 · 表](design_preview/review_settings_surface.jpg) / [设置 · 里](design_preview/review_settings_inner.jpg)：透明侧栏、分组图标、音量条与固定应用/取消。
- [旅程](design_preview/review_journey_surface.jpg) / [空间篇](design_preview/review_spatial_journey.jpg)：十个正式关卡身份及标题，锁定状态仅为示例。
- [暂停](design_preview/review_pause.jpg) / [辅助选项](design_preview/review_accessibility.jpg)。

三张用户参考图已实际查看，其文件身份见 [REFERENCE_IDENTITY.json](REFERENCE_IDENTITY.json)。借鉴场景占比、侧栏和边缘工具关系，没有复制参考游戏的插画、角色、图标、音频或功能。

V3 去掉 V2 的网页外壳、海报构图和装饰性文案；用本作的旅程、四视角、世界、提示和设置承载功能。首次视觉复核后，收小罗盘、减轻侧栏底色，底部渐变改成全宽以消除硬切边。旧 V1/V2 文件及证据原样保留。

## 实际验证与限制

[静态验证](STATIC_VERIFICATION.json)：5 项本地资源、17 个 SVG 引用、10 个批准图标、10 个正式关卡身份/标题/顺序、JS 语法及文件范围检查通过。

[浏览器交互](BROWSER_VERIFICATION.json)：8 项通过，覆盖设置取消/应用、减少动态预览、确认框 Tab/Esc、暂停返回、隐藏界面和单一视角选择。实际查看 1280×720 原始截图，图片身份见 [BROWSER_CAPTURES.json](BROWSER_CAPTURES.json)。部分截图右上有页面外的翻译浮标，未用图片编辑隐藏或改造。

预览内设置只存于当前页面内存，刷新即恢复示例值；音量不控制真实音源，全屏不改变窗口。世界切换仅换静态配色图，视角只选择 UI 状态。提示未填作者解法。关卡不加载，不能把该预览视为游戏操作、SaveStore、暂停或 Runtime 验收。

Godot implementation / Graphical QA / Human QA：**NOT_RUN**。正式 UI、Gameplay、Art masters、A2 候选身份、旧 QA Build 与存档：**未修改**。New formal Build：**NOT_CREATED**。

## 后续实现边界

[完整设计](../../superpowers/specs/2026-10-28-ui-motion-upgrade-v3-design.md) 待用户确认。进入 Godot 后复用原生 Theme、现有控件与 Tween，沿用 SaveStore、AudioDirector、关卡目录及 Runtime 权威事件；不引入第二套状态、存档或音频管理。沿用 V1 已核实的开源调研结论，本轮没有新增第三方依赖。

本轮只新增 V3 设计资料和隔离 HTML/CSS/JS 样例；主菜单和实际角色动效尚未按 V3 接入。此交付不宣称全面 UI 升级完成，也不代表用户批准正式资产替换。
