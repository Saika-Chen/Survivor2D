extends CanvasLayer

const DOTween := preload("res://scripts/utils/dotween.gd")
const UITheme := preload("res://scripts/ui/ui_theme.gd")
const TextureFactory := preload("res://scripts/visuals/texture_factory.gd")

signal upgrade_selected(upgrade_id: String)
signal restart_requested
signal joystick_changed(input_vector: Vector2)
signal reroll_requested
signal jackpot_reward_granted(upgrade_id: String)
signal jackpot_finished

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

var current_upgrade_ids: Array[String] = []
var joystick_active := false
var joystick_pointer_id := -1
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

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	level_up_overlay.hide()
	slot_machine.hide()
	wave_alert.hide()
	restart_button.hide()
	event_badge.hide()
	health_bar.texture_under = TextureFactory.health_bar_bg()
	health_bar.texture_progress = TextureFactory.health_bar_fill()
	health_bar.texture_over = TextureFactory.health_bar_frame()
	wave_alert_frame.texture = TextureFactory.warning_banner()
	restart_button.pressed.connect(_on_restart_pressed)
	reroll_button.pressed.connect(_on_reroll_pressed)
	for button_index in range(upgrade_buttons.size()):
		upgrade_buttons[button_index].pressed.connect(_on_upgrade_button_pressed.bind(button_index))
	get_viewport().size_changed.connect(_layout_mobile_joystick)
	get_viewport().size_changed.connect(_layout_hud_for_orientation)
	_configure_mobile_controls()
	_reset_joystick()
	_layout_hud_for_orientation()

func _input(event: InputEvent) -> void:
	if level_up_overlay.visible and event is InputEventKey and event.pressed and not event.echo:
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

	if event is InputEventScreenTouch:
		if event.pressed and _is_inside_joystick(event.position):
			joystick_active = true
			joystick_pointer_id = event.index
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
				_update_joystick(event.position)
			elif joystick_pointer_id == -2:
				joystick_active = false
				joystick_pointer_id = -1
				_reset_joystick()
	elif event is InputEventMouseMotion and joystick_active and joystick_pointer_id == -2:
		_update_joystick(event.position)

func set_stats(health: float, max_health: float, score: int, elapsed: float, enemy_count: int, level: int, experience: int, experience_to_next: int, wave: int, max_wave: int, time_left: float, weapons_summary: String, relics_summary: String) -> void:
	var seconds := int(elapsed) % 60
	var minutes := int(elapsed) / 60
	stats.text = "生命: %d / %d\n等级: %d  XP: %d / %d\n击杀: %d\n时间: %02d:%02d\n敌人: %d" % [
		int(ceil(health)),
		int(max_health),
		level,
		experience,
		experience_to_next,
		score,
		minutes,
		seconds,
		enemy_count
	]
	health_bar.max_value = max_health
	health_bar.value = health
	health_label.text = "HP %d / %d" % [int(ceil(health)), int(max_health)]
	wave_label.text = "第 %02d / %02d 波  %02d秒" % [wave, max_wave, max(0, int(ceil(time_left)))]
	weapons_label.text = weapons_summary
	relics_label.text = relics_summary

func show_game_over(score: int, elapsed: float) -> void:
	var seconds := int(elapsed) % 60
	var minutes := int(elapsed) / 60
	hint.text = "死亡降临 - 击杀 %d - 生存 %02d:%02d" % [score, minutes, seconds]
	restart_button.show()

func show_victory(elapsed: float) -> void:
	var seconds := int(elapsed) % 60
	var minutes := int(elapsed) / 60
	hint.text = "深渊君王已陨落 - 生存 %02d:%02d" % [minutes, seconds]
	restart_button.show()

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
			continue
		var option: Dictionary = options[option_index]
		var rarity := str(option.get("rarity", "普通"))
		var category := str(option.get("category", "属性"))
		current_upgrade_ids.append(option["id"])
		upgrade_buttons[option_index].show()
		upgrade_buttons[option_index].disabled = false
		upgrade_buttons[option_index].text = "%s\n[%s] %s\n%s" % [_category_icon(category), rarity, option["title"], option["description"]]
		upgrade_buttons[option_index].add_theme_color_override("font_color", UITheme.rarity_color(rarity))
		upgrade_buttons[option_index].add_theme_color_override("font_hover_color", Color.WHITE)
		upgrade_buttons[option_index].add_theme_color_override("font_pressed_color", Color.WHITE)
		upgrade_buttons[option_index].add_theme_color_override("font_focus_color", UITheme.rarity_color(rarity).lightened(0.25))
		upgrade_buttons[option_index].modulate = UITheme.rarity_background(rarity).lightened(0.75)
	reroll_button.visible = allow_reroll
	level_up_overlay.show()
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
	slot_frame.texture = TextureFactory.slot_machine_frame()
	slot_jackpot_label.text = "三连命运符号 = 6张奖励卡" if jackpot else "命运抽出 3 张奖励卡"
	slot_jackpot_label.modulate = Color(1.0, 0.88, 0.32) if jackpot else Color(0.86, 0.78, 1.0)
	_apply_panel_style(false, "命运拉霸")
	for button in upgrade_buttons:
		button.hide()
	for reel in slot_reels:
		reel.texture = null
	slot_machine.show()
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

