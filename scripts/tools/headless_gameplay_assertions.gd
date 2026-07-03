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
	var hud_root := game.get_node("HUD")
	var ui_manager = get_root().get_node("UIManager")
	var game_hud: GameHUD = ui_manager.game_hud
	var level_up: LevelUpPanel = ui_manager.level_up_panel
	var game_over: GameOverPopup = ui_manager.game_over_popup
	var contract_card: ContractCard = ui_manager.contract_card
	var joystick: MobileJoystick = ui_manager.mobile_joystick
	var damage_layer: DamageNumberLayer = ui_manager.damage_number_layer
	var player := game.get_node("Player")
	var wave_director := game.get_node("WaveDirector")
	var arena := game.get_node("Arena")
	var object_pool: Node = game.object_pool
	assert(hud_root != null, "Game should create the HUD root scene")
	if game_hud == null or level_up == null or game_over == null or joystick == null or damage_layer == null:
		return false
	assert(joystick.fullscreen_joystick_enabled == true, "HUD should use full-screen touch joystick")
	assert(joystick.visible == false, "Visual joystick should be hidden in full-screen mode")
	assert(game_hud.health_bar.visible == true, "Bottom red health bar should be visible")
	assert(game_hud.health_label.visible == true, "Bottom health text should show current/max health")
	assert(game_hud.xp_bar != null and game_hud.xp_bar.visible, "XP bar should move to the bottom")
	assert(game_hud.level_label != null and game_hud.level_label.visible, "Current level should be shown above the bottom XP bar")
	assert(game_hud.stats_art != null and game_hud.stats_art.texture != null, "HUD should use the new portrait frame art")
	assert(game_hud.right_art != null and game_hud.right_art.texture != null, "HUD should use the new mini-map frame art")
	assert(game_hud.currency_gold_bar != null and game_hud.currency_gold_bar.texture != null, "HUD should use the new gold currency bar art")
	assert(game_hud.currency_gem_bar != null and game_hud.currency_gem_bar.texture != null, "HUD should use the new gem currency bar art")
	assert(game_hud.pause_badge != null and game_hud.pause_badge.texture != null, "HUD should use the new pause badge art")
	assert(game_hud.stats.get_theme_font("font") == CJKFontTheme.font(), "HUD labels should use the pixel font")
	assert(level_up.title_label.get_theme_font("font") == CJKFontTheme.font(), "Level-up panel should use the pixel font")
	assert(game_over.restart_button.get_theme_font("font") == CJKFontTheme.font(), "Game over popup should use the pixel font")
	assert(contract_card == null or contract_card.title_label.get_theme_font("font") == CJKFontTheme.font(), "Contract card should use the pixel font")
	assert(ProjectSettings.get_setting("display/window/size/viewport_width") == 720, "Game viewport width should return to 720 for mobile APK performance")
	assert(ProjectSettings.get_setting("display/window/size/viewport_height") == 1280, "Game viewport height should return to 1280 for mobile APK performance")
	assert(game_over.has_signal("main_menu_requested"), "HUD should expose a main-menu return signal on death")
	assert(game_over.main_menu_button != null, "HUD should have a main-menu button")
	assert(game_hud.has_signal("exit_run_requested"), "HUD should expose an in-run exit signal")
	assert(game_hud.exit_run_button != null and game_hud.exit_run_button.visible, "HUD should show an always-visible in-run exit button")
	assert(game_hud.exit_run_button.text == "退出", "In-run exit button should use concise Chinese text")
	assert(game_hud.exit_run_button.offset_left <= 24.0, "In-run exit button should be anchored near the lower-left edge")
	var exit_viewport_size := game_hud.get_viewport().get_visible_rect().size
	if exit_viewport_size.y > exit_viewport_size.x:
		assert(game_hud.exit_run_button.offset_bottom < exit_viewport_size.y - 180.0, "Portrait exit button should sit above the bottom controls")
	else:
		assert(game_hud.exit_run_button.offset_top > exit_viewport_size.y - 90.0, "Landscape exit button should sit in the lower-left corner")
	assert(level_up.jackpot_hold_seconds >= 1.6, "Jackpot should pause on the 6 reward screen before auto-claiming")
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
	assert(ui_manager.game_hud.stats_panel != null and ui_manager.game_hud.stats_panel.texture != null, "HUD should use the new left-side decorative frame")
	assert(ui_manager.game_hud.right_panel != null and ui_manager.game_hud.right_panel.texture != null, "HUD should use the new right-side decorative frame")
	assert(ui_manager.game_hud.menu_strip != null and ui_manager.game_hud.menu_strip.texture != null, "HUD should use the new vertical menu strip art")
	assert(ui_manager.damage_number_layer != null, "HUD should own a damage-number layer above world rendering")
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
	assert(ThemeDB.fallback_font == CJKFontTheme.font(), "Global fallback font should be the pixel UI font")
	assert(game_hud.stats.has_theme_font_override("font"), "HUD labels should use the bundled CJK font")
	assert(game_hud.weapons_label.horizontal_alignment == HORIZONTAL_ALIGNMENT_LEFT, "Weapon summary should be readable in the right-side column")
	assert(game_hud.weapons_label.offset_left > game_hud.stats.offset_right, "Weapon summary should sit to the right of the main stats block")
	assert(game_hud.weapon_icon_row != null, "HUD should render weapon icons above the text summary")
	assert(game_hud.relic_icon_row != null, "HUD should render relic icons above the text summary")
	assert(game_hud.weapons_label.text != "", "HUD weapon list should keep readable text next to the icons")
	assert(game_hud.relics_label.text != "", "HUD relic list should keep readable text next to the icons")
	assert(game_hud.weapon_icon_row.get_child_count() >= 1, "HUD weapon icon row should include the starting weapon icon")
	var hud_weapon_icon := game_hud.weapon_icon_row.get_child(0) as AnimatedSprite2D
	assert(hud_weapon_icon != null and hud_weapon_icon.scale.x >= 0.58, "HUD weapon icons should be large enough to read in combat")
	assert(TextureFactory.item_icon_frames("blood_bolt") != null, "Weapon HUD icons should use Duelyst icon animations")
	level_up.show_level_up([
		{"id": "upgrade:blood_bolt", "title": "强化：血咒弹", "description": "等级 1 -> 2", "category": "强化", "rarity": "普通"},
		{"id": "passive:blood_pact", "title": "遗物：鲜血契约", "description": "攻击与吸血提升。", "category": "遗物", "rarity": "稀有"},
		{"id": "stat:damage", "title": "黑血碎片", "description": "攻击 +0.06。", "category": "符文", "rarity": "普通"}
	])
	assert(level_up.upgrade_buttons[0].has_node("Icon"), "3-choice upgrade buttons should show an animated icon next to text")
	assert((level_up.upgrade_buttons[0].get_node("Icon") as AnimatedSprite2D).sprite_frames != null, "3-choice upgrade icon should load SpriteFrames")
	level_up.hide_level_up()
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
	quit()
	return true
