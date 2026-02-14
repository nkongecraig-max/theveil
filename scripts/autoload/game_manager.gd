extends Node

## GameManager - The nervous system of The Veil
## Holds global game state, coordinates between systems, manages scene transitions.

signal scene_changed(scene_name: String)
signal day_advanced(day_number: int)
signal game_state_changed(key: String, value: Variant)

enum GamePhase { SLEEPING_LIFE, THE_CRACKS, NEW_WORLD }

# Core state
var current_phase: GamePhase = GamePhase.SLEEPING_LIFE
var current_day: int = 1
var player_level: int = 1
var player_coins: int = 0
var player_name: String = ""

# Progression tracking
var puzzles_completed: int = 0
var npcs_met: Array[String] = []
var items_collected: Array[String] = []
var shop_upgrades: Array[String] = []

# Session tracking (for analytics and save)
var session_start_time: float = 0.0
var total_play_time: float = 0.0

func _ready() -> void:
	session_start_time = Time.get_unix_time_from_system()
	print("[GameManager] The Veil initialized. Phase: SLEEPING_LIFE")

func _process(_delta: float) -> void:
	total_play_time = Time.get_unix_time_from_system() - session_start_time

# -- State Management --

func set_state(key: String, value: Variant) -> void:
	if key in self:
		set(key, value)
		game_state_changed.emit(key, value)

func add_coins(amount: int) -> void:
	player_coins += amount
	game_state_changed.emit("player_coins", player_coins)

func spend_coins(amount: int) -> bool:
	if player_coins >= amount:
		player_coins -= amount
		game_state_changed.emit("player_coins", player_coins)
		return true
	return false

# -- Progression --

func complete_puzzle(puzzle_id: String) -> void:
	puzzles_completed += 1
	Analytics.track_event("puzzle_completed", {"puzzle_id": puzzle_id, "total": puzzles_completed})
	_check_level_up()

func meet_npc(npc_id: String) -> void:
	if npc_id not in npcs_met:
		npcs_met.append(npc_id)
		Analytics.track_event("npc_met", {"npc_id": npc_id})

func _check_level_up() -> void:
	# Simple level curve: every 3 puzzles = 1 level (will be tuned later)
	var new_level = 1 + (puzzles_completed / 3)
	if new_level > player_level:
		player_level = new_level
		game_state_changed.emit("player_level", player_level)
		Analytics.track_event("level_up", {"level": player_level})
		_check_phase_transition()

func _check_phase_transition() -> void:
	# Phase transitions at specific levels
	if current_phase == GamePhase.SLEEPING_LIFE and player_level >= 30:
		current_phase = GamePhase.THE_CRACKS
		scene_changed.emit("the_cracks_intro")
	elif current_phase == GamePhase.THE_CRACKS and player_level >= 50:
		current_phase = GamePhase.NEW_WORLD
		scene_changed.emit("new_world_intro")

# -- Day System --

func advance_day() -> void:
	current_day += 1
	day_advanced.emit(current_day)
	Analytics.track_event("day_advanced", {"day": current_day})

# -- Scene Transitions --

func go_to_scene(scene_path: String) -> void:
	get_tree().change_scene_to_file(scene_path)
	scene_changed.emit(scene_path)

# -- Save Data Export --

func get_save_data() -> Dictionary:
	return {
		"current_phase": current_phase,
		"current_day": current_day,
		"player_level": player_level,
		"player_coins": player_coins,
		"player_name": player_name,
		"puzzles_completed": puzzles_completed,
		"npcs_met": npcs_met,
		"items_collected": items_collected,
		"shop_upgrades": shop_upgrades,
		"total_play_time": total_play_time,
	}

func load_save_data(data: Dictionary) -> void:
	for key in data:
		if key in self:
			# Handle typed string arrays from JSON (which loads as untyped Array)
			if key in ["npcs_met", "items_collected", "shop_upgrades"]:
				var typed_arr: Array[String] = []
				for v in data[key]:
					typed_arr.append(str(v))
				set(key, typed_arr)
			else:
				set(key, data[key])
	print("[GameManager] Save data loaded. Day %d, Level %d" % [current_day, player_level])
