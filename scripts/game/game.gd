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
const EnemyBatchRendererScript := preload("res://scripts/visuals/enemy_batch_renderer.gd")
const XPBatchRendererScript := preload("res://scripts/visuals/xp_batch_renderer.gd")

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

var bgm_stream_paths: Array[String] = [
	"res://assets/audio/bgm.mp3",
	"res://assets/audio/bgm2.mp3",
	"res://assets/audio/bgm3.mp3",
	"res://assets/audio/bgm4.mp3",
	"res://assets/audio/bgm5.mp3"
]
var bgm_streams: Array[AudioStream] = []
var last_bgm_index := -1
var score := 0
var elapsed := 0.0
var level := 1
var experience := 0
var experience_to_next := 10
var level_up_pending := false
var victory_pending := false
var current_wave := 1
var max_wave := 50
var wave_time_left := 0.0
var player_damage_multiplier := 1.0
var xp_magnet_range := 120.0
var run_magic_crystals := 0
var experience_gain_bonus := 0.0
var luck := 0.0
@export_range(0.0, 100.0, 0.01) var magnet_pickup_drop_chance_percent := 2.5
@export_range(0.0, 100.0, 0.01) var potion_pickup_drop_chance_percent := 0.5
@export_range(0.0, 100.0, 0.01) var slot_pickup_drop_chance_percent := 0.02
@export_range(0.0, 100.0, 0.01) var chest_pickup_drop_chance_percent := 0.2
@export_range(0.0, 100.0, 0.01) var magic_crystal_pickup_drop_chance_percent := 0.01
@export_range(0.0, 100.0, 0.01) var bomb_pickup_drop_chance_percent := 0.133333
var rerolls_left := 1
var shake_timer := 0.0
var shake_strength := 0.0
var global_magnet_timer := 0.0
var haste_timer := 0.0
var haste_speed_bonus := 220.0
var haste_active := false
var max_effect_nodes := 70
var mobile_profile_enabled := false
var collision_tick_interval := 0.08
var enemy_spatial_cell_size := 320.0
var enemy_spatial_buckets: Dictionary = {}
var collision_tick_timer: Timer
var hud_tick_timer: Timer
var enemy_batch_renderer: Node2D
var xp_batch_renderer: Node2D
var xp_spawn_queue: Array[Dictionary] = []
var xp_spawn_per_tick := 24
var sfx_manager
var pending_event := {}
var active_blessings := {}
var bounty_target_id := -1
var bounty_expires_wave := -1
var selected_hero := {}
var world_scale_multiplier := 1.0
var pool_root: Node
var object_pools := {
	"enemy": [],
	"projectile": [],
	"enemy_projectile": [],
	"xp_gem": [],
	"pickup": [],
	"effect": [],
	"weapon_zone": [],
	"particle_burst": [],
	"ui_burst": []
}
var pool_limits := {
		"enemy": 240,
	"projectile": 160,
	"enemy_projectile": 64,
		"xp_gem": 180,
	"pickup": 36,
		"effect": 140,
	"weapon_zone": 120,
	"particle_burst": 42,
	"ui_burst": 80
}

func _ready() -> void:
	get_tree().paused = false
	_setup_object_pool()
	_setup_enemy_batch_renderer()
	_setup_xp_batch_renderer()
	_setup_bgm()
	if has_node("Arena"):
		player.world_size = $Arena.arena_size
	_apply_selected_hero()
	_apply_runtime_profile()
	player.died.connect(_on_player_died)
	player.damaged.connect(_on_player_damaged)
	hud.upgrade_selected.connect(_on_upgrade_selected)
	hud.reroll_requested.connect(_on_reroll_requested)
	hud.restart_requested.connect(_on_restart_requested)
	hud.main_menu_requested.connect(_on_main_menu_requested)
	hud.exit_run_requested.connect(_on_exit_run_requested)
	hud.jackpot_reward_granted.connect(_on_jackpot_reward_granted)
	hud.jackpot_finished.connect(_on_jackpot_finished)
	hud.joystick_changed.connect(player.set_virtual_joystick_vector)
	sfx_manager = Node.new()
	sfx_manager.set_script(SFXManagerScript)
	add_child(sfx_manager)
	hud.slot_tick_requested.connect(_on_slot_tick_requested)
	weapon_manager.setup(player, enemies, projectiles, weapon_zones, ProjectileScene, WeaponZoneScene, str(selected_hero.get("initial_weapon", "blood_bolt")))
	if weapon_manager.has_method("configure_hero_rules"):
		weapon_manager.configure_hero_rules(selected_hero)
	if weapon_manager.has_method("set_projectile_recycler"):
		weapon_manager.set_projectile_recycler(Callable(self, "_return_to_pool"))
	if weapon_manager.has_method("set_projectile_factory"):
		weapon_manager.set_projectile_factory(Callable(self, "_take_projectile_from_pool"))
	if weapon_manager.has_method("set_zone_factory"):
		weapon_manager.set_zone_factory(Callable(self, "_take_weapon_zone_from_pool"))
	if weapon_manager.has_method("set_zone_recycler"):
		weapon_manager.set_zone_recycler(Callable(self, "_return_to_pool"))
	if hud.has_method("set_ui_burst_pool"):
		hud.set_ui_burst_pool(Callable(self, "_take_ui_burst_from_pool"), Callable(self, "_return_to_pool"))
	_apply_selected_hero_weapon_mods()
	weapon_manager.weapon_fired.connect(_on_weapon_fired)
	wave_director.spawn_requested.connect(_on_wave_spawn_requested)
	wave_director.wave_changed.connect(_on_wave_changed)
	wave_director.boss_wave_started.connect(_on_boss_wave_started)
	wave_director.reset()
	_setup_event_timers()
	_update_hud()

