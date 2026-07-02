extends Node2D

const EnemyScene := preload("res://scenes/enemy/Enemy.tscn")
const ProjectileScene := preload("res://scenes/projectile/Projectile.tscn")
const EnemyProjectileScene := preload("res://scenes/projectile/EnemyProjectile.tscn")
const XPGemScene := preload("res://scenes/xp/XPGem.tscn")
const PickupItemScene := preload("res://scenes/pickups/PickupItem.tscn")
const WeaponZoneScene := preload("res://scenes/effects/WeaponZone.tscn")
const ParticleBurstScene := preload("res://scenes/effects/ParticleBurst.tscn")
const CombatEffectScript := preload("res://scripts/effects/combat_effect.gd")
const SFXManagerScript := preload("res://scripts/audio/sfx_manager.gd")

@onready var player: Node2D = $Player
@onready var enemies: Node2D = $Enemies
@onready var projectiles: Node2D = $Projectiles
@onready var enemy_projectiles: Node2D = $EnemyProjectiles
@onready var weapon_zones: Node2D = $WeaponZones
@onready var effects: Node2D = $Effects
@onready var xp_gems: Node2D = $XPGems
@onready var pickups: Node2D = $Pickups
@onready var weapon_manager: Node = $WeaponManager
@onready var wave_director: Node = $WaveDirector
@onready var hud: CanvasLayer = $HUD
@onready var camera: Camera2D = $Player/Camera2D
@onready var bgm_player: AudioStreamPlayer = $BGMPlayer

var score := 0
var elapsed := 0.0
var level := 1
var experience := 0
var experience_to_next := 18
var level_up_pending := false
var victory_pending := false
var current_wave := 1
var max_wave := 30
var wave_time_left := 0.0
var player_damage_multiplier := 1.0
var xp_magnet_range := 120.0
@export_range(0.0, 100.0, 0.01) var magnet_pickup_drop_chance_percent := 2.5
@export_range(0.0, 100.0, 0.01) var potion_pickup_drop_chance_percent := 0.5
@export_range(0.0, 100.0, 0.01) var slot_pickup_drop_chance_percent := 0.2
var rerolls_left := 1
var shake_timer := 0.0
var shake_strength := 0.0
var global_magnet_timer := 0.0
var max_effect_nodes := 70
var mobile_profile_enabled := false
var sfx_manager
var pending_event := {}
var active_blessings := {}
var bounty_target_id := -1
var bounty_expires_wave := -1

func _ready() -> void:
	get_tree().paused = false
	_setup_bgm()
	if has_node("Arena"):
		player.world_size = $Arena.arena_size
	if has_node("MapDecor"):
		$MapDecor.arena_size = player.world_size
	_apply_runtime_profile()
	player.died.connect(_on_player_died)
	player.damaged.connect(_on_player_damaged)
	hud.upgrade_selected.connect(_on_upgrade_selected)
	hud.reroll_requested.connect(_on_reroll_requested)
	hud.restart_requested.connect(_on_restart_requested)
	hud.jackpot_reward_granted.connect(_on_jackpot_reward_granted)
	hud.jackpot_finished.connect(_on_jackpot_finished)
	hud.joystick_changed.connect(player.set_virtual_joystick_vector)
	sfx_manager = Node.new()
	sfx_manager.set_script(SFXManagerScript)
	add_child(sfx_manager)
	weapon_manager.setup(player, enemies, projectiles, weapon_zones, ProjectileScene, WeaponZoneScene)
	weapon_manager.weapon_fired.connect(_on_weapon_fired)
	wave_director.spawn_requested.connect(_on_wave_spawn_requested)
	wave_director.wave_changed.connect(_on_wave_changed)
	wave_director.boss_wave_started.connect(_on_boss_wave_started)
	wave_director.reset()
	_update_hud()

