extends Node

const MAX_WEAPON_LEVEL := 7
const MAX_WEAPONS := 3
const SIZE_SCALE := 1.0
const WingmanScene := preload("res://scenes/weapons/Wingman.tscn")

signal weapon_fired(weapon_family: String)

var player: Node2D
var enemies: Node2D
var projectiles: Node2D
var weapon_zones: Node2D
var projectile_scene: PackedScene
var zone_scene: PackedScene

var weapons := {"blood_bolt": 1}
var evolved := {}
var super_evolved := {}
var passives := {}
var fusion_recipes := {
	"crimson_reaper": {"weapons": ["blood_bolt", "reaping_scythe"], "title": "血神之怒", "description": "超大范围镰刃风暴 + 追踪血弹，吸血翻倍。", "tags": ["血系", "环绕", "弹幕"]},
	"psychic_tempest": {"weapons": ["ghost_blades", "doom_laser"], "title": "灵能风暴", "description": "环刃龙卷 + 多重贯穿激光，弹速暴增。", "tags": ["灵能", "环绕", "弹幕"]},
	"abyss_lord": {"weapons": ["shadow_spikes", "abyss_tentacle"], "title": "深渊主宰", "description": "触手抽打同时爆发地刺，冷却极短。", "tags": ["深渊", "区域", "召唤"]},
	"ruin_nova": {"weapons": ["soul_nova", "plague_bomb"], "title": "毁灭新星", "description": "灵火爆裂 + 连锁瘟疫爆炸，范围巨大。", "tags": ["爆裂", "区域", "弹幕"]},
	"frost_legion": {"weapons": ["grave_familiar", "frost_orb"], "title": "冰墓军团", "description": "冰星僚机群同时射击 + 冰弹减速，数量翻倍。", "tags": ["召唤", "弹幕", "灵能"]},
	"void_thunder": {"weapons": ["thunder_chain", "void_mines"], "title": "虚空雷狱", "description": "雷链 + 虚空地雷同时触发，范围覆盖全屏。", "tags": ["区域", "灵能", "深渊"]},
}
var timers := {}
var orbit_angle := 0.0
var damage_multiplier := 1.0
var cooldown_multiplier := 1.0
var radius_multiplier := 1.0
var projectile_speed_multiplier := 1.0
var synergy_damage_bonus := 1.0
var synergy_cooldown_bonus := 1.0
var synergy_radius_bonus := 1.0
var synergy_projectile_speed_bonus := 1.0
var temp_damage_bonus := 1.0
var temp_cooldown_bonus := 1.0
var temp_radius_bonus := 1.0
var temp_projectile_speed_bonus := 1.0
@export_range(0.0, 100.0, 0.1) var slot_jackpot_chance_percent := 5.0
var max_weapon_zones := 90
var max_projectiles := 140
var wingmen: Array[Node2D] = []
var active_synergies: Array[String] = []
var weapon_focus := {}
var locked_weapon_id := ""
var attack_flat_bonus := 0.0
var relic_luck_bonus := 0.0
var projectile_factory: Callable
var projectile_recycler: Callable
var zone_factory: Callable
var zone_recycler: Callable
var crit_chance := 0.05
var crit_damage_multiplier := 1.75
var passive_health_bonus := 8.0
var lifesteal_chance := 0.50
var lifesteal_amount := 10.0

var definitions := {
	"blood_bolt": {
		"title": "血咒弹",
		"description": "追踪最近敌人的暗红弹丸。",
		"evolved_id": "crimson_judgment",
		"passive": "blood_pact",
		"evolved_title": "猩红审判",
		"sfx": "projectile",
		"tags": ["血系", "弹幕"],
		"traits": {}
	},
	"ghost_blades": {
		"title": "幽魂环刃",
		"description": "在身边切割敌人的灵刃。",
		"evolved_id": "wraith_storm",
		"passive": "spirit_core",
		"evolved_title": "亡魂风暴",
		"sfx": "orbit",
		"tags": ["灵能", "环绕"],
		"traits": {}
	},
	"shadow_spikes": {
		"title": "暗影地刺",
		"description": "在敌人脚下爆发尖刺。",
		"evolved_id": "abyss_scream",
		"passive": "abyss_mark",
		"evolved_title": "深渊尖啸",
		"sfx": "summon",
		"tags": ["深渊", "区域"],
		"traits": {"slow": 0.88}
	},
	"soul_nova": {
		"title": "灵火新星",
		"description": "周期性释放范围爆炸。",
		"evolved_id": "soul_eclipse",
		"passive": "ember_crown",
		"evolved_title": "灭魂日冕",
		"sfx": "burst",
		"tags": ["爆裂", "区域"],
		"traits": {}
	},
	"doom_laser": {
		"title": "毁灭激光",
		"description": "贯穿直线的猩红光束，命中击退敌人。",
		"evolved_id": "void_lance",
		"passive": "lens_of_ruin",
		"evolved_title": "虚空长枪",
		"sfx": "laser",
		"tags": ["灵能", "弹幕"],
		"traits": {"knockback": 2.2}
	},
	"plague_bomb": {
		"title": "瘟疫炸弹",
		"description": "投向怪群并爆炸，减速敌人。",
		"evolved_id": "grave_mortar",
		"passive": "powder_heart",
		"evolved_title": "坟场迫击炮",
		"sfx": "burst",
		"tags": ["爆裂", "弹幕"],
		"traits": {"slow": 0.78}
	},
	"abyss_tentacle": {
		"title": "深渊触手",
		"description": "从脚下抽打附近敌人，减速敌人。",
		"evolved_id": "old_one_grasp",
		"passive": "eldritch_eye",
		"evolved_title": "旧日之握",
		"sfx": "summon",
		"tags": ["深渊", "召唤"],
		"traits": {"slow": 0.82}
	},
	"reaping_scythe": {
		"title": "穿魂镰刃",
		"description": "穿透敌群的镰刃，命中击退敌人。",
		"evolved_id": "death_carousel",
		"passive": "bone_wheel",
		"evolved_title": "死神回廊",
		"sfx": "orbit",
		"tags": ["血系", "环绕"],
		"traits": {"knockback": 4.2}
	},
	"grave_familiar": {
		"title": "幽冥僚机",
		"description": "环绕玩家并自动射击的灵能僚机。",
		"evolved_id": "seraph_swarm",
		"passive": "clockwork_heart",
		"evolved_title": "炽天使蜂群",
		"sfx": "summon",
		"tags": ["召唤", "弹幕"],
		"traits": {"slow": 0.92}
	},
	"frost_orb": {
		"title": "寒星法球",
		"description": "向敌群发射冰冷星弹，减速敌人。",
		"evolved_id": "glacial_comet",
		"passive": "frost_heart",
		"evolved_title": "冰墓彗星",
		"sfx": "projectile",
		"tags": ["灵能", "弹幕"],
		"traits": {"slow": 0.68}
	},
	"thunder_chain": {
		"title": "雷链符文",
		"description": "在敌群中落下连锁雷击。",
		"evolved_id": "storm_crown",
		"passive": "storm_totem",
		"evolved_title": "风暴王冠",
		"sfx": "laser",
		"tags": ["灵能", "区域"],
		"traits": {}
	},
	"void_mines": {
		"title": "虚空地雷",
		"description": "在身边布下吞噬减速的虚空陷阱。",
		"evolved_id": "event_horizon",
		"passive": "void_anchor",
		"evolved_title": "事件视界",
		"sfx": "burst",
		"tags": ["深渊", "区域"],
		"traits": {"slow": 0.72}
	}
}

