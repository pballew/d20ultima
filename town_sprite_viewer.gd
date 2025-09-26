extends Node

func _ready():
	# Load and display the town sprite
	var sprite_path = "res://assets/sprites/town_sprite.png"
	
	if ResourceLoader.exists(sprite_path):
		var texture = load(sprite_path) as Texture2D
		if texture:
			print("Town sprite loaded successfully!")
			print("Sprite size: ", texture.get_size())
			
			# Create a simple scene to display the sprite
			_create_display_scene(texture)
		else:
			print("Failed to load sprite as texture")
	else:
		print("Sprite file not found at: ", sprite_path)

func _create_display_scene(texture: Texture2D):
	# Create a Control node to hold our display
	var control = Control.new()
	control.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	
	# Create background
	var background = ColorRect.new()
	background.color = Color(0.2, 0.2, 0.3)  # Dark blue background
	background.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	control.add_child(background)
	
	# Create sprite display
	var texture_rect = TextureRect.new()
	texture_rect.texture = texture
	texture_rect.expand_mode = TextureRect.EXPAND_FIT_WIDTH_PROPORTIONAL
	texture_rect.stretch_mode = TextureRect.STRETCH_KEEP_CENTERED
	
	# Center it and make it larger for visibility
	texture_rect.position = Vector2(400, 300)
	texture_rect.size = Vector2(256, 256)  # 8x scale for 32x32 sprite
	control.add_child(texture_rect)
	
	# Add title
	var label = Label.new()
	label.text = "Generated Town Sprite (32x32 scaled to 256x256)"
	label.position = Vector2(350, 250)
	label.add_theme_font_size_override("font_size", 20)
	label.add_theme_color_override("font_color", Color.WHITE)
	control.add_child(label)
	
	# Add instructions
	var instructions = Label.new()
	instructions.text = "Press ESC to close"
	instructions.position = Vector2(450, 580)
	instructions.add_theme_color_override("font_color", Color.LIGHT_GRAY)
	control.add_child(instructions)
	
	# Add to scene
	get_tree().root.add_child(control)
	
	print("Sprite display created! Press ESC in the game window to close.")

func _input(event):
	if event.is_action_pressed("ui_cancel"):
		get_tree().quit()