func _setup_bgm() -> void:
	if bgm_player == null or bgm_player.stream == null:
		return
	if bgm_player.stream.has_method("set_loop"):
		bgm_player.stream.set_loop(true)
	elif "loop" in bgm_player.stream:
		bgm_player.stream.loop = true
	if not bgm_player.finished.is_connected(_on_bgm_finished):
		bgm_player.finished.connect(_on_bgm_finished)
	if not bgm_player.playing:
		bgm_player.play()

func _on_bgm_finished() -> void:
	if bgm_player != null and bgm_player.stream != null:
		bgm_player.play()

func _apply_runtime_profile() -> void:
	mobile_profile_enabled = OS.has_feature("mobile")
	if not mobile_profile_enabled:
		return

	max_effect_nodes = 42
	xp_magnet_range = 150.0
	wave_director.max_alive_enemies = min(wave_director.max_alive_enemies, 68)
	weapon_manager.max_weapon_zones = min(weapon_manager.max_weapon_zones, 42)
	weapon_manager.max_projectiles = min(weapon_manager.max_projectiles, 72)
	if has_node("MapDecor"):
		var decor := $MapDecor
		if decor.has_method("set_mobile_profile"):
			decor.set_mobile_profile(true)

func _physics_process(delta: float) -> void:
	if level_up_pending or victory_pending:
		return

	elapsed += delta
	wave_director.tick(delta, enemies.get_child_count())
	_update_enemy_buffs()
	weapon_manager.tick(delta)
	_check_projectile_hits()
	_check_weapon_zone_hits()
	_check_enemy_projectile_hits()
	_check_xp_gems()
	_check_pickups()
	_check_enemy_contacts(delta)
	global_magnet_timer = max(0.0, global_magnet_timer - delta)
	_update_camera_shake(delta)
	_update_hud()

func _spawn_enemy(archetype: String, spawn_position := Vector2.INF) -> void:
	var enemy: Node2D = EnemyScene.instantiate()
	if spawn_position == Vector2.INF:
		enemy.global_position = _random_spawn_position(archetype)
	else:
		enemy.global_position = spawn_position
	enemy.target = player
	enemies.add_child(enemy)
	enemy.configure(archetype, current_wave)
	_maybe_apply_enemy_affix(enemy, archetype)
	enemy.projectile_requested.connect(_on_enemy_projectile_requested)
	enemy.summon_requested.connect(_on_enemy_summon_requested)

func _random_spawn_position(archetype: String) -> Vector2:
	var world_size: Vector2 = player.world_size
	if archetype == "boss":
		return (player.global_position + Vector2(0, -420.0)).clamp(Vector2(96, 96), world_size - Vector2(96, 96))
	var angle := randf() * TAU
	var distance := randf_range(520.0, 760.0)
	return (player.global_position + Vector2.RIGHT.rotated(angle) * distance).clamp(Vector2(64, 64), world_size - Vector2(64, 64))

func _check_projectile_hits() -> void:
	for projectile in projectiles.get_children():
		for enemy in enemies.get_children():
			var hit_key := "hit_%s" % enemy.get_instance_id()
			if projectile.has_meta(hit_key):
				continue
			if projectile.global_position.distance_to(enemy.global_position) <= projectile.radius + enemy.radius:
				projectile.set_meta(hit_key, true)
				_damage_enemy(enemy, projectile.damage * player_damage_multiplier)
				projectile.hit_count += 1
				if projectile.hit_count > projectile.pierce:
					projectile.queue_free()
					break

func _check_weapon_zone_hits() -> void:
	for zone in weapon_zones.get_children():
		if not zone.has_method("consume_damage_ready"):
			continue
		if not zone.consume_damage_ready():
			continue
		for enemy in enemies.get_children():
			if zone.global_position.distance_to(enemy.global_position) <= zone.radius + enemy.radius:
				_damage_enemy(enemy, zone.damage * player_damage_multiplier)