var passive_definitions := {
		"blood_pact": {"title": "鲜血契约", "description": "攻击 +0.08，暴击率 +3%，吸血率 +2%。血咒弹满级后可合体。", "tags": ["血系"]},
		"spirit_core": {"title": "幽魂核心", "description": "冷却 -4%，移速 +6。幽魂环刃满级后可合体。", "tags": ["灵能"]},
		"abyss_mark": {"title": "深渊印记", "description": "范围 +4%，吸附 +10。暗影地刺满级后可合体。", "tags": ["深渊"]},
		"ember_crown": {"title": "余烬王冠", "description": "攻击 +0.07，最大生命 +8。灵火新星满级后可合体。", "tags": ["爆裂"]},
		"lens_of_ruin": {"title": "毁灭透镜", "description": "弹速 +6%，暴击伤害 +12%。毁灭激光满级后可合体。", "tags": ["灵能"]},
		"powder_heart": {"title": "火药心脏", "description": "范围 +5%，最大生命 +8。瘟疫炸弹满级后可合体。", "tags": ["爆裂"]},
		"eldritch_eye": {"title": "邪神之眼", "description": "冷却 -5%，受伤无敌 +0.08秒。深渊触手满级后可合体。", "tags": ["深渊"]},
		"bone_wheel": {"title": "骨质轮轴", "description": "攻击 +0.06，暴击率 +4%，吸血量 +1。穿魂镰刃满级后可合体。", "tags": ["血系"]},
	"clockwork_heart": {"title": "机心圣核", "description": "弹速 +10%，移速 +14。幽冥僚机满级后可合体。", "tags": ["召唤"]},
		"frost_heart": {"title": "霜心棱镜", "description": "弹速 +5%，范围 +4%。寒星法球满级后可合体。", "tags": ["灵能"]},
		"storm_totem": {"title": "风暴图腾", "description": "冷却 -4%，暴击率 +3%。雷链符文满级后可合体。", "tags": ["灵能"]},
		"void_anchor": {"title": "虚空锚点", "description": "范围 +5%，吸附 +12，攻击 +0.05。虚空地雷满级后可合体。", "tags": ["深渊"]}
	}

var passive_effects := {
		"blood_pact": [{"stat": "damage", "amount": 0.08}, {"stat": "crit_chance", "amount": 0.03}, {"stat": "lifesteal_chance", "amount": 0.02}],
		"spirit_core": [{"stat": "cooldown", "amount": 0.04}, {"stat": "speed_flat", "amount": 6.0}],
		"abyss_mark": [{"stat": "radius", "amount": 0.04}, {"stat": "magnet_flat", "amount": 10.0}],
		"ember_crown": [{"stat": "damage", "amount": 0.07}, {"stat": "health_flat", "amount": 8.0}],
		"lens_of_ruin": [{"stat": "projectile_speed", "amount": 0.06}, {"stat": "crit_damage", "amount": 0.12}],
		"powder_heart": [{"stat": "radius", "amount": 0.05}, {"stat": "health_flat", "amount": 8.0}],
		"eldritch_eye": [{"stat": "cooldown", "amount": 0.05}, {"stat": "invulnerability_flat", "amount": 0.08}],
		"bone_wheel": [{"stat": "damage", "amount": 0.06}, {"stat": "crit_chance", "amount": 0.04}, {"stat": "lifesteal_amount", "amount": 1.0}],
		"clockwork_heart": [{"stat": "projectile_speed", "amount": 0.05}, {"stat": "speed_flat", "amount": 8.0}],
		"frost_heart": [{"stat": "projectile_speed", "amount": 0.05}, {"stat": "radius", "amount": 0.04}],
		"storm_totem": [{"stat": "cooldown", "amount": 0.04}, {"stat": "crit_chance", "amount": 0.03}],
		"void_anchor": [{"stat": "radius", "amount": 0.05}, {"stat": "magnet_flat", "amount": 12.0}, {"stat": "damage", "amount": 0.05}]
	}

func _ensure_passive_health_bonus() -> void:
	for passive_id in passive_definitions.keys():
		var effects: Array = passive_effects.get(passive_id, [])
		var has_health := false
		for effect_index in range(effects.size()):
			var effect_data: Dictionary = effects[effect_index]
			if effect_data.get("stat", "") == "health_flat":
				effect_data["amount"] = passive_health_bonus
				effects[effect_index] = effect_data
				has_health = true
		if not has_health:
			effects.append({"stat": "health_flat", "amount": passive_health_bonus})
		passive_effects[passive_id] = effects
		var passive_data: Dictionary = passive_definitions[passive_id]
		var description := str(passive_data.get("description", ""))
		if not "生命" in description:
			passive_data["description"] = description + " 生命 +8。"
			passive_definitions[passive_id] = passive_data

var synergy_definitions := {
	"血系": {
		"2": {"title": "血系共鸣", "description": "血系武器伤害提高 18%。", "damage": 1.18},
		"3": {"title": "血河狂潮", "description": "血系与环绕伤害再提高，冷却缩短。", "damage": 1.30, "cooldown": 0.92}
	},
	"灵能": {
		"2": {"title": "灵能回路", "description": "弹丸速度提高 18%，冷却缩短。", "projectile_speed": 1.18, "cooldown": 0.94},
		"3": {"title": "虚空矩阵", "description": "灵能武器射程感更强，伤害提高。", "projectile_speed": 1.28, "damage": 1.16}
	},
	"爆裂": {
		"2": {"title": "爆裂引信", "description": "范围扩大 20%。", "radius": 1.20},
		"3": {"title": "余烬狂欢", "description": "范围与伤害双提升。", "radius": 1.32, "damage": 1.18}
	},
	"深渊": {
		"2": {"title": "深渊咒印", "description": "范围扩大 16%，冷却缩短。", "radius": 1.16, "cooldown": 0.94},
		"3": {"title": "旧神低语", "description": "深渊技能大幅提速。", "radius": 1.24, "cooldown": 0.88}
	},
	"召唤": {
		"2": {"title": "召唤协奏", "description": "僚机与召唤物攻速提高。", "cooldown": 0.90},
		"3": {"title": "军团降临", "description": "召唤伤害与弹速同步提高。", "damage": 1.18, "projectile_speed": 1.18}
	}
}

func setup(new_player: Node2D, new_enemies: Node2D, new_projectiles: Node2D, new_weapon_zones: Node2D, new_projectile_scene: PackedScene, new_zone_scene: PackedScene, starting_weapon := "blood_bolt") -> void:
	player = new_player
	enemies = new_enemies
	projectiles = new_projectiles
	weapon_zones = new_weapon_zones
	projectile_scene = new_projectile_scene
	zone_scene = new_zone_scene
	if not definitions.has(starting_weapon):
		starting_weapon = "blood_bolt"
	weapons = {starting_weapon: 1}
	weapon_focus = {starting_weapon: 1}
	evolved.clear()
	passives.clear()
	_ensure_passive_health_bonus()
	timers.clear()
	orbit_angle = 0.0
	damage_multiplier = 1.0
	cooldown_multiplier = 1.0
	radius_multiplier = 1.0
	projectile_speed_multiplier = 1.0
	synergy_damage_bonus = 1.0
	synergy_cooldown_bonus = 1.0
	synergy_radius_bonus = 1.0
	synergy_projectile_speed_bonus = 1.0
	temp_damage_bonus = 1.0
	temp_cooldown_bonus = 1.0
	temp_radius_bonus = 1.0
	temp_projectile_speed_bonus = 1.0
	attack_flat_bonus = 0.0
	locked_weapon_id = starting_weapon
	crit_chance = 0.05
	crit_damage_multiplier = 1.75
	active_synergies.clear()
	_clear_wingmen()

