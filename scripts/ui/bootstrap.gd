extends Control

const HeroCatalog := preload("res://scripts/game/hero_catalog.gd")
const DuelystTheme := preload("res://scripts/visuals/duelyst_theme.gd")
const CJKFontTheme := preload("res://scripts/ui/cjk_font_theme.gd")
const TextureFactory := preload("res://scripts/visuals/texture_factory.gd")

var preload_paths: Array[String] = []
var preload_index := 0
var selected_hero_id := "blood_knight"
var progress_bar: ProgressBar
var status_label: Label
var loading_panel: VBoxContainer
var select_panel: VBoxContainer
var detail_label: Label
var start_button: Button
var hero_buttons: Array[Button] = []
var hero_preview_area: Control
var hero_preview: AnimatedSprite2D
var hero_detail_icon: AnimatedSprite2D
var hero_tab_button: Button
var talent_tab_button: Button
var codex_tab_button: Button
var hero_content: Control
var talent_panel: VBoxContainer
var codex_panel: ScrollContainer
var crystal_label: Label
var menu_pixel_frame: TextureRect
var talent_pixel_frame: TextureRect

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_build_loading_ui()
	CJKFontTheme.apply_to_tree(self)
	preload_paths = _unique_paths(HeroCatalog.asset_paths() + DuelystTheme.preload_asset_paths() + [
		CJKFontTheme.FONT_PATH,
		"res://scenes/main/Main.tscn",
		"res://scenes/enemy/Enemy.tscn",
		"res://scenes/projectile/Projectile.tscn",
		"res://scenes/projectile/EnemyProjectile.tscn",
		"res://scenes/effects/WeaponZone.tscn",
		"res://scenes/effects/ParticleBurst.tscn",
		"res://scenes/xp/XPGem.tscn",
		"res://scenes/pickups/PickupItem.tscn"
	])
	status_label.text = "正在预加载角色、怪物、武器特效..."
	progress_bar.max_value = max(1, preload_paths.size())

func _process(_delta: float) -> void:
	if preload_index >= preload_paths.size():
		set_process(false)
		_show_hero_select()
		return
	var path := preload_paths[preload_index]
	if ResourceLoader.exists(path):
		load(path)
	preload_index += 1
	progress_bar.value = preload_index
	status_label.text = "加载资源 %d / %d" % [preload_index, preload_paths.size()]

func _build_loading_ui() -> void:
	anchors_preset = Control.PRESET_FULL_RECT
	var background := ColorRect.new()
	background.color = Color(0.025, 0.018, 0.032, 1.0)
	background.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(background)

	loading_panel = VBoxContainer.new()
	loading_panel.anchor_left = 0.12
	loading_panel.anchor_right = 0.88
	loading_panel.anchor_top = 0.34
	loading_panel.anchor_bottom = 0.62
	loading_panel.add_theme_constant_override("separation", 16)
	add_child(loading_panel)

	var title := Label.new()
	title.text = "深渊幸存者"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 40)
	title.add_theme_color_override("font_color", Color(1.0, 0.92, 0.58, 1.0))
	loading_panel.add_child(title)

	status_label = Label.new()
	status_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	status_label.add_theme_font_size_override("font_size", 20)
	status_label.add_theme_color_override("font_color", Color(0.88, 0.96, 1.0, 1.0))
	loading_panel.add_child(status_label)

	progress_bar = ProgressBar.new()
	progress_bar.custom_minimum_size = Vector2(0, 24)
	progress_bar.show_percentage = true
	loading_panel.add_child(progress_bar)

