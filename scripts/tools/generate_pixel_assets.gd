extends SceneTree

const TILE_DIR := "res://assets/art/generated/tiles/"
const UI_DIR := "res://assets/art/generated/ui/"

func _initialize() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(TILE_DIR))
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(UI_DIR))
	for index in range(8):
		_save_tile(index)
	_save_panel("hud_panel_left", Vector2i(256, 132), Color(0.10, 0.04, 0.08, 0.94), Color(0.95, 0.22, 0.26, 0.98))
	_save_panel("hud_panel_right", Vector2i(256, 160), Color(0.05, 0.05, 0.11, 0.92), Color(0.34, 0.78, 1.0, 0.96))
	_save_panel("menu_frame", Vector2i(560, 820), Color(0.08, 0.04, 0.10, 0.96), Color(0.94, 0.70, 0.22, 0.98))
	_save_panel("talent_frame", Vector2i(560, 760), Color(0.06, 0.05, 0.12, 0.96), Color(0.68, 0.42, 1.0, 0.98))
	_save_panel("option_card", Vector2i(560, 116), Color(0.11, 0.05, 0.10, 0.96), Color(0.92, 0.64, 0.24, 0.98))
	_save_panel("slot_frame", Vector2i(512, 320), Color(0.09, 0.03, 0.08, 0.98), Color(1.0, 0.72, 0.18, 1.0), true)
	_save_bar("hp_bar", Color(0.82, 0.05, 0.10, 1.0), Color(0.22, 0.02, 0.05, 1.0), Color(1.0, 0.58, 0.32, 1.0))
	_save_bar("xp_bar", Color(0.40, 0.16, 1.0, 1.0), Color(0.05, 0.03, 0.12, 1.0), Color(0.80, 0.62, 1.0, 1.0))
	quit(0)

func _save_tile(index: int) -> void:
	var image := Image.create(128, 128, false, Image.FORMAT_RGBA8)
	var base_colors := [
		Color(0.055, 0.055, 0.075, 1.0),
		Color(0.070, 0.060, 0.080, 1.0),
		Color(0.060, 0.045, 0.060, 1.0),
		Color(0.045, 0.055, 0.070, 1.0),
		Color(0.075, 0.050, 0.045, 1.0),
		Color(0.040, 0.065, 0.065, 1.0),
		Color(0.070, 0.065, 0.050, 1.0),
		Color(0.050, 0.040, 0.075, 1.0)
	]
	image.fill(base_colors[index])
	for x in range(0, 128, 16):
		for y in range(0, 128, 16):
			var shade := 0.018 * float((x / 16 + y / 16 + index) % 4)
			_fill_rect(image, Rect2i(x, y, 16, 16), base_colors[index].lightened(shade))
	for line in range(5):
		var y := 12 + ((line * 23 + index * 11) % 108)
		_draw_line(image, Vector2i(4, y), Vector2i(124, y + ((index + line) % 5) - 2), Color(0.16, 0.08, 0.10, 0.46))
	if index % 2 == 1:
		_draw_diamond(image, Vector2i(64, 64), 18 + index, Color(0.28, 0.08, 0.16, 0.38))
	if index % 3 == 0:
		_draw_line(image, Vector2i(18, 100), Vector2i(104, 22), Color(0.65, 0.16, 0.10, 0.45))
	image.save_png("%stile_floor_%d.png" % [TILE_DIR, index])

func _save_panel(name: String, size: Vector2i, fill: Color, border: Color, slot := false) -> void:
	var image := Image.create(size.x, size.y, false, Image.FORMAT_RGBA8)
	image.fill(Color(0, 0, 0, 0))
	_fill_rect(image, Rect2i(4, 4, size.x - 8, size.y - 8), fill)
	_draw_rect_outline(image, Rect2i(4, 4, size.x - 8, size.y - 8), 4, border)
	_draw_rect_outline(image, Rect2i(10, 10, size.x - 20, size.y - 20), 2, border.darkened(0.35))
	for x in range(18, size.x - 18, 24):
		image.set_pixel(x, 8, border.lightened(0.20))
		image.set_pixel(x + 1, 8, border.lightened(0.20))
	if slot:
		for reel in range(3):
			var rx := 54 + reel * 148
			_fill_rect(image, Rect2i(rx, 80, 108, 108), Color(0.02, 0.015, 0.03, 1.0))
			_draw_rect_outline(image, Rect2i(rx, 80, 108, 108), 4, Color(0.96, 0.24, 0.42, 0.95))
		_fill_rect(image, Rect2i(380, 28, 22, 118), Color(0.78, 0.58, 0.15, 1.0))
		_draw_disc(image, Vector2i(418, 50), 17, Color(1.0, 0.20, 0.18, 1.0))
	image.save_png("%s%s.png" % [UI_DIR, name])

func _save_bar(name: String, fill: Color, bg: Color, border: Color) -> void:
	var image := Image.create(512, 40, false, Image.FORMAT_RGBA8)
	image.fill(Color(0, 0, 0, 0))
	_fill_rect(image, Rect2i(4, 6, 504, 28), bg)
	_fill_rect(image, Rect2i(10, 12, 492, 16), fill)
	_draw_rect_outline(image, Rect2i(4, 6, 504, 28), 4, border)
	for x in range(16, 496, 24):
		_fill_rect(image, Rect2i(x, 12, 8, 16), fill.lightened(0.18))
	image.save_png("%s%s.png" % [UI_DIR, name])

func _fill_rect(image: Image, rect: Rect2i, color: Color) -> void:
	for x in range(rect.position.x, rect.position.x + rect.size.x):
		for y in range(rect.position.y, rect.position.y + rect.size.y):
			if x >= 0 and y >= 0 and x < image.get_width() and y < image.get_height():
				image.set_pixel(x, y, color)

func _draw_rect_outline(image: Image, rect: Rect2i, width: int, color: Color) -> void:
	_fill_rect(image, Rect2i(rect.position.x, rect.position.y, rect.size.x, width), color)
	_fill_rect(image, Rect2i(rect.position.x, rect.position.y + rect.size.y - width, rect.size.x, width), color)
	_fill_rect(image, Rect2i(rect.position.x, rect.position.y, width, rect.size.y), color)
	_fill_rect(image, Rect2i(rect.position.x + rect.size.x - width, rect.position.y, width, rect.size.y), color)

func _draw_line(image: Image, start: Vector2i, end: Vector2i, color: Color) -> void:
	var delta := end - start
	var steps: int = maxi(abs(delta.x), abs(delta.y))
	for step in range(steps + 1):
		var point := Vector2(start).lerp(Vector2(end), float(step) / float(maxi(1, steps))).round()
		if point.x >= 0 and point.y >= 0 and point.x < image.get_width() and point.y < image.get_height():
			image.set_pixel(int(point.x), int(point.y), color)

func _draw_diamond(image: Image, center: Vector2i, radius: int, color: Color) -> void:
	for x in range(center.x - radius, center.x + radius + 1):
		for y in range(center.y - radius, center.y + radius + 1):
			if abs(x - center.x) + abs(y - center.y) <= radius and x >= 0 and y >= 0 and x < image.get_width() and y < image.get_height():
				image.set_pixel(x, y, color)

func _draw_disc(image: Image, center: Vector2i, radius: int, color: Color) -> void:
	for x in range(center.x - radius, center.x + radius + 1):
		for y in range(center.y - radius, center.y + radius + 1):
			if Vector2(x - center.x, y - center.y).length() <= radius and x >= 0 and y >= 0 and x < image.get_width() and y < image.get_height():
				image.set_pixel(x, y, color)
