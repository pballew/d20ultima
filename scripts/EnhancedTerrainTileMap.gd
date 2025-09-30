class_name EnhancedTerrainTileMap
extends Node2D

# Enhanced terrain system using native Godot TileMap for better performance
# Maintains backward compatibility with existing save data

const TILE_SIZE = 32
const MAP_WIDTH = 25
const MAP_HEIGHT = 20

# Terrain types - must match the legacy system for save compatibility
enum TerrainType { 
	GRASS, DIRT, STONE, WATER, TREE, 
	MOUNTAIN, VALLEY, RIVER, LAKE, OCEAN,
	FOREST, HILLS, BEACH, SWAMP, TOWN
}

# TileMap-based map section structure
class TileMapSection:
	var section_id: Vector2i
	var tilemap: TileMap  # Native Godot TileMap node
	var terrain_data: Dictionary = {}  # Keep for save compatibility
	var town_data: Dictionary = {}    # Store town information
	
	func _init(id: Vector2i, tileset: TileSet):
		section_id = id
		# Create TileMap node
		tilemap = TileMap.new()
		if tileset:
			tilemap.tile_set = tileset
		tilemap.name = "Section_" + str(id.x) + "_" + str(id.y)

# Multi-map system variables
var map_sections: Dictionary = {}  # Key: Vector2i section_id, Value: TileMapSection
var current_sections: Array[Vector2i] = []

# Map data persistence
var map_data_manager
var current_world_seed: int

# Noise generators (same as legacy system)
var noise: FastNoiseLite
var elevation_noise: FastNoiseLite
var moisture_noise: FastNoiseLite

# TileSet resource
var terrain_tileset: TileSet
var terrain_atlas_texture: Texture2D = null

# Boundary markers for debugging
var boundary_markers: Array = []

func _ready():
	# FORCE REGENERATION: Create new bright TileSet for debugging
	DebugLogger.info("Forcing generation of new bright TileSet...")
	terrain_tileset = generate_terrain_tileset()
	# Save for future use
	ResourceSaver.save(terrain_tileset, "res://assets/debug_bright_tileset.tres")
	DebugLogger.info("Generated and saved new bright TileSet")
	
	if not terrain_tileset:
		DebugLogger.info("Error: Could not create terrain TileSet")
		return
	
	DebugLogger.info(str("TileSet created successfully - sources: ") + " " + str(terrain_tileset.get_source_count()))
	
	# Hide initially while generating
	visible = false
	
	# Initialize map data manager
	var MapDataManagerClass = load("res://scripts/MapDataManager.gd")
	map_data_manager = MapDataManagerClass.new()
	current_world_seed = randi()
	
	# Initialize noise generators (same as legacy)
	setup_noise_generators()
	
	DebugLogger.info("Starting terrain generation...")
	
	# Generate initial batch of sections to cover screen area
	var sections_to_generate = []
	
	# Generate sections from -1 to 2 (X) and -2 to 1 (Y) to cover 50x40 screen area
	for x in range(-1, 3):  # -1, 0, 1, 2
		for y in range(-2, 2):  # -2, -1, 0, 1
			var section_id = Vector2i(x, y)
			sections_to_generate.append(section_id)
	
	# Generate all sections
	for section_id in sections_to_generate:
		generate_map_section_data_only(section_id)
		create_tilemap_for_section(section_id)
	
	DebugLogger.info("Generated all initial sections")
	
	# add_boundary_markers()  # Disabled: remove section boundary overlays
	
	# Debug info
	print_debug_info()
	
	# Test coordinate conversions
	test_coordinate_conversions()
	
	DebugLogger.info("Terrain generation complete - now visible")
	visible = true

func setup_noise_generators():
	# Same noise setup as legacy system
	noise = FastNoiseLite.new()
	noise.seed = current_world_seed
	noise.frequency = 0.1
	noise.noise_type = FastNoiseLite.TYPE_PERLIN
	
	elevation_noise = FastNoiseLite.new()
	elevation_noise.seed = current_world_seed + 1000
	elevation_noise.frequency = 0.05
	elevation_noise.noise_type = FastNoiseLite.TYPE_SIMPLEX
	
	moisture_noise = FastNoiseLite.new()
	moisture_noise.seed = current_world_seed + 2000
	moisture_noise.frequency = 0.08
	moisture_noise.noise_type = FastNoiseLite.TYPE_CELLULAR

