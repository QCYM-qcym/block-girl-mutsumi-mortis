# UI / Motion Upgrade 01 — Design Handoff

日期：2026-10-28（Asia/Shanghai）。Owner：00 Integration Coordinator。

**DESIGN_REVIEW_READY；产品实现尚未开始。**

用户要求全面升级游戏 UI 与动效，复用成熟实现；明确审美为“精致，简约，但是不简陋”。本阶段交付可评审的具体方向与工程边界，用户尚未批准完整设计。

## 本阶段产物

- [完整设计规格](../../superpowers/specs/2026-10-28-ui-motion-upgrade-design.md)：覆盖实际正式入口的十关菜单、HUD、暂停、设置、确认、完成与动作反馈。
- [三页设计预览](design_preview/index.html)：主菜单 / HUD / 设置；含页面淡变与减少动态的示意切换。数值和进度为预览示例，不读写游戏数据。
- 实际浏览器截图：[主菜单](design_preview/review_main.jpg)、[HUD](design_preview/review_hud.jpg)、[设置](design_preview/review_settings.jpg)。三图均由独立隐藏浏览器打开本页后截图，非 Godot 截图。
- [文件身份与只读验证](DESIGN_VERIFICATION.json)。

## 已作出的设计提议

延续现有浅石色、青绿和批准的角色/拱门图像；通过字重、间距、对齐与主次操作建立精致感。HUD 收拢常驻信息，设置改为清晰的独立模态，底部动作固定。动效以短淡变、轻位移和稳定焦点为主，减少动态仍保留全部操作信息。

此处是设计协调者建议，不把用户一句审美偏好扩写成逐项批准。正式 A2 资产替换仍 NOT_APPROVED；本阶段不消费 A2 候选 shader，不修改冻结美术母版。

## 复用结论

1. 继续使用项目现有 Theme、Stone 控件、Noto 中文字体、图标、SaveStore、AudioDirector、Presenter 与动作完成桥。
2. [Godot 4.7 Tween](https://docs.godotengine.org/en/4.7/classes/class_tween.html) 提供所需数值补间、绑定和中断能力；不增加另一个动画状态机。
3. [Maaack Menus Template](https://github.com/Maaack/Godot-Menus-Template) 为 MIT，上游声明支持 Godot 4.7；[v1.7.1](https://github.com/Maaack/Godot-Menus-Template/releases/tag/v1.7.1) 可作为菜单与焦点组织的选择性参考。尚未 vendor、安装或在本项目 4.7.2 实测。
4. [Tweens2D](https://github.com/Baukereg/godot-tweens-2d) 仅作后续动效配方候选；如确需拷贝，再固定完整版本身份和许可。原生能力已能解决的部分不为引入依赖而引入。

## 实际检查与限制

已在独立浏览器实际查看三页：中文字体与原有图片加载、页面选中态、左右键切页和减少动态开关均有效；浏览器记录没有 error/warn。设计规格经独立 builder 审阅，返回 `nothing important left`。

本阶段**没有**运行 Godot、游戏键鼠测试、三尺寸游戏矩阵、正式 Replay、冷启动 Continue 或真人 QA。HTML 的切页不是这些项目的替代证明。静态 HUD 使用既有批准的 L01 预览，不代表当前十关实机渲染。

后续批准后：独立 feature worktree → 实现计划与明确 Owner 文件范围 → 组件/页面及减动接线并发实施 → 真实 Godot 三尺寸与生命周期专项 → 新独立 Build → 指定 Build QA。保留旧包、旧存档和历史事实。

## GitHub 阶段身份

设计基线：`35bf571ea57dcef97da7d65388a0d282dec323d2`。

所属分支：`feat/spatial-formal-chapter-01`。仅提交本设计规格与新预览目录。生产修改：NONE；正式美术修改：NONE；新游戏 Build：NOT_CREATED；Human QA：NOT_RUN。

Commit、普通 Push 与远端 SHA 通过提交后的独立查询记录在阶段交付中，避免文件内自引用提交身份。main、Release Branch / Tag 不变。
