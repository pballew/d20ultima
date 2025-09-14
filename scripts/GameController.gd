extends Control

@onready var main_menu = $MainMenu
@onready var game_scene = $GameScene

var current_character: CharacterData
var quit_confirmation_dialog: AcceptDialog

func _ready():
	# Ensure proper layout
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	
	# Create quit confirmation dialog
	_create_quit_confirmation_dialog()
	
	# Connect main menu signals
	main_menu.start_game.connect(_on_start_game)
	
	# Ensure main menu fills the controller (only for Control nodes)
	main_menu.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	
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
	if SaveSystem.has_save_data():
		var last_character = SaveSystem.load_last_character()
		if last_character:
			print("Auto-loading last character: ", last_character.character_name)
			_on_start_game(last_character)
			return
	
	# No save data or failed to load, show main menu
	main_menu.show()
	game_scene.hide()

func _on_start_game(character_data: CharacterData):
	current_character = character_data
	main_menu.hide()
	
	# Initialize game with character data
	var player = game_scene.get_node("Player")
	player.load_from_character_data(character_data)
	
	# Enable the game camera
	var player_camera = game_scene.get_node("Camera2D")
	if player_camera:
		player_camera.enabled = true
	
	# Update and show player stats UI
	var player_stats_ui = game_scene.get_node("UI/PlayerStatsUI")
	if player_stats_ui:
		player_stats_ui.setup_player_stats(player)
		player_stats_ui.show()
	
	game_scene.show()
	print("Game started with character: ", character_data.character_name)

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
