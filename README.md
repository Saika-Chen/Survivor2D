# Survivor2D

一个基于 Godot 4.7 的 2D Survivor-like 肉鸽原型。

当前版本已经从“单脚本原型”重构为更清晰的模块化结构，保留了自动攻击、刷怪、升级、武器进化、30 波挑战、掉落系统、移动端摇杆和对象池优化等核心玩法，同时把数值和规则逐步数据化。

## 玩法概览

- 自动攻击与近战/弹幕/范围等多类武器
- 敌人波次推进，包含普通波、精英波和 Boss 波
- 击杀敌人获取经验，升级后从多种选项中做选择
- 武器可升级、进化、超进化，部分武器可融合
- 掉落磁铁、药瓶、宝箱、魔晶和炸弹等拾取物
- 支持移动端虚拟摇杆与基础性能降档

## 当前架构

项目现在按职责拆分为几个主要层：

- `scripts/game/game.gd`：主游戏场景编排，连接各子系统
- `scripts/core/ObjectPool.gd`：对象池
- `scripts/progression/LevelSystem.gd`：经验、升级、重掷次数
- `scripts/progression/UpgradeSystem.gd`：升级次数与规则
- `scripts/combat/DamageSystem.gd`：暴击、最终伤害、吸血判定
- `scripts/enemy/EnemyConfig.gd`：敌人配置数据入口
- `scripts/enemy/EnemyStats.gd`：敌人属性计算兼容层
- `scripts/enemy/EnemySpawner.gd`：刷怪位置与实例配置
- `scripts/game/RunEventSystem.gd`：波次事件、祝福、悬赏、恶魔交易
- `scripts/weapons/WeaponDatabase.gd`：武器/遗物/融合/羁绊数据库
- `scripts/weapons/WeaponConfig.gd`：武器升级池和配置逻辑
- `scripts/ui/HUDController.gd`：HUD 文本格式化
- `scripts/ui/UpgradePanel.gd`：升级面板文案和事件模式判断

## 数据文件

项目已经开始使用数据驱动方式管理核心数值：

- `data/weapons.json`：武器、被动、融合、羁绊
- `data/waves.json`：波次规则与刷怪配置
- `data/enemies.json`：敌人基础数值与各 archetype 配置

后续新增武器、敌人或波次时，优先先改数据表，再补脚本行为。

## 目录结构

```text
assets/        美术、音频、图集等资源
data/          配置数据
docs/          设计与重构文档
scenes/        Godot 场景
scripts/       GDScript 逻辑
shaders/       GPU Shader
```

## 运行方式

### 在 Godot 中打开

1. 用 Godot 4.7 打开项目根目录
2. 主场景为 `res://scenes/main/Main.tscn`
3. 直接运行即可

### 命令行验证

可以使用 headless 模式做快速编译检查：

```bash
"/Applications/Godot.app/Contents/MacOS/Godot" --headless --path /Users/mac/Documents/Codex/2026-06-28/wo/Survivor2D --quit
```

也可以运行一些 smoke test：

```bash
"/Applications/Godot.app/Contents/MacOS/Godot" --headless --path /Users/mac/Documents/Codex/2026-06-28/wo/Survivor2D --script res://scripts/tests/rearchitecture_smoke.gd
"/Applications/Godot.app/Contents/MacOS/Godot" --headless --path /Users/mac/Documents/Codex/2026-06-28/wo/Survivor2D --script res://scripts/tests/enemy_stats_smoke.gd
```

## 重构进度

已经完成的方向：

- 把对象池、经验系统、伤害系统、刷怪系统拆成独立模块
- 把波次、敌人、武器和事件的关键配置数据化
- 把 HUD 文案和升级面板文案收口到专门的辅助脚本
- 保留原有玩法，同时减少 `game.gd` 的“上帝对象”味道

仍然可以继续推进的方向：

- 进一步拆分 `weapon_manager.gd` 的运行时职责
- 把更多武器行为抽成 `WeaponRuntime` 或按家族拆模块
- 增加更多敌人配置和波次表
- 继续整理 UI 和数值平衡

## 备注

- 项目里仍有一个来自旧资源的无关 UID 警告，当前不影响运行。
- 目前主入口仍然是 `scripts/game/game.gd`，`GameSession.gd` 处于预留状态。
