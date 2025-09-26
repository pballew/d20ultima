extends SceneTree

func _init():
	print("Loading TileSetGenerator...")
	var generator = preload("res://scripts/TileSetGenerator.gd").new()
	print("Generating enhanced tileset...")
	var tileset = generator.generate_terrain_tileset()
	generator.save_tileset_to_file(tileset, "res://assets/enhanced_terrain_tileset.tres")
	print("Enhanced tileset generation complete!")
	quit()