func _show_hero_select() -> void:
	loading_panel.hide()
	menu_pixel_frame = _new_pixel_frame("HeroMenuFrame", TextureFactory.pixel_ui_asset("menu_frame"))
	menu_pixel_frame.anchor_left = 0.04
	menu_pixel_frame.anchor_right = 0.96
	menu_pixel_frame.anchor_top = 0.035
	menu_pixel_frame.anchor_bottom = 0.97
	select_panel = VBoxContainer.new()
	select_panel.anchor_left = 0.06
	select_panel.anchor_right = 0.94
	select_panel.anchor_top = 0.06
	select_panel.anchor_bottom = 0.96
	select_panel.add_theme_constant_override("separation", 12)
	add_child(select_panel)

	var title := Label.new()
	title.text = "选择英雄"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 42)
	title.add_theme_color_override("font_color", Color(1.0, 0.88, 0.36, 1.0))
	select_panel.add_child(title)

	var tabs := HBoxContainer.new()
	tabs.add_theme_constant_override("separation", 10)
	select_panel.add_child(tabs)
	hero_tab_button = Button.new()
	hero_tab_button.text = "英雄"
	hero_tab_button.custom_minimum_size = Vector2(0, 54)
	hero_tab_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	hero_tab_button.add_theme_font_size_override("font_size", 26)
	hero_tab_button.pressed.connect(_show_hero_tab)
	_apply_pixel_button_style(hero_tab_button, TextureFactory.pixel_ui_asset("option_card"))
	tabs.add_child(hero_tab_button)
	talent_tab_button = Button.new()
	talent_tab_button.text = "天赋"
	talent_tab_button.custom_minimum_size = Vector2(0, 54)
	talent_tab_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	talent_tab_button.add_theme_font_size_override("font_size", 26)
	talent_tab_button.pressed.connect(_show_talent_tab)
	_apply_pixel_button_style(talent_tab_button, TextureFactory.pixel_ui_asset("option_card"))
	tabs.add_child(talent_tab_button)
	codex_tab_button = Button.new()
	codex_tab_button.text = "图鉴"
	codex_tab_button.custom_minimum_size = Vector2(0, 54)
	codex_tab_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	codex_tab_button.add_theme_font_size_override("font_size", 26)
	codex_tab_button.pressed.connect(_show_codex_tab)
	_apply_pixel_button_style(codex_tab_button, TextureFactory.pixel_ui_asset("option_card"))
	tabs.add_child(codex_tab_button)

	hero_content = VBoxContainer.new()
	hero_content.size_flags_vertical = Control.SIZE_EXPAND_FILL
	select_panel.add_child(hero_content)

	var chooser_row := HBoxContainer.new()
	chooser_row.custom_minimum_size = Vector2(0, 660)
	chooser_row.size_flags_vertical = Control.SIZE_EXPAND_FILL
	chooser_row.add_theme_constant_override("separation", 14)
	hero_content.add_child(chooser_row)

	var scroll := ScrollContainer.new()
	scroll.custom_minimum_size = Vector2(0, 660)
	scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	chooser_row.add_child(scroll)

	var list_box := VBoxContainer.new()
	list_box.add_theme_constant_override("separation", 8)
	scroll.add_child(list_box)

	for hero in HeroCatalog.list():
		var button := Button.new()
		button.text = "      %s  |  初始：%s" % [hero.get("name", ""), _weapon_title(str(hero.get("initial_weapon", "")))]
		button.custom_minimum_size = Vector2(0, 72)
		button.alignment = HORIZONTAL_ALIGNMENT_LEFT
		button.add_theme_font_size_override("font_size", 22)
		button.add_theme_color_override("font_color", Color(0.95, 0.98, 1.0, 1.0))
		button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		_apply_pixel_button_style(button, TextureFactory.pixel_ui_asset("option_card"))
		_set_button_icon(button, str(hero.get("initial_weapon", "")), 44.0)
		button.pressed.connect(_select_hero.bind(str(hero.get("id", ""))))
		list_box.add_child(button)
		hero_buttons.append(button)

	hero_preview_area = Panel.new()
	hero_preview_area.custom_minimum_size = Vector2(220, 660)
	chooser_row.add_child(hero_preview_area)

	var preview_title := Label.new()
	preview_title.text = "英雄预览"
	preview_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	preview_title.add_theme_font_size_override("font_size", 24)
	preview_title.add_theme_color_override("font_color", Color(1.0, 0.9, 0.48, 1.0))
	preview_title.offset_left = 12
	preview_title.offset_top = 16
	preview_title.offset_right = 208
	preview_title.offset_bottom = 48
	hero_preview_area.add_child(preview_title)

	hero_preview = AnimatedSprite2D.new()
	hero_preview.centered = true
	hero_preview.position = Vector2(110, 300)
	hero_preview.scale = Vector2.ONE * 2.2
	hero_preview_area.add_child(hero_preview)

	var detail_row := HBoxContainer.new()
	detail_row.custom_minimum_size = Vector2(0, 104)
	detail_row.add_theme_constant_override("separation", 10)
	hero_content.add_child(detail_row)
	var detail_icon_holder := Control.new()
	detail_icon_holder.custom_minimum_size = Vector2(76, 96)
	detail_row.add_child(detail_icon_holder)
	hero_detail_icon = AnimatedSprite2D.new()
	hero_detail_icon.name = "HeroDetailIcon"
	hero_detail_icon.centered = true
	hero_detail_icon.position = Vector2(38, 48)
	detail_icon_holder.add_child(hero_detail_icon)
	detail_label = Label.new()
	detail_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	detail_label.add_theme_font_size_override("font_size", 22)
	detail_label.add_theme_color_override("font_color", Color(0.88, 1.0, 0.92, 1.0))
	detail_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	detail_row.add_child(detail_label)

	_build_talent_panel()
	_build_codex_panel()

	start_button = Button.new()
	start_button.text = "开始游戏"
	start_button.custom_minimum_size = Vector2(0, 72)
	start_button.add_theme_font_size_override("font_size", 30)
	_apply_pixel_button_style(start_button, TextureFactory.pixel_ui_asset("option_card"))
	start_button.pressed.connect(_start_game)
	select_panel.add_child(start_button)
	CJKFontTheme.apply_to_tree(select_panel)
	_select_hero(selected_hero_id)
	_show_hero_tab()