func configure_hero_rules(hero_data: Dictionary) -> void:
	locked_weapon_id = str(hero_data.get("initial_weapon", locked_weapon_id))

func set_projectile_factory(factory: Callable) -> void:
	projectile_factory = factory

func set_projectile_recycler(recycler: Callable) -> void:
	projectile_recycler = recycler

func set_zone_factory(factory: Callable) -> void:
	zone_factory = factory

func set_zone_recycler(recycler: Callable) -> void:
	zone_recycler = recycler

func tick(delta: float) -> void:
	if player == null:
		return
	orbit_angle += delta * 3.2
	_sync_wingmen()
	for weapon_id in weapons.keys():
		timers[weapon_id] = float(timers.get(weapon_id, 0.0)) - delta
		if timers[weapon_id] <= 0.0:
			_fire_weapon(weapon_id)
			timers[weapon_id] = _cooldown_for(weapon_id)

func build_upgrade_options(count: int = 3) -> Array:
	var options: Array = []
	for weapon_id in weapons.keys():
		if _can_evolve(weapon_id):
			var definition: Dictionary = definitions[weapon_id]
			if not evolved.has(weapon_id):
				options.append({
					"id": "evolve:%s" % weapon_id,
					"title": "进化：%s" % definition["evolved_title"],
					"description": "%s Lv5 → 进化终极武器。" % definition["title"],
					"category": "进化",
					"weight": 120
				})
			else:
				options.append({
					"id": "super_evolve:%s" % weapon_id,
					"title": "超进化：%s·改" % definition["evolved_title"],
					"description": "%s Lv7 → 二次进化，威力暴涨。" % definition["title"],
					"category": "超进化",
					"weight": 100
				})

	var fusion_id: String = _can_fuse()
	if fusion_id != "":
		var recipe: Dictionary = fusion_recipes[fusion_id]
		options.append({
			"id": "fusion:%s" % fusion_id,
			"title": "融合：%s" % recipe["title"],
			"description": "%s + %s → %s" % [definitions[recipe["weapons"][0]]["title"], definitions[recipe["weapons"][1]]["title"], recipe["title"]],
			"category": "融合",
			"weight": 200
		})

	for candidate_weapon_id in definitions.keys():
		if not weapons.has(candidate_weapon_id):
			if weapons.size() >= MAX_WEAPONS:
				continue
			var definition: Dictionary = definitions[candidate_weapon_id]
			options.append({"id": "unlock:%s" % candidate_weapon_id, "title": "新武器：%s" % definition["title"], "description": definition["description"], "category": "武器", "weight": 48})
		elif int(weapons[candidate_weapon_id]) < MAX_WEAPON_LEVEL:
			var definition: Dictionary = definitions[candidate_weapon_id]
			options.append({"id": "upgrade:%s" % candidate_weapon_id, "title": "强化：%s" % definition["title"], "description": "等级 %d → %d" % [weapons[candidate_weapon_id], int(weapons[candidate_weapon_id]) + 1], "category": "强化", "weight": 95})

	for passive_id in passive_definitions.keys():
		if not passives.has(passive_id):
			var passive: Dictionary = passive_definitions[passive_id]
			options.append({"id": "passive:%s" % passive_id, "title": "遗物：%s" % passive["title"], "description": passive["description"], "category": "遗物", "weight": 8 + int(round(relic_luck_bonus))})

	options.append({"id": "stat:damage", "title": "黑血碎片", "description": "攻击 +0.06。", "category": "符文", "weight": 46})
	options.append({"id": "stat:minor_damage", "title": "钝刃磨石", "description": "攻击 +0.02。", "category": "符文", "weight": 68})
	options.append({"id": "stat:crit_chance", "title": "裂纹骰骨", "description": "暴击率 +1%。", "category": "符文", "weight": 42})
	options.append({"id": "stat:cooldown", "title": "短咒残页", "description": "冷却缩短 3%。", "category": "符文", "weight": 42})
	options.append({"id": "stat:radius", "title": "粗糙尺规", "description": "非终极武器范围 +4%。", "category": "符文", "weight": 44})
	options.append({"id": "stat:projectile_speed", "title": "轻羽弹道", "description": "弹丸速度 +5%。", "category": "符文", "weight": 36})
	options.append({"id": "stat:vitality", "title": "旧布绷带", "description": "生命 +8，移速 +4。", "category": "符文", "weight": 46})
	options.append({"id": "stat:magnet", "title": "磁石耳坠", "description": "经验拾取范围 +10。", "category": "符文", "weight": 44})
	options.append({"id": "stat:tiny_magnet", "title": "铁屑磁针", "description": "经验拾取范围 +4。", "category": "符文", "weight": 52})
	options.append({"id": "stat:tiny_cooldown", "title": "风干墨条", "description": "冷却缩短 1%。", "category": "符文", "weight": 38})
	options.append({"id": "stat:heal", "title": "生命药瓶", "description": "恢复 18% 最大生命。", "category": "符文", "weight": 48})
	options.append({"id": "stat:invulnerability", "title": "薄纱护符", "description": "受伤无敌 +0.05秒。", "category": "符文", "weight": 52})
	options.append({"id": "stat:nothing", "title": "发暗铜片", "description": "也许下一次会有好运。", "category": "符文", "weight": 38})

	return _pick_options(options, count)


func build_slot_bundle() -> Dictionary:
	var jackpot := randf() * 100.0 < slot_jackpot_chance_percent
	var reels: Array[String] = []
	if jackpot:
		var symbol: String = ["weapon", "relic", "power", "fate", "jackpot"][randi() % 5]
		reels = [symbol, symbol, symbol]
	else:
		for index in range(3):
			reels.append(["weapon", "relic", "power", "fate", "jackpot"][randi() % 5])
	return {
		"reels": reels,
		"jackpot": jackpot,
		"options": build_upgrade_options(6 if jackpot else 3),
		"auto_claim_all": jackpot
	}

func apply_upgrade(option_id: String) -> Dictionary:
	var parts := option_id.split(":")
	if parts.size() < 2:
		return {"kind": "none"}
	var kind := parts[0]
	var value := parts[1]
	match kind:
		"unlock":
			weapons[value] = 1
			weapon_focus[value] = int(weapon_focus.get(value, 0)) + 1
			if value == "grave_familiar":
				_sync_wingmen(true)
			_refresh_synergies()
			return {"kind": "weapon", "weapon": value}
		"upgrade":
			weapons[value] = min(MAX_WEAPON_LEVEL, int(weapons.get(value, 1)) + 1)
			weapon_focus[value] = int(weapon_focus.get(value, 0)) + 1
			if value == "grave_familiar":
				_sync_wingmen(true)
			_refresh_synergies()
			return {"kind": "weapon", "weapon": value}
		"passive":
			passives[value] = true
			_apply_passive_effect(value)
			_refresh_synergies()
			return {"kind": "passive", "passive": value, "effects": passive_effects.get(value, [])}
		"evolve":
			var definition: Dictionary = definitions[value]
			evolved[value] = true
			weapon_focus[value] = int(weapon_focus.get(value, 0)) + 2
			if value == "grave_familiar":
				_sync_wingmen(true)
			_refresh_synergies()
			return {"kind": "evolve", "weapon": value, "evolved_id": definition["evolved_id"]}
		"super_evolve":
			super_evolved[value] = true
			weapon_focus[value] = int(weapon_focus.get(value, 0)) + 3
			if value == "grave_familiar":
				_sync_wingmen(true)
			_refresh_synergies()
			return {"kind": "super_evolve", "weapon": value}
		"fusion":
			var recipe: Dictionary = fusion_recipes[value]
			weapons.erase(recipe["weapons"][0])
			weapons.erase(recipe["weapons"][1])
			evolved.erase(recipe["weapons"][0])
			evolved.erase(recipe["weapons"][1])
			super_evolved.erase(recipe["weapons"][0])
			super_evolved.erase(recipe["weapons"][1])
			weapons[value] = 10
			_refresh_synergies()
			return {"kind": "fusion", "weapon": value, "fusion_id": value}
		"stat":
			return {"kind": "stat", "stat": value}
	return {"kind": "none"}

