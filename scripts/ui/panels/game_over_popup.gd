extends Control
class_name GameOverPopup
## GameOverPopup：游戏结束/通关弹窗，提供重开和返回主菜单按钮。

const CJKFontTheme := preload("res://scripts/ui/cjk_font_theme.gd")

signal restart_requested
signal main_menu_requested

@onready var restart_button: Button = $RestartButton
@onready var main_menu_button: Button = $MainMenuButton

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	CJKFontTheme.apply_to_tree(self)
	hide()
	restart_button.pressed.connect(func(): restart_requested.emit())
	main_menu_button.pressed.connect(func(): main_menu_requested.emit())
