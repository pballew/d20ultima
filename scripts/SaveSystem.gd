extends Node

const SAVE_PATH = "user://game_save.dat"
const CHARACTERS_PATH = "user://characters/"

func save_game_state(character_data: CharacterData):
	"""Save the current character data and mark them as the last played character"""
	# Ensure characters directory exists
	if not DirAccess.dir_exists_absolute(CHARACTERS_PATH):
		DirAccess.make_dir_recursive_absolute(CHARACTERS_PATH)
	
	# Save character data
	var character_save_path = CHARACTERS_PATH + character_data.character_name.to_lower().replace(" ", "_") + ".tres"
	var char_save_result = ResourceSaver.save(character_data, character_save_path)
	
	# Save game state (last played character info)
	var game_state = {
		"last_character_name": character_data.character_name,
		"last_character_file": character_save_path,
		"last_played_timestamp": Time.get_unix_time_from_system()
	}
	
	var file = FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if file:
		file.store_string(JSON.stringify(game_state))
		file.close()
		DebugLogger.info("Game state saved successfully!")
		return char_save_result == OK
	else:
		DebugLogger.error("Failed to save game state!")
		return false

func load_last_character() -> CharacterData:
	"""Load the last played character, returns null if none found"""
	if not FileAccess.file_exists(SAVE_PATH):
		DebugLogger.warn("No previous game state found")
		return null
	
	var file = FileAccess.open(SAVE_PATH, FileAccess.READ)
	if not file:
		DebugLogger.error("Failed to open game state file")
		return null
	
	var json_string = file.get_as_text()
	file.close()
	
	var json = JSON.new()
	var parse_result = json.parse(json_string)
	if parse_result != OK:
		DebugLogger.error("Failed to parse game state JSON")
		return null
	
	var game_state = json.data
	if not game_state.has("last_character_file"):
		DebugLogger.error("Invalid game state format")
		return null
	
	var character_file = game_state["last_character_file"]
	if not FileAccess.file_exists(character_file):
		DebugLogger.warn("Last character file not found: %s" % character_file)
		return null
	
	var character_data = load(character_file) as CharacterData
	if character_data:
		DebugLogger.info("Loaded last character: %s" % character_data.character_name)
		return character_data
	else:
		DebugLogger.error("Failed to load character data from: %s" % character_file)
		return null

func has_save_data() -> bool:
	"""Check if there's any saved game data"""
	return FileAccess.file_exists(SAVE_PATH)

func get_last_character_name() -> String:
	"""Get the name of the last played character without loading the full data"""
	if not FileAccess.file_exists(SAVE_PATH):
		return ""
	
	var file = FileAccess.open(SAVE_PATH, FileAccess.READ)
	if not file:
		return ""
	
	var json_string = file.get_as_text()
	file.close()
	
	var json = JSON.new()
	var parse_result = json.parse(json_string)
	if parse_result != OK:
		return ""
	
	var game_state = json.data
	return game_state.get("last_character_name", "")

func delete_all_characters():
	"""Delete all saved character data and game state"""
	DebugLogger.info("Deleting all saved characters...")
	
	var characters_deleted = 0
	
	# Delete characters directory and all character files
	if DirAccess.dir_exists_absolute(CHARACTERS_PATH):
		var dir = DirAccess.open(CHARACTERS_PATH)
		if dir:
			dir.list_dir_begin()
			var file_name = dir.get_next()
			while file_name != "":
				if file_name.ends_with(".tres"):
					DebugLogger.info("Deleting character file: %s" % file_name)
					dir.remove(file_name)
					characters_deleted += 1
				file_name = dir.get_next()
			dir.list_dir_end()
			
			# Try to remove the directory itself
			var parent_dir = DirAccess.open("user://")
			if parent_dir:
				parent_dir.remove("characters/")
	
	# Delete main save file
	if FileAccess.file_exists(SAVE_PATH):
		DebugLogger.info("Deleting main save file: %s" % SAVE_PATH)
		var dir = DirAccess.open("user://")
		if dir:
			dir.remove("game_save.dat")
	
	DebugLogger.info("Deleted %d character files and main save data" % characters_deleted)
	return characters_deleted
