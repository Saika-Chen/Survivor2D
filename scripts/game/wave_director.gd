extends Node

const WAVE_CONFIG_PATH := "res://data/waves.json"

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
var wave_config: WaveConfig = WaveConfig.new()

func _ready() -> void:
	_load_wave_config()

func reset() -> void:
	wave = 1
	time_left = wave_duration
	spawn_timer = wave_config.initial_spawn_timer
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

	# 如果还没达到本波目标，并且场上还有空位，就继续刷怪。
	if wave_spawned_total < wave_target_total and spawn_timer <= 0.0:
		var alive_cap := _current_alive_cap()
		if alive_enemies < alive_cap:
			var remaining_total := wave_target_total - wave_spawned_total
			var pack_size := _spawn_wave_pack(min(remaining_total, alive_cap - alive_enemies))
			wave_spawned_total += pack_size
			spawn_timer = wave_config.spawn_timer_for_wave(wave)

	# 本波结束：已经刷完且都清掉，或者时间到了就先保持当前状态。
	if wave_spawned_total >= wave_target_total:
		if alive_enemies <= 0:
			_advance_wave()
	elif time_left <= 0.0:
		# 时间到了但场上还有怪，就先等待它们被清掉。
		wave_changed.emit(wave, max_wave, 0.0)

func _advance_wave() -> void:
	wave += 1
	time_left = wave_duration
	wave_spawned_total = 0
	wave_target_total = _total_for_wave(wave)
	if wave % major_boss_interval == 0:
		spawn_requested.emit("bullet_boss", 1)
	if wave_config.has_wave_bonus_elite(wave):
		spawn_requested.emit("elite", 1)
	wave_changed.emit(wave, max_wave, time_left)

func _total_for_wave(w: int) -> int:
	return wave_config.total_for_wave(w)

func _spawn_wave_pack(max_to_spawn: int) -> int:
	if max_to_spawn <= 0:
		return 0
	var requests := wave_config.spawn_requests_for_wave(wave, max_to_spawn)
	var spawned := 0
	for request in requests:
		var archetype := str(request.get("archetype", ""))
		var count := int(request.get("count", 0))
		if archetype.is_empty() or count <= 0:
			continue
		spawn_requested.emit(archetype, count)
		spawned += count
	return spawned

func _current_alive_cap() -> int:
	return wave_config.current_alive_cap(wave, max_alive_enemies)

func _load_wave_config() -> void:
	wave_config = WaveConfig.load_from_file(WAVE_CONFIG_PATH)
	max_wave = wave_config.max_wave
	wave_duration = wave_config.wave_duration
	max_alive_enemies = wave_config.max_alive_enemies
	major_boss_interval = wave_config.major_boss_interval
	spawn_density_multiplier = wave_config.spawn_density_multiplier