func generate_map_section_data_only(section_id: Vector2i):
	DebugLogger.info(str("Generating data for section: ") + " " + str(section_id))
	
	# Try to load existing data first
	var saved_data = map_data_manager.load_section(section_id)
	if saved_data:
		DebugLogger.info(str("Loaded existing data for section: ") + " " + str(section_id))
		restore_section_from_saved_data(section_id, saved_data)
		return
	
	# Generate new section if no saved data
	generate_fresh_section_data(section_id)
	save_section_data(section_id)

func restore_section_from_saved_data(section_id: Vector2i, saved_data):
	# Create section from saved data
	var section = TileMapSection.new(section_id, terrain_tileset)
	section.terrain_data = saved_data.terrain_data.duplicate()
	
	# Restore town data if it exists
	if saved_data.town_data.size() > 0:
		section.town_data = saved_data.town_data.duplicate()
		DebugLogger.info(str("Restored ") + " " + str(saved_data.town_data.size()), " towns for section ", section_id)
	else:
		DebugLogger.info(str("No towns found in saved data for section ") + " " + str(section_id) + " " + str(" - generating new towns"))
		# Generate towns for sections that don't have any
		map_sections[section_id] = section
		generate_towns_for_section(section_id)
		# Save the updated section with new towns
		save_section_data(section_id)
		return
	
	map_sections[section_id] = section
	current_sections.append(section_id)

func generate_fresh_section_data(section_id: Vector2i):
	DebugLogger.info(str("Generating new section: ") + " " + str(section_id))
	
	var section = TileMapSection.new(section_id, terrain_tileset)
	map_sections[section_id] = section
	current_sections.append(section_id)
	
	# Calculate global offset for this section
	var section_offset_x = section_id.x * MAP_WIDTH
	var section_offset_y = section_id.y * MAP_HEIGHT
	
	# Generate terrain data for this section
	for x in range(MAP_WIDTH):
		for y in range(MAP_HEIGHT):
			# Local coordinates within this section
			var local_x = x - MAP_WIDTH/2
			var local_y = y - MAP_HEIGHT/2
			
			# Global coordinates (noise sampling coordinates)
			var global_noise_x = x + section_offset_x
			var global_noise_y = y + section_offset_y
			
			# Sample noise using global coordinates for continuity
			var elevation = elevation_noise.get_noise_2d(global_noise_x, global_noise_y)
			var moisture = moisture_noise.get_noise_2d(global_noise_x, global_noise_y)
			var base_noise = noise.get_noise_2d(global_noise_x, global_noise_y)
			
			var terrain_type = determine_terrain_type(elevation, moisture, base_noise)
			
			# Store in section's terrain data
			var local_tile_pos = Vector2i(local_x, local_y)
			section.terrain_data[local_tile_pos] = terrain_type
	
	# Generate towns for this section
	generate_towns_for_section(section_id)
	
	# FORCE town regeneration for debugging (even on existing sections)
	DebugLogger.info(str("FORCING town generation for existing section: ") + " " + str(section_id))
	generate_towns_for_section(section_id)

func create_tilemap_for_section(section_id: Vector2i):
	if not map_sections.has(section_id):
		DebugLogger.info(str("Warning: Trying to create TileMap for non-existent section: ") + " " + str(section_id))
		return
	
	DebugLogger.info(str("Creating TileMap for section: ") + " " + str(section_id))
	var section = map_sections[section_id]
	
	# Calculate section position in world coordinates
	# Section (0,0) should be centered at world origin (0,0)
	var section_world_x = section_id.x * MAP_WIDTH * TILE_SIZE
	var section_world_y = section_id.y * MAP_HEIGHT * TILE_SIZE
	section.tilemap.position = Vector2(section_world_x, section_world_y)
	
	# Add TileMap to scene tree
	add_child(section.tilemap)
	
	# Ensure TileMap is visible and on correct layer
	section.tilemap.visible = true
	section.tilemap.z_index = 0  # Put terrain behind player (player is z_index 10)
	section.tilemap.modulate = Color.WHITE
	section.tilemap.y_sort_enabled = false
	
	DebugLogger.info(str("Created TileMap at position: ") + " " + str(section.tilemap.position) + " " + str(" for section ") + " " + str(section_id))
	
	# Populate the TileMap with terrain data using native tiles
	populate_native_tilemap(section_id)