func get_summary() -> String:
	var pieces: Array[String] = []
	for weapon_id in weapons.keys():
		var title: String
		if fusion_recipes.has(weapon_id):
			title = fusion_recipes[weapon_id]["title"]
		else:
			title = definitions[weapon_id]["title"]
		var suffix: String
		if super_evolved.has(weapon_id):
			suffix = "★★"
		elif evolved.has(weapon_id):
			suffix = "★"
		else:
			suffix = "Lv%d" % int(weapons[weapon_id])
		pieces.append("%s %s" % [title, suffix])
	return " | ".join(pieces)

func get_weapon_icon_ids() -> Array[String]:
	var ids: Array[String] = []
	for weapon_id in weapons.keys():
		ids.append(str(weapon_id))
	return ids

func current_attack_power() -> float:
	var base_damage := 36.0  # blood_bolt Lv1 base
	var primary_weapon_id: String = locked_weapon_id if locked_weapon_id != "" else "blood_bolt"
	if weapons.has(primary_weapon_id):
		var level := int(weapons[primary_weapon_id])
		base_damage = 28.0 + level * 8.0  # matches _fire_blood_bolt formula
		if evolved.has(primary_weapon_id):
			base_damage *= 1.9
	return base_damage * damage_multiplier * synergy_damage_bonus * temp_damage_bonus

func get_passive_summary() -> String:
	if passives.is_empty():
		return "遗物: 无"
	var pieces: Array[String] = []
	for passive_id in passives.keys():
		var passive: Dictionary = passive_definitions[passive_id]
		pieces.append(passive["title"])
	if not active_synergies.is_empty():
		pieces.append("羁绊：" + " / ".join(active_synergies))
	return "遗物: " + " / ".join(pieces)

func get_passive_icon_ids() -> Array[String]:
	var ids: Array[String] = []
	for passive_id in passives.keys():
		ids.append(str(passive_id))
	return ids

func _fire_origin() -> Vector2:
	return player.global_position + Vector2(-80, 80)

func _fire_weapon(weapon_id: String) -> void:
	if fusion_recipes.has(weapon_id):
		var recipe: Dictionary = fusion_recipes[weapon_id]
		_fire_weapon(recipe["weapons"][0])
		_fire_weapon(recipe["weapons"][1])
		return
	match weapon_id:
		"blood_bolt":
			_fire_blood_bolt()
		"ghost_blades":
			_fire_ghost_blades()
		"shadow_spikes":
			_fire_shadow_spikes()
		"soul_nova":
			_fire_soul_nova()
		"doom_laser":
			_fire_doom_laser()
		"plague_bomb":
			_fire_plague_bomb()
		"abyss_tentacle":
			_fire_abyss_tentacle()
		"reaping_scythe":
			_fire_reaping_scythe()
		"grave_familiar":
			_fire_grave_familiar()
		"frost_orb":
			_fire_frost_orb()
		"thunder_chain":
			_fire_thunder_chain()
		"void_mines":
			_fire_void_mines()

func _fire_blood_bolt() -> void:
	var level := int(weapons["blood_bolt"])
	var count := 3 if evolved.has("blood_bolt") else 1 + level / 3
	if active_synergies.has("血河狂潮"):
		count += 1
	var fired := false
	for index in range(count):
		var target := _nearest_enemy(index, 400.0)
		if target == null:
			continue
		var projectile: Node2D = _new_projectile()
		projectile.global_position = _fire_origin() + Vector2(-24, 24)
		projectile.direction = player.global_position.direction_to(target.global_position).rotated((float(index) - float(count - 1) * 0.5) * 0.12)
		projectile.damage = (28.0 + level * 8.0) * (1.9 if evolved.has("blood_bolt") else 1.0) * damage_multiplier * synergy_damage_bonus * temp_damage_bonus
		projectile.speed = 760.0 * projectile_speed_multiplier * synergy_projectile_speed_bonus * temp_projectile_speed_bonus
		projectile.radius = 8.0 if evolved.has("blood_bolt") else 6.0
		projectile.weapon_id = "crimson_judgment" if evolved.has("blood_bolt") else "blood_bolt"
		projectile.pierce = (4 if active_synergies.has("血河狂潮") else 3) if evolved.has("blood_bolt") else (1 if active_synergies.has("血河狂潮") else 0)
		projectile.world_size = player.world_size
		_add_projectile(projectile)
		fired = true
	if fired:
		_emit_weapon_sfx("blood_bolt")

func _fire_ghost_blades() -> void:
	var level := int(weapons["ghost_blades"])
	var count := 8 if evolved.has("ghost_blades") else 3 + level
	if active_synergies.has("虚空矩阵"):
		count += 2
	var distance := 76.0 if evolved.has("ghost_blades") else 56.0
	if evolved.has("ghost_blades"):
		distance += sin(orbit_angle * 1.8) * 16.0
	for index in range(count):
		var angle := orbit_angle + TAU * float(index) / float(count)
		_spawn_zone(player.global_position + Vector2.RIGHT.rotated(angle) * distance, (42.0 + level * 8.0) * damage_multiplier * synergy_damage_bonus * temp_damage_bonus, 34.0 * radius_multiplier * synergy_radius_bonus * temp_radius_bonus, 0.13, "wraith_storm" if evolved.has("ghost_blades") else "ghost_blades", evolved.has("ghost_blades"), angle)
	if evolved.has("ghost_blades"):
		for index in range(max(2, count / 4)):
			var angle := -orbit_angle + TAU * float(index) / float(max(2, count / 4))
			_spawn_zone(player.global_position + Vector2.RIGHT.rotated(angle) * (distance * 0.62), (24.0 + level * 4.0) * damage_multiplier * synergy_damage_bonus * temp_damage_bonus, 22.0 * radius_multiplier * synergy_radius_bonus * temp_radius_bonus, 0.10, "wraith_storm", true, angle)
	_emit_weapon_sfx("ghost_blades")

func _fire_shadow_spikes() -> void:
	var level := int(weapons["shadow_spikes"])
	var count := 8 if evolved.has("shadow_spikes") else 3 + level
	if active_synergies.has("旧神低语"):
		count += 3
	var fired := false
	for index in range(count):
		var target := _nearest_enemy(index, 400.0)
		if target == null:
			target = player
		_spawn_zone(target.global_position, (34.0 + level * 8.0) * damage_multiplier * synergy_damage_bonus * temp_damage_bonus, (7.0 + level * 2.0) * radius_multiplier * synergy_radius_bonus * temp_radius_bonus, 0.42, "abyss_scream" if evolved.has("shadow_spikes") else "shadow_spikes", evolved.has("shadow_spikes"), randf() * TAU)
		if evolved.has("shadow_spikes"):
			_spawn_zone(target.global_position + Vector2(randf_range(-30, 30), randf_range(-30, 30)), (20.0 + level * 5.0) * damage_multiplier * synergy_damage_bonus * temp_damage_bonus, (5.0 + level * 1.0) * radius_multiplier * synergy_radius_bonus * temp_radius_bonus, 0.28, "abyss_scream", true, randf() * TAU)
		fired = true
	if fired:
		_emit_weapon_sfx("shadow_spikes")