func _setup_enemy_batch_renderer() -> void:
	enemy_batch_renderer = Node2D.new()
	enemy_batch_renderer.name = "EnemyBatchRenderer"
	enemy_batch_renderer.set_script(EnemyBatchRendererScript)
	add_child(enemy_batch_renderer)
	move_child(enemy_batch_renderer, enemies.get_index())
	if enemy_batch_renderer.has_method("setup"):
		enemy_batch_renderer.setup(enemies)

func _setup_xp_batch_renderer() -> void:
	xp_batch_renderer = Node2D.new()
	xp_batch_renderer.name = "XPBatchRenderer"
	xp_batch_renderer.set_script(XPBatchRendererScript)
	add_child(xp_batch_renderer)
	if xp_batch_renderer.has_method("setup"):
		xp_batch_renderer.setup(xp_gems)


func _setup_event_timers() -> void:
	collision_tick_timer = Timer.new()
	collision_tick_timer.wait_time = collision_tick_interval
	collision_tick_timer.one_shot = false
	collision_tick_timer.timeout.connect(_on_collision_tick)
	add_child(collision_tick_timer)
	collision_tick_timer.start()

	hud_tick_timer = Timer.new()
	hud_tick_timer.wait_time = 0.28 if mobile_profile_enabled else 0.20
	hud_tick_timer.one_shot = false
	hud_tick_timer.timeout.connect(_on_hud_tick)
	add_child(hud_tick_timer)
	hud_tick_timer.start()

func _setup_bgm() -> void:
	if bgm_player == null:
		return
	bgm_streams.clear()
	for path in bgm_stream_paths:
		if not ResourceLoader.exists(path):
			continue
		var loaded := load(path)
		if loaded is AudioStream:
			var stream := loaded as AudioStream
			_set_bgm_loop(stream, false)
			bgm_streams.append(stream)
	if bgm_streams.is_empty() and bgm_player.stream != null:
		_set_bgm_loop(bgm_player.stream, false)
		bgm_streams.append(bgm_player.stream)
	if bgm_streams.is_empty():
		return
	if not bgm_player.finished.is_connected(_on_bgm_finished):
		bgm_player.finished.connect(_on_bgm_finished)
	_play_random_bgm(true)

func _set_bgm_loop(stream: AudioStream, enabled: bool) -> void:
	if stream == null:
		return
	if stream.has_method("set_loop"):
		stream.set_loop(enabled)
	elif "loop" in stream:
		stream.loop = enabled

func _play_random_bgm(force := false) -> void:
	if bgm_player == null or bgm_streams.is_empty():
		return
	if bgm_player.playing and not force:
		return
	var index := randi() % bgm_streams.size()
	if bgm_streams.size() > 1 and index == last_bgm_index:
		index = (index + 1 + randi() % (bgm_streams.size() - 1)) % bgm_streams.size()
	last_bgm_index = index
	bgm_player.stream = bgm_streams[index]
	bgm_player.play()

func _on_bgm_finished() -> void:
	_play_random_bgm(true)

func _apply_runtime_profile() -> void:
	mobile_profile_enabled = OS.has_feature("mobile")
	if not mobile_profile_enabled:
		return

	max_effect_nodes = 32
	collision_tick_interval = 0.11
	xp_magnet_range = 150.0
	wave_director.max_alive_enemies = min(wave_director.max_alive_enemies, 82)
	weapon_manager.max_weapon_zones = min(weapon_manager.max_weapon_zones, 24)
	weapon_manager.max_projectiles = min(weapon_manager.max_projectiles, 42)

func _apply_selected_hero() -> void:
	if has_node("/root/RuntimeConfig"):
		selected_hero = get_node("/root/RuntimeConfig").selected_hero()
	else:
		selected_hero = {"initial_weapon": "blood_bolt"}
	if player.has_method("apply_hero"):
		player.apply_hero(selected_hero)

