extends RefCounted
class_name EnemySpawner

static func random_spawn_position(player_position: Vector2, world_size: Vector2, archetype: String) -> Vector2:
	if archetype == "boss" or archetype == "bullet_boss":
		return (player_position + Vector2(0, -420.0)).clamp(Vector2(96, 96), world_size - Vector2(96, 96))
	var angle := randf() * TAU
	var distance := randf_range(800.0, 1100.0)
	return (player_position + Vector2.RIGHT.rotated(angle) * distance).clamp(Vector2(64, 64), world_size - Vector2(64, 64))

static func configure_enemy(enemy: Node2D, player: Node2D, archetype: String, wave: int, connect_callback: Callable, maybe_affix_callback: Callable) -> void:
	enemy.target = player
	enemy.set("world_size", player.world_size)
	enemy.configure(archetype, wave)
	if maybe_affix_callback.is_valid():
		maybe_affix_callback.call(enemy, archetype)
	if connect_callback.is_valid():
		connect_callback.call(enemy)

