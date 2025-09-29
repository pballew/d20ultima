extends Control

@onready var main_menu = $MainMenu
@onready var game_scene = $GameScene
@onready var town_dialog = $TownDialog

var current_character: CharacterData
var quit_confirmation_dialog: AcceptDialog
## Controls whether pressing Q in-game saves and returns to menu (true) or saves and quits (false)
var q_saves_to_menu: bool = true

func _ready():
	# Add GameController to a group so Player can find it
	add_to_group("game_controller")
	
	# Ensure GameController processes input with high priority
	process_mode = Node.PROCESS_MODE_ALWAYS
	
	# Ensure proper layout
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	
	
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

	# Ensure menu visible initially; hide game scene until a game starts
	if main_menu:
		main_menu.show()
		if main_menu.has_method("show_main_menu"):
			main_menu.show_main_menu()
		main_menu.call_deferred("move_to_front")
	if game_scene:
		game_scene.hide()
	
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

	# Do not auto-create the combat log here; it will be created when combat begins
	
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
		# Immediately center the camera on the player before showing the scene
		player_camera.global_position = player.global_position
		if player and player.has_method("set_camera_target"):
			player.set_camera_target(player.global_position)
		print("Camera enabled and centered at: ", player_camera.global_position)
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
		if player and player.has_method("save_to_character_data"):
			current_character = player.save_to_character_data()
		if current_character and current_character.explored_tiles and current_character.explored_tiles.size() > 0:
			print("Saving fog explored tile count:", current_character.explored_tiles.size())
		
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

	# Combat log UI removed; no cleanup needed here
	
	main_menu.show()
	main_menu.show_main_menu()  # Refresh the menu state
	print("Returned to main menu")

func save_game():
	if current_character and game_scene.visible:
		var player = game_scene.get_node("Player")
		if player and player.has_method("save_to_character_data"):
			current_character = player.save_to_character_data()
		if current_character and current_character.explored_tiles and current_character.explored_tiles.size() > 0:
			print("Manual save fog explored tile count:", current_character.explored_tiles.size())
		
		# Save using the new save system
		var success = SaveSystem.save_game_state(current_character)
		
		if success:
			print("Game saved successfully!")
		else:
			print("Failed to save game!")

    

func _input(event):
	if event.is_action_pressed("ui_cancel") and game_scene.visible:
		# Show quit to menu confirmation when in game
		quit_confirmation_dialog.popup_centered()
	elif event.is_action_pressed("ui_cancel") and main_menu.visible:
		# Exit the application when in main menu
		get_tree().quit()
	elif event is InputEventKey and event.pressed and event.keycode == KEY_Q:
		if game_scene.visible:
			if q_saves_to_menu:
				# Q saves and returns to startup menu (no confirmation)
				print("Q pressed: saving game and returning to main menu")
				_save_and_return_to_menu()
				get_viewport().set_input_as_handled()
				return
			else:
				# Q saves and quits (single press exit)
				if current_character:
					var player = game_scene.get_node("Player")
					if player and player.has_method("save_to_character_data"):
						current_character = player.save_to_character_data()
					SaveSystem.save_game_state(current_character)
					print("Q pressed: game saved, quitting application")
				else:
					print("Q pressed: no character to save, quitting application")
				get_tree().quit()
		else:
			# On main menu: do nothing (already at startup dialog)
			print("Q pressed on main menu: already at startup screen")
			get_viewport().set_input_as_handled()
			return

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
	var town_name = town_data.get("name", "Unknown")
	print("Player entered town: ", town_name)
	
	# Award exploration XP
	var game_scene = get_node("GameScene")
	if game_scene:
		var player = game_scene.get_node("Player")
		if player and player.has_method("award_xp_for_exploration"):
			var xp_gained = player.award_xp_for_exploration()
			print("Awarded ", xp_gained, " XP for discovering ", town_name, "!")
			
			# Update the player stats UI
			var ui = game_scene.get_node("UI")
			if ui:
				var player_stats_ui = ui.get_node("PlayerStatsUI")
				if player_stats_ui and player_stats_ui.has_method("update_all_stats"):
					player_stats_ui.update_all_stats()
	
	# TODO: Add town interior scene or town management interface
	# For now, just show a simple message
	print("Town entered! (Town interior not yet implemented)")

func _on_town_dialog_cancelled():
	"""Handle when player cancels town entry"""
	print("Player continued journey without entering town")
