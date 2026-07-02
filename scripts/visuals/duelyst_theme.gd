extends RefCounted

const UNIT_BASE := "res://assets/art/duelyst_animated_sprites/spriteframes/units/"
const FX_BASE := "res://assets/art/duelyst_animated_sprites/spriteframes/fx/"

static var _cache := {}

static func _load_frames(path: String) -> SpriteFrames:
	if path == "":
		return null
	if not _cache.has(path):
		_cache[path] = load(path)
	return _cache[path]

static func player_style() -> Dictionary:
	return {
		"frames": _load_frames(UNIT_BASE + "f4_altgeneral.tres"),
		"scale": 1.04,
		"speed": 10.0,
		"offset": Vector2(0, -8)
	}

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
			scale = 1.24
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
			unit_id = "boss_wraith"
			scale = 2.24
		_:
			unit_id = "neutral_shadowranged"
			scale = 0.88
	return {
		"frames": _load_frames(UNIT_BASE + unit_id + ".tres"),
		"scale": scale,
		"speed": 10.0,
		"offset": Vector2(0, -6 if archetype != "boss" else -18)
	}

static func projectile_style(weapon_id: String) -> Dictionary:
	match weapon_id:
		"blood_bolt":
			return {"frames": _load_frames(FX_BASE + "fx_plasma.tres"), "scale": 0.34, "speed": 20.0, "offset": Vector2.ZERO}
		"crimson_judgment":
			return {"frames": _load_frames(FX_BASE + "fx_redplasma_vertical.tres"), "scale": 0.42, "speed": 18.0, "offset": Vector2.ZERO}
		"reaping_scythe":
			return {"frames": _load_frames(FX_BASE + "fx_crossslash.tres"), "scale": 0.34, "speed": 16.0, "offset": Vector2.ZERO}
		"death_carousel":
			return {"frames": _load_frames(FX_BASE + "fx_crossslash_x.tres"), "scale": 0.38, "speed": 18.0, "offset": Vector2.ZERO}
		"grave_familiar":
			return {"frames": _load_frames(FX_BASE + "fx_fairiefire.tres"), "scale": 0.30, "speed": 16.0, "offset": Vector2.ZERO}
		"seraph_swarm":
			return {"frames": _load_frames(FX_BASE + "fx_blueplasma_vertical.tres"), "scale": 0.34, "speed": 18.0, "offset": Vector2.ZERO}
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
	var scale := 0.60
	var speed := 16.0
	var offset := Vector2.ZERO
	var spin := true
	match weapon_id:
		"ghost_blades", "wraith_storm":
			fx_id = "fx_bladestorm"
			scale = 0.34 if not evolved else 0.42
		"shadow_spikes", "abyss_scream":
			fx_id = "fx_shadowcreep"
			scale = 0.42 if not evolved else 0.52
			spin = false
			offset = Vector2(0, -8)
		"soul_nova", "soul_eclipse":
			fx_id = "fx_ringswirl"
			scale = 0.70 if not evolved else 0.98
		"doom_laser", "void_lance":
			fx_id = "fx_beamlaser"
			scale = 0.32 if not evolved else 0.40
			speed = 18.0
			spin = false
			offset = Vector2(0, -22)
		"plague_bomb", "grave_mortar":
			fx_id = "fx_explosionpurplesmoke"
			scale = 0.46 if not evolved else 0.62
			spin = false
		"abyss_tentacle", "old_one_grasp":
			fx_id = "fx_roots"
			scale = 0.44 if not evolved else 0.56
			spin = false
			offset = Vector2(0, -10)
	return {
		"frames": _load_frames(FX_BASE + fx_id + ".tres"),
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

static func play_best_animation(sprite: AnimatedSprite2D) -> void:
	if sprite == null or sprite.sprite_frames == null:
		return
	var names := sprite.sprite_frames.get_animation_names()
	if names.is_empty():
		return
	sprite.play(names[0])