func _select_hero(hero_id: String) -> void:
	selected_hero_id = hero_id
	var hero := HeroCatalog.find(hero_id)
	detail_label.text = "%s\n定位：%s\n初始武器：%s\n特性：%s" % [hero.get("name", ""), hero.get("role", ""), _weapon_title(str(hero.get("initial_weapon", ""))), hero.get("special", "")]
	_set_icon_sprite(hero_detail_icon, str(hero.get("initial_weapon", "")), 64.0)
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

func _start_game() -> void:
	RuntimeConfig.select_hero(selected_hero_id)
	get_tree().change_scene_to_file("res://scenes/main/Main.tscn")

func _build_talent_panel() -> void:
	talent_panel = VBoxContainer.new()
	talent_panel.size_flags_vertical = Control.SIZE_EXPAND_FILL
	talent_panel.add_theme_constant_override("separation", 10)
	select_panel.add_child(talent_panel)
	talent_pixel_frame = _new_pixel_frame("TalentFrame", TextureFactory.pixel_ui_asset("talent_frame"))
	talent_pixel_frame.anchor_left = 0.08
	talent_pixel_frame.anchor_right = 0.92
	talent_pixel_frame.anchor_top = 0.18
	talent_pixel_frame.anchor_bottom = 0.82
	talent_pixel_frame.hide()
	crystal_label = Label.new()
	crystal_label.add_theme_font_size_override("font_size", 28)
	crystal_label.add_theme_color_override("font_color", Color(0.86, 0.62, 1.0, 1.0))
	talent_panel.add_child(crystal_label)
	var talent_data := [
		["damage", "攻击", "初始攻击倍率提升"],
		["health", "生命", "初始最大生命提升"],
		["speed", "移速", "初始移动速度提升"],
		["radius", "范围", "武器范围提升"],
		["magnet", "吸附", "拾取吸附范围提升"],
		["lifesteal_chance", "吸血率", "武器吸血触发概率提升"],
		["lifesteal_amount", "吸血量", "武器吸血回复量提升"],
		["crit_chance", "暴击率", "攻击暴击概率提升"],
		["crit_damage", "爆伤", "暴击伤害倍率提升"],
		["experience_gain", "经验", "局内经验获取提升，最高 +50%"],
		["luck", "幸运", "略微提高遗物出现率，最高 10"]
	]
	for item in talent_data:
		var talent_id := str(item[0])
		var button := Button.new()
		button.custom_minimum_size = Vector2(0, 76)
		button.add_theme_font_size_override("font_size", 24)
		_apply_pixel_button_style(button, TextureFactory.pixel_ui_asset("option_card"))
		button.pressed.connect(_upgrade_talent.bind(talent_id))
		talent_panel.add_child(button)
	_update_talent_panel()

