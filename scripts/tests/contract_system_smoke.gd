extends SceneTree

const ContractDirectorScript := preload("res://scripts/game/ContractDirector.gd")

func _initialize() -> void:
	var director := ContractDirectorScript.new()
	var offer: Dictionary = director.build_offer(5, false)
	print("%s|%s" % [str(offer.get("title", "")), str(offer.get("options", []).size())])
	quit(0)
