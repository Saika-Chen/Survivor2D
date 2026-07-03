extends RefCounted
class_name UpgradePanel

# 升级面板工具：统一处理选项分类、文案和奖励文本。

static func is_event_mode(options: Array) -> bool:
	for option in options:
		if not str(option.get("id", "")).begins_with("event:"):
			return false
	return true

static func is_contract_mode(options: Array) -> bool:
	for option in options:
		if not str(option.get("id", "")).begins_with("contract:"):
			return false
	return options.size() > 0

static func level_up_hint_text(options: Array, allow_reroll: bool) -> String:
	return "选择 1 - 6" if options.size() > 3 else ("选择 1 / 2 / 3，或按 R 重新 Roll。" if allow_reroll else "选择 1 / 2 / 3")

static func option_text(option: Dictionary) -> String:
	var rarity := str(option.get("rarity", "普通"))
	return "      [%s] %s\n      %s" % [rarity, option["title"], option["description"]]

static func jackpot_text(option: Dictionary) -> String:
	var rarity := str(option.get("rarity", "普通"))
	var category := str(option.get("category", "属性"))
	return "%s\n[%s] %s\n%s" % [_category_icon(category), rarity, option["title"], option["description"]]

static func _category_icon(category: String) -> String:
	match category:
		"武器":
			return "⚔"
		"强化":
			return "▲"
		"遗物":
			return "◆"
		"合体":
			return "★"
		_:
			return "✦"
