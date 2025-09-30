extends Node

# Utility script to generate a proper TileSet with texture atlas for terrain
# This creates a texture atlas with colored squares for each terrain type

const TILE_SIZE = 32
const TERRAIN_TYPES = 15  # Number of terrain types (includes towns)

# Reference to shared terrain colors
const terrain_colors_resource = preload("res://scripts/TerrainColors.gd")
const TERRAIN_COLORS = terrain_colors_resource.TERRAIN_COLORS

func generate_terrain_tileset() -> TileSet:
	DebugLogger.info("Generating terrain TileSet with texture atlas...")
	
	# Create the TileSet resource
	var tileset = TileSet.new()
	tileset.tile_size = Vector2i(TILE_SIZE, TILE_SIZE)
	
	# Create atlas texture
	var atlas_texture = create_terrain_atlas()
	
	# Create TileSetAtlasSource
	var atlas_source = TileSetAtlasSource.new()
	atlas_source.texture = atlas_texture
	atlas_source.texture_region_size = Vector2i(TILE_SIZE, TILE_SIZE)
	
	# Add tiles to the atlas source
	for terrain_id in range(TERRAIN_TYPES):
		var atlas_coords = Vector2i(terrain_id % 8, terrain_id / 8)  # Arrange in 8x2 grid
		
		# Create the tile
		atlas_source.create_tile(atlas_coords)
		
		# Set up the tile properties
		var tile_data = atlas_source.get_tile_data(atlas_coords, 0)
		if tile_data:
			# Add collision for solid tiles (stone, tree, mountain)
			if terrain_id in [2, 4, 5]:  # STONE, TREE, MOUNTAIN
				var collision_polygon = PackedVector2Array([
					Vector2(-TILE_SIZE/2, -TILE_SIZE/2),
					Vector2(TILE_SIZE/2, -TILE_SIZE/2),
					Vector2(TILE_SIZE/2, TILE_SIZE/2),
					Vector2(-TILE_SIZE/2, TILE_SIZE/2)
				])
				tile_data.add_collision_polygon(0)
				tile_data.set_collision_polygon_points(0, 0, collision_polygon)
			
			# Set terrain type for autotiling (optional)
			tile_data.terrain_set = 0
			tile_data.terrain = terrain_id
	
	# Add physics layer
	tileset.add_physics_layer()
	tileset.set_physics_layer_collision_layer(0, 1)
	
	# Add terrain set for autotiling
	tileset.add_terrain_set()
	tileset.set_terrain_set_mode(0, TileSet.TERRAIN_MODE_MATCH_CORNERS_AND_SIDES)
	
	# Add individual terrains
	for terrain_id in range(TERRAIN_TYPES):
		tileset.add_terrain(0)
		tileset.set_terrain_name(0, terrain_id, get_terrain_name(terrain_id))
		tileset.set_terrain_color(0, terrain_id, TERRAIN_COLORS[terrain_id])
	
	# Add the atlas source to the tileset
	tileset.add_source(atlas_source, 0)
	
	DebugLogger.info("TileSet generation complete!")
	return tileset

func create_terrain_atlas() -> ImageTexture:
	# Load the pre-generated enhanced texture atlas
	var enhanced_texture_path = "res://assets/enhanced_terrain_atlas.png"
	var enhanced_texture = load(enhanced_texture_path) as Texture2D
	
	if enhanced_texture and enhanced_texture is ImageTexture:
		DebugLogger.info(str("Using enhanced terrain atlas from: ") + " " + str(enhanced_texture_path))
		return enhanced_texture
	
	# Fallback: Create atlas with detailed patterns if enhanced version not found
	DebugLogger.info(str("Enhanced atlas not found, generating detailed patterns..."))
	var atlas_width = 8 * TILE_SIZE  # 8 tiles wide
	var atlas_height = 2 * TILE_SIZE  # 2 tiles high (for 14 terrain types)
	
	var image = Image.create(atlas_width, atlas_height, false, Image.FORMAT_RGBA8)
	image.fill(Color.MAGENTA)  # Default color for unused areas
	
	# Draw each terrain tile with detailed patterns
	for terrain_id in range(TERRAIN_TYPES):
		var x = (terrain_id % 8) * TILE_SIZE
		var y = int(terrain_id / 8) * TILE_SIZE
		
		# Create detailed terrain tile pattern
		create_terrain_tile_pattern(image, terrain_id, x, y)
	
	# Create texture from image
	var texture = ImageTexture.new()
	texture.set_image(image)
	return texture

