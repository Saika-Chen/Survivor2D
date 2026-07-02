# Contract System Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Add a mid-run contract layer that offers short-term objectives, tracks progress during combat, and pays out rewards or penalties cleanly at wave boundaries.

**Architecture:** Keep the existing `game.gd` orchestration and layer the contract flow into `RunEventSystem.gd` so the game loop still owns enemy deaths, XP, and wave timing. Put contract selection rules in a small data-driven director, store active contract state in one place, and surface progress through the existing HUD message channels instead of building a new modal UI.

**Tech Stack:** Godot 4.7, GDScript, JSON data files, headless `--script` smoke tests.

---

### Task 1: Contract Director and Smoke Test

**Files:**
- Create: `data/contracts.json`
- Create: `scripts/game/ContractDirector.gd`
- Create: `scripts/tests/contract_system_smoke.gd`

- [ ] **Step 1: Write the failing smoke test**

```gdscript
extends SceneTree

const ContractDirectorScript := preload("res://scripts/game/ContractDirector.gd")

func _initialize() -> void:
	var director := ContractDirectorScript.new()
	var offer: Dictionary = director.build_offer(6, false)
	print("%s|%s" % [str(offer.get("title", "")), str(offer.get("options", []).size())])
	quit(0)
```

- [ ] **Step 2: Run the smoke test and confirm it fails before implementation**

Run:

```bash
"/Applications/Godot.app/Contents/MacOS/Godot" --headless --path /Users/mac/Documents/Codex/2026-06-28/wo/Survivor2D --script res://scripts/tests/contract_progress_smoke.gd
```

Expected: parse/load failure because `ContractDirector.gd` does not exist yet.

- [ ] **Step 3: Implement the director and contract data**

Create `data/contracts.json` with three contract families:

- `hunt`: kill a target number of enemies within a limited wave window
- `elite_hunt`: kill a small number of elites or special enemies
- `scavenge`: collect a target amount of XP or pickups

Create `scripts/game/ContractDirector.gd` with these exact responsibilities:

```gdscript
extends RefCounted
class_name ContractDirector

const DEFAULT_PATH := "res://data/contracts.json"
var contracts: Dictionary = {}
var contract_ids: Array[String] = []

func build_offer(wave: int, is_major: bool) -> Dictionary:
	if wave < 6 or is_major or contract_ids.is_empty() or wave % 6 != 0:
		return {}
	var contract_id := contract_ids[wave / 6 % contract_ids.size()]
	var contract: Dictionary = contracts.get(contract_id, {})
	return {
		"id": contract_id,
		"title": str(contract.get("title", "")),
		"prompt": str(contract.get("prompt", "")),
		"options": [
			{"id": "contract:accept", "title": "接受契约"},
			{"id": "contract:decline", "title": "拒绝契约"}
		],
		"contract": contract.duplicate(true)
	}

func build_contract(contract_id: String, wave: int) -> Dictionary:
	var contract: Dictionary = contracts.get(contract_id, {}).duplicate(true)
	if contract.is_empty():
		return {}
	contract["wave"] = wave
	contract["duration_waves"] = int(contract.get("duration_waves", 2))
	return contract
```

The first implementation should:

- load the JSON table once in `_init()`
- only offer contracts on non-major waves, starting in the midgame
- return a dictionary with `id`, `title`, `prompt`, `options`, `contract`
- make the selected contract deterministic enough for smoke tests by keying it off the wave number

- [ ] **Step 4: Run the smoke test and confirm it passes**

Run:

```bash
"/Applications/Godot.app/Contents/MacOS/Godot" --headless --path /Users/mac/Documents/Codex/2026-06-28/wo/Survivor2D --script res://scripts/tests/contract_system_smoke.gd
```

Expected: the smoke test prints a contract title and exits 0.

- [ ] **Step 5: Commit**