func _damage_enemy(enemy: Node2D, amount: float) -> void:
	if enemy.health <= 0.0:
		return
	enemy.take_damage(amount)
	_spawn_hit_effect(enemy.global_position, amount)
	if enemy.health <= 0.0:
		score += 1
		_spawn_xp_gem(enemy.global_position, enemy.xp_reward)
		_try_spawn_pickup(enemy.global_position)
		_spawn_death_effect(enemy.global_position, enemy.radius, enemy.archetype)
		_spawn_particle_burst(enemy.global_position, "death")
		_add_shake(0.12, 7.0)
		sfx_manager.play_enemy_death(enemy.archetype)
		if enemy.archetype == "splitter":
			for index in range(2):
				_spawn_enemy("chaser", enemy.global_position + Vector2.RIGHT.rotated(randf() * TAU) * 34.0)
		if enemy.archetype == "bomber":
			for nearby in enemies.get_children():
				if nearby != enemy and nearby.global_position.distance_to(enemy.global_position) <= 125.0:
					nearby.take_damage(60.0)
		if enemy.archetype == "boss":
			_on_boss_defeated()
		elif enemy.get_instance_id() == bounty_target_id:
			_on_bounty_completed()
		elif str(enemy.get("elite_affix")) == "splinter":
			_spawn_enemy("chaser", enemy.global_position + Vector2.RIGHT.rotated(randf() * TAU) * 24.0)

func _spawn_xp_gem(spawn_position: Vector2, value: int) -> void:
	var gem: Node2D = XPGemScene.instantiate()
	gem.global_position = spawn_position
	gem.value = value
	xp_gems.add_child(gem)

func _try_spawn_pickup(spawn_position: Vector2) -> void:
	var roll := randf() * 100.0
	if roll < magnet_pickup_drop_chance_percent:
		_spawn_pickup(spawn_position, "magnet")
	elif roll < magnet_pickup_drop_chance_percent + potion_pickup_drop_chance_percent:
		_spawn_pickup(spawn_position, "potion")
	elif roll < magnet_pickup_drop_chance_percent + potion_pickup_drop_chance_percent + slot_pickup_drop_chance_percent:
		_spawn_pickup(spawn_position, "slot")

func _spawn_pickup(spawn_position: Vector2, pickup_type: String) -> void:
	var pickup: Node2D = PickupItemScene.instantiate()
	pickup.global_position = spawn_position
	pickup.pickup_type = pickup_type
	pickups.add_child(pickup)

func _check_xp_gems() -> void:
	for gem in xp_gems.get_children():
		var distance := player.global_position.distance_to(gem.global_position)
		if global_magnet_timer > 0.0 or distance <= xp_magnet_range:
			gem.target = player
		if distance <= player.radius + gem.radius:
			_gain_experience(gem.value)
			gem.queue_free()

func _check_pickups() -> void:
	for pickup in pickups.get_children():
		var distance := player.global_position.distance_to(pickup.global_position)
		if global_magnet_timer > 0.0 or distance <= xp_magnet_range:
			pickup.target = player
		if distance <= player.radius + pickup.radius:
			_apply_pickup(pickup.pickup_type)
			_spawn_particle_burst(pickup.global_position, "pickup")
			pickup.queue_free()

func _apply_pickup(pickup_type: String) -> void:
	match pickup_type:
		"magnet":
			global_magnet_timer = 4.0
			for gem in xp_gems.get_children():
				gem.target = player
			for pickup in pickups.get_children():
				pickup.target = player
			hud.hint.text = "磁铁：全图灵魂正在靠近。"
		"potion":
			player.heal_percent(0.5)
			hud.hint.text = "药瓶：恢复 50% 最大生命。"
		"slot":
			_start_slot_machine()

func _start_slot_machine() -> void:
	var bundle: Dictionary = weapon_manager.build_slot_bundle()
	level_up_pending = true
	get_tree().paused = true
	hud.show_slot_machine(bundle.get("reels", []), bundle.get("options", []), bool(bundle.get("jackpot", false)))

func _gain_experience(amount: int) -> void:
	experience += amount
	while experience >= experience_to_next:
		experience -= experience_to_next
		level += 1
		experience_to_next = int(round(experience_to_next * 1.42 + 11.0 + level * 1.8))
		_start_level_up()
		if level_up_pending:
			return

