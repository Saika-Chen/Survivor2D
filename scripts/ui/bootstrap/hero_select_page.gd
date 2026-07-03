extends Control
class_name HeroSelectPage

signal start_requested(hero_id: String)

const CJKFontTheme := preload("res://scripts/ui/cjk_font_theme.gd")
const DuelystTheme := preload("res://scripts/visuals/duelyst_theme.gd")
const HeroCatalog := preload("res://scripts/game/hero_catalog.gd")
const TextureFactory := preload("res://scripts/visuals/texture_factory.gd")
const BootstrapUIHelpers := preload("res://scripts/ui/bootstrap/bootstrap_ui_helpers.gd")
const TalentPage := preload("res://scripts/ui/bootstrap/talent_page.gd")
const CodexPage := preload("res://scripts/ui/bootstrap/codex_page.gd")

@onready var menu_pixel_frame: TextureRect = $MenuFrame
@onready var title_label: Label = $Layout/Title
@onready var hero_tab_button: Button = $Layout/TabRow/HeroTabButton
@onready var talent_tab_button: Button = $Layout/TabRow/TalentTabButton
@onready var codex_tab_button: Button = $Layout/TabRow/CodexTabButton
@onready var hero_content: Control = $Layout/PageArea/HeroContent
@onready var hero_list_scroll: ScrollContainer = $Layout/PageArea/HeroContent/HeroLayout/MainRow/HeroListScroll
@onready var hero_list: VBoxContainer = $Layout/PageArea/HeroContent/HeroLayout/MainRow/HeroListScroll/HeroList
@onready var hero_preview: AnimatedSprite2D = $Layout/PageArea/HeroContent/HeroLayout/MainRow/PreviewPanel/HeroPreview
@onready var hero_detail_icon: AnimatedSprite2D = $Layout/PageArea/HeroContent/HeroLayout/DetailRow/DetailIconHolder/HeroDetailIcon
@onready var detail_label: Label = $Layout/PageArea/HeroContent/HeroLayout/DetailRow/DetailLabel
@onready var start_button: Button = $Layout/StartButton
@onready var talent_page: TalentPage = $Layout/PageArea/TalentPage
@onready var codex_page: CodexPage = $Layout/PageArea/CodexPage
@onready var talent_pixel_frame: TextureRect = $Layout/PageArea/TalentPage/Frame

var hero_buttons: Array[Button] = []
var selected_hero_id := "blood_knight"

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	CJKFontTheme.apply_to_tree(self)
	menu_pixel_frame.texture = TextureFactory.pixel_ui_asset("menu_frame")
	menu_pixel_frame.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	menu_pixel_frame.stretch_mode = TextureRect.STRETCH_SCALE
	menu_pixel_frame.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_update_tab_styles()
	_connect_tabs()
	_build_hero_list()
	selected_hero_id = RuntimeConfig.selected_hero_id
	if selected_hero_id.is_empty():
		selected_hero_id = "blood_knight"
	select_hero(selected_hero_id)
	_show_hero_tab()
	hide()

func select_hero(hero_id: String) -> void:
	selected_hero_id = hero_id
	var hero := HeroCatalog.find(hero_id)
	detail_label.text = "%s\n定位：%s\n初始武器：%s\n特性：%s" % [
		hero.get("name", ""),
		hero.get("role", ""),
		BootstrapUIHelpers.weapon_title(str(hero.get("initial_weapon", ""))),
		hero.get("special", "")
	]
	BootstrapUIHelpers.set_icon_sprite(hero_detail_icon, str(hero.get("initial_weapon", "")), 64.0)
	var style := DuelystTheme.player_style(hero)
	hero_preview.sprite_frames = style.get("frames", null)
	hero_preview.scale = Vector2.ONE * float(style.get("scale", 1.0)) * 1.42
	hero_preview.position = Vector2(110, 330) + style.get("offset", Vector2.ZERO) * 1.5
	DuelystTheme.play_animation(hero_preview, ["idle", "breathing", "run"], true)
	for button in hero_buttons:
		button.modulate = Color(1, 1, 1, 1)
	for index in range(HeroCatalog.list().size()):
		if str(HeroCatalog.list()[index].get("id", "")) == hero_id and index < hero_buttons.size():
			hero_buttons[index].modulate = Color(1.0, 0.86, 0.42, 1.0)

