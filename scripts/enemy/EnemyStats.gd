extends RefCounted
class_name EnemyStats

const EnemyConfigScript := preload("res://scripts/enemy/EnemyConfig.gd")

static func for_archetype(archetype: String, wave: int) -> Dictionary:
	return EnemyConfigScript.for_archetype(archetype, wave)
