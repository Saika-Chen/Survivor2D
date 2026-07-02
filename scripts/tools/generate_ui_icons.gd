extends SceneTree

const OUTPUT_DIR := "res://resources/ui/generated/"
const ICONS := {
	"weapon_blood_bolt": Color(1.0, 0.12, 0.10),
	"weapon_laser": Color(1.0, 0.62, 0.45),
	"weapon_bomb": Color(0.58, 1.0, 0.18),
	"weapon_tentacle": Color(0.72, 0.22, 1.0),
	"weapon_scythe": Color(0.72, 0.86, 1.0),
	"relic": Color(0.92, 0.72, 1.0),
	"magnet": Color(0.30, 0.76, 1.0),
	"potion": Color(0.30, 1.0, 0.45),
	"rarity_legend": Color(1.0, 0.62, 0.12)
}

func _initialize() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUTPUT_DIR))
	for icon_name in ICONS.keys():
		_save_icon(icon_name, ICONS[icon_name])
	quit(0)

func _save_icon(icon_name: String, color: Color) -> void:
	var image := Image.create(64, 64, false, Image.FORMAT_RGBA8)
	image.fill(Color(0, 0, 0, 0))
	for x in range(64):
		for y in range(64):
			var point := Vector2(x - 32, y - 32)
			var distance := point.length()
			if distance < 30.0:
				var alpha := clampf(1.0 - distance / 31.0, 0.0, 1.0)
				var glow := color.lightened(0.35)
				image.set_pixel(x, y, Color(glow.r, glow.g, glow.b, alpha * 0.96))
			if distance < 20.0:
				var core := color.lightened(0.55)
				image.set_pixel(x, y, Color(core.r, core.g, core.b, 0.95))
			if abs(point.x) + abs(point.y) < 22.0:
				image.set_pixel(x, y, Color(1.0, 0.97, 0.90, 0.92))
	var path := "%s%s.png" % [OUTPUT_DIR, icon_name]
	image.save_png(path)
