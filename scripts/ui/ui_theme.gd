extends RefCounted

const RARITY_COLORS := {
	"普通": Color(0.70, 0.78, 0.72),
	"稀有": Color(0.30, 0.68, 1.0),
	"史诗": Color(0.78, 0.34, 1.0),
	"传说": Color(1.0, 0.66, 0.16)
}

const RARITY_BACKGROUNDS := {
	"普通": Color(0.035, 0.045, 0.050, 0.92),
	"稀有": Color(0.030, 0.080, 0.130, 0.94),
	"史诗": Color(0.090, 0.030, 0.130, 0.94),
	"传说": Color(0.140, 0.075, 0.020, 0.95)
}

static func rarity_color(rarity: String) -> Color:
	return RARITY_COLORS.get(rarity, RARITY_COLORS["普通"])

static func rarity_background(rarity: String) -> Color:
	return RARITY_BACKGROUNDS.get(rarity, RARITY_BACKGROUNDS["普通"])
