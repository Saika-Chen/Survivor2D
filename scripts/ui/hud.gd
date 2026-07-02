extends CanvasLayer

const DOTween := preload("res://scripts/utils/dotween.gd")
const UITheme := preload("res://scripts/ui/ui_theme.gd")
const TextureFactory := preload("res://scripts/visuals/texture_factory.gd")
const CJKFontTheme := preload("res://scripts/ui/cjk_font_theme.gd")

signal upgrade_selected(upgrade_id: String)
signal restart_requested
signal main_menu_requested
signal exit_run_requested
signal joystick_changed(input_vector: Vector2)
signal reroll_requested
signal jackpot_reward_granted(upgrade_id: String)
signal jackpot_finished
signal slot_tick_requested

@onready var stats: Label = $Stats
@onready var health_bar: TextureProgressBar = $HealthBar
@onready var health_label: Label = $HealthBar/HealthLabel
@onready var hint: Label = $Hint
@onready var wave_label: Label = $WaveLabel
@onready var weapons_label: Label = $WeaponsLabel
@onready var relics_label: Label = $RelicsLabel
@onready var wave_alert: Control = $WaveAlert
@onready var wave_alert_frame: TextureRect = $WaveAlert/Frame
@onready var wave_alert_label: Label = $WaveAlert/Label
@onready var restart_button: Button = $RestartButton
@onready var main_menu_button: Button = $MainMenuButton
@onready var level_up_overlay: Control = $LevelUpOverlay
@onready var level_up_panel: Panel = $LevelUpOverlay/Panel
@onready var level_up_title: Label = $LevelUpOverlay/Panel/Title
@onready var event_badge: Label = $LevelUpOverlay/Panel/EventBadge
@onready var level_up_prompt: Label = $LevelUpOverlay/Panel/Prompt
@onready var reroll_button: Button = $LevelUpOverlay/Panel/RerollButton
@onready var mobile_joystick: Control = $MobileJoystick
@onready var joystick_backplate: ColorRect = $MobileJoystick/Backplate
@onready var upgrade_buttons := [
	$LevelUpOverlay/Panel/Options/DamageButton,
	$LevelUpOverlay/Panel/Options/FireRateButton,
	$LevelUpOverlay/Panel/Options/VitalityButton,
	$LevelUpOverlay/Panel/Options/Option4Button,
	$LevelUpOverlay/Panel/Options/Option5Button,
	$LevelUpOverlay/Panel/Options/Option6Button
]
@onready var slot_machine: Control = $LevelUpOverlay/Panel/SlotMachine
@onready var slot_frame: TextureRect = $LevelUpOverlay/Panel/SlotMachine/Frame
@onready var slot_reels := [
	$LevelUpOverlay/Panel/SlotMachine/Reel1,
	$LevelUpOverlay/Panel/SlotMachine/Reel2,
	$LevelUpOverlay/Panel/SlotMachine/Reel3
]
@onready var slot_jackpot_label: Label = $LevelUpOverlay/Panel/SlotMachine/JackpotLabel
@onready var joystick_base: Control = $MobileJoystick/Base
@onready var joystick_ring: ColorRect = $MobileJoystick/Base/Ring
@onready var joystick_stick: Control = $MobileJoystick/Base/Stick
var performance_label: Label
var stats_art: TextureRect
var right_art: TextureRect
var stats_panel: TextureRect
var right_panel: TextureRect
var xp_bar: TextureProgressBar
var level_label: Label
var exit_run_button: Button
var weapon_icon_row: Control
var relic_icon_row: Control
var option_card_texture: Texture2D
var damage_number_layer: Control
var damage_label_pool: Array[Label] = []
var last_damage_number_label: Label

var current_upgrade_ids: Array[String] = []
var joystick_active := false
var joystick_pointer_id := -1
var fullscreen_joystick_enabled := true
var fullscreen_joystick_center := Vector2.ZERO
var mobile_controls_enabled := false
var slot_spinning := false
var slot_stop_times: Array[float] = [0.85, 1.35, 1.85]
var slot_target_symbols: Array[String] = []
var slot_reward_options: Array = []
var slot_symbol_pool := ["weapon", "relic", "power", "fate", "jackpot"]
var slot_is_jackpot := false
var jackpot_animating := false
var jackpot_step_index := 0
var jackpot_reward_ids: Array[String] = []
var jackpot_hold_seconds := 1.8
var ui_scale := 1.22
var ui_burst_factory: Callable
var ui_burst_recycler: Callable

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	CJKFontTheme.apply_to_tree(self)
	level_up_overlay.hide()
	slot_machine.hide()
	wave_alert.hide()
	restart_button.hide()
	main_menu_button.hide()
	event_badge.hide()
	health_label.show()
	health_bar.show()
	_build_pixel_ui_art()
	_build_bottom_xp_bar()
	_build_loadout_icon_rows()
	_build_damage_number_layer()
	_build_exit_run_button()
	_build_performance_hud()
	_apply_bright_text_theme()
	_configure_pixel_bars()
	wave_alert_frame.texture = TextureFactory.warning_banner()
	restart_button.pressed.connect(_on_restart_pressed)
	main_menu_button.pressed.connect(_on_main_menu_pressed)
	exit_run_button.pressed.connect(_on_exit_run_pressed)
	reroll_button.pressed.connect(_on_reroll_pressed)
	for button_index in range(upgrade_buttons.size()):
		upgrade_buttons[button_index].pressed.connect(_on_upgrade_button_pressed.bind(button_index))
	get_viewport().size_changed.connect(_layout_mobile_joystick)
	get_viewport().size_changed.connect(_layout_hud_for_orientation)
	_configure_mobile_controls()
	_reset_joystick()
	_layout_hud_for_orientation()

