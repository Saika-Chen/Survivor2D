extends SceneTree

const CombatFeedbackScript := preload("res://scripts/combat/CombatFeedback.gd")

func _initialize() -> void:
	var hit: Dictionary = CombatFeedbackScript.damage_popup(128.0, true)
	var death: Dictionary = CombatFeedbackScript.death_style("bomber", 24.0)
	print("%s|%s" % [str(hit.get("text", "")), str(death.get("radius", -1.0))])
	quit(0)