func populate_native_tilemap(section_id: Vector2i):
	# Populate TileMap using native Godot tiles
	if not map_sections.has(section_id):
		return
	
	var section = map_sections[section_id]
	DebugLogger.info(str("Populating TileMap for section ") + " " + str(section_id) + " " + str(" with ") + " " + str(section.terrain_data.size()), " tiles")
	
	if not section.tilemap.tile_set:
		DebugLogger.error(str("ERROR: No TileSet assigned to TileMap for section ") + " " + str(section_id))
		return
	
	var tiles_placed = 0
	for local_pos in section.terrain_data:
		var terrain_type = int(section.terrain_data[local_pos])
		
		# Convert local position to TileMap coordinates
		var tilemap_coords = Vector2i(local_pos.x + MAP_WIDTH/2, local_pos.y + MAP_HEIGHT/2)
		
		# Calculate atlas coordinates based on terrain type (ensure integer division)
		var atlas_coords = Vector2i(terrain_type % 8, terrain_type / 8)
		
		# Set the tile in the TileMap using native tiles
		section.tilemap.set_cell(0, tilemap_coords, 0, atlas_coords)
		tiles_placed += 1
	
	DebugLogger.info(str("Placed ") + " " + str(tiles_placed) + " " + str(" tiles in section ") + " " + str(section_id))
	
	# DEBUG: Place bright test tiles with different colors
	var center_coords = Vector2i(MAP_WIDTH/2, MAP_HEIGHT/2)
	# Force different terrain types in a pattern
	section.tilemap.set_cell(0, center_coords, 0, Vector2i(0, 0))  # GRASS (green)
	section.tilemap.set_cell(0, center_coords + Vector2i(1, 0), 0, Vector2i(1, 0))  # DIRT (brown) 
	section.tilemap.set_cell(0, center_coords + Vector2i(0, 1), 0, Vector2i(3, 0))  # WATER (blue)
	section.tilemap.set_cell(0, center_coords + Vector2i(1, 1), 0, Vector2i(5, 0))  # MOUNTAIN (gray)
	DebugLogger.info(str("Placed debug color tiles at center of section ") + " " + str(section_id))

func get_terrain_color(terrain_type: int) -> Color:
	# Same color mapping as legacy system
	match terrain_type:
		TerrainType.GRASS:
			return Color.GREEN
		TerrainType.DIRT:
			return Color(0.6, 0.4, 0.2)  # Brown
		TerrainType.STONE:
			return Color.GRAY
		TerrainType.WATER:
			return Color.BLUE
		TerrainType.TREE:
			return Color.DARK_GREEN
		TerrainType.MOUNTAIN:
			return Color(0.5, 0.5, 0.5)  # Dark gray
		TerrainType.VALLEY:
			return Color(0.4, 0.8, 0.4)  # Light green
		TerrainType.RIVER:
			return Color(0.2, 0.6, 1.0)  # Light blue
		TerrainType.LAKE:
			return Color(0.1, 0.4, 0.8)  # Dark blue
		TerrainType.OCEAN:
			return Color(0.0, 0.3, 0.6)  # Very dark blue
		TerrainType.FOREST:
			return Color(0.1, 0.5, 0.1)  # Very dark green
		TerrainType.HILLS:
			return Color(0.7, 0.6, 0.4)  # Light brown
		TerrainType.BEACH:
			return Color(0.9, 0.9, 0.6)  # Sandy
		TerrainType.SWAMP:
			return Color(0.4, 0.6, 0.3)  # Muddy green
		_:
			return Color.MAGENTA  # Error color

func determine_terrain_type(elevation: float, moisture: float, base_noise: float) -> int:
	# Same terrain generation logic as legacy system
	var combined = elevation * 0.6 + moisture * 0.3 + base_noise * 0.1
	
	if elevation < -0.4:
		if moisture > 0.2:
			return TerrainType.OCEAN
		else:
			return TerrainType.LAKE
	elif elevation < -0.2:
		if moisture > 0.3:
			return TerrainType.WATER
		else:
			return TerrainType.RIVER
	elif elevation > 0.4:
		if moisture > 0.1:
			return TerrainType.MOUNTAIN
		else:
			return TerrainType.STONE
	elif elevation > 0.2:
		if moisture > 0.3:
			return TerrainType.FOREST
		elif moisture > 0.0:
			return TerrainType.HILLS
		else:
			return TerrainType.TREE
	elif moisture > 0.4:
		if elevation > -0.1:
			return TerrainType.SWAMP
		else:
			return TerrainType.WATER
	elif moisture < -0.3:
		return TerrainType.BEACH
	elif combined > 0.1:
		return TerrainType.GRASS
	else:
		return TerrainType.DIRT