func _input(event: InputEvent) -> void:
	if level_up_overlay.visible:
		if event is InputEventKey and event.pressed and not event.echo:
			if slot_spinning:
				return
			match event.keycode:
				KEY_1:
					_on_upgrade_button_pressed(0)
				KEY_2:
					_on_upgrade_button_pressed(1)
				KEY_3:
					_on_upgrade_button_pressed(2)
				KEY_4:
					_on_upgrade_button_pressed(3)
				KEY_5:
					_on_upgrade_button_pressed(4)
				KEY_6:
					_on_upgrade_button_pressed(5)
				KEY_R:
					if reroll_button.visible and not reroll_button.disabled:
						_on_reroll_pressed()
			return
		return

	if event is InputEventScreenTouch:
		if event.pressed and _is_inside_joystick(event.position):
			joystick_active = true
			joystick_pointer_id = event.index
			fullscreen_joystick_center = event.position
			_update_joystick(event.position)
		elif event.index == joystick_pointer_id:
			joystick_active = false
			joystick_pointer_id = -1
			_reset_joystick()
	elif event is InputEventScreenDrag and joystick_active and event.index == joystick_pointer_id:
		_update_joystick(event.position)
	elif event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT:
			if event.pressed and _is_inside_joystick(event.position):
				joystick_active = true
				joystick_pointer_id = -2
				fullscreen_joystick_center = event.position
				_update_joystick(event.position)
			elif joystick_pointer_id == -2:
				joystick_active = false
				joystick_pointer_id = -1
				_reset_joystick()
	elif event is InputEventMouseMotion and joystick_active and joystick_pointer_id == -2:
		_update_joystick(event.position)

func set_stats(health: float, max_health: float, score: int, elapsed: float, enemy_count: int, level: int, experience: int, experience_to_next: int, wave: int, max_wave: int, time_left: float, weapons_summary: String, relics_summary: String, attack_power := 1.0, crit_chance := 0.0, crit_damage := 1.0, lifesteal_chance := 0.0, lifesteal_amount := 0.0, run_magic_crystals := 0) -> void:
	var seconds := int(elapsed) % 60
	var minutes := int(elapsed) / 60
	stats.text = "⚔ 攻击力 %.0f\n✦ 暴击 %.0f%%  爆伤 x%.2f\n🩸 吸血 %.0f%%  +%.0f\n◆ 本局魔晶 %d\n☠ 击杀 %d\n◷ %02d:%02d\n◆ 敌人 %d" % [
		max(1.0, attack_power),
		crit_chance * 100.0,
		crit_damage,
		lifesteal_chance * 100.0,
		lifesteal_amount,
		run_magic_crystals,
		score,
		minutes,
		seconds,
		enemy_count
	]
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

func _stack_summary(summary: String, separator: String, max_lines: int) -> String:
	var pieces := summary.split(separator, false)
	if pieces.size() <= 1:
		return summary
	var visible: Array[String] = []
	for index in range(min(max_lines, pieces.size())):
		visible.append(pieces[index])
	if pieces.size() > max_lines:
		visible.append("+%d" % (pieces.size() - max_lines))
	return "\n".join(visible)

func _build_performance_hud() -> void:
	performance_label = Label.new()
	performance_label.name = "PerformanceHUD"
	performance_label.process_mode = Node.PROCESS_MODE_ALWAYS
	performance_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	performance_label.vertical_alignment = VERTICAL_ALIGNMENT_BOTTOM
	performance_label.autowrap_mode = TextServer.AUTOWRAP_OFF
	performance_label.add_theme_font_size_override("font_size", 14)
	performance_label.add_theme_color_override("font_color", Color(0.72, 1.0, 0.72, 0.92))
	performance_label.add_theme_color_override("font_shadow_color", Color(0.0, 0.0, 0.0, 1.0))
	performance_label.add_theme_constant_override("shadow_offset_x", 2)
	performance_label.add_theme_constant_override("shadow_offset_y", 2)
	performance_label.text = "FPS --"
	add_child(performance_label)
	CJKFontTheme.apply_to(performance_label)

func _build_pixel_ui_art() -> void:
	option_card_texture = TextureFactory.pixel_ui_asset("option_card")
	stats_art = null
	right_art = null
	stats_panel = null
	right_panel = null

func _new_ui_texture(node_name: String, texture: Texture2D, color: Color) -> TextureRect:
	var rect := TextureRect.new()
	rect.name = node_name
	rect.texture = texture
	rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	rect.stretch_mode = TextureRect.STRETCH_SCALE
	rect.modulate = color
	add_child(rect)
	move_child(rect, 0)
	return rect

func _build_bottom_xp_bar() -> void:
	xp_bar = TextureProgressBar.new()
	xp_bar.name = "BottomXPBar"
	xp_bar.texture_under = TextureFactory.pixel_ui_asset("xp_bar")
	xp_bar.texture_progress = TextureFactory.pixel_ui_asset("xp_bar")
	xp_bar.tint_progress = Color(0.78, 0.56, 1.0, 1.0)
	xp_bar.tint_under = Color(0.18, 0.12, 0.25, 0.86)
	add_child(xp_bar)
	level_label = Label.new()
	level_label.name = "BottomLevelLabel"
	level_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	level_label.add_theme_font_size_override("font_size", 24)
	level_label.add_theme_color_override("font_color", Color(1.0, 0.92, 0.42, 1.0))
	level_label.add_theme_color_override("font_shadow_color", Color.BLACK)
	level_label.add_theme_constant_override("shadow_offset_x", 2)
	level_label.add_theme_constant_override("shadow_offset_y", 2)
	add_child(level_label)
	CJKFontTheme.apply_to(level_label)

func _build_loadout_icon_rows() -> void:
	weapon_icon_row = Control.new()
	weapon_icon_row.name = "WeaponIconRow"
	add_child(weapon_icon_row)
	relic_icon_row = Control.new()
	relic_icon_row.name = "RelicIconRow"
	add_child(relic_icon_row)

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

func _build_exit_run_button() -> void:
	exit_run_button = Button.new()
	exit_run_button.name = "ExitRunButton"
	exit_run_button.process_mode = Node.PROCESS_MODE_ALWAYS
	exit_run_button.text = "退出"
	exit_run_button.custom_minimum_size = Vector2(128.0, 54.0)
	exit_run_button.focus_mode = Control.FOCUS_NONE
	exit_run_button.mouse_filter = Control.MOUSE_FILTER_STOP
	exit_run_button.z_index = 90
	add_child(exit_run_button)
	CJKFontTheme.apply_to(exit_run_button)
	_apply_pixel_button_style(exit_run_button, option_card_texture)

