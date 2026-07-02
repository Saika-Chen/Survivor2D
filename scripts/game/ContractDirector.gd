extends RefCounted
class_name ContractDirector

const DEFAULT_PATH := "res://data/contracts.json"

var contracts: Dictionary = {}
var contract_ids: Array[String] = []

func _init() -> void:
	_load_from_file(DEFAULT_PATH)
	if contract_ids.is_empty():
		_load_fallback_contracts()

func build_offer(wave: int, is_major: bool) -> Dictionary:
	if wave < 6 or is_major or contract_ids.is_empty() or wave % 6 != 0 or wave % 4 == 0:
		return {}
	var contract_id := contract_ids[int(wave / 6) % contract_ids.size()]
	var contract: Dictionary = contracts.get(contract_id, {})
	if contract.is_empty():
		return {}
	return {
		"id": contract_id,
		"title": str(contract.get("title", "")),
		"prompt": str(contract.get("prompt", "")),
		"options": [
			{"id": "contract:accept", "title": "接受契约", "description": "立刻开始追踪目标。"},
			{"id": "contract:decline", "title": "拒绝契约", "description": "放弃这次交易。"}
		],
		"contract": contract.duplicate(true)
	}

func build_contract(contract_id: String, wave: int) -> Dictionary:
	var contract: Dictionary = contracts.get(contract_id, {}).duplicate(true)
	if contract.is_empty():
		return {}
	contract["id"] = contract_id
	contract["wave"] = wave
	contract["duration_waves"] = int(contract.get("duration_waves", 2))
	return contract

func _load_from_file(path: String) -> void:
	contracts.clear()
	contract_ids.clear()
	if not FileAccess.file_exists(path):
		return
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		return
	var parsed: Variant = JSON.parse_string(file.get_as_text())
	if not (parsed is Dictionary):
		return
	var contract_data: Variant = parsed.get("contracts", {})
	if contract_data is Dictionary:
		var keys: Array = contract_data.keys()
		keys.sort()
		for key in keys:
			var contract_id := str(key)
			var contract_value: Variant = contract_data.get(key, {})
			if contract_value is Dictionary:
				contracts[contract_id] = contract_value.duplicate(true)
				contract_ids.append(contract_id)

func _load_fallback_contracts() -> void:
	contracts = {
		"elite_hunt": {
			"title": "精英狩猎",
			"prompt": "追猎更危险的目标，契约会给你更高的回报。",
			"type": "elite_hunt",
			"target": 3,
			"duration_waves": 3,
			"reward_type": "reroll",
			"reward_amount": 1
		},
		"hunt": {
			"title": "血猎契约",
			"prompt": "连续清除敌潮，换取一份更直接的杀戮回报。",
			"type": "hunt",
			"target": 48,
			"duration_waves": 2,
			"reward_type": "damage",
			"reward_amount": 0.12
		},
		"scavenge": {
			"title": "灰烬拾荒",
			"prompt": "在战场上搜集灵魂碎屑，把残余能量变成资源。",
			"type": "scavenge",
			"target": 180,
			"duration_waves": 2,
			"reward_type": "crystal",
			"reward_amount": 2
		}
	}
	contract_ids = ["elite_hunt", "hunt", "scavenge"]
