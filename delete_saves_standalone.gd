extends SceneTree

func _init():
	DebugLogger.info("Deleting all saved characters and save data (standalone)...")
	var characters_deleted := 0
	var char_dir_path := "user://characters/"

	# Delete character files
	if DirAccess.dir_exists_absolute(char_dir_path):
		var dir := DirAccess.open(char_dir_path)
		if dir:
			dir.list_dir_begin()
			var file_name := dir.get_next()
			while file_name != "":
				if not file_name.begins_with(".") and file_name.ends_with(".tres"):
					DebugLogger.info(str("Deleting character file: ") + " " + str(file_name))
					dir.remove(file_name)
					characters_deleted += 1
				file_name = dir.get_next()
			dir.list_dir_end()
			# Try to remove the directory itself
			var parent_dir := DirAccess.open("user://")
			if parent_dir:
				parent_dir.remove("characters/")

	# Delete main save file
	var save_file := "user://game_save.dat"
	if FileAccess.file_exists(save_file):
		DebugLogger.info(str("Deleting main save file: ") + " " + str(save_file))
		var parent := DirAccess.open("user://")
		if parent:
			parent.remove("game_save.dat")

	DebugLogger.info(str("Deleted ") + " " + str(characters_deleted) + " " + str(" character files and main save data (if present))")
	quit()


