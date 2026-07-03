extends Control
class_name LevelUpPanel
## LevelUpPanel：升级选择面板，支持普通升级和拉霸奖励。

const DOTween := preload("res://scripts/utils/dotween.gd")
const CJKFontTheme := preload("res://scripts/ui/cjk_font_theme.gd")
const UITheme := preload("res://scripts/ui/ui_theme.gd")
const TextureFactory := preload("res://scripts/visuals/texture_factory.gd")
const UpgradePanelScript := preload("res://scripts/ui/UpgradePanel.gd")

signal upgrade_selected(upgrade_id: String)
signal reroll_requested
signal jackpot_reward_granted(upgrade_id: String)
signal jackpot_finished
signal slot_tick_requested

@onready var shade: ColorRect = $Shade
@onready var panel: Panel = $Panel
@onready var title_label: Label = $Panel/Title
@onready var event_badge: Label = $Panel/EventBadge
@onready var prompt_label: Label = $Panel/Prompt
@onready var reroll_button: Button = $Panel/RerollButton
@onready var upgrade_buttons := [
	$Panel/Options/DamageButton, $Panel/Options/FireRateButton, $Panel/Options/VitalityButton,
	$Panel/Options/Option4Button, $Panel/Options/Option5Button, $Panel/Options/Option6Button
]
@onready var slot_machine: Control = $Panel/SlotMachine
@onready var slot_frame: TextureRect = $Panel/SlotMachine/Frame
@onready var slot_reels: Array[TextureRect] = [$Panel/SlotMachine/Reel1, $Panel/SlotMachine/Reel2, $Panel/SlotMachine/Reel3]
@onready var slot_jackpot_label: Label = $Panel/SlotMachine/JackpotLabel

var current_upgrade_ids: Array[String] = []
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
var ui_burst_factory: Callable
var ui_burst_recycler: Callable
var option_card_texture: Texture2D = TextureFactory.pixel_ui_asset("option_card")

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	CJKFontTheme.apply_to_tree(self)
	hide()
	slot_machine.hide()
	event_badge.hide()
	reroll_button.pressed.connect(func(): reroll_requested.emit())
	for i in range(upgrade_buttons.size()):
		upgrade_buttons[i].pressed.connect(func(): _on_upgrade_pressed(i))

func _on_upgrade_pressed(index: int) -> void:
	if jackpot_animating or slot_spinning: return
	if index >= current_upgrade_ids.size(): return
	upgrade_selected.emit(current_upgrade_ids[index])

func show_level_up(options: Array, title := "升级暂停：选择一项继续", prompt_text := "选择一种献祭回报，然后继续生存。", allow_reroll := true) -> void:
	current_upgrade_ids.clear(); slot_machine.hide()
	title_label.text = title; prompt_label.text = prompt_text
	_apply_panel_style(UpgradePanelScript.is_event_mode(options), title, UpgradePanelScript.is_contract_mode(options))
	for i in range(upgrade_buttons.size()):
		if i >= options.size(): upgrade_buttons[i].hide(); _set_button_icon(upgrade_buttons[i], "", 46.0); continue
		var opt: Dictionary = options[i]; current_upgrade_ids.append(opt["id"])
		upgrade_buttons[i].show(); upgrade_buttons[i].disabled = false; upgrade_buttons[i].alignment = HORIZONTAL_ALIGNMENT_LEFT
		upgrade_buttons[i].text = UpgradePanelScript.option_text(opt)
		_set_button_icon(upgrade_buttons[i], _option_icon_id(opt), 46.0)
		upgrade_buttons[i].add_theme_color_override("font_color", Color(1.0, 0.98, 0.82, 1.0))
		upgrade_buttons[i].add_theme_color_override("font_hover_color", Color.WHITE)
		upgrade_buttons[i].add_theme_color_override("font_pressed_color", Color.WHITE)
		upgrade_buttons[i].add_theme_color_override("font_shadow_color", Color.BLACK)
		upgrade_buttons[i].add_theme_constant_override("shadow_offset_x", 2)
		upgrade_buttons[i].add_theme_constant_override("shadow_offset_y", 2)
		upgrade_buttons[i].modulate = UITheme.rarity_background(str(opt.get("rarity", "普通"))).lightened(1.15)
	reroll_button.visible = allow_reroll
	show(); _layout_options()
	DOTween.pop_in(self, panel, 0.20, Vector2.ONE * 0.94, Vector2.ONE, "level_panel")

