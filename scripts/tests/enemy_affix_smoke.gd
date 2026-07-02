extends SceneTree

const EnemyScene := preload("res://scenes/enemy/Enemy.tscn")

func _initialize() -> void:
	var enemy := EnemyScene.instantiate()
	get_root().add_child(enemy)
	enemy.configure("elite", 12)
	enemy.apply_affix("volatile")
	print("%s|%s" % [str(enemy.get("elite_variant")), str(enemy.get("elite_affix"))])
	enemy.queue_free()
	quit(0)
