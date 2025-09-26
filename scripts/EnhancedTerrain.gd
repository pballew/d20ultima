class_name EnhancedTerrain
extends Node2D

# Enhanced terrain system with pixel art and animations
const TILE_SIZE = 32
const MAP_WIDTH = 25  # Reduced from 50 to make sections more visible
const MAP_HEIGHT = 20  # Reduced from 40 to make sections more visible

# Terrain types
enum TerrainType { 
	GRASS, DIRT, STONE, WATER, TREE, 
	MOUNTAIN, VALLEY, RIVER, LAKE, OCEAN,
	FOREST, HILLS, BEACH, SWAMP, TOWN
}

# Map section structure for multi-map support
class MapSection:
	var section_id: Vector2i  # Grid coordinate of this map section (0,0 is original, 0,-1 is north)
	var terrain_data: Dictionary = {}  # Local terrain data for this section
	var sprites: Array = []  # Visual sprites for this section
	var animated_waters: Array = []  # Animated water tiles in this section
	
	func _init(id: Vector2i):
		section_id = id

# Multi-map system variables
var map_sections: Dictionary = {}  # Key: Vector2i section_id, Value: MapSection
var current_sections: Array[Vector2i] = []  # Currently loaded sections

# Map data persistence
var map_data_manager
var current_world_seed: int

# Legacy single-map data (will be migrated to map_sections)
var terrain_data: Dictionary = {}
var noise: FastNoiseLite
var moisture_noise: FastNoiseLite
var elevation_noise: FastNoiseLite

# Animated terrain nodes
var animated_waters: Array = []

func _ready():
	# Hide terrain during generation to prevent visual "loading" effect
	visible = false
	
	# Initialize map data manager
	var MapDataManagerClass = load("res://scripts/MapDataManager.gd")
	map_data_manager = MapDataManagerClass.new()
	current_world_seed = randi()
	
	# Initialize multiple noise layers for complex terrain
	noise = FastNoiseLite.new()
	noise.seed = current_world_seed
	noise.frequency = 0.1
	noise.noise_type = FastNoiseLite.TYPE_PERLIN
	
	moisture_noise = FastNoiseLite.new()
	moisture_noise.seed = current_world_seed + 1000
	moisture_noise.frequency = 0.05
	moisture_noise.noise_type = FastNoiseLite.TYPE_SIMPLEX
	
	elevation_noise = FastNoiseLite.new()
	elevation_noise.seed = current_world_seed + 2000
	elevation_noise.frequency = 0.08
	elevation_noise.noise_type = FastNoiseLite.TYPE_SIMPLEX_SMOOTH
	
	# Initialize multi-map system
	initialize_multi_map_system()
	
	# DEBUG: Force clear existing map data to test new town generation
	map_sections.clear()
	
	print("=== TOWN GENERATION DEBUG: About to start terrain generation ===")
	
	# Generate initial map sections to cover the spawn area and adjacent areas
	print("Starting terrain generation...")
	
	# Generate all terrain data first (no visuals)
	# With 25x20 sections, we need more sections to cover the screen area
	var sections_to_generate = [
		# Center 2x2 grid around spawn
		Vector2i(0, 0),   Vector2i(1, 0),   # Bottom row
		Vector2i(0, -1),  Vector2i(1, -1),  # Top row
		# Extended coverage for full screen area
		Vector2i(-1, 0),  Vector2i(-1, -1), # Left column
		Vector2i(2, 0),   Vector2i(2, -1),  # Right column  
		Vector2i(0, 1),   Vector2i(1, 1),   # Bottom extension
	]
	
	# First pass: Generate all terrain data without creating sprites
	for section_id in sections_to_generate:
		generate_map_section_data_only(section_id)
	
	# Second pass: Create all sprites at once
	for section_id in sections_to_generate:
		create_sprites_for_section(section_id)
	
	print("Generated all initial sections")
	
	# DEBUG: Manually place a town in center section for testing
	var center_section_id = Vector2i(0, 0)
	var test_town_pos = Vector2i(5, 5)  # Place at (5,5) within section
	
	if map_sections.has(center_section_id):
		var center_section = map_sections[center_section_id]
		center_section.terrain_data[test_town_pos] = TerrainType.TOWN
		terrain_data[Vector2i(5, 5)] = TerrainType.TOWN  # Global position
		print("=== DEBUG: Manually placed town at (5,5) in center section ===")
		
		# Also refresh the tilemap for this section to show the town
		var tilemap_name = "TileMap_" + str(center_section_id.x) + "_" + str(center_section_id.y)
		var existing_tilemap = get_node_or_null(tilemap_name)
		if existing_tilemap:
			populate_native_tilemap(existing_tilemap, center_section.terrain_data, center_section_id)
			print("=== DEBUG: Refreshed tilemap to show manual town ===")
	else:
		print("=== DEBUG ERROR: Center section not found! ===")
	
	# Don't call ensure_safe_spawn_area here - it generates extra sections
	# The spawn area should already be walkable from the generated sections
	
	# Debug output and visual markers
	print_map_debug_info()
	test_coordinate_conversions()
	draw_section_boundaries()
	
	# Show terrain now that generation is complete
	visible = true
	print("Terrain generation complete - now visible")

# Map data management functions
func get_map_save_statistics() -> Dictionary:
	return map_data_manager.get_save_statistics()

func clear_all_saved_maps():
	map_data_manager.clear_all_sections()
	print("Cleared all saved map data")

func get_saved_sections() -> Array[Vector2i]:
	return map_data_manager.get_saved_sections()

func force_save_current_sections():
	for section_id in current_sections:
		save_section_data(section_id)
	print("Force saved ", current_sections.size(), " sections")

func reload_section_from_disk(section_id: Vector2i):
	if map_sections.has(section_id):
		# Remove existing section
		var section = map_sections[section_id]
		
		# Clear sprites for this section
		for child in get_children():
			var child_section_id = get_section_id_from_world_pos(child.position)
			if child_section_id == section_id:
				child.queue_free()
		
		# Remove from memory
		map_sections.erase(section_id)
		current_sections.erase(section_id)
	
	# Regenerate from disk
	generate_map_section_data_only(section_id)
	create_sprites_for_section(section_id)

