extends Node2D

const DOTween := preload("res://scripts/utils/dotween.gd")
const TextureFactory := preload("res://scripts/visuals/texture_factory.gd")

@export var value := 6
@export var radius := 9.0
@export var magnet_speed := 760.0

var target: Node2D
@onready var sprite: Sprite2D = $Sprite

func _ready() -> void:
	sprite.texture = TextureFactory.xp_gem()
	var base_scale := Vector2.ONE * (radius / 16.0)
	sprite.scale = base_scale
	DOTween.pulse_scale(self, sprite, base_scale, 1.08, 0.42, "idle_pulse")

func _physics_process(delta: float) -> void:
	if target != null:
		global_position = global_position.move_toward(target.global_position, magnet_speed * delta)