func create_terrain_tile_pattern(image: Image, terrain_id: int, start_x: int, start_y: int):
	var base_color = TERRAIN_COLORS[terrain_id]
	
	match terrain_id:
		0: # GRASS - Green with darker grass blades
			create_grass_pattern(image, start_x, start_y, base_color)
		1: # DIRT - Brown with texture
			create_dirt_pattern(image, start_x, start_y, base_color)
		2: # STONE - Gray with rock texture
			create_stone_pattern(image, start_x, start_y, base_color)
		3: # WATER - Blue with wave pattern
			create_water_pattern(image, start_x, start_y, base_color)
		4: # TREE - Green with trunk
			create_tree_pattern(image, start_x, start_y, base_color)
		5: # MOUNTAIN - Gray with peaks
			create_mountain_pattern(image, start_x, start_y, base_color)
		6: # VALLEY - Light green with rolling hills
			create_valley_pattern(image, start_x, start_y, base_color)
		7: # RIVER - Flowing water pattern
			create_river_pattern(image, start_x, start_y, base_color)
		8: # LAKE - Calm water with reflections
			create_lake_pattern(image, start_x, start_y, base_color)
		9: # OCEAN - Deep water with foam
			create_ocean_pattern(image, start_x, start_y, base_color)
		10: # FOREST - Dense tree pattern
			create_forest_pattern(image, start_x, start_y, base_color)
		11: # HILLS - Rolling terrain
			create_hills_pattern(image, start_x, start_y, base_color)
		12: # BEACH - Sand with shells/stones
			create_beach_pattern(image, start_x, start_y, base_color)
		13: # SWAMP - Murky with vegetation
			create_swamp_pattern(image, start_x, start_y, base_color)
		14: # TOWN - Medieval buildings
			create_town_pattern(image, start_x, start_y, base_color)
		_:
			# Default: solid color
			fill_tile_solid(image, start_x, start_y, base_color)

func fill_tile_solid(image: Image, start_x: int, start_y: int, color: Color):
	for px in range(TILE_SIZE):
		for py in range(TILE_SIZE):
			image.set_pixel(start_x + px, start_y + py, color)

func fill_tile_transparent(image: Image, start_x: int, start_y: int):
	for px in range(TILE_SIZE):
		for py in range(TILE_SIZE):
			image.set_pixel(start_x + px, start_y + py, Color(0, 0, 0, 0))

func create_grass_pattern(image: Image, start_x: int, start_y: int, base_color: Color):
	# Fill with base grass color
	fill_tile_solid(image, start_x, start_y, base_color)
	
	# Add darker grass blades as vertical lines
	var dark_green = base_color.darkened(0.3)
	for i in range(0, TILE_SIZE, 4):
		for j in range(0, TILE_SIZE, 6):
			if start_x + i < image.get_width() and start_y + j + 1 < image.get_height():
				image.set_pixel(start_x + i, start_y + j, dark_green)
				if j + 1 < TILE_SIZE:
					image.set_pixel(start_x + i, start_y + j + 1, dark_green)

func create_dirt_pattern(image: Image, start_x: int, start_y: int, base_color: Color):
	# Fill with base dirt color
	fill_tile_solid(image, start_x, start_y, base_color)
	
	# Add darker patches for texture
	var dark_dirt = base_color.darkened(0.4)
	var light_dirt = base_color.lightened(0.2)
	
	# Random-looking dirt patches
	for i in range(0, TILE_SIZE, 3):
		for j in range(0, TILE_SIZE, 3):
			if (i + j) % 7 == 0:
				if start_x + i < image.get_width() and start_y + j < image.get_height():
					image.set_pixel(start_x + i, start_y + j, dark_dirt)
			elif (i + j) % 11 == 0:
				if start_x + i < image.get_width() and start_y + j < image.get_height():
					image.set_pixel(start_x + i, start_y + j, light_dirt)

