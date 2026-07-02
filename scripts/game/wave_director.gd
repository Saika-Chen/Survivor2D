extends Node

signal spawn_requested(archetype: String, count: int)
signal wave_changed(wave: int, max_wave: int, time_left: float)
signal boss_wave_started

@export var max_wave := 30
@export var wave_duration := 16.0
@export var max_alive_enemies := 135

var wave := 1
var time_left := wave_duration
var spawn_timer := 0.0
var boss_started := false
var active := true

func reset() -> void:
	wave = 1
	time_left = wave_duration
	spawn_timer = 0.2
	boss_started = false
	active = true
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

	time_left -= delta
	spawn_timer -= delta
	if spawn_timer <= 0.0:
		var alive_cap := _current_alive_cap()
		if alive_enemies < alive_cap:
			_spawn_wave_pack(alive_enemies)
		var mobile_slowdown := 0.08 if OS.has_feature("mobile") else 0.0
		var min_spawn_timer := 0.12 if OS.has_feature("mobile") else 0.075
		spawn_timer = max(min_spawn_timer, 0.68 - float(wave) * 0.024 + mobile_slowdown)

	if time_left <= 0.0:
		wave += 1
		time_left = wave_duration
		if wave == 10 or wave == 20:
			spawn_requested.emit("elite", 1)
		wave_changed.emit(wave, max_wave, time_left)
	else:
		wave_changed.emit(wave, max_wave, time_left)

func _spawn_wave_pack(alive_enemies: int) -> void:
	var remaining_capacity: int = max(0, _current_alive_cap() - alive_enemies)
	if remaining_capacity <= 0:
		return
	var base_count := (3 if OS.has_feature("mobile") else 4) + wave / 2
	var bonus_count := wave / 6
	var count: int = min(base_count + bonus_count, remaining_capacity)
	spawn_requested.emit("chaser", count)
	if wave >= 2 and randi() % 100 < 46 + wave:
		spawn_requested.emit("shooter", 1 + wave / 14)
	if wave >= 3 and randi() % 100 < 32 + wave:
		spawn_requested.emit("charger", 1 + wave / 16)
	if wave >= 5 and randi() % 100 < 28 + wave / 2:
		spawn_requested.emit("buffer", 1 + wave / 18)
	if wave >= 6 and randi() % 100 < 24 + wave / 2:
		spawn_requested.emit("bomber", 1 + wave / 20)
	if wave >= 8 and randi() % 100 < 20 + wave / 2:
		spawn_requested.emit("splitter", 1 + wave / 18)
	if wave >= 11 and randi() % 100 < 16 + wave / 3:
		spawn_requested.emit("tank", 1 + wave / 24)
	if wave >= 16 and randi() % 100 < 20 + wave / 4:
		spawn_requested.emit("elite", 1 + wave / 26)

func _current_alive_cap() -> int:
	var growth := wave * (5 if OS.has_feature("mobile") else 7)
	return max_alive_enemies + growth
