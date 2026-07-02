extends Node2D

const DOTween := preload("res://scripts/utils/dotween.gd")
const TextureFactory := preload("res://scripts/visuals/texture_factory.gd")
const DuelystTheme := preload("res://scripts/visuals/duelyst_theme.gd")

@onready var sprite: Sprite2D = $Sprite
@onready var animated_sprite: AnimatedSprite2D = $AnimatedSprite
var _base_scale := Vector2.ONE * 0.62
var _is_evolved := false

func configure_style(is_evolved: bool) -> void:
	if animated_sprite.sprite_frames != null and _is_evolved == is_evolved:
		return
	_is_evolved = is_evolved
	var style := DuelystTheme.wingman_style(is_evolved)
	if style.get("frames") != null:
		animated_sprite.visible = true
		animated_sprite.sprite_frames = style.get("frames")
		animated_sprite.position = style.get("offset", Vector2.ZERO)
		animated_sprite.speed_scale = float(style.get("speed", 8.0)) / 10.0
		DuelystTheme.play_best_animation(animated_sprite)
		sprite.visible = false
		_base_scale = Vector2.ONE * float(style.get("scale", 0.48))
		animated_sprite.scale = _base_scale
	else:
		animated_sprite.visible = false
		sprite.visible = true
		sprite.texture = TextureFactory.wingman_body(is_evolved)
		_base_scale = Vector2.ONE * (0.72 if is_evolved else 0.62)
		sprite.scale = _base_scale
	_play_spawn_tween()
	var visual: Node2D = animated_sprite if animated_sprite.visible else sprite
	DOTween.oscillate_property(self, visual, "scale", _base_scale, _base_scale * (1.07 if is_evolved else 1.05), 0.44 if is_evolved else 0.52, "wingman_breathe")

func set_orbit_pose(center: Vector2, angle: float, orbit_radius: float) -> void:
	global_position = center + Vector2.RIGHT.rotated(angle) * orbit_radius
	rotation = angle + PI * 0.5

func _play_spawn_tween() -> void:
	DOTween.kill(self, "wingman_spawn")
	var from_scale := _base_scale * 0.68
	var visual: Node2D = animated_sprite if animated_sprite.visible else sprite
	visual.scale = from_scale
	var tween := DOTween.sequence(self, "wingman_spawn")
	tween.tween_property(visual, "scale", _base_scale, 0.20).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
