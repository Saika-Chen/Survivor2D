# Survivor2D Gameplay Boost Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Strengthen moment-to-moment combat feedback and add a richer wave event layer so each run feels more reactive, varied, and strategic.

**Architecture:** Keep the existing `game.gd` scene orchestration, but pull the most reusable feedback calculations into a small combat helper and expand the wave event system into a data-driven encounter layer. The combat pass should improve hit/kill/jackpot presentation without changing core balance, while the event pass should add new event types and temporary modifiers that expire cleanly at wave boundaries.

**Tech Stack:** Godot 4.7, GDScript, JSON data files, headless `--script` smoke tests.

---

### Task 1: Combat Feedback Pass

**Files:**
- Create: `scripts/combat/CombatFeedback.gd`
- Create: `scripts/tests/combat_feedback_smoke.gd`
- Modify: `scripts/game/game.gd`
- Modify: `scripts/ui/hud.gd`
- Modify: `scripts/enemy/enemy.gd`

- [ ] **Step 1: Write the failing smoke test**

```gdscript
extends SceneTree

const CombatFeedbackScript := preload("res://scripts/combat/CombatFeedback.gd")

func _initialize() -> void:
	var hit: Dictionary = CombatFeedbackScript.damage_popup(128.0, true)
	var death: Dictionary = CombatFeedbackScript.death_style("bomber")
	print("%s|%s" % [str(hit.get("text", "")), str(death.get("radius", -1.0))])
	quit(0)
```

- [ ] **Step 2: Run the smoke test and confirm it fails before implementation**

Run:

```bash
"/Applications/Godot.app/Contents/MacOS/Godot" --headless --path /Users/mac/Documents/Codex/2026-06-28/wo/Survivor2D --script res://scripts/tests/combat_feedback_smoke.gd
```

Expected: parse/load failure because `CombatFeedback.gd` does not exist yet.

- [ ] **Step 3: Implement the combat helper and wire it into the scene flow**

Add `scripts/combat/CombatFeedback.gd` with these exact static helpers:

```gdscript
extends RefCounted
class_name CombatFeedback

static func damage_popup(amount: float, critical: bool) -> Dictionary:
	return {
		"text": "%d" % int(round(amount)),
		"color": Color(1.0, 0.16, 0.08, 1.0) if critical else Color(1.0, 0.98, 0.46, 1.0),
		"duration": 0.92 if critical else 0.72,
		"velocity": Vector2(0, -76.0 if critical else -52.0)
	}

static func death_style(archetype: String, radius: float) -> Dictionary:
	var color := Color(1.0, 0.15, 0.10, 0.82)
	var scale := 2.4
	if archetype == "bomber":
		color = Color(0.72, 1.0, 0.18, 0.86)
		scale = 3.24
	return {
		"color": color,
		"radius": max(42.0, radius * scale),
		"duration": 0.46
	}

static func shake_for_hit(critical: bool) -> Dictionary:
	return {"duration": 0.12, "strength": 7.0} if critical else {"duration": 0.08, "strength": 4.5}
```

Update `game.gd` to call `CombatFeedback.damage_popup()` inside `_spawn_hit_effect()`, `CombatFeedback.death_style()` inside `_spawn_death_effect()`, and `CombatFeedback.shake_for_hit()` when applying kill feedback. Keep the existing HUD damage number path, but route the formatting through the helper so critical and non-critical hits stay consistent.

- [ ] **Step 4: Run the smoke test and the project headless**

Run:

```bash
"/Applications/Godot.app/Contents/MacOS/Godot" --headless --path /Users/mac/Documents/Codex/2026-06-28/wo/Survivor2D --script res://scripts/tests/combat_feedback_smoke.gd
"/Applications/Godot.app/Contents/MacOS/Godot" --headless --path /Users/mac/Documents/Codex/2026-06-28/wo/Survivor2D --quit
```

Expected: the smoke test prints a short summary and exits 0; the project headless run exits 0 with the existing unrelated UID warning only.

- [ ] **Step 5: Commit**