func _build_damage_number_layer() -> void:
	damage_number_layer = Control.new()
	damage_number_layer.name = "DamageNumberLayer"
	damage_number_layer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	damage_number_layer.set_anchors_preset(Control.PRESET_FULL_RECT)
	damage_number_layer.z_index = 1000
	add_child(damage_number_layer)
	for index in range(48):
		var label := _create_damage_label()
		label.hide()
		damage_number_layer.add_child(label)
		damage_label_pool.append(label)

func _create_damage_label() -> Label:
	var label := Label.new()
	label.name = "DamageNumber"
	label.size = Vector2(95.0, 28.0)
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	label.z_index = 1000
	label.add_theme_font_size_override("font_size", 17)
	label.add_theme_color_override("font_shadow_color", Color(0.0, 0.0, 0.0, 1.0))
	label.add_theme_constant_override("shadow_offset_x", 3)
	label.add_theme_constant_override("shadow_offset_y", 3)
	CJKFontTheme.apply_to(label)
	return label

func _configure_pixel_bars() -> void:
	health_bar.texture_under = TextureFactory.pixel_ui_asset("hp_bar")
	health_bar.texture_progress = TextureFactory.pixel_ui_asset("hp_bar")
	health_bar.tint_under = Color(0.22, 0.02, 0.04, 0.82)
	health_bar.tint_progress = Color(1.0, 0.06, 0.10, 1.0)
	slot_frame.texture = TextureFactory.pixel_slot_frame()

func show_damage_number(screen_position: Vector2, text: String, critical := false) -> void:
	if damage_number_layer == null:
		return
	var label: Label = _take_damage_label()
	last_damage_number_label = label
	DOTween.kill(label, "damage_number")
	label.text = text
	label.z_index = 1000
	label.visible = true
	label.modulate = Color.WHITE
	label.scale = Vector2.ONE * (1.18 if critical else 1.0)
	label.position = screen_position - label.size * 0.5
	label.add_theme_font_size_override("font_size", 21 if critical else 16)
	label.add_theme_color_override("font_color", Color(1.0, 0.14, 0.06, 1.0) if critical else Color(1.0, 0.96, 0.34, 1.0))
	var rise: float = 46.0 if critical else 33.0
	var tween := DOTween.sequence(label, "damage_number")
	tween.set_parallel(true)
	tween.tween_property(label, "position:y", label.position.y - rise, 0.78 if critical else 0.58).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	tween.tween_property(label, "scale", Vector2.ONE * (1.36 if critical else 1.10), 0.16).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.tween_property(label, "modulate:a", 0.0, 0.78 if critical else 0.58).set_delay(0.12).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)
	tween.chain()
	tween.tween_callback(_recycle_damage_label.bind(label))

func _recycle_damage_label(label: Label) -> void:
	label.hide()
	label.scale = Vector2.ONE
	if not damage_label_pool.has(label):
		damage_label_pool.append(label)

func _take_damage_label() -> Label:
	while not damage_label_pool.is_empty():
		var label: Label = damage_label_pool.pop_back()
		if is_instance_valid(label):
			return label
	var replacement: Label = _create_damage_label()
	damage_number_layer.add_child(replacement)
	return replacement

func show_game_over(score: int, elapsed: float) -> void:
	var seconds := int(elapsed) % 60
	var minutes := int(elapsed) / 60
	hint.text = "死亡降临 - 击杀 %d - 生存 %02d:%02d" % [score, minutes, seconds]
	restart_button.show()
	main_menu_button.show()

func show_victory(elapsed: float) -> void:
	var seconds := int(elapsed) % 60
	var minutes := int(elapsed) / 60
	hint.text = "深渊君王已陨落 - 生存 %02d:%02d" % [minutes, seconds]
	restart_button.show()
	main_menu_button.show()

func show_wave_alert(text: String, is_boss := false) -> void:
	wave_alert_label.text = text
	wave_alert_label.modulate = Color(1.0, 0.88, 0.36) if is_boss else Color(0.92, 0.84, 1.0)
	wave_alert.modulate.a = 1.0
	DOTween.pop_in(self, wave_alert, 0.22, Vector2.ONE * 0.92, Vector2.ONE, "wave_alert_show")
	var hold_time := 2.2 if is_boss else 1.5
	var hide_tween := DOTween.sequence(self, "wave_alert_hide")
	hide_tween.tween_interval(hold_time)
	hide_tween.tween_property(wave_alert, "modulate:a", 0.0, 0.24).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)
	hide_tween.tween_callback(func() -> void:
		wave_alert.hide()
	)

func show_level_up(options: Array, title := "升级暂停：选择一项继续", prompt_text := "选择一种献祭回报，然后继续生存。", allow_reroll := true) -> void:
	current_upgrade_ids.clear()
	slot_machine.hide()
	level_up_title.text = title
	level_up_prompt.text = prompt_text
	var event_mode := true
	for option in options:
		if not str(option.get("id", "")).begins_with("event:"):
			event_mode = false
			break
	_apply_panel_style(event_mode, title)
	hint.text = "选择 1 - 6" if options.size() > 3 else ("选择 1 / 2 / 3，或按 R 重新 Roll。" if allow_reroll else "选择 1 / 2 / 3")
	for option_index in range(upgrade_buttons.size()):
		if option_index >= options.size():
			upgrade_buttons[option_index].hide()
			_set_button_icon(upgrade_buttons[option_index], "", 46.0)
			continue
		var option: Dictionary = options[option_index]
		var rarity := str(option.get("rarity", "普通"))
		var category := str(option.get("category", "属性"))
		current_upgrade_ids.append(option["id"])
		upgrade_buttons[option_index].show()
		upgrade_buttons[option_index].disabled = false
		upgrade_buttons[option_index].alignment = HORIZONTAL_ALIGNMENT_LEFT
		upgrade_buttons[option_index].text = "      [%s] %s\n      %s" % [rarity, option["title"], option["description"]]
		_set_button_icon(upgrade_buttons[option_index], _option_icon_id(option), 46.0)
		var option_font_color := Color(1.0, 0.98, 0.82, 1.0)
		upgrade_buttons[option_index].add_theme_color_override("font_color", option_font_color)
		upgrade_buttons[option_index].add_theme_color_override("font_hover_color", Color.WHITE)
		upgrade_buttons[option_index].add_theme_color_override("font_pressed_color", Color.WHITE)
		upgrade_buttons[option_index].add_theme_color_override("font_focus_color", Color(0.72, 1.0, 1.0, 1.0))
		upgrade_buttons[option_index].add_theme_color_override("font_shadow_color", Color(0.0, 0.0, 0.0, 1.0))
		upgrade_buttons[option_index].add_theme_constant_override("shadow_offset_x", 2)
		upgrade_buttons[option_index].add_theme_constant_override("shadow_offset_y", 2)
		upgrade_buttons[option_index].modulate = UITheme.rarity_background(rarity).lightened(1.15)
		_apply_pixel_button_style(upgrade_buttons[option_index], option_card_texture)
	reroll_button.visible = allow_reroll
	level_up_overlay.show()
	_layout_hud_for_orientation()
	DOTween.pop_in(self, level_up_panel, 0.20, Vector2.ONE * 0.94, Vector2.ONE, "level_panel")

