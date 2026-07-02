extends RefCounted

static var _cache := {}

static func enemy_body(archetype: String) -> Texture2D:
	return _fetch("enemy_body_%s" % archetype, func() -> Texture2D:
		var image := Image.create(96, 96, false, Image.FORMAT_RGBA8)
		image.fill(Color(0, 0, 0, 0))
		var color := _enemy_body_color(archetype)
		var points := PackedVector2Array([
			Vector2(48, 8),
			Vector2(84, 38),
			Vector2(70, 82),
			Vector2(26, 82),
			Vector2(12, 38)
		])
		_fill_polygon(image, points, color)
		return ImageTexture.create_from_image(image)
	)

static func enemy_glow(archetype: String) -> Texture2D:
	return _fetch("enemy_glow_%s" % archetype, func() -> Texture2D:
		return _radial_texture(128, _enemy_glow_color(archetype))
	)

static func enemy_mark(archetype: String) -> Texture2D:
	return _fetch("enemy_mark_%s" % archetype, func() -> Texture2D:
		var image := Image.create(96, 96, false, Image.FORMAT_RGBA8)
		image.fill(Color(0, 0, 0, 0))
		match archetype:
			"shooter":
				_draw_rect(image, Rect2i(24, 42, 48, 8), Color(1.0, 0.55, 0.25, 0.92))
			"buffer":
				_draw_ring(image, Vector2(48, 48), 34.0, 4.0, Color(0.78, 0.44, 1.0, 0.95))
			"charger":
				_draw_rect(image, Rect2i(44, 12, 8, 72), Color(1.0, 0.95, 0.28, 0.95))
			"tank":
				_draw_rect_outline(image, Rect2i(22, 22, 52, 52), 4, Color(0.62, 0.48, 0.26, 0.92))
			"splitter":
				_draw_disc(image, Vector2(34, 58), 8.0, Color(0.96, 0.32, 0.82, 0.95))
				_draw_disc(image, Vector2(62, 58), 8.0, Color(0.96, 0.32, 0.82, 0.95))
			"bomber":
				_draw_disc(image, Vector2(48, 48), 16.0, Color(0.78, 1.0, 0.14, 0.95))
			"elite":
				_draw_line(image, Vector2(20, 20), Vector2(76, 76), 3.0, Color(1.0, 0.72, 0.20, 0.95))
			"boss":
				_draw_ring(image, Vector2(48, 48), 38.0, 6.0, Color(1.0, 0.18, 0.12, 0.95))
		return ImageTexture.create_from_image(image)
	)

static func enemy_eye() -> Texture2D:
	return _fetch("enemy_eye", func() -> Texture2D:
		var image := Image.create(48, 24, false, Image.FORMAT_RGBA8)
		image.fill(Color(0, 0, 0, 0))
		_draw_disc(image, Vector2(14, 12), 5.0, Color(1.0, 0.48, 0.22, 0.96))
		_draw_disc(image, Vector2(34, 12), 5.0, Color(1.0, 0.48, 0.22, 0.96))
		return ImageTexture.create_from_image(image)
	)

static func projectile(weapon_id: String) -> Texture2D:
	return _fetch("projectile_%s" % weapon_id, func() -> Texture2D:
		var core := Color(1.0, 0.86, 0.32)
		var ring := Color(0.98, 0.42, 0.12, 0.78)
		if weapon_id == "blood_bolt":
			core = Color(1.0, 0.58, 0.36)
			ring = Color(1.0, 0.12, 0.14, 0.82)
		elif weapon_id == "crimson_judgment":
			core = Color(1.0, 0.86, 0.74)
			ring = Color(1.0, 0.04, 0.08, 0.92)
		elif weapon_id == "grave_familiar":
			core = Color(0.72, 0.98, 1.0)
			ring = Color(0.28, 0.86, 1.0, 0.90)
		elif weapon_id == "seraph_swarm":
			core = Color(1.0, 0.92, 0.68)
			ring = Color(1.0, 0.36, 0.42, 0.94)
		elif weapon_id == "reaping_scythe" or weapon_id == "death_carousel":
			core = Color(0.92, 0.96, 1.0)
			ring = Color(0.42, 0.68, 1.0, 0.92)
		return _disc_with_ring(52, core, ring)
	)

