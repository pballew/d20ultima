extends Node

# Create a simple terrain texture programmatically
func create_terrain_texture() -> ImageTexture:
	var image = Image.create(160, 32, false, Image.FORMAT_RGB8)
	
	# Define colors for each terrain type
	var colors = [
		Color.GREEN,        # Grass
		Color(0.6, 0.4, 0.2), # Dirt (brown)
		Color.GRAY,         # Stone
		Color.BLUE,         # Water
		Color(0.2, 0.4, 0.1)  # Tree (dark green)
	]
	
	# Fill each 32x32 tile with its color
	for i in range(5):
		var start_x = i * 32
		for x in range(32):
			for y in range(32):
				image.set_pixel(start_x + x, y, colors[i])
	
	var texture = ImageTexture.new()
	texture.set_image(image)
	return texture
