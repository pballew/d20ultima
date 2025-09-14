extends TileMap

# Terrain types
enum TerrainType { GRASS, DIRT, STONE, WATER, TREE }

# Tile size (should match your movement grid)
const TILE_SIZE = 32
const MAP_WIDTH = 50
const MAP_HEIGHT = 40

# Simple noise for terrain generation
var noise: FastNoiseLite
var terrain_data: Dictionary = {}

func _ready():
	# Initialize noise
	noise = FastNoiseLite.new()
	noise.seed = randi()
	noise.frequency = 0.1
	noise.noise_type = FastNoiseLite.TYPE_PERLIN
	
	# Wait a frame for tileset to be properly initialized
	await get_tree().process_frame
	generate_terrain()

func generate_terrain():
	# Create a simple terrain map using colored rectangles instead of tileset
	for x in range(MAP_WIDTH):
		for y in range(MAP_HEIGHT):
			var noise_value = noise.get_noise_2d(x, y)
			var terrain_type = get_terrain_type(noise_value)
			var tile_pos = Vector2i(x - MAP_WIDTH/2, y - MAP_HEIGHT/2)
			
			# Store terrain data for collision checking
			terrain_data[tile_pos] = terrain_type
			
			# Try to set the tile, catch any errors
			if tile_set and tile_set.get_source_count() > 0:
				set_cell(0, tile_pos, 0, Vector2i(terrain_type, 0))

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
	var tile_pos = local_to_map(world_pos)
	
	# Check our terrain data first
	if terrain_data.has(tile_pos):
		var terrain_type = terrain_data[tile_pos]
		# Water and trees are not walkable
		return terrain_type != TerrainType.WATER and terrain_type != TerrainType.TREE
	
	return true  # Empty tiles are walkable