static func enemy_projectile() -> Texture2D:
	return _fetch("enemy_projectile", func() -> Texture2D:
		return _disc_with_ring(54, Color(1.0, 0.18, 0.12), Color(1.0, 0.68, 0.28, 0.85))
	)

static func xp_gem() -> Texture2D:
	return _fetch("xp_gem", func() -> Texture2D:
		var image := Image.create(56, 56, false, Image.FORMAT_RGBA8)
		image.fill(Color(0, 0, 0, 0))
		_draw_disc(image, Vector2(28, 28), 20.0, Color(0.45, 0.18, 0.95, 0.18))
		_fill_polygon(image, PackedVector2Array([
			Vector2(28, 6),
			Vector2(44, 28),
			Vector2(28, 50),
			Vector2(12, 28)
		]), Color(0.55, 0.30, 1.0, 0.95))
		_draw_line(image, Vector2(28, 15), Vector2(28, 41), 2.0, Color(0.95, 0.88, 1.0, 0.85))
		return ImageTexture.create_from_image(image)
	)

static func pickup(pickup_type: String) -> Texture2D:
	return _fetch("pickup_%s" % pickup_type, func() -> Texture2D:
		var image := Image.create(64, 64, false, Image.FORMAT_RGBA8)
		image.fill(Color(0, 0, 0, 0))
		if pickup_type == "potion":
			_draw_disc(image, Vector2(32, 32), 24.0, Color(0.12, 1.0, 0.32, 0.14))
			_draw_rect(image, Rect2i(22, 18, 20, 28), Color(0.08, 0.16, 0.10, 0.98))
			_draw_rect(image, Rect2i(24, 23, 16, 18), Color(0.20, 1.0, 0.42, 0.98))
			_draw_rect(image, Rect2i(29, 14, 6, 8), Color(0.86, 1.0, 0.82, 0.95))
		elif pickup_type == "slot":
			_draw_disc(image, Vector2(32, 32), 26.0, Color(1.0, 0.76, 0.14, 0.16))
			_draw_rect_outline(image, Rect2i(12, 16, 40, 32), 4, Color(0.72, 0.10, 0.34, 0.98))
			_draw_rect(image, Rect2i(18, 22, 28, 20), Color(0.14, 0.03, 0.10, 0.98))
			_draw_disc(image, Vector2(22, 32), 4.0, Color(1.0, 0.35, 0.42, 0.96))
			_draw_disc(image, Vector2(32, 32), 4.0, Color(1.0, 0.86, 0.30, 0.96))
			_draw_disc(image, Vector2(42, 32), 4.0, Color(0.55, 1.0, 0.82, 0.96))
			_draw_line(image, Vector2(50, 20), Vector2(56, 12), 2.5, Color(0.92, 0.74, 0.18, 0.98))
			_draw_disc(image, Vector2(56, 12), 4.0, Color(1.0, 0.82, 0.26, 0.98))
		else:
			_draw_disc(image, Vector2(32, 32), 24.0, Color(0.18, 0.56, 1.0, 0.14))
			_draw_ring(image, Vector2(24, 32), 11.0, 4.0, Color(0.28, 0.72, 1.0, 0.98))
			_draw_ring(image, Vector2(40, 32), 11.0, 4.0, Color(1.0, 0.22, 0.32, 0.98))
			_draw_disc(image, Vector2(32, 32), 4.0, Color(0.92, 0.96, 1.0, 0.95))
		return ImageTexture.create_from_image(image)
	)