func set_rerolls_left(count: int) -> void:
	reroll_button.text = "重新 Roll（%d）" % count
	reroll_button.disabled = count <= 0

func show_slot_machine(reel_ids: Array[String], options: Array, jackpot: bool) -> void:
	slot_target_symbols = reel_ids.duplicate()
	slot_reward_options = options.duplicate()
	slot_is_jackpot = jackpot
	slot_spinning = true
	level_up_title.text = "命运拉霸"
	level_up_prompt.text = "齿轮正在咬合，命运开始转动。"
	hint.text = "拉霸开奖中..."
	slot_frame.texture = TextureFactory.pixel_slot_frame()
	slot_jackpot_label.text = "三连命运符号 = 6张奖励卡" if jackpot else "命运抽出 3 张奖励卡"
	slot_jackpot_label.modulate = Color(1.0, 0.88, 0.32) if jackpot else Color(0.86, 0.78, 1.0)
	_apply_panel_style(false, "命运拉霸")
	for button in upgrade_buttons:
		button.hide()
		_set_button_icon(button, "", 46.0)
	for reel in slot_reels:
		reel.texture = null
	slot_machine.show()
	_layout_hud_for_orientation()
	reroll_button.hide()
	level_up_overlay.show()
	DOTween.pop_in(self, level_up_panel, 0.20, Vector2.ONE * 0.94, Vector2.ONE, "slot_panel")
	_start_slot_spin_animation()

func hide_level_up() -> void:
	level_up_overlay.hide()
	slot_machine.hide()
	slot_spinning = false
	DOTween.kill(self, "slot_spin_sequence")
	DOTween.kill(self, "jackpot_sequence")
	DOTween.kill(self, "wave_alert_show")
	DOTween.kill(self, "wave_alert_hide")
	jackpot_animating = false
	jackpot_reward_ids.clear()
	event_badge.hide()
	level_up_panel.modulate = Color(0.55, 0.42, 0.68, 1)
	hint.text = "左摇杆移动  |  黑暗会回应击杀" if mobile_controls_enabled else "移动: WASD / 方向键  |  黑暗会回应击杀"

func _on_upgrade_button_pressed(button_index: int) -> void:
	if jackpot_animating or slot_spinning:
		return
	if button_index >= current_upgrade_ids.size():
		return
	upgrade_selected.emit(current_upgrade_ids[button_index])

func _on_restart_pressed() -> void:
	restart_requested.emit()

func _on_main_menu_pressed() -> void:
	main_menu_requested.emit()

func _on_exit_run_pressed() -> void:
	exit_run_requested.emit()

func _on_reroll_pressed() -> void:
	reroll_requested.emit()

func _set_button_icon(button: Button, item_id: String, icon_size: float) -> void:
	var icon: AnimatedSprite2D = button.get_node_or_null("Icon") as AnimatedSprite2D
	if item_id == "":
		if icon != null:
			icon.hide()
		return
	var frames := TextureFactory.item_icon_frames(item_id)
	if frames == null:
		if icon != null:
			icon.hide()
		return
	if icon == null:
		icon = AnimatedSprite2D.new()
		icon.name = "Icon"
		icon.centered = true
		icon.z_index = 20
		button.add_child(icon)
	icon.sprite_frames = frames
	icon.scale = Vector2.ONE * (icon_size / 96.0)
	icon.position = Vector2(34.0, max(icon_size * 0.62, button.size.y * 0.5))
	icon.show()
	_play_icon(icon)

func _option_icon_id(option: Dictionary) -> String:
	var option_id := str(option.get("id", ""))
	var parts := option_id.split(":")
	if parts.size() >= 2:
		match parts[0]:
			"unlock", "upgrade", "evolve", "super_evolve":
				return parts[1]
			"passive":
				return parts[1]
			"fusion":
				return parts[1]
			"stat":
				return "stat:%s" % parts[1]
	return str(option.get("icon_id", ""))

func _category_icon(category: String) -> String:
	match category:
		"武器":
			return "⚔"
		"强化":
			return "▲"
		"遗物":
			return "◆"
		"合体":
			return "★"
		_:
			return "✦"

func _is_inside_joystick(position: Vector2) -> bool:
	if fullscreen_joystick_enabled:
		return mobile_controls_enabled and get_viewport().get_visible_rect().has_point(position)
	var center := joystick_base.global_position + joystick_base.size * 0.5
	return position.distance_to(center) <= _joystick_radius() * 1.35

func _update_joystick(position: Vector2) -> void:
	var center := fullscreen_joystick_center if fullscreen_joystick_enabled else joystick_base.global_position + joystick_base.size * 0.5
	var joystick_radius := _joystick_radius()
	var offset := (position - center).limit_length(joystick_radius)
	DOTween.kill(self, "joystick_stick_reset")
	if not fullscreen_joystick_enabled:
		joystick_stick.position = joystick_base.size * 0.5 + offset - joystick_stick.size * 0.5
		_animate_joystick_state(true)
	joystick_changed.emit(offset / joystick_radius)

func _reset_joystick() -> void:
	if fullscreen_joystick_enabled:
		joystick_changed.emit(Vector2.ZERO)
		return
	var center_position := joystick_base.size * 0.5 - joystick_stick.size * 0.5
	var tween := DOTween.sequence(self, "joystick_stick_reset")
	tween.tween_property(joystick_stick, "position", center_position, 0.12).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	_animate_joystick_state(false)
	joystick_changed.emit(Vector2.ZERO)

