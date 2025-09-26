extends Node2D

## Overlay that draws a small dot at the center of every generated terrain tile.
## Works with either EnhancedTerrain (sprite-based) or EnhancedTerrainTileMap (TileMap-based)
@export var dot_color: Color = Color(1, 1, 1, 0.45)
@export var dot_size: int = 3  # Pixel size of each dot
@export var max_dots: int = 0  # 0 = no limit; can be used to throttle for performance tests

var terrain_ref: Node
var dot_points: Array[Vector2] = []

func _ready():
	# Attempt to locate the terrain node (it may still be named EnhancedTerrainTileMap for compatibility)
	terrain_ref = get_tree().get_root().find_child("EnhancedTerrainTileMap", true, false)
	if not terrain_ref:
		terrain_ref = get_tree().get_root().find_child("EnhancedTerrain", true, false)
	if terrain_ref and terrain_ref.has_signal("sections_generated"):
		terrain_ref.sections_generated.connect(_on_sections_generated)
	# Build immediately (in case generation already finished before we were added)
	build_points()
	queue_redraw()
	set_process_input(true)

func _on_sections_generated():
	build_points()
	queue_redraw()

func build_points():
	dot_points.clear()
	if not terrain_ref:
		return
	var tile_size := 32
	if "TILE_SIZE" in terrain_ref:
		tile_size = terrain_ref.TILE_SIZE

	# Try to use map_sections if present (both implementations expose it)
	if not ("map_sections" in terrain_ref):
		return

	var count := 0
	for section_id in terrain_ref.map_sections.keys():
		var section = terrain_ref.map_sections[section_id]
		if not section:
			continue
		# Section stores terrain_data differently between implementations but key iteration is the same
		if not ("terrain_data" in section):
			continue
		var terrain_dict = section.terrain_data
		for local_pos in terrain_dict.keys():
			var global_tile: Vector2i
			if terrain_ref.has_method("world_to_global_tile"):
				# EnhancedTerrain version
				global_tile = terrain_ref.world_to_global_tile(local_pos, section_id)
			else:
				# Fallback: assume local_pos already global (unlikely)
				global_tile = local_pos
			var center = Vector2(global_tile.x * tile_size + tile_size * 0.5, global_tile.y * tile_size + tile_size * 0.5)
			dot_points.append(center)
			count += 1
			if max_dots > 0 and count >= max_dots:
				return
	print("TileCentersOverlay: built", dot_points.size(), "dots from", terrain_ref.map_sections.size(), "sections")

func _draw():
	if dot_size <= 0:
		return
	var half = dot_size * 0.5
	for p in dot_points:
		draw_rect(Rect2(p - Vector2(half, half), Vector2(dot_size, dot_size)), dot_color, true)

func _input(event):
	if event is InputEventKey and event.pressed:
		# Toggle overlay visibility with F9
		if event.keycode == KEY_F9:
			visible = not visible
			print("TileCentersOverlay visibility:", visible)
		# Rebuild with F10 (debug)
		elif event.keycode == KEY_F10:
			build_points()
			queue_redraw()
			print("TileCentersOverlay rebuilt (", dot_points.size(), " dots)")
