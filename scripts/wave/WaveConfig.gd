extends Resource
class_name WaveConfig

const DEFAULT_PATH := "res://data/waves.json"

var max_wave: int = 50
var wave_duration: float = 32.0
var max_alive_enemies: int = 200
var major_boss_interval: int = 10
var spawn_density_multiplier: float = 2.25

var wave_target_base: int = 40
var wave_target_growth: int = 24
var initial_spawn_timer: float = 0.2

var spawn_timer_base: float = 0.72
var spawn_timer_decay_per_wave: float = 0.018
var mobile_spawn_timer_slowdown: float = 0.10
var desktop_spawn_timer_slowdown: float = 0.02
var mobile_spawn_timer_min: float = 0.12
var desktop_spawn_timer_min: float = 0.07

var horde_wave_interval: int = 3
var horde_multiplier: float = 1.8
var mobile_horde_base_count: int = 3
var desktop_horde_base_count: int = 10
var horde_bonus_wave_divisor: int = 10
var horde_charger_base: int = 3
var horde_charger_wave_divisor: int = 6
var horde_splitter_base: int = 2
var horde_splitter_wave_divisor: int = 8

var alive_cap_max: int = 800
var mobile_alive_growth_per_wave: int = 5
var desktop_alive_growth_per_wave: int = 6

var elite_bonus_waves: Array = [10, 20]
var spawn_rules: Array[Dictionary] = [
	{"archetype": "shooter", "min_wave": 2, "chance_base": 28, "chance_wave_divisor": 2, "count_base": 1, "count_wave_divisor": 14, "count_scale": 2},
	{"archetype": "charger", "min_wave": 3, "chance_base": 22, "chance_wave_divisor": 2, "count_base": 1, "count_wave_divisor": 16, "count_scale": 2},
	{"archetype": "buffer", "min_wave": 5, "chance_base": 18, "chance_wave_divisor": 3, "count_base": 1, "count_wave_divisor": 18, "count_scale": 2},
	{"archetype": "bomber", "min_wave": 6, "chance_base": 16, "chance_wave_divisor": 3, "count_base": 1, "count_wave_divisor": 20, "count_scale": 2},
	{"archetype": "splitter", "min_wave": 8, "chance_base": 14, "chance_wave_divisor": 3, "count_base": 1, "count_wave_divisor": 18, "count_scale": 2},
	{"archetype": "tank", "min_wave": 11, "chance_base": 12, "chance_wave_divisor": 4, "count_base": 1, "count_wave_divisor": 24, "count_scale": 2},
	{"archetype": "elite", "min_wave": 16, "chance_base": 10, "chance_wave_divisor": 5, "count_base": 1, "count_wave_divisor": 26, "count_scale": 2}
]

static func load_default() -> WaveConfig:
	return load_from_file(DEFAULT_PATH)

static func load_from_file(path: String) -> WaveConfig:
	var config := WaveConfig.new()
	if not FileAccess.file_exists(path):
		return config
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		return config
	var parsed: Variant = JSON.parse_string(file.get_as_text())
	if parsed is Dictionary:
		config._apply_dict(parsed)
	return config

func total_for_wave(wave: int) -> int:
	return wave_target_base + wave * wave_target_growth

func spawn_timer_for_wave(wave: int) -> float:
	var mobile := OS.has_feature("mobile")
	var slowdown := mobile_spawn_timer_slowdown if mobile else desktop_spawn_timer_slowdown
	var min_spawn_timer := mobile_spawn_timer_min if mobile else desktop_spawn_timer_min
	return max(min_spawn_timer, (spawn_timer_base - float(wave) * spawn_timer_decay_per_wave) / spawn_density_multiplier + slowdown)

func current_alive_cap(wave: int, base_alive_enemies: int) -> int:
	var mobile := OS.has_feature("mobile")
	var growth_per_wave := mobile_alive_growth_per_wave if mobile else desktop_alive_growth_per_wave
	var growth := int(round(float(wave * growth_per_wave) * spawn_density_multiplier))
	return min(alive_cap_max, base_alive_enemies + growth)

func has_wave_bonus_elite(wave: int) -> bool:
	return elite_bonus_waves.has(wave)

