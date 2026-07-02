extends CharacterBody2D

signal despawn_requested(enemy: Node2D)
signal projectile_requested(spawn_position: Vector2, direction: Vector2, damage: float, speed: float, radius: float)
signal summon_requested(archetype: String, spawn_position: Vector2)

const DOTween := preload("res://scripts/utils/dotween.gd")
const TextureFactory := preload("res://scripts/visuals/texture_factory.gd")
const DuelystTheme := preload("res://scripts/visuals/duelyst_theme.gd")

@export var speed := 115.0
@export var max_health := 24.0
@export var radius := 16.0
@export var contact_damage := 18.0
@export var xp_reward := 6
@export var archetype := "chaser"
@export var collision_scale_multiplier := 1.5
@export var world_size := Vector2(15600, 10800)

var health: float = max_health
var target: Node2D
var fire_timer := 1.6
var special_timer := 5.0
var wave_power := 1.0
var buff_multiplier := 1.0
var projectile_damage_multiplier := 1.0
var elite_affix := ""
var elite_variant := ""
var boss_variant := ""
var body_scale_value := 1.0
var glow_scale_value := 1.0
var elite_scale_multiplier := 1.0
var animation_state := ""
var action_animation_timer := 0.0
var projectile_burst_count := 0
var slow_multiplier := 1.0
var slow_timer := 0.0
var knockback_velocity := Vector2.ZERO
var batched_visual_enabled := false
var hit_flash_timer := 0.0
var _cached_ahead := 0
var _ahead_timer := 0
@onready var glow_sprite: Sprite2D = $Glow
@onready var animated_body: AnimatedSprite2D = $AnimatedBody
@onready var body_sprite: Sprite2D = $Body
@onready var mark_sprite: Sprite2D = $Mark
@onready var eyes_sprite: Sprite2D = $Eyes

func configure(new_archetype: String, wave: int) -> void:
	archetype = new_archetype
	scale = Vector2.ONE
	velocity = Vector2.ZERO
	buff_multiplier = 1.0
	projectile_damage_multiplier = 1.0
	projectile_burst_count = 0
	elite_affix = ""
	elite_variant = ""
	boss_variant = ""
	slow_multiplier = 1.0
	slow_timer = 0.0
	knockback_velocity = Vector2.ZERO
	hit_flash_timer = 0.0
	batched_visual_enabled = false
	elite_scale_multiplier = 2.0 if archetype == "elite" else 1.0
	fire_timer = 1.6
	special_timer = 5.0
	wave_power = 1.0 + float(max(0, wave - 1)) * 0.24 + float(max(0, wave - 1) * max(0, wave - 1)) * 0.006
	var w := float(max(0, wave - 1))
	var health_power := 1.0 + w * 0.25 + w * w * 0.01
	match archetype:
		"shooter":
			speed = 82.0
			max_health = 80.0 * health_power
			radius = 15.0
			contact_damage = 12.0 * wave_power
			fire_timer = 1.1
		"buffer":
			speed = 68.0
			max_health = 120.0 * health_power
			radius = 18.0
			contact_damage = 10.0 * wave_power
		"elite":
			speed = 92.0
			max_health = 8000.0 * health_power
			radius = 28.0
			contact_damage = 30.0 * wave_power
		"charger":
			speed = 155.0 + wave * 2.2
			max_health = 90.0 * health_power
			radius = 14.0
			contact_damage = 24.0 * wave_power
		"tank":
			speed = 54.0
			max_health = 500.0 * health_power
			radius = 34.0
			contact_damage = 34.0 * wave_power
		"splitter":
			speed = 104.0
			max_health = 130.0 * health_power
			radius = 19.0
			contact_damage = 17.0 * wave_power
		"bomber":
			speed = 126.0
			max_health = 110.0 * health_power
			radius = 17.0
			contact_damage = 45.0 * wave_power
		"boss":
			speed = 76.0
			max_health = 60000.0 * health_power
			radius = 56.0
			contact_damage = 46.0 + max(0, wave - 1) * 2.5
			fire_timer = max(0.58, 0.9 - wave * 0.012)
			special_timer = max(1.8, 3.2 - wave * 0.04)
		"bullet_boss":
			speed = 64.0
			max_health = 80000.0 * health_power
			radius = 62.0
			contact_damage = 42.0 * wave_power
			fire_timer = 0.34
			special_timer = 1.65
			projectile_burst_count = 24
			boss_variant = _boss_variant_for_wave(wave)
		_:
			speed = 115.0 + wave * 2.0
			max_health = 100.0 * health_power
			radius = 16.0
			contact_damage = 18.0 * wave_power
	var base_xp := 1
	match archetype:
		"shooter": xp_reward = base_xp * 2
		"buffer": xp_reward = base_xp * 3
		"elite": xp_reward = base_xp * 15
		"charger": xp_reward = base_xp * 2
		"tank": xp_reward = base_xp * 5
		"splitter": xp_reward = base_xp * 3
		"bomber": xp_reward = base_xp * 3
		"boss": xp_reward = base_xp * 50
		"bullet_boss": xp_reward = base_xp * 40
		_: xp_reward = base_xp
	radius *= collision_scale_multiplier * elite_scale_multiplier
	health = max_health
	if archetype == "elite":
		_configure_elite_variant()
	_update_visuals()

