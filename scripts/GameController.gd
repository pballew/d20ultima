extends Control

@onready var main_menu = $MainMenu
@onready var game_scene = $GameScene
@onready var town_dialog = $TownDialog

var current_character: CharacterData
var quit_confirmation_dialog: AcceptDialog

func _ready():
	# Add GameController to a group so Player can find it
	add_to_group("game_controller")
	
	# Ensure proper layout
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	
	# Add a debug background color to make the controller visible
	var color_rect = ColorRect.new()
	color_rect.color = Color.DARK_BLUE
	color_rect.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(color_rect)
	move_child(color_rect, 0)  # Move to back
	
	# Create quit confirmation dialog
	_create_quit_confirmation_dialog()
	
	# Connect main menu signals
	main_menu.start_game.connect(_on_start_game)
	
	# Connect town dialog signals
	town_dialog.town_entered.connect(_on_town_entered)
	town_dialog.dialog_cancelled.connect(_on_town_dialog_cancelled)
	
	# Ensure main menu fills the controller (only for Control nodes)
	main_menu.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	
	# Force MainMenu to be on top and properly sized
	main_menu.z_index = 100
	print("MainMenu z_index set to: ", main_menu.z_index)
	print("MainMenu anchors: ", main_menu.anchor_left, ", ", main_menu.anchor_top, ", ", main_menu.anchor_right, ", ", main_menu.anchor_bottom)
	print("MainMenu offset: ", main_menu.offset_left, ", ", main_menu.offset_top, ", ", main_menu.offset_right, ", ", main_menu.offset_bottom)
	
	# Create a simple working menu directly in GameController to bypass broken MainMenu
	create_emergency_menu()
	
	# Disable game camera while in menu
	var player_camera = game_scene.get_node("Camera2D")
	if player_camera:
		player_camera.enabled = false
	
	# Hide player stats UI while in menu
	var player_stats_ui = game_scene.get_node("UI/PlayerStatsUI")
	if player_stats_ui:
		player_stats_ui.hide()
	
	# Check for auto-load of last character
	_check_auto_load()

func _check_auto_load():
	"""Check if we should auto-load the last played character"""
	print("=== GameController Debug ===")
	print("Checking for save data...")
	
	if SaveSystem.has_save_data():
		print("Save data found, attempting to load last character...")
		var last_character = SaveSystem.load_last_character()
		if last_character:
			print("Auto-loading last character: ", last_character.character_name)
			print("Main menu visible: ", main_menu.visible)
			print("Game scene visible: ", game_scene.visible)
			_on_start_game(last_character)
			return
		else:
			print("Failed to load character data!")
	else:
		print("No save data found")
	
	# No save data or failed to load, show main menu
	print("Showing main menu, hiding game scene")
	main_menu.show()
	game_scene.hide()
	print("Main menu visible: ", main_menu.visible)
	print("Game scene visible: ", game_scene.visible)

func _on_start_game(character_data: CharacterData):
	print("=== _ON_START_GAME CALLED ===")
	print("Character: ", character_data.character_name if character_data else "NULL")
	
	current_character = character_data
	
	print("Hiding main menu...")
	main_menu.hide()
	
	# Hide emergency menu if it exists
	for child in get_children():
		if child is VBoxContainer and child != main_menu and child != game_scene and child != town_dialog:
			print("Hiding emergency menu...")
			child.hide()
	
	print("Looking for game scene nodes...")
	# Initialize game with character data
	var player = game_scene.get_node("Player")
	if player:
		print("Player node found, loading character data...")
		player.load_from_character_data(character_data)
	else:
		print("ERROR: Player node not found!")
	
	# Enable the game camera
	var player_camera = game_scene.get_node("Camera2D")
	if player_camera:
		player_camera.enabled = true
		print("Camera enabled at: ", player_camera.global_position)
	else:
		print("ERROR: Camera not found!")
	
	# Update and show player stats UI
	var player_stats_ui = game_scene.get_node("UI/PlayerStatsUI")
	if player_stats_ui:
		player_stats_ui.setup_player_stats(player)
		player_stats_ui.show()
		print("Player stats UI setup and shown")
	else:
		print("ERROR: Player stats UI not found!")
	
	print("Showing game scene...")
	game_scene.show()
	print("Game scene shown - visible: ", game_scene.visible)
	print("Main menu hidden - visible: ", main_menu.visible)
	print("Game started with character: ", character_data.character_name)
	print("=== _ON_START_GAME COMPLETE ===")

func _create_quit_confirmation_dialog():
	quit_confirmation_dialog = AcceptDialog.new()
	quit_confirmation_dialog.dialog_text = "Save and return to main menu?"
	quit_confirmation_dialog.title = "Quit to Menu"
	quit_confirmation_dialog.add_cancel_button("Cancel")
	
	# Add the dialog to the scene tree
	add_child(quit_confirmation_dialog)
	
	# Connect the confirmed signal to save and return to menu
	quit_confirmation_dialog.confirmed.connect(_on_quit_confirmed)

func _on_quit_confirmed():
	_save_and_return_to_menu()

