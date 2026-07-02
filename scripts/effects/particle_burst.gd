extends GPUParticles2D

signal despawn_requested(burst: GPUParticles2D)

func configure(effect_type: String) -> void:
	if finished.is_connected(queue_free):
		finished.disconnect(queue_free)
	if not finished.is_connected(_on_finished):
		finished.connect(_on_finished)
	one_shot = true
	explosiveness = 0.88
	lifetime = 0.55
	amount = 28
	process_material = ParticleProcessMaterial.new()
	var material := process_material as ParticleProcessMaterial
	material.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_SPHERE
	material.emission_sphere_radius = 8.0
	material.initial_velocity_min = 90.0
	material.initial_velocity_max = 210.0
	material.gravity = Vector3.ZERO
	material.scale_min = 1.0
	material.scale_max = 2.8
	modulate = Color(1.0, 0.20, 0.12, 0.85)
	match effect_type:
		"pickup":
			amount = 18
			lifetime = 0.42
			material.initial_velocity_min = 55.0
			material.initial_velocity_max = 130.0
			modulate = Color(0.35, 0.95, 1.0, 0.82)
		"level_up":
			amount = 64
			lifetime = 0.9
			material.initial_velocity_min = 120.0
			material.initial_velocity_max = 290.0
			modulate = Color(1.0, 0.68, 0.18, 0.92)
		"legendary":
			amount = 72
			lifetime = 1.0
			material.initial_velocity_min = 140.0
			material.initial_velocity_max = 330.0
			modulate = Color(1.0, 0.45, 0.08, 0.95)
	emitting = true

func _on_finished() -> void:
	despawn_requested.emit(self)