func _fire_soul_nova() -> void:
	var level := int(weapons["soul_nova"])
	var radius := (170.0 if evolved.has("soul_nova") else 82.0 + level * 8.0) * radius_multiplier * synergy_radius_bonus * temp_radius_bonus
	var damage := (54.0 + level * 12.0) * damage_multiplier * synergy_damage_bonus * temp_damage_bonus
	_spawn_zone(player.global_position, damage * (1.5 if evolved.has("soul_nova") else 1.0), radius, 0.5, "soul_eclipse" if evolved.has("soul_nova") else "soul_nova", evolved.has("soul_nova"), 0.0)
	if evolved.has("soul_nova"):
		_spawn_zone(player.global_position, damage * 0.55, radius * 0.58, 0.24, "soul_eclipse", true, 0.0)
	_emit_weapon_sfx("soul_nova")

func _fire_doom_laser() -> void:
	var level := int(weapons["doom_laser"])
	var target := _nearest_enemy()
	if target == null:
		return
	var direction := player.global_position.direction_to(target.global_position)
	var length := 920.0 if evolved.has("doom_laser") else 620.0 + level * 55.0
	for step in range(5 + level):
		_spawn_zone(player.global_position + direction * (80.0 + length * float(step) / float(5 + level)), (46.0 + level * 12.0) * damage_multiplier * synergy_damage_bonus * temp_damage_bonus, (30.0 + level * 2.0) * radius_multiplier * synergy_radius_bonus * temp_radius_bonus, 0.18, "void_lance" if evolved.has("doom_laser") else "doom_laser", evolved.has("doom_laser"), direction.angle() + PI * 0.5)
	if evolved.has("doom_laser"):
		for branch in [-0.18, 0.18]:
			for step in range(3 + level / 2):
				var branch_direction := direction.rotated(branch)
				_spawn_zone(player.global_position + branch_direction * (110.0 + length * 0.55 * float(step) / float(max(1, 3 + level / 2))), (24.0 + level * 7.0) * damage_multiplier * synergy_damage_bonus * temp_damage_bonus, 18.0 * radius_multiplier * synergy_radius_bonus * temp_radius_bonus, 0.13, "void_lance", true, branch_direction.angle() + PI * 0.5)
	_emit_weapon_sfx("doom_laser")

func _fire_plague_bomb() -> void:
	var level := int(weapons["plague_bomb"])
	var count := 3 if evolved.has("plague_bomb") else 1 + level / 3
	if active_synergies.has("余烬狂欢"):
		count += 1
	var fired := false
	for index in range(count):
		var target := _nearest_enemy(index, 400.0)
		if target == null:
			target = player
		var offset := Vector2(randf_range(-40.0, 40.0), randf_range(-40.0, 40.0))
		_spawn_zone(target.global_position + offset, (78.0 + level * 18.0) * damage_multiplier * synergy_damage_bonus * temp_damage_bonus, (43.0 + level * 4.0) * radius_multiplier * synergy_radius_bonus * temp_radius_bonus, 0.72, "grave_mortar" if evolved.has("plague_bomb") else "plague_bomb", evolved.has("plague_bomb"), 0.0)
		if evolved.has("plague_bomb"):
			_spawn_zone(target.global_position + offset * 0.45, (30.0 + level * 9.0) * damage_multiplier * synergy_damage_bonus * temp_damage_bonus, 24.0 * radius_multiplier * synergy_radius_bonus * temp_radius_bonus, 0.34, "grave_mortar", true, 0.0)
		fired = true
	if fired:
		_emit_weapon_sfx("plague_bomb")

func _fire_abyss_tentacle() -> void:
	var level := int(weapons["abyss_tentacle"])
	var count := 6 if evolved.has("abyss_tentacle") else 2 + level
	if active_synergies.has("旧神低语"):
		count += 2
	for index in range(count):
		var target := _nearest_enemy(index, 400.0)
		if target == null:
			target = player
		var angle := randf() * TAU
		_spawn_zone(target.global_position, (52.0 + level * 11.0) * damage_multiplier * synergy_damage_bonus * temp_damage_bonus, (28.0 + level * 4.0) * radius_multiplier * synergy_radius_bonus * temp_radius_bonus, 0.36, "old_one_grasp" if evolved.has("abyss_tentacle") else "abyss_tentacle", evolved.has("abyss_tentacle"), angle + PI * 0.5)
		if evolved.has("abyss_tentacle"):
			_spawn_zone(target.global_position + Vector2(randf_range(-30, 30), randf_range(-30, 30)), (26.0 + level * 6.0) * damage_multiplier * synergy_damage_bonus * temp_damage_bonus, 20.0 * radius_multiplier * synergy_radius_bonus * temp_radius_bonus, 0.22, "old_one_grasp", true, angle + PI * 1.5)
	_emit_weapon_sfx("abyss_tentacle")

func _fire_reaping_scythe() -> void:
	var level := int(weapons["reaping_scythe"])
	var count := 6 if evolved.has("reaping_scythe") else 2 + level
	if active_synergies.has("血河狂潮"):
		count += 2
	for index in range(count):
		var projectile: Node2D = _new_projectile()
		projectile.global_position = _fire_origin() + Vector2(-24, 24)
		projectile.direction = Vector2.RIGHT.rotated(orbit_angle + TAU * float(index) / float(count))
		projectile.damage = (44.0 + level * 10.0) * (1.55 if evolved.has("reaping_scythe") else 1.0) * damage_multiplier * synergy_damage_bonus * temp_damage_bonus
		projectile.speed = 520.0 * projectile_speed_multiplier * synergy_projectile_speed_bonus * temp_projectile_speed_bonus
		projectile.radius = 3.0
		projectile.weapon_id = "death_carousel" if evolved.has("reaping_scythe") else "reaping_scythe"
		projectile.pierce = 10 if evolved.has("reaping_scythe") else 4 + level
		projectile.world_size = player.world_size
		_add_projectile(projectile)
		if evolved.has("reaping_scythe"):
			var reverse_projectile: Node2D = _new_projectile()
			reverse_projectile.global_position = _fire_origin() + Vector2(-24, 24)
			reverse_projectile.direction = projectile.direction.rotated(PI / float(max(2, count)))
			reverse_projectile.damage = projectile.damage * 0.58
			reverse_projectile.speed = projectile.speed * 0.82
			reverse_projectile.radius = 2.0
			reverse_projectile.weapon_id = "death_carousel"
			reverse_projectile.pierce = 5
			reverse_projectile.world_size = player.world_size
			_add_projectile(reverse_projectile)
	_emit_weapon_sfx("reaping_scythe")

func _fire_grave_familiar() -> void:
	if wingmen.is_empty():
		return
	var level := int(weapons["grave_familiar"])
	var fired := false
	for wingman in wingmen:
		var target := _nearest_enemy()
		if target == null:
			continue
		var projectile: Node2D = _new_projectile()
		projectile.global_position = wingman.global_position
		projectile.direction = wingman.global_position.direction_to(target.global_position)
		projectile.damage = (24.0 + level * 7.0) * (1.7 if evolved.has("grave_familiar") else 1.0) * damage_multiplier * synergy_damage_bonus * temp_damage_bonus
		projectile.speed = (720.0 if evolved.has("grave_familiar") else 620.0) * projectile_speed_multiplier * synergy_projectile_speed_bonus * temp_projectile_speed_bonus
		projectile.radius = 7.0 if evolved.has("grave_familiar") else 5.0
		projectile.weapon_id = "seraph_swarm" if evolved.has("grave_familiar") else "grave_familiar"
		projectile.pierce = 2 if evolved.has("grave_familiar") else 0
		projectile.world_size = player.world_size
		_add_projectile(projectile)
		if evolved.has("grave_familiar"):
			var side_projectile: Node2D = _new_projectile()
			side_projectile.global_position = wingman.global_position
			side_projectile.direction = projectile.direction.rotated(0.18 if randf() > 0.5 else -0.18)
			side_projectile.damage = projectile.damage * 0.62
			side_projectile.speed = projectile.speed * 0.94
			side_projectile.radius = 5.0
			side_projectile.weapon_id = "seraph_swarm"
			side_projectile.pierce = 1
			side_projectile.world_size = player.world_size
			_add_projectile(side_projectile)
		fired = true
	if fired:
		_emit_weapon_sfx("grave_familiar")

