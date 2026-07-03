extends Control
class_name ContractCard
## ContractCard：显示战斗中的契约进度。

const CJKFontTheme := preload("res://scripts/ui/cjk_font_theme.gd")
const TextureFactory := preload("res://scripts/visuals/texture_factory.gd")

@onready var frame: TextureRect = $Frame
@onready var title_label: Label = $Title
@onready var objective_label: Label = $Objective
@onready var progress_label: Label = $Progress
@onready var reward_label: Label = $Reward

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	z_index = 120
	CJKFontTheme.apply_to_tree(self)
	frame.texture = TextureFactory.pixel_ui_asset("option_card")
	hide()

func set_contract_card(contract: Dictionary) -> void:
	if contract.is_empty(): hide(); return
	show()
	title_label.text = str(contract.get("title", "契约"))
	objective_label.text = str(contract.get("objective", "契约目标"))
	progress_label.text = "进度 %s" % str(contract.get("progress_text", "0/0"))
	var status := str(contract.get("status_text", ""))
	var reward := str(contract.get("reward_text", ""))
	reward_label.text = reward if status == "" else "%s\n%s" % [reward, status]
	frame.modulate = contract.get("accent", Color(0.72, 0.92, 1.0, 0.92))
