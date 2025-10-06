extends Control

signal start_game(character_data: CharacterData)

const CharacterData = preload("res://scripts/CharacterData.gd")

@onready var title_label = $CenterContainer/VBoxContainer/TitleLabel
@onready var continue_btn = $CenterContainer/VBoxContainer/ContinueButton
@onready var new_character_btn = $CenterContainer/VBoxContainer/NewCharacterButton
@onready var load_character_btn = $CenterContainer/VBoxContainer/LoadCharacterButton
@onready var quit_btn = $CenterContainer/VBoxContainer/QuitButton
@onready var character_creation = $CharacterCreation
@onready var sprite_container = $SpriteDisplay/SpriteContainer

func _ready():
	DebugLogger.info("=== MainMenu _ready() Debug ===")
	DebugLogger.info(str("MainMenu node path: ") + " " + str(get_path()))
	DebugLogger.info(str("MainMenu size: ") + " " + str(size))
	DebugLogger.info(str("MainMenu position: ") + " " + str(position))
	
	# Check if all required nodes exist
	if not continue_btn:
		DebugLogger.error("ERROR: continue_btn not found!")
	if not new_character_btn:
		DebugLogger.error("ERROR: new_character_btn not found!")
	if not load_character_btn:
		DebugLogger.error("ERROR: load_character_btn not found!")
	if not quit_btn:
		DebugLogger.error("ERROR: quit_btn not found!")
	if not character_creation:
		DebugLogger.error("ERROR: character_creation not found!")
	if not sprite_container:
		DebugLogger.error("ERROR: sprite_container not found!")
	
	# Connect signals
	if continue_btn:
		continue_btn.pressed.connect(_on_continue)
	if new_character_btn:
		new_character_btn.pressed.connect(_on_new_character)
	if load_character_btn:
		load_character_btn.pressed.connect(_on_load_character)
	if quit_btn:
		quit_btn.pressed.connect(_on_quit)
	
	if character_creation:
		character_creation.character_created.connect(_on_character_created)
		character_creation.character_loaded.connect(_on_character_loaded)
	
	# Generate and display all player sprites
	display_all_player_sprites()
	
	# Force MainMenu to front and ensure proper positioning
	z_index = 200
	call_deferred("move_to_front")
	DebugLogger.info(str("MainMenu moved to front with z_index: ") + " " + str(z_index))
	
	# Show main menu initially
	show_main_menu()

