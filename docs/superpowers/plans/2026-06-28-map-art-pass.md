# Map Art Pass Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Make the arena look like a dark sacrificial battlefield instead of a simple grid.

**Architecture:** Keep static art in `scripts/game/arena.gd`; add animated low-cost decor in `scripts/game/map_decor.gd`; wire `MapDecor` into `scenes/main/Main.tscn` above the arena and below gameplay objects.

**Tech Stack:** Godot 4.7, GDScript, procedural 2D drawing.

---

## Tasks
- [ ] Add static rock, cracks, blood, bones, rune, altar, and edge fog layers to `arena.gd`.
- [ ] Create `map_decor.gd` for animated fog wisps, soul flames, and rune pulses.
- [ ] Add a `MapDecor` node to `Main.tscn`.
- [ ] Run Godot headless parse and runtime smoke test.
