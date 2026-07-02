extends Node2D

const DOTween := preload("res://scripts/utils/dotween.gd")
const TextureFactory := preload("res://scripts/visuals/texture_factory.gd")

@export var pickup_type := "magnet"
@export var radius := 13.0
@export var magnet_speed := 420.0

var target: Node2D
@onready var sprite: Sprite2D = $Sprite

func _ready() -> void:
	_update_visual()
	DOTween.pulse_scale(self, sprite, Vector2.ONE * (radius / 18.0), 1.07, 0.38, "idle_pulse")

func _physics_process(delta: float) -> void:
	if target != null:
		global_position = global_position.move_toward(target.global_position, magnet_speed * delta)

func _update_visual() -> void:
	sprite.texture = TextureFactory.pickup(pickup_type)
	sprite.scale = Vector2.ONE * (radius / 18.0)