```bash
git add data/contracts.json scripts/game/ContractDirector.gd scripts/tests/contract_system_smoke.gd
git commit -m "feat: add contract director"
```

### Task 2: Contract State Tracking

**Files:**
- Modify: `scripts/game/RunEventSystem.gd`
- Modify: `scripts/game/game.gd`
- Modify: `scripts/ui/hud.gd`
- Create: `scripts/tests/contract_progress_smoke.gd`

- [ ] **Step 1: Write the failing integration test**

```gdscript
extends SceneTree

const RunEventSystemScript := preload("res://scripts/game/RunEventSystem.gd")

func _initialize() -> void:
	var system := RunEventSystemScript.new()
	system.record_xp_gained(12)
	system.record_enemy_defeated("elite", "")
	print("%s|%s" % [str(system.has_method("record_xp_gained")), str(system.has_method("record_enemy_defeated"))])
	quit(0)
```

- [ ] **Step 2: Run the smoke test and confirm it fails before integration**

Run:

```bash
"/Applications/Godot.app/Contents/MacOS/Godot" --headless --path /Users/mac/Documents/Codex/2026-06-28/wo/Survivor2D --script res://scripts/tests/contract_system_smoke.gd
```

Expected: the test still fails until the new progress hooks exist on `RunEventSystem.gd`.

- [ ] **Step 3: Wire contract lifecycle into `RunEventSystem.gd`**

Add contract state to the existing event system instead of creating a second controller:

```gdscript
var contract_director
var active_contract := {}
var pending_contract_offer := {}
var contract_progress := 0
var contract_target := 0
var contract_expires_wave := -1

func maybe_offer_contract(wave: int, is_major: bool) -> void:
	if game.level_up_pending or game.victory_pending or not active_contract.is_empty():
		return
	var offer: Dictionary = contract_director.build_offer(wave, is_major)
	if offer.is_empty():
		return
	pending_contract_offer = offer
	game.level_up_pending = true
	game.get_tree().paused = true
	game.hud.show_level_up(offer.get("options", []), str(offer.get("title", "契约")), str(offer.get("prompt", "")), false)

func accept_contract(contract_id: String, wave: int) -> void:
	active_contract = contract_director.build_contract(contract_id, wave)
	contract_progress = 0
	contract_target = int(active_contract.get("target", 0))
	contract_expires_wave = wave + int(active_contract.get("duration_waves", 2)) - 1
	game.hud.hint.text = "契约生效：%s" % str(active_contract.get("title", "未知契约"))

func resolve_contract_choice(choice_id: String) -> void:
	if choice_id == "contract:accept":
		accept_contract(str(pending_contract_offer.get("id", "")), game.current_wave)
	elif choice_id == "contract:decline":
		game.hud.hint.text = "你拒绝了契约。"
	pending_contract_offer.clear()
	game.level_up_pending = false
	game.hud.hide_level_up()
	game.get_tree().paused = false
	game._update_hud()

func record_enemy_defeated(archetype: String, elite_variant: String) -> void:
	if active_contract.is_empty():
		return
	if str(active_contract.get("type", "")) == "hunt" and archetype != "boss":
		contract_progress += 1
	elif str(active_contract.get("type", "")) == "elite_hunt" and (elite_variant != "" or archetype == "elite"):
		contract_progress += 1
	_check_contract_completion()

func record_xp_gained(amount: int) -> void:
	if active_contract.is_empty():
		return
	if str(active_contract.get("type", "")) == "scavenge":
		contract_progress += amount
	_check_contract_completion()

func _check_contract_completion() -> void:
	if active_contract.is_empty() or contract_target <= 0 or contract_progress < contract_target:
		return
	game.hud.hint.text = "契约完成：%s" % str(active_contract.get("title", "未知契约"))
	active_contract.clear()
	pending_contract_offer.clear()
	contract_progress = 0
	contract_target = 0
	contract_expires_wave = -1

func expire_wave_effects() -> void:
	if not active_contract.is_empty() and game.current_wave > contract_expires_wave:
		game.hud.hint.text = "契约失效：%s" % str(active_contract.get("title", "未知契约"))
		active_contract.clear()
		contract_progress = 0
		contract_target = 0
		contract_expires_wave = -1
```

