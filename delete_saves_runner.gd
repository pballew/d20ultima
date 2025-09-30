extends Node

func _ready():
	DebugLogger.info("Starting save deletion process...")
	
	# Access the SaveSystem autoload and delete all characters
	var save_system = SaveSystem
	if save_system:
		var deleted_count = save_system.delete_all_characters()
		DebugLogger.info("Successfully deleted all saved characters!")
		DebugLogger.info(str("Total files deleted: ") + " " + str(deleted_count))
	else:
		DebugLogger.info("Error: SaveSystem not found!")
	
	# Wait a moment then exit
	await get_tree().create_timer(1.0).timeout
	get_tree().quit()