func _start_level_up() -> void:
	level_up_pending = true
	rerolls_left = 1 + level / 8
	get_tree().paused = true
	_spawn_particle_burst(player.global_position, "level_up")
	hud.show_level_up(weapon_manager.build_upgrade_options())
	hud.set_rerolls_left(rerolls_left)

func _check_enemy_contacts(delta: float) -> void:
	for enemy in enemies.get_children():
		if player.global_position.distance_to(enemy.global_position) <= player.radius + enemy.radius:
			player.take_damage(enemy.contact_damage * delta)

func _check_enemy_projectile_hits() -> void:
	for enemy_projectile in enemy_projectiles.get_children():
		if player.global_position.distance_to(enemy_projectile.global_position) <= player.radius + enemy_projectile.radius:
			player.take_damage(enemy_projectile.damage)
			enemy_projectile.queue_free()

func _update_enemy_buffs() -> void:
	var buffers := []
	for enemy in enemies.get_children():
		if enemy.archetype == "buffer":
			buffers.append(enemy)
	for enemy in enemies.get_children():
		var buffed := false
		for buffer in buffers:
			if enemy != buffer and enemy.global_position.distance_to(buffer.global_position) <= 110.0:
				buffed = true
				break
		enemy.set_buffed(buffed)

func _update_hud() -> void:
	hud.set_stats(player.health, player.max_health, score, elapsed, enemies.get_child_count(), level, experience, experience_to_next, current_wave, max_wave, wave_time_left, weapon_manager.get_summary(), weapon_manager.get_passive_summary())

func _on_wave_spawn_requested(archetype: String, count: int) -> void:
	for index in range(count):
		_spawn_enemy(archetype)

func _on_wave_changed(wave: int, new_max_wave: int, time_left: float) -> void:
	var previous_wave := current_wave
	current_wave = wave
	max_wave = new_max_wave
	wave_time_left = time_left
	if wave > 1 and wave != previous_wave:
		_expire_wave_effects()
		var alert_text := "第 %02d 波来袭" % wave
		var is_major := false
		if wave == 10 or wave == 20:
			alert_text = "精英波来袭"
			is_major = true
		elif wave == 30:
			alert_text = "深渊君王来袭"
			is_major = true
		hud.show_wave_alert(alert_text, is_major)
		sfx_manager.play_ui("boss_wave" if is_major else "wave")
		_vibrate_wave(is_major)
		_maybe_offer_wave_event(wave, is_major)

func _on_boss_wave_started() -> void:
	hud.hint.text = "第30波：深渊君王降临。"
	hud.show_wave_alert("深渊君王来袭", true)
	sfx_manager.play_ui("boss_wave")
	_vibrate_for_boss()

func _on_enemy_projectile_requested(spawn_position: Vector2, direction: Vector2, damage: float, speed: float, radius: float) -> void:
	if mobile_profile_enabled and enemy_projectiles.get_child_count() >= 44:
		return
	var enemy_projectile: Node2D = EnemyProjectileScene.instantiate()
	enemy_projectile.global_position = spawn_position
	enemy_projectile.direction = direction
	enemy_projectile.damage = damage
	enemy_projectile.speed = speed
	enemy_projectile.radius = radius
	enemy_projectile.world_size = player.world_size
	enemy_projectiles.add_child(enemy_projectile)

func _on_enemy_summon_requested(archetype: String, spawn_position: Vector2) -> void:
	_spawn_enemy(archetype, spawn_position)

func _on_player_damaged(_health: float) -> void:
	_update_hud()

func _on_player_died() -> void:
	get_tree().paused = true
	hud.show_game_over(score, elapsed)

func _on_boss_defeated() -> void:
	victory_pending = true
	get_tree().paused = true
	hud.show_victory(elapsed)

func _on_upgrade_selected(upgrade_id: String) -> void:
	if str(upgrade_id).begins_with("event:"):
		_resolve_event_choice(upgrade_id)
		return
	_resolve_upgrade(upgrade_id)
	level_up_pending = false
	hud.hide_level_up()
	get_tree().paused = false
	_update_hud()