func _save_and_return_to_menu():
	"""Save current game state and return to main menu"""
	if current_character and game_scene.visible:
		# Update character data from current player state
		var player = game_scene.get_node("Player")
		current_character = player.save_to_character_data()
		
		# Save using the new save system
		SaveSystem.save_game_state(current_character)
	
	# Hide game and show main menu
	game_scene.hide()
	
	# Disable game camera
	var player_camera = game_scene.get_node("Camera2D")
	if player_camera:
		player_camera.enabled = false
	
	# Hide player stats UI
	var player_stats_ui = game_scene.get_node("UI/PlayerStatsUI")
	if player_stats_ui:
		player_stats_ui.hide()
	
	main_menu.show()
	main_menu.show_main_menu()  # Refresh the menu state
	print("Returned to main menu")

func save_game():
	if current_character and game_scene.visible:
		var player = game_scene.get_node("Player")
		current_character = player.save_to_character_data()
		
		# Save using the new save system
		var success = SaveSystem.save_game_state(current_character)
		
		if success:
			print("Game saved successfully!")
		else:
			print("Failed to save game!")

func create_emergency_menu():
	"""Create a simple emergency menu since MainMenu is broken"""
	var emergency_container = VBoxContainer.new()
	emergency_container.position = Vector2(400, 200)
	emergency_container.size = Vector2(300, 400)
	emergency_container.add_theme_color_override("background_color", Color.BLUE)
	add_child(emergency_container)
	
	var title = Label.new()
	title.text = "D20 RPG - Emergency Menu"
	title.add_theme_color_override("font_color", Color.YELLOW)
	emergency_container.add_child(title)
	
	var spacer = Control.new()
	spacer.custom_minimum_size = Vector2(0, 50)
	emergency_container.add_child(spacer)
	
	var new_game_btn = Button.new()
	new_game_btn.text = "New Game (No Character Creation)"
	new_game_btn.add_theme_color_override("font_color", Color.WHITE)
	new_game_btn.add_theme_color_override("font_color_pressed", Color.BLACK)
	new_game_btn.custom_minimum_size = Vector2(250, 40)
	print("Connecting emergency button...")
	var connection_result = new_game_btn.pressed.connect(_on_emergency_new_game)
	print("Button connection result: ", connection_result)
	emergency_container.add_child(new_game_btn)
	
	var quit_btn = Button.new()
	quit_btn.text = "Quit"
	quit_btn.add_theme_color_override("font_color", Color.WHITE)
	quit_btn.custom_minimum_size = Vector2(250, 40)
	quit_btn.pressed.connect(get_tree().quit)
	emergency_container.add_child(quit_btn)
	
	print("Created emergency menu with ", emergency_container.get_child_count(), " children")
	
	# Add a timer to auto-start the game after 3 seconds for testing
	var auto_start_timer = Timer.new()
	auto_start_timer.wait_time = 3.0
	auto_start_timer.one_shot = true
	auto_start_timer.timeout.connect(_on_emergency_new_game)
	add_child(auto_start_timer)
	auto_start_timer.start()
	print("Auto-start timer started - game will start in 3 seconds")
	
	# Force immediate game start for testing
	print("FORCING IMMEDIATE GAME START FOR DEBUGGING...")
	call_deferred("_on_emergency_new_game")

func _on_emergency_new_game():
	"""Start game with default character"""
	print("=== EMERGENCY NEW GAME CLICKED ===")
	print("Button function called successfully!")
	print("Starting emergency new game...")
	
	# Create a basic character
	var character = CharacterData.new()
	character.character_name = "Emergency Hero"
	character.character_race = CharacterData.CharacterRace.HUMAN
	character.character_class = CharacterData.CharacterClass.FIGHTER
	character.strength = 16
	character.dexterity = 14
	character.constitution = 15
	character.intelligence = 13
	character.wisdom = 12
	character.charisma = 10
	character.max_health = 20
	character.current_health = 20
	
	print("Created emergency character: ", character.character_name)
	print("About to call _on_start_game...")
	_on_start_game(character)
	print("=== END EMERGENCY NEW GAME ===")

func _input(event):
	if event.is_action_pressed("ui_cancel") and game_scene.visible:
		# Show quit to menu confirmation when in game
		quit_confirmation_dialog.popup_centered()
	elif event.is_action_pressed("ui_cancel") and main_menu.visible:
		# Exit the application when in main menu
		get_tree().quit()
	elif event is InputEventKey and event.pressed and event.keycode == KEY_Q:
		if game_scene.visible:
			# Quick save and return to menu
			_save_and_return_to_menu()
		else:
			# Exit the application when in main menu
			get_tree().quit()
	elif event is InputEventKey and event.pressed and event.keycode == KEY_N and main_menu.visible:
		# Emergency keyboard shortcut to start new game
		print("N key pressed - starting emergency new game via keyboard")
		_on_emergency_new_game()

func show_town_dialog(town_data: Dictionary):
	"""Show town entry dialog with town data"""
	print("DEBUG GameController: show_town_dialog called with: ", town_data)
	print("DEBUG GameController: town_dialog exists: ", town_dialog != null)
	if town_dialog:
		print("DEBUG GameController: Calling town_dialog.show_town_dialog")
		town_dialog.show_town_dialog(town_data)
		print("DEBUG GameController: Town dialog should now be visible")
	else:
		print("ERROR GameController: town_dialog is null!")

func _on_town_entered(town_data: Dictionary):
	"""Handle when player chooses to enter a town"""
	print("Player entered town: ", town_data.get("name", "Unknown"))
	# TODO: Add town interior scene or town management interface
	# For now, just show a simple message
	print("Town entered! (Town interior not yet implemented)")

func _on_town_dialog_cancelled():
	"""Handle when player cancels town entry"""
	print("Player continued journey without entering town")
