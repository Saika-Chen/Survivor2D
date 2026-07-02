extends Node2D

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
@onready var sprite: Sprite2D = $Sprite
@onready var animated_sprite: AnimatedSprite2D = $AnimatedSprite

func _ready() -> void:
	_update_visual()
	_setup_visual_tween()

func _physics_process(delta: float) -> void:
	lifetime -= delta
	global_position += direction.normalized() * speed * delta
	if lifetime <= 0.0 or not Rect2(Vector2.ZERO, world_size).grow(180.0).has_point(global_position):
		queue_free()
	rotation = direction.angle()

func _update_visual() -> void:
	var style := DuelystTheme.projectile_style(weapon_id)
	if style.get("frames") != null:
		sprite.visible = false
		animated_sprite.visible = true
		animated_sprite.sprite_frames = style.get("frames")
		animated_sprite.scale = Vector2.ONE * float(style.get("scale", 0.34)) * (radius / 7.0)
		animated_sprite.position = style.get("offset", Vector2.ZERO)
		animated_sprite.speed_scale = float(style.get("speed", 18.0)) / 10.0
		DuelystTheme.play_best_animation(animated_sprite)
		return
	animated_sprite.visible = false
	animated_sprite.position = Vector2.ZERO
	sprite.visible = true
	sprite.texture = TextureFactory.projectile(weapon_id)
	sprite.scale = Vector2.ONE * (radius / 11.0)

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