func _apply_passive_side_effect(result: Dictionary) -> void:
	var effect: Dictionary = result.get("effect", {})
	if effect.is_empty():
		return
	match effect.get("stat", ""):
		"damage":
			player_damage_multiplier *= 1.04
		"cooldown":
			xp_magnet_range += 15.0
		"radius":
			xp_magnet_range += 20.0
		"projectile_speed":
			player.speed += 8.0

func _on_reroll_requested() -> void:
	if not level_up_pending or rerolls_left <= 0:
		return
	rerolls_left -= 1
	hud.show_level_up(weapon_manager.build_upgrade_options())
	hud.set_rerolls_left(rerolls_left)

func _resolve_upgrade(upgrade_id: String) -> void:
	var result: Dictionary = weapon_manager.apply_upgrade(upgrade_id)
	match result.get("kind", ""):
		"passive":
			player.add_passive_trait(result.get("passive", ""))
			_apply_passive_side_effect(result)
		"stat":
			match result.get("stat", ""):
				"damage":
					weapon_manager.apply_stat_upgrade("damage", 0.18)
					player_damage_multiplier *= 1.08
				"cooldown":
					weapon_manager.apply_stat_upgrade("cooldown", 0.10)
				"radius":
					weapon_manager.apply_stat_upgrade("radius", 0.14)
				"projectile_speed":
					weapon_manager.apply_stat_upgrade("projectile_speed", 0.16)
				"vitality":
					player.speed += 18.0
					player.increase_vitality()
				"magnet":
					xp_magnet_range += 55.0
				"invulnerability":
					player.invulnerability_duration += 0.35
				"heal":
					player.heal_percent(0.35)

func _on_jackpot_reward_granted(upgrade_id: String) -> void:
	_resolve_upgrade(upgrade_id)
	sfx_manager.play_ui("jackpot_step")
	_add_shake(0.04, 2.2)
	_update_hud()

func _on_jackpot_finished() -> void:
	level_up_pending = false
	hud.hide_level_up()
	get_tree().paused = false
	sfx_manager.play_ui("jackpot")
	_vibrate_jackpot()
	_update_hud()

func _on_weapon_fired(weapon_family: String) -> void:
	sfx_manager.play_weapon(weapon_family)

func _vibrate_wave(is_major: bool) -> void:
	if not mobile_profile_enabled:
		return
	Input.vibrate_handheld(120 if is_major else 60, 0.8 if is_major else 0.45)

func _vibrate_for_boss() -> void:
	if not mobile_profile_enabled:
		return
	Input.vibrate_handheld(180, 1.0)

func _vibrate_jackpot() -> void:
	if not mobile_profile_enabled:
		return
	Input.vibrate_handheld(90, 0.9)

func _maybe_offer_wave_event(wave: int, is_major: bool) -> void:
	if is_major or wave >= 30 or wave % 4 != 0:
		return
	if level_up_pending or victory_pending:
		return
	pending_event = _build_wave_event()
	if pending_event.is_empty():
		return
	level_up_pending = true
	get_tree().paused = true
	hud.show_level_up(
		pending_event.get("options", []),
		str(pending_event.get("title", "命运事件")),
		str(pending_event.get("prompt", "做出你的选择。")),
		false
	)

