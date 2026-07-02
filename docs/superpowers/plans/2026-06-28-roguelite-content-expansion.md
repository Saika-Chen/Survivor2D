# Roguelite Content Expansion Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Add enemy variety, weapon variety/evolution, mobile controls, restart, waves, and a wave-30 boss.

**Architecture:** Keep existing procedural rendering and add focused manager scripts. `WaveDirector` emits spawn pressure, `WeaponManager` owns weapons/upgrades, `game.gd` coordinates collisions and lifecycle, and HUD handles player-facing overlays.

**Tech Stack:** Godot 4.7, GDScript, `.tscn` scenes, procedural `_draw()` art.

---

## File Structure
- Modify `scripts/enemy/enemy.gd` for enemy archetypes, ranged fire, buff aura, elite and boss behavior.
- Create `scripts/projectile/enemy_projectile.gd` and `scenes/projectile/EnemyProjectile.tscn` for hostile bullets.
- Create `scripts/game/wave_director.gd` to manage waves and spawn recipes.
- Create `scripts/weapons/weapon_manager.gd` to manage weapon inventory, firing, options, and evolutions.
- Create `scripts/effects/weapon_zone.gd` and `scenes/effects/WeaponZone.tscn` for area weapon hit zones.
- Modify `scripts/projectile/projectile.gd` for weapon IDs, pierce, homing, orbit visuals, and evolved colors.
- Modify `scripts/player/player.gd` for mobile joystick vector support.
- Modify `scripts/ui/hud.gd` and `scenes/ui/HUD.tscn` for restart, wave display, and mobile joystick UI.
- Modify `scripts/game/game.gd` to coordinate managers, collisions, upgrades, restart, and boss victory.
- Modify `scenes/main/Main.tscn` to add manager/effects containers.
- Update `README.md`.

## Tasks
- [ ] Add reusable enemy archetypes and hostile projectiles.
- [ ] Add wave director and 30-wave spawn progression.
- [ ] Add weapon manager, four base weapons, four evolutions, and level-up option generation.
- [ ] Add area weapon zones and projectile collision support.
- [ ] Add restart button and virtual joystick.
- [ ] Wire all systems through `game.gd` and HUD.
- [ ] Run Godot headless verification and fix parser/runtime errors.
