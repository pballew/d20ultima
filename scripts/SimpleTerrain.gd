extends Node2D

# Simple visual terrain system using ColorRect nodes
const TILE_SIZE = 32
const MAP_WIDTH = 50
const MAP_HEIGHT = 40

# Terrain types
enum TerrainType { GRASS, DIRT, STONE, WATER, TREE }

var terrain_data: Dictionary = {}
var noise: FastNoiseLite

func _ready():
	# Initialize noise
	noise = FastNoiseLite.new()
	noise.seed = randi()
	noise.frequency = 0.1
	noise.noise_type = FastNoiseLite.TYPE_PERLIN
	
	generate_visual_terrain()

func generate_visual_terrain():
	# Define colors for each terrain type
	var colors = {
		TerrainType.GRASS: Color.GREEN,
		TerrainType.DIRT: Color(0.6, 0.4, 0.2),
		TerrainType.STONE: Color.GRAY,
		TerrainType.WATER: Color.BLUE,
		TerrainType.TREE: Color(0.2, 0.4, 0.1)
	}
	
	# Create visual terrain tiles
	for x in range(MAP_WIDTH):
		for y in range(MAP_HEIGHT):
			var noise_value = noise.get_noise_2d(x, y)
			var terrain_type = get_terrain_type(noise_value)
			var tile_pos = Vector2i(x - MAP_WIDTH/2, y - MAP_HEIGHT/2)
			
			# Store terrain data for collision checking
			terrain_data[tile_pos] = terrain_type
			
			# Create visual tile
			var tile_rect = ColorRect.new()
			tile_rect.size = Vector2(TILE_SIZE, TILE_SIZE)
			tile_rect.position = Vector2(tile_pos.x * TILE_SIZE, tile_pos.y * TILE_SIZE)
			tile_rect.color = colors[terrain_type]
			add_child(tile_rect)

func get_terrain_type(noise_value: float) -> int:
	if noise_value < -0.3:
		return TerrainType.WATER
	elif noise_value < -0.1:
		return TerrainType.DIRT
	elif noise_value < 0.2:
		return TerrainType.GRASS
	elif noise_value < 0.4:
		return TerrainType.STONE
	else:
		return TerrainType.TREE

func is_walkable(world_pos: Vector2) -> bool:
	var tile_pos = Vector2i(int(world_pos.x / TILE_SIZE), int(world_pos.y / TILE_SIZE))
	
	# Check our terrain data
	if terrain_data.has(tile_pos):
		var terrain_type = terrain_data[tile_pos]
		# Water and trees are not walkable
		return terrain_type != TerrainType.WATER and terrain_type != TerrainType.TREE
	
	return true  # Empty tiles are walkable
