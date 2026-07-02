extends SceneTree

const EncounterDirectorScript := preload("res://scripts/game/EncounterDirector.gd")

func _initialize() -> void:
	var director := EncounterDirectorScript.new()
	var event_data: Dictionary = director.build_event(12, false)
	print("%s|%d" % [str(event_data.get("title", "")), int((event_data.get("options", []) as Array).size())])
	quit(0)