static func arena_background() -> Texture2D:
	var texture_size: int = 768 if OS.has_feature("mobile") else 1024
	return _fetch("arena_background_%d" % texture_size, func() -> Texture2D:
		var image := Image.create(texture_size, texture_size, false, Image.FORMAT_RGBA8)
		image.fill(Color(0.035, 0.04, 0.06, 1.0))
		var tile_size: int = maxi(48, texture_size / 20)
		for x in range(0, texture_size, tile_size):
			for y in range(0, texture_size, tile_size):
				var shade := 0.03 + float((x / 96 + y / 96) % 5) * 0.007
				_draw_rect(image, Rect2i(x, y, tile_size, tile_size), Color(shade, shade * 0.84, shade * 1.2, 0.55))
		var grid_step: int = maxi(32, texture_size / 28)
		for x in range(0, texture_size, grid_step):
			_draw_rect(image, Rect2i(x, 0, 2, texture_size), Color(0.24, 0.10, 0.20, 0.26))
		for y in range(0, texture_size, grid_step):
			_draw_rect(image, Rect2i(0, y, texture_size, 2), Color(0.24, 0.10, 0.20, 0.26))
		for index in range(42):
			var center := Vector2(
				fposmod(173.0 * index + 217.0, float(texture_size)),
				fposmod(251.0 * index + 81.0, float(texture_size))
			)
			_draw_disc(image, center, 22.0 + float(index % 4) * 8.0, Color(0.09, 0.015, 0.03, 0.22))
		for index in range(8):
			var center := Vector2(
				fposmod(311.0 * index + 420.0, float(texture_size)),
				fposmod(389.0 * index + 340.0, float(texture_size))
			)
			_draw_ring(image, center, 60.0 + float(index % 3) * 18.0, 3.0, Color(0.72, 0.10, 0.34, 0.34))
			_draw_ring(image, center, 32.0 + float(index % 3) * 10.0, 2.0, Color(0.72, 0.10, 0.34, 0.24))
		return ImageTexture.create_from_image(image)
	)

static func slot_symbol(symbol_id: String) -> Texture2D:
	return _fetch("slot_symbol_%s" % symbol_id, func() -> Texture2D:
		var image := Image.create(96, 96, false, Image.FORMAT_RGBA8)
		image.fill(Color(0, 0, 0, 0))
		_draw_rect(image, Rect2i(8, 8, 80, 80), Color(0.10, 0.04, 0.12, 0.98))
		_draw_rect_outline(image, Rect2i(8, 8, 80, 80), 4, Color(0.92, 0.76, 0.24, 0.96))
		match symbol_id:
			"weapon":
				_draw_line(image, Vector2(28, 70), Vector2(68, 30), 4.0, Color(1.0, 0.24, 0.32, 0.96))
				_draw_line(image, Vector2(36, 76), Vector2(76, 36), 2.0, Color(1.0, 0.88, 0.78, 0.9))
			"relic":
				_fill_polygon(image, PackedVector2Array([Vector2(48, 18), Vector2(72, 48), Vector2(48, 78), Vector2(24, 48)]), Color(0.86, 0.64, 1.0, 0.96))
			"power":
				_draw_disc(image, Vector2(48, 48), 20.0, Color(0.32, 0.88, 1.0, 0.92))
				_draw_ring(image, Vector2(48, 48), 28.0, 4.0, Color(0.84, 0.94, 1.0, 0.9))
			"jackpot":
				_draw_disc(image, Vector2(48, 48), 24.0, Color(1.0, 0.24, 0.34, 0.92))
				_draw_disc(image, Vector2(48, 48), 14.0, Color(1.0, 0.90, 0.32, 0.96))
				_draw_line(image, Vector2(48, 14), Vector2(48, 82), 2.0, Color(1.0, 0.96, 0.88, 0.92))
				_draw_line(image, Vector2(14, 48), Vector2(82, 48), 2.0, Color(1.0, 0.96, 0.88, 0.92))
			"fate":
				_draw_arc_tex(image, Vector2(48, 48), 24.0, 0.0, TAU, 3.0, Color(0.56, 1.0, 0.80, 0.96))
				_draw_disc(image, Vector2(48, 28), 5.0, Color(0.56, 1.0, 0.80, 0.96))
		return ImageTexture.create_from_image(image)
	)

static func slot_machine_frame() -> Texture2D:
	return _fetch("slot_machine_frame", func() -> Texture2D:
		var image := Image.create(512, 320, false, Image.FORMAT_RGBA8)
		image.fill(Color(0, 0, 0, 0))
		_draw_rect(image, Rect2i(8, 8, 496, 304), Color(0.14, 0.04, 0.12, 0.96))
		_draw_rect_outline(image, Rect2i(8, 8, 496, 304), 8, Color(0.92, 0.74, 0.20, 0.98))
		for index in range(3):
			var x := 54 + index * 148
			_draw_rect(image, Rect2i(x, 74, 108, 108), Color(0.06, 0.02, 0.08, 0.98))
			_draw_rect_outline(image, Rect2i(x, 74, 108, 108), 5, Color(0.80, 0.24, 0.42, 0.94))
		_draw_rect(image, Rect2i(374, 30, 24, 124), Color(0.84, 0.68, 0.18, 0.96))
		_draw_disc(image, Vector2(418, 52), 18.0, Color(1.0, 0.26, 0.34, 0.96))
		return ImageTexture.create_from_image(image)
	)