func set_buffed(is_buffed: bool) -> void:
	var new_multiplier := 1.25 if is_buffed else 1.0
	if not is_equal_approx(buff_multiplier, new_multiplier):
		buff_multiplier = new_multiplier
		_update_buff_visual()

func _physics_process(delta: float) -> void:
	if target == null:
		return

	# Batched enemies: lightweight movement only, skip all AI
	if batched_visual_enabled:
		_ahead_timer += 1
		if _ahead_timer >= 12:
			_ahead_timer = 0
			_cached_ahead = 0
			var my_dist_sq := global_position.distance_squared_to(target.global_position)
			var game_node := get_tree().current_scene
			if game_node != null and game_node.has_method("_nearby_enemies"):
				for other in game_node._nearby_enemies(global_position, 400.0):
					if other == self or not is_instance_valid(other):
						continue
					if other.global_position.distance_squared_to(target.global_position) < my_dist_sq:
						_cached_ahead += 1
					if _cached_ahead > 60:
						break
		var ahead_factor := clampf(float(_cached_ahead) / 30.0, 0.0, 1.0)
		var speed_mult := lerpf(1.0, 0.12, ahead_factor)
		velocity = global_position.direction_to(target.global_position) * speed * speed_mult
		velocity = velocity * slow_multiplier + knockback_velocity
		knockback_velocity = knockback_velocity.move_toward(Vector2.ZERO, 620.0 * delta)
		move_and_slide()
		return

	var dist_to_player := global_position.distance_squared_to(target.global_position)
	var cull_dist_sq := 2500000.0  # ~1581px squared
	if dist_to_player > cull_dist_sq:
		velocity = global_position.direction_to(target.global_position) * speed
		velocity = velocity * slow_multiplier + knockback_velocity
		knockback_velocity = knockback_velocity.move_toward(Vector2.ZERO, 620.0 * delta)
		move_and_slide()
		return

	action_animation_timer = max(0.0, action_animation_timer - delta)
	hit_flash_timer = max(0.0, hit_flash_timer - delta)
	if slow_timer > 0.0:
		slow_timer = max(0.0, slow_timer - delta)
		if slow_timer <= 0.0:
			slow_multiplier = 1.0
			modulate = Color.WHITE
	fire_timer -= delta
	special_timer -= delta

	match archetype:
		"shooter":
			_process_shooter(delta)
		"buffer":
			_process_chaser(0.72)
		"elite":
			_process_elite(delta)
		"charger":
			_process_charger(delta)
		"tank":
			_process_chaser(0.55)
		"splitter":
			_process_chaser(0.92)
		"bomber":
			_process_chaser(1.25)
		"boss":
			_process_boss(delta)
		"bullet_boss":
			_process_bullet_boss(delta)
		_:
			_process_chaser(1.0)

	velocity = velocity * slow_multiplier + knockback_velocity
	knockback_velocity = knockback_velocity.move_toward(Vector2.ZERO, 620.0 * delta)
	_separate_from_enemies()
	move_and_slide()
	var clamped_position := global_position.clamp(Vector2(radius, radius), world_size - Vector2(radius, radius))
	if clamped_position != global_position:
		global_position = clamped_position
		knockback_velocity = Vector2.ZERO
	if absf(velocity.x) > 0.01:
		animated_body.flip_h = velocity.x < 0.0
	_update_animation_state()

