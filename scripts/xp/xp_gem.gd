extends Node2D

signal despawn_requested(gem: Node2D)

const DOTween := preload("res://scripts/utils/dotween.gd")
const TextureFactory := preload("res://scripts/visuals/texture_factory.gd")

@export var value := 6
@export var radius := 9.0
@export var magnet_speed := 760.0
@export var magnet_arrival_seconds := 0.5

var target: Node2D
var batched := false
@onready var sprite: Sprite2D = $Sprite

func _ready() -> void:
	reset_for_pool()

func set_batched(b: bool) -> void:
	batched = b
	if sprite != null:
		sprite.visible = not b

func reset_for_pool() -> void:
	target = null
	batched = false
	if sprite == null:
		return
	sprite.visible = true
	sprite.texture = TextureFactory.xp_gem()
	var base_scale := Vector2.ONE * (radius / 16.0)
	sprite.scale = base_scale
	DOTween.pulse_scale(self, sprite, base_scale, 1.08, 0.42, "idle_pulse")

func _physics_process(delta: float) -> void:
	if target != null:
		var distance := global_position.distance_to(target.global_position)
		var pull_speed := maxf(magnet_speed, distance / maxf(0.05, magnet_arrival_seconds))
		global_position = global_position.move_toward(target.global_position, pull_speed * delta)
