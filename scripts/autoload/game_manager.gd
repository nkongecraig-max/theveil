extends Node

## GameManager - The nervous system of The Veil
## Holds global game state, coordinates between systems, manages scene transitions.

signal scene_changed(scene_name: String)
signal day_advanced(day_number: int)
signal game_state_changed(key: String, value: Variant)
signal daily_reward_available(streak: int, coins: int)

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

# Daily reward system
var last_reward_date: String = ""  # "YYYY-MM-DD"
var daily_streak: int = 0

# Best-day stats
var best_day_coins: int = 0
var best_day_served: int = 0
var best_day_number: int = 0

func _ready() -> void:
	session_start_time = Time.get_unix_time_from_system()
	process_mode = Node.PROCESS_MODE_ALWAYS
	print("[GameManager] The Veil initialized. Phase: SLEEPING_LIFE")

func _process(_delta: float) -> void:
	total_play_time = Time.get_unix_time_from_system() - session_start_time

func _notification(what: int) -> void:
	if what == NOTIFICATION_APPLICATION_FOCUS_OUT:
		# App going to background — auto-save and pause
		get_tree().paused = true
		SaveManager.save_game()
		Analytics.track_event("app_backgrounded", {})
	elif what == NOTIFICATION_APPLICATION_FOCUS_IN:
		# App returning — resume
		get_tree().paused = false
		Analytics.track_event("app_resumed", {})
	elif what == NOTIFICATION_WM_CLOSE_REQUEST or what == NOTIFICATION_WM_GO_BACK_REQUEST:
		SaveManager.save_game()

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
	var new_level = 1 + (puzzles_completed / 3)
	if new_level > player_level:
		player_level = new_level
		game_state_changed.emit("player_level", player_level)
		Analytics.track_event("level_up", {"level": player_level})
		AudioManager.play("level_up")
		_check_phase_transition()

func _check_phase_transition() -> void:
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

func record_day_stats(coins_earned: int, customers_served: int) -> void:
	if coins_earned > best_day_coins:
		best_day_coins = coins_earned
		best_day_number = current_day
	if customers_served > best_day_served:
		best_day_served = customers_served

# -- Daily Reward System --

func check_daily_reward() -> void:
	var today = _get_today_str()
	if today == last_reward_date:
		return
	var yesterday = _get_yesterday_str()
	if last_reward_date == yesterday:
		daily_streak += 1
	else:
		daily_streak = 1
	last_reward_date = today
	var reward = mini(daily_streak * 5, 25)
	add_coins(reward)
	daily_reward_available.emit(daily_streak, reward)
	AudioManager.play("daily_reward")
	Analytics.track_event("daily_reward", {"streak": daily_streak, "coins": reward})

func _get_today_str() -> String:
	var dt = Time.get_datetime_dict_from_system()
	return "%04d-%02d-%02d" % [dt["year"], dt["month"], dt["day"]]

func _get_yesterday_str() -> String:
	var unix = Time.get_unix_time_from_system() - 86400
	var dt = Time.get_datetime_dict_from_unix_time(int(unix))
	return "%04d-%02d-%02d" % [dt["year"], dt["month"], dt["day"]]

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
		"last_reward_date": last_reward_date,
		"daily_streak": daily_streak,
		"best_day_coins": best_day_coins,
		"best_day_served": best_day_served,
		"best_day_number": best_day_number,
	}

func load_save_data(data: Dictionary) -> void:
	for key in data:
		if key in self:
			if key in ["npcs_met", "items_collected", "shop_upgrades"]:
				var typed_arr: Array[String] = []
				for v in data[key]:
					typed_arr.append(str(v))
				set(key, typed_arr)
			else:
				set(key, data[key])
	print("[GameManager] Save data loaded. Day %d, Level %d" % [current_day, player_level])
