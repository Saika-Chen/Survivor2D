extends Node2D

signal despawn_requested(zone: Node2D)

const DOTween := preload("res://scripts/utils/dotween.gd")
const TextureFactory := preload("res://scripts/visuals/texture_factory.gd")
const DuelystTheme := preload("res://scripts/visuals/duelyst_theme.gd")

@export var radius := 46.0
@export var damage := 10.0
@export var duration := 0.35
@export var tick_interval := 0.18
@export var weapon_id := "zone"
@export var evolved := false
@export var visual_rotation := 0.0

var tick_timer := 0.0
var damage_ready := true
var traits := {}
@onready var sprite: Sprite2D = $Sprite
@onready var animated_sprite: AnimatedSprite2D = $AnimatedSprite

func _ready() -> void:
	reset_for_pool()

func reset_for_pool() -> void:
	DOTween.kill(self, "zone_spin")
	DOTween.kill(self, "zone_lifetime")
	tick_timer = 0.0
	damage_ready = true
	_update_visual()
	var visual: CanvasItem = animated_sprite if animated_sprite.visible else sprite
	if visual is Node2D:
		(visual as Node2D).rotation = visual_rotation
	visual.modulate.a = 1.0
	var style := DuelystTheme.zone_style(weapon_id, evolved)
	if bool(style.get("spin", true)):
		DOTween.spin_property(self, visual, "rotation", visual_rotation + TAU, 4.0 if evolved else 5.0, "zone_spin")
	var fade_tween := DOTween.sequence(self, "zone_lifetime")
	fade_tween.tween_property(visual, "modulate:a", 0.0, duration).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	fade_tween.tween_callback(func() -> void:
		despawn_requested.emit(self)
	)

func _physics_process(delta: float) -> void:
	tick_timer -= delta
	if tick_timer <= 0.0:
		damage_ready = true
		tick_timer = tick_interval

func consume_damage_ready() -> bool:
	if not damage_ready:
		return false
	damage_ready = false
	return true

func _update_visual() -> void:
	if sprite == null or animated_sprite == null:
		return
	var style := DuelystTheme.zone_style(weapon_id, evolved)
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
		animated_sprite.scale = Vector2.ONE * float(style.get("scale", 0.6)) * (radius / 46.0)
		animated_sprite.position = style.get("offset", Vector2.ZERO)
		animated_sprite.speed_scale = float(style.get("speed", 16.0)) / 10.0
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
	sprite.texture = TextureFactory.weapon_zone(weapon_id, evolved)
	sprite.scale = Vector2.ONE * (radius / 76.0)
