extends RefCounted
class_name EncounterDirector

const DATA_PATH := "res://data/encounters.json"

var weights: Dictionary = {}
var encounters: Dictionary = {}

func _init() -> void:
	_load()

func _load() -> void:
	weights = {"blessing": 4, "bounty": 3, "trade": 3, "altar": 2, "shop": 2}
	encounters = {}
	if not FileAccess.file_exists(DATA_PATH):
		return
	var raw := FileAccess.get_file_as_string(DATA_PATH)
	var parsed: Variant = JSON.parse_string(raw)
	if not (parsed is Dictionary):
		return
	var data: Dictionary = parsed
	weights = data.get("weights", weights)
	encounters = data.get("encounters", {})

func build_event(wave: int, is_major: bool) -> Dictionary:
	if is_major or wave < 4:
		return {}
	var pool := _weighted_pool(wave)
	if pool.is_empty():
		return {}
	var event_kind := _pick_kind(pool)
	var template: Dictionary = encounters.get(event_kind, {})
	if template.is_empty():
		return {}
	return {
		"kind": event_kind,
		"title": str(template.get("title", "")),
		"prompt": str(template.get("prompt", "")),
		"options": template.get("options", [])
	}

func _weighted_pool(wave: int) -> Dictionary:
	var pool := weights.duplicate(true)
	if wave >= 12:
		pool["altar"] = int(pool.get("altar", 2)) + 1
	if wave >= 18:
		pool["shop"] = int(pool.get("shop", 2)) + 1
	if wave >= 20:
		pool["trade"] = int(pool.get("trade", 3)) + 1
	return pool

func _pick_kind(pool: Dictionary) -> String:
	var total := 0
	for value in pool.values():
		total += int(value)
	var roll: int = randi() % max(1, total)
	var cursor := 0
	for kind in pool.keys():
		cursor += int(pool[kind])
		if roll < cursor:
			return str(kind)
	return str(pool.keys()[0])
