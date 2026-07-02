extends Node

var pool_root: Node
var object_pools := {}
var pool_limits := {}
var prewarm_count := 20
var effect_script: Script

func setup(parent: Node, limits: Dictionary, prewarm_scene_map: Dictionary, new_effect_script: Script, new_prewarm_count := 20) -> void:
	pool_limits = limits.duplicate(true)
	effect_script = new_effect_script
	prewarm_count = new_prewarm_count
	pool_root = Node.new()
	pool_root.name = "ObjectPool"
	parent.add_child(pool_root)
	_prewarm_object_pools(prewarm_scene_map)

func _prewarm_object_pools(scene_map: Dictionary) -> void:
	for pool_id in scene_map.keys():
		_prewarm_pool(str(pool_id), scene_map[pool_id], prewarm_count)

func _prewarm_pool(pool_id: String, scene: PackedScene, count: int) -> void:
	var pool: Array = object_pools.get(pool_id, [])
	while pool.size() < count:
		var node: Node2D
		if scene != null:
			node = scene.instantiate()
		else:
			node = Node2D.new()
			if effect_script != null:
				node.set_script(effect_script)
			node.set_meta("pool_id", "effect")
		_prepare_node_for_pool(node)
		pool_root.add_child(node)
		pool.append(node)
	object_pools[pool_id] = pool

func _prepare_node_for_pool(node: Node) -> void:
	node.hide()
	node.process_mode = Node.PROCESS_MODE_DISABLED
	node.set_process(false)
	node.set_physics_process(false)

func _prewarm_ui_burst_pool(count: int) -> void:
	var pool: Array = object_pools.get("ui_burst", [])
	while pool.size() < count:
		var rect := ColorRect.new()
		rect.color = Color.WHITE
		_prepare_node_for_pool(rect)
		pool_root.add_child(rect)
		pool.append(rect)
	object_pools["ui_burst"] = pool

func take_from_pool(pool_id: String, scene: PackedScene) -> Node2D:
	var pool: Array = object_pools.get(pool_id, [])
	while not pool.is_empty():
		var node: Node2D = pool.pop_back()
		if is_instance_valid(node):
			if node.get_parent() != null:
				node.get_parent().remove_child(node)
			node.process_mode = Node.PROCESS_MODE_INHERIT
			node.show()
			node.set_process(true)
			node.set_physics_process(true)
			object_pools[pool_id] = pool
			return node
	object_pools[pool_id] = pool
	if scene == null:
		return Node2D.new()
	return scene.instantiate()

func take_ui_burst_from_pool() -> ColorRect:
	var pool: Array = object_pools.get("ui_burst", [])
	while not pool.is_empty():
		var node: Node = pool.pop_back()
		if is_instance_valid(node):
			if node.get_parent() != null:
				node.get_parent().remove_child(node)
			node.process_mode = Node.PROCESS_MODE_INHERIT
			node.show()
			node.set_process(true)
			node.set_physics_process(true)
			object_pools["ui_burst"] = pool
			var rect := node as ColorRect
			rect.modulate = Color.WHITE
			rect.rotation = 0.0
			return rect
	object_pools["ui_burst"] = pool
	var replacement := ColorRect.new()
	replacement.color = Color.WHITE
	return replacement

func return_to_pool(node: Node, pool_id: String) -> void:
	if node == null or not is_instance_valid(node):
		return
	if node.get_parent() == pool_root:
		return
	var pool: Array = object_pools.get(pool_id, [])
	if node.get_parent() != null:
		node.get_parent().remove_child(node)
	if pool_id == "enemy" and node.has_method("set_batched_visual_enabled"):
		node.set_batched_visual_enabled(false)
	if pool.size() >= int(pool_limits.get(pool_id, 32)):
		node.queue_free()
		return
	_prepare_node_for_pool(node)
	pool_root.add_child(node)
	pool.append(node)
	object_pools[pool_id] = pool

func return_effect_child(node: Node) -> void:
	if node is GPUParticles2D:
		return_to_pool(node, "particle_burst")
	elif node.has_signal("despawn_requested"):
		return_to_pool(node, str(node.get_meta("pool_id", "effect")))
	else:
		node.queue_free()