func is_gpu_batch_candidate() -> bool:
	return archetype != "elite" and archetype != "boss" and archetype != "bullet_boss"

func set_batched_visual_enabled(enabled: bool) -> void:
	if batched_visual_enabled == enabled:
		return
	batched_visual_enabled = enabled
	_apply_batched_visual_visibility()

func gpu_hit_flash() -> float:
	return clampf(hit_flash_timer / 0.16, 0.0, 1.0)

func _apply_batched_visual_visibility() -> void:
	if animated_body == null:
		return
	var show_local := not batched_visual_enabled
	glow_sprite.visible = show_local
	animated_body.visible = show_local and animated_body.sprite_frames != null
	body_sprite.visible = show_local and body_sprite.texture != null and animated_body.sprite_frames == null
	mark_sprite.visible = body_sprite.visible
	eyes_sprite.visible = body_sprite.visible
	if batched_visual_enabled:
		animated_body.stop()
	elif animated_body.sprite_frames != null and not animated_body.is_playing():
		_set_animation_state("idle", true)

func _separate_from_enemies() -> void:
	# Global frame counter: all enemies separate on same frames
	if Engine.get_physics_frames() % 3 != 0:
		return
	var sep_radius := radius * 5.0
	var game_node := get_tree().current_scene
	if game_node == null or not game_node.has_method("_nearby_enemies"):
		return
	var checked := 0
	for other in game_node._nearby_enemies(global_position, sep_radius + 60.0):
		if other == self or not is_instance_valid(other):
			continue
		checked += 1
		if checked > 16:
			break
		var dist := global_position.distance_to(other.global_position)
		if dist < sep_radius and dist > 0.01:
			var push_dir := global_position.direction_to(other.global_position)
			var force := (sep_radius - dist) / sep_radius * 240.0
			velocity -= push_dir * force

func _process_chaser(speed_scale: float) -> void:
	velocity = global_position.direction_to(target.global_position) * speed * speed_scale * buff_multiplier

func _process_elite(delta: float) -> void:
	match elite_variant:
		"charger":
			_process_charger(delta)
		"summoner":
			_process_chaser(0.78)
			if special_timer <= 0.0:
				special_timer = 3.2
				for index in range(3):
					var offset := Vector2.RIGHT.rotated(TAU * float(index) / 3.0 + randf() * 0.4) * 76.0
					summon_requested.emit("chaser", global_position + offset)
				_play_action_animation("cast", 0.26)
		"suppressor":
			_process_chaser(0.68)
			if fire_timer <= 0.0:
				fire_timer = 1.25
				var direction := global_position.direction_to(target.global_position)
				for index in range(5):
					projectile_requested.emit(global_position, direction.rotated((float(index) - 2.0) * 0.18), 14.0 * wave_power * projectile_damage_multiplier, 260.0, 8.0)
				_play_action_animation("attack", 0.22)
		"mirror":
			_process_chaser(0.92)
			if special_timer <= 0.0:
				special_timer = 4.8
				for index in range(2):
					summon_requested.emit("splitter", global_position + Vector2.RIGHT.rotated(randf() * TAU) * 92.0)
				_play_action_animation("cast", 0.24)
		_:
			_process_chaser(0.92 if elite_variant == "swift" else 0.84)

func _process_shooter(_delta: float) -> void:
	var direction := global_position.direction_to(target.global_position)
	var distance := global_position.distance_to(target.global_position)
	if distance < 230.0:
		velocity = -direction * speed * buff_multiplier
	elif distance > 310.0:
		velocity = direction * speed * buff_multiplier
	else:
		velocity = velocity.move_toward(Vector2.ZERO, 18.0)

	if fire_timer <= 0.0:
		fire_timer = max(0.42, 1.35 - wave_power * 0.05)
		projectile_requested.emit(global_position, direction, 10.0 * wave_power * projectile_damage_multiplier, 260.0 + wave_power * 20.0, 7.0)
		_play_action_animation("attack", 0.24)

