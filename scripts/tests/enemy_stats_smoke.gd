extends SceneTree

const EnemyConfigScript := preload("res://scripts/enemy/EnemyConfig.gd")

func _initialize() -> void:
	var elite_stats: Dictionary = EnemyConfigScript.for_archetype("elite", 10)
	var chaser_stats: Dictionary = EnemyConfigScript.for_archetype("chaser", 3)
	print("%s|%s" % [str(elite_stats.get("xp_reward", -1)), str(chaser_stats.get("speed", -1.0))])
	quit(0)
