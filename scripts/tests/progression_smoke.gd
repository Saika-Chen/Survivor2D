extends SceneTree

const LevelSystemScript := preload("res://scripts/progression/LevelSystem.gd")
const UpgradeSystemScript := preload("res://scripts/progression/UpgradeSystem.gd")

func _initialize() -> void:
	var levels := LevelSystemScript.new()
	var upgrades := UpgradeSystemScript.new()
	if levels.gain_experience(10) <= 0:
		push_error("Expected a level up from 10 XP")
		quit(1)
		return
	if upgrades.rerolls_for_level(9) < 2:
		push_error("Expected rerolls to grow with level")
		quit(1)
		return
	print("OK")
	quit(0)
