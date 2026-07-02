extends SceneTree

const WaveMutationDirectorScript := preload("res://scripts/game/WaveMutationDirector.gd")

func _initialize() -> void:
	var director := WaveMutationDirectorScript.new()
	var mutation: Dictionary = director.build_mutation(25, false)
	print("%s|%s|%s" % [str(mutation.get("title", "")), str(mutation.get("spawn_density_multiplier", 0.0)), str(mutation.get("reward_type", ""))])
	quit(0)