func _show_hero_tab() -> void:
	if hero_content != null:
		hero_content.show()
	if talent_panel != null:
		talent_panel.hide()
	if codex_panel != null:
		codex_panel.hide()
	if talent_pixel_frame != null:
		talent_pixel_frame.hide()
	hero_tab_button.modulate = Color(1.0, 0.86, 0.42, 1.0)
	talent_tab_button.modulate = Color(1.0, 1.0, 1.0, 1.0)
	codex_tab_button.modulate = Color(1.0, 1.0, 1.0, 1.0)

func _show_talent_tab() -> void:
	if hero_content != null:
		hero_content.hide()
	if talent_panel != null:
		talent_panel.show()
	if codex_panel != null:
		codex_panel.hide()
	if talent_pixel_frame != null:
		talent_pixel_frame.show()
	_update_talent_panel()
	hero_tab_button.modulate = Color(1.0, 1.0, 1.0, 1.0)
	talent_tab_button.modulate = Color(1.0, 0.86, 0.42, 1.0)
	codex_tab_button.modulate = Color(1.0, 1.0, 1.0, 1.0)

func _show_codex_tab() -> void:
	if hero_content != null:
		hero_content.hide()
	if talent_panel != null:
		talent_panel.hide()
	if codex_panel != null:
		codex_panel.show()
	if talent_pixel_frame != null:
		talent_pixel_frame.show()
	hero_tab_button.modulate = Color(1.0, 1.0, 1.0, 1.0)
	talent_tab_button.modulate = Color(1.0, 1.0, 1.0, 1.0)
	codex_tab_button.modulate = Color(1.0, 0.86, 0.42, 1.0)

func _upgrade_talent(talent_id: String) -> void:
	RuntimeConfig.upgrade_talent(talent_id)
	_update_talent_panel()

func _update_talent_panel() -> void:
	if talent_panel == null or crystal_label == null:
		return
	crystal_label.text = "魔晶：%d" % RuntimeConfig.magic_crystals
	var names := {"damage": "攻击", "health": "生命", "speed": "移速", "radius": "范围", "magnet": "吸附", "lifesteal_chance": "吸血率", "lifesteal_amount": "吸血量", "crit_chance": "暴击率", "crit_damage": "爆伤", "experience_gain": "经验", "luck": "幸运"}
	var descs := {"damage": "每级攻击 +3.5%", "health": "每级生命 +18", "speed": "每级移速 +7", "radius": "每级范围 +2.5%", "magnet": "每级吸附 +12", "lifesteal_chance": "每级吸血率 +2%", "lifesteal_amount": "每级吸血量 +2", "crit_chance": "每级暴击率 +2%", "crit_damage": "每级爆伤 +10%", "experience_gain": "每级经验 +5%，最高 +50%", "luck": "每级幸运 +1，最高 10"}
	var button_index := 1
	for talent_id in ["damage", "health", "speed", "radius", "magnet", "lifesteal_chance", "lifesteal_amount", "crit_chance", "crit_damage", "experience_gain", "luck"]:
		if button_index >= talent_panel.get_child_count():
			break
		var button := talent_panel.get_child(button_index) as Button
		var level := int(RuntimeConfig.talent_levels.get(talent_id, 0))
		var cost := RuntimeConfig.talent_cost(talent_id)
		var max_level := RuntimeConfig.talent_max_level(talent_id)
		var cap_text := " / %d" % max_level if max_level > 0 else ""
		button.text = "%s Lv.%d%s  消耗 %d 魔晶\n%s" % [names[talent_id], level, cap_text, cost, descs[talent_id]]
		button.disabled = RuntimeConfig.magic_crystals < cost or (max_level > 0 and level >= max_level)
		button_index += 1