func _fire_frost_orb() -> void:
	var level := int(weapons["frost_orb"])
	var count := 5 if evolved.has("frost_orb") else 1 + level / 2
	if active_synergies.has("虚空矩阵"):
		count += 1
	var fired := false
	for index in range(count):
		var target := _nearest_enemy(index, 400.0)
		if target == null:
			continue
		var projectile: Node2D = _new_projectile()
		projectile.global_position = _fire_origin() + Vector2(-24, 24)
		projectile.direction = player.global_position.direction_to(target.global_position).rotated((float(index) - float(count - 1) * 0.5) * 0.10)
		projectile.damage = (30.0 + level * 8.0) * (1.7 if evolved.has("frost_orb") else 1.0) * damage_multiplier * synergy_damage_bonus * temp_damage_bonus
		projectile.speed = (690.0 if evolved.has("frost_orb") else 600.0) * projectile_speed_multiplier * synergy_projectile_speed_bonus * temp_projectile_speed_bonus
		projectile.radius = 10.0 if evolved.has("frost_orb") else 7.0
		projectile.weapon_id = "glacial_comet" if evolved.has("frost_orb") else "frost_orb"
		projectile.pierce = 5 if evolved.has("frost_orb") else 1 + level / 2
		projectile.world_size = player.world_size
		_add_projectile(projectile)
		fired = true
	if fired:
		_emit_weapon_sfx("frost_orb")

func _fire_thunder_chain() -> void:
	var level := int(weapons["thunder_chain"])
	var strikes := 6 if evolved.has("thunder_chain") else 2 + level
	if active_synergies.has("虚空矩阵"):
		strikes += 2
	var origin := _nearest_enemy()
	if origin == null:
		return
	for index in range(strikes):
		var target := _nearest_enemy(index, 400.0)
		if target == null:
			target = origin
		var offset := Vector2(randf_range(-26.0, 26.0), randf_range(-26.0, 26.0))
		_spawn_zone(target.global_position + offset, (34.0 + level * 10.0) * (1.55 if evolved.has("thunder_chain") else 1.0) * damage_multiplier * synergy_damage_bonus * temp_damage_bonus, (38.0 + level * 3.0) * radius_multiplier * synergy_radius_bonus * temp_radius_bonus, 0.22, "storm_crown" if evolved.has("thunder_chain") else "thunder_chain", evolved.has("thunder_chain"), randf() * TAU)
	if evolved.has("thunder_chain"):
		_spawn_zone(origin.global_position, (42.0 + level * 12.0) * damage_multiplier * synergy_damage_bonus * temp_damage_bonus, 82.0 * radius_multiplier * synergy_radius_bonus * temp_radius_bonus, 0.34, "storm_crown", true, 0.0)
	_emit_weapon_sfx("thunder_chain")

func _fire_void_mines() -> void:
	var level := int(weapons["void_mines"])
	var count := 5 if evolved.has("void_mines") else 1 + level / 2
	if active_synergies.has("旧神低语"):
		count += 1
	for index in range(count):
		var angle := orbit_angle + TAU * float(index) / float(max(1, count))
		var distance := randf_range(70.0, 170.0 + level * 18.0)
		var position := player.global_position + Vector2.RIGHT.rotated(angle) * distance
		_spawn_zone(position, (38.0 + level * 9.0) * (1.65 if evolved.has("void_mines") else 1.0) * damage_multiplier * synergy_damage_bonus * temp_damage_bonus, (24.0 + level * 3.0) * radius_multiplier * synergy_radius_bonus * temp_radius_bonus, 0.85 if evolved.has("void_mines") else 0.55, "event_horizon" if evolved.has("void_mines") else "void_mines", evolved.has("void_mines"), angle)
	if evolved.has("void_mines"):
		_spawn_zone(player.global_position, (28.0 + level * 7.0) * damage_multiplier * synergy_damage_bonus * temp_damage_bonus, 120.0 * radius_multiplier * synergy_radius_bonus * temp_radius_bonus, 0.42, "event_horizon", true, 0.0)
	_emit_weapon_sfx("void_mines")

func _spawn_zone(position: Vector2, damage: float, radius: float, duration: float, weapon_id: String, is_evolved: bool, rotation_angle := 0.0) -> void:
	_trim_weapon_zones(1)
	var zone: Node2D = _new_zone()
	zone.global_position = position
	zone.damage = damage
	zone.radius = radius * SIZE_SCALE
	var zwid: String = weapon_id
	if zwid in ["blood_bolt", "crimson_judgment", "frost_orb", "glacial_comet"]:
		zone.radius *= 0.5
	if zwid in ["shadow_spikes", "abyss_scream"]:
		zone.radius *= 6.0
	if zwid in ["doom_laser", "void_lance"]:
		zone.radius *= 2.0
	zone.duration = duration
	zone.weapon_id = weapon_id
	zone.evolved = is_evolved
	zone.visual_rotation = rotation_angle
	zone.traits = _traits_for_weapon(weapon_id)
	weapon_zones.add_child(zone)
	if zone.has_method("reset_for_pool"):
		zone.reset_for_pool()
	if zone.has_signal("despawn_requested") and not zone.despawn_requested.is_connected(_on_zone_despawn_requested):
		zone.despawn_requested.connect(_on_zone_despawn_requested)

func _trim_weapon_zones(incoming_count := 1) -> void:
	var overflow: int = weapon_zones.get_child_count() + incoming_count - max_weapon_zones
	if overflow <= 0:
		return
	for index in range(min(overflow, weapon_zones.get_child_count())):
		_recycle_zone(weapon_zones.get_child(index))

func _add_projectile(projectile: Node2D) -> void:
		_trim_projectiles(1)
		projectile.traits = _traits_for_weapon(projectile.weapon_id)
		projectile.radius *= SIZE_SCALE
		var pid: String = projectile.weapon_id
		if pid in ["blood_bolt", "crimson_judgment", "frost_orb", "glacial_comet"]:
			projectile.radius *= 0.5
		# B+D: Set ricochet + hit explosion per weapon type
		var wid: String = projectile.weapon_id
		match wid:
			"blood_bolt", "crimson_judgment":
				projectile.ricochet_count = 3; projectile.ricochet_range = 220.0
				projectile.explosion_radius = 60.0; projectile.explosion_damage = projectile.damage * 0.5
			"frost_orb", "glacial_comet":
				projectile.ricochet_count = 2; projectile.ricochet_range = 200.0
				projectile.explosion_radius = 50.0; projectile.explosion_damage = projectile.damage * 0.4
			"reaping_scythe", "death_carousel":
				projectile.ricochet_count = 3; projectile.ricochet_range = 240.0
				projectile.explosion_radius = 55.0; projectile.explosion_damage = projectile.damage * 0.45
			"grave_familiar", "seraph_swarm":
				projectile.ricochet_count = 1; projectile.ricochet_range = 180.0
				projectile.explosion_radius = 40.0; projectile.explosion_damage = projectile.damage * 0.35
			_:
				projectile.ricochet_count = 0; projectile.explosion_radius = 0.0
		if projectile.has_method("_update_visual"):
			projectile._update_visual()
		projectiles.add_child(projectile)
		if projectile.has_method("reset_for_pool"):
			projectile.reset_for_pool()
		if projectile.has_signal("despawn_requested") and not projectile.despawn_requested.is_connected(_on_projectile_despawn_requested):
			projectile.despawn_requested.connect(_on_projectile_despawn_requested)

