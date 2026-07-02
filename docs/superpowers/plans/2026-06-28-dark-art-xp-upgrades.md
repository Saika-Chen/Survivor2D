# Dark Art XP Upgrades Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Add dark procedural art, a humanoid player, XP pickups, and a three-choice level-up overlay.

**Architecture:** Keep the current procedural drawing style and small scene structure. `game.gd` owns XP, leveling, weapon tuning, and collection checks; focused scripts draw player/enemy/projectile/XP visuals; `hud.gd` owns stats and the upgrade overlay.

**Tech Stack:** Godot 4.7, GDScript, `.tscn` scenes, procedural `_draw()` art.

---

## File Structure

- Modify `scripts/game/arena.gd`: dark arena background, layered grid, stains, edge shadows.
- Modify `scripts/player/player.gd`: humanoid procedural player art and upgrade helper methods.
- Modify `scripts/enemy/enemy.gd`: darker enemy visuals, XP reward, hit flash data.
- Modify `scripts/projectile/projectile.gd`: darker magic projectile visuals.
- Create `scripts/xp/xp_gem.gd`: collectible XP gem data and visuals.
- Create `scenes/xp/XPGem.tscn`: XP gem scene.
- Modify `scripts/game/game.gd`: XP spawning, collection, level thresholds, upgrade application, tuned fire/damage state.
- Modify `scripts/ui/hud.gd`: expanded stats and level-up option signals.
- Modify `scenes/ui/HUD.tscn`: upgrade overlay UI nodes.
- Modify `scenes/main/Main.tscn`: XP gem container.
- Modify `README.md`: document new slice and 1280x720 default.

## Tasks

### Task 1: Visual Upgrade
- [ ] Update arena, player, enemy, and projectile `_draw()` methods with dark procedural art.
- [ ] Keep exported gameplay values compatible with existing scripts.
- [ ] Verify scripts parse with Godot if the binary is available.

### Task 2: XP Pickup
- [ ] Add `scripts/xp/xp_gem.gd` with `value`, `radius`, and idle animation drawing.
- [ ] Add `scenes/xp/XPGem.tscn` using the XP gem script.
- [ ] Add an `XPGems` container to `scenes/main/Main.tscn`.
- [ ] Spawn XP gems when enemies die and collect them when the player is close.

### Task 3: Level-Up Overlay
- [ ] Extend `hud.gd` with `upgrade_selected(upgrade_id)` and button handlers.
- [ ] Add a dark modal overlay and three buttons to `HUD.tscn`.
- [ ] Pause combat during level-up and resume after a choice.
- [ ] Apply damage, fire-rate, and vitality/speed upgrades.

### Task 4: Docs and Verification
- [ ] Update `README.md` with dark visuals, XP, upgrades, and `1280x720` default.
- [ ] Run available syntax checks.
- [ ] Provide manual verification checklist.
