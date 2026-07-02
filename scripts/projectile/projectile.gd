extends Node2D

signal despawn_requested(projectile: Node2D)

const DOTween := preload("res://scripts/utils/dotween.gd")
const TextureFactory := preload("res://scripts/visuals/texture_factory.gd")
const DuelystTheme := preload("res://scripts/visuals/duelyst_theme.gd")

@export var speed := 620.0
@export var damage := 12.0
@export var radius := 6.0
@export var pierce := 0
@export var weapon_id := "blood_bolt"
@export var world_size := Vector2(3600, 2400)
@export var lifetime := 4.0

var direction := Vector2.RIGHT
var hit_count := 0
var traits := {}
var ricochet_count := 0
var ricochet_range := 200.0
var explosion_radius := 0.0
var explosion_damage := 0.0
@onready var sprite: Sprite2D = $Sprite
@onready var animated_sprite: AnimatedSprite2D = $AnimatedSprite

func _ready() -> void:
	reset_for_pool()

func _physics_process(delta: float) -> void:
	lifetime -= delta
	global_position += direction.normalized() * speed * delta
	if lifetime <= 0.0 or not Rect2(Vector2.ZERO, world_size).grow(180.0).has_point(global_position):
		despawn_requested.emit(self)
		return
	rotation = direction.angle()

func reset_for_pool() -> void:
	DOTween.kill(self, "projectile_spawn")
	DOTween.kill(self, "projectile_breathe")
	DOTween.kill(self, "ricochet_flash")
	lifetime = 4.0
	hit_count = 0
	for key in get_meta_list():
		if str(key).begins_with("hit_"):
			remove_meta(key)
	_update_visual()
	_setup_visual_tween()

func _update_visual() -> void:
	if sprite == null or animated_sprite == null:
		return
	var style := DuelystTheme.projectile_style(weapon_id)
	var frames: SpriteFrames = style.get("frames", null)
	if frames == null:
		frames = style.get("fallback", null)
	if frames != null:
		sprite.visible = false
		sprite.modulate = Color.WHITE
		sprite.rotation = 0.0
		animated_sprite.visible = true
		animated_sprite.sprite_frames = frames
		animated_sprite.modulate = Color.WHITE
		animated_sprite.rotation = 0.0
		animated_sprite.scale = Vector2.ONE * float(style.get("scale", 0.34)) * (radius / 7.0)
		animated_sprite.position = style.get("offset", Vector2.ZERO)
		animated_sprite.speed_scale = float(style.get("speed", 18.0)) / 10.0
		DuelystTheme.play_best_animation(animated_sprite, true)
		animated_sprite.frame = 0
		animated_sprite.frame_progress = 0.0
		return
	animated_sprite.visible = false
	animated_sprite.modulate = Color.WHITE
	animated_sprite.rotation = 0.0
	animated_sprite.position = Vector2.ZERO
	sprite.visible = true
	sprite.modulate = Color.WHITE
	sprite.rotation = 0.0
	sprite.texture = TextureFactory.projectile(weapon_id)
	sprite.scale = Vector2.ONE * (radius / 11.0)

func try_ricochet(enemies_node: Node2D) -> bool:
	if ricochet_count <= 0:
		return false
	var nearest: Node2D = null
	var nearest_dist := ricochet_range
	for enemy in enemies_node.get_children():
		if not is_instance_valid(enemy) or float(enemy.get("health")) <= 0:
			continue
		var d := global_position.distance_to(enemy.global_position)
		if d < nearest_dist:
			nearest_dist = d
			nearest = enemy
	if nearest == null:
		return false
	ricochet_count -= 1
	direction = global_position.direction_to(nearest.global_position)
	lifetime = max(lifetime, 1.5)
	# Visual flash on ricochet
	var visual: Node2D = animated_sprite if animated_sprite.visible else sprite
	visual.modulate = Color(2.0, 2.0, 2.0, 1.0)
	var tween := DOTween.sequence(self, "ricochet_flash")
	tween.tween_property(visual, "modulate", Color.WHITE, 0.12)
	return true

func _setup_visual_tween() -> void:
	var visual: Node2D = animated_sprite if animated_sprite.visible else sprite
	var base_scale := visual.scale
	var orbit_weapon := weapon_id in ["reaping_scythe", "death_carousel", "grave_familiar", "seraph_swarm"]
	if not orbit_weapon:
		return
	visual.scale = base_scale * 0.70
	var spawn_tween := DOTween.sequence(self, "projectile_spawn")
	spawn_tween.tween_property(visual, "scale", base_scale, 0.16).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	DOTween.oscillate_property(self, visual, "scale", base_scale, base_scale * 1.08, 0.34, "projectile_breathe")
