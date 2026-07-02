class_name DOTween
extends RefCounted

static func _meta_key(key: String) -> String:
	return "__dotween_%s" % key

static func kill(owner: Object, key: String) -> void:
	if owner == null or key.is_empty():
		return
	var meta_key := _meta_key(key)
	if not owner.has_meta(meta_key):
		return
	var tween = owner.get_meta(meta_key)
	if tween is Tween and tween.is_valid():
		tween.kill()
	owner.remove_meta(meta_key)

static func sequence(owner: Node, key := "") -> Tween:
	if not key.is_empty():
		kill(owner, key)
	var tween := owner.create_tween()
	tween.bind_node(owner)
	if not key.is_empty():
		owner.set_meta(_meta_key(key), tween)
	return tween

static func pulse_scale(owner: Node, target: Node, base_scale: Vector2, multiplier := 1.08, duration := 0.36, key := "") -> Tween:
	var tween := sequence(owner, key)
	tween.set_loops()
	tween.tween_property(target, "scale", base_scale * multiplier, duration).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	tween.tween_property(target, "scale", base_scale, duration).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	return tween

static func pop_in(owner: Node, target: CanvasItem, duration := 0.24, from_scale := Vector2.ONE * 0.86, to_scale := Vector2.ONE, key := "") -> Tween:
	target.visible = true
	target.scale = from_scale
	target.modulate.a = 0.0
	var tween := sequence(owner, key)
	tween.set_parallel(true)
	tween.tween_property(target, "scale", to_scale, duration).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.tween_property(target, "modulate:a", 1.0, duration * 0.8).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	return tween

static func fade_out(owner: Node, target: CanvasItem, duration := 0.24, key := "", hide_after := true) -> Tween:
	var tween := sequence(owner, key)
	tween.tween_property(target, "modulate:a", 0.0, duration).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)
	if hide_after:
		tween.tween_callback(func() -> void:
			target.hide()
		)
	return tween

static func delayed_call(owner: Node, delay: float, callback: Callable, key := "") -> Tween:
	var tween := sequence(owner, key)
	tween.tween_interval(delay)
	tween.tween_callback(callback)
	return tween

static func oscillate_property(owner: Node, target: Object, property: String, from_value, to_value, duration := 0.5, key := "") -> Tween:
	var tween := sequence(owner, key)
	tween.set_loops()
	tween.tween_property(target, property, to_value, duration).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	tween.tween_property(target, property, from_value, duration).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	return tween

static func spin_property(owner: Node, target: Object, property: String, delta_value, duration := 1.0, key := "") -> Tween:
	var tween := sequence(owner, key)
	tween.set_loops()
	tween.tween_property(target, property, delta_value, duration).as_relative().set_trans(Tween.TRANS_LINEAR).set_ease(Tween.EASE_IN_OUT)
	return tween
