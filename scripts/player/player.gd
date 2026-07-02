extends CharacterBody2D

const TextureFactory := preload("res://scripts/visuals/texture_factory.gd")
const DuelystTheme := preload("res://scripts/visuals/duelyst_theme.gd")

signal damaged(health: float)
signal died

@export var speed := 338.0
@export var max_health := 100.0
@export var radius := 18.0
@export var world_size := Vector2(5200, 3600)
@export var invulnerability_duration := 2.0

var health: float = max_health
var facing_direction := Vector2.DOWN
var virtual_joystick_vector := Vector2.ZERO
var invulnerability_timer := 0.0
var passive_traits := {}
@onready var invulnerability_sprite: Sprite2D = $Invulnerability
@onready var glow_sprite: Sprite2D = $Glow
@onready var animated_body: AnimatedSprite2D = $AnimatedBody
@onready var cloak_sprite: Sprite2D = $Cloak
@onready var body_sprite: Sprite2D = $Body
@onready var bones_sprite: Sprite2D = $Bones
@onready var eyes_sprite: Sprite2D = $Eyes
@onready var trait_overlay_sprite: Sprite2D = $TraitOverlay
@onready var facing_sprite: Sprite2D = $Facing

func _ready() -> void:
	_update_visuals()

func _physics_process(delta: float) -> void:
	invulnerability_timer = max(0.0, invulnerability_timer - delta)
	var input_vector := Input.get_vector("move_left", "move_right", "move_up", "move_down")
	if virtual_joystick_vector.length() > input_vector.length():
		input_vector = virtual_joystick_vector
	if input_vector.length() > 0.01:
		var new_facing := input_vector.normalized()
		facing_direction = new_facing
	velocity = input_vector * speed
	move_and_slide()
	global_position = global_position.clamp(Vector2(32, 32), world_size - Vector2(32, 32))
	_update_runtime_visuals()

func take_damage(amount: float) -> void:
	if health <= 0 or invulnerability_timer > 0.0:
		return
	health = max(0.0, health - amount)
	invulnerability_timer = invulnerability_duration
	_update_runtime_visuals()
	damaged.emit(health)
	if health <= 0.0:
		died.emit()

func increase_vitality() -> void:
	max_health += 20.0
	health = min(max_health, health + 24.0)
	damaged.emit(health)

func heal_percent(percent: float) -> void:
	if health <= 0.0:
		return
	health = min(max_health, health + max_health * percent)
	damaged.emit(health)

func set_virtual_joystick_vector(input_vector: Vector2) -> void:
	virtual_joystick_vector = input_vector.limit_length(1.0)

func add_passive_trait(trait_id: String) -> void:
	passive_traits[trait_id] = true
	_update_trait_overlay()

func _update_visuals() -> void:
	var base_scale := radius / 18.0
	invulnerability_sprite.texture = TextureFactory.player_layer("invulnerability")
	glow_sprite.texture = TextureFactory.player_layer("glow")
	glow_sprite.scale = Vector2.ONE * (base_scale * 1.18)
	var body_style := DuelystTheme.player_style()
	if body_style.get("frames") != null:
		animated_body.visible = true
		animated_body.sprite_frames = body_style.get("frames")
		animated_body.scale = Vector2.ONE * float(body_style.get("scale", 0.52))
		animated_body.position = body_style.get("offset", Vector2.ZERO)
		animated_body.speed_scale = float(body_style.get("speed", 10.0)) / 10.0
		DuelystTheme.play_best_animation(animated_body)
		cloak_sprite.visible = false
		body_sprite.visible = false
		bones_sprite.visible = false
		eyes_sprite.visible = false
		facing_sprite.visible = false
	else:
		animated_body.visible = false
		animated_body.position = Vector2.ZERO
		cloak_sprite.texture = TextureFactory.player_layer("cloak")
		body_sprite.texture = TextureFactory.player_layer("body")
		bones_sprite.texture = TextureFactory.player_layer("bones")
		eyes_sprite.texture = TextureFactory.player_layer("eyes")
		facing_sprite.texture = TextureFactory.player_layer("facing")
		cloak_sprite.visible = true
		body_sprite.visible = true
		bones_sprite.visible = true
		eyes_sprite.visible = true
		facing_sprite.visible = true
		for sprite in [cloak_sprite, body_sprite, bones_sprite, eyes_sprite, facing_sprite]:
			sprite.scale = Vector2.ONE * base_scale
	for sprite in [trait_overlay_sprite, invulnerability_sprite]:
		sprite.scale = Vector2.ONE * base_scale
	_update_trait_overlay()
	_update_runtime_visuals()

func _update_trait_overlay() -> void:
	var layer := ""
	if passive_traits.has("bone_wheel"):
		layer = "bone_wheel"
	elif passive_traits.has("spirit_core"):
		layer = "spirit_ring"
	elif passive_traits.has("blood_pact"):
		layer = "core"
	elif passive_traits.has("ember_crown"):
		layer = "ember_crown"
	elif passive_traits.has("lens_of_ruin"):
		layer = "lens"
	elif passive_traits.has("powder_heart"):
		layer = "powder"
	elif passive_traits.has("abyss_mark") or passive_traits.has("eldritch_eye"):
		layer = "abyss_horns"
	trait_overlay_sprite.visible = layer != ""
	if trait_overlay_sprite.visible:
		trait_overlay_sprite.texture = TextureFactory.player_layer(layer)

func _update_runtime_visuals() -> void:
	invulnerability_sprite.visible = invulnerability_timer > 0.0 and int(invulnerability_timer * 12.0) % 2 == 0
	animated_body.flip_h = facing_direction.x < -0.08
