# UI Rebuild Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Replace the game's UI art with the new `ui/` image set, align the in-game HUD and menus to the provided reference, and remove the obsolete generated UI art files.

**Architecture:** Keep the gameplay/UI logic in the existing scripts, but move every pixel-art UI lookup behind one asset resolver in `TextureFactory`. Then re-lay out the HUD and menu scenes so the new textures are placed on the same functional controls the game already uses. Finally, delete the old generated UI images and update the smoke assertions so they validate the new art paths.

**Tech Stack:** Godot 4.7, GDScript, existing HUD/bootstrap scenes, existing smoke tests.

---

### Task 1: Remap Pixel UI Assets

**Files:**
- Modify: `scripts/visuals/texture_factory.gd`
- Modify: `scripts/tools/generate_pixel_assets.gd`
- Modify: `scripts/tools/headless_gameplay_assertions.gd`

- [ ] **Step 1: Add a failing check for the new UI asset source**

```gdscript
assert(ResourceLoader.exists("res://ui/slice_0002.png"))
assert(ResourceLoader.exists("res://ui/slice_0002.png"))
```

- [ ] **Step 2: Run the smoke assertion and confirm it fails before the remap**

Run: `"/Applications/Godot.app/Contents/MacOS/Godot" --headless --path "/Users/mac/Documents/Codex/2026-06-28/wo/Survivor2D" --script res://scripts/tools/headless_gameplay_assertions.gd`
Expected: fail because the assertions still point at the generated UI folder.

- [ ] **Step 3: Implement the asset resolver and new file mapping**

```gdscript
const PIXEL_UI_MAP := {
	"hp_bar": "slice_0037",
	"xp_bar": "slice_0036",
	"menu_frame": "slice_0004",
	"talent_frame": "slice_0039",
	"option_card": "slice_0041",
	"slot_frame": "slice_0039",
	"warning_banner": "slice_0027"
}

static func pixel_ui_asset(asset_id: String) -> Texture2D:
	var mapped_id := str(PIXEL_UI_MAP.get(asset_id, asset_id))
	return _fetch("pixel_ui_%s" % mapped_id, func() -> Texture2D:
		var texture := _load_png_texture("res://ui/%s.png" % mapped_id)
		return texture if texture != null else warning_banner()
	)
```

- [ ] **Step 4: Update the smoke assertion to the `ui/` folder**

```gdscript
assert(FileAccess.file_exists("res://ui/slice_0002.png"), "New UI slice set should exist")
assert(FileAccess.file_exists("res://ui/slice_0039.png"), "New slot / frame art should exist")
```

- [ ] **Step 5: Run the smoke assertion again and confirm the new path passes**

Run: `"/Applications/Godot.app/Contents/MacOS/Godot" --headless --path "/Users/mac/Documents/Codex/2026-06-28/wo/Survivor2D" --script res://scripts/tools/headless_gameplay_assertions.gd`
Expected: pass once the resolver and assertion paths match the new art set.

### Task 2: Rebuild HUD Layout Around New Art

**Files:**
- Modify: `scripts/ui/hud.gd`
- Modify: `scenes/ui/HUD.tscn`

- [ ] **Step 1: Add a failing runtime expectation for the new art-backed HUD nodes**

```gdscript
assert(hud.health_bar.texture_under != null)
assert(hud.slot_frame.texture != null)
```

- [ ] **Step 2: Rework the HUD build path to place the new portrait, bars, map, equipment, and menu art**

```gdscript
func _build_pixel_ui_art() -> void:
	option_card_texture = TextureFactory.pixel_ui_asset("option_card")
	stats_art = _new_ui_texture("StatsArt", TextureFactory.pixel_ui_asset("menu_frame"), Color(1, 1, 1, 1))
	right_art = _new_ui_texture("RightArt", TextureFactory.pixel_ui_asset("menu_frame"), Color(1, 1, 1, 1))
	stats_panel = _new_ui_texture("StatsPanel", TextureFactory.pixel_ui_asset("talent_frame"), Color(1, 1, 1, 1))
	right_panel = _new_ui_texture("RightPanel", TextureFactory.pixel_ui_asset("menu_frame"), Color(1, 1, 1, 1))
}
```

- [ ] **Step 3: Replace the current plain bars with the new themed bars and portrait framing**