static func health_bar_frame() -> Texture2D:
	return _fetch("health_bar_frame", func() -> Texture2D:
		var image := Image.create(360, 36, false, Image.FORMAT_RGBA8)
		image.fill(Color(0, 0, 0, 0))
		_draw_rect(image, Rect2i(0, 0, 360, 36), Color(0.08, 0.03, 0.07, 0.94))
		_draw_rect_outline(image, Rect2i(0, 0, 360, 36), 4, Color(0.88, 0.74, 0.28, 0.96))
		return ImageTexture.create_from_image(image)
	)

static func health_bar_fill() -> Texture2D:
	return _fetch("health_bar_fill", func() -> Texture2D:
		var image := Image.create(340, 20, false, Image.FORMAT_RGBA8)
		image.fill(Color(0.78, 0.10, 0.18, 0.98))
		for x in range(0, 340, 16):
			_draw_rect(image, Rect2i(x, 0, 8, 20), Color(1.0, 0.32, 0.38, 0.20))
		return ImageTexture.create_from_image(image)
	)

static func health_bar_bg() -> Texture2D:
	return _fetch("health_bar_bg", func() -> Texture2D:
		var image := Image.create(340, 20, false, Image.FORMAT_RGBA8)
		image.fill(Color(0.16, 0.06, 0.10, 0.95))
		return ImageTexture.create_from_image(image)
	)

static func warning_banner() -> Texture2D:
	return _fetch("warning_banner", func() -> Texture2D:
		var image := Image.create(720, 96, false, Image.FORMAT_RGBA8)
		image.fill(Color(0, 0, 0, 0))
		_fill_polygon(image, PackedVector2Array([
			Vector2(38, 48), Vector2(92, 8), Vector2(628, 8), Vector2(682, 48), Vector2(628, 88), Vector2(92, 88)
		]), Color(0.16, 0.03, 0.06, 0.92))
		_draw_rect_outline(image, Rect2i(96, 10, 528, 76), 4, Color(0.96, 0.72, 0.24, 0.96))
		return ImageTexture.create_from_image(image)
	)

static func wingman_body(evolved: bool) -> Texture2D:
	return _fetch("wingman_body_%s" % str(evolved), func() -> Texture2D:
		var image := Image.create(96, 96, false, Image.FORMAT_RGBA8)
		image.fill(Color(0, 0, 0, 0))
		var core := Color(0.52, 0.96, 1.0, 0.96)
		var shell := Color(0.12, 0.08, 0.18, 0.96)
		if evolved:
			core = Color(1.0, 0.36, 0.42, 0.96)
			shell = Color(0.16, 0.03, 0.06, 0.98)
		_fill_polygon(image, PackedVector2Array([
			Vector2(48, 10), Vector2(76, 34), Vector2(66, 78), Vector2(30, 78), Vector2(20, 34)
		]), shell)
		_draw_disc(image, Vector2(48, 46), 18.0, core)
		_draw_line(image, Vector2(20, 38), Vector2(8, 58), 2.5, core)
		_draw_line(image, Vector2(76, 38), Vector2(88, 58), 2.5, core)
		if evolved:
			_draw_ring(image, Vector2(48, 46), 28.0, 3.0, Color(1.0, 0.84, 0.58, 0.90))
		return ImageTexture.create_from_image(image)
	)

