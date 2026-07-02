extends Node

signal xp_changed(experience: int, experience_to_next: int)
signal level_up_requested
signal wave_changed(wave: int, max_wave: int, time_left: float)
signal upgrade_selected(upgrade_id: String)
signal player_died
signal player_damaged(health: float)
