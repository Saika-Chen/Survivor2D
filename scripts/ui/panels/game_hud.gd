extends Control
class_name GameHUD

# 主 HUD 面板：负责静态布局和运行时数据刷新。

const CJKFontTheme := preload("res://scripts/ui/cjk_font_theme.gd")
const HUDControllerScript := preload("res://scripts/ui/HUDController.gd")
const TextureFactory := preload("res://scripts/visuals/texture_factory.gd")

signal exit_run_requested

@onready var stats: Label = $Stats
@onready var health_bar: TextureProgressBar = $HealthBar
@onready var health_label: Label = $HealthBar/HealthLabel
@onready var hint: Label = $Hint
@onready var wave_label: Label = $WaveLabel
@onready var weapons_label: Label = $WeaponsLabel
@onready var relics_label: Label = $RelicsLabel
@onready var performance_label: Label = $PerformanceHUD
@onready var stats_art: TextureRect = $PortraitArt
@onready var right_art: TextureRect = $MapArt
@onready var stats_panel: TextureRect = $StatsPanel
@onready var right_panel: TextureRect = $RightPanel
@onready var currency_gold_bar: TextureRect = $CurrencyGoldBar
@onready var currency_gold_label: Label = $CurrencyGoldBar/GoldValue
@onready var currency_gem_bar: TextureRect = $CurrencyGemBar
@onready var currency_gem_label: Label = $CurrencyGemBar/GemValue
@onready var pause_badge: TextureRect = $PauseBadge
@onready var menu_strip: TextureRect = $MenuStrip
@onready var level_label: Label = $BottomLevelLabel
@onready var xp_bar: TextureProgressBar = $BottomXPBar
@onready var exit_run_button: Button = $ExitRunButton
@onready var weapon_icon_row: Control = $WeaponIconRow
@onready var relic_icon_row: Control = $RelicIconRow

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	CJKFontTheme.apply_to_tree(self)
	_apply_text_theme()
	exit_run_button.pressed.connect(func() -> void: exit_run_requested.emit())
	get_viewport().size_changed.connect(_layout_exit_run_button)
	_layout_exit_run_button()

func set_stats(health: float, max_health: float, score: int, elapsed: float, enemy_count: int, level: int, experience: int, experience_to_next: int, wave: int, max_wave: int, time_left: float, weapons_summary: String, relics_summary: String, attack_power := 1.0, crit_chance := 0.0, crit_damage := 1.0, lifesteal_chance := 0.0, lifesteal_amount := 0.0, run_magic_crystals := 0, contract_summary := "") -> void:
	stats.text = HUDControllerScript.format_stats(health, max_health, score, elapsed, enemy_count, level, experience, experience_to_next, wave, max_wave, time_left, attack_power, crit_chance, crit_damage, lifesteal_chance, lifesteal_amount, run_magic_crystals, contract_summary)
	currency_gold_label.text = str(score)
	currency_gem_label.text = str(run_magic_crystals)
	xp_bar.max_value = experience_to_next
	xp_bar.value = experience
	level_label.text = "Lv.%d" % level
	health_bar.max_value = max_health
	health_bar.value = health
	health_label.text = "%d / %d" % [int(ceil(health)), int(max_health)]
	wave_label.text = "第 %02d / %02d 波  %02d秒" % [wave, max_wave, max(0, int(ceil(time_left)))]
	weapons_label.text = _stack_summary(weapons_summary, " | ", 8)
	relics_label.text = _stack_summary(relics_summary, " / ", 8)

func set_loadout_icons(weapon_ids: Array, relic_ids: Array) -> void:
	_populate_icon_row(weapon_icon_row, weapon_ids, 58.0)
	_populate_icon_row(relic_icon_row, relic_ids, 50.0)

func set_performance_stats(fps: float, enemy_count: int, projectile_count: int, enemy_projectile_count: int, zone_count: int, effect_count: int, gem_count: int, pickup_count: int) -> void:
	if performance_label == null:
		return
	performance_label.text = "FPS %d\n怪 %d  弹 %d/%d\n区 %d  特 %d\n魂 %d  掉 %d" % [
		int(round(fps)),
		enemy_count,
		projectile_count,
		enemy_projectile_count,
		zone_count,
		effect_count,
		gem_count,
		pickup_count
	]

func set_hint(text: String) -> void:
	hint.text = text

func show_game_over(score: int, elapsed: float) -> void:
	var seconds := int(elapsed) % 60
	var minutes := int(elapsed) / 60
	hint.text = "死亡降临 - 击杀 %d - 生存 %02d:%02d" % [score, minutes, seconds]

func show_victory(elapsed: float) -> void:
	var seconds := int(elapsed) % 60
	var minutes := int(elapsed) / 60
	hint.text = "深渊君王已陨落 - 生存 %02d:%02d" % [minutes, seconds]

func _apply_text_theme() -> void:
	stats.add_theme_font_size_override("font_size", 24)
	health_label.add_theme_font_size_override("font_size", 20)
	hint.add_theme_font_size_override("font_size", 20)
	wave_label.add_theme_font_size_override("font_size", 26)
	weapons_label.add_theme_font_size_override("font_size", 16)
	relics_label.add_theme_font_size_override("font_size", 16)
	weapons_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	relics_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	performance_label.add_theme_font_size_override("font_size", 14)
	level_label.add_theme_font_size_override("font_size", 24)
	exit_run_button.add_theme_font_size_override("font_size", 22)

func _stack_summary(summary: String, separator: String, max_lines: int) -> String:
	return HUDControllerScript.stack_summary(summary, separator, max_lines)

func _populate_icon_row(row: Control, item_ids: Array, icon_size: float) -> void:
	if row == null:
		return
	for child in row.get_children():
		child.queue_free()
	var index := 0
	for item_id_variant in item_ids:
		var frames := TextureFactory.item_icon_frames(str(item_id_variant))
		if frames == null:
			continue
		var icon := AnimatedSprite2D.new()
		icon.name = "Icon"
		icon.sprite_frames = frames
		icon.centered = true
		icon.position = Vector2(icon_size * 0.5 + float(index) * (icon_size + 6.0), icon_size * 0.5)
		icon.scale = Vector2.ONE * (icon_size / 96.0)
		_play_icon(icon)
		row.add_child(icon)
		index += 1

func _play_icon(icon: AnimatedSprite2D) -> void:
	if icon.sprite_frames == null:
		return
	var names := icon.sprite_frames.get_animation_names()
	if names.is_empty():
		return
	icon.play(str(names[0]))

func _layout_exit_run_button() -> void:
	var size := get_viewport().get_visible_rect().size
	var portrait := size.y > size.x
	var button_size := Vector2(128.0, 54.0)
	var left := 18.0
	var bottom := size.y - 18.0
	if portrait:
		bottom = size.y - 248.0
	exit_run_button.offset_left = left
	exit_run_button.offset_top = bottom - button_size.y
	exit_run_button.offset_right = left + button_size.x
	exit_run_button.offset_bottom = bottom