func _build_codex_panel() -> void:
	codex_panel = ScrollContainer.new()
	codex_panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	codex_panel.size_flags_vertical = Control.SIZE_EXPAND_FILL
	codex_panel.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	select_panel.add_child(codex_panel)
	var content := VBoxContainer.new()
	content.name = "CodexContent"
	content.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	content.size_flags_vertical = Control.SIZE_EXPAND_FILL
	content.add_theme_constant_override("separation", 12)
	codex_panel.add_child(content)
	_add_codex_section(content, "武器", [], _weapon_codex_items())
	_add_codex_section(content, "遗物与普通奖励", [], _relic_and_reward_codex_items())
	_add_codex_section(content, "怪物与精英", [
		"普通怪群：追击、射击、冲撞、分裂、爆破等类型。",
		"精英：可能带镜像、压制、召唤、冲锋、护盾等能力。",
		"Boss：每10波出现，拥有不同战斗机制。"
	])
	_add_codex_section(content, "合成表与羁绊", [
		"血咒弹 + 鲜血契约 = 猩红审判。",
		"幽魂环刃 + 幽魂核心 = 亡魂风暴。",
		"暗影地刺 + 深渊印记 = 深渊尖啸。",
		"灵火新星 + 余烬王冠 = 灭魂日冕。",
		"毁灭激光 + 毁灭透镜 = 虚空长枪。",
		"瘟疫炸弹 + 火药心脏 = 坟场迫击炮。",
		"深渊触手 + 邪神之眼 = 旧日之握。",
		"穿魂镰刃 + 骨质轮轴 = 死神回廊。",
		"幽冥僚机 + 机心圣核 = 炽天使蜂群。",
		"寒星法球 + 霜心棱镜 = 冰墓彗星。",
		"雷链符文 + 风暴图腾 = 风暴王冠。",
		"虚空地雷 + 虚空锚点 = 事件视界。",
		"同标签武器与遗物可激活羁绊。"
	])
	CJKFontTheme.apply_to_tree(codex_panel)
	codex_panel.hide()

func _add_codex_section(parent: VBoxContainer, title_text: String, lines: Array, entries: Array = []) -> void:
	var card := PanelContainer.new()
	card.custom_minimum_size = Vector2(0.0, 140.0)
	card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	card.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
	var style := StyleBoxTexture.new()
	style.texture = TextureFactory.pixel_ui_asset("option_card")
	style.texture_margin_left = 24
	style.texture_margin_right = 24
	style.texture_margin_top = 24
	style.texture_margin_bottom = 24
	style.axis_stretch_horizontal = StyleBoxTexture.AXIS_STRETCH_MODE_TILE
	style.axis_stretch_vertical = StyleBoxTexture.AXIS_STRETCH_MODE_TILE
	style.content_margin_left = 18
	style.content_margin_right = 18
	style.content_margin_top = 14
	style.content_margin_bottom = 14
	card.add_theme_stylebox_override("panel", style)
	var content := VBoxContainer.new()
	content.name = "Content"
	content.add_theme_constant_override("separation", 10)
	card.add_child(content)
	var label := Label.new()
	label.name = "Title"
	label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.add_theme_font_size_override("font_size", 22)
	label.add_theme_color_override("font_color", Color(0.92, 1.0, 0.94, 1.0))
	label.text = title_text if entries.size() > 0 else "%s\n%s" % [title_text, "\n".join(lines)]
	content.add_child(label)
	if entries.size() > 0:
		var icon_grid := GridContainer.new()
		icon_grid.name = "ItemGrid"
		icon_grid.columns = 1
		icon_grid.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		icon_grid.add_theme_constant_override("h_separation", 0)
		icon_grid.add_theme_constant_override("v_separation", 8)
		content.add_child(icon_grid)
		for entry_variant in entries:
			var entry: Dictionary = entry_variant
			var item_id := str(entry.get("id", ""))
			var holder := HBoxContainer.new()
			holder.custom_minimum_size = Vector2(0, 82)
			holder.add_theme_constant_override("separation", 12)
			holder.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			var icon_holder := Control.new()
			icon_holder.name = "IconHolder"
			icon_holder.custom_minimum_size = Vector2(66, 66)
			holder.add_child(icon_holder)
			var icon := AnimatedSprite2D.new()
			icon.name = "Icon"
			icon.centered = true
			icon.position = Vector2(33, 33)
			icon_holder.add_child(icon)
			_set_icon_sprite(icon, item_id, 54.0)
			var text_box := VBoxContainer.new()
			text_box.name = "Text"
			text_box.add_theme_constant_override("separation", 2)
			text_box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			holder.add_child(text_box)
			var name_label := Label.new()
			name_label.name = "NameLabel"
			name_label.text = str(entry.get("name", item_id))
			name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
			name_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
			name_label.clip_text = true
			name_label.add_theme_font_size_override("font_size", 17)
			name_label.add_theme_color_override("font_color", Color(1.0, 0.92, 0.50, 1.0))
			text_box.add_child(name_label)
			var desc_label := Label.new()
			desc_label.name = "DescriptionLabel"
			desc_label.text = str(entry.get("description", ""))
			desc_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
			desc_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
			desc_label.clip_text = true
			desc_label.add_theme_font_size_override("font_size", 14)
			desc_label.add_theme_color_override("font_color", Color(0.88, 0.96, 1.0, 1.0))
			text_box.add_child(desc_label)
			icon_grid.add_child(holder)
	parent.add_child(card)