# Debug function to manually load sections around a point
func debug_load_sections_around(world_pos: Vector2, radius: int = 1):
	var center_section = get_section_id_from_world_pos(world_pos)
	print("Loading sections around ", center_section, " with radius ", radius)
	
	for x in range(-radius, radius + 1):
		for y in range(-radius, radius + 1):
			var section_id = Vector2i(center_section.x + x, center_section.y + y)
			if not map_sections.has(section_id):
				generate_map_section_data_only(section_id)
				create_sprites_for_section(section_id)
				print("  Loaded section: ", section_id)

# Console command for debugging
func _input(event):
	if event is InputEventKey and event.pressed:
		if event.keycode == KEY_F1:
			var player = get_node("../Player")
			if player:
				debug_load_sections_around(player.global_position, 2)
		elif event.keycode == KEY_F2:
			print("=== Map Data Statistics ===")
			print("Sections in memory: ", map_sections.size())
			print("Current sections: ", current_sections.size())
			var stats = get_map_save_statistics()
			print("Save statistics: ", stats)
		elif event.keycode == KEY_F3:
			clear_all_saved_maps()
			# Also clear in-memory sections and regenerate
			map_sections.clear()
			current_sections.clear()
			for child in get_children():
				child.queue_free()
			var player = get_node("../Player")
			if player:
				debug_load_sections_around(player.global_position, 2)

func ensure_safe_spawn_area():
	# Ensure there's always a 5x5 area of walkable terrain around world center (0,0)
	var spawn_radius = 3  # 7x7 area around center
	for x in range(-spawn_radius, spawn_radius + 1):
		for y in range(-spawn_radius, spawn_radius + 1):
			var global_tile_pos = Vector2i(x, y)
			
			# Create a mix of grass and dirt in spawn area
			var spawn_terrain = TerrainType.GRASS if (x + y) % 2 == 0 else TerrainType.DIRT
			
			# Update terrain in both global terrain_data and appropriate section
			terrain_data[global_tile_pos] = spawn_terrain
			
			# Update the terrain in the appropriate map section
			var coord_info = global_tile_to_section_and_local(global_tile_pos)
			var section_id = coord_info["section_id"]
			var local_pos = coord_info["local_pos"]
			
			# Ensure the section exists
			if not map_sections.has(section_id):
				generate_map_section(section_id)
			
			# Update section terrain data
			map_sections[section_id].terrain_data[local_pos] = spawn_terrain
			
			# Remove any existing sprite at this position
			var world_pos = Vector2(global_tile_pos.x * TILE_SIZE, global_tile_pos.y * TILE_SIZE)
			for child in get_children():
				if child.position == world_pos:
					child.queue_free()
			
			# Create new walkable terrain sprite
			create_basic_terrain(world_pos, spawn_terrain)

func ensure_safe_spawn_area_minimal():
	# Ensure there's always walkable terrain around world center (0,0) WITHOUT generating extra sections
	var spawn_radius = 2  # Smaller 5x5 area around center to stay within original section
	for x in range(-spawn_radius, spawn_radius + 1):
		for y in range(-spawn_radius, spawn_radius + 1):
			var global_tile_pos = Vector2i(x, y)
			
			# Create a mix of grass and dirt in spawn area
			var spawn_terrain = TerrainType.GRASS if (x + y) % 2 == 0 else TerrainType.DIRT
			
			# Only update if the section already exists (don't generate new ones)
			var coord_info = global_tile_to_section_and_local(global_tile_pos)
			var section_id = coord_info["section_id"]
			var local_pos = coord_info["local_pos"]
			
			if map_sections.has(section_id):
				# Update terrain in both global terrain_data and section
				terrain_data[global_tile_pos] = spawn_terrain
				map_sections[section_id].terrain_data[local_pos] = spawn_terrain
				
				# Remove any existing sprite at this position
				var world_pos = Vector2(global_tile_pos.x * TILE_SIZE, global_tile_pos.y * TILE_SIZE)
				for child in get_children():
					if child.position == world_pos:
						child.queue_free()
				
				# Create new walkable terrain sprite
				create_basic_terrain(world_pos, spawn_terrain)

# Multi-map system functions
func initialize_multi_map_system():
	# Initialize map sections dictionary
	map_sections.clear()
	current_sections.clear()

func generate_map_section(section_id: Vector2i):
	# Don't regenerate if section already exists
	if map_sections.has(section_id):
		return
	
	print("Generating map section: ", section_id)
	
	# Create new map section
	var section = MapSection.new(section_id)
	map_sections[section_id] = section
	current_sections.append(section_id)
	
	# Calculate global offset for this section
	var section_offset_x = section_id.x * MAP_WIDTH
	var section_offset_y = section_id.y * MAP_HEIGHT
	
	# First pass: Generate all terrain data without visuals
	var sprites_to_create = []
	
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
			
			# Store in section's local terrain data
			var local_tile_pos = Vector2i(local_x, local_y)
			section.terrain_data[local_tile_pos] = terrain_type
			
			# Also store in global terrain_data for backward compatibility
			var global_tile_pos = world_to_global_tile(local_tile_pos, section_id)
			terrain_data[global_tile_pos] = terrain_type
			
			# Queue sprite for creation
			sprites_to_create.append({
				"local_pos": local_tile_pos,
				"terrain_type": terrain_type,
				"section_id": section_id
			})
	
	# Second pass: Create all visual sprites at once
	for sprite_data in sprites_to_create:
		create_terrain_sprite_for_section(sprite_data.local_pos, sprite_data.terrain_type, sprite_data.section_id)

func world_to_global_tile(local_tile_pos: Vector2i, section_id: Vector2i) -> Vector2i:
	# Convert local tile position within a section to global tile coordinates
	var section_base_x = section_id.x * MAP_WIDTH - MAP_WIDTH/2
	var section_base_y = section_id.y * MAP_HEIGHT - MAP_HEIGHT/2
	return Vector2i(
		local_tile_pos.x + section_base_x,
		local_tile_pos.y + section_base_y
	)

