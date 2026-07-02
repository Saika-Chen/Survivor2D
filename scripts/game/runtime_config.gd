extends Node

const HeroCatalog := preload("res://scripts/game/hero_catalog.gd")

var selected_hero_id := "blood_knight"
var magic_crystals := 0
var talent_levels := {
	"damage": 0,
	"health": 0,
	"speed": 0,
	"radius": 0,
	"magnet": 0,
	"lifesteal_chance": 0,
	"lifesteal_amount": 0,
	"crit_chance": 0,
	"crit_damage": 0,
	"experience_gain": 0,
	"luck": 0
}

const SAVE_PATH := "user://survivor2d_save.cfg"

func _ready() -> void:
	load_progress()

func select_hero(hero_id: String) -> void:
	selected_hero_id = hero_id

func selected_hero() -> Dictionary:
	return HeroCatalog.find(selected_hero_id)

func load_progress() -> void:
	var config := ConfigFile.new()
	if config.load(SAVE_PATH) != OK:
		return
	magic_crystals = int(config.get_value("currency", "magic_crystals", 0))
	for talent_id in talent_levels.keys():
		talent_levels[talent_id] = int(config.get_value("talents", talent_id, 0))

func save_progress() -> void:
	var config := ConfigFile.new()
	config.set_value("currency", "magic_crystals", magic_crystals)
	for talent_id in talent_levels.keys():
		config.set_value("talents", talent_id, int(talent_levels[talent_id]))
	config.save(SAVE_PATH)

func add_magic_crystals(amount: int) -> void:
	magic_crystals = max(0, magic_crystals + amount)
	save_progress()

func talent_cost(talent_id: String) -> int:
	return 4 + int(talent_levels.get(talent_id, 0)) * 3

func upgrade_talent(talent_id: String) -> bool:
	if not talent_levels.has(talent_id):
		return false
	var max_level := talent_max_level(talent_id)
	if max_level > 0 and int(talent_levels[talent_id]) >= max_level:
		return false
	var cost := talent_cost(talent_id)
	if magic_crystals < cost:
		return false
	magic_crystals -= cost
	talent_levels[talent_id] = int(talent_levels[talent_id]) + 1
	save_progress()
	return true

func talent_max_level(talent_id: String) -> int:
	match talent_id:
		"experience_gain":
			return 10
		"luck":
			return 10
	return 0

func talent_bonus(talent_id: String) -> float:
	var level := float(talent_levels.get(talent_id, 0))
	match talent_id:
		"damage":
			return level * 0.035
		"health":
			return level * 18.0
		"speed":
			return level * 7.0
		"radius":
			return level * 0.025
		"magnet":
			return level * 12.0
		"lifesteal_chance":
			return level * 0.02
		"lifesteal_amount":
			return level * 2.0
		"crit_chance":
			return level * 0.02
		"crit_damage":
			return level * 0.10
		"experience_gain":
			return min(0.50, level * 0.05)
		"luck":
			return min(10.0, level)
	return 0.0
