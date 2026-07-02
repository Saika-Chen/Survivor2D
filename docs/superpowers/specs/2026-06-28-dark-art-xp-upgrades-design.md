# Dark Art, XP, and Level-Up Choices Design

## Scope
Add a dark visual direction, make the player read as humanoid, keep the default landscape viewport at 1280x720, and add an experience system with a three-choice level-up screen.

## Visual Direction
The game keeps its lightweight procedural art approach. The arena uses a dark cold palette with subtle grid lines, stains, and vignette-like edge shading. The player becomes a small humanoid silhouette with head, torso, limbs, and a cyan/green spectral glow. Enemies become red occult shapes with health rings and damaged feedback. Projectiles and experience gems use bright accent colors to stand out against the arena.

## Experience Flow
Defeated enemies spawn experience gems. Gems are collectible nodes that drift or remain visible until the player gets close enough to collect them. Collecting gems adds XP to the player. XP thresholds increase by level so later levels need more kills.

## Level-Up Flow
When the player reaches the next XP threshold, the game pauses combat and asks the HUD to show three upgrade choices. The player clicks one option, the chosen upgrade is applied, the overlay hides, and combat resumes. Excess XP carries into the next level.

## Upgrade Choices
The first implementation uses three deterministic choices: increased projectile damage, faster firing, and improved survivability/mobility. These directly affect existing systems without adding unnecessary weapon architecture.

## Data Flow
`game.gd` owns combat, score, XP, level state, and weapon tuning values. `hud.gd` displays health, score, time, enemy count, level, XP progress, and the upgrade overlay. `player.gd`, `enemy.gd`, `projectile.gd`, and the new XP gem script focus on their own visuals and movement/collection data.

## Testing and Verification
Because this project currently has no automated test harness, verification will use Godot script parsing where available and a focused manual checklist: default resolution remains 1280x720, player appears humanoid, enemies drop XP, XP updates HUD, level-up pauses game, each of the three options applies and resumes play.