func global_tile_to_section_and_local(global_tile_pos: Vector2i) -> Dictionary:
	# Convert global tile coordinates to section_id and local coordinates
	# Each section covers tiles from -MAP_WIDTH/2 to +MAP_WIDTH/2 (exclusive) in local coordinates
	# Section (0,0) covers global tiles -25 to +24 in both X and Y
	
	# Determine which section this global tile belongs to
	var section_x = 0
	var section_y = 0
	
	# Handle negative coordinates properly
	if global_tile_pos.x >= 0:
		section_x = int((global_tile_pos.x + MAP_WIDTH/2) / MAP_WIDTH)
	else:
		section_x = int((global_tile_pos.x + MAP_WIDTH/2 + 1) / MAP_WIDTH) - 1
	
	if global_tile_pos.y >= 0:
		section_y = int((global_tile_pos.y + MAP_HEIGHT/2) / MAP_HEIGHT)
	else:
		section_y = int((global_tile_pos.y + MAP_HEIGHT/2 + 1) / MAP_HEIGHT) - 1
		
	var section_id = Vector2i(section_x, section_y)
	
	# Calculate local position within the section
	var section_base_x = section_x * MAP_WIDTH - MAP_WIDTH/2
	var section_base_y = section_y * MAP_HEIGHT - MAP_HEIGHT/2
	var local_x = global_tile_pos.x - section_base_x
	var local_y = global_tile_pos.y - section_base_y
	var local_pos = Vector2i(local_x, local_y)
	
	return {"section_id": section_id, "local_pos": local_pos}

func generate_map_section_data_only(section_id: Vector2i):
	# Generate terrain data without creating sprites (faster)
	if map_sections.has(section_id):
		return
	
	print("Generating data for section: ", section_id)
	
	# Try to load existing section data first
	var saved_data = map_data_manager.load_section(section_id)
	
	# Create new map section
	var section = MapSection.new(section_id)
	map_sections[section_id] = section
	current_sections.append(section_id)
	
	if saved_data and saved_data.terrain_data.size() > 0:
		# Use saved data
		print("Loaded existing data for section: ", section_id)
		section.terrain_data = saved_data.terrain_data.duplicate()
		
		# Restore town data if it exists
		if saved_data.town_data.size() > 0:
			section.set("town_data", saved_data.town_data.duplicate())
			print("Restored ", saved_data.town_data.size(), " towns for section ", section_id)
		
		# Update global terrain_data for backward compatibility
		for local_pos in section.terrain_data.keys():
			var global_tile_pos = world_to_global_tile(local_pos, section_id)
			terrain_data[global_tile_pos] = section.terrain_data[local_pos]
		return
	
	# Calculate global offset for this section
	var section_offset_x = section_id.x * MAP_WIDTH
	var section_offset_y = section_id.y * MAP_HEIGHT
	
	# Generate terrain data only
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
			
			# Store in section's local terrain data
			var local_tile_pos = Vector2i(local_x, local_y)
			section.terrain_data[local_tile_pos] = terrain_type
			
			# Also store in global terrain_data for backward compatibility
			var global_tile_pos = world_to_global_tile(local_tile_pos, section_id)
			terrain_data[global_tile_pos] = terrain_type
	
	# Generate towns for this section
	generate_towns_for_section(section_id)
	
	# Save the generated section data to file
	save_section_data(section_id)

func generate_towns_for_section(section_id: Vector2i):
	# Generate towns with 15-30 tile spacing
	var section = map_sections[section_id]
	var TownNameGen = load("res://scripts/TownNameGenerator.gd")
	
	# Create a deterministic RNG for this section
	var rng = RandomNumberGenerator.new()
	rng.seed = current_world_seed + section_id.x * 1000 + section_id.y
	
	# Try to place 1-2 towns per section, with spacing constraints
	var town_attempts = rng.randi_range(0, 2)  # 0-2 towns per section
	
	for attempt in range(town_attempts):
		# Random position within section
		var local_x = rng.randi_range(-MAP_WIDTH/2 + 2, MAP_WIDTH/2 - 2)
		var local_y = rng.randi_range(-MAP_HEIGHT/2 + 2, MAP_HEIGHT/2 - 2)
		var local_pos = Vector2i(local_x, local_y)
		var global_pos = world_to_global_tile(local_pos, section_id)
		
		# Check if this position is suitable for a town
		print("Trying to place town at local_pos: ", local_pos, " global_pos: ", global_pos)
		if can_place_town_at_position(local_pos, section_id):
			print("Position is suitable for town")
			# Check spacing from other towns
			if is_town_spacing_valid(global_pos):
				print("Spacing is valid for town")
				# Place the town
				section.terrain_data[local_pos] = TerrainType.TOWN
				terrain_data[global_pos] = TerrainType.TOWN
				
				# Generate town data and store it
				var town_data = TownNameGen.generate_town_data(global_pos, rng.seed + attempt)
				store_town_data(section_id, local_pos, town_data)
				
				print("Placed town '", town_data.name, "' at ", global_pos, " in section ", section_id)
			else:
				print("Town spacing invalid at ", global_pos)
		else:
			print("Position not suitable for town at ", local_pos)

func can_place_town_at_position(local_pos: Vector2i, section_id: Vector2i) -> bool:
	print("*** CAN_PLACE_TOWN_AT_POSITION CALLED FOR ", local_pos, " in section ", section_id, " ***")
	
	# Towns can only be placed on suitable terrain types
	var section = map_sections[section_id]
	if not section.terrain_data.has(local_pos):
		print("  ERROR: No terrain data at local_pos: ", local_pos)
		return false
	
	var terrain_type = section.terrain_data[local_pos]
	var terrain_name = TerrainType.keys()[terrain_type] if terrain_type < TerrainType.keys().size() else "UNKNOWN"
	print("  Terrain type at ", local_pos, " is: ", terrain_type, " (", terrain_name, ")")
	
	# For debugging: Allow towns on any terrain type except water/lava
	var forbidden_types = [TerrainType.WATER, TerrainType.LAVA]
	var is_suitable = terrain_type not in forbidden_types
	print("  Is suitable: ", is_suitable, " (terrain ", terrain_type, " not in forbidden: ", forbidden_types, ")")
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

func store_town_data(section_id: Vector2i, local_pos: Vector2i, town_data: Dictionary):
	# Store town data in the section for persistence
	# For now, we'll add this to the map data manager later
	var section = map_sections[section_id]
	if not section.has_method("get_town_data"):
		# Add a simple dictionary to store town data
		if not section.has("town_data"):
			section.set("town_data", {})
		section.get("town_data")[local_pos] = town_data

