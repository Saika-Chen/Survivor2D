extends RefCounted
class_name BootstrapUIHelpers

const TextureFactory := preload("res://scripts/visuals/texture_factory.gd")

static func unique_paths(paths: Array) -> Array[String]:
	var seen := {}
	var result: Array[String] = []
	for path in paths:
		var text := str(path)
		if text == "" or seen.has(text):
			continue
		seen[text] = true
		result.append(text)
	return result

static func new_pixel_frame(parent: Node, node_name: String, texture: Texture2D) -> TextureRect:
	var frame := TextureRect.new()
	frame.name = node_name
	frame.texture = texture
	frame.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	frame.stretch_mode = TextureRect.STRETCH_SCALE
	frame.modulate = Color(1.0, 1.0, 1.0, 0.94)
	parent.add_child(frame)
	parent.move_child(frame, 1)
	return frame

static func apply_pixel_button_style(button: Button, texture: Texture2D) -> void:
	var style := StyleBoxTexture.new()
	style.texture = texture
	style.texture_margin_left = 24
	style.texture_margin_right = 24
	style.texture_margin_top = 24
	style.texture_margin_bottom = 24
	style.axis_stretch_horizontal = StyleBoxTexture.AXIS_STRETCH_MODE_TILE
	style.axis_stretch_vertical = StyleBoxTexture.AXIS_STRETCH_MODE_TILE
	style.content_margin_left = 18
	style.content_margin_right = 18
	style.content_margin_top = 10
	style.content_margin_bottom = 10
	button.add_theme_stylebox_override("normal", style)
	button.add_theme_stylebox_override("hover", style)
	button.add_theme_stylebox_override("pressed", style)
	button.add_theme_stylebox_override("focus", style)

static func set_icon_sprite(icon: AnimatedSprite2D, item_id: String, icon_size: float) -> void:
	var frames := TextureFactory.item_icon_frames(item_id)
	if frames == null:
		icon.hide()
		return
	icon.sprite_frames = frames
	icon.scale = Vector2.ONE * (icon_size / 96.0)
	var names := frames.get_animation_names()
	if not names.is_empty():
		icon.play(str(names[0]))
	icon.show()

static func weapon_title(weapon_id: String) -> String:
	match weapon_id:
		"blood_bolt":
			return "血咒弹"
		"ghost_blades":
			return "幽魂环刃"
		"shadow_spikes":
			return "暗影地刺"
		"soul_nova":
			return "灵火新星"
		"doom_laser":
			return "毁灭激光"
		"plague_bomb":
			return "瘟疫炸弹"
		"abyss_tentacle":
			return "深渊触手"
		"reaping_scythe":
			return "穿魂镰刃"
		"grave_familiar":
			return "幽冥僚机"
		"frost_orb":
			return "寒星法球"
		"thunder_chain":
			return "雷链符文"
		"void_mines":
			return "虚空地雷"
	return weapon_id
