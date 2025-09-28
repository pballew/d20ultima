extends SceneTree

func _initialize():
	print("Starting monster sprite generation...")
	
	# Load Main script to access monster creation functions
	var main_script = load("res://scripts/Main.gd")
	if not main_script:
		print("ERROR: Could not load Main.gd script")
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
				print("Generated sprite: ", file_path)
				generated_count += 1
			else:
				print("ERROR: Failed to save ", file_path, " - Error code: ", error)
		else:
			print("ERROR: Failed to create texture for ", monster_name)
	
	print("Monster sprite generation complete! Generated ", generated_count, " sprites.")
	quit()