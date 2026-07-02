extends RefCounted
class_name LevelSystem

signal leveled_up(new_level: int)

var level: int = 1
var experience: int = 0
var experience_to_next: int = 10
var rerolls_left: int = 1
var experience_gain_bonus: float = 0.0

func reset() -> void:
	level = 1
	experience = 0
	experience_to_next = 10
	rerolls_left = 1
	experience_gain_bonus = 0.0

func set_experience_gain_bonus(value: float) -> void:
	experience_gain_bonus = max(0.0, value)

func gain_experience(amount: int) -> int:
	amount = int(round(float(amount) * (1.0 + experience_gain_bonus)))
	experience += amount
	var gained_levels := 0
	while experience >= experience_to_next:
		experience -= experience_to_next
		level += 1
		experience_to_next = int(float(level * level) * 3.0)
		rerolls_left = 1 + level / 8
		gained_levels += 1
		leveled_up.emit(level)
	return gained_levels

func start_level_up() -> int:
	rerolls_left = 1 + level / 8
	return rerolls_left

func consume_reroll() -> bool:
	if rerolls_left <= 0:
		return false
	rerolls_left -= 1
	return true