```gdscript
func _configure_pixel_bars() -> void:
	health_bar.texture_under = TextureFactory.pixel_ui_asset("hp_bar")
	health_bar.texture_progress = TextureFactory.pixel_ui_asset("hp_bar")
	xp_bar.texture_under = TextureFactory.pixel_ui_asset("xp_bar")
	xp_bar.texture_progress = TextureFactory.pixel_ui_asset("xp_bar")
	slot_frame.texture = TextureFactory.pixel_slot_frame()
	wave_alert_frame.texture = TextureFactory.warning_banner()
```

- [ ] **Step 4: Adjust layout helpers so the new art lands where the reference shows it**

```gdscript
func _apply_landscape_layout() -> void:
	_layout_art(stats_panel, Rect2(8.0, 8.0, 520.0, 190.0))
	_layout_art(right_panel, Rect2(860.0, 50.0, 408.0, 260.0))
	_layout_bottom_xp(viewport_size)
```

- [ ] **Step 5: Run the HUD smoke assertions**

Run: `"/Applications/Godot.app/Contents/MacOS/Godot" --headless --path "/Users/mac/Documents/Codex/2026-06-28/wo/Survivor2D" --script res://scripts/tests/rearchitecture_smoke.gd`
Expected: pass with the HUD still instantiating and the art nodes present.

### Task 3: Update Bootstrap and Menu Surfaces

**Files:**
- Modify: `scripts/ui/bootstrap.gd`
- Modify: `scripts/tools/headless_bootstrap_assertions.gd`

- [ ] **Step 1: Add a failing check for the new button skin and frame art**

```gdscript
assert(bootstrap.menu_pixel_frame.texture != null)
assert(bootstrap.hero_tab_button.has_theme_stylebox("normal"))
```

- [ ] **Step 2: Use the new slice-backed button and frame textures everywhere the menu uses the old generated art**

```gdscript
menu_pixel_frame = _new_pixel_frame("HeroMenuFrame", TextureFactory.pixel_ui_asset("menu_frame"))
_apply_pixel_button_style(hero_tab_button, TextureFactory.pixel_ui_asset("option_card"))
talent_pixel_frame = _new_pixel_frame("TalentFrame", TextureFactory.pixel_ui_asset("talent_frame"))
```

- [ ] **Step 3: Update the bootstrap smoke assertion to the new asset references**

```gdscript
assert(FileAccess.file_exists("res://ui/slice_0004.png"), "Menu frame art should exist")
assert(FileAccess.file_exists("res://ui/slice_0041.png"), "Button art should exist")
```

- [ ] **Step 4: Run the bootstrap smoke assertion**

Run: `"/Applications/Godot.app/Contents/MacOS/Godot" --headless --path "/Users/mac/Documents/Codex/2026-06-28/wo/Survivor2D" --script res://scripts/tools/headless_bootstrap_assertions.gd`
Expected: pass after the menu art swaps are wired correctly.

### Task 4: Remove Obsolete Generated UI Art

**Files:**
- Delete: `assets/art/generated/ui/hp_bar.png`
- Delete: `assets/art/generated/ui/hp_bar.png.import`
- Delete: `assets/art/generated/ui/hud_panel_left.png`
- Delete: `assets/art/generated/ui/hud_panel_left.png.import`
- Delete: `assets/art/generated/ui/hud_panel_right.png`
- Delete: `assets/art/generated/ui/hud_panel_right.png.import`
- Delete: `assets/art/generated/ui/menu_frame.png`
- Delete: `assets/art/generated/ui/menu_frame.png.import`
- Delete: `assets/art/generated/ui/option_card.png`
- Delete: `assets/art/generated/ui/option_card.png.import`
- Delete: `assets/art/generated/ui/slot_frame.png`
- Delete: `assets/art/generated/ui/slot_frame.png.import`
- Delete: `assets/art/generated/ui/talent_frame.png`
- Delete: `assets/art/generated/ui/talent_frame.png.import`
- Delete: `assets/art/generated/ui/xp_bar.png`
- Delete: `assets/art/generated/ui/xp_bar.png.import`

- [ ] **Step 1: Remove the obsolete files from the workspace**

```bash
git rm assets/art/generated/ui/*.png assets/art/generated/ui/*.png.import
```

- [ ] **Step 2: Verify no code still references the old path**

```bash
rg -n "res://assets/art/generated/ui/" scripts scenes
```

- [ ] **Step 3: Run a final headless project boot**

Run: `"/Applications/Godot.app/Contents/MacOS/Godot" --headless --path "/Users/mac/Documents/Codex/2026-06-28/wo/Survivor2D" --quit`
Expected: project boots cleanly with the new UI assets.
