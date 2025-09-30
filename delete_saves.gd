extends SceneTree

func _init():
	DebugLogger.info("Deleting all saved character data...")
	
	# Access the SaveSystem autoload and delete all characters
	var save_system = SaveSystem
	if save_system:
		var deleted_count = save_system.delete_all_characters()
		DebugLogger.info("Successfully deleted all saved characters!")
		DebugLogger.info(str("Total files deleted: ") + " " + str(deleted_count))
	else:
		DebugLogger.info("Error: SaveSystem not found!")
	
	# Exit immediately
	quit()


