extends SceneTree

func _initialize():
	print("Starting sprite generation...")
	
	# Load and create the factory
	var factory_script = load("res://scripts/PlayerIconFactory.gd")
	if factory_script:
		var factory = factory_script.new()
		if factory.has_method("export_all_player_sprites"):
			var count = factory.export_all_player_sprites()
			print("Generated ", count, " sprite files!")
		else:
			print("Factory missing export method")
	else:
		print("Could not load PlayerIconFactory script")
	
	# Exit after generation
	quit()
