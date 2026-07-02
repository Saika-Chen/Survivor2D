# Survivor2D

Godot 4.7 starter project for a 2D survivor game.

## Open

- Godot: open this folder as a project.
- VS Code: open this folder and use the Godot Tools extension.

## Current Slice

- Move with WASD or arrow keys.
- Auto-fire targets the nearest enemy.
- Enemies spawn around the arena and chase the player.
- Dark procedural art style with a humanoid glowing player, occult enemies, magic projectiles, and a moody arena.
- Defeated enemies drop XP gems that the player can collect.
- Leveling up pauses combat and offers three upgrade choices from weapons, weapon upgrades, relics, evolutions, and stats.
- Four player weapons are available: Blood Bolt, Ghost Blades, Shadow Spikes, and Soul Nova.
- Additional juice-pass weapons include Doom Laser, Plague Bomb, Abyss Tentacle, and Reaping Scythe.
- Max-level weapons can evolve when the matching relic has been collected.
- Enemies now include melee chasers, ranged shooters, buff priests, chargers, tanks, splitters, bombers, elites, and a wave-30 boss.
- The wave director runs a 30-wave challenge inspired by survivor and arena roguelites.
- The arena is larger than the viewport and a Camera2D follows the player.
- The map has a dark sacrificial wasteland art pass with rock texture, cracks, bones, blood stains, rune circles, soul flames, and drifting fog.
- Level-up choices include rarity labels and rerolls.
- Level-up choices use weighted rolls that prefer upgrading current weapons.
- UI cards, generated icons, and burst particles reinforce the dark ritual style.
- Late-wave performance is protected with caps on live enemies, weapon zones, and effects.
- Relics immediately grant stats and also unlock weapon evolutions.
- Monster drops can include magnets that pull all pickups and potions that restore 50% max health.
- The player has brief invulnerability after taking damage.
- Owned relics show in the upper-right HUD and add small visual changes to the player.
- Combat feedback includes hit sparks, damage numbers, death explosions, and camera shake.
- HUD shows health, level, XP, score, time, enemy count, wave, and weapon loadout.
- Death and victory screens include a restart button.
- Mobile play has a lower-left virtual joystick while PC keyboard controls remain available.
- Default landscape viewport is 1280x720.

## Platform Direction

PC is the primary development target. Android, iOS, and web or mini-game platforms are prepared as future export tracks under `export/`.
