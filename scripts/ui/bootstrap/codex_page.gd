extends ScrollContainer
class_name CodexPage

const CJKFontTheme := preload("res://scripts/ui/cjk_font_theme.gd")
const TextureFactory := preload("res://scripts/visuals/texture_factory.gd")
const BootstrapUIHelpers := preload("res://scripts/ui/bootstrap/bootstrap_ui_helpers.gd")

@onready var content: VBoxContainer = $Content

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	CJKFontTheme.apply_to_tree(self)
	_build_codex()
	hide()

func _build_codex() -> void:
	for child in content.get_children():
		child.queue_free()
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
	CJKFontTheme.apply_to_tree(content)

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
	var content_box := VBoxContainer.new()
	content_box.name = "Content"
	content_box.add_theme_constant_override("separation", 10)
	card.add_child(content_box)
	var label := Label.new()
	label.name = "Title"
	label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.add_theme_font_size_override("font_size", 22)
	label.add_theme_color_override("font_color", Color(0.92, 1.0, 0.94, 1.0))
	label.text = title_text if entries.size() > 0 else "%s\n%s" % [title_text, "\n".join(lines)]
	content_box.add_child(label)
	if entries.size() > 0:
		var icon_grid := GridContainer.new()
		icon_grid.name = "ItemGrid"
		icon_grid.columns = 1
		icon_grid.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		icon_grid.add_theme_constant_override("h_separation", 0)
		icon_grid.add_theme_constant_override("v_separation", 8)
		content_box.add_child(icon_grid)
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
			BootstrapUIHelpers.set_icon_sprite(icon, item_id, 54.0)
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
		items.append({"id": weapon_id, "name": BootstrapUIHelpers.weapon_title(weapon_id), "description": descriptions.get(weapon_id, "")})
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

func _weapon_icon_ids() -> Array[String]:
	return ["blood_bolt", "ghost_blades", "shadow_spikes", "soul_nova", "doom_laser", "plague_bomb", "abyss_tentacle", "reaping_scythe", "grave_familiar", "frost_orb", "thunder_chain", "void_mines"]