func save_section_data(section_id: Vector2i):
	if not map_sections.has(section_id):
		return
	
	var section = map_sections[section_id]
	var town_dict = {}
	if section.has("town_data"):
		town_dict = section.get("town_data")
	
	var section_data = map_data_manager.create_section_data_from_terrain(
		section_id, 
		section.terrain_data, 
		current_world_seed,
		town_dict
	)
	map_data_manager.save_section(section_data)

func create_sprites_for_section(section_id: Vector2i):
	# Create all sprites for a section at once
	if not map_sections.has(section_id):
		return
		
	print("Creating sprites for section: ", section_id)
	var section = map_sections[section_id]
	
	# Create all sprites for this section
	for local_pos in section.terrain_data.keys():
		var terrain_type = section.terrain_data[local_pos]
		create_terrain_sprite_for_section(local_pos, terrain_type, section_id)

func create_terrain_sprite_for_section(local_tile_pos: Vector2i, terrain_type: int, section_id: Vector2i):
	# Calculate world position for sprite
	var global_tile_pos = world_to_global_tile(local_tile_pos, section_id)
	var world_pos = Vector2(global_tile_pos.x * TILE_SIZE, global_tile_pos.y * TILE_SIZE)
	
	# Create sprite using existing terrain sprite creation logic
	create_terrain_sprite(global_tile_pos, terrain_type)

# Function to get section ID from world position
func get_section_id_from_world_pos(world_pos: Vector2) -> Vector2i:
	var tile_pos = Vector2i(int(world_pos.x / TILE_SIZE), int(world_pos.y / TILE_SIZE))
	var coord_info = global_tile_to_section_and_local(tile_pos)
	return coord_info["section_id"]

# Function to ensure needed sections are loaded around a position
func ensure_sections_loaded_around_position(world_pos: Vector2, radius: int = 1):
	var center_section = get_section_id_from_world_pos(world_pos)
	
	# Load sections in a grid around the center section
	for x in range(-radius, radius + 1):
		for y in range(-radius, radius + 1):
			var section_id = center_section + Vector2i(x, y)
			if not map_sections.has(section_id):
				generate_map_section(section_id)

# Debug function to print map information
func print_map_debug_info():
	print("=== Multi-Map Debug Info ===")
	print("Total sections loaded: ", map_sections.size())
	print("Sections: ", map_sections.keys())
	var bounds = get_used_rect()
	print("World bounds (tiles): ", bounds)
	print("World bounds (pixels): ", Vector2(bounds.position) * TILE_SIZE, " to ", Vector2(bounds.position + bounds.size) * TILE_SIZE)
	print("=============================")

# Debug function to draw section boundaries (call this after generation)
func draw_section_boundaries():
	for section_id in map_sections.keys():
		# Calculate section boundaries in world coordinates
		var section_min_tile = Vector2i(section_id.x * MAP_WIDTH - MAP_WIDTH/2, section_id.y * MAP_HEIGHT - MAP_HEIGHT/2)
		var section_max_tile = Vector2i((section_id.x + 1) * MAP_WIDTH - MAP_WIDTH/2 - 1, (section_id.y + 1) * MAP_HEIGHT - MAP_HEIGHT/2 - 1)
		
		# Create boundary markers (small colored squares at corners)
		create_section_boundary_marker(Vector2(section_min_tile.x * TILE_SIZE, section_min_tile.y * TILE_SIZE), section_id)
		create_section_boundary_marker(Vector2(section_max_tile.x * TILE_SIZE, section_min_tile.y * TILE_SIZE), section_id)
		create_section_boundary_marker(Vector2(section_min_tile.x * TILE_SIZE, section_max_tile.y * TILE_SIZE), section_id)
		create_section_boundary_marker(Vector2(section_max_tile.x * TILE_SIZE, section_max_tile.y * TILE_SIZE), section_id)

func create_section_boundary_marker(world_pos: Vector2, section_id: Vector2i):
	var marker = ColorRect.new()
	marker.size = Vector2(16, 16)  # Larger markers for better visibility
	marker.position = world_pos - Vector2(8, 8)  # Center the marker
	# Color-code by section position for easy identification
	var color = Color.WHITE
	if section_id.x < 0: color.r = 1.0  # Red tint for negative X
	if section_id.y < 0: color.b = 1.0  # Blue tint for negative Y  
	if section_id.x > 0: color.g = 1.0  # Green tint for positive X
	marker.color = color
	marker.z_index = 100  # Draw on top
	add_child(marker)

# Test coordinate conversion functions
func test_coordinate_conversions():
	print("=== Testing Coordinate Conversions ===")
	
	# Test cases: tile positions that should be in different sections
	var test_cases = [
		Vector2i(0, 0),    # Center of original section (0,0)
		Vector2i(0, -20),  # Center of northern section (0,-1) 
		Vector2i(0, -21),  # Just into northern section (0,-1)
		Vector2i(0, -19),  # Just at edge of original section
		Vector2i(-25, -20), # Far corner 
		Vector2i(25, -40)   # Another far corner
	]
	
	for tile_pos in test_cases:
		var coord_info = global_tile_to_section_and_local(tile_pos)
		var section_id = coord_info["section_id"]
		var local_pos = coord_info["local_pos"]
		var reconstructed = world_to_global_tile(local_pos, section_id)
		
		print("Tile ", tile_pos, " -> Section ", section_id, " Local ", local_pos, " -> Reconstructed ", reconstructed)
		if reconstructed != tile_pos:
			print("ERROR: Coordinate conversion mismatch!")
	
	print("=== End Coordinate Tests ===")

func generate_enhanced_terrain():
	# Legacy function - terrain generation now handled by generate_map_section()
	# This function is kept for backward compatibility but does nothing
	print("Note: generate_enhanced_terrain() is deprecated - using multi-map system")

