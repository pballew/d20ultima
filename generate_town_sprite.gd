extends Node

# Script to generate a town sprite
const SPRITE_SIZE := 32

func _ready():
	generate_town_sprite()

func generate_town_sprite():
	DebugLogger.info("Generating town sprite...")
	
	var image = Image.create(SPRITE_SIZE, SPRITE_SIZE, false, Image.FORMAT_RGBA8)
	image.fill(Color(0, 0, 0, 0))  # Transparent background
	
	# Draw the town from side view
	_draw_town(image)
	
	# Save the sprite to user directory first, then copy to project
	var user_path = "user://town_sprite.png"
	image.save_png(user_path)
	
	# Also try to save directly to project assets
	var path = "res://assets/sprites/town_sprite.png"
	var file = FileAccess.open(path, FileAccess.WRITE)
	if file:
		var user_file = FileAccess.open(user_path, FileAccess.READ)
		if user_file:
			var data = user_file.get_buffer(user_file.get_length())
			file.store_buffer(data)
			user_file.close()
		file.close()
		DebugLogger.info("Sprite saved to project assets")
	else:
		DebugLogger.info(str("Could not save to project assets, saved to user directory only"))
	
	DebugLogger.info(str("Town sprite saved to: ") + " " + str(path))
	
	# Also create texture and show it
	var texture = ImageTexture.new()
	texture.set_image(image)
	
	# Create a simple scene to display the sprite
	_show_sprite(texture)
	
	DebugLogger.info("Town sprite generation complete!")

func _draw_town(image: Image):
	# Color palette for the town
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
	
	# Main building base (left side)
	_draw_rectangle(image, 2, 18, 12, 12, colors["stone"])
	
	# Main building roof (triangular)
	_draw_triangle_roof(image, 2, 18, 12, 6, colors["roof"])
	
	# Taller tower (right side)
	_draw_rectangle(image, 14, 12, 8, 18, colors["stone"])
	
	# Tower roof (pointed)
	_draw_triangle_roof(image, 14, 12, 8, 8, colors["roof"])
	
	# Small building (center-back)
	_draw_rectangle(image, 8, 16, 8, 10, colors["wood"])
	_draw_triangle_roof(image, 8, 16, 8, 5, colors["roof"])
	
	# Windows on main building
	_draw_rectangle(image, 4, 22, 2, 3, colors["window"])
	_draw_rectangle(image, 8, 22, 2, 3, colors["window"])
	
	# Windows on tower
	_draw_rectangle(image, 16, 16, 2, 2, colors["window"])
	_draw_rectangle(image, 19, 20, 2, 2, colors["window"])
	
	# Door on main building
	_draw_rectangle(image, 6, 26, 2, 4, colors["door"])
	
	# Chimney on main building
	_draw_rectangle(image, 10, 15, 2, 5, colors["chimney"])
	
	# Smoke from chimney
	_draw_pixel_if_valid(image, 11, 14, colors["smoke"])
	_draw_pixel_if_valid(image, 12, 13, colors["smoke"])
	_draw_pixel_if_valid(image, 10, 12, colors["smoke"])
	
	# Add some architectural details
	# Stone outline on main building
	_draw_outline(image, 2, 18, 12, 12, colors["detail"])
	# Stone outline on tower
	_draw_outline(image, 14, 12, 8, 18, colors["detail"])

func _draw_rectangle(image: Image, x: int, y: int, width: int, height: int, color: Color):
	for px in range(x, x + width):
		for py in range(y, y + height):
			_draw_pixel_if_valid(image, px, py, color)

func _draw_triangle_roof(image: Image, x: int, y: int, width: int, height: int, color: Color):
	var center_x = x + width / 2
	for py in range(y - height, y):
		var roof_y = py
		var distance_from_top = abs(roof_y - (y - height))
		var roof_width = (distance_from_top * width) / height
		var start_x = center_x - roof_width / 2
		var end_x = center_x + roof_width / 2
		
		for px in range(start_x, end_x + 1):
			_draw_pixel_if_valid(image, px, roof_y, color)

func _draw_outline(image: Image, x: int, y: int, width: int, height: int, color: Color):
	# Top and bottom lines
	for px in range(x, x + width):
		_draw_pixel_if_valid(image, px, y, color)
		_draw_pixel_if_valid(image, px, y + height - 1, color)
	
	# Left and right lines
	for py in range(y, y + height):
		_draw_pixel_if_valid(image, x, py, color)
		_draw_pixel_if_valid(image, x + width - 1, py, color)

func _draw_pixel_if_valid(image: Image, x: int, y: int, color: Color):
	if x >= 0 and x < SPRITE_SIZE and y >= 0 and y < SPRITE_SIZE:
		image.set_pixel(x, y, color)

func _show_sprite(texture: ImageTexture):
	DebugLogger.info("Town sprite texture created successfully!")
	DebugLogger.info(str("Sprite size: ") + " " + str(texture.get_size()))
	
	# Exit after generating
	get_tree().call_deferred("quit")

