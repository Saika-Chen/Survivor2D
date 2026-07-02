extends Node2D

const TextureFactory := preload("res://scripts/visuals/texture_factory.gd")
const DuelystTheme := preload("res://scripts/visuals/duelyst_theme.gd")
const EnemyBatchShader := preload("res://shaders/enemy_batch_gpu.gdshader")

const BATCH_ARCHETYPES: Array[String] = [
	"chaser",
	"shooter",
	"buffer",
	"charger",
	"tank",
	"splitter",
	"bomber"
]

const UPDATE_EVERY_N_FRAMES := 5

@export var max_instances_per_archetype := 320

var enemy_root: Node2D
var batches := {}
var frame_textures := {}
var frame_timers := {}
var frame_skip := 0
var cached_grouped := {}

func _ready() -> void:
	z_index = 2
	for archetype in BATCH_ARCHETYPES:
		_create_batch(archetype)
		cached_grouped[archetype] = []

func setup(root: Node2D) -> void:
	enemy_root = root

func _process(delta: float) -> void:
	if enemy_root == null:
		_clear_batches()
		return
	frame_skip += 1
	if frame_skip >= UPDATE_EVERY_N_FRAMES:
		frame_skip = 0
		_rebuild_groups()
	_animate_frames(delta * UPDATE_EVERY_N_FRAMES)
	# Every frame: lightweight transform update
	for archetype in BATCH_ARCHETYPES:
		var enemies: Array = cached_grouped.get(archetype, [])
		if enemies.size() > 0:
			_update_transforms(archetype, enemies)

func _rebuild_groups() -> void:
	for archetype in BATCH_ARCHETYPES:
		cached_grouped[archetype] = []
	for enemy_node in enemy_root.get_children():
		var enemy := enemy_node as Node2D
		if enemy == null or not is_instance_valid(enemy):
			continue
		if float(enemy.get("health")) <= 0.0:
			continue
		if not enemy.has_method("is_gpu_batch_candidate") or not enemy.is_gpu_batch_candidate():
			if enemy.has_method("set_batched_visual_enabled"):
				enemy.set_batched_visual_enabled(false)
			continue
		var archetype := str(enemy.get("archetype"))
		if not cached_grouped.has(archetype):
			continue
		enemy.set_batched_visual_enabled(true)
		(cached_grouped[archetype] as Array).append(enemy)
	for archetype in BATCH_ARCHETYPES:
		_update_visible_count(archetype, cached_grouped.get(archetype, []))

func _update_transforms(archetype: String, enemies: Array) -> void:
	if not batches.has(archetype):
		return
	var batch := batches[archetype] as MultiMeshInstance2D
	var multimesh := batch.multimesh
	# Compact dead entries
	var i := enemies.size() - 1
	while i >= 0:
		if not is_instance_valid(enemies[i]):
			enemies.remove_at(i)
		i -= 1
	var count: int = min(enemies.size(), max_instances_per_archetype)
	multimesh.visible_instance_count = count
	for index in range(count):
		var enemy: Node2D = enemies[index]
		if not is_instance_valid(enemy):
			continue
		var scale_value := _visual_scale_for(enemy)
		var flip := -1.0 if float(enemy.get("velocity").x) < -0.01 else 1.0
		var basis_x := Vector2(scale_value * flip, 0.0)
		var basis_y := Vector2(0.0, scale_value)
		multimesh.set_instance_transform_2d(index, Transform2D(basis_x, basis_y, enemy.global_position))
		multimesh.set_instance_color(index, _color_for(enemy))

func _update_visible_count(archetype: String, enemies: Array) -> void:
	if not batches.has(archetype):
		return
	var batch := batches[archetype] as MultiMeshInstance2D
	var count: int = min(enemies.size(), max_instances_per_archetype)
	batch.multimesh.visible_instance_count = count

func _animate_frames(delta: float) -> void:
	for archetype in BATCH_ARCHETYPES:
		var textures: Array = frame_textures.get(archetype, [])
		if textures.size() <= 1:
			continue
		var batch: MultiMeshInstance2D = batches.get(archetype)
		if batch == null or batch.multimesh.visible_instance_count <= 0:
			continue
		frame_timers[archetype] = frame_timers.get(archetype, 0.0) + delta
		var frame_index: int = int(floor(frame_timers[archetype] * 9.0)) % textures.size()
		batch.texture = textures[frame_index]

func _create_batch(archetype: String) -> void:
	var quad_mesh := QuadMesh.new()
	quad_mesh.size = Vector2(128.0, 128.0)
	var multimesh := MultiMesh.new()
	multimesh.transform_format = MultiMesh.TRANSFORM_2D
	multimesh.use_colors = true
	multimesh.mesh = quad_mesh
	multimesh.instance_count = max_instances_per_archetype
	multimesh.visible_instance_count = 0
	var batch := MultiMeshInstance2D.new()
	batch.name = "EnemyGPUBatch_%s" % archetype
	var meta = DuelystTheme.batch_texture_meta(archetype)
	if meta.is_empty():
		batch.texture = TextureFactory.enemy_body(archetype)
	else:
		var textures: Array = meta.get("textures", [])
		if textures.size() > 0:
			batch.texture = textures[0]
			frame_textures[archetype] = textures
			frame_timers[archetype] = 0.0
	batch.material = _new_batch_material()
	batch.multimesh = multimesh
	batch.z_index = 2
	add_child(batch)
	batches[archetype] = batch

func _new_batch_material() -> ShaderMaterial:
	var material := ShaderMaterial.new()
	material.shader = EnemyBatchShader
	material.set_shader_parameter("sway_strength", 2.8)
	material.set_shader_parameter("breath_strength", 0.052)
	material.set_shader_parameter("glow_strength", 0.16)
	return material

func _visual_scale_for(enemy: Node2D) -> float:
	var radius := float(enemy.get("radius"))
	return max(0.64, radius / 22.0)

func _color_for(enemy: Node2D) -> Color:
	var archetype := str(enemy.get("archetype"))
	var color := Color.WHITE
	match archetype:
		"shooter":
			color = Color(0.70, 0.88, 1.0, 1.0)
		"buffer":
			color = Color(0.88, 0.62, 1.0, 1.0)
		"charger":
			color = Color(1.0, 0.58, 0.42, 1.0)
		"tank":
			color = Color(0.88, 0.78, 0.56, 1.0)
		"splitter":
			color = Color(1.0, 0.72, 0.94, 1.0)
		"bomber":
			color = Color(0.76, 1.0, 0.54, 1.0)
	if float(enemy.get("slow_timer")) > 0.0:
		color = color.lerp(Color(0.48, 0.78, 1.0, 1.0), 0.58)
	if enemy.has_method("gpu_hit_flash"):
		color = color.lerp(Color(1.0, 0.74, 0.42, 1.0), enemy.gpu_hit_flash())
	return color

func _clear_batches() -> void:
	for batch in batches.values():
		var multimesh: MultiMesh = (batch as MultiMeshInstance2D).multimesh
		multimesh.visible_instance_count = 0
