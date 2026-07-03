extends SceneTree

const CJKFontTheme := preload("res://scripts/ui/cjk_font_theme.gd")
const HeroCatalog := preload("res://scripts/game/hero_catalog.gd")
const TextureFactory := preload("res://scripts/visuals/texture_factory.gd")

var elapsed := 0.0
var checked := false

func _initialize() -> void:
	change_scene_to_file("res://scenes/bootstrap/Bootstrap.tscn")

func _process(delta: float) -> bool:
	elapsed += delta
	if current_scene == null or checked:
		return false
	if elapsed > 8.0:
		assert(false, "Bootstrap should finish loading within timeout")
	if bootstrap_has_not_finished():
		return false
	checked = true
	var bootstrap := current_scene
	assert(bootstrap.progress_bar.value >= bootstrap.progress_bar.max_value, "Loading screen should finish preloading assets")
	assert(bootstrap.preload_paths.has(CJKFontTheme.FONT_PATH), "Bootstrap should track the bundled CJK font path")
	assert(bootstrap.select_panel != null and bootstrap.select_panel.visible, "Hero select panel should appear after loading")
	assert(CJKFontTheme.font() != null, "Bundled CJK UI font should load in bootstrap")
	assert(ThemeDB.fallback_font == CJKFontTheme.font(), "Global fallback font should be the pixel UI font")
	assert(bootstrap.loading_page.title_label.get_theme_font("font") == CJKFontTheme.font(), "Loading page should use the pixel UI font")
	assert(bootstrap.hero_select_page.title_label.get_theme_font("font") == CJKFontTheme.font(), "Hero select page should use the pixel UI font")
	assert(bootstrap.detail_label.has_theme_font_override("font"), "Hero select labels should use the bundled CJK font")
	assert(bootstrap.hero_buttons.size() == 12, "Hero select should render 12 hero buttons")
	assert(HeroCatalog.list().size() == 12, "Hero catalog should include 12 heroes")
	var hero_by_id := {}
	for hero in HeroCatalog.list():
		var hero_data: Dictionary = hero
		var hero_id := str(hero_data.get("id", ""))
		hero_by_id[hero_id] = hero_data
		assert(not bool(hero_data.get("single_weapon", false)), "Hero %s should not be locked to one weapon" % hero_id)
		assert(FileAccess.file_exists(HeroCatalog.UNIT_BASE + str(hero_data.get("unit_id", "")) + ".tres"), "Hero %s should use an existing Duelyst unit SpriteFrames file" % hero_id)
	assert(hero_by_id.has("storm_caller"), "Thunder-chain hero should be registered")
	assert(hero_by_id.has("void_miner"), "Void-mine hero should be registered")
	assert(hero_by_id["storm_caller"].get("initial_weapon", "") == "thunder_chain", "Thunder-chain hero should start with thunder_chain")
	assert(hero_by_id["void_miner"].get("initial_weapon", "") == "void_mines", "Void-mine hero should start with void_mines")
	var hero_button_text := ""
	for button in bootstrap.hero_buttons:
		hero_button_text += button.text + "\n"
	assert(hero_button_text.contains("雷链术士"), "Hero select should list the thunder-chain hero")
	assert(hero_button_text.contains("虚空埋雷者"), "Hero select should list the void-mine hero")
	assert(TextureFactory.item_icon_frames("blood_bolt") != null, "Weapon icon animation should load from Duelyst icons")
	assert(TextureFactory.item_icon_frames("blood_pact") != null, "Relic icon animation should load from Duelyst icons")
	assert(bootstrap.hero_buttons[0].has_node("Icon"), "Hero buttons should show an animated weapon icon next to text")
	assert(bootstrap.hero_buttons[0].get_theme_font_size("font_size") >= 22, "Hero select button text should be readable on mobile")
	assert(bootstrap.detail_label.get_theme_font_size("font_size") >= 22, "Hero detail text should be readable on mobile")
	assert(bootstrap.get("hero_detail_icon") != null and bootstrap.hero_detail_icon.sprite_frames != null, "Hero detail should show the selected weapon icon next to text")
	assert(bootstrap.hero_preview != null and bootstrap.hero_preview.visible, "Hero select should show an animated hero preview")
	assert(bootstrap.menu_pixel_frame != null and bootstrap.menu_pixel_frame.texture != null, "Hero select should use pixel UI frame art")
	assert(bootstrap.talent_pixel_frame != null and bootstrap.talent_pixel_frame.texture != null, "Talent tab should use pixel UI frame art")
	assert(FileAccess.file_exists("res://ui/slice_0004.png"), "Menu frame art should exist in the ui folder")
	assert(FileAccess.file_exists("res://ui/slice_0003.png"), "Gold currency art should exist in the ui folder")
	assert(FileAccess.file_exists("res://ui/slice_0007.png"), "Gem currency art should exist in the ui folder")
	assert(FileAccess.file_exists("res://ui/slice_0015.png"), "Vertical menu strip art should exist in the ui folder")
	assert(FileAccess.file_exists("res://ui/slice_0016.png"), "Pause badge art should exist in the ui folder")
	assert(FileAccess.file_exists("res://ui/slice_0041.png"), "Button art should exist in the ui folder")
	assert(bootstrap.hero_tab_button != null and bootstrap.talent_tab_button != null, "Hero select should provide hero and talent tabs")
	bootstrap._show_talent_tab()
	assert(bootstrap.talent_panel != null and bootstrap.talent_panel.visible, "Talent tab should show the talent panel")
	assert(bootstrap.talent_panel.title_label.get_theme_font("font") == CJKFontTheme.font(), "Talent page should use the pixel UI font")
	assert(bootstrap.crystal_label.text.contains("魔晶"), "Talent panel should display magic crystals")
	assert(bootstrap.get_node("/root/RuntimeConfig").talent_levels.has("damage"), "Runtime save config should include damage talent")
	bootstrap._show_codex_tab()
	assert(bootstrap.codex_panel != null and bootstrap.codex_panel.visible, "Codex tab should show the codex panel")
	var codex_content := bootstrap.codex_panel.get_child(0) as VBoxContainer
	assert(codex_content != null, "Codex should use a vertical section layout that fits inside the scroll view")
	assert(codex_content.get_child_count() >= 4, "Codex should render multiple readable sections")
	assert((codex_content.get_child(0).get_node("Content/Title") as Label).get_theme_font("font") == CJKFontTheme.font(), "Codex section labels should use the pixel UI font")
	assert(codex_content.get_child(0).has_node("Content/ItemGrid"), "Codex weapon section should render icon-text-description entries")
	assert(codex_content.get_child(1).has_node("Content/ItemGrid"), "Codex relic/reward section should render icon-text-description entries")
	var weapon_icon_grid := codex_content.get_child(0).get_node("Content/ItemGrid") as GridContainer
	var relic_icon_grid := codex_content.get_child(1).get_node("Content/ItemGrid") as GridContainer
	assert(weapon_icon_grid.columns == 1, "Codex weapon entries should use one full-width row per icon-description pair")
	assert(relic_icon_grid.columns == 1, "Codex relic entries should use one full-width row per icon-description pair")
	assert(weapon_icon_grid.get_child_count() >= 12, "Codex weapon section should show weapon entries")
	assert(relic_icon_grid.get_child_count() >= 12, "Codex relic section should show relic/reward entries")
	assert(weapon_icon_grid.get_child(0).has_node("Text/NameLabel"), "Codex weapon entries should include readable names")
	assert(weapon_icon_grid.get_child(0).has_node("Text/DescriptionLabel"), "Codex weapon entries should include matching descriptions")
	assert(relic_icon_grid.get_child(0).has_node("Text/NameLabel"), "Codex relic entries should include readable names")
	assert(relic_icon_grid.get_child(0).has_node("Text/DescriptionLabel"), "Codex relic entries should include matching descriptions")
	assert((weapon_icon_grid.get_child(0).get_node("Text/DescriptionLabel") as Label).text != "", "Codex weapon descriptions should not be empty")
	assert((relic_icon_grid.get_child(0).get_node("Text/DescriptionLabel") as Label).text != "", "Codex relic descriptions should not be empty")
	assert((weapon_icon_grid.get_child(0) as HBoxContainer).get_child(0).name == "IconHolder", "Codex entry should put the icon at the left of its matching text")
	assert((weapon_icon_grid.get_child(0) as HBoxContainer).get_child(1).name == "Text", "Codex entry should put matching name and description directly beside the icon")
	var codex_text := ""
	for card in codex_content.get_children():
		var label := card.get_node("Content/Title") as Label
		if label != null:
			codex_text += label.text + "\n"
	for item in weapon_icon_grid.get_children():
		if item.has_node("Text/NameLabel"):
			codex_text += (item.get_node("Text/NameLabel") as Label).text + "\n"
		if item.has_node("Text/DescriptionLabel"):
			codex_text += (item.get_node("Text/DescriptionLabel") as Label).text + "\n"
	for item in relic_icon_grid.get_children():
		if item.has_node("Text/NameLabel"):
			codex_text += (item.get_node("Text/NameLabel") as Label).text + "\n"
		if item.has_node("Text/DescriptionLabel"):
			codex_text += (item.get_node("Text/DescriptionLabel") as Label).text + "\n"
	assert(codex_text.contains("血咒弹"), "Codex should display weapon names next to icons")
	assert(codex_text.contains("追踪血弹"), "Codex should display weapon descriptions next to icons")
	assert(codex_text.contains("鲜血契约"), "Codex should display relic names next to icons")
	assert(not codex_text.contains("概率"), "Player-facing codex should not describe reward probability")
	assert(not codex_text.contains("稀释"), "Player-facing codex should not use design-tuning language")
	assert(not codex_text.contains("更新"), "Player-facing codex should not read like patch notes")
	bootstrap._show_hero_tab()
	assert(bootstrap.hero_content.visible, "Hero tab should return to hero selection content")
	bootstrap._select_hero("abyss_stalker")
	assert(bootstrap.selected_hero_id == "abyss_stalker", "Hero selection should update selected hero id")
	assert(bootstrap.hero_preview.sprite_frames != null, "Selected hero preview should load sprite frames")
	quit()
	return true

func bootstrap_has_not_finished() -> bool:
	return current_scene == null or current_scene.get("select_panel") == null or not current_scene.select_panel.visible
