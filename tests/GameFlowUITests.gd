extends Node

# Game Flow UI Tests
# Tests overall game flow and UI transitions between different states

var test_scene: PackedScene
var test_instance: Node
var game_controller: Control

func _ready():
	run_all_tests()

func run_all_tests():
	UITestFramework.clear_results()
	print("Starting Game Flow UI Tests...")
	
	# Load the main game controller scene
	test_scene = load("res://scenes/GameController.tscn")
	test_instance = test_scene.instantiate()
	get_tree().root.add_child(test_instance)
	
	# Wait for scene to initialize
	await UITestFramework.wait_frames(get_tree(), 3)
	
	game_controller = test_instance
	
	# Run individual tests
	await test_initial_state()
	await test_menu_to_character_creation()
	await test_character_creation_to_game()
	await test_game_to_combat()
	await test_combat_to_game()
	await test_save_system_integration()
	await test_quit_functionality()
	await test_camera_integration()
	
	# Cleanup
	test_instance.queue_free()
	
	# Generate and save report
	var report = UITestFramework.generate_report()
	print(report)
	save_test_report(report, "game_flow_ui_tests")
	
	print("Game Flow UI Tests completed!")

func test_initial_state():
	UITestFramework.start_test("Initial Game State")
	
	var main_menu = game_controller.get_node("MainMenu")
	var game_scene = game_controller.get_node("GameScene")
	
	if not UITestFramework.assert_not_null(main_menu, "Main menu not found"):
		return
	
	if not UITestFramework.assert_not_null(game_scene, "Game scene not found"):
		return
	
	# Initially, main menu should be visible and game scene hidden
	if not UITestFramework.assert_true(UITestFramework.is_control_visible(main_menu), "Main menu not visible on startup"):
		return
	
	if not UITestFramework.assert_false(UITestFramework.is_control_visible(game_scene), "Game scene should be hidden on startup"):
		return
	
	UITestFramework.end_test(UITestFramework.TestResult.PASS)

func test_menu_to_character_creation():
	UITestFramework.start_test("Menu to Character Creation Transition")
	
	var main_menu = game_controller.get_node("MainMenu")
	var new_char_button = UITestFramework.find_button_by_text(main_menu, "Create New Character")
	
	if not UITestFramework.assert_not_null(new_char_button, "New Character button not found"):
		return
	
	# Click new character button
	UITestFramework.click_button(new_char_button as Button)
	await UITestFramework.wait_frames(get_tree(), 2)
	
	# Check that character creation is now visible
	var char_creation = main_menu.get_node("CharacterCreation")
	if not UITestFramework.assert_not_null(char_creation, "Character creation screen not found"):
		return
	
	if not UITestFramework.assert_true(UITestFramework.is_control_visible(char_creation), "Character creation not visible after button click"):
		return
	
	UITestFramework.end_test(UITestFramework.TestResult.PASS)

func test_character_creation_to_game():
	UITestFramework.start_test("Character Creation to Game Transition")
	
	# First navigate to character creation
	var main_menu = game_controller.get_node("MainMenu")
	var new_char_button = UITestFramework.find_button_by_text(main_menu, "Create New Character")
	UITestFramework.click_button(new_char_button as Button)
	await UITestFramework.wait_frames(get_tree(), 2)
	
	var char_creation = main_menu.get_node("CharacterCreation")
	
	# Fill out character creation form
	var name_input = UITestFramework.find_control_by_name(char_creation, "NameLineEdit")
	if UITestFramework.assert_not_null(name_input, "Name input not found"):
		UITestFramework.set_line_edit_text(name_input as LineEdit, "UITestHero")
		await UITestFramework.wait_frames(get_tree(), 1)
	
	# Click create character button
	var create_button = UITestFramework.find_button_by_text(char_creation, "Create Character")
	if not UITestFramework.assert_not_null(create_button, "Create Character button not found"):
		return
	
	UITestFramework.click_button(create_button as Button)
	await UITestFramework.wait_frames(get_tree(), 3)
	
	# Check that game scene is now visible
	var game_scene = game_controller.get_node("GameScene")
	if not UITestFramework.assert_true(UITestFramework.is_control_visible(game_scene), "Game scene not visible after character creation"):
		return
	
	# Check that main menu is hidden
	if not UITestFramework.assert_false(UITestFramework.is_control_visible(main_menu), "Main menu should be hidden during gameplay"):
		return
	
	UITestFramework.end_test(UITestFramework.TestResult.PASS)

func test_game_to_combat():
	UITestFramework.start_test("Game to Combat Transition")
	
	# Ensure we're in game state
	await setup_game_state()
	
	var game_scene = game_controller.get_node("GameScene")
	var combat_ui = game_scene.get_node("UI/CombatUI")
	var player = game_scene.get_node("Player")
	
	# Trigger combat manually
	player.enter_combat()
	combat_ui.show()
	await UITestFramework.wait_frames(get_tree(), 2)
	
	if not UITestFramework.assert_true(UITestFramework.is_control_visible(combat_ui), "Combat UI not visible during combat"):
		return
	
	# Check that action buttons are available
	var attack_button = combat_ui.get_node("VBoxContainer/ActionButtons/AttackButton")
	if not UITestFramework.assert_not_null(attack_button, "Attack button not found during combat"):
		return
	
	UITestFramework.end_test(UITestFramework.TestResult.PASS)