func _weapon_icon_ids() -> Array[String]:
	return ["blood_bolt", "ghost_blades", "shadow_spikes", "soul_nova", "doom_laser", "plague_bomb", "abyss_tentacle", "reaping_scythe", "grave_familiar", "frost_orb", "thunder_chain", "void_mines"]

func _relic_and_reward_icon_ids() -> Array[String]:
	return ["blood_pact", "spirit_core", "abyss_mark", "ember_crown", "lens_of_ruin", "powder_heart", "eldritch_eye", "bone_wheel", "clockwork_heart", "frost_heart", "storm_totem", "void_anchor", "stat:damage", "stat:crit_chance", "stat:cooldown", "stat:radius", "stat:heal", "stat:nothing"]

func _weapon_codex_items() -> Array[Dictionary]:
	var descriptions := {
		"blood_bolt": "追踪血弹，命中后可弹射并引爆小范围伤害。",
		"ghost_blades": "环形幽刃持续切割身边敌人，适合贴身清怪。",
		"shadow_spikes": "在敌群脚下爆出暗影地刺，范围大但节奏较慢。",
		"soul_nova": "周期性释放灵火新星，覆盖大范围近身威胁。",
		"doom_laser": "贯穿直线激光，适合处理成排敌人和 Boss。",
		"plague_bomb": "投出瘟疫爆弹，爆炸区带减速与群体伤害。",
		"abyss_tentacle": "召出深渊触手抓击附近目标，压制贴脸敌人。",
		"reaping_scythe": "穿魂镰刃绕场飞行，可弹射并制造爆裂伤害。",
		"grave_familiar": "幽冥僚机会环绕玩家并主动开火。",
		"frost_orb": "寒星法球追击敌人，带爆裂与减速能力。",
		"thunder_chain": "雷链符文在目标附近跳跃打击，适合清散兵。",
		"void_mines": "虚空地雷布置在周围，敌人靠近时爆发。"
	}
	var items: Array[Dictionary] = []
	for weapon_id in _weapon_icon_ids():
		items.append({"id": weapon_id, "name": _weapon_title(weapon_id), "description": descriptions.get(weapon_id, "")})
	return items

func _relic_and_reward_codex_items() -> Array[Dictionary]:
	return [
		{"id": "blood_pact", "name": "鲜血契约", "description": "提高攻击与吸血，血系武器的进化钥匙。"},
		{"id": "spirit_core", "name": "幽魂核心", "description": "增强灵体武器，帮助幽魂环刃进化。"},
		{"id": "abyss_mark", "name": "深渊印记", "description": "强化深渊伤害，让暗影地刺获得进化条件。"},
		{"id": "ember_crown", "name": "余烬王冠", "description": "提高火焰爆发，灵火新星的核心遗物。"},
		{"id": "lens_of_ruin", "name": "毁灭透镜", "description": "提升弹速与爆伤，毁灭激光的进化组件。"},
		{"id": "powder_heart", "name": "火药心脏", "description": "增强爆炸系伤害，支撑瘟疫炸弹进化。"},
		{"id": "eldritch_eye", "name": "邪神之眼", "description": "扩大深渊控制范围，触手武器的关键遗物。"},
		{"id": "bone_wheel", "name": "骨质轮轴", "description": "提高旋刃输出，穿魂镰刃的进化部件。"},
		{"id": "clockwork_heart", "name": "机心圣核", "description": "提高移动与弹速，幽冥僚机的进化核心。"},
		{"id": "frost_heart", "name": "霜心棱镜", "description": "提升冰霜范围与弹速，寒星法球的进化钥匙。"},
		{"id": "storm_totem", "name": "风暴图腾", "description": "增强雷系连锁，雷链符文的进化组件。"},
		{"id": "void_anchor", "name": "虚空锚点", "description": "强化虚空区域，虚空地雷的进化遗物。"},
		{"id": "stat:damage", "name": "攻击", "description": "直接提高全武器伤害。"},
		{"id": "stat:crit_chance", "name": "暴击", "description": "提高暴击率，适合高频武器。"},
		{"id": "stat:cooldown", "name": "冷却", "description": "缩短攻击间隔，让武器更频繁触发。"},
		{"id": "stat:radius", "name": "范围", "description": "扩大非终极武器的影响范围。"},
		{"id": "stat:heal", "name": "治疗", "description": "立即回复一部分最大生命。"},
		{"id": "stat:nothing", "name": "空响", "description": "没有直接收益，但保留下一次好运的余味。"}
	]

