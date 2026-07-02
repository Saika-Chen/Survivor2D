extends RefCounted
class_name RunEventSystem

const EnemyScene := preload("res://scenes/enemy/Enemy.tscn")

var game: Node
var pending_event := {}
var active_blessings := {}
var bounty_target_id := -1
var bounty_expires_wave := -1

func setup(owner: Node) -> void:
	game = owner

func maybe_offer_wave_event(wave: int, is_major: bool) -> void:
	if is_major or wave >= 30 or wave % 4 != 0:
		return
	if game.level_up_pending or game.victory_pending:
		return
	pending_event = build_wave_event()
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

func build_wave_event() -> Dictionary:
	var event_roll := randi() % 3
	if event_roll == 0:
		return {
			"title": "临时祝福",
			"prompt": "选择一份仅持续 1 波的祝福。",
			"options": [
				{"id": "event:blessing_damage", "title": "血潮祝福", "description": "本波伤害 +25%。", "category": "事件", "rarity": "稀有"},
				{"id": "event:blessing_cooldown", "title": "疾咒祝福", "description": "本波冷却缩短 20%。", "category": "事件", "rarity": "稀有"},
				{"id": "event:blessing_haste", "title": "迅影祝福", "description": "本波移速 +50，弹速 +20%。", "category": "事件", "rarity": "稀有"}
			]
		}
	if event_roll == 1:
		return {
			"title": "精英悬赏",
			"prompt": "接受悬赏，击杀目标精英即可获得额外升级。",
			"options": [
				{"id": "event:bounty_accept", "title": "接受悬赏", "description": "刷出一只悬赏精英，击杀后获得 1 次额外升级。", "category": "事件", "rarity": "史诗"},
				{"id": "event:bounty_skip", "title": "放弃悬赏", "description": "跳过本次高风险机会。", "category": "事件", "rarity": "普通"}
			]
		}
	return {
		"title": "恶魔交易",
		"prompt": "付出代价，换取立刻爆发的力量。",
		"options": [
			{"id": "event:bargain_blood", "title": "血契", "description": "失去 25% 最大生命，永久伤害 +30%。", "category": "事件", "rarity": "史诗"},
			{"id": "event:bargain_level", "title": "邪馈", "description": "失去 15% 最大生命，立刻获得一次额外升级。", "category": "事件", "rarity": "传说"},
			{"id": "event:bargain_refuse", "title": "拒绝", "description": "保持现状，不接受恶魔提议。", "category": "事件", "rarity": "普通"}
		]
	}

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
