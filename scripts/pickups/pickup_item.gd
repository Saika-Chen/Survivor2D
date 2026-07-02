extends Node2D

signal despawn_requested(pickup: Node2D)

const DOTween := preload("res://scripts/utils/dotween.gd")
const TextureFactory := preload("res://scripts/visuals/texture_factory.gd")

@export var pickup_type := "magnet"
@export var radius := 13.0
@export var magnet_speed := 420.0
@export var magnet_arrival_seconds := 0.5

var target: Node2D
var opening := false
@onready var sprite: Sprite2D = $Sprite

func _ready() -> void:
	reset_for_pool()

func reset_for_pool() -> void:
	DOTween.kill(self, "open_chest")
	DOTween.kill(self, "idle_pulse")
	target = null
	opening = false
	modulate = Color.WHITE
	rotation = 0.0
	_update_visual()
	DOTween.pulse_scale(self, sprite, Vector2.ONE * (radius / 18.0), 1.07, 0.38, "idle_pulse")

func _physics_process(delta: float) -> void:
	if target != null and not opening:
		var distance := global_position.distance_to(target.global_position)
		var pull_speed := maxf(magnet_speed, distance / maxf(0.05, magnet_arrival_seconds))
		global_position = global_position.move_toward(target.global_position, pull_speed * delta)

func play_open_animation(reward_type: String, finished: Callable) -> void:
	opening = true
	target = null
	DOTween.kill(self, "idle_pulse")
	pickup_type = "chest_open"
	_update_visual()
	var reward_tint := _reward_tint(reward_type)
	sprite.modulate = Color.WHITE
	var tween := DOTween.sequence(self, "open_chest")
	tween.set_parallel(true)
	tween.tween_property(sprite, "scale", Vector2.ONE * (radius / 18.0) * 1.55, 0.18).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.tween_property(sprite, "modulate", reward_tint, 0.18).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	tween.tween_property(self, "rotation", 0.10, 0.08).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	tween.chain().tween_property(self, "rotation", -0.08, 0.08).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	tween.chain().tween_property(sprite, "scale", Vector2.ONE * (radius / 18.0) * 1.18, 0.12).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	tween.tween_callback(func() -> void:
		if finished.is_valid():
			finished.call()
	)

func _update_visual() -> void:
	sprite.texture = TextureFactory.pickup(pickup_type)
	sprite.scale = Vector2.ONE * (radius / 18.0)

func _reward_tint(reward_type: String) -> Color:
	match reward_type:
		"potion":
			return Color(0.46, 1.0, 0.56, 1.0)
		"slot":
			return Color(1.0, 0.72, 0.30, 1.0)
		"haste":
			return Color(0.58, 0.92, 1.0, 1.0)
		_:
			return Color(0.72, 0.86, 1.0, 1.0)
