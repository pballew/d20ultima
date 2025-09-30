extends SceneTree

# Standalone tileset generator script  
# Run with: godot --headless --script generate_enhanced_tileset.gd

const TILE_SIZE = 32
const TERRAIN_TYPES = 15

# Reference to shared terrain colors
const terrain_colors_resource = preload("res://scripts/TerrainColors.gd")
const TERRAIN_COLORS = terrain_colors_resource.TERRAIN_COLORS

func _init():
	DebugLogger.info("=== ENHANCED TILESET GENERATOR ===")
	generate_enhanced_tileset()
	quit()

func generate_enhanced_tileset():
	DebugLogger.info("Creating enhanced terrain tileset...")
	
	# Calculate atlas dimensions
	var atlas_cols = 8
	var atlas_rows = (TERRAIN_TYPES + atlas_cols - 1) / atlas_cols  # Ceiling division
	var atlas_width = atlas_cols * TILE_SIZE
	var atlas_height = atlas_rows * TILE_SIZE
	
	# Create the texture atlas image
	var image = Image.create(atlas_width, atlas_height, false, Image.FORMAT_RGBA8)
	image.fill(Color.TRANSPARENT)
	
	# Generate each terrain tile
	for terrain_type in range(TERRAIN_TYPES):
		var x = (terrain_type % atlas_cols) * TILE_SIZE
		var y = int(terrain_type / atlas_cols) * TILE_SIZE
		var base_color = TERRAIN_COLORS[terrain_type]
		
		create_terrain_pattern(image, Rect2i(x, y, TILE_SIZE, TILE_SIZE), terrain_type, base_color)
	
	# Save the texture
	var texture_path = "res://assets/enhanced_terrain_atlas.png"
	image.save_png(texture_path)
	DebugLogger.info(str("Saved enhanced terrain atlas: ") + " " + str(texture_path))
	DebugLogger.info("=== GENERATION COMPLETE ===")

func create_terrain_pattern(image: Image, rect: Rect2i, terrain_type: int, base_color: Color):
	# Enhanced patterns for each terrain type
	match terrain_type:
		0: # GRASS
			create_grass_pattern(image, rect, base_color)
		1: # DIRT  
			create_dirt_pattern(image, rect, base_color)
		2: # STONE
			create_stone_pattern(image, rect, base_color)
		3: # WATER
			create_water_pattern(image, rect, base_color)
		4: # TREE
			create_tree_pattern(image, rect, base_color)
		_: # Default fallback
			create_default_pattern(image, rect, base_color)

func create_grass_pattern(image: Image, rect: Rect2i, base_color: Color):
	# Fill with base grass color
	image.fill_rect(rect, base_color)
	
	# Add some darker grass strands
	var dark_grass = base_color.darkened(0.3)
	for i in range(8):
		var x = rect.position.x + (i * 4) + 2
		var y = rect.position.y + rect.size.y - 4 + (i % 3)
		if x < rect.position.x + rect.size.x:
			image.set_pixel(x, y, dark_grass)

func create_dirt_pattern(image: Image, rect: Rect2i, base_color: Color):
	# Fill with base dirt color
	image.fill_rect(rect, base_color)
	
	# Add some darker spots for texture
	var dark_dirt = base_color.darkened(0.4)
	for i in range(6):
		var x = rect.position.x + (i * 5) + 1
		var y = rect.position.y + (i * 3) + 2
		if x < rect.position.x + rect.size.x - 1 and y < rect.position.y + rect.size.y - 1:
			image.set_pixel(x, y, dark_dirt)
			image.set_pixel(x + 1, y, dark_dirt)

func create_stone_pattern(image: Image, rect: Rect2i, base_color: Color):
	# Fill with base stone color
	image.fill_rect(rect, base_color)
	
	# Add some lighter highlights and darker cracks
	var light_stone = base_color.lightened(0.3)
	var dark_stone = base_color.darkened(0.4)
	
	# Horizontal cracks
	for x in range(rect.position.x + 4, rect.position.x + rect.size.x - 4, 8):
		var y = rect.position.y + rect.size.y / 2
		image.set_pixel(x, y, dark_stone)
		image.set_pixel(x + 1, y, dark_stone)
	
	# Highlights
	for i in range(3):
		var x = rect.position.x + i * 10 + 2
		var y = rect.position.y + i * 8 + 3
		if x < rect.position.x + rect.size.x and y < rect.position.y + rect.size.y:
			image.set_pixel(x, y, light_stone)

func create_water_pattern(image: Image, rect: Rect2i, base_color: Color):
	# Fill with base water color
	image.fill_rect(rect, base_color)
	
	# Add some wave-like patterns with lighter blue
	var light_water = base_color.lightened(0.2)
	for y in range(rect.position.y + 4, rect.position.y + rect.size.y - 4, 8):
		for x in range(rect.position.x + 2, rect.position.x + rect.size.x - 2, 4):
			if (x + y) % 8 < 4:
				image.set_pixel(x, y, light_water)

func create_tree_pattern(image: Image, rect: Rect2i, base_color: Color):
	# Fill with base tree color
	image.fill_rect(rect, base_color)
	
	# Add a simple trunk in brown
	var trunk_color = Color(0.4, 0.2, 0.1)
	var trunk_x = rect.position.x + rect.size.x / 2
	for y in range(rect.position.y + rect.size.y - 8, rect.position.y + rect.size.y):
		image.set_pixel(trunk_x, y, trunk_color)
		image.set_pixel(trunk_x + 1, y, trunk_color)

func create_default_pattern(image: Image, rect: Rect2i, base_color: Color):
	# Simple checkered pattern for unknown types
	for y in range(rect.position.y, rect.position.y + rect.size.y):
		for x in range(rect.position.x, rect.position.x + rect.size.x):
			if (x + y) % 4 < 2:
				image.set_pixel(x, y, base_color)
			else:
				image.set_pixel(x, y, base_color.darkened(0.2))