func _animate_joystick_state(active: bool) -> void:
	var backplate_color := Color(1.0, 1.0, 1.0, 1.0) if active else Color(1.0, 1.0, 1.0, 0.92)
	var base_color := Color(1.0, 0.52, 1.0, 0.98) if active else Color(0.96, 0.48, 1.0, 0.88)
	var ring_color := Color(0.95, 0.98, 1.0, 0.95) if active else Color(0.88, 0.94, 1.0, 0.8)
	var stick_color := Color(0.92, 1.0, 0.98, 1.0) if active else Color(0.86, 1.0, 0.94, 0.98)
	var base_scale := Vector2.ONE
	var stick_scale := Vector2.ONE * (1.06 if active else 1.0)
	var tween := DOTween.sequence(self, "joystick_visual_state")
	tween.set_parallel(true)
	tween.tween_property(joystick_backplate, "modulate", backplate_color, 0.10).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	tween.tween_property(joystick_base, "modulate", base_color, 0.10).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	tween.tween_property(joystick_ring, "modulate", ring_color, 0.10).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	tween.tween_property(joystick_stick, "modulate", stick_color, 0.10).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	tween.tween_property(joystick_base, "scale", base_scale, 0.10).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	tween.tween_property(joystick_stick, "scale", stick_scale, 0.10).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)

func _configure_mobile_controls() -> void:
	mobile_controls_enabled = OS.has_feature("mobile") or OS.has_feature("editor") or DisplayServer.is_touchscreen_available()
	mobile_joystick.visible = mobile_controls_enabled and not fullscreen_joystick_enabled
	_layout_mobile_joystick()

func _layout_mobile_joystick() -> void:
	if not mobile_controls_enabled:
		return
	var viewport_size := get_viewport().get_visible_rect().size
	var joystick_size := clampf(min(viewport_size.x, viewport_size.y) * 0.34, 218.0, 304.0)
	var lower_half_center := Vector2(viewport_size.x * 0.5, viewport_size.y * 0.75)
	mobile_joystick.offset_left = lower_half_center.x - joystick_size * 0.5
	mobile_joystick.offset_top = lower_half_center.y - joystick_size * 0.5
	mobile_joystick.offset_right = lower_half_center.x + joystick_size * 0.5
	mobile_joystick.offset_bottom = lower_half_center.y + joystick_size * 0.5
	joystick_backplate.position = Vector2(-14.0, -14.0)
	joystick_backplate.size = Vector2.ONE * (joystick_size + 28.0)
	joystick_base.position = Vector2(0, 0)
	joystick_base.size = Vector2.ONE * joystick_size
	joystick_ring.position = Vector2.ONE * 10.0
	joystick_ring.size = Vector2.ONE * (joystick_size - 20.0)
	var stick_size := joystick_size * 0.40
	joystick_stick.size = Vector2.ONE * stick_size
	_reset_joystick()

func _joystick_radius() -> float:
	return min(joystick_base.size.x, joystick_base.size.y) * 0.34

func _show_slot_rewards() -> void:
	if slot_is_jackpot:
		_show_jackpot_rewards()
		return
	show_level_up(
		slot_reward_options,
		"命运奖池",
		"三连同符号会开启更多选择。挑一张，把好运带走。",
		false
	)

func _show_jackpot_rewards() -> void:
	current_upgrade_ids.clear()
	slot_machine.hide()
	jackpot_reward_ids.clear()
	level_up_title.text = "JACKPOT / 全拿！"
	level_up_prompt.text = "命运偏向你，6 个奖励将连续注入。"
	_apply_panel_style(false, "JACKPOT / 全拿！")
	hint.text = "大奖结算中..."
	for option_index in range(upgrade_buttons.size()):
		if option_index >= slot_reward_options.size():
			upgrade_buttons[option_index].hide()
			continue
		var option: Dictionary = slot_reward_options[option_index]
		var rarity := str(option.get("rarity", "普通"))
		var category := str(option.get("category", "属性"))
		var text := "%s\n[%s] %s\n%s" % [_category_icon(category), rarity, option["title"], option["description"]]
		jackpot_reward_ids.append(str(option["id"]))
		upgrade_buttons[option_index].show()
		upgrade_buttons[option_index].disabled = true
		upgrade_buttons[option_index].text = text
		upgrade_buttons[option_index].add_theme_color_override("font_color", Color(1.0, 0.98, 0.74, 1.0))
		upgrade_buttons[option_index].add_theme_color_override("font_shadow_color", Color(0.0, 0.0, 0.0, 1.0))
		upgrade_buttons[option_index].modulate = Color.from_hsv(fmod(float(option_index) / 6.0 + 0.02, 1.0), 0.64, 1.0, 1.0)
		_apply_pixel_button_style(upgrade_buttons[option_index], option_card_texture)
	reroll_button.hide()
	level_up_overlay.show()
	jackpot_animating = true
	jackpot_step_index = 0
	_spawn_jackpot_burst(36)
	var sequence := DOTween.sequence(self, "jackpot_sequence")
	sequence.tween_interval(jackpot_hold_seconds)
	for reward_index in range(jackpot_reward_ids.size()):
		sequence.tween_interval(0.16)
		sequence.tween_callback(func(index := reward_index) -> void:
			var button: Button = upgrade_buttons[index]
			button.modulate = Color(1.0, 0.92, 0.62, 1.0)
			jackpot_step_index = index + 1
			jackpot_reward_granted.emit(jackpot_reward_ids[index])
		)
	sequence.tween_callback(func() -> void:
		jackpot_animating = false
		jackpot_finished.emit()
	)

func set_ui_burst_pool(factory: Callable, recycler: Callable) -> void:
	ui_burst_factory = factory
	ui_burst_recycler = recycler