func generate_towns_for_section(section_id: Vector2i):
	# Generate towns with 15-30 tile spacing
	var section = map_sections[section_id]
	var TownNameGen = load("res://scripts/TownNameGenerator.gd")
	
	# Create a deterministic RNG for this section
	var rng = RandomNumberGenerator.new()
	rng.seed = current_world_seed + section_id.x * 1000 + section_id.y
	
	# Try to place 1-2 towns per section, with spacing constraints
	var town_attempts = rng.randi_range(0, 2)  # 0-2 towns per section
	DebugLogger.info(str("Section ") + " " + str(section_id) + " " + str(" attempting to place ") + " " + str(town_attempts) + " " + str(" towns"))
	
	for attempt in range(town_attempts):
		# Random position within section
		var local_x = rng.randi_range(-MAP_WIDTH/2 + 2, MAP_WIDTH/2 - 2)
		var local_y = rng.randi_range(-MAP_HEIGHT/2 + 2, MAP_HEIGHT/2 - 2)
		var local_pos = Vector2i(local_x, local_y)
		var global_pos = world_to_global_tile(local_pos, section_id)
		
		# Check if this position is suitable for a town
		DebugLogger.info(str("Trying to place town at local_pos: ") + " " + str(local_pos) + " " + str(" global_pos: ") + " " + str(global_pos))
		if can_place_town_at_position(local_pos, section_id):
			DebugLogger.info("Position is suitable for town")
			# Check spacing from other towns
			if is_town_spacing_valid(global_pos):
				DebugLogger.info("Town spacing is valid")
				# Place the town
				section.terrain_data[local_pos] = TerrainType.TOWN
				
				# Generate town data and store it
				var town_data = TownNameGen.generate_town_data(global_pos, rng.seed + attempt)
				store_town_data(section_id, local_pos, town_data)
				
				DebugLogger.info(str("*** PLACED TOWN '") + " " + str(town_data.name) + " " + str("' at ") + " " + str(global_pos) + " " + str(" in section ") + " " + str(section_id) + " " + str(" ***"))
			else:
				DebugLogger.info(str("Town spacing invalid at ") + " " + str(global_pos))
		else:
			DebugLogger.info(str("Position not suitable for town at ") + " " + str(local_pos))

