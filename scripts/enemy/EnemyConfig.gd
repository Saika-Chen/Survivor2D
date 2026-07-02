extends RefCounted
class_name EnemyConfig

const ENEMY_DATA_PATH := "res://data/enemies.json"

static var _cached_data: Dictionary = {}

static func _load_data() -> Dictionary:
	if not _cached_data.is_empty():
		return _cached_data
	var defaults := {
		"speed": 115.0,
		"max_health": 24.0,
		"radius": 16.0,
		"contact_damage": 18.0,
		"xp_reward": 6,
		"fire_timer": 1.6,
		"special_timer": 5.0,
		"projectile_burst_count": 0,
		"boss_variant": "",
		"elite_scale_multiplier": 1.0
	}
	if FileAccess.file_exists(ENEMY_DATA_PATH):
		var raw := FileAccess.get_file_as_string(ENEMY_DATA_PATH)
		var parsed: Variant = JSON.parse_string(raw)
		if parsed is Dictionary:
			_cached_data = parsed
			return _cached_data
	_cached_data = {
		"defaults": defaults,
		"archetypes": {
			"chaser": defaults.duplicate(true)
		}
	}
	return _cached_data

static func for_archetype(archetype: String, wave: int) -> Dictionary:
	var data := _load_data()
	var defaults: Dictionary = data.get("defaults", {})
	var archetypes: Dictionary = data.get("archetypes", {})
	var base: Dictionary = defaults.duplicate(true)
	if archetypes.has("chaser"):
		base.merge(archetypes["chaser"], true)
	if archetypes.has(archetype):
		base.merge(archetypes[archetype], true)
	elif not archetype.is_empty() and not archetypes.has("chaser") and archetypes.has("default"):
		base.merge(archetypes["default"], true)

	var speed := float(base.get("speed", 115.0))
	var max_health := float(base.get("max_health", 24.0))
	var radius := float(base.get("radius", 16.0))
	var contact_damage := float(base.get("contact_damage", 18.0))
	var xp_reward := int(base.get("xp_reward", 6))
	var fire_timer := float(base.get("fire_timer", 1.6))
	var special_timer := float(base.get("special_timer", 5.0))
	var projectile_burst_count := int(base.get("projectile_burst_count", 0))
	var boss_variant := str(base.get("boss_variant", ""))
	var elite_scale_multiplier := float(base.get("elite_scale_multiplier", 1.0))

	var wave_power := 1.0 + float(max(0, wave - 1)) * 0.24 + float(max(0, wave - 1) * max(0, wave - 1)) * 0.006
	var w := float(max(0, wave - 1))
	var health_power := 1.0 + w * 0.25 + w * w * 0.01

	match archetype:
		"shooter":
			speed = float(base.get("speed", speed))
			max_health = float(base.get("max_health", max_health)) * health_power
			radius = float(base.get("radius", radius))
			contact_damage = float(base.get("contact_damage", contact_damage)) * wave_power
			fire_timer = float(base.get("fire_timer", fire_timer))
			xp_reward = int(base.get("xp_reward", xp_reward))
		"buffer":
			speed = float(base.get("speed", speed))
			max_health = float(base.get("max_health", max_health)) * health_power
			radius = float(base.get("radius", radius))
			contact_damage = float(base.get("contact_damage", contact_damage)) * wave_power
			xp_reward = int(base.get("xp_reward", xp_reward))
		"elite":
			speed = float(base.get("speed", speed))
			max_health = float(base.get("max_health", max_health)) * health_power
			radius = float(base.get("radius", radius))
			contact_damage = float(base.get("contact_damage", contact_damage)) * wave_power
			xp_reward = int(base.get("xp_reward", xp_reward))
			elite_scale_multiplier = float(base.get("elite_scale_multiplier", elite_scale_multiplier))
		"charger":
			speed = float(base.get("speed", speed)) + wave * 2.2
			max_health = float(base.get("max_health", max_health)) * health_power
			radius = float(base.get("radius", radius))
			contact_damage = float(base.get("contact_damage", contact_damage)) * wave_power
			xp_reward = int(base.get("xp_reward", xp_reward))
		"tank":
			speed = float(base.get("speed", speed))
			max_health = float(base.get("max_health", max_health)) * health_power
			radius = float(base.get("radius", radius))
			contact_damage = float(base.get("contact_damage", contact_damage)) * wave_power
			xp_reward = int(base.get("xp_reward", xp_reward))
		"splitter":
			speed = float(base.get("speed", speed))
			max_health = float(base.get("max_health", max_health)) * health_power
			radius = float(base.get("radius", radius))
			contact_damage = float(base.get("contact_damage", contact_damage)) * wave_power
			xp_reward = int(base.get("xp_reward", xp_reward))
		"bomber":
			speed = float(base.get("speed", speed))
			max_health = float(base.get("max_health", max_health)) * health_power
			radius = float(base.get("radius", radius))
			contact_damage = float(base.get("contact_damage", contact_damage)) * wave_power
			xp_reward = int(base.get("xp_reward", xp_reward))
		"boss":
			speed = float(base.get("speed", speed))
			max_health = float(base.get("max_health", max_health)) * health_power
			radius = float(base.get("radius", radius))
			contact_damage = float(base.get("contact_damage", contact_damage)) + max(0, wave - 1) * 2.5
			fire_timer = max(0.58, float(base.get("fire_timer", fire_timer)) - wave * 0.012)
			special_timer = max(1.8, float(base.get("special_timer", special_timer)) - wave * 0.04)
			xp_reward = int(base.get("xp_reward", xp_reward))
		"bullet_boss":
			speed = float(base.get("speed", speed))
			max_health = float(base.get("max_health", max_health)) * health_power
			radius = float(base.get("radius", radius))
			contact_damage = float(base.get("contact_damage", contact_damage)) * wave_power
			fire_timer = float(base.get("fire_timer", fire_timer))
			special_timer = float(base.get("special_timer", special_timer))
			projectile_burst_count = int(base.get("projectile_burst_count", projectile_burst_count))
			boss_variant = str(base.get("boss_variant", _boss_variant_for_wave(wave)))
			if boss_variant.is_empty():
				boss_variant = _boss_variant_for_wave(wave)
			xp_reward = int(base.get("xp_reward", xp_reward))
		_:
			speed = float(base.get("speed", 115.0)) + wave * 2.0
			max_health = float(base.get("max_health", 100.0)) * health_power
			radius = float(base.get("radius", 16.0))
			contact_damage = float(base.get("contact_damage", 18.0)) * wave_power

	return {
		"speed": speed,
		"max_health": max_health,
		"radius": radius,
		"contact_damage": contact_damage,
		"xp_reward": xp_reward,
		"fire_timer": fire_timer,
		"special_timer": special_timer,
		"projectile_burst_count": projectile_burst_count,
		"boss_variant": boss_variant,
		"elite_scale_multiplier": elite_scale_multiplier
	}

static func _boss_variant_for_wave(wave: int) -> String:
	if wave >= 40:
		return "storm"
	if wave >= 30:
		return "shadow"
	return "default"
