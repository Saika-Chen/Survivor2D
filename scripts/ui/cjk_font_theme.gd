extends RefCounted

const FONT_PATH := "res://assets/fonts/fusion-pixel-12px-monospaced-zh_hans.ttf"

static var _font: FontFile
static var _global_applied := false

static func font() -> FontFile:
	if _font != null:
		return _font
	_font = load(FONT_PATH) as FontFile
	if _font == null:
		push_warning("Unable to load CJK UI font: %s" % FONT_PATH)
	return _font

static func ensure_global() -> void:
	if _global_applied:
		return
	var loaded_font := font()
	if loaded_font == null:
		return
	ThemeDB.fallback_font = loaded_font
	ThemeDB.fallback_font_size = 18
	_global_applied = true

static func apply_to(control: Control) -> void:
	ensure_global()
	var loaded_font := font()
	if control == null or loaded_font == null:
		return
	control.add_theme_font_override("font", loaded_font)

static func apply_to_tree(root: Node) -> void:
	ensure_global()
	if root == null:
		return
	if root is Control:
		apply_to(root)
	for child in root.get_children():
		apply_to_tree(child)
