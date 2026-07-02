extends CharacterBody2D

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

var health: float = max_health
var target: Node2D
var fire_timer := 1.6
var special_timer := 5.0
var wave_power := 1.0
var buff_multiplier := 1.0
var projectile_damage_multiplier := 1.0
var elite_affix := ""
var body_scale_value := 1.0
var glow_scale_value := 1.0
@onready var glow_sprite: Sprite2D = $Glow
@onready var animated_body: AnimatedSprite2D = $AnimatedBody
@onready var body_sprite: Sprite2D = $Body
@onready var mark_sprite: Sprite2D = $Mark
@onready var eyes_sprite: Sprite2D = $Eyes

func configure(new_archetype: String, wave: int) -> void:
	archetype = new_archetype
	wave_power = 1.0 + float(max(0, wave - 1)) * 0.18 + float(max(0, wave - 1) * max(0, wave - 1)) * 0.0045
	match archetype:
		"shooter":
			speed = 82.0
			max_health = 28.0 * wave_power
			radius = 15.0
			contact_damage = 12.0 * wave_power
			xp_reward = 8 + wave / 3
			fire_timer = 1.1
		"buffer":
			speed = 68.0
			max_health = 42.0 * wave_power
			radius = 18.0
			contact_damage = 10.0 * wave_power
			xp_reward = 11 + wave / 2
		"elite":
			speed = 92.0
			max_health = 170.0 * wave_power
			radius = 28.0
			contact_damage = 30.0 * wave_power
			xp_reward = 34 + wave
		"charger":
			speed = 155.0 + wave * 2.2
			max_health = 32.0 * wave_power
			radius = 14.0
			contact_damage = 24.0 * wave_power
			xp_reward = 9 + wave / 3
		"tank":
			speed = 54.0
			max_health = 240.0 * wave_power
			radius = 34.0
			contact_damage = 34.0 * wave_power
			xp_reward = 26 + wave
		"splitter":
			speed = 104.0
			max_health = 54.0 * wave_power
			radius = 19.0
			contact_damage = 17.0 * wave_power
			xp_reward = 15 + wave / 2
		"bomber":
			speed = 126.0
			max_health = 38.0 * wave_power
			radius = 17.0
			contact_damage = 45.0 * wave_power
			xp_reward = 14 + wave / 2
		"boss":
			speed = 76.0
			max_health = 2800.0 + max(0, wave - 1) * 180.0
			radius = 56.0
			contact_damage = 46.0 + max(0, wave - 1) * 2.5
			xp_reward = 280 + wave * 14
			fire_timer = max(0.58, 0.9 - wave * 0.012)
			special_timer = max(1.8, 3.2 - wave * 0.04)
		_:
			speed = 115.0 + wave * 2.0
			max_health = 24.0 * wave_power
			radius = 16.0
			contact_damage = 18.0 * wave_power
			xp_reward = 6 + wave / 4
	health = max_health
	_update_visuals()

func set_buffed(is_buffed: bool) -> void:
	var new_multiplier := 1.25 if is_buffed else 1.0
	if not is_equal_approx(buff_multiplier, new_multiplier):
		buff_multiplier = new_multiplier
		_update_buff_visual()

func _physics_process(delta: float) -> void:
	if target == null:
		return

	fire_timer -= delta
	special_timer -= delta

	match archetype:
		"shooter":
			_process_shooter(delta)
		"buffer":
			_process_chaser(0.72)
		"elite":
			_process_chaser(0.88)
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
		_:
			_process_chaser(1.0)

	move_and_slide()
	if absf(velocity.x) > 0.01:
		animated_body.flip_h = velocity.x < 0.0

func _process_chaser(speed_scale: float) -> void:
	velocity = global_position.direction_to(target.global_position) * speed * speed_scale * buff_multiplier

func _process_shooter(_delta: float) -> void:
	var distance := global_position.distance_to(target.global_position)
	var direction := global_position.direction_to(target.global_position)
	if distance < 230.0:
		velocity = -direction * speed * buff_multiplier
	elif distance > 310.0:
		velocity = direction * speed * buff_multiplier
	else:
		velocity = velocity.move_toward(Vector2.ZERO, 18.0)

	if fire_timer <= 0.0:
		fire_timer = max(0.42, 1.35 - wave_power * 0.05)
		projectile_requested.emit(global_position, direction, 10.0 * wave_power * projectile_damage_multiplier, 260.0 + wave_power * 20.0, 7.0)

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
	if special_timer <= 0.0:
		special_timer = 4.2
		velocity = direction * speed * 4.0
		for index in range(3):
			var offset := Vector2(randf_range(-90.0, 90.0), randf_range(-90.0, 90.0))
			summon_requested.emit("chaser", global_position + offset)

func take_damage(amount: float) -> void:
	health -= amount
	if health <= 0.0:
		queue_free()
	else:
		_play_hit_flash()

func _update_visuals() -> void:
	glow_sprite.texture = TextureFactory.enemy_glow(archetype)
	var style := DuelystTheme.enemy_style(archetype)
	if style.get("frames") != null:
		animated_body.visible = true
		animated_body.sprite_frames = style.get("frames")
		animated_body.scale = Vector2.ONE * float(style.get("scale", 0.44))
		animated_body.position = style.get("offset", Vector2.ZERO)
		animated_body.speed_scale = float(style.get("speed", 10.0)) / 10.0
		DuelystTheme.play_best_animation(animated_body)
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
	if archetype == "boss":
		glow_scale_value = (radius + 28.0) / 64.0
	elif archetype == "buffer":
		glow_scale_value = (radius + 22.0) / 64.0
	body_sprite.scale = Vector2.ONE * body_scale_value
	mark_sprite.scale = Vector2.ONE * body_scale_value
	eyes_sprite.scale = Vector2.ONE * body_scale_value
	_update_buff_visual()
	_play_spawn_pop()

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
	var to_scale := animated_body.scale
	var from_scale := to_scale * 0.88
	animated_body.scale = from_scale
	var tween := DOTween.sequence(self, "enemy_spawn_pop")
	tween.tween_property(animated_body, "scale", to_scale, 0.18).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)

func _play_hit_flash() -> void:
	DOTween.kill(self, "enemy_hit_flash")
	animated_body.modulate = Color(1.0, 0.62, 0.45, 1.0)
	var tween := DOTween.sequence(self, "enemy_hit_flash")
	tween.tween_property(animated_body, "modulate", Color.WHITE, 0.20).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