func spawn_requests_for_wave(wave: int, max_to_spawn: int) -> Array[Dictionary]:
	var requests: Array[Dictionary] = []
	if max_to_spawn <= 0:
		return requests

	var mobile := OS.has_feature("mobile")
	var base_pack := mobile_horde_base_count if mobile else desktop_horde_base_count
	var horde_boost := horde_multiplier if horde_wave_interval > 0 and wave % horde_wave_interval == 0 else 1.0
	var base_count := int(round((base_pack + wave) * spawn_density_multiplier * horde_boost))
	var bonus_count := int(round(float(wave) / float(horde_bonus_wave_divisor) * spawn_density_multiplier))
	var count: int = min(base_count + bonus_count, max_to_spawn)
	if count > 0:
		requests.append({"archetype": "chaser", "count": count})
		max_to_spawn -= count

	if max_to_spawn <= 0:
		return requests

	if horde_wave_interval > 0 and wave % horde_wave_interval == 0:
		var charger_count: int = int(min(max_to_spawn, (horde_charger_base + float(wave) / float(horde_charger_wave_divisor)) * 2.0))
		if charger_count > 0:
			requests.append({"archetype": "charger", "count": charger_count})
			max_to_spawn -= charger_count
		var splitter_count: int = int(min(max_to_spawn, (horde_splitter_base + float(wave) / float(horde_splitter_wave_divisor)) * 2.0))
		if splitter_count > 0:
			requests.append({"archetype": "splitter", "count": splitter_count})
		return requests

	for rule in spawn_rules:
		if max_to_spawn <= 0:
			break
		if wave < int(rule.get("min_wave", 0)):
			continue
		var chance := int(rule.get("chance_base", 0)) + float(wave) / float(rule.get("chance_wave_divisor", 1))
		if randi() % 100 < chance:
			var rule_count := int(min(max_to_spawn, (float(rule.get("count_base", 1)) + float(wave) / float(rule.get("count_wave_divisor", 1))) * float(rule.get("count_scale", 2))))
			if rule_count > 0:
				requests.append({"archetype": str(rule.get("archetype", "")), "count": rule_count})
				max_to_spawn -= rule_count
	return requests

func _apply_dict(data: Dictionary) -> void:
	max_wave = int(data.get("max_wave", max_wave))
	wave_duration = float(data.get("wave_duration", wave_duration))
	max_alive_enemies = int(data.get("max_alive_enemies", max_alive_enemies))
	major_boss_interval = int(data.get("major_boss_interval", major_boss_interval))
	spawn_density_multiplier = float(data.get("spawn_density_multiplier", spawn_density_multiplier))
	wave_target_base = int(data.get("wave_target_base", wave_target_base))
	wave_target_growth = int(data.get("wave_target_growth", wave_target_growth))
	initial_spawn_timer = float(data.get("initial_spawn_timer", initial_spawn_timer))
	spawn_timer_base = float(data.get("spawn_timer_base", spawn_timer_base))
	spawn_timer_decay_per_wave = float(data.get("spawn_timer_decay_per_wave", spawn_timer_decay_per_wave))
	mobile_spawn_timer_slowdown = float(data.get("mobile_spawn_timer_slowdown", mobile_spawn_timer_slowdown))
	desktop_spawn_timer_slowdown = float(data.get("desktop_spawn_timer_slowdown", desktop_spawn_timer_slowdown))
	mobile_spawn_timer_min = float(data.get("mobile_spawn_timer_min", mobile_spawn_timer_min))
	desktop_spawn_timer_min = float(data.get("desktop_spawn_timer_min", desktop_spawn_timer_min))
	horde_wave_interval = int(data.get("horde_wave_interval", horde_wave_interval))
	horde_multiplier = float(data.get("horde_multiplier", horde_multiplier))
	mobile_horde_base_count = int(data.get("mobile_horde_base_count", mobile_horde_base_count))
	desktop_horde_base_count = int(data.get("desktop_horde_base_count", desktop_horde_base_count))
	horde_bonus_wave_divisor = int(data.get("horde_bonus_wave_divisor", horde_bonus_wave_divisor))
	horde_charger_base = int(data.get("horde_charger_base", horde_charger_base))
	horde_charger_wave_divisor = int(data.get("horde_charger_wave_divisor", horde_charger_wave_divisor))
	horde_splitter_base = int(data.get("horde_splitter_base", horde_splitter_base))
	horde_splitter_wave_divisor = int(data.get("horde_splitter_wave_divisor", horde_splitter_wave_divisor))
	alive_cap_max = int(data.get("alive_cap_max", alive_cap_max))
	mobile_alive_growth_per_wave = int(data.get("mobile_alive_growth_per_wave", mobile_alive_growth_per_wave))
	desktop_alive_growth_per_wave = int(data.get("desktop_alive_growth_per_wave", desktop_alive_growth_per_wave))

	if data.has("elite_bonus_waves"):
		var elite_data: Variant = data.get("elite_bonus_waves", elite_bonus_waves)
		if elite_data is Array:
			elite_bonus_waves = []
			for wave in elite_data:
				elite_bonus_waves.append(int(wave))

	if data.has("spawn_rules"):
		var rule_data: Variant = data.get("spawn_rules", spawn_rules)
		if rule_data is Array:
			spawn_rules = []
			for rule in rule_data:
				if rule is Dictionary:
					spawn_rules.append(rule.duplicate(true))