func _set_button_icon(button: Button, item_id: String, icon_size: float) -> void:
	var icon := AnimatedSprite2D.new()
	icon.name = "Icon"
	icon.centered = true
	icon.position = Vector2(34, 36)
	icon.z_index = 20
	button.add_child(icon)
	_set_icon_sprite(icon, item_id, icon_size)

func _set_icon_sprite(icon: AnimatedSprite2D, item_id: String, icon_size: float) -> void:
	var frames := TextureFactory.item_icon_frames(item_id)
	if frames == null:
		icon.hide()
		return
	icon.sprite_frames = frames
	icon.scale = Vector2.ONE * (icon_size / 96.0)
	var names := frames.get_animation_names()
	if not names.is_empty():
		icon.play(str(names[0]))
	icon.show()

func _new_pixel_frame(node_name: String, texture: Texture2D) -> TextureRect:
	var frame := TextureRect.new()
	frame.name = node_name
	frame.texture = texture
	frame.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	frame.stretch_mode = TextureRect.STRETCH_SCALE
	frame.modulate = Color(1.0, 1.0, 1.0, 0.94)
	add_child(frame)
	move_child(frame, 1)
	return frame

func _apply_pixel_button_style(button: Button, texture: Texture2D) -> void:
	var style := StyleBoxTexture.new()
	style.texture = texture
	# 9-patch: use the middle of the texture for stretch, keep corners crisp
	style.texture_margin_left = 24
	style.texture_margin_right = 24
	style.texture_margin_top = 24
	style.texture_margin_bottom = 24
	style.axis_stretch_horizontal = StyleBoxTexture.AXIS_STRETCH_MODE_TILE
	style.axis_stretch_vertical = StyleBoxTexture.AXIS_STRETCH_MODE_TILE
	style.content_margin_left = 18
	style.content_margin_right = 18
	style.content_margin_top = 10
	style.content_margin_bottom = 10
	button.add_theme_stylebox_override("normal", style)
	button.add_theme_stylebox_override("hover", style)
	button.add_theme_stylebox_override("pressed", style)
	button.add_theme_stylebox_override("focus", style)

func _weapon_title(weapon_id: String) -> String:
	match weapon_id:
		"blood_bolt": return "血咒弹"
		"ghost_blades": return "幽魂环刃"
		"shadow_spikes": return "暗影地刺"
		"soul_nova": return "灵火新星"
		"doom_laser": return "毁灭激光"
		"plague_bomb": return "瘟疫炸弹"
		"abyss_tentacle": return "深渊触手"
		"reaping_scythe": return "穿魂镰刃"
		"grave_familiar": return "幽冥僚机"
		"frost_orb": return "寒星法球"
		"thunder_chain": return "雷链符文"
		"void_mines": return "虚空地雷"
	return weapon_id

func _unique_paths(paths: Array) -> Array[String]:
	var seen := {}
	var result: Array[String] = []
	for path in paths:
		var text := str(path)
		if text == "" or seen.has(text):
			continue
		seen[text] = true
		result.append(text)
	return result