func hide_level_up() -> void:
	hide(); slot_machine.hide(); slot_spinning = false
	DOTween.kill(self, "slot_spin_sequence"); DOTween.kill(self, "jackpot_sequence")
	jackpot_animating = false; jackpot_reward_ids.clear(); event_badge.hide()
	panel.modulate = Color(0.55, 0.42, 0.68, 1)

func set_rerolls_left(count: int) -> void:
	reroll_button.text = "重新 Roll（%d）" % count; reroll_button.disabled = count <= 0

func show_slot_machine(reel_ids: Array, options: Array, jackpot: bool) -> void:
	slot_target_symbols = reel_ids.duplicate(); slot_reward_options = options.duplicate()
	slot_is_jackpot = jackpot; slot_spinning = true
	title_label.text = "命运拉霸"; prompt_label.text = "齿轮正在咬合，命运开始转动。"
	slot_jackpot_label.text = "三连命运符号 = 6张奖励卡" if jackpot else "命运抽出 3 张奖励卡"
	slot_jackpot_label.modulate = Color(1.0, 0.88, 0.32) if jackpot else Color(0.86, 0.78, 1.0)
	_apply_panel_style(false, "命运拉霸")
	for btn in upgrade_buttons: btn.hide(); _set_button_icon(btn, "", 46.0)
	for reel: TextureRect in slot_reels: reel.texture = null
	slot_machine.show(); reroll_button.hide(); show(); _layout_options()
	DOTween.pop_in(self, panel, 0.20, Vector2.ONE * 0.94, Vector2.ONE, "slot_panel")
	_start_slot_spin()

func set_ui_burst_pool(factory: Callable, recycler: Callable) -> void:
	ui_burst_factory = factory; ui_burst_recycler = recycler

# ── 拉霸逻辑 ───────────────────────────────────────────────────────────────
func _start_slot_spin() -> void:
	var seq := DOTween.sequence(self, "slot_spin_sequence")
	var step := 0.06; var max_t := slot_stop_times[slot_stop_times.size() - 1]
	for s in range(int(ceil(max_t / step))):
		seq.tween_interval(step)
		seq.tween_callback(func(si := s) -> void:
			var elapsed := float(si + 1) * step
			for ri in range(slot_reels.size()):
				slot_tick_requested.emit()
				if elapsed < slot_stop_times[ri]:
					slot_reels[ri].texture = TextureFactory.slot_symbol(slot_symbol_pool[randi() % slot_symbol_pool.size()])
				elif ri < slot_target_symbols.size():
					slot_reels[ri].texture = TextureFactory.slot_symbol(slot_target_symbols[ri])
		)
	seq.tween_interval(0.12)
	seq.tween_callback(func() -> void:
		slot_spinning = false
		for ri in range(min(slot_reels.size(), slot_target_symbols.size())):
			slot_reels[ri].texture = TextureFactory.slot_symbol(slot_target_symbols[ri])
		_show_slot_rewards()
	)

func _show_slot_rewards() -> void:
	if slot_is_jackpot: _show_jackpot(); return
	show_level_up(slot_reward_options, "命运奖池", "三连同符号会开启更多选择。挑一张，把好运带走。", false)