func _spawn_jackpot_burst(count: int) -> void:
	if not ui_burst_factory.is_valid():
		return
	var center := level_up_panel.global_position + level_up_panel.size * 0.5
	for index in range(count):
		var block: ColorRect = ui_burst_factory.call()
		block.color = Color.from_hsv(float(index) / float(max(1, count)), 0.78, 1.0, 1.0)
		block.size = Vector2(14.0, 14.0) * randf_range(0.8, 1.55)
		block.global_position = center
		block.rotation = randf() * TAU
		level_up_overlay.add_child(block)
		var direction := Vector2.RIGHT.rotated(TAU * float(index) / float(count) + randf_range(-0.22, 0.22))
		var distance := randf_range(180.0, 420.0)
		var tween := DOTween.sequence(block, "jackpot_burst")
		tween.set_parallel(true)
		tween.tween_property(block, "global_position", center + direction * distance, 0.95).set_trans(Tween.TRANS_QUART).set_ease(Tween.EASE_OUT)
		tween.tween_property(block, "rotation", block.rotation + randf_range(-4.0, 4.0), 0.95)
		tween.tween_property(block, "modulate:a", 0.0, 0.95).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)
		tween.chain()
		tween.tween_callback(func(node := block) -> void:
			if ui_burst_recycler.is_valid():
				ui_burst_recycler.call(node, "ui_burst")
			else:
				node.queue_free()
		)

func _start_slot_spin_animation() -> void:
	var sequence := DOTween.sequence(self, "slot_spin_sequence")
	var step_time: float = 0.06
	var max_time: float = slot_stop_times[slot_stop_times.size() - 1]
	var steps: int = int(ceil(max_time / step_time))
	for step in range(steps):
		sequence.tween_interval(step_time)
		sequence.tween_callback(func(step_index := step) -> void:
			var elapsed := float(step_index + 1) * step_time
			for reel_index in range(slot_reels.size()):
				slot_tick_requested.emit()
				if elapsed < float(slot_stop_times[reel_index]):
					var symbol_id: String = slot_symbol_pool[randi() % slot_symbol_pool.size()]
					slot_reels[reel_index].texture = TextureFactory.slot_symbol(symbol_id)
				elif reel_index < slot_target_symbols.size():
					slot_reels[reel_index].texture = TextureFactory.slot_symbol(slot_target_symbols[reel_index])
		)
	sequence.tween_interval(0.12)
	sequence.tween_callback(func() -> void:
		slot_spinning = false
		for reel_index in range(min(slot_reels.size(), slot_target_symbols.size())):
			slot_reels[reel_index].texture = TextureFactory.slot_symbol(slot_target_symbols[reel_index])
		_show_slot_rewards()
	)

func _layout_hud_for_orientation() -> void:
	var size := get_viewport().get_visible_rect().size
	var portrait := size.y > size.x
	if portrait:
		_apply_portrait_layout(size)
	else:
		_apply_landscape_layout()

func _layout_art(rect: TextureRect, bounds: Rect2) -> void:
	if rect == null:
		return
	rect.offset_left = bounds.position.x
	rect.offset_top = bounds.position.y
	rect.offset_right = bounds.position.x + bounds.size.x
	rect.offset_bottom = bounds.position.y + bounds.size.y

func _apply_pixel_button_style(button: Button, texture: Texture2D) -> void:
	if texture == null:
		return
	var style := StyleBoxTexture.new()
	style.texture = texture
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

func _apply_portrait_layout(size: Vector2) -> void:
	health_bar.offset_left = 18.0
	health_bar.offset_top = 16.0
	health_bar.offset_right = min(size.x - 18.0, 346.0)
	health_bar.offset_bottom = 48.0
	stats.offset_left = 18.0
	stats.offset_top = 58.0
	stats.offset_right = size.x * 0.56
	stats.offset_bottom = 178.0
	_layout_art(stats_panel, Rect2(8.0, 8.0, max(340.0, stats.offset_right + 12.0), 184.0))
	var right_panel_left := size.x * 0.56
	wave_label.offset_left = right_panel_left
	wave_label.offset_top = 18.0
	wave_label.offset_right = size.x - 18.0
	wave_label.offset_bottom = 48.0
	var right_width: float = size.x - 18.0 - right_panel_left
	var col_width: float = (right_width - 10.0) * 0.5
	weapons_label.offset_left = right_panel_left
	weapons_label.offset_top = 122.0
	weapons_label.offset_right = right_panel_left + col_width
	weapons_label.offset_bottom = 330.0
	weapons_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	_layout_icon_row(weapon_icon_row, Rect2(weapons_label.offset_left, 58.0, col_width, 60.0))
	relics_label.offset_left = right_panel_left + col_width + 10.0
	relics_label.offset_top = 122.0
	relics_label.offset_right = size.x - 18.0
	relics_label.offset_bottom = 330.0
	relics_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	_layout_icon_row(relic_icon_row, Rect2(relics_label.offset_left, 58.0, col_width, 60.0))
	_layout_art(right_panel, Rect2(right_panel_left - 12.0, 52.0, size.x - right_panel_left + 4.0, 290.0))
	_layout_bottom_xp(size)
	wave_alert.anchor_left = 0.0
	wave_alert.anchor_right = 0.0
	wave_alert.offset_left = 18.0
	wave_alert.offset_right = size.x - 18.0
	wave_alert.offset_top = 332.0
	wave_alert.offset_bottom = 418.0
	hint.offset_left = 18.0
	hint.offset_top = size.y - 248.0
	hint.offset_right = size.x - 18.0
	hint.offset_bottom = size.y - 198.0
	_layout_exit_run_button(size, true)
	restart_button.offset_left = size.x * 0.2
	restart_button.offset_top = size.y * 0.76
	restart_button.offset_right = size.x * 0.8
	restart_button.offset_bottom = size.y * 0.82
	main_menu_button.offset_left = size.x * 0.2
	main_menu_button.offset_top = size.y * 0.835
	main_menu_button.offset_right = size.x * 0.8
	main_menu_button.offset_bottom = size.y * 0.895
	_layout_performance_hud(size)
	var panel := level_up_panel as Control
	var panel_size := Vector2(max(420.0, size.x - 96.0), min(size.y * 0.72, 860.0))
	_center_panel(panel, size, panel_size)
	event_badge.offset_left = 62.0
	event_badge.offset_right = size.x - 62.0
	var options := level_up_overlay.get_node("Panel/Options") as GridContainer
	options.columns = 1
	_layout_vertical_options(options, panel_size)
	_layout_slot_machine(panel_size)

