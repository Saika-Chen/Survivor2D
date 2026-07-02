extends Node

signal spawn_requested(archetype: String, count: int)
signal wave_changed(wave: int, max_wave: int, time_left: float)
signal boss_wave_started

@export var max_wave := 50
@export var wave_duration := 32.0
@export var max_alive_enemies := 200
@export var major_boss_interval := 10
@export var spawn_density_multiplier := 2.25

var wave := 1
var time_left := wave_duration
var spawn_timer := 0.0
var boss_started := false
var active := true
var wave_spawned_total := 0
var wave_target_total := 40

func reset() -> void:
	wave = 1
	time_left = wave_duration
	spawn_timer = 0.2
	boss_started = false
	active = true
	wave_spawned_total = 0
	wave_target_total = _total_for_wave(1)
	wave_changed.emit(wave, max_wave, time_left)

func tick(delta: float, alive_enemies := 0) -> void:
	if not active:
		return
	if wave >= max_wave:
		if not boss_started:
			boss_started = true
			boss_wave_started.emit()
			spawn_requested.emit("boss", 1)
		wave_changed.emit(wave, max_wave, 0.0)
		return

	time_left = max(0.0, time_left - delta)
	spawn_timer -= delta

	# Spawn if we haven't hit the wave target AND there's room
	if wave_spawned_total < wave_target_total and spawn_timer <= 0.0:
		var alive_cap := _current_alive_cap()
		if alive_enemies < alive_cap:
			var remaining_total := wave_target_total - wave_spawned_total
			var pack_size := _spawn_wave_pack(min(remaining_total, alive_cap - alive_enemies))
			wave_spawned_total += pack_size
			var mobile_slowdown := 0.10 if OS.has_feature("mobile") else 0.02
			var min_spawn_timer := 0.12 if OS.has_feature("mobile") else 0.07
			spawn_timer = max(min_spawn_timer, (0.72 - float(wave) * 0.018) / spawn_density_multiplier + mobile_slowdown)

	# Wave ends: all spawned AND all killed (or timer ran out with what's left)
	if wave_spawned_total >= wave_target_total:
		if alive_enemies <= 0:
			_advance_wave()
	elif time_left <= 0.0:
		# Timer ran out but enemies remain - just wait
		wave_changed.emit(wave, max_wave, 0.0)

func _advance_wave() -> void:
	wave += 1
	time_left = wave_duration
	wave_spawned_total = 0
	wave_target_total = _total_for_wave(wave)
	if wave % major_boss_interval == 0:
		spawn_requested.emit("bullet_boss", 1)
	if wave == 10 or wave == 20:
		spawn_requested.emit("elite", 1)
	wave_changed.emit(wave, max_wave, time_left)

func _total_for_wave(w: int) -> int:
	return 40 + w * 24

func _spawn_wave_pack(max_to_spawn: int) -> int:
	if max_to_spawn <= 0:
		return 0
	var horde_multiplier := 1.8 if wave % 3 == 0 else 1.0
	var base_count := int(round(((3 if OS.has_feature("mobile") else 10) + wave) * spawn_density_multiplier * horde_multiplier))
	var bonus_count := int(round(float(wave / 10) * spawn_density_multiplier))
	var count: int = min(base_count + bonus_count, max_to_spawn)
	spawn_requested.emit("chaser", count)
	var spawned := count
	max_to_spawn -= count

	if max_to_spawn <= 0:
		return spawned

	if wave % 3 == 0:
		var charger_count: int = int(min(max_to_spawn, (3 + wave / 6) * 2))
		spawn_requested.emit("charger", charger_count)
		spawned += charger_count
		max_to_spawn -= charger_count
		var splitter_count: int = int(min(max_to_spawn, (2 + wave / 8) * 2))
		spawn_requested.emit("splitter", splitter_count)
		spawned += splitter_count
		return spawned

	if max_to_spawn > 0 and wave >= 2 and randi() % 100 < 28 + wave / 2:
		var c: int = int(min(max_to_spawn, (1 + wave / 14)) * 2)
		spawn_requested.emit("shooter", c); spawned += c; max_to_spawn -= c
	if max_to_spawn > 0 and wave >= 3 and randi() % 100 < 22 + wave / 2:
		var c: int = int(min(max_to_spawn, (1 + wave / 16)) * 2)
		spawn_requested.emit("charger", c); spawned += c; max_to_spawn -= c
	if max_to_spawn > 0 and wave >= 5 and randi() % 100 < 18 + wave / 3:
		var c: int = int(min(max_to_spawn, (1 + wave / 18)) * 2)
		spawn_requested.emit("buffer", c); spawned += c; max_to_spawn -= c
	if max_to_spawn > 0 and wave >= 6 and randi() % 100 < 16 + wave / 3:
		var c: int = int(min(max_to_spawn, (1 + wave / 20)) * 2)
		spawn_requested.emit("bomber", c); spawned += c; max_to_spawn -= c
	if max_to_spawn > 0 and wave >= 8 and randi() % 100 < 14 + wave / 3:
		var c: int = int(min(max_to_spawn, (1 + wave / 18)) * 2)
		spawn_requested.emit("splitter", c); spawned += c; max_to_spawn -= c
	if max_to_spawn > 0 and wave >= 11 and randi() % 100 < 12 + wave / 4:
		var c: int = int(min(max_to_spawn, (1 + wave / 24)) * 2)
		spawn_requested.emit("tank", c); spawned += c; max_to_spawn -= c
	if max_to_spawn > 0 and wave >= 16 and randi() % 100 < 10 + wave / 5:
		var c: int = int(min(max_to_spawn, (1 + wave / 26)) * 2)
		spawn_requested.emit("elite", c); spawned += c
	return spawned

func _current_alive_cap() -> int:
	var growth := int(round(float(wave * (5 if OS.has_feature("mobile") else 6)) * spawn_density_multiplier))
	return min(800, max_alive_enemies + growth)