func determine_terrain_type(elevation: float, moisture: float, base_noise: float) -> int:
	# Ocean and lakes (very low elevation)
	if elevation < -0.6:
		return TerrainType.OCEAN
	elif elevation < -0.3 and moisture > 0.0:
		return TerrainType.LAKE
	
	# Rivers (low elevation with specific moisture patterns)
	elif elevation < -0.1 and abs(moisture) < 0.2:
		return TerrainType.RIVER
	
	# Mountains (high elevation)
	elif elevation > 0.5:
		return TerrainType.MOUNTAIN
	elif elevation > 0.3:
		return TerrainType.HILLS
	
	# Valleys (moderate elevation, high moisture)
	elif elevation > -0.1 and elevation < 0.2 and moisture > 0.3:
		return TerrainType.VALLEY
	
	# Forests and trees (moderate elevation and moisture)
	elif moisture > 0.2 and elevation > 0.0:
		if base_noise > 0.1:
			return TerrainType.FOREST
		else:
			return TerrainType.TREE
	
	# Swamps (low elevation, high moisture)
	elif elevation < 0.1 and moisture > 0.4:
		return TerrainType.SWAMP
	
	# Beaches (near water)
	elif elevation < 0.0 and moisture < -0.2:
		return TerrainType.BEACH
	
	# Default terrain based on moisture
	elif moisture < -0.2:
		return TerrainType.DIRT
	elif moisture < 0.2:
		return TerrainType.GRASS
	else:
		return TerrainType.STONE

func create_terrain_sprite(tile_pos: Vector2i, terrain_type: int):
	var world_pos = Vector2(tile_pos.x * TILE_SIZE, tile_pos.y * TILE_SIZE)
	
	match terrain_type:
		TerrainType.WATER, TerrainType.RIVER, TerrainType.LAKE, TerrainType.OCEAN:
			create_animated_water(world_pos, terrain_type)
		TerrainType.TREE, TerrainType.FOREST:
			create_tree_sprite(world_pos, terrain_type)
		TerrainType.MOUNTAIN:
			create_mountain_sprite(world_pos, tile_pos)
		TerrainType.HILLS:
			create_hills_sprite(world_pos, tile_pos)
		TerrainType.VALLEY:
			create_valley_sprite(world_pos)
		TerrainType.TOWN:
			create_town_sprite(world_pos, tile_pos)
		_:
			create_basic_terrain(world_pos, terrain_type)

func create_animated_water(world_pos: Vector2, water_type: int):
	var animated_sprite = AnimatedSprite2D.new()
	animated_sprite.position = world_pos
	
	# Create animation frames programmatically
	var sprite_frames = SpriteFrames.new()
	sprite_frames.add_animation("flow")
	
	# Create water animation frames
	var colors = get_water_colors(water_type)
	for i in range(4):
		var frame_texture = create_water_frame(colors, i)
		sprite_frames.add_frame("flow", frame_texture)
	
	sprite_frames.set_animation_speed("flow", 2.0)
	animated_sprite.sprite_frames = sprite_frames
	animated_sprite.play("flow")
	
	add_child(animated_sprite)
	animated_waters.append(animated_sprite)

func get_water_colors(water_type: int) -> Array:
	match water_type:
		TerrainType.RIVER:
			return [Color(0.3, 0.6, 0.9), Color(0.4, 0.7, 1.0)]
		TerrainType.LAKE:
			return [Color(0.2, 0.5, 0.8), Color(0.3, 0.6, 0.9)]
		TerrainType.OCEAN:
			return [Color(0.1, 0.3, 0.6), Color(0.2, 0.4, 0.7)]
		_:
			return [Color(0.4, 0.7, 1.0), Color(0.5, 0.8, 1.0)]

func create_water_frame(colors: Array, frame: int) -> ImageTexture:
	var image = Image.create(TILE_SIZE, TILE_SIZE, false, Image.FORMAT_RGB8)
	
	# Create animated water effect
	var base_color = colors[0]
	var highlight_color = colors[1]
	
	for x in range(TILE_SIZE):
		for y in range(TILE_SIZE):
			# Create wave pattern
			var wave = sin((x + frame * 4) * 0.3) * 0.3 + sin((y + frame * 3) * 0.4) * 0.2
			var color = base_color.lerp(highlight_color, (wave + 1.0) * 0.5)
			image.set_pixel(x, y, color)
	
	var texture = ImageTexture.new()
	texture.set_image(image)
	return texture

func create_tree_sprite(world_pos: Vector2, tree_type: int):
	var sprite = Sprite2D.new()
	sprite.position = world_pos
	sprite.texture = create_tree_texture(tree_type)
	add_child(sprite)

func create_tree_texture(tree_type: int) -> ImageTexture:
	var image = Image.create(TILE_SIZE, TILE_SIZE, false, Image.FORMAT_RGB8)
	
	var trunk_color = Color(0.4, 0.2, 0.1)  # Brown
	var dark_green = Color(0.0, 0.3, 0.0)  # Dark evergreen
	var light_green = Color(0.1, 0.5, 0.1)  # Lighter evergreen
	var grass_color = Color(0.3, 0.6, 0.2)
	
	# Fill with grass background
	for x in range(TILE_SIZE):
		for y in range(TILE_SIZE):
			image.set_pixel(x, y, grass_color)
	
	# Draw tree trunk (bottom center) - thin vertical trunk
	var trunk_width = 4
	var trunk_height = 8
	var trunk_start_x = (TILE_SIZE - trunk_width) / 2
	var trunk_start_y = TILE_SIZE - trunk_height
	
	for x in range(trunk_start_x, trunk_start_x + trunk_width):
		for y in range(trunk_start_y, TILE_SIZE):
			if x >= 0 and x < TILE_SIZE and y >= 0 and y < TILE_SIZE:
				image.set_pixel(x, y, trunk_color)
	
	# Draw wider evergreen tree in triangular layers (pine/fir style)
	var center_x = TILE_SIZE / 2
	var tree_color = dark_green if tree_type == TerrainType.FOREST else light_green
	
	# Create 3-4 layers of triangular canopy - made wider
	var layers = [
		{"top": 3, "bottom": 14, "width": 10},   # Top layer - wider
		{"top": 10, "bottom": 20, "width": 16}, # Middle layer - much wider
		{"top": 17, "bottom": 26, "width": 22}  # Bottom layer - very wide
	]
	
	for layer in layers:
		for y in range(layer.top, min(layer.bottom, TILE_SIZE - 2)):
			# Calculate triangle width at this height
			var progress = float(y - layer.top) / float(layer.bottom - layer.top)
			var half_width = int(layer.width * progress * 0.5)
			
			for x in range(center_x - half_width, center_x + half_width + 1):
				if x >= 0 and x < TILE_SIZE and y >= 0 and y < TILE_SIZE:
					# Add some texture variation
					var edge_distance = min(abs(x - (center_x - half_width)), abs(x - (center_x + half_width)))
					if edge_distance > 0 or randi() % 3 == 0:  # Don't make edges too jagged
						image.set_pixel(x, y, tree_color)
	
	var texture = ImageTexture.new()
	texture.set_image(image)
	return texture

