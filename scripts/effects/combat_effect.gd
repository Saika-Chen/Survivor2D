extends Node2D

signal despawn_requested(effect: Node2D)

const DOTween := preload("res://scripts/utils/dotween.gd")
const TextureFactory := preload("res://scripts/visuals/texture_factory.gd")
const DuelystTheme := preload("res://scripts/visuals/duelyst_theme.gd")
const CJKFontTheme := preload("res://scripts/ui/cjk_font_theme.gd")

@export var radius := 34.0
@export var duration := 0.35
@export var color := Color(1.0, 0.22, 0.12, 0.75)
@export var label := ""
@export var effect_kind := "hit"

var velocity := Vector2.ZERO
var ring_sprite: Sprite2D
var animated_sprite: AnimatedSprite2D
var text_label: Label

func _ready() -> void:
	reset_for_pool()

func reset_for_pool() -> void:
	DOTween.kill(self, "label_anim")
	DOTween.kill(self, "ring_anim")
	DOTween.kill(self, "anim_fx")
	DOTween.kill(self, "motion")
	for child in get_children():
		remove_child(child)
		child.queue_free()
	ring_sprite = null
	animated_sprite = null
	text_label = null
	z_index = 0
	if label != "":
		z_index = max(z_index, 1000)
		text_label = Label.new()
		text_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		text_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		text_label.size = Vector2(180, 54)
		text_label.position = Vector2(-90, -27)
		text_label.text = label
		CJKFontTheme.apply_to(text_label)
		text_label.add_theme_font_size_override("font_size", 15)
		text_label.add_theme_color_override("font_color", color)
		text_label.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.95))
		text_label.add_theme_constant_override("shadow_offset_x", 2)
		text_label.add_theme_constant_override("shadow_offset_y", 2)
		add_child(text_label)
		_animate_label()
		_animate_motion()
		return
	var fx_style := DuelystTheme.combat_fx_style(effect_kind)
	if fx_style.get("frames") != null:
		animated_sprite = AnimatedSprite2D.new()
		animated_sprite.centered = true
		animated_sprite.sprite_frames = fx_style.get("frames")
		animated_sprite.scale = Vector2.ONE * float(fx_style.get("scale", 0.34)) * (radius / 26.0)
		animated_sprite.position = fx_style.get("offset", Vector2.ZERO)
		animated_sprite.speed_scale = float(fx_style.get("speed", 18.0)) / 10.0
		animated_sprite.modulate = color
		add_child(animated_sprite)
		DuelystTheme.play_best_animation(animated_sprite)
		_animate_animated_sprite()
		_animate_motion()
		return
	ring_sprite = Sprite2D.new()
	ring_sprite.texture = TextureFactory.combat_ring()
	ring_sprite.modulate = color
	ring_sprite.scale = Vector2.ONE * (4.0 / 70.0)
	add_child(ring_sprite)
	_animate_ring()
	_animate_motion()

func _animate_label() -> void:
	text_label.modulate = Color(1.0, 1.0, 1.0, 1.0)
	var tween := DOTween.sequence(self, "label_anim")
	tween.set_parallel(true)
	tween.tween_property(text_label, "position:y", text_label.position.y - 28.0, duration).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	tween.tween_property(text_label, "modulate:a", 0.0, duration).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)
	tween.tween_callback(func() -> void:
		despawn_requested.emit(self)
	)

func _animate_ring() -> void:
	var tween := DOTween.sequence(self, "ring_anim")
	tween.set_parallel(true)
	tween.tween_property(ring_sprite, "scale", Vector2.ONE * (radius / 70.0), duration).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tween.tween_property(ring_sprite, "modulate:a", 0.0, duration).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)
	tween.tween_callback(func() -> void:
		despawn_requested.emit(self)
	)

func _animate_animated_sprite() -> void:
	var tween := DOTween.sequence(self, "anim_fx")
	tween.set_parallel(true)
	tween.tween_property(animated_sprite, "scale", animated_sprite.scale * 1.18, duration).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tween.tween_property(animated_sprite, "modulate:a", 0.0, duration).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)
	tween.tween_callback(func() -> void:
		despawn_requested.emit(self)
	)

func _animate_motion() -> void:
	if velocity == Vector2.ZERO:
		return
	DOTween.sequence(self, "motion").tween_property(self, "global_position", global_position + velocity * duration, duration).set_trans(Tween.TRANS_LINEAR).set_ease(Tween.EASE_OUT)
