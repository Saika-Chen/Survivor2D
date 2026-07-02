# Duelyst 资源替换设计

## 目标

在不改战斗逻辑与数值的前提下，将当前项目中的主角、核心敌人、核心武器弹体/区域特效、命中特效替换为 `duelyst_animated_sprites` 资源包中的动画资源。

本轮优先保证：

- 敌我辨识清晰
- 暗黑风格统一
- 安卓端额外性能开销可控
- 尽量少改已有玩法脚本

## 接入策略

1. 保留当前逻辑层与大部分场景结构。
2. 新增 Duelyst 资源映射脚本，统一管理单位与特效动画资源。
3. 玩家与敌人采用“新增动画主体节点 + 保留少量旧叠层/光效”的混合方案。
4. 武器弹体、僚机、区域攻击优先替换为 AnimatedSprite2D。
5. 命中与死亡提示优先替换为 Duelyst FX，文字伤害数字继续保留。

## 资源路径兼容

资源包内 `.tres` 引用的是 `res://addons/duelyst_animated_sprites/...`。

项目中实际资源位于：

- `assets/art/duelyst_animated_sprites`

因此通过建立：

- `addons/duelyst_animated_sprites -> ../assets/art/duelyst_animated_sprites`

来兼容现成 `.tres` 的内部引用，避免批量修改资源文件。

## 首轮映射

### 主角

- 玩家主体：`f4_altgeneral`

原因：

- 人形清晰
- 暗黑气质强
- 自带攻击与施法动作，适合当前幸存者玩法

### 敌人

- `chaser` -> `neutral_shadowranged`
- `shooter` -> `neutral_moonlitsorcerer`
- `buffer` -> `f4_mistressofcommands`
- `elite` -> `f4_bloodbaronette`
- `charger` -> `neutral_mercmelee3`
- `tank` -> `f4_juggernaut`
- `splitter` -> `neutral_ghoulie`
- `bomber` -> `f4_plaguedr`
- `boss` -> `boss_wraith`

原则：

- 近战体型更厚重
- 远程和辅助怪轮廓差异更大
- Boss 视觉显著高于普通怪

### 武器与特效

- `blood_bolt` / `crimson_judgment` -> `fx_plasma`
- `reaping_scythe` / `death_carousel` -> `fx_crossslash`
- `grave_familiar` / `seraph_swarm` 弹体 -> `fx_fairiefire`
- 僚机本体普通 -> `f4_remora`
- 僚机本体进化 -> `f6_circulus`
- `ghost_blades` / `wraith_storm` -> `fx_bladestorm`
- `shadow_spikes` / `abyss_scream` -> `fx_shadowcreep`
- `soul_nova` / `soul_eclipse` -> `fx_ringswirl`
- `doom_laser` / `void_lance` -> `fx_beamlaser`
- `plague_bomb` / `grave_mortar` -> `fx_explosionpurplesmoke`
- `abyss_tentacle` / `old_one_grasp` -> `fx_roots`
- 命中特效 -> `fx_impactred`
- 死亡特效 -> `fx_blood_explosion`

## 代码改动范围

- 新增 Duelyst 资源映射脚本
- 玩家脚本与场景：增加动画主体
- 敌人脚本与场景：增加动画主体
- 弹体、区域攻击、僚机场景与脚本：支持 AnimatedSprite2D
- Combat effect：优先使用 Duelyst 命中/死亡 FX

## 风险与回退

风险：

- 某些资源帧尺寸偏大，需要额外缩放
- 个别 `.tres` 若引用异常，可能需要替补资源
- AnimatedSprite2D 增加后，部分旧叠层需要隐藏，避免画面重叠

回退方式：

- 保留原 TextureFactory 逻辑作为后备
- 若单个资源不适配，仅回退该映射，不影响整体流程