func _apply_landscape_layout() -> void:
	var viewport_size := get_viewport().get_visible_rect().size
	health_bar.offset_left = 24.0
	health_bar.offset_top = 18.0
	health_bar.offset_right = 392.0
	health_bar.offset_bottom = 50.0
	stats.offset_left = 24.0
	stats.offset_top = 62.0
	stats.offset_right = 520.0
	stats.offset_bottom = 190.0
	_layout_art(stats_panel, Rect2(14.0, 8.0, 520.0, 190.0))
	wave_label.offset_left = 874.0
	wave_label.offset_top = 20.0
	wave_label.offset_right = 1252.0
	wave_label.offset_bottom = 54.0
	var land_right_width: float = 1252.0 - 874.0
	var land_col_width: float = (land_right_width - 10.0) * 0.5
	weapons_label.offset_left = 874.0
	weapons_label.offset_top = 122.0
	weapons_label.offset_right = 874.0 + land_col_width
	weapons_label.offset_bottom = 300.0
	weapons_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	_layout_icon_row(weapon_icon_row, Rect2(weapons_label.offset_left, 58.0, land_col_width, 60.0))
	relics_label.offset_left = 874.0 + land_col_width + 10.0
	relics_label.offset_top = 122.0
	relics_label.offset_right = 1252.0
	relics_label.offset_bottom = 300.0
	relics_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	_layout_icon_row(relic_icon_row, Rect2(relics_label.offset_left, 58.0, land_col_width, 60.0))
	_layout_art(right_panel, Rect2(860.0, 50.0, 408.0, 260.0))
	_layout_bottom_xp(viewport_size)
	wave_alert.anchor_left = 0.5
	wave_alert.anchor_right = 0.5
	wave_alert.offset_left = -360.0
	wave_alert.offset_right = 360.0
	wave_alert.offset_top = 90.0
	wave_alert.offset_bottom = 186.0
	hint.offset_left = 24.0
	hint.offset_top = 666.0
	hint.offset_right = 780.0
	hint.offset_bottom = 704.0
	_layout_exit_run_button(viewport_size, false)
	restart_button.offset_left = 520.0
	restart_button.offset_top = 594.0
	restart_button.offset_right = 760.0
	restart_button.offset_bottom = 650.0
	main_menu_button.offset_left = 520.0
	main_menu_button.offset_top = 660.0
	main_menu_button.offset_right = 760.0
	main_menu_button.offset_bottom = 716.0
	_layout_performance_hud(viewport_size)
	var panel := level_up_panel as Control
	var panel_size := Vector2(760.0, min(760.0, viewport_size.y - 64.0))
	_center_panel(panel, viewport_size, panel_size)
	event_badge.offset_left = 276.0
	event_badge.offset_right = 468.0
	var options := level_up_overlay.get_node("Panel/Options") as GridContainer
	options.columns = 1
	_layout_vertical_options(options, panel_size)
	_layout_slot_machine(panel_size)

func _center_panel(panel: Control, viewport_size: Vector2, panel_size: Vector2) -> void:
	panel.offset_left = (viewport_size.x - panel_size.x) * 0.5
	panel.offset_top = (viewport_size.y - panel_size.y) * 0.5
	panel.offset_right = panel.offset_left + panel_size.x
	panel.offset_bottom = panel.offset_top + panel_size.y

func _layout_performance_hud(size: Vector2) -> void:
	if performance_label == null:
		return
	performance_label.offset_left = size.x - 230.0
	performance_label.offset_top = size.y - 116.0
	performance_label.offset_right = size.x - 12.0
	performance_label.offset_bottom = size.y - 12.0

func _layout_icon_row(row: Control, bounds: Rect2) -> void:
	if row == null:
		return
	row.offset_left = bounds.position.x
	row.offset_top = bounds.position.y
	row.offset_right = bounds.position.x + bounds.size.x
	row.offset_bottom = bounds.position.y + bounds.size.y

func _layout_exit_run_button(size: Vector2, portrait: bool) -> void:
	if exit_run_button == null:
		return
	var button_size := Vector2(128.0, 54.0)
	var left := 18.0
	var bottom := size.y - 18.0
	if portrait:
		bottom = size.y - 248.0
	exit_run_button.offset_left = left
	exit_run_button.offset_top = bottom - button_size.y
	exit_run_button.offset_right = left + button_size.x
	exit_run_button.offset_bottom = bottom

func _layout_bottom_xp(size: Vector2) -> void:
	if xp_bar == null or level_label == null:
		return
	var width: float = min(size.x * 0.76, 560.0)
	var left: float = (size.x - width) * 0.5
	health_bar.offset_left = left
	health_bar.offset_right = left + width
	health_bar.offset_top = size.y - 120.0
	health_bar.offset_bottom = size.y - 90.0
	xp_bar.offset_left = left
	xp_bar.offset_right = left + width
	xp_bar.offset_top = size.y - 42.0
	xp_bar.offset_bottom = size.y - 14.0
	level_label.offset_left = left
	level_label.offset_right = left + width
	level_label.offset_top = size.y - 74.0
	level_label.offset_bottom = size.y - 42.0

func _layout_vertical_options(options: GridContainer, panel_size: Vector2) -> void:
	var visible_count := 0
	for button in upgrade_buttons:
		if button.visible:
			visible_count += 1
	visible_count = max(1, visible_count)
	options.add_theme_constant_override("h_separation", 0)
	var gap := 8.0
	options.add_theme_constant_override("v_separation", int(gap))
	var option_width: float = clampf(panel_size.x * 0.72, 280.0, min(520.0, panel_size.x - 96.0))
	var max_options_height := panel_size.y - 230.0
	var option_height: float = clampf((max_options_height - gap * float(visible_count - 1)) / float(visible_count), 62.0, 92.0)
	var total_height := option_height * float(visible_count) + gap * float(visible_count - 1)
	var top: float = clampf((panel_size.y - total_height) * 0.5 + 34.0, 128.0, max(128.0, panel_size.y - 82.0 - total_height))
	for button in upgrade_buttons:
		button.custom_minimum_size = Vector2(option_width, option_height)
		button.size = Vector2(option_width, option_height)
		button.clip_text = true
		button.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		var icon := button.get_node_or_null("Icon") as AnimatedSprite2D
		if icon != null:
			icon.position = Vector2(34.0, option_height * 0.5)
	options.offset_left = (panel_size.x - option_width) * 0.5
	options.offset_top = top
	options.offset_right = options.offset_left + option_width
	options.offset_bottom = top + total_height
	options.custom_minimum_size = Vector2(option_width, total_height)
	options.position = Vector2(options.offset_left, options.offset_top)
	options.size = Vector2(option_width, total_height)
	reroll_button.offset_left = options.offset_left
	reroll_button.offset_top = top + total_height + 110.0
	reroll_button.offset_right = options.offset_left + option_width
	reroll_button.offset_bottom = reroll_button.offset_top + 48.0

