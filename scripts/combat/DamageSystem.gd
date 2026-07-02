extends RefCounted
class_name DamageSystem

func roll_critical(chance: float) -> bool:
	return randf() < chance

func compute_final_damage(base_amount: float, critical: bool, crit_damage_multiplier: float) -> float:
	var final_amount := base_amount
	if critical:
		final_amount *= crit_damage_multiplier
	return final_amount

func apply_lifesteal(chance: float, amount: float) -> bool:
	return randf() < chance and amount > 0.0
