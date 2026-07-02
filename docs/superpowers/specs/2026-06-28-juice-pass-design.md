# Juice Pass Design

## Scope
Increase moment-to-moment fun by expanding the arena, adding a player-follow camera, making mobile joystick visible, increasing early damage and enemy density, adding laser/bomb/tentacle/piercing weapons, making orbit weapons feel continuous, adding reroll and rarity to level-up choices, making monsters more visually distinct, and adding hit/death feedback.

## Map and Camera
The arena becomes a large world. The player is clamped to world bounds rather than viewport bounds. A Camera2D follows the player. Enemies spawn around the player at a ring distance so pressure follows exploration.

## Weapon Expansion
WeaponManager adds four new weapons: Doom Laser, Plague Bomb, Abyss Tentacle, and Reaping Scythe. Existing weapons gain stronger starting damage and clearer per-level scaling. Ghost Blades use rapid rotating zones so they appear to orbit continuously.

## Upgrade Experience
Level-up options receive rarity labels and colors. The player gets rerolls on each level-up overlay. Option rarity affects presentation and can mildly improve stat options.

## Enemy and Feedback
New archetypes include charger, tank, splitter, and bomber. Existing enemies receive stronger visual differences. Death creates explosion effects; hits create brief impact flashes and camera shake.

## Verification
Run Godot headless parsing and a short headless runtime smoke test.
