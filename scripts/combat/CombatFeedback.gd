extends RefCounted
class_name CombatFeedback

static func damage_popup(amount: float, critical: bool) -> Dictionary:
	return {
		"text": "%d" % int(round(amount)),
		"color": Color(1.0, 0.16, 0.08, 1.0) if critical else Color(1.0, 0.98, 0.46, 1.0),
		"duration": 0.92 if critical else 0.72,
		"velocity": Vector2(0, -76.0 if critical else -52.0)
	}

static func death_style(archetype: String, radius: float) -> Dictionary:
	var color := Color(1.0, 0.15, 0.10, 0.82)
	var scale := 2.4
	match archetype:
		"bomber":
			color = Color(0.72, 1.0, 0.18, 0.86)
			scale = 3.24
		"boss":
			color = Color(1.0, 0.52, 0.18, 0.92)
			scale = 3.8
		"bullet_boss":
			color = Color(0.78, 0.88, 1.0, 0.9)
			scale = 3.9
		"elite":
			color = Color(0.86, 0.28, 1.0, 0.88)
			scale = 3.0
	return {
		"color": color,
		"radius": max(42.0, radius * scale),
		"duration": 0.46
	}

static func shake_for_hit(critical: bool) -> Dictionary:
	if critical:
		return {"duration": 0.12, "strength": 7.0}
	return {"duration": 0.08, "strength": 4.5}

static func death_shake(archetype: String) -> Dictionary:
	match archetype:
		"boss":
			return {"duration": 0.30, "strength": 18.0}
		"bullet_boss":
			return {"duration": 0.26, "strength": 16.0}
		"elite":
			return {"duration": 0.18, "strength": 12.0}
		"bomber":
			return {"duration": 0.14, "strength": 9.0}
		_:
			return {"duration": 0.10, "strength": 7.0}
