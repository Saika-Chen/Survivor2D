extends SceneTree

func _initialize() -> void:
	var db := preload("res://scripts/weapons/WeaponDatabase.gd").new()
	var title := str(db.get_definition("blood_bolt").get("title", ""))
	if title != "血咒弹":
		push_error("Weapon database smoke test expected 血咒弹, got %s" % title)
		quit(1)
		return
	print(title)
	quit(0)
