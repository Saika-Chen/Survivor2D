extends Node
## UIManager：统一注册各个 UI 面板，并对外转发信号。

const CJKFontTheme := preload("res://scripts/ui/cjk_font_theme.gd")
const GameHUD := preload("res://scripts/ui/panels/game_hud.gd")
const LevelUpPanel := preload("res://scripts/ui/panels/level_up_panel.gd")
const GameOverPopup := preload("res://scripts/ui/panels/game_over_popup.gd")
const WaveAlert := preload("res://scripts/ui/panels/wave_alert.gd")
const ContractCard := preload("res://scripts/ui/panels/contract_card.gd")
const DamageNumberLayer := preload("res://scripts/ui/panels/damage_number_layer.gd")
const MobileJoystick := preload("res://scripts/ui/panels/mobile_joystick.gd")

signal upgrade_selected(upgrade_id: String)
signal restart_requested
signal main_menu_requested
signal exit_run_requested
signal joystick_changed(input_vector: Vector2)
signal reroll_requested
signal jackpot_reward_granted(upgrade_id: String)
signal jackpot_finished
signal slot_tick_requested

var game_hud: GameHUD = null
var level_up_panel: LevelUpPanel = null
var game_over_popup: GameOverPopup = null
var wave_alert: WaveAlert = null
var contract_card: ContractCard = null
var damage_number_layer: DamageNumberLayer = null
var mobile_joystick: MobileJoystick = null

func _ready() -> void:
	# 先把全局回退字体设成像素字体，避免未显式覆盖的 Label 跑回默认字体。
	CJKFontTheme.ensure_global()

func register_game_hud(panel: GameHUD) -> void:
	game_hud = panel
	game_hud.exit_run_requested.connect(func() -> void: exit_run_requested.emit())

func register_level_up_panel(panel: LevelUpPanel) -> void:
	level_up_panel = panel
	level_up_panel.upgrade_selected.connect(func(id: String) -> void: upgrade_selected.emit(id))
	level_up_panel.reroll_requested.connect(func() -> void: reroll_requested.emit())
	level_up_panel.jackpot_reward_granted.connect(func(id: String) -> void: jackpot_reward_granted.emit(id))
	level_up_panel.jackpot_finished.connect(func() -> void: jackpot_finished.emit())
	level_up_panel.slot_tick_requested.connect(func() -> void: slot_tick_requested.emit())

func register_game_over_popup(panel: GameOverPopup) -> void:
	game_over_popup = panel
	game_over_popup.restart_requested.connect(func() -> void: restart_requested.emit())
	game_over_popup.main_menu_requested.connect(func() -> void: main_menu_requested.emit())

func register_wave_alert(panel: WaveAlert) -> void:
	wave_alert = panel

func register_contract_card(panel: ContractCard) -> void:
	contract_card = panel

func register_damage_number_layer(panel: DamageNumberLayer) -> void:
	damage_number_layer = panel

func register_mobile_joystick(panel: MobileJoystick) -> void:
	mobile_joystick = panel
	mobile_joystick.joystick_changed.connect(func(v: Vector2) -> void: joystick_changed.emit(v))

func set_stats(health: float, max_health: float, score: int, elapsed: float, enemy_count: int, level: int, experience: int, experience_to_next: int, wave: int, max_wave: int, time_left: float, weapons_summary: String, relics_summary: String, attack_power := 1.0, crit_chance := 0.0, crit_damage := 1.0, lifesteal_chance := 0.0, lifesteal_amount := 0.0, run_magic_crystals := 0, contract_summary := "") -> void:
	if game_hud != null:
		game_hud.set_stats(health, max_health, score, elapsed, enemy_count, level, experience, experience_to_next, wave, max_wave, time_left, weapons_summary, relics_summary, attack_power, crit_chance, crit_damage, lifesteal_chance, lifesteal_amount, run_magic_crystals, contract_summary)

func show_level_up(options: Array, title := "升级暂停：选择一项继续", prompt_text := "选择一种献祭回报，然后继续生存。", allow_reroll := true) -> void:
	if level_up_panel != null:
		level_up_panel.show_level_up(options, title, prompt_text, allow_reroll)

func hide_level_up() -> void:
	if level_up_panel != null:
		level_up_panel.hide_level_up()

func set_rerolls_left(count: int) -> void:
	if level_up_panel != null:
		level_up_panel.set_rerolls_left(count)

func show_slot_machine(reel_ids: Array, options: Array, jackpot: bool) -> void:
	if level_up_panel != null:
		level_up_panel.show_slot_machine(reel_ids, options, jackpot)

func show_game_over(score: int, elapsed: float) -> void:
	if game_over_popup != null:
		game_over_popup.show()
	if game_hud != null:
		game_hud.show_game_over(score, elapsed)

func show_victory(elapsed: float) -> void:
	if game_over_popup != null:
		game_over_popup.show()
	if game_hud != null:
		game_hud.show_victory(elapsed)

func show_wave_alert(text: String, is_boss := false) -> void:
	if wave_alert != null:
		wave_alert.show_wave_alert(text, is_boss)

func show_damage_number(screen_position: Vector2, text: String, critical := false) -> void:
	if damage_number_layer != null:
		damage_number_layer.show_damage_number(screen_position, text, critical)

func set_contract_card(contract: Dictionary) -> void:
	if contract_card != null:
		contract_card.set_contract_card(contract)

func set_loadout_icons(weapon_ids: Array, relic_ids: Array) -> void:
	if game_hud != null:
		game_hud.set_loadout_icons(weapon_ids, relic_ids)

func set_performance_stats(fps: float, enemy_count: int, projectile_count: int, enemy_projectile_count: int, zone_count: int, effect_count: int, gem_count: int, pickup_count: int) -> void:
	if game_hud != null:
		game_hud.set_performance_stats(fps, enemy_count, projectile_count, enemy_projectile_count, zone_count, effect_count, gem_count, pickup_count)

func set_ui_burst_pool(factory: Callable, recycler: Callable) -> void:
	if level_up_panel != null:
		level_up_panel.set_ui_burst_pool(factory, recycler)

func set_hint(text: String) -> void:
	if game_hud != null:
		game_hud.set_hint(text)

func get_hint() -> Label:
	if game_hud != null:
		return game_hud.hint
	return null
