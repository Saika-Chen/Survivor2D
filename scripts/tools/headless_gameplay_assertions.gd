extends SceneTree

const DuelystTheme := preload("res://scripts/visuals/duelyst_theme.gd")
const HeroCatalog := preload("res://scripts/game/hero_catalog.gd")
const CJKFontTheme := preload("res://scripts/ui/cjk_font_theme.gd")
const TextureFactory := preload("res://scripts/visuals/texture_factory.gd")

var elapsed := 0.0
var checked := false

func _initialize() -> void:
	change_scene_to_file("res://scenes/main/Main.tscn")

func _process(delta: float) -> bool:
	elapsed += delta
	if current_scene == null or checked:
		return false
	checked = true
	var game := current_scene
	var hud := game.get_node("HUD")
	var player := game.get_node("Player")
	var wave_director := game.get_node("WaveDirector")
	var arena := game.get_node("Arena")
	var object_pool: Node = game.object_pool
	assert(hud.fullscreen_joystick_enabled == true, "HUD should use full-screen touch joystick")
	assert(hud.mobile_joystick.visible == false, "Visual joystick should be hidden in full-screen mode")
	assert(hud.health_bar.visible == true, "Bottom red health bar should be visible")
	assert(hud.health_label.visible == true, "Bottom health text should show current/max health")
	assert(hud.xp_bar != null and hud.xp_bar.visible, "XP bar should move to the bottom")
	assert(hud.level_label != null and hud.level_label.visible, "Current level should be shown above the bottom XP bar")
	assert(hud.stats_art != null and hud.stats_art.texture != null, "HUD should use the new portrait frame art")
	assert(hud.right_art != null and hud.right_art.texture != null, "HUD should use the new mini-map frame art")
	assert(hud.currency_gold_bar != null and hud.currency_gold_bar.texture != null, "HUD should use the new gold currency bar art")
	assert(hud.currency_gem_bar != null and hud.currency_gem_bar.texture != null, "HUD should use the new gem currency bar art")
	assert(hud.pause_badge != null and hud.pause_badge.texture != null, "HUD should use the new pause badge art")
	assert(ProjectSettings.get_setting("display/window/size/viewport_width") == 720, "Game viewport width should return to 720 for mobile APK performance")
	assert(ProjectSettings.get_setting("display/window/size/viewport_height") == 1280, "Game viewport height should return to 1280 for mobile APK performance")
	assert(hud.has_signal("main_menu_requested"), "HUD should expose a main-menu return signal on death")
	assert(hud.main_menu_button != null, "HUD should have a main-menu button")
	assert(hud.has_signal("exit_run_requested"), "HUD should expose an in-run exit signal")
	assert(hud.exit_run_button != null and hud.exit_run_button.visible, "HUD should show an always-visible in-run exit button")
	assert(hud.exit_run_button.text == "退出", "In-run exit button should use concise Chinese text")
	assert(hud.exit_run_button.offset_left <= 24.0, "In-run exit button should be anchored near the lower-left edge")
	var exit_viewport_size := hud.get_viewport().get_visible_rect().size
	if exit_viewport_size.y > exit_viewport_size.x:
		assert(hud.exit_run_button.offset_bottom < exit_viewport_size.y - 180.0, "Portrait exit button should sit above the bottom controls")
	else:
		assert(hud.exit_run_button.offset_top > exit_viewport_size.y - 90.0, "Landscape exit button should sit in the lower-left corner")
	assert(hud.jackpot_hold_seconds >= 1.6, "Jackpot should pause on the 6 reward screen before auto-claiming")
	assert(is_equal_approx(player.collision_scale_multiplier, 1.5), "Player collision scale should return to the earlier 1.5x size")
	assert(is_equal_approx(player.invulnerability_duration, 1.0), "Player post-hit invulnerability should be 1 second")
	assert(player.radius > 18.0 and player.radius <= 30.0, "Player radius should return to the 720x1280 scale")
	assert(player.world_size.x >= 15000.0 and player.world_size.y >= 10000.0, "World/map should expand for the new pixel tile map")
	assert(is_equal_approx(game.world_scale_multiplier, 1.0), "World scale multiplier should return to 1.0")
	assert(game.camera.zoom.x > 0.72 and game.camera.zoom.x <= 0.86, "Camera should zoom in slightly")
	assert(game.collision_tick_interval >= 0.04, "Expensive collision/pickup checks should be dispatched on a throttled tick")
	assert(game.collision_tick_timer != null, "Game should use a timer event for collision and pickup checks")
	assert(game.bgm_stream_paths.size() == 5, "Game should randomize between five BGM tracks")
	assert(game.bgm_stream_paths.has("res://assets/audio/bgm.mp3"), "BGM playlist should include bgm.mp3")
	assert(game.bgm_stream_paths.has("res://assets/audio/bgm2.mp3"), "BGM playlist should include bgm2.mp3")
	assert(game.bgm_stream_paths.has("res://assets/audio/bgm3.mp3"), "BGM playlist should include bgm3.mp3")
	assert(game.bgm_stream_paths.has("res://assets/audio/bgm4.mp3"), "BGM playlist should include bgm4.mp3")
	assert(game.bgm_stream_paths.has("res://assets/audio/bgm5.mp3"), "BGM playlist should include bgm5.mp3")
	assert(game.bgm_streams.size() == 5, "All five BGM tracks should load")
	assert(game.enemy_spatial_cell_size > 0.0, "Enemy collision broadphase should use spatial buckets")
	assert(game.enemy_spatial_buckets is Dictionary, "Enemy spatial buckets should be available for cheap nearby queries")
	assert(game.max_wave == 50, "Game should expand to 50 waves")
	assert(wave_director.max_wave == 50, "Wave director should expand to 50 waves")
	assert(game.weapon_manager.has_method("current_attack_power"), "HUD should be able to show current attack power")
	assert(game.weapon_manager.current_attack_power() > 0.0, "Current attack power should be calculable")
	assert(is_equal_approx(game.magic_crystal_pickup_drop_chance_percent, game.slot_pickup_drop_chance_percent * 0.5), "Magic crystal drop chance should be half of slot-machine chance")
	assert(game.bomb_pickup_drop_chance_percent >= game.slot_pickup_drop_chance_percent * 6.0, "Slot-machine drops should be much rarer after the balance pass")
	assert(arena.tile_paths.size() >= 8, "Arena should use split single tile images, not one full atlas")
	assert(arena.tile_style_block_size == 8, "Arena tile style should change around every 8 tiles")
	assert(arena.tile_textures.size() >= 8, "Arena should load individual tile textures")
	assert(arena.tile_batch_nodes.size() <= arena.tile_paths.size(), "Arena should batch tiles by texture for GPU rendering")
	assert(arena.get_child_count() <= arena.tile_paths.size() + 1, "Arena should not create one CanvasItem per tile")
	for batch in arena.tile_batch_nodes:
		assert(batch.multimesh != null and batch.multimesh.mesh != null, "Arena tile batches need a mesh or the map will be invisible")
	assert(FileAccess.file_exists("res://assets/art/generated/tiles/tile_floor_0.png"), "Split pixel floor tile should exist")
	assert(FileAccess.file_exists("res://ui/slice_0001.png"), "Portrait frame art should exist")
	assert(FileAccess.file_exists("res://ui/slice_0008.png"), "Mini-map frame art should exist")
	assert(hud.stats_panel != null and hud.stats_panel.texture != null, "HUD should use the new left-side decorative frame")
	assert(hud.right_panel != null and hud.right_panel.texture != null, "HUD should use the new right-side decorative frame")
	assert(hud.menu_strip != null and hud.menu_strip.texture != null, "HUD should use the new vertical menu strip art")
	assert(hud.damage_number_layer != null, "HUD should own a damage-number layer above world rendering")
	var player_frames: SpriteFrames = player.animated_body.sprite_frames
	assert(DuelystTheme.select_animation_name(player_frames, ["idle", "breathing"]) == "idle", "Player should prefer idle animation over first imported animation")
	assert(DuelystTheme.select_animation_name(player_frames, ["run", "idle"]) == "run", "Player should use run animation when moving")
	assert(DuelystTheme.select_animation_name(player_frames, ["hit", "idle"]) == "hit", "Player should use hit animation when damaged")
	assert(player.animation_state == "idle", "Player animation state should initialize as idle")
	player.set_virtual_joystick_vector(Vector2.RIGHT)
	player._physics_process(0.016)
	assert(player.animation_state == "run", "Player animation state should switch to run while moving")
	player.set_virtual_joystick_vector(Vector2.ZERO)
	player.take_damage(1.0)
	assert(player.animation_state == "hit", "Player animation state should switch to hit when damaged")
	var damage_event_count := 0
	player.damaged.connect(func(_health: float) -> void:
		damage_event_count += 1
	)
	player.take_damage(1.0)
	assert(damage_event_count == 0, "Invulnerable player should not emit damaged events")
	assert(object_pool != null, "Game should create a shared object pool manager")
	assert(object_pool.object_pools.has("effect"), "Combat effects should be pooled")
	assert(object_pool.object_pools.has("weapon_zone"), "Weapon zones should be pooled")
	assert(object_pool.object_pools.has("ui_burst"), "Jackpot rainbow burst particles should be pooled")
	for pool_id in object_pool.object_pools.keys():
		assert((object_pool.object_pools[pool_id] as Array).size() >= 20, "Object pool %s should be prewarmed with at least 20 nodes" % pool_id)
	var pooled_projectile: Node2D = game._take_projectile_from_pool()
	game.projectiles.add_child(pooled_projectile)
	pooled_projectile.weapon_id = "blood_bolt"
	pooled_projectile.radius = 6.0
	pooled_projectile.reset_for_pool()
	var pooled_projectile_anim := pooled_projectile.get_node("AnimatedSprite") as AnimatedSprite2D
	assert(pooled_projectile_anim.visible, "Pooled projectile should use the animated effect sprite")
	pooled_projectile_anim.modulate = Color(0.2, 0.3, 0.4, 0.25)
	pooled_projectile_anim.scale *= 3.0
	pooled_projectile_anim.rotation = 1.25
	pooled_projectile_anim.frame = max(0, pooled_projectile_anim.sprite_frames.get_frame_count(pooled_projectile_anim.animation) - 1)
	pooled_projectile.reset_for_pool()
	assert(pooled_projectile_anim.modulate == Color.WHITE, "Projectile reset should clear previous visual tint/fade")
	assert(pooled_projectile_anim.rotation == 0.0, "Projectile reset should clear previous visual rotation")
	assert(pooled_projectile_anim.frame == 0, "Projectile reset should restart animated effects from the first frame")
	var pooled_projectile_scale := pooled_projectile_anim.scale
	pooled_projectile_anim.scale *= 2.0
	pooled_projectile.reset_for_pool()
	assert(pooled_projectile_anim.scale == pooled_projectile_scale, "Projectile reset should not inherit a previous tween scale")
	game._return_to_pool(pooled_projectile, "projectile")
	var pooled_zone: Node2D = game._take_weapon_zone_from_pool()
	game.weapon_zones.add_child(pooled_zone)
	pooled_zone.weapon_id = "void_mines"
	pooled_zone.radius = 32.0
	pooled_zone.duration = 0.4
	pooled_zone.visual_rotation = 0.4
	pooled_zone.reset_for_pool()
	var pooled_zone_anim := pooled_zone.get_node("AnimatedSprite") as AnimatedSprite2D
	assert(pooled_zone_anim.visible, "Pooled weapon zone should use the animated effect sprite")
	pooled_zone_anim.modulate = Color(0.4, 0.5, 0.6, 0.2)
	pooled_zone_anim.scale *= 2.0
	pooled_zone_anim.frame = max(0, pooled_zone_anim.sprite_frames.get_frame_count(pooled_zone_anim.animation) - 1)
	pooled_zone.reset_for_pool()
	assert(is_equal_approx(pooled_zone_anim.modulate.a, 1.0), "Weapon zone reset should clear previous fade alpha")
	assert(pooled_zone_anim.frame == 0, "Weapon zone reset should restart animated effects from the first frame")
	pooled_zone.weapon_id = "abyss_tentacle"
	pooled_zone.evolved = false
	pooled_zone.radius = 56.0
	pooled_zone.reset_for_pool()
	var abyss_style: Dictionary = DuelystTheme.zone_style("abyss_tentacle", false)
	assert(abyss_style.get("asset_id", "") == "fx_roots", "Basic abyss tentacle should use a visible root/grasp effect")
	assert(pooled_zone_anim.visible, "Basic abyss tentacle should show an animated zone effect")
	assert(pooled_zone_anim.sprite_frames == abyss_style.get("frames", null), "Basic abyss tentacle should load the mapped visible effect frames")
	assert(pooled_zone_anim.modulate.a > 0.95, "Basic abyss tentacle should not inherit an invisible alpha")
	game._return_to_pool(pooled_zone, "weapon_zone")
	assert(game.enemy_batch_renderer != null, "Game should create a GPU enemy batch renderer")
	assert(game.enemy_batch_renderer.get_child_count() >= 7, "GPU enemy batch renderer should create one MultiMesh batch per normal archetype")
	var first_enemy_batch := game.enemy_batch_renderer.get_child(0) as MultiMeshInstance2D
	assert(first_enemy_batch != null and first_enemy_batch.multimesh != null and first_enemy_batch.multimesh.mesh != null, "Enemy GPU batches need a real mesh to render")
	assert(game.weapon_manager.crit_chance > 0.0, "Relic/stat system should expose crit chance")
	assert(game.run_magic_crystals == 0, "Run magic crystal counter should start at zero")
	game.elapsed = 125.0
	game.current_wave = 4
	game.score = 170
	assert(game._calculate_early_exit_magic_crystals() == 7, "Early exit should settle progress into magic crystals before returning to hero select")
	var passive_health_bonus_value = game.weapon_manager.get("passive_health_bonus")
	assert(passive_health_bonus_value is float and is_equal_approx(passive_health_bonus_value, 8.0), "Every relic should grant +8 max health")
	for passive_id in game.weapon_manager.passive_definitions.keys():
		var passive_effects: Array = game.weapon_manager.passive_effects.get(passive_id, [])
		var has_health_bonus := false
		var flat_attack_bonus := 0.0
		for effect in passive_effects:
			var effect_data: Dictionary = effect
			if effect_data.get("stat", "") == "health_flat" and float(effect_data.get("amount", 0.0)) >= 8.0:
				has_health_bonus = true
			if effect_data.get("stat", "") == "damage":
				flat_attack_bonus = max(flat_attack_bonus, float(effect_data.get("amount", 0.0)))
		assert(has_health_bonus, "Relic %s should include +8 health" % passive_id)
		if passive_id in ["blood_pact", "ember_crown", "bone_wheel", "void_anchor"]:
			assert(flat_attack_bonus > 0.0 and flat_attack_bonus <= 0.08, "Relic %s should grant a small fixed attack value" % passive_id)
	for passive_id in ["blood_pact", "ember_crown", "bone_wheel", "void_anchor"]:
		var boosted_effects: Array = game.weapon_manager.passive_effects.get(passive_id, [])
		for effect in boosted_effects:
			var data: Dictionary = effect
			if data.get("stat", "") == "damage":
				assert(float(data.get("amount", 0.0)) <= 0.08, "Relic %s attack bonus should remain fixed and modest" % passive_id)
	assert(ProjectSettings.get_setting("application/run/main_scene") == "res://scenes/bootstrap/Bootstrap.tscn", "Game should start at the loading/bootstrap scene")
	assert(FileAccess.file_exists("res://assets/fonts/fusion-pixel-12px-monospaced-zh_hans.ttf"), "Bundled CJK pixel UI font should exist")
	assert(CJKFontTheme.font() != null, "Bundled CJK UI font should load at runtime")
	assert(hud.stats.has_theme_font_override("font"), "HUD labels should use the bundled CJK font")
	assert(hud.weapons_label.horizontal_alignment == HORIZONTAL_ALIGNMENT_LEFT, "Weapon summary should be readable in the right-side column")
	assert(hud.weapons_label.offset_left > hud.stats.offset_right, "Weapon summary should sit to the right of the main stats block")
	assert(hud.get("weapon_icon_row") != null, "HUD should render weapon icons above the text summary")
	assert(hud.get("relic_icon_row") != null, "HUD should render relic icons above the text summary")
	assert(hud.weapons_label.text != "", "HUD weapon list should keep readable text next to the icons")
	assert(hud.relics_label.text != "", "HUD relic list should keep readable text next to the icons")
	assert(hud.weapon_icon_row.get_child_count() >= 1, "HUD weapon icon row should include the starting weapon icon")
	var hud_weapon_icon := hud.weapon_icon_row.get_child(0) as AnimatedSprite2D
	assert(hud_weapon_icon != null and hud_weapon_icon.scale.x >= 0.58, "HUD weapon icons should be large enough to read in combat")
	assert(TextureFactory.item_icon_frames("blood_bolt") != null, "Weapon HUD icons should use Duelyst icon animations")
	hud.show_level_up([
		{"id": "upgrade:blood_bolt", "title": "强化：血咒弹", "description": "等级 1 -> 2", "category": "强化", "rarity": "普通"},
		{"id": "passive:blood_pact", "title": "遗物：鲜血契约", "description": "攻击与吸血提升。", "category": "遗物", "rarity": "稀有"},
		{"id": "stat:damage", "title": "黑血碎片", "description": "攻击 +0.06。", "category": "符文", "rarity": "普通"}
	])
	assert(hud.upgrade_buttons[0].has_node("Icon"), "3-choice upgrade buttons should show an animated icon next to text")
	assert((hud.upgrade_buttons[0].get_node("Icon") as AnimatedSprite2D).sprite_frames != null, "3-choice upgrade icon should load SpriteFrames")
	hud.hide_level_up()
	assert(HeroCatalog.list().size() == 12, "Hero select should offer exactly 12 heroes")
	var hero_ids := {}
	for hero in HeroCatalog.list():
		hero_ids[hero.get("id", "")] = true
		assert(hero.get("initial_weapon", "") != "", "Each hero should have a unique starting weapon")
		assert(hero.get("unit_id", "") != "", "Each hero should define a skin unit id")
		assert(not bool(hero.get("single_weapon", false)), "Heroes should not be locked to one weapon")
	assert(hero_ids.has("abyss_stalker"), "A shadow-spike hero should be available")
	assert(hero_ids.has("storm_caller"), "A thunder-chain hero should be available")
	assert(hero_ids.has("void_miner"), "A void-mine hero should be available")
	game.weapon_manager.weapons = {"blood_bolt": 1}
	game.weapon_manager.locked_weapon_id = "blood_bolt"
	var has_unlock_option := false
	for option in game.weapon_manager.build_upgrade_options(12):
		if str(option.get("id", "")).begins_with("unlock:"):
			has_unlock_option = true
	assert(has_unlock_option, "Heroes should be able to roll new weapons while below the 3 weapon slot cap")
	game.weapon_manager.weapons = {"blood_bolt": 1, "ghost_blades": 1, "shadow_spikes": 1}
	for option in game.weapon_manager.build_upgrade_options(12):
		assert(not str(option.get("id", "")).begins_with("unlock:"), "Weapon choices should stop once all 3 weapon slots are filled")
	assert(game.weapon_manager.definitions.has("frost_orb"), "New frost orb weapon should exist")
	assert(game.weapon_manager.definitions.has("thunder_chain"), "New thunder chain weapon should exist")
	assert(game.weapon_manager.definitions.has("void_mines"), "New void mines weapon should exist")
	assert(game.chest_pickup_drop_chance_percent >= game.slot_pickup_drop_chance_percent * 9.0, "Random slot-machine drops should be much rarer than chests")
	assert(object_pool.object_pools.has("pickup"), "Pickups, including chests, should be pooled")
	game._spawn_pickup(player.global_position + Vector2(72, 0), "chest")
	var chest_pickup: Node2D = game.pickups.get_child(game.pickups.get_child_count() - 1)
	assert(chest_pickup.pickup_type == "chest", "Chest pickup should spawn through the pickup pool")
	assert(TextureFactory.pickup("chest") != null, "Generated chest image should exist")
	assert(TextureFactory.pickup("bomb") != null, "Bomb pickup image should exist")
	assert(TextureFactory.pickup("crystal") != null, "Magic crystal pickup image should exist")
	assert(TextureFactory.enemy_projectile() != null, "Enemy ranged projectile should use a generated pixel image")
	assert(chest_pickup.has_method("play_open_animation"), "Chest pickup should provide an opening animation")
	assert(chest_pickup.magnet_arrival_seconds <= 0.5, "Pickups should reach the player in about 0.5s when magnetized")
	chest_pickup.global_position = player.global_position + Vector2(500, 0)
	chest_pickup.target = player
	chest_pickup._physics_process(0.5)
	assert(chest_pickup.global_position.distance_to(player.global_position) <= 2.0, "Magnetized pickups should fly to the player in 0.5s")
	var old_speed: float = player.speed
	game._apply_pickup("haste")
	assert(player.speed > old_speed, "Haste potion should immediately increase player speed")
	assert(game.haste_timer >= 4.9, "Haste potion should last about 5 seconds")
	assert(wave_director.major_boss_interval == 10, "A bullet boss should appear every 10 waves")
	assert(wave_director.spawn_density_multiplier >= 2.0, "Wave spawns should be at least doubled")
	assert(wave_director.max_alive_enemies >= 200, "Alive enemy cap should stay high for denser hordes")
	var bullet_boss: Node2D = game.EnemyScene.instantiate()
	game.add_child(bullet_boss)
	bullet_boss.configure("bullet_boss", 10)
	var elite_probe: Node2D = game.EnemyScene.instantiate()
	game.add_child(elite_probe)
	elite_probe.configure("elite", 10)
	assert(bullet_boss.max_health <= elite_probe.max_health * 12.0, "Every-10-wave bullet boss health should be low enough to kill")
	assert(bullet_boss.projectile_burst_count >= 18, "Bullet boss should use dense patterned bullet attacks")
	assert(bullet_boss.boss_variant != "", "Every-10-wave bosses should roll a distinct behavior variant")
	assert(game.weapon_manager.crit_chance <= 0.50, "Crit chance should never exceed 50%")
	assert(game.weapon_manager.lifesteal_chance > 0.0, "Blood builds should expose lifesteal through fixed stats")
	assert(game.weapon_manager.definitions["frost_orb"].get("traits", {}).has("slow"), "Frost orb should have slow trait")
	assert(game.weapon_manager.definitions["plague_bomb"].get("traits", {}).has("slow"), "Plague bomb should keep its crowd-control trait")
	assert(game.sfx_manager.sound_profile("projectile").get("frequency", 9999.0) <= 620.0, "Projectile attack sound should be less piercing")
	assert(game.sfx_manager.sound_profile("laser").get("volume_db", 0.0) <= -16.0, "Laser attack sound should be quieter")
	assert(game.sfx_manager.sound_profile("slot_tick").get("frequency", 9999.0) <= 520.0, "Slot rolling sound should use a soft tick")
	var wave_one_enemy: Node2D = game.EnemyScene.instantiate()
	var wave_two_enemy: Node2D = game.EnemyScene.instantiate()
	game.add_child(wave_one_enemy)
	game.add_child(wave_two_enemy)
	wave_one_enemy.configure("chaser", 1)
	wave_two_enemy.configure("chaser", 2)
	assert(wave_two_enemy.max_health / wave_one_enemy.max_health >= 1.10, "Enemy health should grow enough to resist runaway player scaling")
	bullet_boss.queue_free()
	elite_probe.queue_free()
	wave_one_enemy.queue_free()
	wave_two_enemy.queue_free()
	game._spawn_enemy("chaser", player.global_position + Vector2(140, 0))
	var batched_enemy: Node2D = game.enemies.get_child(game.enemies.get_child_count() - 1)
	game.enemy_batch_renderer._process(0.016)
	var projectile_count: int = game.projectiles.get_child_count()
	game.weapon_manager.weapons = {"frost_orb": 1}
	game.weapon_manager._fire_weapon("frost_orb")
	assert(game.projectiles.get_child_count() > projectile_count, "Frost orb should spawn projectiles")
	var zone_count: int = game.weapon_zones.get_child_count()
	game.weapon_manager.weapons = {"thunder_chain": 1}
	game.weapon_manager._fire_weapon("thunder_chain")
	assert(game.weapon_zones.get_child_count() > zone_count, "Thunder chain should spawn weapon zones")
	zone_count = game.weapon_zones.get_child_count()
	game.weapon_manager.weapons = {"void_mines": 1}
	game.weapon_manager._fire_weapon("void_mines")
	assert(game.weapon_zones.get_child_count() > zone_count, "Void mines should spawn weapon zones")
	quit()
	return true
	game.weapon_manager.weapons = {str(game.selected_hero.get("initial_weapon", "blood_bolt")): 1}
	assert(DuelystTheme.zone_style("shadow_spikes", false).get("asset_id", "") == "fx_searingchasm", "Low-level shadow spikes should use a visible ground spike/chasm effect")
	assert(float(DuelystTheme.zone_style("shadow_spikes", false).get("scale", 0.0)) >= 1.20, "Low-level shadow spikes should be doubled visually")
	assert(float(DuelystTheme.zone_style("death_carousel", true).get("scale", 0.0)) <= 0.80, "Evolved weapon visuals should not receive the 2x size boost")
	assert(DuelystTheme.projectile_style("blood_bolt").get("asset_id", "") == "fx_redlightning", "Blood bolt should use a brighter, clearer projectile effect")
	assert(float(DuelystTheme.projectile_style("blood_bolt").get("scale", 0.0)) >= 0.80, "Basic projectile effects should be doubled visually")
	assert(DuelystTheme.projectile_style("death_carousel").get("asset_id", "") == "fx_multislash_full", "Evolved scythe should use a large multi-slash effect")
	assert(float(DuelystTheme.projectile_style("death_carousel").get("scale", 0.0)) <= 0.50, "Evolved projectile effects should keep their old scale")
	assert(DuelystTheme.projectile_style("seraph_swarm").get("asset_id", "") == "fx_chainlightning", "Seraph swarm should use a clear lightning effect")
	assert(DuelystTheme.projectile_style("blood_bolt").get("frames", null) != null, "Blood bolt effect frames should load")
	assert(DuelystTheme.projectile_style("death_carousel").get("frames", null) != null, "Evolved scythe effect frames should load")
	assert(DuelystTheme.projectile_style("seraph_swarm").get("frames", null) != null, "Seraph swarm effect frames should load")
	assert(DuelystTheme.zone_style("ghost_blades", false).get("asset_id", "") == "fx_slashfrenzy", "Ghost blades should use a clearer slash-zone effect")
	assert(DuelystTheme.zone_style("wraith_storm", true).get("asset_id", "") == "fx_multislash_full", "Evolved ghost blades should use a large multi-slash zone")
	assert(DuelystTheme.zone_style("plague_bomb", false).get("asset_id", "") == "fx_explosiongreenelectrical", "Plague bomb should use a vivid green explosion")
	assert(DuelystTheme.zone_style("grave_mortar", true).get("asset_id", "") == "fx_f4_shadownova", "Evolved plague bomb should use a large shadow nova")
	assert(DuelystTheme.zone_style("old_one_grasp", true).get("asset_id", "") == "fx_f4_daemoniclure", "Evolved tentacle should use a stronger dark grasp effect")
	assert(DuelystTheme.zone_style("ghost_blades", false).get("frames", null) != null, "Ghost blades effect frames should load")
	assert(DuelystTheme.zone_style("wraith_storm", true).get("frames", null) != null, "Evolved ghost blades effect frames should load")
	assert(DuelystTheme.zone_style("plague_bomb", false).get("frames", null) != null, "Plague bomb effect frames should load")
	assert(DuelystTheme.zone_style("grave_mortar", true).get("frames", null) != null, "Evolved plague bomb effect frames should load")
	assert(DuelystTheme.zone_style("old_one_grasp", true).get("frames", null) != null, "Evolved tentacle effect frames should load")
	hud.show_level_up(game.weapon_manager.build_upgrade_options())
	var large_upgrade_pool: Array = game.weapon_manager.build_upgrade_options(48)
	var has_tiny_cooldown := false
	for upgrade_option in large_upgrade_pool:
		if str(upgrade_option.get("id", "")) == "stat:tiny_cooldown":
			has_tiny_cooldown = true
	assert(has_tiny_cooldown, "Common junk rewards should include a tiny cooldown reduction")
	var panel := hud.level_up_panel as Control
	var options := hud.level_up_overlay.get_node("Panel/Options") as GridContainer
	var viewport_size := hud.get_viewport().get_visible_rect().size
	var panel_center := panel.position + panel.size * 0.5
	assert(absf(panel_center.y - viewport_size.y * 0.5) < viewport_size.y * 0.12, "Upgrade panel should sit near screen center")
	assert(options.columns == 1, "All upgrade choices should be stacked vertically")
	assert(options.size.x <= panel.size.x * 0.82, "Upgrade option bars should be shorter than the panel width")
	assert(absf((options.position.x + options.size.x * 0.5) - panel.size.x * 0.5) <= 6.0, "Upgrade option bars should be centered in the panel")
	assert(hud.stats.get_theme_font_size("font_size") >= 24, "HUD stats font should stay readable after returning to 720x1280")
	assert(hud.stats.text.contains("攻击力"), "HUD stats should show current attack power")
	assert(hud.stats.text.find("攻击力") < hud.stats.text.find("倍率"), "Current attack power should appear above the multiplier")
	assert(hud.stats.text.contains("倍率"), "HUD stats should show the current attack multiplier")
	assert(hud.stats.text.contains("本局魔晶"), "HUD stats should show magic crystals gained this run")
	assert(hud.stats.text.contains("暴击"), "HUD stats should show crit chance and crit damage")
	assert(not hud.stats.text.contains("XP"), "XP text should be removed from the top-left stats block")
	assert(hud.option_card_texture != null, "Upgrade/event choices should use pixel card UI art")
	var before_damage_labels: int = hud.damage_number_layer.get_child_count()
	game._spawn_hit_effect(player.global_position + Vector2(80, 0), 123.0, true)
	assert(hud.damage_number_layer.get_child_count() >= before_damage_labels, "Damage numbers should render in the HUD layer")
	var damage_number: Label = hud.last_damage_number_label
	assert(damage_number != null and damage_number.visible, "Damage number label should be visible immediately")
	assert(damage_number.text == "123", "Critical damage number should show the rolled amount")
	assert(damage_number.z_index >= 1000, "Damage numbers should render above combat visuals")
	assert(hud.level_up_title.get_theme_font_size("font_size") >= 38, "Upgrade title font should scale up")
	hud.hide_level_up()
	var slot_reels: Array[String] = ["weapon", "weapon", "weapon"]
	hud.show_slot_machine(slot_reels, game.weapon_manager.build_upgrade_options(), false)
	var slot_center := (hud.level_up_panel as Control).position + (hud.level_up_panel as Control).size * 0.5
	assert(slot_center.distance_to(viewport_size * 0.5) < 4.0, "Slot machine panel should be centered")
	assert(hud.slot_machine.position.x + hud.slot_machine.size.x * 0.5 > (hud.level_up_panel as Control).size.x * 0.44, "Slot machine content should be centered in its panel")
	assert(hud.slot_machine.position.x + hud.slot_machine.size.x * 0.5 < (hud.level_up_panel as Control).size.x * 0.56, "Slot machine content should be centered in its panel")
	assert(FileAccess.file_exists("res://ui/slice_0039.png"), "Slot machine should use the new ornate frame art")
	hud.hide_level_up()
	quit()
	return true