```bash
git add scripts/combat/CombatFeedback.gd scripts/tests/combat_feedback_smoke.gd scripts/game/game.gd scripts/ui/hud.gd scripts/enemy/enemy.gd
git commit -m "feat: improve combat feedback"
```

### Task 2: Wave Event Expansion

**Files:**
- Create: `data/encounters.json`
- Create: `scripts/game/EncounterDirector.gd`
- Create: `scripts/tests/event_system_smoke.gd`
- Modify: `scripts/game/RunEventSystem.gd`
- Modify: `scripts/game/game.gd`
- Modify: `scripts/ui/hud.gd`

- [ ] **Step 1: Write the failing smoke test**

```gdscript
extends SceneTree

const EncounterDirectorScript := preload("res://scripts/game/EncounterDirector.gd")

func _initialize() -> void:
	var director := EncounterDirectorScript.new()
	var event_data: Dictionary = director.build_event(4, false)
	print(str(event_data.get("title", "")))
	quit(0)
```

- [ ] **Step 2: Run the smoke test and confirm it fails before implementation**

Run:

```bash
"/Applications/Godot.app/Contents/MacOS/Godot" --headless --path /Users/mac/Documents/Codex/2026-06-28/wo/Survivor2D --script res://scripts/tests/event_system_smoke.gd
```

Expected: parse/load failure because `EncounterDirector.gd` does not exist yet.

- [ ] **Step 3: Implement the encounter director and expand wave events**

Create `data/encounters.json` with encounter definitions for:

- `blessing`
- `bounty`
- `trade`
- `altar`
- `shop`

Create `scripts/game/EncounterDirector.gd` with these responsibilities:

- load the encounter table from `data/encounters.json`
- build an encounter for the current wave and major/minor wave flag
- expose `build_event(wave: int, is_major: bool) -> Dictionary`
- expose `resolve_choice(event_id: String) -> Dictionary`

Wire `RunEventSystem.gd` to use the director for event selection while keeping the current blessing/expiry bookkeeping there. Update `game.gd` so the pause/show-hud flow stays in one place, but the event content comes from the director.

- [ ] **Step 4: Run the smoke test and the project headless**

Run:

```bash
"/Applications/Godot.app/Contents/MacOS/Godot" --headless --path /Users/mac/Documents/Codex/2026-06-28/wo/Survivor2D --script res://scripts/tests/event_system_smoke.gd
"/Applications/Godot.app/Contents/MacOS/Godot" --headless --path /Users/mac/Documents/Codex/2026-06-28/wo/Survivor2D --quit
```

Expected: the smoke test prints an encounter title and exits 0; the project headless run exits 0 with the existing unrelated UID warning only.

- [ ] **Step 5: Commit**

```bash
git add data/encounters.json scripts/game/EncounterDirector.gd scripts/tests/event_system_smoke.gd scripts/game/RunEventSystem.gd scripts/game/game.gd scripts/ui/hud.gd
git commit -m "feat: expand wave encounters"
```

### Task 3: Verification

**Files:**
- None

- [ ] **Step 1: Run all smoke tests**

Run:

```bash
"/Applications/Godot.app/Contents/MacOS/Godot" --headless --path /Users/mac/Documents/Codex/2026-06-28/wo/Survivor2D --script res://scripts/tests/combat_feedback_smoke.gd
"/Applications/Godot.app/Contents/MacOS/Godot" --headless --path /Users/mac/Documents/Codex/2026-06-28/wo/Survivor2D --script res://scripts/tests/event_system_smoke.gd
"/Applications/Godot.app/Contents/MacOS/Godot" --headless --path /Users/mac/Documents/Codex/2026-06-28/wo/Survivor2D --script res://scripts/tests/rearchitecture_smoke.gd
```

Expected: all three exit 0.

- [ ] **Step 2: Run the full headless parse check**

Run:

```bash
"/Applications/Godot.app/Contents/MacOS/Godot" --headless --path /Users/mac/Documents/Codex/2026-06-28/wo/Survivor2D --quit
```

Expected: exit 0 with only the pre-existing `invalid UID` warning.

