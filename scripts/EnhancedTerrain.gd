extends Node2D

# Enhanced terrain system with pixel art and animations
const TILE_SIZE = 32
const MAP_WIDTH = 50
const MAP_HEIGHT = 40

# Terrain types
enum TerrainType { 
	GRASS, DIRT, STONE, WATER, TREE, 
	MOUNTAIN, VALLEY, RIVER, LAKE, OCEAN,
	FOREST, HILLS, BEACH, SWAMP
}

var terrain_data: Dictionary = {}
var noise: FastNoiseLite
var moisture_noise: FastNoiseLite
var elevation_noise: FastNoiseLite

# Animated terrain nodes
var animated_waters: Array = []

func _ready():
	# Initialize multiple noise layers for complex terrain
	noise = FastNoiseLite.new()
	noise.seed = randi()
	noise.frequency = 0.1
	noise.noise_type = FastNoiseLite.TYPE_PERLIN
	
	moisture_noise = FastNoiseLite.new()
	moisture_noise.seed = randi() + 1000
	moisture_noise.frequency = 0.05
	moisture_noise.noise_type = FastNoiseLite.TYPE_SIMPLEX
	
	elevation_noise = FastNoiseLite.new()
	elevation_noise.seed = randi() + 2000
	elevation_noise.frequency = 0.08
	elevation_noise.noise_type = FastNoiseLite.TYPE_SIMPLEX_SMOOTH
	
	generate_enhanced_terrain()
	ensure_safe_spawn_area()

func ensure_safe_spawn_area():
	# Ensure there's always a 5x5 area of walkable terrain around world center
	var spawn_radius = 3  # 7x7 area around center
	for x in range(-spawn_radius, spawn_radius + 1):
		for y in range(-spawn_radius, spawn_radius + 1):
			var tile_pos = Vector2i(x, y)
			
			# Create a mix of grass and dirt in spawn area
			var spawn_terrain = TerrainType.GRASS if (x + y) % 2 == 0 else TerrainType.DIRT
			
			# Force walkable terrain in spawn area
			terrain_data[tile_pos] = spawn_terrain
			
			# Remove any existing sprite at this position
			var world_pos = Vector2(tile_pos.x * TILE_SIZE, tile_pos.y * TILE_SIZE)
			for child in get_children():
				if child.position == world_pos:
					child.queue_free()
			
			# Create new walkable terrain sprite
			create_basic_terrain(world_pos, spawn_terrain)

func generate_enhanced_terrain():
	# Create terrain with elevation and moisture consideration
	for x in range(MAP_WIDTH):
		for y in range(MAP_HEIGHT):
			var world_x = x - MAP_WIDTH/2
			var world_y = y - MAP_HEIGHT/2
			
			var elevation = elevation_noise.get_noise_2d(x, y)
			var moisture = moisture_noise.get_noise_2d(x, y)
			var base_noise = noise.get_noise_2d(x, y)
			
			var terrain_type = determine_terrain_type(elevation, moisture, base_noise)
			var tile_pos = Vector2i(world_x, world_y)
			
			# Store terrain data for collision checking
			terrain_data[tile_pos] = terrain_type
			
			# Create visual representation
			create_terrain_sprite(tile_pos, terrain_type)

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
	# width/height are inclusive tile span, so add 1
	return Rect2i(Vector2i(min_x, min_y), Vector2i(max_x - min_x + 1, max_y - min_y + 1))
