# Mobile Portrait Jackpot Audio Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** 为当前生存游戏实现移动端竖屏适配、拉霸三连全拿、波次手机震动和基础程序音效。

**Architecture:** 以 `game.gd` 作为战斗编排入口，`hud.gd` 负责拉霸大奖演出与竖屏布局，新增 `sfx_manager.gd` 统一处理程序音效，尽量不改核心战斗循环。移动端适配优先通过 `project.godot` 与 HUD 布局重排完成。

**Tech Stack:** Godot 4.7、GDScript、现有 HUD/WeaponManager 架构、无头 Godot 冒烟验证

---

### Task 1: 建立第一批改动骨架

**Files:**
- Create: `scripts/audio/sfx_manager.gd`
- Modify: `scripts/game/game.gd`
- Modify: `scripts/ui/hud.gd`

- [ ] 新增统一音效管理脚本
- [ ] 在主游戏节点接入音效管理与拉霸大奖信号
- [ ] 在 HUD 中增加 Jackpot 自动结算状态机信号

### Task 2: 实现拉霸三连全拿

**Files:**
- Modify: `scripts/ui/hud.gd`
- Modify: `scripts/game/game.gd`
- Modify: `scripts/weapons/weapon_manager.gd`

- [ ] 让拉霸三连结果不再进入 6 选 1
- [ ] 在 HUD 中按顺序点亮并发放 6 个奖励
- [ ] 在 `game.gd` 中逐个应用奖励并在结束后恢复战斗

### Task 3: 实现移动端竖屏适配

**Files:**
- Modify: `project.godot`
- Modify: `scenes/ui/HUD.tscn`
- Modify: `scripts/ui/hud.gd`
- Modify: `scenes/main/Main.tscn`

- [ ] 将项目默认视口调整为竖屏基准
- [ ] 重排 HUD 顶部信息、提示文本、摇杆和升级面板
- [ ] 调整摄像机缩放与升级面板布局适配窄屏

### Task 4: 接入手机震动与基础音效

**Files:**
- Modify: `scripts/game/game.gd`
- Modify: `scripts/weapons/weapon_manager.gd`
- Create: `scripts/audio/sfx_manager.gd`

- [ ] 在波次开始、Boss 来袭、Jackpot 时触发移动端震动
- [ ] 给不同武器族挂上基础发射音效
- [ ] 给普通怪、精英怪、Boss 死亡接入差异化爆裂音

### Task 5: 验证

**Files:**
- Modify: `scripts/tools/headless_smoke.gd`（仅当需要）

- [ ] 运行 `'/Applications/Godot.app/Contents/MacOS/Godot' --headless --path . --quit`
- [ ] 运行 `'/Applications/Godot.app/Contents/MacOS/Godot' --headless --path . --script res://scripts/tools/headless_smoke.gd`
- [ ] 检查没有新的脚本编译错误
