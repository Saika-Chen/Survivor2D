extends RefCounted
class_name WeaponConfig

const WeaponDatabaseScript := preload("res://scripts/weapons/WeaponDatabase.gd")

const MAX_WEAPON_LEVEL := 7
const MAX_WEAPONS := 3

var weapon_database: WeaponDatabase
var definitions: Dictionary = {}
var passive_definitions: Dictionary = {}
var passive_effects: Dictionary = {}
var fusion_recipes: Dictionary = {}
var synergy_definitions: Dictionary = {}
var passive_health_bonus := 8.0

func _init() -> void:
	weapon_database = WeaponDatabaseScript.new()
	load_from_database(weapon_database)

func load_from_database(database: WeaponDatabase) -> void:
	weapon_database = database
	definitions = weapon_database.get_definitions()
	passive_definitions = weapon_database.get_passive_definitions()
	passive_effects = weapon_database.get_passive_effects()
	fusion_recipes = weapon_database.get_fusion_recipes()
	synergy_definitions = weapon_database.get_synergy_definitions()
	_ensure_passive_health_bonus()

func build_upgrade_options(weapons: Dictionary, evolved: Dictionary, super_evolved: Dictionary, passives: Dictionary, weapon_focus: Dictionary, relic_luck_bonus: float, count: int = 3) -> Array:
	var options: Array = []
	for weapon_id in weapons.keys():
		if _can_evolve(weapons, evolved, super_evolved, weapon_id, passives):
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

	var fusion_id := _can_fuse(weapons, super_evolved)
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

	options = _bias_options_to_specialty(options, weapon_focus)
	options = _bias_options_to_build(options, weapons, passives)
	options = _assign_rarities(options)
	return _pick_options(options, count)

func build_slot_bundle(weapons: Dictionary, evolved: Dictionary, super_evolved: Dictionary, passives: Dictionary, weapon_focus: Dictionary, relic_luck_bonus: float, slot_jackpot_chance_percent: float) -> Dictionary:
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
		"options": build_upgrade_options(weapons, evolved, super_evolved, passives, weapon_focus, relic_luck_bonus, 6 if jackpot else 3),
		"auto_claim_all": jackpot
	}

func apply_upgrade(option_id: String, weapons: Dictionary, evolved: Dictionary, super_evolved: Dictionary, passives: Dictionary, weapon_focus: Dictionary) -> Dictionary:
	var parts := option_id.split(":")
	if parts.size() < 2:
		return {"kind": "none"}
	var kind := parts[0]
	var value := parts[1]
	match kind:
		"unlock":
			weapons[value] = 1
			weapon_focus[value] = int(weapon_focus.get(value, 0)) + 1
			return {"kind": "weapon", "weapon": value}
		"upgrade":
			weapons[value] = min(MAX_WEAPON_LEVEL, int(weapons.get(value, 1)) + 1)
			weapon_focus[value] = int(weapon_focus.get(value, 0)) + 1
			return {"kind": "weapon", "weapon": value}
		"passive":
			passives[value] = true
			return {"kind": "passive", "passive": value, "effects": passive_effects.get(value, [])}
		"evolve":
			evolved[value] = true
			weapon_focus[value] = int(weapon_focus.get(value, 0)) + 2
			return {"kind": "evolve", "weapon": value, "evolved_id": definitions[value]["evolved_id"]}
		"super_evolve":
			super_evolved[value] = true
			weapon_focus[value] = int(weapon_focus.get(value, 0)) + 3
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
			return {"kind": "fusion", "weapon": value, "fusion_id": value}
		"stat":
			return {"kind": "stat", "stat": value}
	return {"kind": "none"}

func get_summary(weapons: Dictionary, evolved: Dictionary, super_evolved: Dictionary) -> String:
	var pieces: Array[String] = []
	for weapon_id in weapons.keys():
		var title := get_weapon_title(weapon_id)
		if fusion_recipes.has(weapon_id):
			title = fusion_recipes[weapon_id]["title"]
		var suffix: String
		if super_evolved.has(weapon_id):
			suffix = "★★"
		elif evolved.has(weapon_id):
			suffix = "★"
		else:
			suffix = "Lv%d" % int(weapons[weapon_id])
		pieces.append("%s %s" % [title, suffix])
	return " | ".join(pieces)