func _trim_projectiles(incoming_count := 1) -> void:
	var overflow: int = projectiles.get_child_count() + incoming_count - max_projectiles
	if overflow <= 0:
		return
	for index in range(min(overflow, projectiles.get_child_count())):
		_recycle_projectile(projectiles.get_child(index))

func _new_projectile() -> Node2D:
	if projectile_factory.is_valid():
		return projectile_factory.call()
	return projectile_scene.instantiate()

func _new_zone() -> Node2D:
	if zone_factory.is_valid():
		return zone_factory.call()
	return zone_scene.instantiate()

func _recycle_projectile(projectile: Node2D) -> void:
	if projectile_recycler.is_valid():
		projectile_recycler.call(projectile, "projectile")
	else:
		projectile.queue_free()

func _on_projectile_despawn_requested(projectile: Node2D) -> void:
	_recycle_projectile(projectile)

func _recycle_zone(zone: Node2D) -> void:
	if zone_recycler.is_valid():
		zone_recycler.call(zone, "weapon_zone")
	else:
		zone.queue_free()

func _on_zone_despawn_requested(zone: Node2D) -> void:
	_recycle_zone(zone)

func _cooldown_for(weapon_id: String) -> float:
	var level := int(weapons.get(weapon_id, 1))
	match weapon_id:
		"blood_bolt":
			return (max(0.16, (0.45 if evolved.has(weapon_id) else 0.62) - level * 0.035)) * cooldown_multiplier * synergy_cooldown_bonus * temp_cooldown_bonus
		"ghost_blades":
			return (0.07 if evolved.has(weapon_id) else 0.11) * cooldown_multiplier * synergy_cooldown_bonus * temp_cooldown_bonus
		"shadow_spikes":
			return (max(0.55, (1.1 if evolved.has(weapon_id) else 1.45) - level * 0.07)) * cooldown_multiplier * synergy_cooldown_bonus * temp_cooldown_bonus
		"soul_nova":
			return (max(1.05, (2.0 if evolved.has(weapon_id) else 2.7) - level * 0.12)) * cooldown_multiplier * synergy_cooldown_bonus * temp_cooldown_bonus
		"doom_laser":
			return (max(0.55, (1.05 if evolved.has(weapon_id) else 1.55) - level * 0.08)) * cooldown_multiplier * synergy_cooldown_bonus * temp_cooldown_bonus
		"plague_bomb":
			return (max(0.75, (1.45 if evolved.has(weapon_id) else 2.1) - level * 0.12)) * cooldown_multiplier * synergy_cooldown_bonus * temp_cooldown_bonus
		"abyss_tentacle":
			return (max(0.38, (0.75 if evolved.has(weapon_id) else 1.05) - level * 0.06)) * cooldown_multiplier * synergy_cooldown_bonus * temp_cooldown_bonus
		"reaping_scythe":
			return (max(0.34, (0.72 if evolved.has(weapon_id) else 1.05) - level * 0.055)) * cooldown_multiplier * synergy_cooldown_bonus * temp_cooldown_bonus
		"grave_familiar":
			return (max(0.20, (0.40 if evolved.has(weapon_id) else 0.72) - level * 0.05)) * cooldown_multiplier * synergy_cooldown_bonus * temp_cooldown_bonus
		"frost_orb":
			return (max(0.34, (0.80 if evolved.has(weapon_id) else 1.10) - level * 0.055)) * cooldown_multiplier * synergy_cooldown_bonus * temp_cooldown_bonus
		"thunder_chain":
			return (max(0.58, (1.12 if evolved.has(weapon_id) else 1.58) - level * 0.075)) * cooldown_multiplier * synergy_cooldown_bonus * temp_cooldown_bonus
		"void_mines":
			return (max(0.62, (1.18 if evolved.has(weapon_id) else 1.70) - level * 0.085)) * cooldown_multiplier * synergy_cooldown_bonus * temp_cooldown_bonus
	return 1.0

func apply_stat_upgrade(stat_id: String, amount: float) -> void:
	match stat_id:
		"damage":
			attack_flat_bonus += amount
			damage_multiplier = 1.0 + attack_flat_bonus
		"cooldown":
			cooldown_multiplier *= max(0.45, 1.0 - amount)
		"radius":
			radius_multiplier *= 1.0 + amount
		"projectile_speed":
			projectile_speed_multiplier *= 1.0 + amount
		"crit_chance":
			crit_chance = min(0.50, crit_chance + amount)
		"crit_damage":
			crit_damage_multiplier += amount
		"lifesteal_chance":
			lifesteal_chance = min(0.60, lifesteal_chance + amount)
		"lifesteal_amount":
			lifesteal_amount += amount

func _apply_passive_effect(passive_id: String) -> void:
	var effects: Array = passive_effects.get(passive_id, [])
	for effect in effects:
		var data: Dictionary = effect
		apply_stat_upgrade(data["stat"], data["amount"])

func roll_critical() -> bool:
	return randf() < crit_chance

func _traits_for_weapon(weapon_id: String) -> Dictionary:
	var base_id := weapon_id
	for candidate in definitions.keys():
		var definition: Dictionary = definitions[candidate]
		if str(definition.get("evolved_id", "")) == weapon_id:
			base_id = candidate
			break
	if definitions.has(base_id):
		return (definitions[base_id].get("traits", {}) as Dictionary).duplicate()
	return {}

func _is_evolved_weapon_id(weapon_id: String) -> bool:
	for candidate in definitions.keys():
		var definition: Dictionary = definitions[candidate]
		if evolved.has(candidate) and str(definition.get("evolved_id", "")) == weapon_id:
			return true
	return false

func _nearest_enemy(skip_count: int = 0, max_range: float = INF) -> Node2D:
	var children := enemies.get_children()
	if children.is_empty():
		return null
	var max_dist_sq := max_range * max_range
	var nearest: Node2D = null
	var best_dist_sq: float = max_dist_sq
	for enemy in children:
		var d2 := player.global_position.distance_squared_to(enemy.global_position)
		if d2 < best_dist_sq:
			best_dist_sq = d2
			nearest = enemy
	if nearest == null or best_dist_sq >= max_dist_sq:
		return null
	if skip_count <= 0 or nearest == null:
		return nearest
	# For skip_count > 0: collect top N+1, return the Nth
	var candidates: Array = []
	for enemy in children:
		var d2 := player.global_position.distance_squared_to(enemy.global_position)
		candidates.append({"enemy": enemy, "d2": d2})
	candidates.sort_custom(func(a, b): return a.d2 < b.d2)
	return candidates[min(skip_count, candidates.size() - 1)].enemy

func _random_enemy() -> Node2D:
	var children := enemies.get_children()
	if children.is_empty():
		return null
	return children[randi() % children.size()]

func _can_evolve(weapon_id: String) -> bool:
	if int(weapons.get(weapon_id, 0)) < MAX_WEAPON_LEVEL:
		return false
	var definition: Dictionary = definitions[weapon_id]
	if not passives.has(definition["passive"]):
		return false
	if not evolved.has(weapon_id):
		return true  # Lv5 → 进化
	if not super_evolved.has(weapon_id):
		return true  # Lv7 → 超进化
	return false

