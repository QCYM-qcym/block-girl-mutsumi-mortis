# Mutsumi Veilshift UI 与动效升级 V3 设计

日期：2026-10-28。状态：**PENDING_APPROVAL；仅设计草案，不进入产品实现**。
工作树：`E:/godot/worktrees/bg-formal01`；分支：`feat/spatial-formal-chapter-01`。
本轮基线：`a800c4c83deacd84c8ea6bfa3eb3a4ca06eae881`；职责：00 协调设计审核。
V1、V2 设计和证据原样保留；本稿替代 V2 拟议的视觉基调，不扩大功能范围。

## 1. 目标、参考与本轮范围

用户认为 V1 过于简单，V2 仍有通用模板感，希望参考《Chill with You Lo-Fi Story》。
本轮三张用户截图提供明确方向：场景主导、边缘常驻小工具、按需展开的透明侧栏。
借鉴其空间关系、圆形线图标与操作节奏；不照搬插画、界面截图、文案或独有功能。
不沿用 V2 海报式标题、继续卡、假进度、英文装饰文案、金色角饰或重度磨砂。
新预览：`docs/beta-sprint/ui-motion-upgrade-03/design_preview/index.html`。
只审核闭合 HUD、左侧旅程/设置/暂停面板及展开收起关系；不扩展成全套新主页。
HTML 为静态美术上的交互样例，不读取 Save、不接管输入，不证明游戏已实现。
本阶段仅新增设计资料与隔离预览；不改产品代码、Runtime、规则、存档或 frozenArt。
A2 继续 **NOT_APPROVED**；本稿不能追认它或批准新的 Inner 美术。

## 2. 画面主次与材质

关卡几何、角色、关键落点始终清晰；背景不模糊、不铺全屏暗幕、不裁切主要几何。
HUD 闭合时只保留边缘工具；草案左栏宽约 30%，限制在 330–400px，其余面积交给场景。
采用深靛半透明底、浅灰文字、低饱和淡紫次级线条；青色仅点亮当前状态与焦点。
圆形按钮使用统一线宽、圆环、内距及命中区域；不用 emoji、杂糅字形或发光装饰堆砌。
透明度服务可读性；文字背后可局部加深底色，不能遮去场景的空间判断依据。
细分隔、紧凑分组和真实状态提供密度；不以大卡片、重复标题或空白容器制造复杂感。
中文沿用已批准 Noto 字体；图标入口提供中文提示、可访问名称和明显键盘焦点。
正文、数值及固定操作保持既有可读字号；在窄屏优先滚动内容，不能无限缩小字体。

## 3. 闭合 HUD：四视角圆盘与边缘工具

右上小圆盘显示现有四个视角及当前方向；圆环是选择状态，不是计时或完成率。
圆盘按实际相机接口呈现可用操作；UI 不自行增加相机动作资格或绕过 Runtime 判断。
右侧竖排提示、重置、设置、暂停，统一圆形外观；禁用状态可辨，说明可通过焦点读取。
提示只消费 `get_hint_presentation()`；不猜答案、不扩展提示权限，不反复堆积常驻反馈。
重置与返回沿用已有确认和动作生命周期；无权限时不得在样例中承诺可以执行。
右侧工具栏的旅程入口打开关卡导航；底部紧凑呈现世界、相机与当前输入提示。
纯展示区域鼠标透传；操作提示关闭后，必要的世界与相机状态仍能辨识。
音频条只展示 `game/feel/audio/audio_director.gd` 已有接口支持的控制。
未核实播放/切歌接口时只保留真实音量或静音入口；不伪造曲名、艺术家、播放进度和曲库。
不新增计时器、任务清单、日历、货币、环境音混音、等级或解锁机制。

## 4. 左侧面板：同一结构的三种内容

