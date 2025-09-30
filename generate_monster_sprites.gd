extends SceneTree

func _initialize():
	DebugLogger.info("Starting monster sprite generation...")
	
	# Load Main script to access monster creation functions
	var main_script = load("res://scripts/Main.gd")
	if not main_script:
		DebugLogger.error("ERROR: Could not load Main.gd script")
		quit()
		return
	
	var main_instance = main_script.new()
	
	# List of all monsters defined in the game
	var monster_names = [
		"Goblin",
		"Kobold", 
		"Human Skeleton",
		"Zombie",
		"Wolf",
		"Giant Rat",
		"Orc",
		"Hobgoblin",
		"Gnoll",
		"Stirge",
		"Dire Wolf",
		"Black Bear",
		"Ogre",
		"Lizardfolk",
		"Bandit"
	]
	
	var generated_count = 0
	
	# Create sprites directory if it doesn't exist
	var dir = DirAccess.open("res://")
	if not dir.dir_exists("assets/monster_sprites"):
		dir.make_dir_recursive("assets/monster_sprites")
	
	# Generate sprites for each monster
	for monster_name in monster_names:
		var texture = main_instance.create_monster_texture(monster_name)
		if texture:
			var image = texture.get_image()
			var file_name = monster_name.replace(" ", "_").to_lower() + ".png"
			var file_path = "res://assets/monster_sprites/" + file_name
			
			# Save the image
			var error = image.save_png(file_path)
			if error == OK:
				DebugLogger.info(str("Generated sprite: ") + " " + str(file_path))
				generated_count += 1
			else:
				DebugLogger.error(str("ERROR: Failed to save ") + " " + str(file_path) + " " + str(" - Error code: ") + " " + str(error))
		else:
			DebugLogger.error(str("ERROR: Failed to create texture for ") + " " + str(monster_name))
	
	DebugLogger.info(str("Monster sprite generation complete! Generated ") + " " + str(generated_count) + " " + str(" sprites."))
	quit()

