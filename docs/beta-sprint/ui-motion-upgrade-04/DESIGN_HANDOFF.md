# 放大角色动态菜单 V4

日期：2026-10-28。Owner：00；分支：`feat/spatial-formal-chapter-01`。
基线：`4eca7de9d5fc1f7b65d5a58b6479c1305b849cea`。
状态：**CHARACTER_MENU_PREVIEW_READY**；最终视觉审核及正式 Godot 接入尚未完成。

## 直接查看

[打开动态菜单](design_preview/index.html)，或访问 `http://127.0.0.1:8766/docs/beta-sprint/ui-motion-upgrade-04/design_preview/index.html`。

背景改为中右侧的放大方块少女，保留 V3 圆形线图标、半透明侧栏与中文菜单语言。模型实时渲染，有低频小幅待机、轻转身及侧倾回正；动作按钮位于底栏，不挡脸和身体。表世界使用 Wakaba，里世界使用既有 Mortis；角色、背景、面板、底栏、文字、按钮及焦点色同步切换。

- [表世界菜单](design_preview/review_menu_surface.jpg)
- [里世界菜单](design_preview/review_menu_inner.jpg)
- [表世界设置](design_preview/review_settings_surface.jpg) / [里世界设置](design_preview/review_settings_inner.jpg)
- [侧倾连续帧](design_preview/review_lean_3.jpg) / [减少动态](design_preview/review_reduced_motion.jpg)
- [960×720](design_preview/review_menu_inner_960.jpg)

两份正式 GLB 只读使用；网格、材质和贴图原样保留，精确身份见 [SOURCE_IDENTITY.json](SOURCE_IDENTITY.json)。模型目前无骨骼、animation clips 或 morph：没有眨眼、表情或四肢动作。侧倾只作用于整个模型，并以接触边的高度补偿保持接地；不写 Runtime 的位置、Orientation、StateKey 或动作。

## 实际检查

[浏览器记录](BROWSER_VERIFICATION.json)：13 项通过，覆盖加载两角色、转身开始/结束、打开设置不取消动作、侧倾连续姿态及回稳、减少动态静止/取消恢复、世界身份对应、设置取消/应用、隐藏界面的焦点边界、窄窗口无文档溢出及返回导航重新初始化。

[静态复核](STATIC_VERIFICATION.json)：源文件语法、导入及 DOM 引用、批准资产哈希和文件边界均通过。实际截图与哈希见 [BROWSER_CAPTURES.json](BROWSER_CAPTURES.json)。六张主要画面已由独立审阅者逐张查看：脸与轮廓可见、面板不挡角色，两世界配色有明确区别。Surface 浅色头发与背景的对比仍较柔和，保留为视觉审核观察。

复核中修正了预览的页面恢复、减少动态初始化、焦点配色和设置事件误取消动作；960 下调整展示镜头避免后侧轮廓裁切。最初旧常量产生的阴影 API 警告已修正，历史日志原样保留。缩放后首次捕获早于新的渲染帧，已在实际帧更新后重新捕获；不能拿首次空白帧当作最终图形通过。

已实际验证返回导航会重新加载渲染器；`persisted=false`，所以 BFCache 为 **NOT_EXERCISED**。隐藏标签页恢复仅有静态审查，运行验证为 **NOT_RUN**。1280×720 与 960×720 是浏览器原型范围，不是 Godot 三尺寸矩阵。Human QA、Godot 产品接入、Runtime/Save 回归：**NOT_RUN**。New formal Build：**NOT_CREATED**。

## 开源复用与正式接入边界

浏览器渲染复用 [Three.js WebGLRenderer](https://threejs.org/docs/pages/WebGLRenderer) 和 [GLTFLoader](https://threejs.org/docs/pages/GLTFLoader)，随附官方 npm `0.186.1` 的最小依赖及 MIT 许可；来源、完整性及逐文件 SHA 见 [OPEN_SOURCE.json](OPEN_SOURCE.json)。本轮没有安装脚本、外部 CDN 请求或新增 Godot 依赖。

本原型设置仅在当前页面内存中生效，音量不控制真实游戏，全屏不改变窗口；开始/退出只演示反馈，不启动关卡或关闭用户游戏。它不能被当作 Save/Continue、正式菜单或 Gameplay 验收。

后续 Godot 实现复用已有角色与原生 UI/动画路径。实际世界色彩必须由正式世界状态确认，初次绑定、真实提交、Reset 均同步；不能按 Space 输入推断 World Shift 成功。正式游玩保留现有真实关卡，不用展示动画取代 Runtime 驱动的角色。

[设计记录](../../superpowers/specs/2026-10-28-ui-motion-character-showcase-v4-design.md)。V1–V3、正式资产、A2 未批准身份、旧 QA Build/证据与存档保持不变。本次只新增 V4 预览和设计资料。

完整 whitespace 检查保留一处官方 Three.js `three.core.js:49957` 混合缩进提示；该文件保持 npm 原字节，不改写上游。排除 vendor 后的本轮自有文件检查通过。