顶部为标题、关闭入口和必要分组；内容区独立滚动，底部真实操作固定可达。
旅程草案使用十个正式关卡 ID/标题的副本与示例锁定状态，不读取 Save；示例状态不是权威。
后续 Godot 实现必须读取正式 catalog 及真实可达状态，不添加新解锁链、完成条件或存档字段。`game/shell/level_catalog.gd` 合并 `game/levels/mutsumi/batch_01/level_order.json` 与 `game/levels/mutsumi/spatial_chapter/level_order.json`。
十个 ID 保持 V2 第 4 节原值与顺序；后续 Godot 标题取正式资源 `display_title`，不建立第二套注册表。
展示组名称仅为暂定文案，不重命名正式关卡；无批准预览时明确说明，不用错图冒充。
设置只重组已有音频、画面、辅助选项，保留预览→应用保存/取消回滚与 Esc 取消语义。
沿用总音量、音乐、音效、静音、全屏、减少动态、提示强度、对比度及操作提示接口。
保存中防重复提交；失败保留编辑内容、显示可换行错误并聚焦应用，固定操作不被遮挡。
从游玩进入设置先暂停；退出设置仍处于暂停，通过显式继续恢复。
暂停提供继续、重玩、设置及既有返回入口，不新增样例统计或进度摘要。
面板切换和关闭立即接受输入；焦点进入面板并在关闭时回到触发入口，模态不泄漏操作。

## 5. 美术来源与身份

草案实际使用 V2 的两张批准美术片段，只读使用；保留完整几何、角色和原图比例。
Surface：`docs/beta-sprint/ui-motion-upgrade-02/design_preview/assets/hero_surface_camera0.png`。
Surface 原始来源：`E:/Study/方块娘项目/若叶睦/model/art/production/releases/batch_05/reports/hero_surface_camera0.png`。
Inner：`docs/beta-sprint/ui-motion-upgrade-02/design_preview/assets/hero_inner_camera0.png`。
Inner 原始来源：`E:/Study/方块娘项目/若叶睦/model/art/production/releases/batch_05/reports/hero_inner_camera0.png`。
批准依据：`production/art_3d/VERTICAL_SLICE_ART_HANDOFF.md`；精确拷贝记录见 V2 `ART_REFERENCE_SOURCES.json`。
草案不使用 `surface_identity.png` 或 L01 预览；Surface/Inner 均只用于对照叠层观感，不代表正式关卡可玩性或本轮实时运行。
用户截图仅供视觉研究，不复制进入产品或预览资产；不从截图中提取角色、图标或字体。

## 6. 动效与工程边界

面板进出拟议 160–200ms，短距离位移配合 alpha；图标反馈 80–120ms。
只在状态改变时产生一次反馈；不添加循环旋转、呼吸辉光、飘浮或模拟播放波形。
减少动态关闭非必要位移，使用即时状态或 alpha ≤80ms；焦点、错误和选择仍清楚。
快速切换、关闭、重置和离关取消旧 Tween/回调，防止残留遮罩、重复事件或旧焦点。
技术底座为原生 Godot Theme、既有 Control/Container、ScrollContainer 与 Tween，不增 UI 框架。
`game/shell/visual_01/`、`game/feel/ui/game_feel_ui.gd` 与既有设置行仅作后续复用入口。
SaveStore、AudioDirector、Runtime 保持唯一权威；UI 为薄表现层，不保存第二份玩法状态。
Presenter 动作接受、暂停恢复、session/run/generation 过滤与完成/保存/音效去重均不变。
保留角色正式 sampler、World Shift 互斥写入窗口与单一 transform writer；UI 动效不更改动作时长合同。
批准设计后另列产品 allowlist，由 07 实现 UI、00 协调公共接线；不凭本稿跨 Owner 修改。

## 7. 审核与后续验收

本轮审核重点：闭合时场景占比、开栏后的空间保留、统一圆形图标和真实功能映射。
仍继承 V1 第 8 节与 V2 第 9 节的 12 道工程验收门槛，不因更换视觉基调而减免。
后续游戏检查包含 1920×1080、1280×720、960×720，常规/减少动态、长中文及长错误。
键鼠等价、滚动/固定操作、模态、设置事务、暂停恢复、重置离关与重玩完成闭环均需实测。
本轮 Godot QA、动作生命周期回归、Human QA、Build：**NOT_RUN**。
HTML 检查只能证明预览行为；设计稿保存不等于用户批准、Integration PASS 或正式发布。