func _apply_selected_hero_weapon_mods() -> void:
	var mods: Dictionary = selected_hero.get("mods", {})
	if mods.has("damage"):
		player_damage_multiplier *= float(mods["damage"])
	if mods.has("cooldown"):
		weapon_manager.cooldown_multiplier *= float(mods["cooldown"])
	if mods.has("radius"):
		weapon_manager.radius_multiplier *= float(mods["radius"])
	if mods.has("projectile_speed"):
		weapon_manager.projectile_speed_multiplier *= float(mods["projectile_speed"])
	if mods.has("crit_chance"):
		weapon_manager.crit_chance = min(0.50, weapon_manager.crit_chance + float(mods["crit_chance"]))
	if mods.has("crit_damage"):
		weapon_manager.crit_damage_multiplier += float(mods["crit_damage"])
	if mods.has("magnet"):
		xp_magnet_range += float(mods["magnet"])
	if has_node("/root/RuntimeConfig"):
		var runtime := get_node("/root/RuntimeConfig")
		player.max_health += runtime.talent_bonus("health")
		player.health = player.max_health
		player.speed += runtime.talent_bonus("speed")
		player_damage_multiplier *= 1.0 + runtime.talent_bonus("damage")
		weapon_manager.radius_multiplier *= 1.0 + runtime.talent_bonus("radius")
		xp_magnet_range += runtime.talent_bonus("magnet")
		weapon_manager.lifesteal_chance += runtime.talent_bonus("lifesteal_chance")
		weapon_manager.lifesteal_amount += runtime.talent_bonus("lifesteal_amount")
		weapon_manager.crit_chance = min(0.70, weapon_manager.crit_chance + runtime.talent_bonus("crit_chance"))
		weapon_manager.crit_damage_multiplier += runtime.talent_bonus("crit_damage")
		experience_gain_bonus = runtime.talent_bonus("experience_gain")
		luck = runtime.talent_bonus("luck")
		weapon_manager.relic_luck_bonus = luck

func _physics_process(delta: float) -> void:
	if level_up_pending or victory_pending:
		return

	elapsed += delta
	wave_director.tick(delta, enemies.get_child_count())
	weapon_manager.tick(delta)
	global_magnet_timer = max(0.0, global_magnet_timer - delta)
	_update_haste(delta)
	_update_camera_shake(delta)

func _on_collision_tick() -> void:
	if level_up_pending or victory_pending:
		return
	_process_xp_queue()
	# Adaptive tick rate: slow down collision when FPS drops
	var fps := Engine.get_frames_per_second()
	if fps < 25.0 and collision_tick_interval < 0.18:
		collision_tick_interval = min(0.18, collision_tick_interval + 0.02)
		collision_tick_timer.wait_time = collision_tick_interval
	elif fps > 50.0 and collision_tick_interval > 0.08:
		collision_tick_interval = max(0.08, collision_tick_interval - 0.01)
		collision_tick_timer.wait_time = collision_tick_interval
	_rebuild_enemy_spatial_index()
	_update_enemy_buffs()
	_check_projectile_hits()
	_check_weapon_zone_hits()
	_check_enemy_projectile_hits()
	_check_xp_gems()
	_check_pickups()
	_check_enemy_contacts(collision_tick_interval)

func _on_hud_tick() -> void:
	if level_up_pending:
		return
	_update_hud()

func _spawn_enemy(archetype: String, spawn_position := Vector2.INF) -> void:
	var enemy: Node2D = _take_from_pool("enemy", EnemyScene)
	if spawn_position == Vector2.INF:
		enemy.global_position = _random_spawn_position(archetype)
	else:
		enemy.global_position = spawn_position
	enemy.target = player
	enemy.set("world_size", player.world_size)
	enemies.add_child(enemy)
	enemy.configure(archetype, current_wave)
	_maybe_apply_enemy_affix(enemy, archetype)
	_connect_enemy_pool_signals(enemy)

func _random_spawn_position(archetype: String) -> Vector2:
	var world_size: Vector2 = player.world_size
	if archetype == "boss" or archetype == "bullet_boss":
		return (player.global_position + Vector2(0, -420.0)).clamp(Vector2(96, 96), world_size - Vector2(96, 96))
	var angle := randf() * TAU
	var distance := randf_range(800.0, 1100.0)
	return (player.global_position + Vector2.RIGHT.rotated(angle) * distance).clamp(Vector2(64, 64), world_size - Vector2(64, 64))

func _check_projectile_hits() -> void:
	for projectile in projectiles.get_children():
		if not is_instance_valid(projectile):
			continue
		for enemy in _nearby_enemies(projectile.global_position, projectile.radius + 180.0):
			var hit_key := "hit_%s" % enemy.get_instance_id()
			if projectile.has_meta(hit_key):
				continue
			if projectile.global_position.distance_to(enemy.global_position) <= projectile.radius + enemy.radius:
				projectile.set_meta(hit_key, true)
				_damage_enemy(enemy, projectile.damage * player_damage_multiplier, projectile)
				projectile.hit_count += 1
				# Hit explosion
				var expl_radius: float = float(projectile.get("explosion_radius"))
				if expl_radius > 0.0:
					var expl_dmg: float = float(projectile.get("explosion_damage")) * player_damage_multiplier
					for nearby in _nearby_enemies(projectile.global_position, expl_radius + 60.0):
						if nearby == enemy:
							continue
						if projectile.global_position.distance_to(nearby.global_position) <= expl_radius + float(nearby.get("radius")):
							_damage_enemy(nearby, expl_dmg, projectile)
					_spawn_hit_explosion_effect(projectile.global_position, expl_radius)
				if projectile.hit_count > projectile.pierce:
					# Try ricochet before recycling
					var ricochet_ok := false
					if projectile.has_method("try_ricochet"):
						ricochet_ok = projectile.try_ricochet(enemies)
					if not ricochet_ok:
						_return_to_pool(projectile, "projectile")
						break