func _process_charger(delta: float) -> void:
	var direction := global_position.direction_to(target.global_position)
	special_timer -= delta
	var charge_scale := 2.55 if special_timer <= 0.9 else 0.72
	if special_timer <= 0.0:
		special_timer = 2.4
	velocity = direction * speed * charge_scale * buff_multiplier

func _process_boss(_delta: float) -> void:
	var direction := global_position.direction_to(target.global_position)
	velocity = direction * speed
	if fire_timer <= 0.0:
		fire_timer = 0.75
		for index in range(8):
			var angle := TAU * float(index) / 8.0
			projectile_requested.emit(global_position, Vector2.RIGHT.rotated(angle), 16.0 * projectile_damage_multiplier, 220.0, 9.0)
		_play_action_animation("attack", 0.24)
	if special_timer <= 0.0:
		special_timer = 4.2
		velocity = direction * speed * 4.0
		for index in range(3):
			var offset := Vector2(randf_range(-90.0, 90.0), randf_range(-90.0, 90.0))
			summon_requested.emit("chaser", global_position + offset)

func _process_bullet_boss(_delta: float) -> void:
	var direction := global_position.direction_to(target.global_position)
	var orbit := Vector2.RIGHT.rotated(Time.get_ticks_msec() * 0.0016)
	var pressure := 1.0
	match boss_variant:
		"rift_summoner":
			pressure = 0.72
		"rammer":
			pressure = 1.75 if special_timer <= 0.8 else 0.82
		"cage":
			pressure = 0.58
	velocity = (direction * 0.62 + orbit * 0.38).normalized() * speed * pressure
	if fire_timer <= 0.0:
		fire_timer = 1.18 if boss_variant == "rammer" else 0.92
		var base_angle := global_position.angle_to_point(target.global_position)
		var shot_count := projectile_burst_count
		if boss_variant == "cage":
			shot_count = 14
		for index in range(shot_count):
			var angle := base_angle + TAU * float(index) / float(projectile_burst_count)
			projectile_requested.emit(global_position, Vector2.RIGHT.rotated(angle), 13.0 * projectile_damage_multiplier, 245.0, 8.0)
		_play_action_animation("attack", 0.26)
	if special_timer <= 0.0:
		special_timer = 2.4
		match boss_variant:
			"rift_summoner":
				for index in range(5):
					var offset := Vector2.RIGHT.rotated(TAU * float(index) / 5.0) * 110.0
					summon_requested.emit("charger" if index % 2 == 0 else "shooter", global_position + offset)
				special_timer = 4.2
			"rammer":
				for index in range(8):
					var angle := direction.angle() + (float(index) - 3.5) * 0.16
					projectile_requested.emit(global_position, Vector2.RIGHT.rotated(angle), 18.0 * projectile_damage_multiplier, 360.0, 10.0)
				special_timer = 1.8
			"cage":
				for index in range(24):
					var angle := TAU * float(index) / 24.0
					projectile_requested.emit(target.global_position + Vector2.RIGHT.rotated(angle) * 220.0, -Vector2.RIGHT.rotated(angle), 12.0 * projectile_damage_multiplier, 170.0, 7.0)
				special_timer = 3.1
			_:
				var spiral_offset := Time.get_ticks_msec() * 0.0018
				for ring in range(2):
					for index in range(18):
						var angle := spiral_offset + float(ring) * 0.10 + TAU * float(index) / 18.0
						projectile_requested.emit(global_position, Vector2.RIGHT.rotated(angle), 10.0 * projectile_damage_multiplier, 185.0 + ring * 55.0, 6.0)
		_play_action_animation("cast", 0.34)

