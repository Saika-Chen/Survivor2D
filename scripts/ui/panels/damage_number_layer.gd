extends Control
class_name DamageNumberLayer
## DamageNumberLayer：在世界实体上方显示并复用浮动伤害数字。

const DOTween := preload("res://scripts/utils/dotween.gd")
const CJKFontTheme := preload("res://scripts/ui/cjk_font_theme.gd")

var damage_label_pool: Array[Label] = []
var last_damage_number_label: Label

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	set_anchors_preset(Control.PRESET_FULL_RECT)
	z_index = 1000
	for _i in range(48):
		var label := _create_damage_label(); label.hide(); add_child(label)
		damage_label_pool.append(label)

func show_damage_number(screen_position: Vector2, text: String, critical := false) -> void:
	var label: Label = _take_damage_label()
	last_damage_number_label = label
	DOTween.kill(label, "damage_number")
	label.text = text; label.z_index = 1000; label.visible = true; label.modulate = Color.WHITE
	label.scale = Vector2.ONE * (1.28 if critical else 1.0)
	label.position = screen_position - label.size * 0.5
	label.add_theme_font_size_override("font_size", 23 if critical else 16)
	label.add_theme_color_override("font_color", Color(1.0, 0.14, 0.06, 1.0) if critical else Color(1.0, 0.96, 0.34, 1.0))
	var rise: float = 58.0 if critical else 33.0
	var tw := DOTween.sequence(label, "damage_number"); tw.set_parallel(true)
	tw.tween_property(label, "position:y", label.position.y - rise, 0.84 if critical else 0.58).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	tw.tween_property(label, "scale", Vector2.ONE * (1.42 if critical else 1.10), 0.16).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tw.tween_property(label, "modulate:a", 0.0, 0.84 if critical else 0.58).set_delay(0.12).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)
	tw.chain().tween_callback(_recycle_damage_label.bind(label))

func _recycle_damage_label(label: Label) -> void:
	label.hide(); label.scale = Vector2.ONE
	if not damage_label_pool.has(label): damage_label_pool.append(label)

func _take_damage_label() -> Label:
	while not damage_label_pool.is_empty():
		var label: Label = damage_label_pool.pop_back()
		if is_instance_valid(label): return label
	var replacement := _create_damage_label(); add_child(replacement); return replacement

func _create_damage_label() -> Label:
	var label := Label.new()
	label.name = "DamageNumber"; label.size = Vector2(95.0, 28.0)
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER; label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE; label.z_index = 1000
	label.add_theme_font_size_override("font_size", 17)
	label.add_theme_color_override("font_shadow_color", Color.BLACK)
	label.add_theme_constant_override("shadow_offset_x", 3)
	label.add_theme_constant_override("shadow_offset_y", 3)
	CJKFontTheme.apply_to(label)
	return label
