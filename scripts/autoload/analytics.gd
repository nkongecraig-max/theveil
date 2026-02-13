extends Node

## Analytics - Silent behavioral tracking.
## Collects player patterns during Act 1 (Sleeping Life) to build a behavioral
## profile that the AI companion uses in Act 3 (New World).
## No data leaves the device until the player explicitly opts into cloud features.

const ANALYTICS_PATH = "user://analytics.json"

# Player behavioral profile (built over time)
var profile: Dictionary = {
	"puzzle_style": {
		"avg_solve_time": 0.0,
		"attempts_before_solve": 0.0,
		"preferred_strategy": "unknown",  # "methodical", "experimental", "fast", "careful"
		"frustration_threshold": 0.0,
	},
	"social_style": {
		"npcs_talked_to": 0,
		"favorite_npc": "",
		"dialogue_choices": [],  # tracks choice patterns
	},
	"aesthetic_style": {
		"preferred_colors": [],
		"shop_layout_choices": [],
		"decoration_preferences": [],
	},
	"play_patterns": {
		"avg_session_length": 0.0,
		"sessions_count": 0,
		"most_active_time": "",
		"total_play_time": 0.0,
	},
}

# Event log (recent events, flushed to disk periodically)
var event_buffer: Array[Dictionary] = []
var _flush_timer: float = 0.0
const FLUSH_INTERVAL: float = 30.0  # Save every 30 seconds

func _ready() -> void:
	_load_profile()
	profile["play_patterns"]["sessions_count"] += 1
	print("[Analytics] Behavioral tracking active. Session #%d" % profile["play_patterns"]["sessions_count"])

func _process(delta: float) -> void:
	_flush_timer += delta
	if _flush_timer >= FLUSH_INTERVAL:
		_flush_timer = 0.0
		_flush_to_disk()

# -- Event Tracking --

func track_event(event_name: String, data: Dictionary = {}) -> void:
	var event = {
		"event": event_name,
		"timestamp": Time.get_unix_time_from_system(),
		"data": data,
	}
	event_buffer.append(event)

	# Update profile based on specific events
	match event_name:
		"puzzle_completed":
			_update_puzzle_profile(data)
		"npc_met", "dialogue_choice":
			_update_social_profile(event_name, data)
		"shop_decoration", "item_selected":
			_update_aesthetic_profile(data)

# -- Profile Updates --

func _update_puzzle_profile(data: Dictionary) -> void:
	var p = profile["puzzle_style"]
	if data.has("solve_time"):
		var count = float(profile["play_patterns"]["sessions_count"])
		p["avg_solve_time"] = (p["avg_solve_time"] * (count - 1) + data["solve_time"]) / count

func _update_social_profile(event_name: String, data: Dictionary) -> void:
	var s = profile["social_style"]
	if event_name == "npc_met":
		s["npcs_talked_to"] += 1
	if data.has("choice"):
		s["dialogue_choices"].append(data["choice"])
		# Keep only last 50 choices
		if s["dialogue_choices"].size() > 50:
			s["dialogue_choices"] = s["dialogue_choices"].slice(-50)

func _update_aesthetic_profile(data: Dictionary) -> void:
	if data.has("color"):
		profile["aesthetic_style"]["preferred_colors"].append(data["color"])

# -- Persistence --

func _flush_to_disk() -> void:
	if event_buffer.is_empty():
		return

	profile["play_patterns"]["total_play_time"] = GameManager.total_play_time

	var save_data = {
		"profile": profile,
		"recent_events": event_buffer.slice(-100),  # Keep last 100 events
	}

	var file = FileAccess.open(ANALYTICS_PATH, FileAccess.WRITE)
	if file:
		file.store_string(JSON.stringify(save_data, "\t"))
		file.close()

	event_buffer.clear()

func _load_profile() -> void:
	if not FileAccess.file_exists(ANALYTICS_PATH):
		return

	var file = FileAccess.open(ANALYTICS_PATH, FileAccess.READ)
	if not file:
		return

	var json = JSON.new()
	if json.parse(file.get_as_text()) == OK and json.data is Dictionary:
		if json.data.has("profile"):
			profile = json.data["profile"]
	file.close()

func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_CLOSE_REQUEST or what == NOTIFICATION_WM_GO_BACK_REQUEST:
		_flush_to_disk()

# -- AI Companion Interface (Act 3) --

func get_player_profile() -> Dictionary:
	return profile.duplicate(true)