func _spawn_hit_explosion_effect(position: Vector2, radius: float) -> void:
	_trim_effects(1)
	var effect := _take_effect_from_pool()
	effect.global_position = position
	effect.duration = 0.22
	effect.radius = max(24.0, radius)
	effect.color = Color(1.0, 0.55, 0.15, 0.75)
	effect.effect_kind = "impact"
	effects.add_child(effect)
	if effect.has_method("reset_for_pool"):
		effect.reset_for_pool()
	if not effect.despawn_requested.is_connected(_on_effect_despawn_requested):
		effect.despawn_requested.connect(_on_effect_despawn_requested)

func _check_weapon_zone_hits() -> void:
	for zone in weapon_zones.get_children():
		if not zone.has_method("consume_damage_ready"):
			continue
		if not zone.consume_damage_ready():
			continue
		for enemy in _nearby_enemies(zone.global_position, zone.radius + 180.0):
			if zone.global_position.distance_to(enemy.global_position) <= zone.radius + enemy.radius:
				_damage_enemy(enemy, zone.damage * player_damage_multiplier, zone)

func _damage_enemy(enemy: Node2D, amount: float, source: Node = null) -> void:
	if enemy.health <= 0.0:
		return
	var final_amount := amount
	var critical := false
	if weapon_manager.has_method("roll_critical") and weapon_manager.roll_critical():
		critical = true
		final_amount *= weapon_manager.crit_damage_multiplier
	enemy.take_damage(final_amount)
	_apply_weapon_traits(enemy, final_amount, source)
	_spawn_hit_effect(enemy.global_position, final_amount, critical)
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
			for nearby in _nearby_enemies(enemy.global_position, 160.0):
				if nearby != enemy and nearby.global_position.distance_to(enemy.global_position) <= 125.0:
					_damage_enemy(nearby, 60.0)
			if enemy.archetype == "boss":
				_on_boss_defeated()
			elif enemy.archetype == "bullet_boss":
				_spawn_pickup(enemy.global_position, "slot")
			elif enemy.get_instance_id() == bounty_target_id:
				_on_bounty_completed()
		elif str(enemy.get("elite_affix")) == "splinter":
			_spawn_enemy("chaser", enemy.global_position + Vector2.RIGHT.rotated(randf() * TAU) * 24.0)

func _spawn_xp_gem(spawn_position: Vector2, value: int) -> void:
	xp_spawn_queue.append({"position": spawn_position, "value": value})

func _process_xp_queue() -> void:
	var count := mini(xp_spawn_queue.size(), xp_spawn_per_tick)
	for i in range(count):
		var data: Dictionary = xp_spawn_queue.pop_front()
		var gem: Node2D = _take_from_pool("xp_gem", XPGemScene)
		gem.global_position = data.get("position", Vector2.ZERO)
		gem.value = int(data.get("value", 1))
		if gem.has_method("set_batched"):
			gem.set_batched(true)
		xp_gems.add_child(gem)
		if gem.has_method("reset_for_pool"):
			gem.reset_for_pool()
		if not gem.despawn_requested.is_connected(_on_xp_gem_despawn_requested):
			gem.despawn_requested.connect(_on_xp_gem_despawn_requested)

func _try_spawn_pickup(spawn_position: Vector2) -> void:
	var roll := randf() * 100.0
	var threshold := magnet_pickup_drop_chance_percent
	if roll < magnet_pickup_drop_chance_percent:
		_spawn_pickup(spawn_position, "magnet")
		return
	threshold += potion_pickup_drop_chance_percent
	if roll < threshold:
		_spawn_pickup(spawn_position, "potion")
		return
	threshold += slot_pickup_drop_chance_percent
	if roll < threshold:
		_spawn_pickup(spawn_position, "slot")
		return
	threshold += chest_pickup_drop_chance_percent
	if roll < threshold:
		_spawn_pickup(spawn_position, "chest")
		return
	threshold += magic_crystal_pickup_drop_chance_percent
	if roll < threshold:
		_spawn_pickup(spawn_position, "crystal")
		return
	threshold += bomb_pickup_drop_chance_percent
	if roll < threshold:
		_spawn_pickup(spawn_position, "bomb")

func _spawn_pickup(spawn_position: Vector2, pickup_type: String) -> void:
	var pickup: Node2D = _take_from_pool("pickup", PickupItemScene)
	pickup.global_position = spawn_position
	pickup.pickup_type = pickup_type
	pickups.add_child(pickup)
	if pickup.has_method("reset_for_pool"):
		pickup.reset_for_pool()
	if not pickup.despawn_requested.is_connected(_on_pickup_despawn_requested):
		pickup.despawn_requested.connect(_on_pickup_despawn_requested)

func _check_xp_gems() -> void:
	for gem in xp_gems.get_children():
		var distance := player.global_position.distance_to(gem.global_position)
		if global_magnet_timer > 0.0 or distance <= xp_magnet_range:
			gem.target = player
		if distance <= player.radius + gem.radius:
			_gain_experience(gem.value)
			_return_to_pool(gem, "xp_gem")