func _can_fuse() -> String:
	for fusion_id in fusion_recipes.keys():
		var recipe: Dictionary = fusion_recipes[fusion_id]
		var w1: String = recipe["weapons"][0]
		var w2: String = recipe["weapons"][1]
		if weapons.has(w1) and weapons.has(w2) and super_evolved.has(w1) and super_evolved.has(w2):
			return fusion_id
	return ""

func _has_super(weapon_id: String) -> bool:
	return super_evolved.has(weapon_id)

func _is_fusion(weapon_id: String) -> bool:
	return fusion_recipes.has(weapon_id)

func _pick_options(options: Array, desired_count: int) -> Array:
	var picked: Array = []
	var pool := options.duplicate()
	var current_weapon_upgrades := []
	for option in pool:
		if str(option.get("id", "")).begins_with("upgrade:"):
			current_weapon_upgrades.append(option)
	if not current_weapon_upgrades.is_empty():
		var guaranteed: Dictionary = current_weapon_upgrades[randi() % current_weapon_upgrades.size()]
		picked.append(guaranteed)
		pool.erase(guaranteed)
	while not pool.is_empty() and picked.size() < desired_count:
		var option: Dictionary = _weighted_pick(pool)
		picked.append(option)
		pool.erase(option)
	return picked

func _bias_options_to_specialty(options: Array) -> Array:
	var favored_weapon := _specialized_weapon_id()
	if favored_weapon == "":
		return options
	for option in options:
		var option_id := str(option.get("id", ""))
		if option_id.ends_with(":%s" % favored_weapon):
			option["weight"] = int(option.get("weight", 10)) + 32
		elif option_id.begins_with("passive:"):
			var passive_id := option_id.split(":")[1]
			var passive_data: Dictionary = passive_definitions.get(passive_id, {})
			if str(passive_data.get("title", "")) == str(passive_definitions.get(definitions[favored_weapon]["passive"], {}).get("title", "")):
				option["weight"] = int(option.get("weight", 10)) + 18
	return options

func _specialized_weapon_id() -> String:
	var best_weapon := ""
	var best_score := 0
	for weapon_id in weapon_focus.keys():
		var score := int(weapon_focus.get(weapon_id, 0))
		if score > best_score:
			best_score = score
			best_weapon = str(weapon_id)
	return best_weapon if best_score >= 3 else ""

func _weighted_pick(pool: Array) -> Dictionary:
	var total_weight: int = 0
	for option in pool:
		total_weight += int(option.get("weight", 10))
	var roll: int = randi() % max(1, total_weight)
	var cursor: int = 0
	for option in pool:
		cursor += int(option.get("weight", 10))
		if roll < cursor:
			return option
	return pool[0]

func _assign_rarities(options: Array) -> Array:
	for option in options:
		var roll: int = randi() % 100
		var rarity := "普通"
		if str(option["id"]).begins_with("evolve:"):
			rarity = "传说"
		elif roll >= 92:
			rarity = "传说"
		elif roll >= 76:
			rarity = "史诗"
		elif roll >= 48:
			rarity = "稀有"
		option["rarity"] = rarity
	return options

func _bias_options_to_build(options: Array) -> Array:
	var preferred_tags := _preferred_tags()
	if preferred_tags.is_empty():
		return options
	for option in options:
		var tags: Array[String] = _option_tags(option)
		for tag in preferred_tags:
			if tags.has(tag):
				option["weight"] = int(option.get("weight", 10)) + 26
				break
	return options

func _preferred_tags() -> Array[String]:
	var counts := _build_tag_counts()
	var sorted_tags := counts.keys()
	sorted_tags.sort_custom(func(a, b): return counts[a] > counts[b])
	var preferred: Array[String] = []
	for tag in sorted_tags:
		if int(counts[tag]) >= 2:
			preferred.append(tag)
		if preferred.size() >= 2:
			break
	return preferred

func _build_tag_counts() -> Dictionary:
	var counts := {}
	for weapon_id in weapons.keys():
		for tag in definitions[weapon_id].get("tags", []):
			counts[tag] = int(counts.get(tag, 0)) + 1
	for passive_id in passives.keys():
		for tag in passive_definitions[passive_id].get("tags", []):
			counts[tag] = int(counts.get(tag, 0)) + 1
	return counts

func _option_tags(option: Dictionary) -> Array[String]:
	var option_id := str(option.get("id", ""))
	var parts := option_id.split(":")
	if parts.size() < 2:
		return Array([], TYPE_STRING, "", null)
	match parts[0]:
		"unlock", "upgrade", "evolve":
			return _string_array_from_variant(definitions.get(parts[1], {}).get("tags", []))
		"passive":
			return _string_array_from_variant(passive_definitions.get(parts[1], {}).get("tags", []))
	return Array([], TYPE_STRING, "", null)

func _refresh_synergies() -> void:
	synergy_damage_bonus = 1.0
	synergy_cooldown_bonus = 1.0
	synergy_radius_bonus = 1.0
	synergy_projectile_speed_bonus = 1.0
	active_synergies.clear()
	var counts := _build_tag_counts()
	for tag in synergy_definitions.keys():
		var count := int(counts.get(tag, 0))
		var tier := "3" if count >= 3 else ("2" if count >= 2 else "")
		if tier == "":
			continue
		var data: Dictionary = synergy_definitions[tag][tier]
		active_synergies.append(data["title"])
		synergy_damage_bonus *= float(data.get("damage", 1.0))
		synergy_cooldown_bonus *= float(data.get("cooldown", 1.0))
		synergy_radius_bonus *= float(data.get("radius", 1.0))
		synergy_projectile_speed_bonus *= float(data.get("projectile_speed", 1.0))

func _string_array_from_variant(value: Variant) -> Array[String]:
	var result: Array[String] = []
	if value is Array:
		for item in value:
			result.append(str(item))
	return result

func _clear_wingmen() -> void:
	for wingman in wingmen:
		if is_instance_valid(wingman):
			wingman.queue_free()
	wingmen.clear()

func _sync_wingmen(force_refresh := false) -> void:
	if not weapons.has("grave_familiar"):
		if not wingmen.is_empty():
			_clear_wingmen()
		return
	var level := int(weapons.get("grave_familiar", 1))
	var desired_count := 4 if evolved.has("grave_familiar") else 1 + level / 2
	if force_refresh or wingmen.size() != desired_count:
		_clear_wingmen()
		for index in range(desired_count):
			var wingman: Node2D = WingmanScene.instantiate()
			player.get_parent().add_child(wingman)
			wingman.configure_style(evolved.has("grave_familiar"))
			wingmen.append(wingman)
	for wingman in wingmen:
		if is_instance_valid(wingman):
			wingman.configure_style(evolved.has("grave_familiar"))
	var orbit_radius := (82.0 + level * 10.0) * SIZE_SCALE
	if evolved.has("grave_familiar"):
		orbit_radius += 26.0 * SIZE_SCALE
	for index in range(wingmen.size()):
		var angle := orbit_angle * 0.55 + TAU * float(index) / float(max(1, wingmen.size()))
		wingmen[index].set_orbit_pose(player.global_position, angle, orbit_radius)

func _emit_weapon_sfx(weapon_id: String) -> void:
	var family := str(definitions.get(weapon_id, {}).get("sfx", "projectile"))
	weapon_fired.emit(family)

func set_temporary_bonus(stat_id: String, multiplier: float) -> void:
	match stat_id:
		"damage":
			temp_damage_bonus = multiplier
		"cooldown":
			temp_cooldown_bonus = multiplier
		"radius":
			temp_radius_bonus = multiplier
		"projectile_speed":
			temp_projectile_speed_bonus = multiplier
