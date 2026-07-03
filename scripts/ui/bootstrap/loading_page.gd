extends Control
class_name LoadingPage

const CJKFontTheme := preload("res://scripts/ui/cjk_font_theme.gd")

@onready var background: TextureRect = $Background
@onready var title_label: Label = $Center/Card/Margin/Content/Title
@onready var status_label: Label = $Center/Card/Margin/Content/Status
@onready var progress_bar: ProgressBar = $Center/Card/Margin/Content/ProgressBar
@onready var progress_label: Label = $Center/Card/Margin/Content/ProgressLabel

var total_steps := 1

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	CJKFontTheme.apply_to_tree(self)
	background.texture = preload("res://ui/loadingbg.png")
	background.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	background.stretch_mode = TextureRect.STRETCH_SCALE
	background.mouse_filter = Control.MOUSE_FILTER_IGNORE
	title_label.text = "深渊幸存者"
	status_label.text = "准备加载..."
	progress_bar.max_value = 1
	progress_bar.value = 0
	progress_label.text = "0 / 0"

func configure(total: int, status_text: String) -> void:
	total_steps = max(1, total)
	progress_bar.max_value = total_steps
	set_status(status_text)
	set_progress(0)

func set_status(text: String) -> void:
	status_label.text = text

func set_progress(current: int) -> void:
	progress_bar.value = clamp(current, 0, total_steps)
	progress_label.text = "%d / %d" % [clamp(current, 0, total_steps), total_steps]

func finish() -> void:
	set_progress(total_steps)