func _boss_variant_for_wave(wave: int) -> String:
	match int(wave / 10):
		1:
			return "bullet_ring"
		2:
			return "rift_summoner"
		3:
			return "rammer"
		4:
			return "cage"
	return "bullet_ring"

func take_damage(amount: float) -> void:
	health -= amount
	if health <= 0.0:
		_set_animation_state("death", true)
		despawn_requested.emit(self)
	else:
		_play_hit_flash()

func apply_slow(multiplier: float, duration: float) -> void:
	slow_multiplier = min(slow_multiplier, clampf(multiplier, 0.35, 1.0))
	slow_timer = max(slow_timer, duration)
	modulate = Color(0.62, 0.86, 1.0, 1.0)

func apply_knockback(direction: Vector2, force: float) -> void:
	if direction == Vector2.ZERO:
		return
	knockback_velocity += direction.normalized() * force

func _configure_elite_variant() -> void:
	var variants := ["swift", "buffer", "charger", "warded", "summoner", "suppressor", "mirror"]
	elite_variant = variants[randi() % variants.size()]
	match elite_variant:
		"swift":
			speed *= 1.80
			contact_damage *= 1.15
		"buffer":
			projectile_damage_multiplier = 1.65
			contact_damage *= 1.25
		"charger":
			speed *= 1.45
			contact_damage *= 1.75
			special_timer = 1.2
		"warded":
			max_health *= 2.25
			health = max_health
		"summoner":
			max_health *= 1.35
			health = max_health
			special_timer = 1.0
		"suppressor":
			speed *= 0.86
			contact_damage *= 1.55
			projectile_damage_multiplier = 1.45
		"mirror":
			speed *= 1.18
			max_health *= 1.65
			health = max_health

func _update_visuals() -> void:
	glow_sprite.texture = TextureFactory.enemy_glow(archetype)
	var style := DuelystTheme.enemy_style(archetype)
	if style.get("frames") != null:
		animated_body.visible = true
		animated_body.sprite_frames = style.get("frames")
		animated_body.scale = Vector2.ONE * float(style.get("scale", 0.44))
		animated_body.position = style.get("offset", Vector2.ZERO)
		animated_body.speed_scale = float(style.get("speed", 10.0)) / 10.0
		_set_animation_state("idle", true)
		body_sprite.visible = false
		mark_sprite.visible = false
		eyes_sprite.visible = false
	else:
		animated_body.visible = false
		animated_body.position = Vector2.ZERO
		body_sprite.texture = TextureFactory.enemy_body(archetype)
		mark_sprite.texture = TextureFactory.enemy_mark(archetype)
		eyes_sprite.texture = TextureFactory.enemy_eye()
		body_sprite.visible = true
		mark_sprite.visible = true
		eyes_sprite.visible = true
	body_scale_value = radius / 38.0
	glow_scale_value = (radius + 14.0) / 64.0
	if archetype == "boss" or archetype == "bullet_boss":
		glow_scale_value = (radius + 28.0) / 64.0
	if archetype == "elite":
		match elite_variant:
			"swift":
				animated_body.modulate = Color(1.0, 0.92, 0.42, 1.0)
				glow_sprite.modulate = Color(1.0, 0.92, 0.24, 0.62)
			"buffer":
				animated_body.modulate = Color(0.76, 0.48, 1.0, 1.0)
				glow_sprite.modulate = Color(0.78, 0.38, 1.0, 0.62)
			"charger":
				animated_body.modulate = Color(1.0, 0.36, 0.24, 1.0)
				glow_sprite.modulate = Color(1.0, 0.24, 0.18, 0.62)
			"warded":
				animated_body.modulate = Color(0.50, 1.0, 0.86, 1.0)
				glow_sprite.modulate = Color(0.38, 1.0, 0.80, 0.62)
			"summoner":
				animated_body.modulate = Color(0.92, 0.52, 1.0, 1.0)
				glow_sprite.modulate = Color(0.92, 0.28, 1.0, 0.72)
			"suppressor":
				animated_body.modulate = Color(0.42, 0.74, 1.0, 1.0)
				glow_sprite.modulate = Color(0.24, 0.62, 1.0, 0.72)
			"mirror":
				animated_body.modulate = Color(1.0, 0.58, 0.88, 1.0)
				glow_sprite.modulate = Color(1.0, 0.32, 0.72, 0.72)
	elif archetype == "buffer":
		glow_scale_value = (radius + 22.0) / 64.0
	body_sprite.scale = Vector2.ONE * body_scale_value
	mark_sprite.scale = Vector2.ONE * body_scale_value
	eyes_sprite.scale = Vector2.ONE * body_scale_value
	_update_buff_visual()
	_play_spawn_pop()
	_apply_batched_visual_visibility()

