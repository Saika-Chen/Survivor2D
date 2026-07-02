extends RefCounted
class_name RunEventSystem

const EnemyScene := preload("res://scenes/enemy/Enemy.tscn")
const EncounterDirectorScript := preload("res://scripts/game/EncounterDirector.gd")

var game: Node
var encounter_director
var pending_event := {}
var active_blessings := {}
var bounty_target_id := -1
var bounty_expires_wave := -1

func setup(owner: Node) -> void:
	game = owner
	encounter_director = EncounterDirectorScript.new()

func maybe_offer_wave_event(wave: int, is_major: bool) -> void:
	if is_major or wave >= 30 or wave % 4 != 0:
		return
	if game.level_up_pending or game.victory_pending:
		return
	pending_event = encounter_director.build_event(wave, is_major) if encounter_director != null else {}
	if pending_event.is_empty():
		return
	game.level_up_pending = true
	game.get_tree().paused = true
	game.hud.show_level_up(
		pending_event.get("options", []),
		str(pending_event.get("title", "命运事件")),
		str(pending_event.get("prompt", "做出你的选择。")),
		false
	)

func resolve_event_choice(event_id: String) -> void:
	match event_id:
		"event:blessing_damage":
			apply_blessing("damage", game.current_wave + 1)
		"event:blessing_cooldown":
			apply_blessing("cooldown", game.current_wave + 1)
		"event:blessing_haste":
			apply_blessing("haste", game.current_wave + 1)
		"event:bounty_accept":
			start_bounty_event()
		"event:bounty_skip":
			game.hud.hint.text = "你放弃了本轮悬赏。"
		"event:bargain_blood":
			sacrifice_health(0.25)
			game.player_damage_multiplier *= 1.30
			game.hud.hint.text = "血契生效：永久伤害大幅提升。"
		"event:bargain_level":
			sacrifice_health(0.15)
			game.hud.hint.text = "邪馈生效：立刻赐予额外升级。"
			pending_event.clear()
			game.level_up_pending = false
			game.hud.hide_level_up()
			game.get_tree().paused = false
			game._start_level_up()
			return
		"event:bargain_refuse":
			game.hud.hint.text = "你拒绝了恶魔的交易。"
		"event:altar_heal":
			game.player.heal_percent(0.45)
			game.global_magnet_timer = max(game.global_magnet_timer, 2.0)
			game.hud.hint.text = "祭坛回响：恢复大量生命，灵魂短暂靠近。"
		"event:altar_power":
			game.player_damage_multiplier *= 1.12
			game.hud.hint.text = "祭坛契约：攻击永久提升。"
		"event:altar_leave":
			game.hud.hint.text = "你离开了祭坛，没有做出交换。"
		"event:shop_damage":
			sacrifice_health(0.10)
			game.player_damage_multiplier *= 1.18
			game.hud.hint.text = "黑市药剂：短时间内更凶猛。"
		"event:shop_cooldown":
			if game.run_magic_crystals > 0:
				game.run_magic_crystals -= 1
			game.weapon_manager.set_temporary_bonus("cooldown", 0.88)
			game.hud.hint.text = "冷却卷轴：短时间内更频繁输出。"
		"event:shop_leave":
			game.hud.hint.text = "你离开了流浪商店。"
	pending_event.clear()
	game.level_up_pending = false
	game.hud.hide_level_up()
	game.get_tree().paused = false
	game._update_hud()

func apply_blessing(blessing_id: String, expires_wave: int) -> void:
	active_blessings[blessing_id] = expires_wave
	match blessing_id:
		"damage":
			game.player_damage_multiplier *= 1.25
			game.hud.hint.text = "血潮祝福：本波伤害暴涨。"
		"cooldown":
			game.weapon_manager.set_temporary_bonus("cooldown", 0.80)
			game.hud.hint.text = "疾咒祝福：本波攻击更密集。"
		"haste":
			game.player.speed += 50.0
			game.weapon_manager.set_temporary_bonus("projectile_speed", 1.20)
			game.hud.hint.text = "迅影祝福：本波移动与弹速提升。"

func expire_wave_effects() -> void:
	if bounty_target_id != -1 and game.current_wave > bounty_expires_wave:
		bounty_target_id = -1
		bounty_expires_wave = -1
		game.hud.hint.text = "悬赏过期，目标逃入黑暗。"
	if active_blessings.has("damage") and int(active_blessings["damage"]) <= game.current_wave:
		active_blessings.erase("damage")
		game.player_damage_multiplier /= 1.25
	if active_blessings.has("cooldown") and int(active_blessings["cooldown"]) <= game.current_wave:
		active_blessings.erase("cooldown")
		game.weapon_manager.set_temporary_bonus("cooldown", 1.0)
	if active_blessings.has("haste") and int(active_blessings["haste"]) <= game.current_wave:
		active_blessings.erase("haste")
		game.player.speed -= 50.0
		game.weapon_manager.set_temporary_bonus("projectile_speed", 1.0)

func start_bounty_event() -> void:
	var enemy: Node2D = game._take_from_pool("enemy", EnemyScene)
	enemy.global_position = EnemySpawner.random_spawn_position(game.player.global_position, game.player.world_size, "elite")
	game.enemies.add_child(enemy)
	EnemySpawner.configure_enemy(enemy, game.player, "elite", game.current_wave + 2, Callable(game, "_connect_enemy_pool_signals"), Callable(game, "_maybe_apply_enemy_affix"))
	enemy.scale *= 1.22
	enemy.health *= 1.35
	enemy.max_health *= 1.35
	enemy.xp_reward += 8
	bounty_target_id = enemy.get_instance_id()
	bounty_expires_wave = game.current_wave + 1
	game.hud.hint.text = "悬赏开启：击杀猩红精英，立即获得额外升级。"

func bounty_completed() -> void:
	bounty_target_id = -1
	bounty_expires_wave = -1
	game.level_up_pending = true
	game.get_tree().paused = true
	game.hud.show_level_up(
		game.weapon_manager.build_upgrade_options(4),
		"悬赏完成",
		"猩红悬赏已兑现，挑一项战利品。",
		false
	)
	game.sfx_manager.play_ui("jackpot")

func sacrifice_health(percent: float) -> void:
	game.player.health = max(1.0, game.player.health - game.player.max_health * percent)
	game.player.damaged.emit(game.player.health)
