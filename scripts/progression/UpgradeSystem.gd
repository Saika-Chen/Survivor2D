extends RefCounted
class_name UpgradeSystem

func rerolls_for_level(level: int) -> int:
	return 1 + level / 8