The contract rules should be:

- offer only when no active contract is running
- on accept, store the contract and reset progress
- increment progress from enemy kills and XP gain through the existing `game.gd` hooks
- complete the contract when the target is met and grant a reward through `game.hud.hint.text`
- expire an incomplete contract when its wave window ends

Update `game.gd` to forward these hooks:

- call `run_event_system.maybe_offer_contract(wave, is_major)` from `_on_wave_changed()`
- call `run_event_system.record_enemy_defeated(archetype, elite_variant)` when an enemy dies
- call `run_event_system.record_xp_gained(amount)` in `_gain_experience()`
- call `run_event_system.resolve_contract_choice(upgrade_id)` from `_on_upgrade_selected()` when the HUD emits a contract option id

Update `hud.gd` only as needed to keep the active contract text readable in the same style as the other status banners. The smallest acceptable change is a helper that formats a compact status string and appends it to the existing `hint` line when a contract is active, so no new overlay is required.

- [ ] **Step 4: Run the integration smoke test and the project headless**

Run:

```bash
"/Applications/Godot.app/Contents/MacOS/Godot" --headless --path /Users/mac/Documents/Codex/2026-06-28/wo/Survivor2D --script res://scripts/tests/contract_system_smoke.gd
"/Applications/Godot.app/Contents/MacOS/Godot" --headless --path /Users/mac/Documents/Codex/2026-06-28/wo/Survivor2D --script res://scripts/tests/contract_progress_smoke.gd
"/Applications/Godot.app/Contents/MacOS/Godot" --headless --path /Users/mac/Documents/Codex/2026-06-28/wo/Survivor2D --quit
```

Expected: both smoke tests exit 0 and the project headless run exits 0 with the existing unrelated `invalid UID` warning only.

- [ ] **Step 5: Commit**

```bash
git add scripts/game/RunEventSystem.gd scripts/game/game.gd scripts/ui/hud.gd scripts/tests/contract_progress_smoke.gd
git commit -m "feat: track contract progress"
```

### Task 3: Verification

**Files:**
- None

- [ ] **Step 1: Run all gameplay smoke tests**

Run:

```bash
"/Applications/Godot.app/Contents/MacOS/Godot" --headless --path /Users/mac/Documents/Codex/2026-06-28/wo/Survivor2D --script res://scripts/tests/combat_feedback_smoke.gd
"/Applications/Godot.app/Contents/MacOS/Godot" --headless --path /Users/mac/Documents/Codex/2026-06-28/wo/Survivor2D --script res://scripts/tests/event_system_smoke.gd
"/Applications/Godot.app/Contents/MacOS/Godot" --headless --path /Users/mac/Documents/Codex/2026-06-28/wo/Survivor2D --script res://scripts/tests/wave_mutation_smoke.gd
"/Applications/Godot.app/Contents/MacOS/Godot" --headless --path /Users/mac/Documents/Codex/2026-06-28/wo/Survivor2D --script res://scripts/tests/contract_system_smoke.gd
"/Applications/Godot.app/Contents/MacOS/Godot" --headless --path /Users/mac/Documents/Codex/2026-06-28/wo/Survivor2D --script res://scripts/tests/contract_progress_smoke.gd
```

Expected: all five exit 0.

- [ ] **Step 2: Run the full headless parse check**

Run:

```bash
"/Applications/Godot.app/Contents/MacOS/Godot" --headless --path /Users/mac/Documents/Codex/2026-06-28/wo/Survivor2D --quit
```

Expected: exit 0 with only the pre-existing `invalid UID` warning.