func _check_pickups() -> void:
	for pickup in pickups.get_children():
		if pickup.get("opening"):
			continue
		var distance := player.global_position.distance_to(pickup.global_position)
		if global_magnet_timer > 0.0 or distance <= xp_magnet_range:
			pickup.target = player
		if distance <= player.radius + pickup.radius:
			if pickup.pickup_type == "chest":
				_open_chest_pickup(pickup)
				continue
			_apply_pickup(pickup.pickup_type)
			_spawn_particle_burst(pickup.global_position, "pickup")
			_return_to_pool(pickup, "pickup")

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
		"haste":
			_apply_haste_potion()
		"chest":
			_apply_pickup(_random_chest_reward())
		"crystal":
			var amount := 1 + randi() % 3
			run_magic_crystals += amount
			if has_node("/root/RuntimeConfig"):
				get_node("/root/RuntimeConfig").add_magic_crystals(amount)
			hud.hint.text = "魔晶 +%d：可在天赋页强化初始属性。" % amount
		"bomb":
			_apply_small_bomb()

func _open_chest_pickup(pickup: Node2D) -> void:
	var reward_type := _random_chest_reward()
	var pickup_position := pickup.global_position
	if pickup.has_method("play_open_animation"):
		pickup.play_open_animation(reward_type, func() -> void:
			_spawn_particle_burst(pickup_position, "pickup")
			_return_to_pool(pickup, "pickup")
			_apply_pickup(reward_type)
		)
	else:
		_spawn_particle_burst(pickup_position, "pickup")
		_return_to_pool(pickup, "pickup")
		_apply_pickup(reward_type)

func _random_chest_reward() -> String:
	var rewards := ["potion", "slot", "magnet", "haste"]
	return rewards[randi() % rewards.size()]

func _apply_haste_potion() -> void:
	if not haste_active:
		player.speed += haste_speed_bonus
		haste_active = true
	haste_timer = 5.0
	hud.hint.text = "极速药水：5秒内移速暴涨。"

func _update_haste(delta: float) -> void:
	if not haste_active:
		return
	haste_timer = max(0.0, haste_timer - delta)
	if haste_timer <= 0.0:
		player.speed = max(0.0, player.speed - haste_speed_bonus)
		haste_active = false

func _apply_small_bomb() -> void:
	var cleared := 0
	for enemy in enemies.get_children():
		if enemy.archetype == "elite" or enemy.archetype == "boss" or enemy.archetype == "bullet_boss":
			enemy.take_damage(enemy.health * 0.5)
		else:
			_spawn_xp_gem(enemy.global_position, int(enemy.get("xp_reward")))
			enemy.take_damage(enemy.health)
			cleared += 1
	_spawn_particle_burst(player.global_position, "death")
	_add_shake(0.22, 14.0)
	hud.hint.text = "小炸弹：清掉普通怪 %d 只，强敌扣半血。" % cleared

func _apply_weapon_traits(enemy: Node2D, damage_amount: float, source: Node) -> void:
	if source == null or not ("traits" in source):
		return
	var traits: Dictionary = source.traits
	if traits.is_empty():
		return
	if traits.has("lifesteal"):
			if randf() < weapon_manager.lifesteal_chance:
				player.heal(weapon_manager.lifesteal_amount)
	if traits.has("slow") and enemy.has_method("apply_slow"):
		enemy.apply_slow(float(traits["slow"]), 1.35)
	if traits.has("knockback") and enemy.has_method("apply_knockback"):
		var direction: Vector2 = source.global_position.direction_to(enemy.global_position)
		if direction == Vector2.ZERO:
			direction = player.global_position.direction_to(enemy.global_position)
		enemy.apply_knockback(direction, float(traits["knockback"]))

func _start_slot_machine() -> void:
	var bundle: Dictionary = weapon_manager.build_slot_bundle()
	level_up_pending = true
	get_tree().paused = true
	hud.show_slot_machine(bundle.get("reels", []), bundle.get("options", []), bool(bundle.get("jackpot", false)))

func _gain_experience(amount: int) -> void:
	amount = int(round(float(amount) * (1.0 + experience_gain_bonus)))
	experience += amount
	while experience >= experience_to_next:
		experience -= experience_to_next
		level += 1
		experience_to_next = int(float(level * level) * 3.0)
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
	for enemy in _nearby_enemies(player.global_position, player.radius + 180.0):
		if player.global_position.distance_to(enemy.global_position) <= player.radius + enemy.radius:
			player.take_damage(enemy.contact_damage * delta)

func _check_enemy_projectile_hits() -> void:
	for enemy_projectile in enemy_projectiles.get_children():
		if player.global_position.distance_to(enemy_projectile.global_position) <= player.radius + enemy_projectile.radius:
			player.take_damage(enemy_projectile.damage)
			_return_to_pool(enemy_projectile, "enemy_projectile")

func _update_enemy_buffs() -> void:
	var buffers := []
	for enemy in enemies.get_children():
		if enemy.archetype == "buffer" or str(enemy.get("elite_variant")) == "buffer":
			buffers.append(enemy)
	if buffers.is_empty():
		for enemy in enemies.get_children():
			enemy.set_buffed(false)
		return
	var buffed_ids := {}
	for buffer in buffers:
		for enemy in _nearby_enemies(buffer.global_position, 150.0):
			if enemy != buffer and enemy.global_position.distance_to(buffer.global_position) <= 110.0:
				buffed_ids[enemy.get_instance_id()] = true
	for enemy in enemies.get_children():
		enemy.set_buffed(buffed_ids.has(enemy.get_instance_id()))