func create_mountain_sprite(world_pos: Vector2, tile_pos: Vector2i):
	var sprite = Sprite2D.new()
	sprite.position = world_pos
	
	# Use tile position to determine mountain type consistently
	var mountain_type = (abs(tile_pos.x) + abs(tile_pos.y)) % 3
	sprite.texture = create_mountain_texture(mountain_type)
	add_child(sprite)

func create_hills_sprite(world_pos: Vector2, tile_pos: Vector2i):
	var sprite = Sprite2D.new()
	sprite.position = world_pos
	sprite.texture = create_hill_texture()
	add_child(sprite)

func create_mountain_texture(mountain_type: int) -> ImageTexture:
	var image = Image.create(TILE_SIZE, TILE_SIZE, false, Image.FORMAT_RGB8)
	
	var rock_color = Color(0.6, 0.6, 0.6)
	var dark_rock = Color(0.4, 0.4, 0.4)
	var snow_color = Color(0.95, 0.95, 1.0)
	var shadow_color = Color(0.3, 0.3, 0.35)
	var base_color = Color(0.5, 0.4, 0.3)  # Rocky ground
	
	# Fill with base terrain first
	for x in range(TILE_SIZE):
		for y in range(TILE_SIZE):
			image.set_pixel(x, y, base_color)
	
	var center_x = TILE_SIZE / 2
	
	match mountain_type:
		0: # Large peak mountain
			create_large_peak(image, center_x, rock_color, dark_rock, snow_color, shadow_color, base_color)
		1: # Medium peak mountain  
			create_medium_peak(image, center_x, rock_color, dark_rock, snow_color, shadow_color, base_color)
		2: # Small hill
			create_small_hill(image, center_x, rock_color, dark_rock, shadow_color, base_color)
	
	var texture = ImageTexture.new()
	texture.set_image(image)
	return texture

func create_large_peak(image: Image, center_x: int, rock_color: Color, dark_rock: Color, snow_color: Color, shadow_color: Color, base_color: Color):
	# Single large peak that dominates the tile
	var peak_top = 2
	var peak_base_width = 26
	
	for y in range(peak_top, TILE_SIZE):
		var height_progress = float(y - peak_top) / float(TILE_SIZE - peak_top)
		var half_width = int(peak_base_width * height_progress * 0.5)
		
		for x in range(center_x - half_width, center_x + half_width + 1):
			if x >= 0 and x < TILE_SIZE and y >= 0 and y < TILE_SIZE:
				var color_to_use: Color
				
				# Snow cap on top third
				if y < peak_top + (TILE_SIZE - peak_top) * 0.3:
					color_to_use = snow_color
				# Shadow side (left)
				elif x < center_x:
					color_to_use = shadow_color if y < peak_top + (TILE_SIZE - peak_top) * 0.6 else dark_rock
				# Lit side (right)
				else:
					color_to_use = rock_color
				
				image.set_pixel(x, y, color_to_use)

func create_medium_peak(image: Image, center_x: int, rock_color: Color, dark_rock: Color, snow_color: Color, shadow_color: Color, base_color: Color):
	# Single medium peak
	var peak_top = 6
	var peak_base_width = 20
	
	for y in range(peak_top, TILE_SIZE):
		var height_progress = float(y - peak_top) / float(TILE_SIZE - peak_top)
		var half_width = int(peak_base_width * height_progress * 0.5)
		
		for x in range(center_x - half_width, center_x + half_width + 1):
			if x >= 0 and x < TILE_SIZE and y >= 0 and y < TILE_SIZE:
				var color_to_use: Color
				
				# Small snow cap on top
				if y < peak_top + (TILE_SIZE - peak_top) * 0.2:
					color_to_use = snow_color
				# Shadow side
				elif x < center_x:
					color_to_use = shadow_color if y < peak_top + (TILE_SIZE - peak_top) * 0.5 else dark_rock
				# Lit side
				else:
					color_to_use = rock_color
				
				image.set_pixel(x, y, color_to_use)

func create_small_hill(image: Image, center_x: int, rock_color: Color, dark_rock: Color, shadow_color: Color, base_color: Color):
	# Single small rounded hill - no snow
	var hill_top = 12
	var hill_base_width = 16
	
	for y in range(hill_top, TILE_SIZE):
		var height_progress = float(y - hill_top) / float(TILE_SIZE - hill_top)
		var half_width = int(hill_base_width * height_progress * 0.5)
		
		for x in range(center_x - half_width, center_x + half_width + 1):
			if x >= 0 and x < TILE_SIZE and y >= 0 and y < TILE_SIZE:
				var color_to_use: Color
				
				# Shadow side
				if x < center_x:
					color_to_use = shadow_color
				# Lit side  
				else:
					color_to_use = rock_color
				
				# Add some grassy patches on the hill
				if randi() % 6 == 0 and y > hill_top + (TILE_SIZE - hill_top) * 0.6:
					color_to_use = Color(0.4, 0.6, 0.3)  # Hill grass
				
				image.set_pixel(x, y, color_to_use)