func create_stone_pattern(image: Image, start_x: int, start_y: int, base_color: Color):
	# Fill with base stone color
	fill_tile_solid(image, start_x, start_y, base_color)
	
	# Add cracks and texture
	var dark_stone = base_color.darkened(0.5)
	var light_stone = base_color.lightened(0.3)
	
	# Horizontal cracks
	for i in range(2, TILE_SIZE-2, 8):
		for j in range(0, TILE_SIZE):
			if start_x + j < image.get_width() and start_y + i < image.get_height():
				image.set_pixel(start_x + j, start_y + i, dark_stone)
	
	# Vertical cracks
	for i in range(0, TILE_SIZE):
		for j in range(3, TILE_SIZE-3, 10):
			if start_x + j < image.get_width() and start_y + i < image.get_height():
				image.set_pixel(start_x + j, start_y + i, dark_stone)
	
	# Light highlights
	for i in range(1, TILE_SIZE, 6):
		for j in range(1, TILE_SIZE, 6):
			if start_x + j < image.get_width() and start_y + i < image.get_height():
				image.set_pixel(start_x + j, start_y + i, light_stone)

func create_water_pattern(image: Image, start_x: int, start_y: int, base_color: Color):
	# Fill with base water color
	fill_tile_solid(image, start_x, start_y, base_color)
	
	# Add wave patterns
	var light_water = base_color.lightened(0.4)
	var dark_water = base_color.darkened(0.3)
	
	# Horizontal wave lines
	for i in range(0, TILE_SIZE):
		for j in range(0, TILE_SIZE):
			var wave = sin((i + j) * 0.5) * 0.3
			if wave > 0.1:
				if start_x + j < image.get_width() and start_y + i < image.get_height():
					image.set_pixel(start_x + j, start_y + i, light_water)
			elif wave < -0.1:
				if start_x + j < image.get_width() and start_y + i < image.get_height():
					image.set_pixel(start_x + j, start_y + i, dark_water)

func create_tree_pattern(image: Image, start_x: int, start_y: int, base_color: Color):
	# Fill with base tree color (green foliage)
	fill_tile_solid(image, start_x, start_y, base_color)
	
	# Add brown trunk in center
	var trunk_color = Color(0.4, 0.2, 0.1)
	var trunk_x = TILE_SIZE / 2 - 2
	var trunk_y_start = TILE_SIZE * 3 / 4
	
	for i in range(4):
		for j in range(trunk_y_start, TILE_SIZE):
			if start_x + trunk_x + i < image.get_width() and start_y + j < image.get_height():
				image.set_pixel(start_x + trunk_x + i, start_y + j, trunk_color)
	
	# Add darker foliage patches
	var dark_leaves = base_color.darkened(0.4)
	for i in range(0, TILE_SIZE, 4):
		for j in range(0, trunk_y_start, 5):
			if (i + j) % 6 == 0:
				if start_x + i < image.get_width() and start_y + j < image.get_height():
					image.set_pixel(start_x + i, start_y + j, dark_leaves)

func create_mountain_pattern(image: Image, start_x: int, start_y: int, base_color: Color):
	# Fill with base mountain color
	fill_tile_solid(image, start_x, start_y, base_color)
	
	# Create mountain peaks
	var dark_mountain = base_color.darkened(0.4)
	var light_mountain = base_color.lightened(0.3)
	
	# Draw triangular peaks
	for peak in range(2):
		var peak_x = (peak + 1) * TILE_SIZE / 3
		var peak_height = TILE_SIZE / 4
		
		for i in range(peak_height):
			for j in range(-i, i + 1):
				var px = peak_x + j
				var py = peak_height - i
				if px >= 0 and px < TILE_SIZE and py >= 0 and py < TILE_SIZE:
					if start_x + px < image.get_width() and start_y + py < image.get_height():
						if j < 0:
							image.set_pixel(start_x + px, start_y + py, light_mountain)
						else:
							image.set_pixel(start_x + px, start_y + py, dark_mountain)

func create_valley_pattern(image: Image, start_x: int, start_y: int, base_color: Color):
	create_grass_pattern(image, start_x, start_y, base_color)

func create_river_pattern(image: Image, start_x: int, start_y: int, base_color: Color):
	create_water_pattern(image, start_x, start_y, base_color)

func create_lake_pattern(image: Image, start_x: int, start_y: int, base_color: Color):
	create_water_pattern(image, start_x, start_y, base_color)

func create_ocean_pattern(image: Image, start_x: int, start_y: int, base_color: Color):
	create_water_pattern(image, start_x, start_y, base_color)

