extends SceneTree

const RunEventSystemScript := preload("res://scripts/game/RunEventSystem.gd")

class FakeHud:
	extends RefCounted
	var hint := FakeText.new()

	func show_level_up(_options: Array, _title := "", _prompt := "", _allow_reroll := false) -> void:
		pass

	func hide_level_up() -> void:
		pass

class FakeText:
	extends RefCounted
	var text := ""

class FakeLevelSystem:
	extends RefCounted
	var rerolls_left := 1

class FakeWeaponManager:
	extends RefCounted
	func set_temporary_bonus(_stat_id: String, _multiplier: float) -> void:
		pass

class FakeGame:
	extends Node
	var hud: FakeHud = FakeHud.new()
	var level_up_pending := false
	var victory_pending := false
	var current_wave := 8
	var run_magic_crystals := 0
	var player_damage_multiplier := 1.0
	var rerolls_left := 1
	var level_system: FakeLevelSystem = FakeLevelSystem.new()
	var weapon_manager: FakeWeaponManager = FakeWeaponManager.new()

	func _update_hud() -> void:
		pass

func _initialize() -> void:
	var system := RunEventSystemScript.new()
	var game := FakeGame.new()
	system.setup(game)
	system.accept_contract("hunt", 8)
	system.record_enemy_defeated("chaser", "")
	system.record_xp_gained(12)
	print("%d|%d|%d" % [system.contract_progress, game.run_magic_crystals, game.level_system.rerolls_left])
	game.free()
	quit(0)
