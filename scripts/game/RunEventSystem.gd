extends RefCounted
class_name RunEventSystem

const EnemyScene := preload("res://scenes/enemy/Enemy.tscn")
const EncounterDirectorScript := preload("res://scripts/game/EncounterDirector.gd")
const WaveMutationDirectorScript := preload("res://scripts/game/WaveMutationDirector.gd")
const ContractDirectorScript := preload("res://scripts/game/ContractDirector.gd")

var game: Node
var encounter_director
var wave_mutation_director
var pending_event := {}
var active_blessings := {}
var bounty_target_id := -1
var bounty_expires_wave := -1
var active_mutation := {}
var mutation_expires_wave := -1
var mutation_base_spawn_density := 0.0
var mutation_base_alive_cap := 0
var contract_director
var active_contract := {}
var pending_contract_offer := {}
var contract_progress := 0
var contract_target := 0
var contract_expires_wave := -1

func setup(owner: Node) -> void:
	game = owner
	encounter_director = EncounterDirectorScript.new()
	wave_mutation_director = WaveMutationDirectorScript.new()
	contract_director = ContractDirectorScript.new()

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

func maybe_apply_wave_mutation(wave: int, is_major: bool) -> void:
	if game.level_up_pending or game.victory_pending:
		return
	if wave_mutation_director == null:
		return
	var mutation: Dictionary = wave_mutation_director.build_mutation(wave, is_major)
	if mutation.is_empty():
		return
	_clear_wave_mutation()
	active_mutation = mutation
	mutation_expires_wave = wave + max(0, int(mutation.get("duration_waves", 1)) - 1)
	if game.wave_director != null and game.wave_director.wave_config != null:
		mutation_base_spawn_density = float(game.wave_director.wave_config.spawn_density_multiplier)
		game.wave_director.wave_config.spawn_density_multiplier = mutation_base_spawn_density * float(mutation.get("spawn_density_multiplier", 1.0))
		mutation_base_alive_cap = int(game.wave_director.max_alive_enemies)
		game.wave_director.max_alive_enemies = max(12, mutation_base_alive_cap + int(mutation.get("max_alive_bonus", 0)))
	var reward_type := str(mutation.get("reward_type", "none"))
	var reward_amount := int(mutation.get("reward_amount", 0))
	if reward_type == "crystal":
		game.run_magic_crystals += reward_amount
		game.hud.hint.text = "%s：获得 %d 个魔晶。" % [str(mutation.get("title", "波次词缀")), reward_amount]
	elif reward_type == "reroll":
		if game.level_system != null:
			game.level_system.rerolls_left += reward_amount
			game.rerolls_left = game.level_system.rerolls_left
		game.hud.hint.text = "%s：获得 %d 次重掷。" % [str(mutation.get("title", "波次词缀")), reward_amount]
	else:
		game.hud.hint.text = "%s：%s" % [str(mutation.get("title", "波次词缀")), str(mutation.get("prompt", ""))]
	game._update_hud()

func maybe_offer_contract(wave: int, is_major: bool) -> void:
	if game == null or contract_director == null:
		return
	if game.level_up_pending or game.victory_pending or not active_contract.is_empty() or not pending_contract_offer.is_empty():
		return
	var offer: Dictionary = contract_director.build_offer(wave, is_major)
	if offer.is_empty():
		return
	pending_contract_offer = offer
	game.level_up_pending = true
	game.get_tree().paused = true
	game.hud.show_level_up(
		offer.get("options", []),
		str(offer.get("title", "契约")),
		str(offer.get("prompt", "")),
		false
	)

func resolve_contract_choice(choice_id: String) -> void:
	if pending_contract_offer.is_empty():
		return
	if choice_id == "contract:accept":
		accept_contract(str(pending_contract_offer.get("id", "")), game.current_wave)
	elif choice_id == "contract:decline":
		game.hud.hint.text = "你拒绝了契约。"
	_clear_contract_offer()
	game.level_up_pending = false
	game.hud.hide_level_up()
	game.get_tree().paused = false
	game._update_hud()

func accept_contract(contract_id: String, wave: int) -> void:
	if contract_director == null:
		return
	active_contract = contract_director.build_contract(contract_id, wave)
	if active_contract.is_empty():
		return
	contract_progress = 0
	contract_target = int(active_contract.get("target", 0))
	contract_expires_wave = wave + max(1, int(active_contract.get("duration_waves", 2))) - 1
	game.hud.hint.text = "契约生效：%s" % str(active_contract.get("title", "未知契约"))
	game._update_hud()

func record_enemy_defeated(archetype: String, elite_variant: String) -> void:
	if active_contract.is_empty():
		return
	var contract_type := str(active_contract.get("type", ""))
	if contract_type == "hunt" and archetype != "boss":
		contract_progress += 1
	elif contract_type == "elite_hunt" and (elite_variant != "" or archetype == "elite"):
		contract_progress += 1
	_check_contract_completion()

func record_xp_gained(amount: int) -> void:
	if active_contract.is_empty():
		return
	if str(active_contract.get("type", "")) == "scavenge":
		contract_progress += amount
	_check_contract_completion()

func contract_status_text() -> String:
	if active_contract.is_empty():
		return ""
	return "契约 %s %d/%d" % [
		str(active_contract.get("title", "未知契约")),
		min(contract_progress, contract_target),
		max(1, contract_target)
	]

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
	if mutation_expires_wave != -1 and game.current_wave > mutation_expires_wave:
		_clear_wave_mutation()
	if not active_contract.is_empty() and game.current_wave > contract_expires_wave:
		game.hud.hint.text = "契约失效：%s" % str(active_contract.get("title", "未知契约"))
		_clear_active_contract()
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

func _clear_wave_mutation() -> void:
	if active_mutation.is_empty():
		return
	if game.wave_director != null and game.wave_director.wave_config != null:
		if mutation_base_spawn_density > 0.0:
			game.wave_director.wave_config.spawn_density_multiplier = mutation_base_spawn_density
		if mutation_base_alive_cap > 0:
			game.wave_director.max_alive_enemies = mutation_base_alive_cap
	active_mutation.clear()
	mutation_expires_wave = -1

func _check_contract_completion() -> void:
	if active_contract.is_empty() or contract_target <= 0 or contract_progress < contract_target:
		return
	var reward_type := str(active_contract.get("reward_type", ""))
	var reward_amount: float = float(active_contract.get("reward_amount", 0.0))
	match reward_type:
		"damage":
			game.player_damage_multiplier *= 1.0 + reward_amount
		"reroll":
			if game.level_system != null:
				game.level_system.rerolls_left += int(reward_amount)
				game.rerolls_left = game.level_system.rerolls_left
		"crystal":
			game.run_magic_crystals += int(reward_amount)
	game.hud.hint.text = "契约完成：%s" % str(active_contract.get("title", "未知契约"))
	_clear_active_contract()
	game._update_hud()

func _clear_active_contract() -> void:
	active_contract.clear()
	pending_contract_offer.clear()
	contract_progress = 0
	contract_target = 0
	contract_expires_wave = -1

func _clear_contract_offer() -> void:
	pending_contract_offer.clear()

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
