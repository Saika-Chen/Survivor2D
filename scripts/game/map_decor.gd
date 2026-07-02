extends Node2D

const DOTween := preload("res://scripts/utils/dotween.gd")
const TextureFactory := preload("res://scripts/visuals/texture_factory.gd")

@export var arena_size := Vector2(5200, 3600)

var mobile_profile := false
var decor_root: Node2D

func _ready() -> void:
	_rebuild_decor()

func set_mobile_profile(enabled: bool) -> void:
	if mobile_profile == enabled:
		return
	mobile_profile = enabled
	_rebuild_decor()

func _rebuild_decor() -> void:
	if decor_root != null:
		decor_root.queue_free()
	decor_root = Node2D.new()
	add_child(decor_root)
	_build_fog()
	_build_soul_flames()
	_build_runes()

func _build_fog() -> void:
	var fog_count := 8 if mobile_profile else 16
	var fog_texture := TextureFactory.enemy_glow("buffer")
	for index in range(fog_count):
		var sprite := Sprite2D.new()
		sprite.texture = fog_texture
		sprite.centered = true
		sprite.position = Vector2(
			fposmod(257.0 * index + 37.0, arena_size.x),
			fposmod(349.0 * index + 91.0, arena_size.y)
		)
		var radius := 90.0 + fposmod(float(index * 19), 110.0)
		var scale_value := radius / 64.0
		sprite.scale = Vector2.ONE * scale_value
		sprite.modulate = Color(0.34, 0.12, 0.42, 0.08)
		decor_root.add_child(sprite)
		var drift := Vector2(
			14.0 + float(index % 4) * 3.0,
			10.0 + float((index + 2) % 5) * 2.0
		)
		var target_position := sprite.position + drift * (1.0 if index % 2 == 0 else -1.0)
		DOTween.oscillate_property(self, sprite, "position", sprite.position, target_position, 2.6 + float(index % 5) * 0.55, "fog_pos_%d" % index)
		DOTween.oscillate_property(self, sprite, "scale", Vector2.ONE * scale_value, Vector2.ONE * (scale_value * 1.08), 2.2 + float(index % 4) * 0.45, "fog_scale_%d" % index)

func _build_soul_flames() -> void:
	var flame_count := 10 if mobile_profile else 18
	var core_texture := TextureFactory.xp_gem()
	var glow_texture := TextureFactory.enemy_glow("shooter")
	for index in range(flame_count):
		var flame_root := Node2D.new()
		flame_root.position = Vector2(
			fposmod(311.0 * index + 251.0, arena_size.x),
			fposmod(197.0 * index + 143.0, arena_size.y)
		)
		decor_root.add_child(flame_root)

		var glow := Sprite2D.new()
		glow.texture = glow_texture
		glow.modulate = Color(0.18, 0.72, 1.0, 0.14)
		glow.scale = Vector2.ONE * 0.55
		flame_root.add_child(glow)

		var core := Sprite2D.new()
		core.texture = core_texture
		core.modulate = Color(0.76, 1.0, 0.96, 0.72)
		core.scale = Vector2(0.72, 1.08)
		core.position = Vector2(0.0, -4.0)
		flame_root.add_child(core)

		DOTween.oscillate_property(self, flame_root, "position:y", flame_root.position.y, flame_root.position.y - (10.0 + float(index % 3) * 3.0), 0.56 + float(index % 4) * 0.08, "flame_pos_%d" % index)
		DOTween.oscillate_property(self, glow, "scale", Vector2.ONE * 0.55, Vector2.ONE * 0.74, 0.42 + float(index % 3) * 0.07, "flame_glow_%d" % index)
		DOTween.oscillate_property(self, core, "scale", Vector2(0.72, 1.08), Vector2(0.92, 1.42), 0.38 + float(index % 4) * 0.06, "flame_core_%d" % index)

func _build_runes() -> void:
	var centers := [
		Vector2(arena_size.x * 0.50, arena_size.y * 0.50),
		Vector2(arena_size.x * 0.22, arena_size.y * 0.28),
		Vector2(arena_size.x * 0.78, arena_size.y * 0.34),
		Vector2(arena_size.x * 0.30, arena_size.y * 0.74)
	]
	if not mobile_profile:
		centers.append(Vector2(arena_size.x * 0.72, arena_size.y * 0.76))
	var rune_texture := TextureFactory.combat_ring()
	for index in range(centers.size()):
		var sprite := Sprite2D.new()
		sprite.texture = rune_texture
		sprite.position = centers[index]
		var base_scale := 1.88 if index == 0 else 1.26
		sprite.scale = Vector2.ONE * base_scale
		sprite.modulate = Color(0.95, 0.10, 0.30, 0.16)
		decor_root.add_child(sprite)
		DOTween.oscillate_property(self, sprite, "scale", Vector2.ONE * base_scale, Vector2.ONE * (base_scale * 1.14), 0.9 + float(index) * 0.14, "rune_scale_%d" % index)
		DOTween.spin_property(self, sprite, "rotation", TAU, 6.0 + float(index), "rune_spin_%d" % index)
