extends RefCounted

const FONT_PATH := "res://assets/fonts/PressStart2P-Regular.ttf"

static var _font: FontFile

static func font() -> FontFile:
	if _font != null:
		return _font
	_font = FontFile.new()
	var error := _font.load_dynamic_font(FONT_PATH)
	if error != OK:
		push_warning("Unable to load pixel font: %s" % FONT_PATH)
		_font = null
	return _font

static func apply_to(control: Control) -> void:
	var loaded_font := font()
	if control == null or loaded_font == null:
		return
	control.add_theme_font_override("font", loaded_font)
