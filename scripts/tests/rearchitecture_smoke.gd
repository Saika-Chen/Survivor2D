extends SceneTree

func _initialize() -> void:
	var session := preload("res://scripts/core/GameSession.gd").new()
	var player := preload("res://scenes/player/Player.tscn").instantiate()
	player.name = "Player"
	var camera := Camera2D.new()
	camera.name = "Camera2D"
	player.add_child(camera)
	var hud := preload("res://scenes/ui/HUD.tscn").instantiate()
	hud.name = "HUD"
	var weapon_manager := Node.new()
	weapon_manager.name = "WeaponManager"
	weapon_manager.set_script(preload("res://scripts/weapons/weapon_manager.gd"))
	var wave_director := Node.new()
	wave_director.name = "WaveDirector"
	wave_director.set_script(preload("res://scripts/game/wave_director.gd"))
	var arena := Node2D.new()
	arena.name = "Arena"
	arena.set_script(preload("res://scripts/game/arena.gd"))
	arena.arena_size = Vector2(15600, 10800)
	session.add_child(arena)
	var projectiles := Node2D.new()
	projectiles.name = "Projectiles"
	session.add_child(projectiles)
	var enemy_projectiles := Node2D.new()
	enemy_projectiles.name = "EnemyProjectiles"
	session.add_child(enemy_projectiles)
	var weapon_zones := Node2D.new()
	weapon_zones.name = "WeaponZones"
	session.add_child(weapon_zones)
	var effects := Node2D.new()
	effects.name = "Effects"
	session.add_child(effects)
	var xp_gems := Node2D.new()
	xp_gems.name = "XPGems"
	session.add_child(xp_gems)
	var pickups := Node2D.new()
	pickups.name = "Pickups"
	session.add_child(pickups)
	var enemies := Node2D.new()
	enemies.name = "Enemies"
	session.add_child(enemies)
	session.add_child(weapon_manager)
	session.add_child(wave_director)
	var bgm_player := AudioStreamPlayer.new()
	bgm_player.name = "BGMPlayer"
	session.add_child(bgm_player)
	session.add_child(player)
	session.add_child(hud)
	get_root().add_child(session)
	print("OK")
	session.free()
	quit()
