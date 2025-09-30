extends SceneTree

func _initialize():
	DebugLogger.info("Starting sprite generation...")
	
	# Load and create the factory
	var factory_script = load("res://scripts/PlayerIconFactory.gd")
	if factory_script:
		var factory = factory_script.new()
		if factory.has_method("export_all_player_sprites"):
			var count = factory.export_all_player_sprites()
			DebugLogger.info("Generated %s sprite files!" % count)
		else:
			DebugLogger.warn("Factory missing export method")
	else:
		DebugLogger.error("Could not load PlayerIconFactory script")
	
	# Exit after generation
	quit()
