extends Node2D

const TextureFactory := preload("res://scripts/visuals/texture_factory.gd")

@export var speed := 260.0
@export var damage := 10.0
@export var radius := 7.0
@export var lifetime := 6.0
@export var world_size := Vector2(3600, 2400)

var direction := Vector2.RIGHT
@onready var sprite: Sprite2D = $Sprite

func _ready() -> void:
	sprite.texture = TextureFactory.enemy_projectile()
	sprite.scale = Vector2.ONE * (radius / 11.0)

func _physics_process(delta: float) -> void:
	lifetime -= delta
	global_position += direction.normalized() * speed * delta
	if lifetime <= 0.0 or not Rect2(Vector2.ZERO, world_size).grow(180.0).has_point(global_position):
		queue_free()
	rotation = direction.angle()
