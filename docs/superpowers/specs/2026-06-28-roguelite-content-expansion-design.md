# Roguelite Content Expansion Design

## Scope
Build a content-heavy first version of the survivor roguelite loop: enemy variety, ranged enemies, buff enemies, restart flow, mobile controls, diverse automatic weapons, level-up choices that can add weapons, weapon combinations/evolutions, 30 waves, and a major boss at wave 30.

## Enemy Roster
Enemies share one configurable enemy scene and script. `chaser` rushes the player. `shooter` keeps distance and fires enemy bullets. `buffer` follows slowly and strengthens nearby enemies with a visible aura. `elite` is a large bruiser used on milestone waves. `boss` appears on wave 30 with high health, projectile volleys, charging movement, and summon pressure.

## Weapon System
A `WeaponManager` node owns player weapons and their levels. It starts with Blood Bolt and can unlock Ghost Blades, Shadow Spikes, and Soul Nova from level-up choices. Each weapon has a max level. Weapons fire automatically, scale with level, and can evolve once the weapon reaches max level and its required passive/material upgrade exists.

## Level-Up Choices
Level-up keeps the current three-choice pattern but changes the option pool. Choices can unlock a new weapon, upgrade an owned weapon, add a passive upgrade, evolve a maxed weapon, or improve basic stats. Evolution choices are prioritized when available so the player sees fusion moments.

## Weapon Evolutions
Blood Bolt evolves into Crimson Judgment. Ghost Blades evolve into Wraith Storm. Shadow Spikes evolve into Abyss Scream. Soul Nova evolves into Soul Eclipse. Evolution replaces the base weapon behavior with stronger visuals and tuning while preserving the simple procedural art style.

## Waves and Boss
A `WaveDirector` node tracks waves from 1 to 30. Each wave lasts a short timed interval in the prototype. Spawn rate, health, and composition scale by wave. Waves 10 and 20 add elites. Wave 30 spawns the Abyss King boss and ends normal spawning pressure once defeated.

## Restart and Mobile Input
The HUD death state displays a restart button that reloads the main scene. Mobile input adds a virtual joystick in the lower-left of the HUD. Player movement uses keyboard/gamepad input plus the joystick vector, so PC controls remain intact.

## Data Flow
`game.gd` coordinates scene nodes, XP, upgrades, collisions, and restart state. `weapon_manager.gd` owns weapon definitions, option generation, firing, and evolution. `wave_director.gd` owns wave timing and spawn requests. Enemy/projectile scripts remain focused on movement, tuning, and procedural visuals.

## Verification
Use Godot headless parsing as the primary automated verification. Manual checks: mobile joystick moves the player, restart reloads after death, ranged and buff enemies appear, level-up can unlock/upgrade/evolve weapons, wave HUD advances, and wave 30 boss spawns.
