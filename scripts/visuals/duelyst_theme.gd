extends RefCounted

const UNIT_BASE := "res://assets/art/duelyst_animated_sprites/spriteframes/units/"
const FX_BASE := "res://assets/art/duelyst_animated_sprites/spriteframes/fx/"
const ACTOR_VISUAL_SCALE := 1.5

static var _cache := {}

static func _load_frames(path: String) -> SpriteFrames:
	if path == "":
		return null
	if not _cache.has(path):
		_cache[path] = load(path) if ResourceLoader.exists(path) else null
	return _cache[path]

static func player_style(hero_data: Dictionary = {}) -> Dictionary:
	var unit_id := str(hero_data.get("unit_id", "f2_altgeneraltier2"))
	var scale := float(hero_data.get("scale", 0.96))
	return {
		"frames": _load_frames(UNIT_BASE + unit_id + ".tres"),
		"scale": scale * ACTOR_VISUAL_SCALE,
		"speed": 10.0,
		"offset": Vector2(0, -8)
	}

static var _boss_index := {}

static func _pick_boss(key: String, pool: Array) -> String:
	if not _boss_index.has(key):
		_boss_index[key] = 0
	var idx: int = _boss_index[key]
	_boss_index[key] = (idx + 1) % pool.size()
	return pool[idx]

static func enemy_style(archetype: String) -> Dictionary:
	var unit_id := "neutral_shadowranged"
	var scale := 0.44
	match archetype:
		"shooter":
			unit_id = "neutral_moonlitsorcerer"
			scale = 0.84
		"buffer":
			unit_id = "f4_mistressofcommands"
			scale = 0.92
		"elite":
			unit_id = "f4_bloodbaronette"
			scale = 1.24 * 2.0
		"charger":
			unit_id = "neutral_mercmelee3"
			scale = 0.96
		"tank":
			unit_id = "f4_juggernaut"
			scale = 1.68
		"splitter":
			unit_id = "neutral_ghoulie"
			scale = 0.92
		"bomber":
			unit_id = "f4_plaguedr"
			scale = 0.96
		"boss":
			unit_id = _pick_boss("boss", ["boss_wraith", "boss_kron", "boss_legion", "boss_serpenti", "boss_andromeda", "boss_malyk"])
			scale = 2.24
		"bullet_boss":
			unit_id = _pick_boss("bboss", ["boss_shadowlord", "boss_decepticleprime", "boss_gol", "boss_soulstealer", "boss_kane", "boss_umbra"])
			scale = 2.45
		_:
			unit_id = "neutral_shadowranged"
			scale = 0.88
	return {
		"frames": _load_frames(UNIT_BASE + unit_id + ".tres"),
		"scale": scale * ACTOR_VISUAL_SCALE,
		"speed": 10.0,
		"offset": Vector2(0, -6 if archetype != "boss" else -18)
	}

static func projectile_style(weapon_id: String) -> Dictionary:
	var fallback := _load_frames(FX_BASE + "fx_impactred.tres")
	match weapon_id:
		"blood_bolt":
			return {"asset_id": "fx_f4_doom", "frames": _load_frames(FX_BASE + "fx_f4_doom.tres"), "fallback": fallback, "scale": 0.88, "speed": 22.0, "offset": Vector2.ZERO}
		"crimson_judgment":
			return {"asset_id": "fx_f2_saberspineseal", "frames": _load_frames(FX_BASE + "fx_f2_saberspineseal.tres"), "fallback": fallback, "scale": 0.58, "speed": 20.0, "offset": Vector2.ZERO}
		"reaping_scythe":
			return {"asset_id": "fx_f1_decimate", "frames": _load_frames(FX_BASE + "fx_f1_decimate.tres"), "fallback": fallback, "scale": 0.68, "speed": 18.0, "offset": Vector2.ZERO}
		"death_carousel":
			return {"asset_id": "fx_f2_killingedge", "frames": _load_frames(FX_BASE + "fx_f2_killingedge.tres"), "fallback": fallback, "scale": 0.46, "speed": 20.0, "offset": Vector2.ZERO}
		"grave_familiar":
			return {"asset_id": "fx_electricsphere", "frames": _load_frames(FX_BASE + "fx_electricsphere.tres"), "fallback": fallback, "scale": 0.68, "speed": 18.0, "offset": Vector2.ZERO}
		"seraph_swarm":
			return {"asset_id": "fx_chainlightning", "frames": _load_frames(FX_BASE + "fx_chainlightning.tres"), "fallback": fallback, "scale": 0.38, "speed": 20.0, "offset": Vector2.ZERO}
		"frost_orb":
			return {"asset_id": "fx_f3_aurorastears", "frames": _load_frames(FX_BASE + "fx_f3_aurorastears.tres"), "fallback": fallback, "scale": 0.80, "speed": 18.0, "offset": Vector2.ZERO}
		"glacial_comet":
			return {"asset_id": "fx_f3_fountainofyouth", "frames": _load_frames(FX_BASE + "fx_f3_fountainofyouth.tres"), "fallback": fallback, "scale": 0.48, "speed": 20.0, "offset": Vector2.ZERO}
		_:
			return {}