func _rebuild_enemy_spatial_index() -> void:
	enemy_spatial_buckets.clear()
	for enemy_node in enemies.get_children():
		var enemy := enemy_node as Node2D
		if enemy == null or not is_instance_valid(enemy):
			continue
		if float(enemy.get("health")) <= 0.0:
			continue
		var key := _enemy_spatial_key(enemy.global_position)
		if not enemy_spatial_buckets.has(key):
			enemy_spatial_buckets[key] = []
		var bucket: Array = enemy_spatial_buckets[key]
		bucket.append(enemy)

func _enemy_spatial_key(position: Vector2) -> Vector2i:
	return Vector2i(floori(position.x / enemy_spatial_cell_size), floori(position.y / enemy_spatial_cell_size))

func _nearby_enemies(position: Vector2, radius: float) -> Array:
	var result := []
	var min_key := _enemy_spatial_key(position - Vector2.ONE * radius)
	var max_key := _enemy_spatial_key(position + Vector2.ONE * radius)
	for cell_x in range(min_key.x, max_key.x + 1):
		for cell_y in range(min_key.y, max_key.y + 1):
			var key := Vector2i(cell_x, cell_y)
			if enemy_spatial_buckets.has(key):
				result.append_array(enemy_spatial_buckets[key])
	return result

func _update_hud() -> void:
	hud.set_stats(player.health, player.max_health, score, elapsed, enemies.get_child_count(), level, experience, experience_to_next, current_wave, max_wave, wave_time_left, weapon_manager.get_summary(), weapon_manager.get_passive_summary(), player_damage_multiplier * weapon_manager.current_attack_power(), weapon_manager.crit_chance, weapon_manager.crit_damage_multiplier, weapon_manager.lifesteal_chance, weapon_manager.lifesteal_amount, run_magic_crystals)
	if hud.has_method("set_loadout_icons"):
		hud.set_loadout_icons(weapon_manager.get_weapon_icon_ids(), weapon_manager.get_passive_icon_ids())
	if hud.has_method("set_performance_stats"):
		hud.set_performance_stats(
			Engine.get_frames_per_second(),
			enemies.get_child_count(),
			projectiles.get_child_count(),
			enemy_projectiles.get_child_count(),
			weapon_zones.get_child_count(),
			effects.get_child_count(),
			xp_gems.get_child_count(),
			pickups.get_child_count()
		)

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
		if wave % 10 == 0 and wave < 30:
			alert_text = "弹幕大Boss来袭"
			is_major = true
		elif wave == 10 or wave == 20:
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
	var enemy_projectile: Node2D = _take_from_pool("enemy_projectile", EnemyProjectileScene)
	enemy_projectile.global_position = spawn_position
	enemy_projectile.direction = direction
	enemy_projectile.damage = damage
	enemy_projectile.speed = speed
	enemy_projectile.radius = radius
	enemy_projectile.world_size = player.world_size
	enemy_projectiles.add_child(enemy_projectile)
	if enemy_projectile.has_method("reset_for_pool"):
		enemy_projectile.reset_for_pool()
	if not enemy_projectile.despawn_requested.is_connected(_on_enemy_projectile_despawn_requested):
		enemy_projectile.despawn_requested.connect(_on_enemy_projectile_despawn_requested)

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
	var effects: Array = result.get("effects", [])
	for effect in effects:
		var data: Dictionary = effect
		match data.get("stat", ""):
			"damage":
				pass
			"cooldown":
				xp_magnet_range += 15.0
			"radius":
				xp_magnet_range += 20.0
			"projectile_speed":
				player.speed += 8.0
			"speed_flat":
				player.speed += float(data.get("amount", 0.0))
			"health_flat":
				player.max_health += float(data.get("amount", 0.0))
				player.health = min(player.max_health, player.health + float(data.get("amount", 0.0)))
				player.damaged.emit(player.health)
			"magnet_flat":
				xp_magnet_range += float(data.get("amount", 0.0))
			"invulnerability_flat":
				player.invulnerability_duration += float(data.get("amount", 0.0))

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
						weapon_manager.apply_stat_upgrade("damage", 0.06)
					"minor_damage":
						weapon_manager.apply_stat_upgrade("damage", 0.02)
					"crit_chance":
						weapon_manager.apply_stat_upgrade("crit_chance", 0.01)
					"cooldown":
						weapon_manager.apply_stat_upgrade("cooldown", 0.03)
					"tiny_cooldown":
						weapon_manager.apply_stat_upgrade("cooldown", 0.01)
					"radius":
						weapon_manager.apply_stat_upgrade("radius", 0.04)
					"projectile_speed":
						weapon_manager.apply_stat_upgrade("projectile_speed", 0.05)
					"vitality":
						player.speed += 4.0
						player.max_health += 8.0
						player.health = min(player.max_health, player.health + 8.0)
					"magnet":
						xp_magnet_range += 10.0
					"tiny_magnet":
						xp_magnet_range += 4.0
					"invulnerability":
						player.invulnerability_duration += 0.05
					"heal":
						player.heal_percent(0.18)
					"nothing":
						hud.hint.text = "发暗铜片：你感觉命运笑了一下，但什么都没发生。"

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