func can_place_town_at_position(local_pos: Vector2i, section_id: Vector2i) -> bool:
	DebugLogger.info(str("*** CAN_PLACE_TOWN_AT_POSITION CALLED FOR ") + " " + str(local_pos) + " " + str(" in section ") + " " + str(section_id) + " " + str(" ***"))
	
	# Towns can only be placed on suitable terrain types
	var section = map_sections[section_id]
	if not section.terrain_data.has(local_pos):
		DebugLogger.info(str("  ERROR: No terrain data at local_pos: ") + " " + str(local_pos))
		return false
	
	var terrain_type = section.terrain_data[local_pos]
	var terrain_name = TerrainType.keys()[terrain_type] if terrain_type < TerrainType.keys().size() else "UNKNOWN"
	DebugLogger.info(str("  Terrain type at ") + " " + str(local_pos) + " " + str(" is: ") + " " + str(terrain_type) + " " + str(" (") + " " + str(terrain_name) + " " + str("))")
	
	# For debugging: Allow towns on any terrain type except water/ocean
	var forbidden_types = [TerrainType.WATER, TerrainType.OCEAN, TerrainType.LAKE, TerrainType.RIVER]
	var is_suitable = terrain_type not in forbidden_types
	DebugLogger.info(str("  Is suitable: ") + " " + str(is_suitable) + " " + str(" (terrain ") + " " + str(terrain_type) + " " + str(" not in forbidden: ") + " " + str(forbidden_types) + " " + str("))")
	return is_suitable

func is_town_spacing_valid(global_pos: Vector2i) -> bool:
	# Check that no other towns are within 15 tiles
	var min_distance = 15
	
	# Check existing towns in nearby sections
	var search_radius = 2  # Check 2 sections in each direction
	var center_section = global_tile_to_section_and_local(global_pos)["section_id"]
	
	for x in range(-search_radius, search_radius + 1):
		for y in range(-search_radius, search_radius + 1):
			var check_section_id = center_section + Vector2i(x, y)
			if map_sections.has(check_section_id):
				var section = map_sections[check_section_id]
				for local_pos in section.terrain_data.keys():
					if section.terrain_data[local_pos] == TerrainType.TOWN:
						var existing_global_pos = world_to_global_tile(local_pos, check_section_id)
						var distance = global_pos.distance_to(existing_global_pos)
						if distance < min_distance:
							return false
	
	return true

func store_town_data(section_id: Vector2i, local_pos: Vector2i, town_data_dict: Dictionary):
	# Store town data in the section for persistence
	var section = map_sections[section_id]
	section.town_data[local_pos] = town_data_dict

func world_to_global_tile(local_pos: Vector2i, section_id: Vector2i) -> Vector2i:
	# Convert local section position to global tile coordinates
	var global_x = local_pos.x + section_id.x * MAP_WIDTH
	var global_y = local_pos.y + section_id.y * MAP_HEIGHT
	return Vector2i(global_x, global_y)

func global_tile_to_section_and_local(global_tile_pos: Vector2i) -> Dictionary:
	# Convert global tile position to section ID and local position
	var section_x = int(floor(float(global_tile_pos.x) / MAP_WIDTH))
	var section_y = int(floor(float(global_tile_pos.y) / MAP_HEIGHT))
	var section_id = Vector2i(section_x, section_y)
	
	var local_x = global_tile_pos.x - section_x * MAP_WIDTH
	var local_y = global_tile_pos.y - section_y * MAP_HEIGHT
	var local_pos = Vector2i(local_x, local_y)
	
	return {"section_id": section_id, "local_pos": local_pos}

func save_section_data(section_id: Vector2i):
	if not map_sections.has(section_id):
		return
	
	var section = map_sections[section_id]
	var section_data = map_data_manager.create_section_data_from_terrain(
		section_id, 
		section.terrain_data, 
		current_world_seed,
		section.town_data
	)
	map_data_manager.save_section(section_data)

# Coordinate conversion functions (compatible with legacy system)

func get_section_id_from_world_pos(world_pos: Vector2) -> Vector2i:
	var tile_x = int(world_pos.x / TILE_SIZE)
	var tile_y = int(world_pos.y / TILE_SIZE)
	return get_section_id_from_tile_pos(Vector2i(tile_x, tile_y))

func get_section_id_from_tile_pos(tile_pos: Vector2i) -> Vector2i:
	# Calculate which section this tile belongs to
	var section_x = 0
	var section_y = 0
	
	# Handle X coordinate
	if tile_pos.x >= 0:
		section_x = (tile_pos.x + MAP_WIDTH/2) / MAP_WIDTH
	else:
		section_x = (tile_pos.x - MAP_WIDTH/2 + 1) / MAP_WIDTH
	
	# Handle Y coordinate
	if tile_pos.y >= 0:
		section_y = (tile_pos.y + MAP_HEIGHT/2) / MAP_HEIGHT
	else:
		section_y = (tile_pos.y - MAP_HEIGHT/2 + 1) / MAP_HEIGHT
	
	return Vector2i(section_x, section_y)

func get_used_rect() -> Rect2i:
	# Calculate the used rectangle in tile coordinates for all loaded sections
	if map_sections.is_empty():
		return Rect2i(0, 0, 0, 0)
	
	var min_x = INF
	var min_y = INF
	var max_x = -INF
	var max_y = -INF
	
	for section_id in map_sections.keys():
		# Calculate world tile bounds for this section
		var section_tile_x = section_id.x * MAP_WIDTH - MAP_WIDTH / 2
		var section_tile_y = section_id.y * MAP_HEIGHT - MAP_HEIGHT / 2
		
		min_x = min(min_x, section_tile_x)
		min_y = min(min_y, section_tile_y)
		max_x = max(max_x, section_tile_x + MAP_WIDTH)
		max_y = max(max_y, section_tile_y + MAP_HEIGHT)
	
	return Rect2i(int(min_x), int(min_y), int(max_x - min_x), int(max_y - min_y))

func add_boundary_markers():
	# Add visual markers to show section boundaries (for debugging)
	boundary_markers.clear()
	
	for section_id in current_sections:
		var section_world_x = section_id.x * MAP_WIDTH * TILE_SIZE - (MAP_WIDTH * TILE_SIZE) / 2
		var section_world_y = section_id.y * MAP_HEIGHT * TILE_SIZE - (MAP_HEIGHT * TILE_SIZE) / 2
		
		var marker = ColorRect.new()
		marker.size = Vector2(MAP_WIDTH * TILE_SIZE, MAP_HEIGHT * TILE_SIZE)
		marker.position = Vector2(section_world_x, section_world_y)
		marker.color = Color(1, 0, 0, 0.2)  # Semi-transparent red
		marker.mouse_filter = Control.MOUSE_FILTER_IGNORE
		marker.z_index = 5  # Above terrain but below player
		
		add_child(marker)
		boundary_markers.append(marker)
		
		# Add section ID label
		var label = Label.new()
		label.text = "(" + str(section_id.x) + ", " + str(section_id.y) + ")"
		label.position = Vector2(section_world_x + 10, section_world_y + 10)
		label.add_theme_font_size_override("font_size", 12)
		label.z_index = 15  # Above everything for debugging
		add_child(label)
		boundary_markers.append(label)

func print_debug_info():
	DebugLogger.info("=== Multi-Map Debug Info ===")
	DebugLogger.info(str("Total sections loaded: ") + " " + str(map_sections.size()))
	DebugLogger.info(str("Sections: ") + " " + str(current_sections))
	
	# Calculate world bounds
	if current_sections.size() > 0:
		var min_x = current_sections[0].x
		var max_x = current_sections[0].x
		var min_y = current_sections[0].y
		var max_y = current_sections[0].y
		
		for section_id in current_sections:
			min_x = min(min_x, section_id.x)
			max_x = max(max_x, section_id.x)
			min_y = min(min_y, section_id.y)
			max_y = max(max_y, section_id.y)
		
		var world_min_tile_x = min_x * MAP_WIDTH - MAP_WIDTH/2
		var world_max_tile_x = (max_x + 1) * MAP_WIDTH - MAP_WIDTH/2 - 1
		var world_min_tile_y = min_y * MAP_HEIGHT - MAP_HEIGHT/2
		var world_max_tile_y = (max_y + 1) * MAP_HEIGHT - MAP_HEIGHT/2 - 1
		
		var world_size_x = world_max_tile_x - world_min_tile_x + 1
		var world_size_y = world_max_tile_y - world_min_tile_y + 1
		
		DebugLogger.info("World bounds (tiles): [P: (", world_min_tile_x, ", ", world_min_tile_y, "), S: (", world_size_x, ", ", world_size_y, ")]")
		DebugLogger.info("World bounds (pixels): (", world_min_tile_x * TILE_SIZE, ", ", world_min_tile_y * TILE_SIZE, ") to (", world_max_tile_x * TILE_SIZE, ", ", world_max_tile_y * TILE_SIZE, ")")
	
	DebugLogger.info("=============================")

func test_coordinate_conversions():
	DebugLogger.info("=== Testing Coordinate Conversions ===")
	
	# Test various tile positions
	var test_tiles = [
		Vector2i(0, 0),      # Center
		Vector2i(0, -20),    # Section boundary
		Vector2i(0, -21),    # Cross section boundary  
		Vector2i(0, -19),    # Near boundary
		Vector2i(-25, -20),  # Multiple section boundary
		Vector2i(25, -40)    # Far section
	]
	
	for tile in test_tiles:
		var section_data = global_tile_to_section_and_local(tile)
		var section_id = section_data["section_id"]
		var local_pos = section_data["local_pos"]
		var reconstructed = world_to_global_tile(local_pos, section_id)
		
		DebugLogger.info(str("Tile ") + " " + str(tile) + " " + str(" -> Section ") + " " + str(section_id) + " " + str(" Local ") + " " + str(local_pos) + " " + str(" -> Reconstructed ") + " " + str(reconstructed))
		
		if reconstructed != tile:
			DebugLogger.error("ERROR: Coordinate conversion mismatch!")
	
	DebugLogger.info("=== End Coordinate Tests ===")



# Map data management functions (compatible with legacy system)
func get_map_save_statistics() -> Dictionary:
	return map_data_manager.get_save_statistics()

func clear_all_saved_maps():
	map_data_manager.clear_all_sections()
	DebugLogger.info("Cleared all saved map data")

func get_saved_sections() -> Array[Vector2i]:
	return map_data_manager.get_saved_sections()

func force_save_current_sections():
	for section_id in current_sections:
		save_section_data(section_id)
	DebugLogger.info(str("Force saved ") + " " + str(current_sections.size()), " sections")

# Debug console commands (same as legacy)
func _input(event):
	if event is InputEventKey and event.pressed:
		if event.keycode == KEY_F1:
			var player = get_node("../Player")
			if player:
				debug_load_sections_around(player.global_position, 2)
		elif event.keycode == KEY_F2:
			DebugLogger.info("=== Map Data Statistics ===")
			DebugLogger.info(str("Sections in memory: ") + " " + str(map_sections.size()))
			DebugLogger.info(str("Current sections: ") + " " + str(current_sections.size()))
			var stats = get_map_save_statistics()
			DebugLogger.info(str("Save statistics: ") + " " + str(stats))
		elif event.keycode == KEY_F3:
			clear_all_saved_maps()
			# Clear in-memory sections and regenerate
			for section in map_sections.values():
				if section.tilemap:
					section.tilemap.queue_free()
			map_sections.clear()
			current_sections.clear()
			# Clear boundary markers
			for marker in boundary_markers:
				marker.queue_free()
			boundary_markers.clear()
			
			var player = get_node("../Player")
			if player:
				debug_load_sections_around(player.global_position, 2)

# TileSet generation (embedded version of TileSetGenerator)
func generate_terrain_tileset() -> TileSet:
	DebugLogger.info("Generating terrain TileSet with texture atlas...")
	
	# Reference to shared terrain colors
	var terrain_colors_resource = preload("res://scripts/TerrainColors.gd")
	var TERRAIN_COLORS = terrain_colors_resource.TERRAIN_COLORS
	
	# Create the TileSet resource
	var tileset = TileSet.new()
	tileset.tile_size = Vector2i(TILE_SIZE, TILE_SIZE)
	
	# Create atlas texture
	var atlas_texture = create_terrain_atlas(TERRAIN_COLORS)
	
	# Create TileSetAtlasSource
	var atlas_source = TileSetAtlasSource.new()
	atlas_source.texture = atlas_texture
	atlas_source.texture_region_size = Vector2i(TILE_SIZE, TILE_SIZE)
	
	# Add tiles to the atlas source (NO PHYSICS FOR NOW)
	for terrain_id in range(15):  # 15 terrain types including TOWN
		var atlas_coords = Vector2i(terrain_id % 8, terrain_id / 8)  # Arrange in 8x2 grid
		
		# Create the tile
		atlas_source.create_tile(atlas_coords)
		DebugLogger.info(str("Created tile for terrain ") + " " + str(terrain_id) + " " + str(" at atlas coords ") + " " + str(atlas_coords))
	
	# Add the atlas source to the tileset
	tileset.add_source(atlas_source, 0)

	# Keep a reference to the atlas texture so other systems can extract subregions
	terrain_atlas_texture = atlas_texture

	DebugLogger.info("TileSet generation complete!")
	return tileset


func get_tile_texture_at_world_pos(world_pos: Vector2) -> Texture2D:
	"""Return an AtlasTexture for the terrain tile at the given world position.
	Uses the same atlas layout created during tileset generation.
	Returns null if tile or atlas is not available."""
	if not terrain_atlas_texture:
		# Try to recover atlas from tileset sources if available
		if terrain_tileset and terrain_tileset.get_source_count() > 0:
			var src = terrain_tileset.get_source(0)
			if src and src.has_method("get_texture"):
				terrain_atlas_texture = src.get_texture()
		if not terrain_atlas_texture:
			return null

	# Convert world_pos to global tile coords
	var tile_x = int(floor(world_pos.x / TILE_SIZE))
	var tile_y = int(floor(world_pos.y / TILE_SIZE))
	var info = global_tile_to_section_and_local(Vector2i(tile_x, tile_y))
	var section_id: Vector2i = info["section_id"]
	var local_pos: Vector2i = info["local_pos"]

	if not map_sections.has(section_id):
		return null
	var section = map_sections[section_id]
	if not section.terrain_data.has(local_pos):
		return null

	var terrain_type = int(section.terrain_data[local_pos])
	# Atlas arranged in 8 columns as used during generation
	var atlas_x = terrain_type % 8
	var atlas_y = int(terrain_type / 8)

	var region = Rect2(atlas_x * TILE_SIZE, atlas_y * TILE_SIZE, TILE_SIZE, TILE_SIZE)
	var at = AtlasTexture.new()
	at.atlas = terrain_atlas_texture
	at.region = region
	return at

func create_terrain_atlas(terrain_colors: Dictionary) -> ImageTexture:
	# Use the detailed TileSetGenerator to create proper terrain patterns
	var tileset_generator = load("res://scripts/TileSetGenerator.gd").new()
	
	# Create a texture atlas using TileSetGenerator's detailed patterns
	var atlas_width = 8 * TILE_SIZE  # 8 tiles wide
	var atlas_height = 2 * TILE_SIZE  # 2 tiles high (for 15 terrain types)
	
	var image = Image.create(atlas_width, atlas_height, false, Image.FORMAT_RGBA8)
	image.fill(Color.MAGENTA)  # Default color for unused areas
	
	DebugLogger.info("Creating detailed terrain atlas with patterns...")
	
	# Generate each terrain tile using TileSetGenerator's pattern functions
	for terrain_id in range(15):
		var x = (terrain_id % 8) * TILE_SIZE
		var y = (terrain_id / 8) * TILE_SIZE
		var base_color = terrain_colors[terrain_id]
		
		# Use TileSetGenerator's create_terrain_tile_pattern method for detailed patterns
		tileset_generator.create_terrain_tile_pattern(image, terrain_id, x, y)
		
		DebugLogger.info(str("Generated detailed pattern for terrain ") + " " + str(terrain_id) + " " + str(" at (") + " " + str(x) + " " + str(", ") + " " + str(y) + " " + str("))")
	
	# Create texture from image
	var texture = ImageTexture.new()
	texture.set_image(image)
	DebugLogger.info("Terrain atlas created with detailed patterns including town sprites!")
	return texture

func debug_load_sections_around(world_pos: Vector2, radius: int = 1):
	var center_section = get_section_id_from_world_pos(world_pos)
	DebugLogger.info(str("Loading sections around ") + " " + str(center_section) + " " + str(" with radius ") + " " + str(radius))
	
	for x in range(-radius, radius + 1):
		for y in range(-radius, radius + 1):
			var section_id = Vector2i(center_section.x + x, center_section.y + y)
			if not map_sections.has(section_id):
				generate_map_section_data_only(section_id)
				create_tilemap_for_section(section_id)
				DebugLogger.info(str("  Loaded section: ") + " " + str(section_id))

func get_town_data_at_position(world_pos: Vector2) -> Dictionary:
	# Convert world position to tile coordinate (top-left of tile)
	var tile_pos = Vector2i(int(floor(world_pos.x / TILE_SIZE)), int(floor(world_pos.y / TILE_SIZE)))
    
	# Search all sections for a town matching these tile coordinates
	for section_id in map_sections.keys():
		var section = map_sections[section_id]
		# Skip if no towns recorded
		if section.town_data.is_empty():
			continue
		for local_pos in section.town_data.keys():
			var global_tile_pos = world_to_global_tile(local_pos, section_id)
			if global_tile_pos == tile_pos:
				return section.town_data[local_pos]
    
	# Return empty dictionary if no town at this position
	return {}

func print_section_towns(section_id: Vector2i):
	"""Debug function to print all towns in a section"""
	DebugLogger.info(str("=== SECTION TOWNS DEBUG for ") + " " + str(section_id) + " " + str(" ==="))
	if map_sections.has(section_id):
		var section = map_sections[section_id]
		DebugLogger.info(str("Section found, town count: ") + " " + str(section.town_data.size()))
		for local_pos in section.town_data:
			var town_data = section.town_data[local_pos]
			var global_pos = world_to_global_tile(local_pos, section_id)
			var world_pos = Vector2(global_pos.x * TILE_SIZE, global_pos.y * TILE_SIZE)
			DebugLogger.info(str("Town '") + " " + str(town_data.get("name", "Unknown")), "' at local ", local_pos, " global tile ", global_pos, " world pos ", world_pos)
	else:
		DebugLogger.info(str("Section ") + " " + str(section_id) + " " + str(" not found!"))
	DebugLogger.info("=== END SECTION TOWNS DEBUG ===")

