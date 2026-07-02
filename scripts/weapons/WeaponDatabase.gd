extends RefCounted
class_name WeaponDatabase

const DATA_PATH := "res://data/weapons.json"

var definitions: Dictionary = {}
var passive_definitions: Dictionary = {}
var passive_effects: Dictionary = {}
var fusion_recipes: Dictionary = {}
var synergy_definitions: Dictionary = {}

func _init() -> void:
	_load()

func _load() -> void:
	definitions.clear()
	passive_definitions.clear()
	passive_effects.clear()
	fusion_recipes.clear()
	synergy_definitions.clear()
	if not FileAccess.file_exists(DATA_PATH):
		push_error("WeaponDatabase: missing data file at %s" % DATA_PATH)
		return
	var raw_text := FileAccess.get_file_as_string(DATA_PATH)
	var parsed: Variant = JSON.parse_string(raw_text)
	if not (parsed is Dictionary):
		push_error("WeaponDatabase: failed to parse %s" % DATA_PATH)
		return
	var data: Dictionary = parsed
	definitions = _copy_dictionary(data.get("weapons", {}))
	passive_definitions = _copy_dictionary(data.get("passives", {}))
	passive_effects = _copy_dictionary(data.get("passive_effects", {}))
	fusion_recipes = _copy_dictionary(data.get("fusion_recipes", {}))
	synergy_definitions = _copy_dictionary(data.get("synergy_definitions", {}))

func get_definitions() -> Dictionary:
	return definitions.duplicate(true)

func get_definition(weapon_id: String) -> Dictionary:
	return _copy_dictionary(definitions.get(weapon_id, {}))

func has_definition(weapon_id: String) -> bool:
	return definitions.has(weapon_id)

func get_passive_definitions() -> Dictionary:
	return passive_definitions.duplicate(true)

func get_passive_definition(passive_id: String) -> Dictionary:
	return _copy_dictionary(passive_definitions.get(passive_id, {}))

func get_passive_effects() -> Dictionary:
	return passive_effects.duplicate(true)

func get_passive_effects_for(passive_id: String) -> Array:
	return _copy_array(passive_effects.get(passive_id, []))

func get_fusion_recipes() -> Dictionary:
	return fusion_recipes.duplicate(true)

func get_fusion_recipe(fusion_id: String) -> Dictionary:
	return _copy_dictionary(fusion_recipes.get(fusion_id, {}))

func get_synergy_definitions() -> Dictionary:
	return synergy_definitions.duplicate(true)

func get_weapon_title(weapon_id: String) -> String:
	return str(definitions.get(weapon_id, {}).get("title", ""))

func get_passive_title(passive_id: String) -> String:
	return str(passive_definitions.get(passive_id, {}).get("title", ""))

func get_fusion_title(fusion_id: String) -> String:
	return str(fusion_recipes.get(fusion_id, {}).get("title", ""))

func _copy_dictionary(value: Variant) -> Dictionary:
	if value is Dictionary:
		return (value as Dictionary).duplicate(true)
	return {}

func _copy_array(value: Variant) -> Array:
	if value is Array:
		return (value as Array).duplicate(true)
	return []
