extends Node

var _players: Array[AudioStreamPlayer] = []
var _player_index := 0
var _stream_cache := {}
var _last_play_times := {}

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	var pool_size := 6 if OS.has_feature("mobile") else 8
	for index in range(pool_size):
		var player := AudioStreamPlayer.new()
		player.bus = "Master"
		add_child(player)
		_players.append(player)

func play_weapon(weapon_family: String) -> void:
	match weapon_family:
		"projectile":
			_play("weapon_projectile", 0.045, 0.82, 880.0, 0.14, 0.0, -12.0)
		"laser":
			_play("weapon_laser", 0.06, 0.75, 1320.0, 0.08, 0.0, -13.0)
		"burst":
			_play("weapon_burst", 0.08, 0.72, 240.0, 0.55, 0.35, -11.0)
		"orbit":
			_play("weapon_orbit", 0.05, 0.7, 560.0, 0.22, 0.0, -14.0)
		"summon":
			_play("weapon_summon", 0.05, 0.76, 460.0, 0.18, 0.0, -13.5)

func play_enemy_death(archetype: String) -> void:
	if archetype == "boss":
		_play("death_boss", 0.18, 0.88, 120.0, 0.5, 0.55, -7.5)
	elif archetype == "elite":
		_play("death_elite", 0.1, 0.78, 190.0, 0.45, 0.35, -9.5)
	else:
		_play("death_normal", 0.05, 0.68, 220.0, 0.36, 0.22, -12.5)

func play_ui(kind: String) -> void:
	match kind:
		"wave":
			_play("ui_wave", 0.07, 0.66, 520.0, 0.12, 0.0, -14.0)
		"boss_wave":
			_play("ui_boss_wave", 0.13, 0.78, 320.0, 0.20, 0.12, -10.0)
		"jackpot":
			_play("ui_jackpot", 0.09, 0.84, 980.0, 0.14, 0.0, -10.5)
		"jackpot_step":
			_play("ui_jackpot_step", 0.045, 0.74, 1180.0, 0.1, 0.0, -13.5)

func _play(sound_id: String, duration: float, amplitude: float, frequency: float, square_mix: float, noise_mix: float, volume_db: float) -> void:
	var now := Time.get_ticks_msec()
	var min_gap := 32
	if sound_id.contains("death"):
		min_gap = 22
	elif sound_id.contains("weapon"):
		min_gap = 40
	elif sound_id.contains("jackpot_step"):
		min_gap = 28
	var last_time := int(_last_play_times.get(sound_id, -10000))
	if now - last_time < min_gap:
		return
	_last_play_times[sound_id] = now

	var key := "%s_%.3f_%.3f_%.1f_%.2f_%.2f" % [sound_id, duration, amplitude, frequency, square_mix, noise_mix]
	var stream: AudioStreamWAV = _stream_cache.get(key)
	if stream == null:
		stream = _build_tone(duration, amplitude, frequency, square_mix, noise_mix)
		_stream_cache[key] = stream

	var player := _players[_player_index]
	_player_index = (_player_index + 1) % _players.size()
	player.stop()
	player.stream = stream
	player.volume_db = volume_db
	player.pitch_scale = 1.0 + randf_range(-0.04, 0.04)
	player.play()

func _build_tone(duration: float, amplitude: float, frequency: float, square_mix: float, noise_mix: float) -> AudioStreamWAV:
	var sample_rate: int = 22050
	var sample_count: int = maxi(1, int(duration * sample_rate))
	var bytes := PackedByteArray()
	bytes.resize(sample_count * 2)
	for index in range(sample_count):
		var t := float(index) / float(sample_rate)
		var envelope := sin(min(1.0, t / duration) * PI)
		var sine := sin(TAU * frequency * t)
		var square: float = sign(sine)
		var noise: float = randf_range(-1.0, 1.0)
		var sample: float = (sine * (1.0 - square_mix) + square * square_mix) * (1.0 - noise_mix) + noise * noise_mix
		sample *= amplitude * envelope
		var pcm := int(clampi(int(sample * 32767.0), -32767, 32767))
		var offset := index * 2
		bytes[offset] = pcm & 0xFF
		bytes[offset + 1] = (pcm >> 8) & 0xFF
	var stream: AudioStreamWAV = AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_16_BITS
	stream.mix_rate = sample_rate
	stream.stereo = false
	stream.data = bytes
	return stream