func _show_jackpot() -> void:
	current_upgrade_ids.clear(); slot_machine.hide(); jackpot_reward_ids.clear()
	title_label.text = "JACKPOT / 全拿！"; prompt_label.text = "命运偏向你，6 个奖励将连续注入。"
	_apply_panel_style(false, "JACKPOT / 全拿！")
	for i in range(upgrade_buttons.size()):
		if i >= slot_reward_options.size(): upgrade_buttons[i].hide(); continue
		var opt: Dictionary = slot_reward_options[i]; jackpot_reward_ids.append(str(opt["id"]))
		upgrade_buttons[i].show(); upgrade_buttons[i].disabled = true
		upgrade_buttons[i].text = UpgradePanelScript.jackpot_text(opt)
		upgrade_buttons[i].add_theme_color_override("font_color", Color(1.0, 0.98, 0.74, 1.0))
		upgrade_buttons[i].modulate = Color.from_hsv(fmod(float(i) / 6.0 + 0.02, 1.0), 0.64, 1.0, 1.0)
	reroll_button.hide(); show(); jackpot_animating = true; jackpot_step_index = 0
	_spawn_jackpot_burst(36)
	var seq := DOTween.sequence(self, "jackpot_sequence"); seq.tween_interval(jackpot_hold_seconds)
	for ri in range(jackpot_reward_ids.size()):
		seq.tween_interval(0.16)
		seq.tween_callback(func(idx := ri) -> void:
			upgrade_buttons[idx].modulate = Color(1.0, 0.92, 0.62, 1.0)
			jackpot_step_index = idx + 1; jackpot_reward_granted.emit(jackpot_reward_ids[idx])
		)
	seq.tween_callback(func() -> void: jackpot_animating = false; jackpot_finished.emit())

func _spawn_jackpot_burst(count: int) -> void:
	if not ui_burst_factory.is_valid(): return
	var center := panel.global_position + panel.size * 0.5
	for i in range(count):
		var block: ColorRect = ui_burst_factory.call()
		block.color = Color.from_hsv(float(i) / max(1, count), 0.78, 1.0, 1.0)
		block.size = Vector2(14.0, 14.0) * randf_range(0.8, 1.55); block.global_position = center; block.rotation = randf() * TAU
		add_child(block)
		var dir := Vector2.RIGHT.rotated(TAU * float(i) / count + randf_range(-0.22, 0.22))
		var tw := DOTween.sequence(block, "jackpot_burst"); tw.set_parallel(true)
		tw.tween_property(block, "global_position", center + dir * randf_range(180.0, 420.0), 0.95).set_trans(Tween.TRANS_QUART).set_ease(Tween.EASE_OUT)
		tw.tween_property(block, "rotation", block.rotation + randf_range(-4.0, 4.0), 0.95)
		tw.tween_property(block, "modulate:a", 0.0, 0.95).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)
		tw.chain().tween_callback(func(node := block) -> void:
			if ui_burst_recycler.is_valid(): ui_burst_recycler.call(node, "ui_burst")
			else: node.queue_free()
		)

# ── 辅助方法 ───────────────────────────────────────────────────────────────
func _apply_panel_style(event_mode: bool, title: String, contract_mode := false) -> void:
	if contract_mode:
		event_badge.show(); panel.modulate = Color(0.34, 0.42, 0.58, 1)
		title_label.modulate = Color(0.94, 0.98, 1.0, 1); prompt_label.modulate = Color(0.88, 0.94, 1.0, 1)
		event_badge.text = "契约"; event_badge.modulate = Color(0.78, 0.88, 1.0, 1); return
	if event_mode:
		event_badge.show(); panel.modulate = Color(0.74, 0.38, 0.36, 1)
		title_label.modulate = Color(1.0, 0.88, 0.52, 1); prompt_label.modulate = Color(1.0, 0.90, 0.86, 1)
		if title.contains("祝福"): event_badge.text = "临时祝福"; event_badge.modulate = Color(0.44, 0.95, 0.86, 1)
		elif title.contains("悬赏"): event_badge.text = "精英悬赏"; event_badge.modulate = Color(1.0, 0.62, 0.34, 1)
		else: event_badge.text = "恶魔交易"; event_badge.modulate = Color(1.0, 0.42, 0.52, 1)
	else:
		event_badge.hide(); panel.modulate = Color(0.55, 0.42, 0.68, 1)
		title_label.modulate = Color.WHITE; prompt_label.modulate = Color.WHITE