static func player_layer(layer: String) -> Texture2D:
	return _fetch("player_%s" % layer, func() -> Texture2D:
		var image := Image.create(128, 128, false, Image.FORMAT_RGBA8)
		image.fill(Color(0, 0, 0, 0))
		match layer:
			"glow":
				_draw_disc(image, Vector2(64, 64), 42.0, Color(0.25, 0.95, 0.78, 0.17))
				_draw_disc(image, Vector2(64, 64), 34.0, Color(0.16, 0.65, 0.55, 0.20))
			"cloak":
				_fill_polygon(image, PackedVector2Array([
					Vector2(32, 62),
					Vector2(64, 36),
					Vector2(96, 62),
					Vector2(84, 108),
					Vector2(44, 108)
				]), Color(0.035, 0.055, 0.075, 0.98))
			"body":
				_draw_disc(image, Vector2(64, 30), 16.0, Color(0.12, 0.18, 0.20, 0.98))
				_draw_rect(image, Rect2i(50, 38, 28, 46), Color(0.12, 0.18, 0.20, 0.98))
			"bones":
				_draw_line(image, Vector2(46, 56), Vector2(26, 78), 2.0, Color(0.72, 0.95, 0.88, 0.95))
				_draw_line(image, Vector2(82, 56), Vector2(102, 78), 2.0, Color(0.72, 0.95, 0.88, 0.95))
				_draw_line(image, Vector2(56, 84), Vector2(42, 108), 2.0, Color(0.72, 0.95, 0.88, 0.95))
				_draw_line(image, Vector2(72, 84), Vector2(86, 108), 2.0, Color(0.72, 0.95, 0.88, 0.95))
			"eyes":
				_draw_disc(image, Vector2(58, 26), 3.0, Color(0.55, 1.0, 0.82, 0.98))
				_draw_disc(image, Vector2(70, 26), 3.0, Color(0.55, 1.0, 0.82, 0.98))
			"core":
				_draw_disc(image, Vector2(64, 64), 10.0, Color(1.0, 0.05, 0.10, 0.92))
			"spirit_ring":
				_draw_ring(image, Vector2(64, 64), 42.0, 3.0, Color(0.72, 0.78, 1.0, 0.72))
			"abyss_horns":
				_draw_line(image, Vector2(42, 102), Vector2(22, 122), 2.5, Color(0.72, 0.22, 1.0, 0.72))
				_draw_line(image, Vector2(86, 102), Vector2(106, 122), 2.5, Color(0.72, 0.22, 1.0, 0.72))
			"ember_crown":
				_draw_arc_tex(image, Vector2(64, 18), 16.0, PI, TAU, 2.5, Color(1.0, 0.62, 0.18, 0.88))
			"lens":
				_draw_disc(image, Vector2(64, 26), 5.0, Color(1.0, 0.08, 0.12, 0.92))
			"powder":
				_draw_disc(image, Vector2(82, 68), 5.0, Color(0.72, 1.0, 0.22, 0.92))
			"bone_wheel":
				_draw_ring(image, Vector2(64, 64), 50.0, 2.0, Color(0.90, 0.96, 1.0, 0.65))
			"facing":
				_draw_rect(image, Rect2i(61, 18, 6, 48), Color(0.55, 1.0, 0.82, 0.72))
				_draw_disc(image, Vector2(64, 14), 7.0, Color(0.55, 1.0, 0.82, 0.42))
			"invulnerability":
				_draw_ring(image, Vector2(64, 64), 58.0, 7.0, Color(0.75, 1.0, 0.96, 0.30))
		return ImageTexture.create_from_image(image)
	)