func _build_wave_event() -> Dictionary:
	var event_roll := randi() % 3
	if event_roll == 0:
		return {
			"title": "临时祝福",
			"prompt": "选择一份仅持续 1 波的祝福。",
			"options": [
				{"id": "event:blessing_damage", "title": "血潮祝福", "description": "本波伤害 +25%。", "category": "事件", "rarity": "稀有"},
				{"id": "event:blessing_cooldown", "title": "疾咒祝福", "description": "本波冷却缩短 20%。", "category": "事件", "rarity": "稀有"},
				{"id": "event:blessing_haste", "title": "迅影祝福", "description": "本波移速 +50，弹速 +20%。", "category": "事件", "rarity": "稀有"}
			]
		}
	if event_roll == 1:
		return {
			"title": "精英悬赏",
			"prompt": "接受悬赏，击杀目标精英即可获得额外升级。",
			"options": [
				{"id": "event:bounty_accept", "title": "接受悬赏", "description": "刷出一只悬赏精英，击杀后获得 1 次额外升级。", "category": "事件", "rarity": "史诗"},
				{"id": "event:bounty_skip", "title": "放弃悬赏", "description": "跳过本次高风险机会。", "category": "事件", "rarity": "普通"}
			]
		}
	return {
		"title": "恶魔交易",
		"prompt": "付出代价，换取立刻爆发的力量。",
		"options": [
			{"id": "event:bargain_blood", "title": "血契", "description": "失去 25% 最大生命，永久伤害 +30%。", "category": "事件", "rarity": "史诗"},
			{"id": "event:bargain_level", "title": "邪馈", "description": "失去 15% 最大生命，立刻获得一次额外升级。", "category": "事件", "rarity": "传说"},
			{"id": "event:bargain_refuse", "title": "拒绝", "description": "保持现状，不接受恶魔提议。", "category": "事件", "rarity": "普通"}
		]
	}

func _resolve_event_choice(event_id: String) -> void:
	match event_id:
		"event:blessing_damage":
			_apply_blessing("damage", current_wave + 1)
		"event:blessing_cooldown":
			_apply_blessing("cooldown", current_wave + 1)
		"event:blessing_haste":
			_apply_blessing("haste", current_wave + 1)
		"event:bounty_accept":
			_start_bounty_event()
		"event:bounty_skip":
			hud.hint.text = "你放弃了本轮悬赏。"
		"event:bargain_blood":
			_sacrifice_health(0.25)
			player_damage_multiplier *= 1.30
			hud.hint.text = "血契生效：永久伤害大幅提升。"
		"event:bargain_level":
			_sacrifice_health(0.15)
			hud.hint.text = "邪馈生效：立刻赐予额外升级。"
			pending_event.clear()
			level_up_pending = false
			hud.hide_level_up()
			get_tree().paused = false
			_start_level_up()
			return
		"event:bargain_refuse":
			hud.hint.text = "你拒绝了恶魔的交易。"
	pending_event.clear()
	level_up_pending = false
	hud.hide_level_up()
	get_tree().paused = false
	_update_hud()

func _apply_blessing(blessing_id: String, expires_wave: int) -> void:
	active_blessings[blessing_id] = expires_wave
	match blessing_id:
		"damage":
			player_damage_multiplier *= 1.25
			hud.hint.text = "血潮祝福：本波伤害暴涨。"
		"cooldown":
			weapon_manager.set_temporary_bonus("cooldown", 0.80)
			hud.hint.text = "疾咒祝福：本波攻击更密集。"
		"haste":
			player.speed += 50.0
			weapon_manager.set_temporary_bonus("projectile_speed", 1.20)
			hud.hint.text = "迅影祝福：本波移动与弹速提升。"

func _expire_wave_effects() -> void:
	if bounty_target_id != -1 and current_wave > bounty_expires_wave:
		bounty_target_id = -1
		bounty_expires_wave = -1
		hud.hint.text = "悬赏过期，目标逃入黑暗。"
	if active_blessings.has("damage") and int(active_blessings["damage"]) <= current_wave:
		active_blessings.erase("damage")
		player_damage_multiplier /= 1.25
	if active_blessings.has("cooldown") and int(active_blessings["cooldown"]) <= current_wave:
		active_blessings.erase("cooldown")
		weapon_manager.set_temporary_bonus("cooldown", 1.0)
	if active_blessings.has("haste") and int(active_blessings["haste"]) <= current_wave:
		active_blessings.erase("haste")
		player.speed -= 50.0
		weapon_manager.set_temporary_bonus("projectile_speed", 1.0)

