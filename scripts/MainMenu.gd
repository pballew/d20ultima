extends Control

signal start_game(character_data: CharacterData)

@onready var title_label = $CenterContainer/VBoxContainer/TitleLabel
@onready var continue_btn = $CenterContainer/VBoxContainer/ContinueButton
@onready var new_character_btn = $CenterContainer/VBoxContainer/NewCharacterButton
@onready var load_character_btn = $CenterContainer/VBoxContainer/LoadCharacterButton
@onready var quit_btn = $CenterContainer/VBoxContainer/QuitButton
@onready var character_creation = $CharacterCreation
@onready var sprite_container = $SpriteDisplay/SpriteContainer

func _ready():
	# Connect signals
	continue_btn.pressed.connect(_on_continue)
	new_character_btn.pressed.connect(_on_new_character)
	load_character_btn.pressed.connect(_on_load_character)
	quit_btn.pressed.connect(_on_quit)
	
	character_creation.character_created.connect(_on_character_created)
	character_creation.character_loaded.connect(_on_character_loaded)
	
	# Generate and display all player sprites
	display_all_player_sprites()
	
	# Show main menu initially
	show_main_menu()

func show_main_menu():
	$CenterContainer.show()
	character_creation.hide()
	
	# Update continue button based on save data
	_update_continue_button()
	
	# Update load character button based on available characters
	_update_load_character_button()

func _update_continue_button():
	"""Update the continue button text and visibility based on save data"""
	if SaveSystem.has_save_data():
		var last_character_name = SaveSystem.get_last_character_name()
		if last_character_name != "":
			continue_btn.text = "Continue (" + last_character_name + ")"
			continue_btn.visible = true
		else:
			continue_btn.visible = false
	else:
		continue_btn.visible = false

func _update_load_character_button():
	"""Update the load character button based on available saved characters"""
	var has_characters = _check_for_saved_characters()
	
	if has_characters:
		load_character_btn.disabled = false
		load_character_btn.text = "Load Existing Character"
		load_character_btn.tooltip_text = "Load a previously saved character"
	else:
		load_character_btn.disabled = true
		load_character_btn.text = "Load Existing Character (None Available)"
		load_character_btn.tooltip_text = "No saved characters found. Create a new character first."

func _check_for_saved_characters() -> bool:
	"""Check if there are any saved character files"""
	var characters_dir = "user://characters/"
	
	if not DirAccess.dir_exists_absolute(characters_dir):
		return false
	
	var dir = DirAccess.open(characters_dir)
	if not dir:
		return false
	
	dir.list_dir_begin()
	var file_name = dir.get_next()
	
	while file_name != "":
		if file_name.ends_with(".tres"):
			dir.list_dir_end()
			return true
		file_name = dir.get_next()
	
	dir.list_dir_end()
	return false

func _on_continue():
	"""Continue with the last played character"""
	var last_character = SaveSystem.load_last_character()
	if last_character:
		start_game.emit(last_character)
	else:
		print("Failed to load last character!")
		_update_continue_button()  # Update button state
		_update_load_character_button()  # Update load button state as well

func _on_new_character():
	$CenterContainer.hide()
	character_creation.show()

func _on_load_character():
	# Double-check if button should be disabled (safeguard)
	if load_character_btn.disabled:
		print("Load character button is disabled - no characters available")
		return
	
	# Show available character files
	var characters_dir = "user://characters/"
	
	if not DirAccess.dir_exists_absolute(characters_dir):
		print("No saved characters found!")
		_update_load_character_button()  # Update button state
		return
	
	var dir = DirAccess.open(characters_dir)
	if dir:
		dir.list_dir_begin()
		var file_name = dir.get_next()
		var character_files = []
		
		while file_name != "":
			if file_name.ends_with(".tres"):
				character_files.append(file_name)
			file_name = dir.get_next()
		
		if character_files.is_empty():
			print("No saved characters found!")
			_update_load_character_button()  # Update button state
			return
		
		# Create and show character selection dialog
		show_character_selection(character_files)

func show_character_selection(character_files: Array):
	var dialog = AcceptDialog.new()
	dialog.title = "Select Character"
	dialog.size = Vector2i(400, 300)
	
	var vbox = VBoxContainer.new()
	dialog.add_child(vbox)
	
	var scroll = ScrollContainer.new()
	scroll.custom_minimum_size = Vector2(350, 200)
	vbox.add_child(scroll)
	
	var list_container = VBoxContainer.new()
	scroll.add_child(list_container)
	
	for file in character_files:
		var character_path = "user://characters/" + file
		var character_data = load(character_path) as CharacterData
		
		if character_data:
			var btn = Button.new()
			btn.text = "%s - Level %d %s" % [character_data.character_name, character_data.level, character_data.get_class_name()]
			btn.pressed.connect(func(): _load_character_file(character_path, dialog))
			list_container.add_child(btn)
	
	add_child(dialog)
	dialog.popup_centered()

func _load_character_file(path: String, dialog: AcceptDialog):
	var character_data = load(path) as CharacterData
	if character_data:
		dialog.queue_free()
		_on_character_loaded(character_data)
	else:
		print("Failed to load character from: ", path)

func _on_character_created(character_data: CharacterData):
	start_game.emit(character_data)

func _on_character_loaded(character_data: CharacterData):
	start_game.emit(character_data)

func display_all_player_sprites():
	"""Generate and display all player sprite combinations in a row"""
	print("Displaying all player sprites on main menu...")
	
	# Load PlayerIconFactory
	var factory_script = load("res://scripts/PlayerIconFactory.gd")
	if not factory_script:
		print("Could not load PlayerIconFactory script")
		return
	
	var factory = factory_script.new()
	if not factory.has_method("generate_icon"):
		print("Factory missing generate_icon method")
		return
	
	# Get all race and class combinations (limit to reduce memory usage)
	var races = ["Human", "Elf", "Dwarf", "Halfling"]  # Show fewer to reduce memory
	var classes = ["Fighter", "Wizard", "Rogue"]  # Show fewer classes
	
	var sprite_count = 0
	
	# Create sprites for each combination
	for race in races:
		for char_class in classes:
			var texture = factory.generate_icon(race, char_class)
			if texture:
				# Create TextureRect to display the sprite
				var texture_rect = TextureRect.new()
				texture_rect.texture = texture
				texture_rect.custom_minimum_size = Vector2(32, 32)  # Match sprite size
				texture_rect.expand_mode = TextureRect.EXPAND_FIT_WIDTH_PROPORTIONAL
				texture_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
				
				# Add tooltip with race/class info
				texture_rect.tooltip_text = race + " " + char_class
				
				# Add some spacing
				if sprite_count > 0:
					var spacer = Control.new()
					spacer.custom_minimum_size = Vector2(8, 32)
					sprite_container.add_child(spacer)
				
				# Add to container
				sprite_container.add_child(texture_rect)
				sprite_count += 1
	
	print("Displayed ", sprite_count, " player sprites on main menu")
	
	# Clean up factory to prevent memory leaks
	if factory:
		factory.queue_free()

func _on_quit():
	get_tree().quit()