static func wingman_style(is_evolved: bool) -> Dictionary:
	var unit_id := "f4_remora" if not is_evolved else "f6_circulus"
	return {
		"frames": _load_frames(UNIT_BASE + unit_id + ".tres"),
		"scale": 0.48 if not is_evolved else 0.56,
		"speed": 8.0 if not is_evolved else 10.0,
		"offset": Vector2(0, -6)
	}

static func zone_style(weapon_id: String, evolved: bool) -> Dictionary:
	var fx_id := "fx_ringswirl"
	var fallback_id := "fx_impactred"
	var scale := 0.60
	var speed := 16.0
	var offset := Vector2.ZERO
	var spin := true
	match weapon_id:
		"ghost_blades", "wraith_storm":
			fx_id = "fx_f2_killingedge" if evolved else "fx_slashfrenzy"
			scale = 0.80 if not evolved else 0.54
			spin = false
			speed = 10.0
		"shadow_spikes", "abyss_scream":
			fx_id = "fx_f4_obliterate" if evolved else "fx_f6_flashfreeze"
			scale = 1.28 if not evolved else 0.72
			spin = false
			offset = Vector2(0, -8)
		"soul_nova", "soul_eclipse":
			fx_id = "fx_f2_twinstrike_part2" if evolved else "f3_fx_entropicdecay"
			scale = 1.56 if not evolved else 1.08
		"doom_laser", "void_lance":
			fx_id = "fx_f5_kinectequilibrium" if evolved else "fx_beamtesla"
			scale = 0.76 if not evolved else 0.48
			speed = 20.0
			spin = false
			offset = Vector2(0, -22)
		"plague_bomb", "grave_mortar":
			fx_id = "fx_f4_deathfire_crescendo" if evolved else "fx_f4_darkfiresacrifice"
			scale = 1.16 if not evolved else 0.78
			spin = false
		"abyss_tentacle", "old_one_grasp":
			fx_id = "fx_f4_daemoniclure" if evolved else "fx_roots"
			scale = 1.28 if not evolved else 0.86
			spin = false
			offset = Vector2(0, -10)
		"thunder_chain", "storm_crown":
			fx_id = "fx_f4_voidpulse" if evolved else "fx_f2_backstab"
			scale = 1.08 if not evolved else 0.70
			speed = 22.0
			spin = false
		"void_mines", "event_horizon":
			fx_id = "fx_f4_darkfiretransformation" if evolved else "fx_f3_aurorastears"
			scale = 1.08 if not evolved else 0.78
			speed = 18.0
			spin = true
	return {
		"asset_id": fx_id,
		"frames": _load_frames(FX_BASE + fx_id + ".tres"),
		"fallback": _load_frames(FX_BASE + fallback_id + ".tres"),
		"scale": scale,
		"speed": speed,
		"offset": offset,
		"spin": spin
	}

static func combat_fx_style(kind: String) -> Dictionary:
	match kind:
		"death":
			return {"frames": _load_frames(FX_BASE + "fx_blood_explosion.tres"), "scale": 0.48, "speed": 18.0, "offset": Vector2(0, -6)}
		_:
			return {"frames": _load_frames(FX_BASE + "fx_impactred.tres"), "scale": 0.34, "speed": 18.0, "offset": Vector2(0, -4)}