static func weapon_zone(weapon_id: String, evolved: bool) -> Texture2D:
	return _fetch("weapon_zone_%s_%s" % [weapon_id, str(evolved)], func() -> Texture2D:
		var image := Image.create(160, 160, false, Image.FORMAT_RGBA8)
		image.fill(Color(0, 0, 0, 0))
		var core := Color(0.40, 0.08, 0.95, 0.28)
		var edge := Color(0.95, 0.72, 1.0, 0.82)
		if weapon_id == "soul_nova" or weapon_id == "soul_eclipse":
			core = Color(0.15, 0.90, 0.72, 0.28)
			edge = Color(0.65, 1.0, 0.88, 0.82)
		elif weapon_id == "ghost_blades" or weapon_id == "wraith_storm":
			core = Color(0.62, 0.62, 1.0, 0.24)
			edge = Color(0.82, 0.86, 1.0, 0.80)
		elif weapon_id == "abyss_scream":
			core = Color(0.85, 0.02, 0.18, 0.30)
			edge = Color(1.0, 0.28, 0.38, 0.86)
		elif weapon_id == "doom_laser" or weapon_id == "void_lance":
			core = Color(1.0, 0.02, 0.08, 0.32)
			edge = Color(1.0, 0.78, 0.72, 0.90)
		elif weapon_id == "plague_bomb" or weapon_id == "grave_mortar":
			core = Color(0.68, 0.95, 0.08, 0.32)
			edge = Color(0.92, 1.0, 0.34, 0.86)
		elif weapon_id == "abyss_tentacle" or weapon_id == "old_one_grasp":
			core = Color(0.48, 0.02, 0.72, 0.30)
			edge = Color(0.92, 0.30, 1.0, 0.86)
		_draw_disc(image, Vector2(80, 80), 76.0, core)
		_draw_ring(image, Vector2(80, 80), 76.0, 5.0 if evolved else 3.0, edge)
		_draw_ring(image, Vector2(80, 80), 42.0, 3.0, edge.darkened(0.18))
		return ImageTexture.create_from_image(image)
	)

static func combat_ring() -> Texture2D:
	return _fetch("combat_ring", func() -> Texture2D:
		var image := Image.create(160, 160, false, Image.FORMAT_RGBA8)
		image.fill(Color(0, 0, 0, 0))
		_draw_disc(image, Vector2(80, 80), 70.0, Color(1.0, 1.0, 1.0, 0.20))
		_draw_ring(image, Vector2(80, 80), 70.0, 4.0, Color(1.0, 1.0, 1.0, 0.95))
		return ImageTexture.create_from_image(image)
	)

static func _disc_with_ring(size: int, core: Color, ring: Color) -> Texture2D:
	var image := Image.create(size, size, false, Image.FORMAT_RGBA8)
	image.fill(Color(0, 0, 0, 0))
	var center := Vector2.ONE * (float(size) * 0.5)
	_draw_disc(image, center, size * 0.34, ring)
	_draw_disc(image, center, size * 0.22, core)
	return ImageTexture.create_from_image(image)

static func _radial_texture(size: int, color: Color) -> Texture2D:
	var image := Image.create(size, size, false, Image.FORMAT_RGBA8)
	image.fill(Color(0, 0, 0, 0))
	var center := Vector2.ONE * (float(size) * 0.5)
	for x in range(size):
		for y in range(size):
			var distance := Vector2(x, y).distance_to(center)
			var alpha := clampf(1.0 - distance / (float(size) * 0.5), 0.0, 1.0)
			if alpha <= 0.0:
				continue
			image.set_pixel(x, y, Color(color.r, color.g, color.b, alpha * color.a))
	return ImageTexture.create_from_image(image)

static func _enemy_body_color(archetype: String) -> Color:
	match archetype:
		"shooter":
			return Color(0.28, 0.08, 0.22)
		"buffer":
			return Color(0.19, 0.06, 0.34)
		"elite":
			return Color(0.42, 0.03, 0.03)
		"charger":
			return Color(0.50, 0.16, 0.02)
		"tank":
			return Color(0.13, 0.11, 0.10)
		"splitter":
			return Color(0.36, 0.04, 0.28)
		"bomber":
			return Color(0.22, 0.34, 0.04)
		"boss":
			return Color(0.12, 0.005, 0.01)
		_:
			return Color(0.34, 0.025, 0.055)

static func _enemy_glow_color(archetype: String) -> Color:
	match archetype:
		"shooter":
			return Color(0.7, 0.08, 0.42, 0.20)
		"buffer":
			return Color(0.45, 0.12, 0.9, 0.20)
		"elite":
			return Color(0.9, 0.08, 0.03, 0.22)
		"charger":
			return Color(1.0, 0.52, 0.08, 0.23)
		"tank":
			return Color(0.78, 0.65, 0.45, 0.22)
		"splitter":
			return Color(0.95, 0.16, 0.82, 0.21)
		"bomber":
			return Color(0.64, 1.0, 0.12, 0.24)
		"boss":
			return Color(1.0, 0.08, 0.05, 0.24)
		_:
			return Color(0.55, 0.02, 0.06, 0.20)

