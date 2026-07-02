extends Node2D

const TextureFactory := preload("res://scripts/visuals/texture_factory.gd")

@export var arena_size := Vector2(15600, 10800)
@export var tile_style_block_size := 8

var tile_paths: Array[String] = [
	"res://assets/art/generated/tiles/tile_floor_0.png",
	"res://assets/art/generated/tiles/tile_floor_1.png",
	"res://assets/art/generated/tiles/tile_floor_2.png",
	"res://assets/art/generated/tiles/tile_floor_3.png",
	"res://assets/art/generated/tiles/tile_floor_4.png",
	"res://assets/art/generated/tiles/tile_floor_5.png",
	"res://assets/art/generated/tiles/tile_floor_6.png",
	"res://assets/art/generated/tiles/tile_floor_7.png"
]
var tile_textures: Array[Texture2D] = []
var tile_batch_nodes: Array[MultiMeshInstance2D] = []
var fallback_texture: Texture2D
var tile_size := Vector2(128, 128)

func _ready() -> void:
	for path in tile_paths:
		var texture := _load_png_texture(path)
		if texture != null:
			tile_textures.append(texture)
	if tile_textures.is_empty():
		fallback_texture = TextureFactory.arena_background()
		tile_textures.append(fallback_texture)
	tile_size = Vector2(tile_textures[0].get_width(), tile_textures[0].get_height())
	_build_tile_batches()

func _build_tile_batches() -> void:
	for child in get_children():
		child.queue_free()
	tile_batch_nodes.clear()
	var columns := int(ceil(arena_size.x / tile_size.x))
	var rows := int(ceil(arena_size.y / tile_size.y))
	var batches: Array[Array] = []
	for texture_index in range(tile_textures.size()):
		batches.append([])
	for x in range(columns):
		for y in range(rows):
			var position := Vector2(float(x) * tile_size.x, float(y) * tile_size.y)
			var texture_index := _tile_index_for_cell(x, y)
			batches[texture_index].append(position)
	for texture_index in range(tile_textures.size()):
		var positions: Array = batches[texture_index]
		if positions.is_empty():
			continue
		var quad_mesh := QuadMesh.new()
		quad_mesh.size = tile_size
		var multimesh := MultiMesh.new()
		multimesh.transform_format = MultiMesh.TRANSFORM_2D
		multimesh.mesh = quad_mesh
		multimesh.instance_count = positions.size()
		for instance_index in range(positions.size()):
			var position: Vector2 = positions[instance_index]
			multimesh.set_instance_transform_2d(instance_index, Transform2D(0.0, position + tile_size * 0.5))
		var batch := MultiMeshInstance2D.new()
		batch.name = "TileBatch%d" % texture_index
		batch.texture = tile_textures[texture_index]
		batch.multimesh = multimesh
		add_child(batch)
		tile_batch_nodes.append(batch)

func _tile_for_cell(x: int, y: int) -> Texture2D:
	return tile_textures[_tile_index_for_cell(x, y)]

func _tile_index_for_cell(x: int, y: int) -> int:
	var block_x := x / tile_style_block_size
	var block_y := y / tile_style_block_size
	var style_index := int(abs(block_x * 31 + block_y * 17)) % tile_textures.size()
	var local_variation := int(abs(x * 13 + y * 7 + block_x * 5)) % 11
	if local_variation == 0:
		style_index = (style_index + 1) % tile_textures.size()
	elif local_variation == 1:
		style_index = (style_index + tile_textures.size() - 1) % tile_textures.size()
	return style_index

func _load_png_texture(path: String) -> Texture2D:
	if not ResourceLoader.exists(path):
		return null
	return load(path) as Texture2D
