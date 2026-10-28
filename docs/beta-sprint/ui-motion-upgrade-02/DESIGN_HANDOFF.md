# UI / Motion Upgrade V2 — richer interface review

日期：2026-10-28（Asia/Shanghai）。Owner：00 Integration Coordinator。

**V2_DESIGN_REVIEW_READY；PENDING_USER_REVIEW。**

用户认为 V1 仍太简陋，要求更复杂。本阶段重新组织构图、章节信息、交互层级和控件细节；V1 原件与历史结论保留。V2 尚未获用户批准，也未接入正式游戏。

## 具体交付

- [可交互的五页面预览](design_preview/index.html)：主菜单、十关章节页、HUD、暂停、音频/画面/辅助设置；支持双世界主题和减少动态预览。
- [V2 设计规格](../../superpowers/specs/2026-10-28-ui-motion-upgrade-v2-design.md)：替代 V1 的拟议视觉方向，保留其工程边界与正式验收门槛。
- [10 张浏览器原始截图清单](BROWSER_CAPTURES.json)，包括 [表世界主菜单](design_preview/review_main_surface.jpg)、[里世界主菜单](design_preview/review_main_inner.jpg)、[章节](design_preview/review_chapters_surface.jpg)、[空间篇占位](design_preview/review_spatial_chapter.jpg)、[HUD](design_preview/review_hud.jpg)、[暂停](design_preview/review_pause.jpg)、[音频](design_preview/review_settings_surface.jpg)、[辅助](design_preview/review_accessibility.jpg)。
- [美术参考源身份](ART_REFERENCE_SOURCES.json)与[文件/验证记录](DESIGN_VERIFICATION.json)。

## 相比 V1 的实际改变

主菜单增加完整章节继续卡：正式关卡名、当前位置、进度节点与明确中文主动作。次级入口以序号、标题、说明、箭头组成，背景原画保留对比和体积。细边、内高光、轻投影、局部纹理与青绿/铜色标记区分景观、内容和操作层。

十关分为两个展示组，目录、状态和真实可用预览联动。没有正式关卡预览的项目明确显示占位；未解锁示例不能激活进入。组名只是 UI 暂定文案，正式 ID、标题、顺序及解锁语义不改变。

HUD 将章节、世界、视角、目标与按键组织成连贯的仪表。暂停保留关卡画面与上下文；设置延续当前页面背景，模态底部动作固定。音频采用总音量整行、音乐/音效并列、静音独立行，保证字号与完整控件可见。

交互预览实现分层入场、hover/press、主题切换、章节选择、缺图占位、设置 dirty/应用/取消、提示展开和模态返回。这些状态只存在页面内存，不写文件、不读写游戏存档，也不发送游戏输入。全屏开关是设计演示，不改变窗口。

## 美术与复用

已有 `production/ui/beta_shell_01/` 的 Surface 图、L01 预览、Noto 字体与图标保持只读。新增目录只精确复制两张已批准的 Batch05 美术片段作为参考；Inner 来源依据 [正式美术交接](../../../production/art_3d/VERTICAL_SLICE_ART_HANDOFF.md)，不是新批准或新关卡实机截图。

正式实现仍拟复用原生 Theme/Control/Tween、既有 Shell、SaveStore、AudioDirector、Presenter、Sampler 和完成桥。社区菜单的参考结论沿用 V1；没有为预览安装插件、导入新框架或复制第三方运行时代码。

A2 Expanded 仍 NOT_APPROVED，本阶段未消费它；美术母版、碰撞、通行规则和 Runtime 未修改。

## 实际验证与限制

浏览器预览使用独立隐藏标签页，未操作用户游戏窗口。实际查看与交互包括：

- 双主题与五页面；当前浏览器 viewport 1280×720，截图为 full-page JPEG，实际尺寸另记。
- 音量示例 80→79，取消后恢复 80；应用只更新网页内存并显示清楚状态。
- 减少动态即时预览及取消回滚；高对比与操作提示只影响本预览。
- 两组共十个正式 ID/标题；未解锁示例入口禁用；缺正式图时使用占位。
- Camera 选中态 N→E、提示展开、暂停与设置返回关系。静态 L01 背景不会随 Camera 旋转，不能当作 Gameplay 行为。
- JS 语法检查通过；浏览器 console error/warn 为 0。10 个最终静态截图使用减少动态模式，不能据此宣称普通动效观感通过。

独立视觉审阅指出小字与中文主动作缺失；修复后重新实际查看主菜单、音频、辅助三张终稿，未发现必须修复的裁切或动作标签缺失。独立实现规格审阅返回 `nothing important left`。这些结论均不等于玩家理解性或 Godot QA。

正式 Godot 三尺寸、动作/Replay/Save 回归、真人 QA：**NOT_RUN**。新游戏 Build：**NOT_CREATED**。V2 图与网页不冒充已接入游戏。

## 阶段交付

基线：`c0fa92cf2581661926a98fef451d54f42aaa33a3`。分支：`feat/spatial-formal-chapter-01`。

仅提交本新目录与 V2 设计规格。旧 V1、正式生产文件、原始 Art、QA 包/截图/存档、main 和 Release Branch / Tag 保持不变。Commit / 普通 Push / 远端 SHA 在提交后独立核验，不在本文件伪造自引用提交身份。