func apply_affix(affix_id: String) -> void:
	elite_affix = affix_id
	match affix_id:
		"swift":
			speed *= 1.35
		"warded":
			max_health *= 1.45
			health = max_health
			radius += 2.0
		"furious":
			contact_damage *= 1.45
			projectile_damage_multiplier = 1.35
		"splinter":
			max_health *= 1.18
			health = max_health
	_update_visuals()

func _update_buff_visual() -> void:
	var buffed := buff_multiplier > 1.0
	DOTween.kill(self, "enemy_buff_scale")
	glow_sprite.scale = Vector2.ONE * glow_scale_value
	mark_sprite.modulate = Color(1.0, 1.0, 1.0, 1.0)
	match elite_affix:
		"swift":
			glow_sprite.modulate = Color(0.58, 1.0, 0.94, 1.0)
		"warded":
			glow_sprite.modulate = Color(0.58, 0.78, 1.0, 1.0)
		"furious":
			glow_sprite.modulate = Color(1.0, 0.58, 0.46, 1.0)
		"splinter":
			glow_sprite.modulate = Color(0.98, 0.52, 1.0, 1.0)
		_:
			glow_sprite.modulate = Color.WHITE
	if buffed:
		animated_body.modulate = Color(1.0, 1.0, 1.0, 1.0)
		DOTween.oscillate_property(self, glow_sprite, "scale", Vector2.ONE * glow_scale_value, Vector2.ONE * (glow_scale_value * 1.08), 0.32, "enemy_buff_scale")

func _play_spawn_pop() -> void:
	if batched_visual_enabled:
		return
	var to_scale := animated_body.scale
	var from_scale := to_scale * 0.88
	animated_body.scale = from_scale
	var tween := DOTween.sequence(self, "enemy_spawn_pop")
	tween.tween_property(animated_body, "scale", to_scale, 0.18).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)

func _play_hit_flash() -> void:
	hit_flash_timer = 0.16
	if batched_visual_enabled:
		return
	_play_action_animation("hit", 0.16)
	DOTween.kill(self, "enemy_hit_flash")
	animated_body.modulate = Color(1.0, 0.62, 0.45, 1.0)
	var tween := DOTween.sequence(self, "enemy_hit_flash")
	tween.tween_property(animated_body, "modulate", Color.WHITE, 0.20).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)

func _play_action_animation(new_state: String, duration: float) -> void:
	action_animation_timer = max(action_animation_timer, duration)
	_set_animation_state(new_state, true)

func _update_animation_state() -> void:
	if batched_visual_enabled:
		return
	if animated_body.sprite_frames == null:
		return
	if health <= 0.0:
		_set_animation_state("death")
		return
	if action_animation_timer > 0.0:
		return
	if velocity.length() > 8.0:
		_set_animation_state("run")
	else:
		_set_animation_state("idle")

func _set_animation_state(new_state: String, restart := false) -> void:
	if animated_body.sprite_frames == null:
		return
	animation_state = new_state
	var preferred: Array[String] = []
	match new_state:
		"run":
			preferred = ["run", "idle", "breathing"]
		"idle":
			preferred = ["idle", "breathing", "run"]
		"hit":
			preferred = ["hit", "idle", "breathing"]
		"death":
			preferred = ["death", "hit", "idle"]
		"attack":
			preferred = ["attack", "cast", "idle"]
		"cast":
			preferred = ["cast", "attack", "idle"]
		_:
			preferred = ["idle", "breathing", "run", "attack"]
	DuelystTheme.play_animation(animated_body, preferred, restart)
