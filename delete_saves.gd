extends SceneTree

func _init():
	print("Deleting all saved character data...")
	
	# Access the SaveSystem autoload and delete all characters
	var save_system = SaveSystem
	if save_system:
		var deleted_count = save_system.delete_all_characters()
		print("Successfully deleted all saved characters!")
		print("Total files deleted: ", deleted_count)
	else:
		print("Error: SaveSystem not found!")
	
	# Exit immediately
	quit()