func create_hill_texture() -> ImageTexture:
	# This handles the TerrainType.HILLS - creates rolling hills
	var image = Image.create(TILE_SIZE, TILE_SIZE, false, Image.FORMAT_RGB8)
	
	var hill_color = Color(0.5, 0.4, 0.3)
	var grass_color = Color(0.4, 0.6, 0.3)
	var base_color = Color(0.5, 0.4, 0.3)
	
	# Fill with base terrain
	for x in range(TILE_SIZE):
		for y in range(TILE_SIZE):
			image.set_pixel(x, y, base_color)
	
	# Create rolling hills pattern
	for x in range(TILE_SIZE):
		var hill_height = int(TILE_SIZE * 0.7 + sin(x * 0.3) * 4)
		for y in range(hill_height, TILE_SIZE):
			var color_to_use = hill_color
			if y > hill_height + 2 and randi() % 4 == 0:
				color_to_use = grass_color
			image.set_pixel(x, y, color_to_use)
	
	var texture = ImageTexture.new()
	texture.set_image(image)
	return texture

func create_valley_sprite(world_pos: Vector2):
	var sprite = Sprite2D.new()
	sprite.position = world_pos
	sprite.texture = create_valley_texture()
	add_child(sprite)

func create_valley_texture() -> ImageTexture:
	var image = Image.create(TILE_SIZE, TILE_SIZE, false, Image.FORMAT_RGB8)
	
	var grass_color = Color(0.2, 0.8, 0.3)  # Lush green
	var flower_colors = [Color(1.0, 0.8, 0.2), Color(0.8, 0.2, 0.8), Color(0.2, 0.3, 1.0)]
	
	# Fill with lush grass
	for x in range(TILE_SIZE):
		for y in range(TILE_SIZE):
			image.set_pixel(x, y, grass_color)
	
	# Add some scattered flowers (not in cross patterns)
	for i in range(6):
		var fx = randi() % (TILE_SIZE - 4) + 2  # Keep away from edges
		var fy = randi() % (TILE_SIZE - 4) + 2
		var color = flower_colors[randi() % flower_colors.size()]
		# Create small circular flower clusters
		for dx in range(-1, 2):
			for dy in range(-1, 2):
				if dx*dx + dy*dy <= 1:  # Circular pattern only
					var px = fx + dx
					var py = fy + dy
					if px >= 0 and px < TILE_SIZE and py >= 0 and py < TILE_SIZE:
						image.set_pixel(px, py, color)
	
	var texture = ImageTexture.new()
	texture.set_image(image)
	return texture

func create_basic_terrain(world_pos: Vector2, terrain_type: int):
	var sprite = Sprite2D.new()
	sprite.position = world_pos
	sprite.texture = create_basic_terrain_texture(terrain_type)
	add_child(sprite)

func create_basic_terrain_texture(terrain_type: int) -> ImageTexture:
	var image = Image.create(TILE_SIZE, TILE_SIZE, false, Image.FORMAT_RGB8)
	var base_color = get_terrain_color(terrain_type)
	
	# Fill entire tile with solid color - no patterns
	for x in range(TILE_SIZE):
		for y in range(TILE_SIZE):
			image.set_pixel(x, y, base_color)
	
	var texture = ImageTexture.new()
	texture.set_image(image)
	return texture

func get_terrain_color(terrain_type: int) -> Color:
	match terrain_type:
		TerrainType.GRASS:
			return Color(0.3, 0.6, 0.2)
		TerrainType.DIRT:
			return Color(0.6, 0.4, 0.2)
		TerrainType.STONE:
			return Color(0.6, 0.6, 0.6)
		TerrainType.HILLS:
			return Color(0.5, 0.4, 0.3)
		TerrainType.BEACH:
			return Color(0.9, 0.8, 0.6)
		TerrainType.SWAMP:
			return Color(0.2, 0.3, 0.1)
		_:
			return Color(0.5, 0.5, 0.5)

func is_walkable(world_pos: Vector2) -> bool:
	var tile_pos = Vector2i(int(world_pos.x / TILE_SIZE), int(world_pos.y / TILE_SIZE))
	
	if terrain_data.has(tile_pos):
		var terrain_type = terrain_data[tile_pos]
		# Non-walkable terrain types
		var blocked_terrain = [
			TerrainType.WATER, TerrainType.TREE, TerrainType.FOREST,
			TerrainType.MOUNTAIN, TerrainType.RIVER, TerrainType.LAKE, 
			TerrainType.OCEAN
		]
		return not (terrain_type in blocked_terrain)
	
	return true  # Empty tiles are walkable

# Provide a TileMap-like used rect (in tile coordinates) so camera code can compute world bounds
func get_used_rect() -> Rect2i:
	# Calculate bounds based on loaded map sections for multi-map support
	if map_sections.is_empty():
		# Fallback to legacy terrain_data if no sections exist
		if terrain_data.is_empty():
			return Rect2i(0, 0, 0, 0)
		var min_x = 999999
		var max_x = -999999
		var min_y = 999999
		var max_y = -999999
		for key in terrain_data.keys():
			if key.x < min_x: min_x = key.x
			if key.x > max_x: max_x = key.x
			if key.y < min_y: min_y = key.y
			if key.y > max_y: max_y = key.y
		return Rect2i(Vector2i(min_x, min_y), Vector2i(max_x - min_x + 1, max_y - min_y + 1))
	
	# Calculate bounds from all loaded map sections
	var min_section_x = 999999
	var max_section_x = -999999
	var min_section_y = 999999
	var max_section_y = -999999
	
	for section_id in map_sections.keys():
		if section_id.x < min_section_x: min_section_x = section_id.x
		if section_id.x > max_section_x: max_section_x = section_id.x
		if section_id.y < min_section_y: min_section_y = section_id.y
		if section_id.y > max_section_y: max_section_y = section_id.y
	
	# Convert section bounds to tile bounds
	var min_tile_x = min_section_x * MAP_WIDTH - MAP_WIDTH/2
	var max_tile_x = (max_section_x + 1) * MAP_WIDTH - MAP_WIDTH/2 - 1
	var min_tile_y = min_section_y * MAP_HEIGHT - MAP_HEIGHT/2
	var max_tile_y = (max_section_y + 1) * MAP_HEIGHT - MAP_HEIGHT/2 - 1
	
	var width = max_tile_x - min_tile_x + 1
	var height = max_tile_y - min_tile_y + 1
	
	return Rect2i(Vector2i(min_tile_x, min_tile_y), Vector2i(width, height))

func create_town_sprite(world_pos: Vector2, tile_pos: Vector2i):
	var sprite = Sprite2D.new()
	sprite.position = world_pos
	sprite.texture = create_town_texture(tile_pos)
	add_child(sprite)