func _on_slot_tick_requested() -> void:
	sfx_manager.play_ui("slot_tick")

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
	var enemy: Node2D = _take_from_pool("enemy", EnemyScene)
	enemy.global_position = _random_spawn_position("elite")
	enemy.target = player
	enemies.add_child(enemy)
	enemy.configure("elite", current_wave + 2)
	enemy.scale *= 1.22
	enemy.health *= 1.35
	enemy.max_health *= 1.35
	enemy.xp_reward += 8
	_connect_enemy_pool_signals(enemy)
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

func _spawn_hit_effect(position: Vector2, amount: float, critical := false) -> void:
	var text := "%d" % int(round(amount))
	if hud != null and hud.has_method("show_damage_number"):
		hud.show_damage_number(_world_to_hud_position(position + Vector2(0, -enemy_text_offset())), text, critical)
		return
	_trim_effects(1)
	var number := _take_effect_from_pool()
	number.global_position = position + Vector2(0, -enemy_text_offset())
	number.z_index = 1000
	number.duration = 0.92 if critical else 0.72
	number.label = text
	number.velocity = Vector2(0, -76.0 if critical else -52.0)
	number.color = Color(1.0, 0.16, 0.08, 1.0) if critical else Color(1.0, 0.98, 0.46, 1.0)
	effects.add_child(number)
	if number.has_method("reset_for_pool"):
		number.reset_for_pool()
	if not number.despawn_requested.is_connected(_on_effect_despawn_requested):
		number.despawn_requested.connect(_on_effect_despawn_requested)

func _world_to_hud_position(world_position: Vector2) -> Vector2:
	return get_viewport().get_canvas_transform() * world_position

func _spawn_death_effect(position: Vector2, radius: float, archetype: String) -> void:
	_trim_effects(1)
	var effect := _take_effect_from_pool()
	effect.global_position = position
	effect.duration = 0.46
	effect.radius = max(42.0, radius * 2.4)
	effect.color = Color(1.0, 0.15, 0.10, 0.82)
	effect.effect_kind = "death"
	if archetype == "bomber":
		effect.color = Color(0.72, 1.0, 0.18, 0.86)
		effect.radius *= 1.35
	effects.add_child(effect)
	if effect.has_method("reset_for_pool"):
		effect.reset_for_pool()
	if not effect.despawn_requested.is_connected(_on_effect_despawn_requested):
		effect.despawn_requested.connect(_on_effect_despawn_requested)

func _spawn_particle_burst(position: Vector2, effect_type: String) -> void:
	_trim_effects(1)
	var burst: GPUParticles2D = _take_from_pool("particle_burst", ParticleBurstScene) as GPUParticles2D
	burst.global_position = position
	effects.add_child(burst)
	burst.configure(effect_type)
	if not burst.despawn_requested.is_connected(_on_particle_burst_despawn_requested):
		burst.despawn_requested.connect(_on_particle_burst_despawn_requested)

func _trim_effects(incoming_count := 1) -> void:
	var overflow: int = effects.get_child_count() + incoming_count - max_effect_nodes
	if overflow <= 0:
		return
	for index in range(min(overflow, effects.get_child_count())):
		_return_effect_child(effects.get_child(index))

func enemy_text_offset() -> float:
	return 44.0

func _maybe_apply_enemy_affix(enemy: Node2D, archetype: String) -> void:
	if archetype == "boss" or archetype == "bullet_boss":
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

func _on_main_menu_requested() -> void:
	get_tree().paused = false
	get_tree().change_scene_to_file("res://scenes/bootstrap/Bootstrap.tscn")

func _on_exit_run_requested() -> void:
	var reward := _calculate_early_exit_magic_crystals()
	if reward > 0:
		run_magic_crystals += reward
		if has_node("/root/RuntimeConfig"):
			get_node("/root/RuntimeConfig").add_magic_crystals(reward)
	get_tree().paused = false
	get_tree().change_scene_to_file("res://scenes/bootstrap/Bootstrap.tscn")

func _calculate_early_exit_magic_crystals() -> int:
	var wave_reward: int = max(0, current_wave - 1)
	var time_reward: int = int(floor(elapsed / 60.0))
	var kill_reward: int = int(floor(float(score) / 80.0))
	if elapsed < 8.0 and score <= 0 and current_wave <= 1:
		return 0
	return max(1, wave_reward + time_reward + kill_reward)

func _setup_object_pool() -> void:
	pool_root = Node.new()
	pool_root.name = "ObjectPool"
	add_child(pool_root)
	_prewarm_object_pools(20)

func _prewarm_object_pools(count: int) -> void:
	_prewarm_pool("enemy", EnemyScene, count)
	_prewarm_pool("projectile", ProjectileScene, count)
	_prewarm_pool("enemy_projectile", EnemyProjectileScene, count)
	_prewarm_pool("xp_gem", XPGemScene, count)
	_prewarm_pool("pickup", PickupItemScene, count)
	_prewarm_pool("effect", null, count)
	_prewarm_pool("weapon_zone", WeaponZoneScene, count)
	_prewarm_pool("particle_burst", ParticleBurstScene, count)
	_prewarm_ui_burst_pool(count)