func _start_bounty_event() -> void:
	var enemy: Node2D = EnemyScene.instantiate()
	enemy.global_position = _random_spawn_position("elite")
	enemy.target = player
	enemies.add_child(enemy)
	enemy.configure("elite", current_wave + 2)
	enemy.scale *= 1.22
	enemy.health *= 1.35
	enemy.max_health *= 1.35
	enemy.xp_reward += 8
	enemy.projectile_requested.connect(_on_enemy_projectile_requested)
	enemy.summon_requested.connect(_on_enemy_summon_requested)
	bounty_target_id = enemy.get_instance_id()
	bounty_expires_wave = current_wave + 1
	hud.hint.text = "悬赏开启：击杀猩红精英，立即获得额外升级。"

func _on_bounty_completed() -> void:
	bounty_target_id = -1
	bounty_expires_wave = -1
	level_up_pending = true
	get_tree().paused = true
	hud.show_level_up(
		weapon_manager.build_upgrade_options(4),
		"悬赏完成",
		"猩红悬赏已兑现，挑一项战利品。",
		false
	)
	sfx_manager.play_ui("jackpot")

func _sacrifice_health(percent: float) -> void:
	player.health = max(1.0, player.health - player.max_health * percent)
	player.damaged.emit(player.health)

func _spawn_hit_effect(position: Vector2, amount: float) -> void:
	_trim_effects(2)
	var effect := Node2D.new()
	effect.set_script(CombatEffectScript)
	effect.global_position = position + Vector2(randf_range(-10.0, 10.0), randf_range(-12.0, 4.0))
	effect.duration = 0.22
	effect.radius = 18.0
	effect.color = Color(1.0, 0.82, 0.26, 0.8)
	effect.effect_kind = "hit"
	effects.add_child(effect)
	var number := Node2D.new()
	number.set_script(CombatEffectScript)
	number.global_position = position + Vector2(0, -enemy_text_offset())
	number.duration = 0.48
	number.label = str(int(round(amount)))
	number.velocity = Vector2(0, -34.0)
	effects.add_child(number)

func _spawn_death_effect(position: Vector2, radius: float, archetype: String) -> void:
	_trim_effects(1)
	var effect := Node2D.new()
	effect.set_script(CombatEffectScript)
	effect.global_position = position
	effect.duration = 0.46
	effect.radius = max(42.0, radius * 2.4)
	effect.color = Color(1.0, 0.15, 0.10, 0.82)
	effect.effect_kind = "death"
	if archetype == "bomber":
		effect.color = Color(0.72, 1.0, 0.18, 0.86)
		effect.radius *= 1.35
	effects.add_child(effect)

func _spawn_particle_burst(position: Vector2, effect_type: String) -> void:
	_trim_effects(1)
	var burst: GPUParticles2D = ParticleBurstScene.instantiate()
	burst.global_position = position
	effects.add_child(burst)
	burst.configure(effect_type)

func _trim_effects(incoming_count := 1) -> void:
	var overflow: int = effects.get_child_count() + incoming_count - max_effect_nodes
	if overflow <= 0:
		return
	for index in range(min(overflow, effects.get_child_count())):
		effects.get_child(index).queue_free()

func enemy_text_offset() -> float:
	return 26.0

func _maybe_apply_enemy_affix(enemy: Node2D, archetype: String) -> void:
	if archetype == "boss":
		return
	var chance := 0
	if archetype == "elite":
		chance = 100
	elif current_wave >= 8:
		chance = 10 + current_wave / 2
	if randi() % 100 >= chance:
		return
	var affixes: Array[String] = ["swift", "warded", "furious", "splinter"]
	enemy.apply_affix(affixes[randi() % affixes.size()])

func _add_shake(duration: float, strength: float) -> void:
	shake_timer = max(shake_timer, duration)
	shake_strength = max(shake_strength, strength)

func _update_camera_shake(delta: float) -> void:
	if shake_timer <= 0.0:
		camera.offset = Vector2.ZERO
		return
	shake_timer -= delta
	camera.offset = Vector2(randf_range(-shake_strength, shake_strength), randf_range(-shake_strength, shake_strength))
	shake_strength = max(0.0, shake_strength - delta * 38.0)

func _on_restart_requested() -> void:
	get_tree().paused = false
	get_tree().reload_current_scene()