static func _fetch(key: String, builder: Callable) -> Texture2D:
	if not _cache.has(key):
		_cache[key] = builder.call()
	return _cache[key]

static func _draw_disc(image: Image, center: Vector2, radius: float, color: Color) -> void:
	var radius_sq := radius * radius
	var min_x: int = maxi(0, int(floor(center.x - radius)))
	var max_x: int = mini(image.get_width() - 1, int(ceil(center.x + radius)))
	var min_y: int = maxi(0, int(floor(center.y - radius)))
	var max_y: int = mini(image.get_height() - 1, int(ceil(center.y + radius)))
	for x in range(min_x, max_x + 1):
		for y in range(min_y, max_y + 1):
			if Vector2(x, y).distance_squared_to(center) <= radius_sq:
				image.set_pixel(x, y, color)

static func _draw_ring(image: Image, center: Vector2, radius: float, thickness: float, color: Color) -> void:
	var outer_sq := radius * radius
	var inner_sq: float = max(radius - thickness, 0.0)
	inner_sq *= inner_sq
	var min_x: int = maxi(0, int(floor(center.x - radius)))
	var max_x: int = mini(image.get_width() - 1, int(ceil(center.x + radius)))
	var min_y: int = maxi(0, int(floor(center.y - radius)))
	var max_y: int = mini(image.get_height() - 1, int(ceil(center.y + radius)))
	for x in range(min_x, max_x + 1):
		for y in range(min_y, max_y + 1):
			var distance_sq := Vector2(x, y).distance_squared_to(center)
			if distance_sq <= outer_sq and distance_sq >= inner_sq:
				image.set_pixel(x, y, color)

static func _draw_rect(image: Image, rect: Rect2i, color: Color) -> void:
	for x in range(rect.position.x, rect.position.x + rect.size.x):
		for y in range(rect.position.y, rect.position.y + rect.size.y):
			if x >= 0 and y >= 0 and x < image.get_width() and y < image.get_height():
				image.set_pixel(x, y, color)

static func _draw_rect_outline(image: Image, rect: Rect2i, thickness: int, color: Color) -> void:
	_draw_rect(image, Rect2i(rect.position.x, rect.position.y, rect.size.x, thickness), color)
	_draw_rect(image, Rect2i(rect.position.x, rect.end.y - thickness, rect.size.x, thickness), color)
	_draw_rect(image, Rect2i(rect.position.x, rect.position.y, thickness, rect.size.y), color)
	_draw_rect(image, Rect2i(rect.end.x - thickness, rect.position.y, thickness, rect.size.y), color)

static func _draw_line(image: Image, start: Vector2, end: Vector2, thickness: float, color: Color) -> void:
	var length := int(ceil(start.distance_to(end)))
	for index in range(length + 1):
		var point := start.lerp(end, float(index) / max(length, 1))
		_draw_disc(image, point, thickness, color)

static func _draw_arc_tex(image: Image, center: Vector2, radius: float, start_angle: float, end_angle: float, thickness: float, color: Color) -> void:
	var steps: int = max(16, int(radius * abs(end_angle - start_angle) * 0.4))
	for index in range(steps + 1):
		var angle := lerpf(start_angle, end_angle, float(index) / float(steps))
		var point := center + Vector2.RIGHT.rotated(angle) * radius
		_draw_disc(image, point, thickness, color)

static func _fill_polygon(image: Image, points: PackedVector2Array, color: Color) -> void:
	var min_x := image.get_width() - 1
	var max_x := 0
	var min_y := image.get_height() - 1
	var max_y := 0
	for point in points:
		min_x = min(min_x, int(floor(point.x)))
		max_x = max(max_x, int(ceil(point.x)))
		min_y = min(min_y, int(floor(point.y)))
		max_y = max(max_y, int(ceil(point.y)))
	min_x = max(0, min_x)
	max_x = min(image.get_width() - 1, max_x)
	min_y = max(0, min_y)
	max_y = min(image.get_height() - 1, max_y)
	for x in range(min_x, max_x + 1):
		for y in range(min_y, max_y + 1):
			if Geometry2D.is_point_in_polygon(Vector2(x, y), points):
				image.set_pixel(x, y, color)