func get_weapon_icon_ids(weapons: Dictionary) -> Array[String]:
	var ids: Array[String] = []
	for weapon_id in weapons.keys():
		ids.append(str(weapon_id))
	return ids

func current_attack_power(weapons: Dictionary, evolved: Dictionary, locked_weapon_id: String, damage_multiplier: float, synergy_damage_bonus: float, temp_damage_bonus: float) -> float:
	var base_damage := 36.0
	var primary_weapon_id: String = locked_weapon_id if locked_weapon_id != "" else "blood_bolt"
	if weapons.has(primary_weapon_id):
		var level := int(weapons[primary_weapon_id])
		base_damage = 28.0 + level * 8.0
		if evolved.has(primary_weapon_id):
			base_damage *= 1.9
	return base_damage * damage_multiplier * synergy_damage_bonus * temp_damage_bonus

func get_passive_summary(passives: Dictionary, active_synergies: Array) -> String:
	if passives.is_empty():
		return "遗物: 无"
	var pieces: Array[String] = []
	for passive_id in passives.keys():
		var passive: Dictionary = passive_definitions[passive_id]
		pieces.append(passive["title"])
	if not active_synergies.is_empty():
		pieces.append("羁绊：" + " / ".join(active_synergies))
	return "遗物: " + " / ".join(pieces)

func get_passive_icon_ids(passives: Dictionary) -> Array[String]:
	var ids: Array[String] = []
	for passive_id in passives.keys():
		ids.append(str(passive_id))
	return ids

func get_weapon_title(weapon_id: String) -> String:
	return str(definitions.get(weapon_id, {}).get("title", ""))

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

func _can_evolve(weapons: Dictionary, evolved: Dictionary, super_evolved: Dictionary, weapon_id: String, passives: Dictionary) -> bool:
	if int(weapons.get(weapon_id, 0)) < MAX_WEAPON_LEVEL:
		return false
	var definition: Dictionary = definitions[weapon_id]
	if not passives.has(definition["passive"]):
		return false
	if not evolved.has(weapon_id):
		return true
	if not super_evolved.has(weapon_id):
		return true
	return false

func _can_fuse(weapons: Dictionary, super_evolved: Dictionary) -> String:
	for fusion_id in fusion_recipes.keys():
		var recipe: Dictionary = fusion_recipes[fusion_id]
		var w1: String = recipe["weapons"][0]
		var w2: String = recipe["weapons"][1]
		if weapons.has(w1) and weapons.has(w2) and super_evolved.has(w1) and super_evolved.has(w2):
			return fusion_id
	return ""

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

func _bias_options_to_specialty(options: Array, weapon_focus: Dictionary) -> Array:
	var favored_weapon := _specialized_weapon_id(weapon_focus)
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

func _specialized_weapon_id(weapon_focus: Dictionary) -> String:
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

func _bias_options_to_build(options: Array, weapons: Dictionary, passives: Dictionary) -> Array:
	var preferred_tags := _preferred_tags(weapons, passives)
	if preferred_tags.is_empty():
		return options
	for option in options:
		var tags: Array[String] = _option_tags(option)
		for tag in preferred_tags:
			if tags.has(tag):
				option["weight"] = int(option.get("weight", 10)) + 26
				break
	return options

func _preferred_tags(weapons: Dictionary, passives: Dictionary) -> Array[String]:
	var counts := _build_tag_counts(weapons, passives)
	var sorted_tags := counts.keys()
	sorted_tags.sort_custom(func(a, b): return counts[a] > counts[b])
	var preferred: Array[String] = []
	for tag in sorted_tags:
		if int(counts[tag]) >= 2:
			preferred.append(tag)
		if preferred.size() >= 2:
			break
	return preferred

func _build_tag_counts(weapons: Dictionary, passives: Dictionary) -> Dictionary:
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

func _string_array_from_variant(value: Variant) -> Array[String]:
	var result: Array[String] = []
	if value is Array:
		for element in value:
			result.append(str(element))
	return result
