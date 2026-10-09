# Owner headless reproduction

在 Shell Batch02 工作树运行以下 PowerShell 命令，每次使用全新 EvidenceName。脚本无条件 `--headless`；原存档只读，所有测试写入新 `user://beta_sprint/` slot。

```powershell
& ./tests/beta_sprint/shell_batch_02/run_headless.ps1 `
  -EvidenceName shell_b02_fresh_review `
  -Cases catalog,save_compat,menu_capacity,runtime_seed,runtime_restore,legacy_restore `
  -LegacySave 'E:/godot/beta-sprint-builds/black_box_3d_ui_qa_01_20261007/clean_profile/Roaming/Godot/app_userdata/方块少女-若叶睦/beta_sprint/black_box_3d_ui_qa_01/progress.json' `
  -LegacyProvenance 'E:/godot/beta-sprint-builds/black_box_3d_ui_qa_01_20261007/BLACK_BOX_3D_UI_QA_01.md'
```

默认 Godot 为 `D:/APP/steam/steamapps/common/Godot Engine/godot.windows.opt.tools.64.exe`，可用 `-Godot` 指定。Runtime case 使用 WASAPI 的 headless 进程以避开已记录的 Dummy audio 退出泄漏；不改变生产 audio。新 checkout 需要导入时加 `-Import`；已知冻结 SVG 初次导入 P2 单独保留且 `.import` 恢复原字节。测试过程代码/资源 SHA 发生变化、非零退出、实际测试 stderr、失败断言、同进程 Restore 或不同存档 Restore 均令 runner 失败。

不用旧 QA 包作为可写工程，不复用本次存档目录。没有提供真实旧存档时，save_compat 只读当前默认路径；若缺失，明确 PASS_WITH_PENDING。legacy_restore 需要先执行 save_compat 并提供实际旧源，不能用 fixture 冒充。

最终冻结证据：`evidence/b02_candidate_final_01/`。早期 `b02_real_menu_01` 的 L05 viewport 与请求不匹配，保留作测量失败历史，禁止用它声明三尺寸通过；修正记录见 exact/final 两组证据。每个图形/Human case 仍由 00/08 的独立报告负责。