func _on_reroll_pressed() -> void:
	reroll_requested.emit()

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
	var center := joystick_base.global_position + joystick_base.size * 0.5
	return position.distance_to(center) <= _joystick_radius() * 1.35

func _update_joystick(position: Vector2) -> void:
	var center := joystick_base.global_position + joystick_base.size * 0.5
	var joystick_radius := _joystick_radius()
	var offset := (position - center).limit_length(joystick_radius)
	DOTween.kill(self, "joystick_stick_reset")
	joystick_stick.position = joystick_base.size * 0.5 + offset - joystick_stick.size * 0.5
	_animate_joystick_state(true)
	joystick_changed.emit(offset / joystick_radius)

func _reset_joystick() -> void:
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
	mobile_joystick.visible = mobile_controls_enabled
	_layout_mobile_joystick()

func _layout_mobile_joystick() -> void:
	if not mobile_controls_enabled:
		return
	var viewport_size := get_viewport().get_visible_rect().size
	var joystick_size := clampf(min(viewport_size.x, viewport_size.y) * 0.26, 168.0, 230.0)
	mobile_joystick.offset_left = 18.0
	mobile_joystick.offset_top = -joystick_size - 18.0
	mobile_joystick.offset_right = 18.0 + joystick_size
	mobile_joystick.offset_bottom = -18.0
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
		upgrade_buttons[option_index].modulate = UITheme.rarity_background(rarity).darkened(0.18)
	reroll_button.hide()
	level_up_overlay.show()
	jackpot_animating = true
	jackpot_step_index = 0
	var sequence := DOTween.sequence(self, "jackpot_sequence")
	for reward_index in range(jackpot_reward_ids.size()):
		sequence.tween_interval(0.10 if reward_index > 0 else 0.28)
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

func _apply_portrait_layout(size: Vector2) -> void:
	health_bar.offset_left = 18.0
	health_bar.offset_top = 16.0
	health_bar.offset_right = size.x - 18.0
	health_bar.offset_bottom = 52.0
	stats.offset_left = 18.0
	stats.offset_top = 60.0
	stats.offset_right = size.x * 0.55
	stats.offset_bottom = 186.0
	wave_label.offset_left = size.x * 0.58
	wave_label.offset_top = 18.0
	wave_label.offset_right = size.x - 18.0
	wave_label.offset_bottom = 48.0
	weapons_label.offset_left = 18.0
	weapons_label.offset_top = 184.0
	weapons_label.offset_right = size.x - 18.0
	weapons_label.offset_bottom = 242.0
	weapons_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	relics_label.offset_left = 18.0
	relics_label.offset_top = 244.0
	relics_label.offset_right = size.x - 18.0
	relics_label.offset_bottom = 312.0
	relics_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
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
	restart_button.offset_left = size.x * 0.2
	restart_button.offset_top = size.y * 0.76
	restart_button.offset_right = size.x * 0.8
	restart_button.offset_bottom = size.y * 0.82
	var panel := level_up_panel as Control
	panel.offset_left = 26.0
	panel.offset_top = 128.0
	panel.offset_right = size.x - 26.0
	panel.offset_bottom = size.y - 120.0
	event_badge.offset_left = 62.0
	event_badge.offset_right = size.x - 62.0
	var options := level_up_overlay.get_node("Panel/Options") as GridContainer
	options.columns = 2

func _apply_landscape_layout() -> void:
	health_bar.offset_left = 24.0
	health_bar.offset_top = 18.0
	health_bar.offset_right = 384.0
	health_bar.offset_bottom = 54.0
	stats.offset_left = 24.0
	stats.offset_top = 66.0
	stats.offset_right = 520.0
	stats.offset_bottom = 214.0
	wave_label.offset_left = 874.0
	wave_label.offset_top = 20.0
	wave_label.offset_right = 1252.0
	wave_label.offset_bottom = 54.0
	weapons_label.offset_left = 380.0
	weapons_label.offset_top = 20.0
	weapons_label.offset_right = 850.0
	weapons_label.offset_bottom = 82.0
	weapons_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	relics_label.offset_left = 874.0
	relics_label.offset_top = 58.0
	relics_label.offset_right = 1252.0
	relics_label.offset_bottom = 142.0
	relics_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
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
	restart_button.offset_left = 520.0
	restart_button.offset_top = 594.0
	restart_button.offset_right = 760.0
	restart_button.offset_bottom = 650.0
	var panel := level_up_panel as Control
	panel.offset_left = 268.0
	panel.offset_top = 92.0
	panel.offset_right = 1012.0
	panel.offset_bottom = 628.0
	event_badge.offset_left = 276.0
	event_badge.offset_right = 468.0
	var options := level_up_overlay.get_node("Panel/Options") as GridContainer
	options.columns = 3

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
