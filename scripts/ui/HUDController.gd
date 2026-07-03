extends RefCounted
class_name HUDController

# HUD 文本拼装工具：统一生成战斗中需要显示的统计文本。

static func format_stats(health: float, max_health: float, score: int, elapsed: float, enemy_count: int, level: int, experience: int, experience_to_next: int, wave: int, max_wave: int, time_left: float, attack_power: float, crit_chance: float, crit_damage: float, lifesteal_chance: float, lifesteal_amount: float, run_magic_crystals: int, contract_summary := "") -> String:
	var seconds := int(elapsed) % 60
	var minutes := int(elapsed) / 60
	var stats_text := "⚔ 攻击力 %.0f\n✦ 暴击 %.0f%%  爆伤 x%.2f\n🩸 吸血 %.0f%%  +%.0f\n◆ 本局魔晶 %d\n☠ 击杀 %d\n◷ %02d:%02d\n◆ 敌人 %d" % [
		max(1.0, attack_power),
		crit_chance * 100.0,
		crit_damage,
		lifesteal_chance * 100.0,
		lifesteal_amount,
		run_magic_crystals,
		score,
		minutes,
		seconds,
		enemy_count
	]
	if contract_summary != "":
		stats_text += "\n%s" % contract_summary
	return stats_text

static func stack_summary(summary: String, separator: String, max_lines: int) -> String:
	var pieces := summary.split(separator, false)
	if pieces.size() <= 1:
		return summary
	var visible: Array[String] = []
	for index in range(min(max_lines, pieces.size())):
		visible.append(pieces[index])
	if pieces.size() > max_lines:
		visible.append("+%d" % (pieces.size() - max_lines))
	return "\n".join(visible)
