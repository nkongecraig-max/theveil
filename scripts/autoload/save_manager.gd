extends Node

## SaveManager - Handles save/load to device storage.
## Uses JSON files in user:// (app's private storage on mobile).

const SAVE_PATH = "user://save_data.json"

func save_game() -> void:
	var data = GameManager.get_save_data()
	data["save_timestamp"] = Time.get_unix_time_from_system()
	data["save_version"] = 1

	var file = FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if file:
		file.store_string(JSON.stringify(data, "\t"))
		file.close()
		print("[SaveManager] Game saved successfully")
	else:
		push_error("[SaveManager] Failed to save game")

func load_game() -> bool:
	if not FileAccess.file_exists(SAVE_PATH):
		print("[SaveManager] No save file found")
		return false

	var file = FileAccess.open(SAVE_PATH, FileAccess.READ)
	if not file:
		push_error("[SaveManager] Failed to open save file")
		return false

	var json = JSON.new()
	var parse_result = json.parse(file.get_as_text())
	file.close()

	if parse_result != OK:
		push_error("[SaveManager] Failed to parse save file")
		return false

	var data = json.data
	if data is Dictionary:
		GameManager.load_save_data(data)
		print("[SaveManager] Game loaded successfully")
		return true

	return false

func has_save() -> bool:
	return FileAccess.file_exists(SAVE_PATH)

func delete_save() -> void:
	if FileAccess.file_exists(SAVE_PATH):
		DirAccess.remove_absolute(SAVE_PATH)
		print("[SaveManager] Save deleted")