func _prewarm_pool(pool_id: String, scene: PackedScene, count: int) -> void:
	var pool: Array = object_pools.get(pool_id, [])
	while pool.size() < count:
		var node: Node2D
		if scene != null:
			node = scene.instantiate()
		else:
			node = Node2D.new()
			node.set_script(CombatEffectScript)
			node.set_meta("pool_id", "effect")
		node.hide()
		node.process_mode = Node.PROCESS_MODE_DISABLED
		node.set_process(false)
		node.set_physics_process(false)
		pool_root.add_child(node)
		pool.append(node)
	object_pools[pool_id] = pool

func _prewarm_ui_burst_pool(count: int) -> void:
	var pool: Array = object_pools.get("ui_burst", [])
	while pool.size() < count:
		var rect := ColorRect.new()
		rect.color = Color.WHITE
		rect.hide()
		rect.process_mode = Node.PROCESS_MODE_DISABLED
		rect.set_process(false)
		rect.set_physics_process(false)
		pool_root.add_child(rect)
		pool.append(rect)
	object_pools["ui_burst"] = pool

func _take_from_pool(pool_id: String, scene: PackedScene) -> Node2D:
	var pool: Array = object_pools.get(pool_id, [])
	while not pool.is_empty():
		var node: Node2D = pool.pop_back()
		if is_instance_valid(node):
			if node.get_parent() != null:
				node.get_parent().remove_child(node)
			node.process_mode = Node.PROCESS_MODE_INHERIT
			node.show()
			node.set_process(true)
			node.set_physics_process(true)
			object_pools[pool_id] = pool
			return node
	object_pools[pool_id] = pool
	if scene == null:
		return Node2D.new()
	return scene.instantiate()

func _return_to_pool(node: Node, pool_id: String) -> void:
	if node == null or not is_instance_valid(node):
		return
	if node.get_parent() == pool_root:
		return
	var pool: Array = object_pools.get(pool_id, [])
	if node.get_parent() != null:
		node.get_parent().remove_child(node)
	if pool_id == "enemy" and node.has_method("set_batched_visual_enabled"):
		node.set_batched_visual_enabled(false)
	if pool.size() >= int(pool_limits.get(pool_id, 32)):
		node.queue_free()
		return
	node.hide()
	node.process_mode = Node.PROCESS_MODE_DISABLED
	node.set_process(false)
	node.set_physics_process(false)
	pool_root.add_child(node)
	pool.append(node)
	object_pools[pool_id] = pool

func _take_projectile_from_pool() -> Node2D:
	return _take_from_pool("projectile", ProjectileScene)

func _take_weapon_zone_from_pool() -> Node2D:
	return _take_from_pool("weapon_zone", WeaponZoneScene)

func _take_effect_from_pool() -> Node2D:
	var effect := _take_from_pool("effect", null)
	if effect.get_script() == null:
		effect.set_script(CombatEffectScript)
	effect.set_meta("pool_id", "effect")
	return effect

func _take_ui_burst_from_pool() -> ColorRect:
	var pool: Array = object_pools.get("ui_burst", [])
	while not pool.is_empty():
		var node: Node = pool.pop_back()
		if is_instance_valid(node):
			if node.get_parent() != null:
				node.get_parent().remove_child(node)
			node.process_mode = Node.PROCESS_MODE_INHERIT
			node.show()
			node.set_process(true)
			node.set_physics_process(true)
			object_pools["ui_burst"] = pool
			var rect := node as ColorRect
			rect.modulate = Color.WHITE
			rect.rotation = 0.0
			return rect
	object_pools["ui_burst"] = pool
	var replacement := ColorRect.new()
	replacement.color = Color.WHITE
	return replacement

func _connect_enemy_pool_signals(enemy: Node2D) -> void:
	if not enemy.despawn_requested.is_connected(_on_enemy_despawn_requested):
		enemy.despawn_requested.connect(_on_enemy_despawn_requested)
	if not enemy.projectile_requested.is_connected(_on_enemy_projectile_requested):
		enemy.projectile_requested.connect(_on_enemy_projectile_requested)
	if not enemy.summon_requested.is_connected(_on_enemy_summon_requested):
		enemy.summon_requested.connect(_on_enemy_summon_requested)

func _on_enemy_despawn_requested(enemy: Node2D) -> void:
	call_deferred("_return_to_pool", enemy, "enemy")

func _on_projectile_despawn_requested(projectile: Node2D) -> void:
	_return_to_pool(projectile, "projectile")

func _on_enemy_projectile_despawn_requested(projectile: Node2D) -> void:
	_return_to_pool(projectile, "enemy_projectile")

func _on_xp_gem_despawn_requested(gem: Node2D) -> void:
	_return_to_pool(gem, "xp_gem")

func _on_pickup_despawn_requested(pickup: Node2D) -> void:
	_return_to_pool(pickup, "pickup")

func _on_effect_despawn_requested(effect: Node2D) -> void:
	_return_to_pool(effect, "effect")

func _on_weapon_zone_despawn_requested(zone: Node2D) -> void:
	_return_to_pool(zone, "weapon_zone")

func _on_particle_burst_despawn_requested(burst: GPUParticles2D) -> void:
	_return_to_pool(burst, "particle_burst")

func _return_effect_child(node: Node) -> void:
	if node is GPUParticles2D:
		_return_to_pool(node, "particle_burst")
	elif node.has_signal("despawn_requested"):
		_return_to_pool(node, str(node.get_meta("pool_id", "effect")))
	else:
		node.queue_free()