func _build_hero_list() -> void:
	for child in hero_list.get_children():
		child.queue_free()
	hero_buttons.clear()
	for hero in HeroCatalog.list():
		var button := Button.new()
		button.text = "      %s  |  初始：%s" % [
			hero.get("name", ""),
			BootstrapUIHelpers.weapon_title(str(hero.get("initial_weapon", "")))
		]
		button.custom_minimum_size = Vector2(0, 72)
		button.alignment = HORIZONTAL_ALIGNMENT_LEFT
		button.add_theme_font_size_override("font_size", 22)
		button.add_theme_color_override("font_color", Color(0.95, 0.98, 1.0, 1.0))
		button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		BootstrapUIHelpers.apply_pixel_button_style(button, TextureFactory.pixel_ui_asset("option_card"))
		_set_button_icon(button, str(hero.get("initial_weapon", "")), 44.0)
		button.pressed.connect(_select_hero.bind(str(hero.get("id", ""))))
		hero_list.add_child(button)
		hero_buttons.append(button)
	CJKFontTheme.apply_to_tree(hero_list)

func _select_hero(hero_id: String) -> void:
	select_hero(hero_id)

func _start_game() -> void:
	start_requested.emit(selected_hero_id)

func _connect_tabs() -> void:
	hero_tab_button.pressed.connect(_show_hero_tab)
	talent_tab_button.pressed.connect(_show_talent_tab)
	codex_tab_button.pressed.connect(_show_codex_tab)
	start_button.pressed.connect(_start_game)

func _update_tab_styles() -> void:
	for button in [hero_tab_button, talent_tab_button, codex_tab_button, start_button]:
		BootstrapUIHelpers.apply_pixel_button_style(button, TextureFactory.pixel_ui_asset("option_card"))
		button.add_theme_font_size_override("font_size", 26 if button != start_button else 30)
		button.add_theme_color_override("font_color", Color(0.98, 0.94, 1.0, 1.0))
		button.add_theme_color_override("font_shadow_color", Color.BLACK)
		button.add_theme_constant_override("shadow_offset_x", 2)
		button.add_theme_constant_override("shadow_offset_y", 2)
		button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		if button == start_button:
			button.custom_minimum_size = Vector2(0, 72)
		else:
			button.custom_minimum_size = Vector2(0, 54)

func _show_hero_tab() -> void:
	hero_content.show()
	talent_page.hide()
	codex_page.hide()
	hero_tab_button.modulate = Color(1.0, 0.86, 0.42, 1.0)
	talent_tab_button.modulate = Color(1.0, 1.0, 1.0, 1.0)
	codex_tab_button.modulate = Color(1.0, 1.0, 1.0, 1.0)

func _show_talent_tab() -> void:
	hero_content.hide()
	codex_page.hide()
	talent_page.show()
	talent_page.refresh()
	hero_tab_button.modulate = Color(1.0, 1.0, 1.0, 1.0)
	talent_tab_button.modulate = Color(1.0, 0.86, 0.42, 1.0)
	codex_tab_button.modulate = Color(1.0, 1.0, 1.0, 1.0)

func _show_codex_tab() -> void:
	hero_content.hide()
	talent_page.hide()
	codex_page.show()
	hero_tab_button.modulate = Color(1.0, 1.0, 1.0, 1.0)
	talent_tab_button.modulate = Color(1.0, 1.0, 1.0, 1.0)
	codex_tab_button.modulate = Color(1.0, 0.86, 0.42, 1.0)

func _set_button_icon(button: Button, item_id: String, icon_size: float) -> void:
	var icon := AnimatedSprite2D.new()
	icon.name = "Icon"
	icon.centered = true
	icon.position = Vector2(34, 36)
	icon.z_index = 20
	button.add_child(icon)
	BootstrapUIHelpers.set_icon_sprite(icon, item_id, icon_size)
