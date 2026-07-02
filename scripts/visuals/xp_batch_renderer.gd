extends Node2D

const TextureFactory := preload("res://scripts/visuals/texture_factory.gd")

@export var max_instances := 400

var xp_root: Node2D
var multimesh: MultiMesh
var batch: MultiMeshInstance2D
var instance_data: Array[Dictionary] = []
var frame_skip := 0

func _ready() -> void:
	z_index = 1
	var quad_mesh := QuadMesh.new()
	quad_mesh.size = Vector2(64.0, 64.0)
	multimesh = MultiMesh.new()
	multimesh.transform_format = MultiMesh.TRANSFORM_2D
	multimesh.use_colors = true
	multimesh.mesh = quad_mesh
	multimesh.instance_count = max_instances
	multimesh.visible_instance_count = 0
	batch = MultiMeshInstance2D.new()
	batch.name = "XPGPUBatch"
	batch.texture = TextureFactory.xp_gem()
	batch.multimesh = multimesh
	batch.z_index = 1
	add_child(batch)

func setup(root: Node2D) -> void:
	xp_root = root

func _process(_delta: float) -> void:
	frame_skip += 1
	if frame_skip < 5:
		return
	frame_skip = 0
	if xp_root == null:
		multimesh.visible_instance_count = 0
		instance_data.clear()
		return
	instance_data.clear()
	for gem_node in xp_root.get_children():
		var gem := gem_node as Node2D
		if gem == null or not is_instance_valid(gem):
			continue
		instance_data.append({"position": gem.global_position, "scale": gem.get("radius") / 16.0})
	var count: int = min(instance_data.size(), max_instances)
	multimesh.visible_instance_count = count
	for index in range(count):
		var data: Dictionary = instance_data[index]
		var s := float(data.get("scale", 0.56))
		multimesh.set_instance_transform_2d(index, Transform2D(Vector2(s, 0), Vector2(0, s), data.get("position", Vector2.ZERO)))
		multimesh.set_instance_color(index, Color.WHITE)