func create_forest_pattern(image: Image, start_x: int, start_y: int, base_color: Color):
	# Dense forest - darker base with multiple tree elements
	var forest_base = base_color.darkened(0.2)
	fill_tile_solid(image, start_x, start_y, forest_base)
	
	# Add multiple small trees
	var dark_leaves = base_color.darkened(0.5)
	for i in range(0, TILE_SIZE, 6):
		for j in range(0, TILE_SIZE, 6):
			if start_x + i + 2 < image.get_width() and start_y + j + 2 < image.get_height():
				image.set_pixel(start_x + i + 1, start_y + j + 1, dark_leaves)
				image.set_pixel(start_x + i + 2, start_y + j + 1, dark_leaves)
				image.set_pixel(start_x + i + 1, start_y + j + 2, dark_leaves)

func create_hills_pattern(image: Image, start_x: int, start_y: int, base_color: Color):
	# Fill with base color
	fill_tile_solid(image, start_x, start_y, base_color)
	
	# Add rolling hill shading
	var dark_hill = base_color.darkened(0.3)
	var light_hill = base_color.lightened(0.2)
	
	for i in range(TILE_SIZE):
		for j in range(TILE_SIZE):
			var height = sin(i * 0.3) * 0.5 + sin(j * 0.4) * 0.3
			if height > 0.2:
				if start_x + j < image.get_width() and start_y + i < image.get_height():
					image.set_pixel(start_x + j, start_y + i, light_hill)
			elif height < -0.2:
				if start_x + j < image.get_width() and start_y + i < image.get_height():
					image.set_pixel(start_x + j, start_y + i, dark_hill)

func create_beach_pattern(image: Image, start_x: int, start_y: int, base_color: Color):
	# Fill with sandy base
	fill_tile_solid(image, start_x, start_y, base_color)
	
	# Add small stones/shells
	var stone_color = Color.GRAY
	var shell_color = Color.WHITE
	
	for i in range(0, TILE_SIZE, 8):
		for j in range(0, TILE_SIZE, 7):
			if (i + j) % 13 == 0:
				if start_x + i < image.get_width() and start_y + j < image.get_height():
					image.set_pixel(start_x + i, start_y + j, stone_color)
			elif (i + j) % 17 == 0:
				if start_x + i < image.get_width() and start_y + j < image.get_height():
					image.set_pixel(start_x + i, start_y + j, shell_color)

func create_swamp_pattern(image: Image, start_x: int, start_y: int, base_color: Color):
	# Murky swamp base
	fill_tile_solid(image, start_x, start_y, base_color)
	
	# Add darker water patches
	var dark_water = Color(0.1, 0.3, 0.1)
	var vegetation = Color(0.2, 0.4, 0.1)
	
	# Water patches
	for i in range(2, TILE_SIZE-2, 6):
		for j in range(2, TILE_SIZE-2, 5):
			if start_x + j < image.get_width() and start_y + i < image.get_height():
				image.set_pixel(start_x + j, start_y + i, dark_water)
				if j + 1 < TILE_SIZE:
					image.set_pixel(start_x + j + 1, start_y + i, dark_water)
	
	# Vegetation spots
	for i in range(0, TILE_SIZE, 7):
		for j in range(0, TILE_SIZE, 8):
			if (i + j) % 9 == 0:
				if start_x + j < image.get_width() and start_y + i < image.get_height():
					image.set_pixel(start_x + j, start_y + i, vegetation)