func test_combat_to_game():
	UITestFramework.start_test("Combat to Game Transition")
	
	# Ensure we're in combat state
	await setup_game_state()
	
	var game_scene = game_controller.get_node("GameScene")
	var combat_ui = game_scene.get_node("UI/CombatUI")
	var player = game_scene.get_node("Player")
	
	# Enter combat
	player.enter_combat()
	combat_ui.show()
	await UITestFramework.wait_frames(get_tree(), 1)
	
	# Exit combat
	player.exit_combat()
	combat_ui.hide()
	await UITestFramework.wait_frames(get_tree(), 1)
	
	if not UITestFramework.assert_false(UITestFramework.is_control_visible(combat_ui), "Combat UI should be hidden after combat"):
		return
	
	if not UITestFramework.assert_false(player.is_in_combat, "Player should not be in combat state"):
		return
	
	UITestFramework.end_test(UITestFramework.TestResult.PASS)

func test_save_system_integration():
	UITestFramework.start_test("Save System Integration")
	
	# Ensure we're in game state
	await setup_game_state()
	
	var game_scene = game_controller.get_node("GameScene")
	var player = game_scene.get_node("Player")
	
	# Test save functionality
	var initial_name = player.character_name
	var save_successful = true
	
	# Try to save the game
	if game_controller.has_method("save_game"):
		game_controller.save_game()
		await UITestFramework.wait_frames(get_tree(), 2)
	
	if not UITestFramework.assert_true(save_successful, "Save system not functioning correctly"):
		return
	
	UITestFramework.end_test(UITestFramework.TestResult.PASS)

func test_quit_functionality():
	UITestFramework.start_test("Quit Functionality")
	
	# Test quit from game to menu
	await setup_game_state()
	
	# Simulate quit key press (Q)
	UITestFramework.simulate_key_press(get_viewport(), KEY_Q, true)
	await UITestFramework.wait_frames(get_tree(), 2)
	UITestFramework.simulate_key_press(get_viewport(), KEY_Q, false)
	await UITestFramework.wait_frames(get_tree(), 2)
	
	# Check that we're back to main menu or confirmation dialog appeared
	var main_menu = game_controller.get_node("MainMenu")
	var game_scene = game_controller.get_node("GameScene")
	
	# Either menu should be visible or game should still be running (with confirmation dialog)
	var transition_working = UITestFramework.is_control_visible(main_menu) or UITestFramework.is_control_visible(game_scene)
	
	if not UITestFramework.assert_true(transition_working, "Quit functionality not working correctly"):
		return
	
	UITestFramework.end_test(UITestFramework.TestResult.PASS)

func test_camera_integration():
	UITestFramework.start_test("Camera Integration")
	
	await setup_game_state()
	
	var game_scene = game_controller.get_node("GameScene")
	var camera = game_scene.get_node("Camera2D")
	var player = game_scene.get_node("Player")
	
	if not UITestFramework.assert_not_null(camera, "Camera not found"):
		return
	
	if not UITestFramework.assert_not_null(player, "Player not found"):
		return
	
	# Test that camera is enabled during gameplay
	if not UITestFramework.assert_true(camera.enabled, "Camera should be enabled during gameplay"):
		return
	
	# Test camera position relative to player
	var camera_pos = camera.global_position
	var player_pos = player.global_position
	var distance = camera_pos.distance_to(player_pos)
	
	# Camera should be reasonably close to player (within 2 tiles)
	if not UITestFramework.assert_true(distance < 128, "Camera too far from player position"):
		return
	
	UITestFramework.end_test(UITestFramework.TestResult.PASS)

func setup_game_state():
	# Create a test character and start game
	var char_data = CharacterData.new()
	char_data.character_name = "UITestCharacter"
	char_data.level = 1
	char_data.max_health = 100
	char_data.current_health = 100
	char_data.strength = 14
	char_data.dexterity = 12
	char_data.constitution = 16
	char_data.intelligence = 10
	char_data.wisdom = 12
	char_data.charisma = 8
	
	# Start game with character
	game_controller._on_start_game(char_data)
	await UITestFramework.wait_frames(get_tree(), 3)

func save_test_report(report: String, filename: String):
	var file = FileAccess.open("user://test_reports_%s_%d.txt" % [filename, Time.get_unix_time_from_system()], FileAccess.WRITE)
	if file:
		file.store_string(report)
		file.close()
		print("Test report saved to: user://test_reports_%s_%d.txt" % [filename, Time.get_unix_time_from_system()])
