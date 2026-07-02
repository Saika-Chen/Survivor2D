extends SceneTree

const WaveDirectorScript := preload("res://scripts/game/wave_director.gd")

func _initialize() -> void:
	var director := WaveDirectorScript.new()
	director._ready()
	director.reset()
	assert(director.wave == 1, "Wave director should reset back to wave 1")
	assert(director.wave_target_total > 0, "Wave director should compute a positive wave target after reset")
	director.free()
	quit()
