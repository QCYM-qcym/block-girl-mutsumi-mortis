# 08 黑盒试玩交接 — L-01 正式 3D Vertical Slice

状态：PENDING_MAIN_PROJECT_VERIFICATION。自动化完成后填写真实提交与证据，再改为 READY。本交接不包含解法或路线答案。

主项目：E:/godot/若叶睦/方块少女-若叶睦/project.godot。使用 Godot 4.7.2，F5 应进入实际 Game Shell。通过关卡选择进入 L-01《另一个世界》，不能通过 Art Gallery、技术验证场景或旧 P-01 F6 入口代替试玩。

操作：WASD 翻滚；Q/E 或现有鼠标拖动每次切换一个90°视角；Space 切换世界；R 重置；Esc 暂停/恢复；M 声音。只验证 L-01，L02/L03 仍为已有灰盒内容，不迁移。

请从主菜单进入关卡选择，再进入 L-01，自行识路、完成关卡、从完成界面回到 Shell。至少覆盖：

- 角色确为批准的 Wakaba/Mortis 3D 资产，翻滚连续、物理脸面附着于模型，转动相机或切世界不会回正。
- 四个离散镜头下，角色、路径和出口可读；前景门/出口遮挡处理在移动时更新，不让地面或角色持续透明。
- Surface/Inner 差异可读；转场无强闪、黑屏或阻挡操作的效果，新路不会在逻辑提交前误导玩家。
- 压力板、门与出口外观和实际动作一致；连续输入不会让门或角色卡在旧视觉状态。
- 在翻滚、镜头转动和世界切换中按 R；再次试玩时角色、机关、世界、相机与临时 VFX 都正确复位。
- 暂停、恢复、窗口失焦、重复输入和切关回流正常；完成事件只发生一次；退出后 Continue 回到已解锁关卡的正式初始状态。
- 1280×900 和900×700窗口可读；记录性能、明显 shader 编译卡顿、资源错误、视觉透明排序问题。

报告至少包含版本 SHA、主项目路径、硬件/renderer、操作复现、预期/实际、截图和 P0/P1/P2。自动化通过不是 Human QA PASS。批准资产的 P0/P1 按 MAIN_PROJECT_INTEGRATION_REQUEST 回交05 Art；P2记入backlog。

边界：本关是现有 P01/Content Runtime 的3D呈现接入，不是 Foundation RuntimeSession 迁移。3D资产保留形状和契约，逻辑碰撞继续由原 grid occupancy 管理；没有新增独立的3D Area机关规则。楼梯未纳入：STAIR_CLEARANCE=PARTIAL_PASS，STAIR_TRAVERSAL=NOT_RUN。可选载客/旋转平台、死亡和任意Puzzle存档恢复没有本轮验收。