func create_town_texture(tile_pos: Vector2i) -> ImageTexture:
	var image = Image.create(TILE_SIZE, TILE_SIZE, false, Image.FORMAT_RGB8)
	
	# Medieval town colors
	var grass_color = Color(0.3, 0.6, 0.2)
	var wall_color = Color(0.7, 0.7, 0.8)  # Light grey stone
	var roof_color = Color(0.6, 0.3, 0.2)  # Dark red/brown
	var door_color = Color(0.3, 0.2, 0.1)  # Dark brown
	var window_color = Color(0.8, 0.8, 0.4)  # Yellow light
	
	# Fill with grass background
	for x in range(TILE_SIZE):
		for y in range(TILE_SIZE):
			image.set_pixel(x, y, grass_color)
	
	# Create a deterministic pattern based on tile position
	var rng = RandomNumberGenerator.new()
	rng.seed = tile_pos.x * 1000 + tile_pos.y
	
	var building_type = rng.randi() % 3
	
	match building_type:
		0: # Tower/Keep style
			create_tower_building(image, rng)
		1: # House cluster
			create_house_cluster(image, rng)
		2: # Walled settlement
			create_walled_town(image, rng)
	
	var texture = ImageTexture.new()
	texture.set_image(image)
	return texture

func create_tower_building(image: Image, rng: RandomNumberGenerator):
	var wall_color = Color(0.7, 0.7, 0.8)
	var roof_color = Color(0.6, 0.3, 0.2)
	var door_color = Color(0.3, 0.2, 0.1)
	
	# Draw main tower (centered)
	var tower_width = 8
	var tower_height = 20
	var tower_x = (TILE_SIZE - tower_width) / 2
	var tower_y = TILE_SIZE - tower_height - 2
	
	# Tower walls
	for x in range(tower_x, tower_x + tower_width):
		for y in range(tower_y, tower_y + tower_height):
			if x < TILE_SIZE and y < TILE_SIZE:
				image.set_pixel(x, y, wall_color)
	
	# Tower roof (pointed)
	var roof_height = 6
	for y in range(roof_height):
		var roof_width = tower_width - y * 2
		var roof_start_x = tower_x + y
		for x in range(roof_start_x, roof_start_x + roof_width):
			if x < TILE_SIZE and tower_y + y - roof_height >= 0:
				image.set_pixel(x, tower_y - y, roof_color)
	
	# Door at bottom center
	var door_width = 2
	var door_height = 4
	var door_x = tower_x + (tower_width - door_width) / 2
	var door_y = tower_y + tower_height - door_height
	
	for x in range(door_x, door_x + door_width):
		for y in range(door_y, door_y + door_height):
			if x < TILE_SIZE and y < TILE_SIZE:
				image.set_pixel(x, y, door_color)

func create_house_cluster(image: Image, rng: RandomNumberGenerator):
	var wall_color = Color(0.7, 0.7, 0.8)
	var roof_color = Color(0.6, 0.3, 0.2)
	var door_color = Color(0.3, 0.2, 0.1)
	var window_color = Color(0.8, 0.8, 0.4)
	
	# Create 2-3 small buildings
	var buildings = [
		{"x": 2, "y": 18, "w": 8, "h": 10},
		{"x": 12, "y": 20, "w": 6, "h": 8},
		{"x": 20, "y": 16, "w": 8, "h": 12}
	]
	
	for building in buildings:
		# Building walls
		for x in range(building.x, building.x + building.w):
			for y in range(building.y, building.y + building.h):
				if x < TILE_SIZE and y < TILE_SIZE:
					image.set_pixel(x, y, wall_color)
		
		# Simple triangular roof
		var roof_peak_y = building.y - 3
		for y in range(3):
			var roof_width = building.w - y * 2
			var roof_start_x = building.x + y
			for x in range(roof_start_x, roof_start_x + roof_width):
				if x < TILE_SIZE and roof_peak_y + y >= 0:
					image.set_pixel(x, roof_peak_y + y, roof_color)
		
		# Small door and window
		var door_x = building.x + 1
		var door_y = building.y + building.h - 3
		for x in range(door_x, door_x + 2):
			for y in range(door_y, door_y + 3):
				if x < TILE_SIZE and y < TILE_SIZE:
					image.set_pixel(x, y, door_color)
		
		# Window
		if building.w > 4:
			var window_x = building.x + building.w - 3
			var window_y = building.y + 2
			image.set_pixel(window_x, window_y, window_color)
			image.set_pixel(window_x + 1, window_y, window_color)

func create_walled_town(image: Image, rng: RandomNumberGenerator):
	var wall_color = Color(0.7, 0.7, 0.8)
	var roof_color = Color(0.6, 0.3, 0.2)
	var door_color = Color(0.3, 0.2, 0.1)
	
	# Draw outer wall (perimeter)
	for x in range(TILE_SIZE):
		image.set_pixel(x, 2, wall_color)  # Top wall
		image.set_pixel(x, TILE_SIZE - 3, wall_color)  # Bottom wall
	
	for y in range(2, TILE_SIZE - 2):
		image.set_pixel(2, y, wall_color)  # Left wall
		image.set_pixel(TILE_SIZE - 3, y, wall_color)  # Right wall
	
	# Gate in the wall
	var gate_x = TILE_SIZE / 2 - 1
	for x in range(gate_x, gate_x + 2):
		image.set_pixel(x, TILE_SIZE - 3, door_color)
	
	# Small building inside
	var inner_building_x = 8
	var inner_building_y = 8
	var inner_building_w = 12
	var inner_building_h = 12
	
	for x in range(inner_building_x, inner_building_x + inner_building_w):
		for y in range(inner_building_y, inner_building_y + inner_building_h):
			if x < TILE_SIZE - 3 and y < TILE_SIZE - 3:
				image.set_pixel(x, y, wall_color)
	
	# Roof for inner building
	for y in range(4):
		var roof_width = inner_building_w - y * 2
		var roof_start_x = inner_building_x + y
		for x in range(roof_start_x, roof_start_x + roof_width):
			if x < TILE_SIZE - 3 and inner_building_y - y - 2 >= 0:
				image.set_pixel(x, inner_building_y - y - 2, roof_color)