static func select_animation_name(frames: SpriteFrames, preferred: Array[String]) -> String:
	if frames == null:
		return ""
	var names := frames.get_animation_names()
	if names.is_empty():
		return ""
	for animation_name in preferred:
		if frames.has_animation(animation_name):
			return animation_name
	return names[0]

static func play_animation(sprite: AnimatedSprite2D, preferred: Array[String], restart := false) -> void:
	if sprite == null or sprite.sprite_frames == null:
		return
	var animation_name := select_animation_name(sprite.sprite_frames, preferred)
	if animation_name == "":
		return
	if not restart and sprite.animation == animation_name and sprite.is_playing():
		return
	sprite.play(animation_name)

static func play_best_animation(sprite: AnimatedSprite2D, restart := false) -> void:
	play_animation(sprite, ["idle", "breathing", "run", "attack"], restart)

static func preload_asset_paths() -> Array[String]:
	var unit_ids := [
		"neutral_moonlitsorcerer", "f4_mistressofcommands", "f4_bloodbaronette", "neutral_mercmelee3",
		"f4_juggernaut", "neutral_ghoulie", "f4_plaguedr", "boss_wraith", "neutral_shadowranged",
		"boss_shadowlord", "f4_remora", "f6_circulus"
	]
	var fx_ids := [
		"fx_impactred", "fx_redlightning", "fx_f4_voidpulse", "fx_slashfrenzy", "fx_multislash_full",
		"fx_electricsphere", "fx_chainlightning", "fx_f6_chromaticcold", "f6_fx_winterswake",
		"fx_searingchasm", "fx_f4_obliterate", "fx_impact_verticalring", "fx_whiteexplosion",
		"fx_beamfire", "fx_beamtesla", "fx_explosiongreenelectrical", "fx_f4_shadownova",
		"fx_roots", "fx_f4_daemoniclure", "fx_electrical", "fx_distortion_hex_shield", "fx_vortexswirl",
		"fx_blood_explosion"
	]
	var paths: Array[String] = []
	for unit_id in unit_ids:
		paths.append(UNIT_BASE + unit_id + ".tres")
	for fx_id in fx_ids:
		paths.append(FX_BASE + fx_id + ".tres")
	return paths

static var _spritesheet_image_cache := {}

static func batch_texture_meta(archetype: String) -> Dictionary:
	var style := enemy_style(archetype)
	var frames = style.get("frames")
	if not frames is SpriteFrames:
		return {}
	var sf := frames as SpriteFrames
	var animation_name := select_animation_name(sf, ["idle", "breathing", "run"])
	if animation_name == "":
		return {}
	var frame_count := sf.get_frame_count(animation_name)
	if frame_count <= 0:
		return {}
	var textures: Array = []
	for i in range(frame_count):
		var frame_tex := sf.get_frame_texture(animation_name, i)
		if frame_tex == null:
			continue
		var frame_img := _extract_frame_image(frame_tex)
		if frame_img == null:
			continue
		textures.append(ImageTexture.create_from_image(frame_img))
	if textures.is_empty():
		return {}
	return {
		"textures": textures,
		"frame_count": textures.size(),
		"animation_speed": sf.get_animation_speed(animation_name)
	}

static func _extract_frame_image(frame_tex: Texture2D) -> Image:
	if frame_tex is AtlasTexture:
		var at := frame_tex as AtlasTexture
		var sheet_path := at.atlas.resource_path
		if sheet_path.is_empty():
			return null
		if not _spritesheet_image_cache.has(sheet_path):
			var sheet_img: Image = null
			# 先尝试 ResourceLoader（兼容 Web）。
			var tex: Texture2D = load(sheet_path) as Texture2D
			if tex != null:
				sheet_img = tex.get_image()
			# 兜底：直接从文件读取（PC / Android）。
			if sheet_img == null:
				sheet_img = Image.load_from_file(sheet_path)
			if sheet_img == null:
				printerr("Failed to load spritesheet: ", sheet_path)
			_spritesheet_image_cache[sheet_path] = sheet_img
		var sheet_img: Image = _spritesheet_image_cache[sheet_path]
		if sheet_img == null:
			return null
		return sheet_img.get_region(at.region)
	return frame_tex.get_image()
