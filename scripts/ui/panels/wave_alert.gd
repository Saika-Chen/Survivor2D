extends Control
class_name WaveAlert
## WaveAlert：波次提示条，负责淡入淡出动画。

const DOTween := preload("res://scripts/utils/dotween.gd")
const CJKFontTheme := preload("res://scripts/ui/cjk_font_theme.gd")

@onready var label: Label = $Label

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	CJKFontTheme.apply_to_tree(self)
	hide()

func show_wave_alert(text: String, is_boss := false) -> void:
	label.text = text
	label.modulate = Color(1.0, 0.88, 0.36) if is_boss else Color(0.92, 0.84, 1.0)
	modulate.a = 1.0; show()
	DOTween.pop_in(self, self, 0.22, Vector2.ONE * 0.92, Vector2.ONE, "wave_alert_show")
	var hold := 2.2 if is_boss else 1.5
	var tw := DOTween.sequence(self, "wave_alert_hide"); tw.tween_interval(hold)
	tw.tween_property(self, "modulate:a", 0.0, 0.24).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)
	tw.tween_callback(func() -> void: hide())
