extends Control
class_name TalentPage

const CJKFontTheme := preload("res://scripts/ui/cjk_font_theme.gd")
const TextureFactory := preload("res://scripts/visuals/texture_factory.gd")
const BootstrapUIHelpers := preload("res://scripts/ui/bootstrap/bootstrap_ui_helpers.gd")

const TALENT_DATA := [
	{"id": "damage", "name": "攻击", "desc": "初始攻击倍率提升"},
	{"id": "health", "name": "生命", "desc": "初始最大生命提升"},
	{"id": "speed", "name": "移速", "desc": "初始移动速度提升"},
	{"id": "radius", "name": "范围", "desc": "武器范围提升"},
	{"id": "magnet", "name": "吸附", "desc": "拾取吸附范围提升"},
	{"id": "lifesteal_chance", "name": "吸血率", "desc": "武器吸血触发概率提升"},
	{"id": "lifesteal_amount", "name": "吸血量", "desc": "武器吸血回复量提升"},
	{"id": "crit_chance", "name": "暴击率", "desc": "攻击暴击概率提升"},
	{"id": "crit_damage", "name": "爆伤", "desc": "暴击伤害倍率提升"},
	{"id": "experience_gain", "name": "经验", "desc": "局内经验获取提升，最高 +50%"},
	{"id": "luck", "name": "幸运", "desc": "略微提高遗物出现率，最高 10"}
]

@onready var frame: TextureRect = $Frame
@onready var title_label: Label = $Content/Title
@onready var crystal_label: Label = $Content/CrystalLabel
@onready var button_column: VBoxContainer = $Content/TalentButtons
@onready var buttons: Array[Button] = [
	$Content/TalentButtons/DamageButton,
	$Content/TalentButtons/HealthButton,
	$Content/TalentButtons/SpeedButton,
	$Content/TalentButtons/RadiusButton,
	$Content/TalentButtons/MagnetButton,
	$Content/TalentButtons/LifestealChanceButton,
	$Content/TalentButtons/LifestealAmountButton,
	$Content/TalentButtons/CritChanceButton,
	$Content/TalentButtons/CritDamageButton,
	$Content/TalentButtons/ExperienceGainButton,
	$Content/TalentButtons/LuckButton
]

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	CJKFontTheme.apply_to_tree(self)
	frame.texture = TextureFactory.pixel_ui_asset("talent_frame")
	frame.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	frame.stretch_mode = TextureRect.STRETCH_SCALE
	frame.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_update_button_styles()
	_connect_button_signals()
	refresh()
	hide()

func refresh() -> void:
	crystal_label.text = "魔晶：%d" % RuntimeConfig.magic_crystals
	for index in range(TALENT_DATA.size()):
		var talent: Dictionary = TALENT_DATA[index]
		var talent_id := str(talent.get("id", ""))
		var button := buttons[index]
		var level := int(RuntimeConfig.talent_levels.get(talent_id, 0))
		var cost := RuntimeConfig.talent_cost(talent_id)
		var max_level := RuntimeConfig.talent_max_level(talent_id)
		var cap_text := " / %d" % max_level if max_level > 0 else ""
		button.text = "%s Lv.%d%s  消耗 %d 魔晶\n%s" % [
			str(talent.get("name", talent_id)),
			level,
			cap_text,
			cost,
			str(talent.get("desc", ""))
		]
		button.disabled = RuntimeConfig.magic_crystals < cost or (max_level > 0 and level >= max_level)

func _update_button_styles() -> void:
	for button in buttons:
		BootstrapUIHelpers.apply_pixel_button_style(button, TextureFactory.pixel_ui_asset("option_card"))
		button.custom_minimum_size = Vector2(0, 76)
		button.add_theme_font_size_override("font_size", 24)
		button.add_theme_color_override("font_color", Color(0.98, 0.94, 1.0, 1.0))
		button.add_theme_color_override("font_shadow_color", Color.BLACK)
		button.add_theme_constant_override("shadow_offset_x", 2)
		button.add_theme_constant_override("shadow_offset_y", 2)

func _connect_button_signals() -> void:
	for index in range(buttons.size()):
		var talent_id := str(TALENT_DATA[index].get("id", ""))
		buttons[index].pressed.connect(_upgrade_talent.bind(talent_id))

func _upgrade_talent(talent_id: String) -> void:
	RuntimeConfig.upgrade_talent(talent_id)
	refresh()
