extends Node2D
const TextureFactory := preload("res://scripts/visuals/texture_factory.gd")

@export var arena_size := Vector2(5200, 3600)

var background_sprite: Sprite2D

func _ready() -> void:
	background_sprite = Sprite2D.new()
	background_sprite.centered = false
	background_sprite.texture = TextureFactory.arena_background()
	var texture_size := float(background_sprite.texture.get_width())
	background_sprite.scale = Vector2(arena_size.x / texture_size, arena_size.y / texture_size)
	add_child(background_sprite)
