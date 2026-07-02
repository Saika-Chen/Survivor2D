extends RefCounted
class_name WaveMutationDirector

const DEFAULT_PATH := "res://data/wave_mutations.json"

var mutations: Array[Dictionary] = []

func _init() -> void:
	_load_from_file(DEFAULT_PATH)

func build_mutation(wave: int, is_major: bool) -> Dictionary:
	if wave < 5 or is_major or mutations.is_empty() or wave % 5 != 0:
		return {}
	var index := int(wave / 5) % mutations.size()
	var entry: Dictionary = mutations[index].duplicate(true)
	entry["wave"] = wave
	entry["duration_waves"] = 1
	return entry

func _load_from_file(path: String) -> void:
	mutations.clear()
	if not FileAccess.file_exists(path):
		return
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		return
	var parsed: Variant = JSON.parse_string(file.get_as_text())
	if parsed is Dictionary:
		var mutation_data: Variant = parsed.get("mutations", [])
		if mutation_data is Array:
			for item in mutation_data:
				if item is Dictionary:
					mutations.append(item.duplicate(true))
