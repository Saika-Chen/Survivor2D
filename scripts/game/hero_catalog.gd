extends RefCounted

const UNIT_BASE := "res://assets/art/duelyst_animated_sprites/spriteframes/units/"

static func list() -> Array:
	return [
		{"id": "blood_knight", "name": "血誓骑士", "unit_id": "f2_altgeneraltier2", "initial_weapon": "blood_bolt", "role": "追踪弹幕", "special": "初始携带血咒弹。伤害 x3.0，生命 -15，冷却 +15%。", "scale": 0.96, "single_weapon": false, "mods": {"damage": 3.0, "health": -15.0, "cooldown": 1.15}},
		{"id": "wraith_dancer", "name": "亡魂舞者", "unit_id": "f4_altgeneral", "initial_weapon": "ghost_blades", "role": "近身环绕", "special": "初始携带幽魂环刃。冷却 -20%，移速 +40，生命 -20。", "scale": 1.02, "single_weapon": false, "mods": {"cooldown": 0.80, "speed": 40.0, "health": -20.0}},
		{"id": "abyss_stalker", "name": "深渊刺客", "unit_id": "f4_3rdgeneral", "initial_weapon": "shadow_spikes", "role": "地刺爆发", "special": "初始携带暗影地刺。范围 x1.8，暴击 +10%，移速 -35。", "scale": 1.00, "single_weapon": false, "mods": {"radius": 1.8, "crit_chance": 0.10, "speed": -35.0}},
		{"id": "solar_priest", "name": "日冕祭司", "unit_id": "f1_altgeneraltier2", "initial_weapon": "soul_nova", "role": "贴身爆发", "special": "初始携带灵火新星。生命 +60，无敌 +0.3秒，移速 -50。", "scale": 1.00, "single_weapon": false, "mods": {"health": 60.0, "invulnerability": 0.30, "speed": -50.0}},
		{"id": "void_gunner", "name": "虚空枪匠", "unit_id": "f3_altgeneraltier2", "initial_weapon": "doom_laser", "role": "长线贯穿", "special": "初始携带毁灭激光。弹速 x2，爆伤 +80%，生命 -30。", "scale": 1.00, "single_weapon": false, "mods": {"projectile_speed": 2.0, "crit_damage": 0.80, "health": -30.0}},
		{"id": "plague_alchemist", "name": "瘟疫炼金师", "unit_id": "f4_tier2general", "initial_weapon": "plague_bomb", "role": "重炮轰炸", "special": "初始携带瘟疫炸弹。范围 x1.8，冷却 +40%，移速 -25。", "scale": 1.00, "single_weapon": false, "mods": {"radius": 1.8, "cooldown": 1.40, "speed": -25.0}},
		{"id": "old_one_seer", "name": "旧日术士", "unit_id": "boss_malyk", "initial_weapon": "abyss_tentacle", "role": "触手控场", "special": "初始携带深渊触手。冷却 -30%，吸附 +80，伤害 x0.7。", "scale": 0.82, "single_weapon": false, "mods": {"cooldown": 0.70, "magnet": 80.0, "damage": 0.70}},
		{"id": "reaper_adept", "name": "镰魂收割者", "unit_id": "f6_altgeneraltier2", "initial_weapon": "reaping_scythe", "role": "穿透回旋", "special": "初始携带穿魂镰刃。暴击 +25%，吸血 +8，生命 -25。", "scale": 1.00, "single_weapon": false, "mods": {"crit_chance": 0.25, "lifesteal_amount": 8.0, "health": -25.0}},
		{"id": "seraph_engineer", "name": "圣核机师", "unit_id": "f1_general_skinroguelegacy", "initial_weapon": "grave_familiar", "role": "僚机风筝", "special": "初始携带幽冥僚机。移速 +60，弹速 x1.5，生命 -20。", "scale": 1.00, "single_weapon": false, "mods": {"speed": 60.0, "projectile_speed": 1.5, "health": -20.0}},
		{"id": "frost_oracle", "name": "霜星占者", "unit_id": "f6_tier2general", "initial_weapon": "frost_orb", "role": "冰星减速", "special": "初始携带寒星法球。范围 x1.5，吸附 +60，伤害 x0.75。", "scale": 1.00, "single_weapon": false, "mods": {"radius": 1.5, "magnet": 60.0, "damage": 0.75}},
		{"id": "storm_caller", "name": "雷链术士", "unit_id": "f6_circulus", "initial_weapon": "thunder_chain", "role": "连锁雷击", "special": "初始携带雷链符文。冷却 -18%，暴击 +12%，生命 -18。", "scale": 1.04, "single_weapon": false, "mods": {"cooldown": 0.82, "crit_chance": 0.12, "health": -18.0}},
		{"id": "void_miner", "name": "虚空埋雷者", "unit_id": "boss_umbra", "initial_weapon": "void_mines", "role": "陷阱控场", "special": "初始携带虚空地雷。范围 x1.7，吸附 +70，移速 -30。", "scale": 0.92, "single_weapon": false, "mods": {"radius": 1.7, "magnet": 70.0, "speed": -30.0}}
	]

static func default_hero() -> Dictionary:
	return list()[0]

static func find(hero_id: String) -> Dictionary:
	for hero in list():
		if str(hero.get("id", "")) == hero_id:
			return hero
	return default_hero()

static func asset_paths() -> Array[String]:
	var paths: Array[String] = []
	for hero in list():
		paths.append(UNIT_BASE + str(hero.get("unit_id", "")) + ".tres")
	return paths