func _set_button_icon(button: Button, item_id: String, icon_size: float) -> void:
	var icon: AnimatedSprite2D = button.get_node_or_null("Icon") as AnimatedSprite2D
	if item_id == "": if icon != null: icon.hide(); return
	var frames := TextureFactory.item_icon_frames(item_id)
	if frames == null:
		if icon != null: icon.hide()
		return
	if icon == null:
		icon = AnimatedSprite2D.new(); icon.name = "Icon"; icon.centered = true; icon.z_index = 20
		button.add_child(icon)
	icon.sprite_frames = frames; icon.scale = Vector2.ONE * (icon_size / 96.0)
	icon.position = Vector2(34.0, max(icon_size * 0.62, button.size.y * 0.5)); icon.show()
	var anim_names := frames.get_animation_names(); if anim_names != null and not anim_names.is_empty(): icon.play(str(anim_names[0]))

func _option_icon_id(option: Dictionary) -> String:
	var oid := str(option.get("id", "")); var parts := oid.split(":")
	if parts.size() >= 2:
		match parts[0]:
			"unlock", "upgrade", "evolve", "super_evolve", "passive", "fusion": return parts[1]
			"stat": return "stat:%s" % parts[1]
	return str(option.get("icon_id", ""))

func _layout_options() -> void:
	var vs := get_viewport().get_visible_rect().size
	var psize := Vector2(760.0, min(760.0, vs.y - 64.0)) if vs.x > vs.y else Vector2(max(420.0, vs.x - 96.0), min(vs.y * 0.72, 860.0))
	panel.offset_left = (vs.x - psize.x) * 0.5; panel.offset_top = (vs.y - psize.y) * 0.5
	panel.offset_right = panel.offset_left + psize.x; panel.offset_bottom = panel.offset_top + psize.y
	var opts := $Panel/Options; var vc := 0
	for btn in upgrade_buttons: if btn.visible: vc += 1
	vc = max(1, vc); var gap := 8.0; var ow := clampf(psize.x * 0.72, 280.0, min(520.0, psize.x - 96.0))
	var moh := psize.y - 230.0; var oh := clampf((moh - gap * float(vc - 1)) / float(vc), 62.0, 92.0)
	var th := oh * float(vc) + gap * float(vc - 1)
	var top := clampf((psize.y - th) * 0.5 + 34.0, 128.0, max(128.0, psize.y - 82.0 - th))
	for btn in upgrade_buttons: btn.custom_minimum_size = Vector2(ow, oh); btn.size = Vector2(ow, oh)
	opts.offset_left = (psize.x - ow) * 0.5; opts.offset_top = top
	opts.offset_right = opts.offset_left + ow; opts.offset_bottom = top + th
	opts.position = Vector2(opts.offset_left, opts.offset_top); opts.size = Vector2(ow, th)
	reroll_button.offset_left = opts.offset_left; reroll_button.offset_top = top + th + 110.0
	reroll_button.offset_right = opts.offset_left + ow; reroll_button.offset_bottom = reroll_button.offset_top + 48.0
	_layout_slot_machine(psize)

func _layout_slot_machine(psize: Vector2) -> void:
	var ss := Vector2(min(680.0, psize.x - 96.0), min(430.0, psize.y - 190.0))
	slot_machine.position = Vector2((psize.x - ss.x) * 0.5, 150.0); slot_machine.size = ss
	var rs := clampf(ss.x * 0.18, 108.0, 136.0); var rg := rs * 0.34
	var tw := rs * 3.0 + rg * 2.0; var sx := (ss.x - tw) * 0.5
	for ri in range(slot_reels.size()):
		var reel: TextureRect = slot_reels[ri] as TextureRect
		reel.offset_left = sx + float(ri) * (rs + rg); reel.offset_top = ss.y * 0.24
		reel.offset_right = reel.offset_left + rs; reel.offset_bottom = reel.offset_top + rs
	slot_jackpot_label.offset_left = 24.0; slot_jackpot_label.offset_top = ss.y * 0.70
	slot_jackpot_label.offset_right = ss.x - 24.0; slot_jackpot_label.offset_bottom = ss.y * 0.82
