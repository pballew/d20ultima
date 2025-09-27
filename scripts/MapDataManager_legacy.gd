class_name MapDataManagerLegacy
extends RefCounted

# Manager for saving and loading map section data to persistent files
const SAVE_PATH = "user://map_data/"
const FILE_EXTENSION = ".dat"

# Structure for individual map section data
class MapSectionData:
	var section_id: Vector2i
	var terrain_data: Dictionary = {}  # Key: Vector2i local_pos, Value: int terrain_type
	var generation_seed: int = 0
	var generation_timestamp: int = 0
	var map_width: int = 25
	var map_height: int = 20
	
	func _init(id: Vector2i):
		section_id = id
		generation_timestamp = Time.get_unix_time_from_system()
	
	func to_dict() -> Dictionary:
		return {
			"section_id": {"x": section_id.x, "y": section_id.y},
			"terrain_data": serialize_terrain_data(),
			"generation_seed": generation_seed,
			"generation_timestamp": generation_timestamp,
			"map_width": map_width,
			"map_height": map_height
		}
	
	func from_dict(data: Dictionary):
		section_id = Vector2i(data.section_id.x, data.section_id.y)
		deserialize_terrain_data(data.terrain_data)
		generation_seed = data.get("generation_seed", 0)
		generation_timestamp = data.get("generation_timestamp", 0)
		map_width = data.get("map_width", 25)
		map_height = data.get("map_height", 20)
	
	func serialize_terrain_data() -> Dictionary:
		var serialized = {}
		for pos in terrain_data.keys():
			var key = str(pos.x) + "," + str(pos.y)
			serialized[key] = terrain_data[pos]
		return serialized
	
	func deserialize_terrain_data(serialized: Dictionary):
		terrain_data.clear()
		for key in serialized.keys():
			var coords = key.split(",")
			var pos = Vector2i(int(coords[0]), int(coords[1]))
			terrain_data[pos] = serialized[key]

# Singleton instance
# No singleton needed - use instances

func _init():
	# Ensure save directory exists
	if not DirAccess.dir_exists_absolute(SAVE_PATH):
		DirAccess.open("user://").make_dir_recursive("map_data")

# Save a map section to file
func save_section(section_data: MapSectionData) -> bool:
	var file_path = get_section_file_path(section_data.section_id)
	var file = FileAccess.open(file_path, FileAccess.WRITE)
	
	if not file:
		print("Failed to open file for writing: ", file_path)
		return false
	
	var data_dict = section_data.to_dict()
	var json_string = JSON.stringify(data_dict)
	file.store_string(json_string)
	file.close()
	
	print("Saved map section ", section_data.section_id, " to ", file_path)
	return true

# Load a map section from file
func load_section(section_id: Vector2i) -> MapSectionData:
	var file_path = get_section_file_path(section_id)
	
	if not FileAccess.file_exists(file_path):
		print("No saved data found for section ", section_id)
		return null
	
	var file = FileAccess.open(file_path, FileAccess.READ)
	if not file:
		print("Failed to open file for reading: ", file_path)
		return null
	
	var json_string = file.get_as_text()
	file.close()
	
	var json = JSON.new()
	var parse_result = json.parse(json_string)
	
	if parse_result != OK:
		print("Failed to parse JSON for section ", section_id)
		return null
	
	var section_data = MapSectionData.new(section_id)
	section_data.from_dict(json.data)
	
	print("Loaded map section ", section_id, " from ", file_path)
	return section_data

# Check if a section exists on disk
func section_exists(section_id: Vector2i) -> bool:
	var file_path = get_section_file_path(section_id)
	return FileAccess.file_exists(file_path)

# Delete a section file
func delete_section(section_id: Vector2i) -> bool:
	var file_path = get_section_file_path(section_id)
	if FileAccess.file_exists(file_path):
		var dir = DirAccess.open("user://")
		if dir.remove(file_path.trim_prefix("user://")) == OK:
			print("Deleted map section ", section_id)
			return true
	return false

# Get list of all saved sections
func get_saved_sections() -> Array[Vector2i]:
	var sections: Array[Vector2i] = []
	var dir = DirAccess.open(SAVE_PATH)
	
	if not dir:
		return sections
	
	dir.list_dir_begin()
	var file_name = dir.get_next()
	
	while file_name != "":
		if file_name.ends_with(FILE_EXTENSION):
			var section_id = parse_section_id_from_filename(file_name)
			if section_id != Vector2i.ZERO or file_name.begins_with("section_0_0"):
				sections.append(section_id)
		file_name = dir.get_next()
	
	return sections

# Clear all saved map data
func clear_all_sections() -> bool:
	var dir = DirAccess.open(SAVE_PATH)
	if not dir:
		return false
	
	var sections = get_saved_sections()
	var success = true
	
	for section_id in sections:
		if not delete_section(section_id):
			success = false
	
	print("Cleared ", sections.size(), " map sections")
	return success

# Helper functions
func get_section_file_path(section_id: Vector2i) -> String:
	return SAVE_PATH + "section_" + str(section_id.x) + "_" + str(section_id.y) + FILE_EXTENSION

func parse_section_id_from_filename(filename: String) -> Vector2i:
	# Parse "section_X_Y.dat" format
	var base_name = filename.trim_suffix(FILE_EXTENSION)
	var parts = base_name.split("_")
	
	if parts.size() >= 3 and parts[0] == "section":
		var x = int(parts[1])
		var y = int(parts[2])
		return Vector2i(x, y)
	
	return Vector2i.ZERO

# Convert terrain data from EnhancedTerrain format to MapSectionData format
func create_section_data_from_terrain(section_id: Vector2i, terrain_dict: Dictionary, seed: int = 0) -> MapSectionData:
	var section_data = MapSectionData.new(section_id)
	section_data.terrain_data = terrain_dict.duplicate()
	section_data.generation_seed = seed
	return section_data

# Get statistics about saved map data
func get_save_statistics() -> Dictionary:
	var sections = get_saved_sections()
	var total_size = 0
	
	for section_id in sections:
		var file_path = get_section_file_path(section_id)
		var file = FileAccess.open(file_path, FileAccess.READ)
		if file:
			total_size += file.get_length()
			file.close()
	
	return {
		"total_sections": sections.size(),
		"total_size_bytes": total_size,
		"save_path": SAVE_PATH
	}