func show_main_menu():
	DebugLogger.info("=== MainMenu Debug ===")
	DebugLogger.info(str("MainMenu visible: ") + " " + str(visible))
	DebugLogger.info(str("MainMenu modulate: ") + " " + str(modulate))
	
	# Override the existing background color to be black
	var background = get_node("Background")
	if background:
		background.color = Color.BLACK
		DebugLogger.info("Changed existing background to BLACK")
	else:
		# Add a debug background to make the MainMenu visible
		if not has_node("DebugBackground"):
			var debug_bg = ColorRect.new()
			debug_bg.name = "DebugBackground"
			debug_bg.color = Color.BLACK
			debug_bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
			add_child(debug_bg)
			move_child(debug_bg, 0)  # Move to back
			DebugLogger.info("Added debug background to MainMenu")
	
	$CenterContainer.show()
	character_creation.hide()
	
	DebugLogger.info(str("CenterContainer visible: ") + " " + str($CenterContainer.visible))
	DebugLogger.info(str("CenterContainer modulate: ") + " " + str($CenterContainer.modulate))
	
	if title_label:
		DebugLogger.info(str("Title label visible: ") + " " + str(title_label.visible))
		DebugLogger.info(str("Title label text: ") + " " + str(title_label.text))
		DebugLogger.info(str("Title label modulate: ") + " " + str(title_label.modulate))
		# Stylize the title with a bundled medieval font when available, else SystemFont fallbacks
		title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		title_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		var ls: LabelSettings
		if title_label.label_settings != null:
			ls = title_label.label_settings
		else:
			ls = LabelSettings.new()
		# Try to load a bundled font from assets/fonts
		var bundled_candidates := [
			"res://assets/fonts/EagleLake-Regular.ttf",
			"res://assets/fonts/CinzelDecorative-Regular.ttf",
			"res://assets/fonts/CinzelDecorative-Black.ttf",
			"res://assets/fonts/UnifrakturCook-Regular.ttf",
			"res://assets/fonts/UnifrakturMaguntia-Regular.ttf",
			"res://assets/fonts/MedievalSharp-Regular.ttf",
			"res://assets/fonts/IMFellEnglishSC-Regular.ttf"
		]
		var chosen_font: Font = null
		for path in bundled_candidates:
			DebugLogger.info(str("Trying font candidate: ") + " " + str(path))
			# Load directly from bytes to avoid import-time errors in headless checks
			if FileAccess.file_exists(path):
				var bytes := FileAccess.get_file_as_bytes(path)
				if bytes.size() > 0:
					var ff := FontFile.new()
					ff.data = bytes
					chosen_font = ff
					DebugLogger.info("Loaded bundled medieval font from bytes: %s (%d bytes)" % [path, bytes.size()])
					break
				else:
					DebugLogger.info(str("Font file read returned 0 bytes: ") + " " + str(path))
			else:
				DebugLogger.info(str("Font candidate not found by FileAccess: ") + " " + str(path))
		if chosen_font == null:
			# Fallback to system fonts
			var sys_font := SystemFont.new()
			sys_font.font_names = [
				"Eagle Lake", "EagleLake",
				"UnifrakturCook", "UnifrakturMaguntia",
				"Cinzel Decorative", "CinzelDecorative",
				"IM FELL English SC", "IM FELL English",
				"Old English Text MT", "Goudy Medieval",
				"Blackletter", "Fraktur",
				"MedievalSharp"
			]
			chosen_font = sys_font
			DebugLogger.info("Using SystemFont fallback; candidates: %s" % str(sys_font.font_names))
			# List available files in res://assets/fonts for diagnostics
			var fonts_dir_path = "res://assets/fonts"
			var dir = DirAccess.open(fonts_dir_path)
			if dir:
				dir.list_dir_begin()
				var fname = dir.get_next()
				var listed = []
				while fname != "":
					if not fname.begins_with("."):
						listed.append(fname)
					fname = dir.get_next()
				dir.list_dir_end()
				DebugLogger.info("Fonts present in %s: %s" % [fonts_dir_path, str(listed)])
		ls.font = chosen_font
		ls.font_size = 72
		ls.font_color = Color(0, 1, 1) # aqua
		ls.outline_size = 4
		ls.outline_color = Color(0, 0, 0)
		title_label.label_settings = ls
		DebugLogger.info("Styled title label with medieval font (size=72, aqua, outline=4)")
	else:
		DebugLogger.error("ERROR: Title label not found!")
	
	# Make buttons more visible
	if new_character_btn:
		new_character_btn.modulate = Color.WHITE
		DebugLogger.info(str("New Character button visible: ") + " " + str(new_character_btn.visible))
	if quit_btn:
		quit_btn.modulate = Color.RED
		DebugLogger.info(str("Quit button visible: ") + " " + str(quit_btn.visible))
	
	# Update continue button based on save data
	_update_continue_button()
	
	# Update load character button based on available characters
	_update_load_character_button()
	
	DebugLogger.info("=== End MainMenu Debug ===")

func _update_continue_button():
	"""Update the continue button text and visibility based on save data"""
	var has_data = SaveSystem.has_save_data()
	var last_character_name = SaveSystem.get_last_character_name() if has_data else ""
	DebugLogger.info(str("[Continue Button] has_save_data=") + " " + str(has_data) + " " + str(", last_character_name=") + " " + str(last_character_name))
	if has_data and last_character_name != "":
		continue_btn.text = "Journey Onward (" + last_character_name + ")"
		continue_btn.visible = true
		DebugLogger.info(str("[Continue Button] Visible with last character; text=") + " " + str(continue_btn.text))
	else:
		continue_btn.visible = false
		DebugLogger.info("[Continue Button] Hidden (no save)")

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
		DebugLogger.info("Failed to load last character!")
		_update_continue_button()  # Update button state
		_update_load_character_button()  # Update load button state as well

func _on_new_character():
	$CenterContainer.hide()
	character_creation.show()

func _on_load_character():
	# Double-check if button should be disabled (safeguard)
	if load_character_btn.disabled:
		DebugLogger.info("Load character button is disabled - no characters available")
		return
	
	# Show available character files
	var characters_dir = "user://characters/"
	
	if not DirAccess.dir_exists_absolute(characters_dir):
		DebugLogger.info("No saved characters found!")
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
			DebugLogger.info("No saved characters found!")
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
		DebugLogger.info(str("Failed to load character from: ") + " " + str(path))

func _on_character_created(character_data: CharacterData):
	start_game.emit(character_data)

func _on_character_loaded(character_data: CharacterData):
	start_game.emit(character_data)

func display_all_player_sprites():
	"""Generate and display all player sprite combinations in a row"""
	DebugLogger.info("Displaying all player sprites on main menu...")
	
	# Load PlayerIconFactory
	var factory_script = load("res://scripts/PlayerIconFactory.cs")
	if not factory_script:
		DebugLogger.info("Could not load PlayerIconFactory script")
		return
	
	var factory = factory_script.new()
	if not factory.has_method("generate_icon"):
		DebugLogger.info("Factory missing generate_icon method")
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
	
	DebugLogger.info(str("Displayed ") + " " + str(sprite_count) + " " + str(" player sprites on main menu"))
	
	# Clean up factory to prevent memory leaks
	if factory:
		factory.queue_free()

func _on_quit():
	get_tree().quit()