func create_town_pattern(image: Image, start_x: int, start_y: int, base_color: Color):
	# Fill with transparent background first
	fill_tile_transparent(image, start_x, start_y)
	
	# Color palette for detailed town sprite
	var colors = {
		"stone": Color(0.6, 0.6, 0.65),      # Light gray stone
		"roof": Color(0.7, 0.3, 0.2),        # Red-brown roof
		"wood": Color(0.5, 0.3, 0.1),        # Brown wood
		"window": Color(0.9, 0.9, 0.4),      # Yellow window light
		"door": Color(0.3, 0.2, 0.1),        # Dark brown door
		"chimney": Color(0.4, 0.4, 0.4),     # Dark gray chimney
		"smoke": Color(0.8, 0.8, 0.8, 0.6),  # Light gray smoke
		"detail": Color(0.8, 0.8, 0.8)       # Light details
	}
	
	# Draw smoke from chimney (top)
	_draw_town_pixel(image, start_x, start_y, 11, 12, colors["smoke"])
	_draw_town_pixel(image, start_x, start_y, 12, 13, colors["smoke"])
	_draw_town_pixel(image, start_x, start_y, 10, 14, colors["smoke"])
	
	# Main building roof (triangular)
	for y in range(12, 18):
		var roof_width = (y - 12) + 1
		var center_x = 7
		for x in range(center_x - roof_width/2, center_x + roof_width/2 + 1):
			_draw_town_pixel(image, start_x, start_y, x, y, colors["roof"])
	
	# Tower roof (pointed)
	for y in range(4, 12):
		var roof_width = (y - 4) + 1
		var center_x = 18
		for x in range(center_x - roof_width/2, center_x + roof_width/2 + 1):
			_draw_town_pixel(image, start_x, start_y, x, y, colors["roof"])
	
	# Small building roof
	for y in range(11, 16):
		var roof_width = (y - 11) + 1
		var center_x = 12
		for x in range(center_x - roof_width/2, center_x + roof_width/2 + 1):
			_draw_town_pixel(image, start_x, start_y, x, y, colors["roof"])
	
	# Chimney
	_draw_town_rect(image, start_x, start_y, 10, 15, 2, 5, colors["chimney"])
	
	# Main building walls
	_draw_town_rect(image, start_x, start_y, 2, 18, 12, 12, colors["stone"])
	
	# Tower walls  
	_draw_town_rect(image, start_x, start_y, 14, 12, 8, 18, colors["stone"])
	
	# Small building walls
	_draw_town_rect(image, start_x, start_y, 8, 16, 8, 10, colors["wood"])
	
	# Windows on main building
	_draw_town_rect(image, start_x, start_y, 4, 22, 2, 3, colors["window"])
	_draw_town_rect(image, start_x, start_y, 8, 22, 2, 3, colors["window"])
	
	# Windows on tower
	_draw_town_rect(image, start_x, start_y, 16, 16, 2, 2, colors["window"])
	_draw_town_rect(image, start_x, start_y, 19, 20, 2, 2, colors["window"])
	
	# Door on main building
	_draw_town_rect(image, start_x, start_y, 6, 26, 2, 4, colors["door"])

func _draw_town_pixel(image: Image, start_x: int, start_y: int, x: int, y: int, color: Color):
	var px = start_x + x
	var py = start_y + y
	if px >= 0 and px < image.get_width() and py >= 0 and py < image.get_height():
		image.set_pixel(px, py, color)

func _draw_town_rect(image: Image, start_x: int, start_y: int, x: int, y: int, width: int, height: int, color: Color):
	for py in range(y, y + height):
		for px in range(x, x + width):
			_draw_town_pixel(image, start_x, start_y, px, py, color)

func get_terrain_name(terrain_id: int) -> String:
	match terrain_id:
		0: return "Grass"
		1: return "Dirt"
		2: return "Stone"
		3: return "Water"
		4: return "Tree"
		5: return "Mountain"
		6: return "Valley"
		7: return "River"
		8: return "Lake"
		9: return "Ocean"
		10: return "Forest"
		11: return "Hills"
		12: return "Beach"
		13: return "Swamp"
		14: return "Town"
		_: return "Unknown"

func save_tileset_to_file(tileset: TileSet, filepath: String):
	var result = ResourceSaver.save(tileset, filepath)
	if result == OK:
		DebugLogger.info(str("TileSet saved to: ") + " " + str(filepath))
	else:
		DebugLogger.info(str("Failed to save TileSet: ") + " " + str(result))

# Test function to generate and save the tileset
func _ready():
	DebugLogger.info("=== STARTING ENHANCED TILESET GENERATION ===")
	var tileset = generate_terrain_tileset()
	save_tileset_to_file(tileset, "res://assets/enhanced_terrain_tileset.tres")
	DebugLogger.info("=== ENHANCED TILESET GENERATION COMPLETE! ===")
	DebugLogger.info("Enhanced tileset saved to: assets/enhanced_terrain_tileset.tres")
	# Auto-quit after generation
	get_tree().quit()

func _exit_tree():
	# Clean up any remaining resources
	# Mark script as ready for cleanup
	if has_method("generate_terrain_tileset"):
		# Signal that we're done with this script
		pass

