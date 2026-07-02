extends SceneTree

var elapsed := 0.0

func _initialize() -> void:
	change_scene_to_file("res://scenes/main/Main.tscn")

func _process(delta: float) -> bool:
	elapsed += delta
	if elapsed >= 5.0:
		quit()
		return true
	return false