func _layout_slot_machine(panel_size: Vector2) -> void:
	var slot_size := Vector2(min(680.0, panel_size.x - 96.0), min(430.0, panel_size.y - 190.0))
	slot_machine.position = Vector2((panel_size.x - slot_size.x) * 0.5, 150.0)
	slot_machine.size = slot_size
	var reel_size := clampf(slot_size.x * 0.18, 108.0, 136.0)
	var gap := reel_size * 0.34
	var total_width := reel_size * 3.0 + gap * 2.0
	var start_x := (slot_size.x - total_width) * 0.5
	for reel_index in range(slot_reels.size()):
		var reel: TextureRect = slot_reels[reel_index]
		reel.offset_left = start_x + float(reel_index) * (reel_size + gap)
		reel.offset_top = slot_size.y * 0.24
		reel.offset_right = reel.offset_left + reel_size
		reel.offset_bottom = reel.offset_top + reel_size
	slot_jackpot_label.offset_left = 24.0
	slot_jackpot_label.offset_top = slot_size.y * 0.70
	slot_jackpot_label.offset_right = slot_size.x - 24.0
	slot_jackpot_label.offset_bottom = slot_size.y * 0.82

func _apply_bright_text_theme() -> void:
	var bright := Color(0.96, 1.0, 0.92, 1.0)
	var warm := Color(1.0, 0.94, 0.62, 1.0)
	var cool := Color(0.90, 0.98, 1.0, 1.0)
	var lavender := Color(0.96, 0.90, 1.0, 1.0)
	var shadow := Color(0.0, 0.0, 0.0, 1.0)
	var labels: Array[Label] = [stats, health_label, hint, wave_label, weapons_label, relics_label, wave_alert_label, level_up_title, event_badge, level_up_prompt, slot_jackpot_label]
	for label in labels:
		label.add_theme_color_override("font_shadow_color", shadow)
		label.add_theme_constant_override("shadow_offset_x", 2)
		label.add_theme_constant_override("shadow_offset_y", 2)
	stats.add_theme_font_size_override("font_size", 24)
	health_label.add_theme_font_size_override("font_size", 20)
	hint.add_theme_font_size_override("font_size", 20)
	wave_label.add_theme_font_size_override("font_size", 26)
	weapons_label.add_theme_font_size_override("font_size", 16)
	relics_label.add_theme_font_size_override("font_size", 16)
	weapons_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	relics_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	weapons_label.clip_text = true
	relics_label.clip_text = true
	weapons_label.vertical_alignment = VERTICAL_ALIGNMENT_TOP
	relics_label.vertical_alignment = VERTICAL_ALIGNMENT_TOP
	wave_alert_label.add_theme_font_size_override("font_size", 36)
	level_up_title.add_theme_font_size_override("font_size", 38)
	level_up_prompt.add_theme_font_size_override("font_size", 21)
	event_badge.add_theme_font_size_override("font_size", 21)
	slot_jackpot_label.add_theme_font_size_override("font_size", 21)
	reroll_button.add_theme_font_size_override("font_size", 22)
	restart_button.add_theme_font_size_override("font_size", 26)
	main_menu_button.add_theme_font_size_override("font_size", 26)
	if exit_run_button != null:
		exit_run_button.add_theme_font_size_override("font_size", 22)
		exit_run_button.add_theme_color_override("font_color", Color(1.0, 0.94, 0.62, 1.0))
		exit_run_button.add_theme_color_override("font_hover_color", Color.WHITE)
		exit_run_button.add_theme_color_override("font_pressed_color", Color.WHITE)
		exit_run_button.add_theme_color_override("font_shadow_color", Color(0.0, 0.0, 0.0, 1.0))
		exit_run_button.add_theme_constant_override("shadow_offset_x", 2)
		exit_run_button.add_theme_constant_override("shadow_offset_y", 2)
	for button in upgrade_buttons:
		button.add_theme_font_size_override("font_size", 20)
	stats.add_theme_color_override("font_color", bright)
	health_label.add_theme_color_override("font_color", Color(1.0, 0.98, 0.86, 1.0))
	hint.add_theme_color_override("font_color", lavender)
	wave_label.add_theme_color_override("font_color", warm)
	weapons_label.add_theme_color_override("font_color", cool)
	relics_label.add_theme_color_override("font_color", lavender)
	wave_alert_label.add_theme_color_override("font_color", Color(1.0, 0.96, 0.72, 1.0))
	level_up_title.add_theme_color_override("font_color", warm)
	level_up_prompt.add_theme_color_override("font_color", bright)
	event_badge.add_theme_color_override("font_color", Color(1.0, 0.98, 0.82, 1.0))
	slot_jackpot_label.add_theme_color_override("font_color", warm)

func _apply_panel_style(event_mode: bool, title: String) -> void:
	if event_mode:
		event_badge.show()
		level_up_panel.modulate = Color(0.74, 0.38, 0.36, 1)
		level_up_title.modulate = Color(1.0, 0.88, 0.52, 1)
		level_up_prompt.modulate = Color(1.0, 0.90, 0.86, 1)
		if title.contains("祝福"):
			event_badge.text = "临时祝福"
			event_badge.modulate = Color(0.44, 0.95, 0.86, 1)
		elif title.contains("悬赏"):
			event_badge.text = "精英悬赏"
			event_badge.modulate = Color(1.0, 0.62, 0.34, 1)
		else:
			event_badge.text = "恶魔交易"
			event_badge.modulate = Color(1.0, 0.42, 0.52, 1)
	else:
		event_badge.hide()
		level_up_panel.modulate = Color(0.55, 0.42, 0.68, 1)
		level_up_title.modulate = Color.WHITE
		level_up_prompt.modulate = Color.WHITE
