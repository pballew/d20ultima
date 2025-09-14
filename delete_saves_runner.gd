extends Node

func _ready():
	print("Starting save deletion process...")
	
	# Access the SaveSystem autoload and delete all characters
	var save_system = SaveSystem
	if save_system:
		var deleted_count = save_system.delete_all_characters()
		print("Successfully deleted all saved characters!")
		print("Total files deleted: ", deleted_count)
	else:
		print("Error: SaveSystem not found!")
	
	# Wait a moment then exit
	await get_tree().create_timer(1.0).timeout
	get_tree().quit()
