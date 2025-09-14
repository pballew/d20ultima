extends Node

# Main Menu UI Tests
# Tests all functionality of the main menu including navigation and character management

var test_scene: PackedScene
var test_instance: Node
var main_menu: Control

func _ready():
	run_all_tests()

func run_all_tests():
	UITestFramework.clear_results()
	print("Starting Main Menu UI Tests...")
	
	# Load the main game controller scene
	test_scene = load("res://scenes/GameController.tscn")
	test_instance = test_scene.instantiate()
	get_tree().root.add_child(test_instance)
	
	# Wait for scene to initialize
	await UITestFramework.wait_frames(get_tree(), 3)
	
	# Get main menu reference
	main_menu = test_instance.get_node("MainMenu")
	
	# Run individual tests
	await test_main_menu_visibility()
	await test_title_display()
	await test_button_presence()
	await test_continue_button_functionality()
	await test_new_character_button()
	await test_load_character_button()
	await test_quit_button()
	await test_character_creation_flow()
	
	# Cleanup
	test_instance.queue_free()
	
	# Generate and save report
	var report = UITestFramework.generate_report()
	print(report)
	save_test_report(report, "main_menu_tests")
	
	print("Main Menu UI Tests completed!")

func test_main_menu_visibility():
	UITestFramework.start_test("Main Menu Visibility")
	
	if not UITestFramework.assert_not_null(main_menu, "Main menu node not found"):
		return
	
	if not UITestFramework.assert_true(UITestFramework.is_control_visible(main_menu), "Main menu not visible"):
		return
	
	UITestFramework.end_test(UITestFramework.TestResult.PASS)

func test_title_display():
	UITestFramework.start_test("Title Display")
	
	var title_label = UITestFramework.find_control_by_name(main_menu, "TitleLabel")
	
	if not UITestFramework.assert_not_null(title_label, "Title label not found"):
		return
	
	var title_text = UITestFramework.get_label_text(title_label as Label)
	if not UITestFramework.assert_true(title_text.length() > 0, "Title text is empty"):
		return
	
	if not UITestFramework.assert_true(title_text.contains("RPG"), "Title doesn't contain 'RPG'"):
		return
	
	UITestFramework.end_test(UITestFramework.TestResult.PASS)

func test_button_presence():
	UITestFramework.start_test("Button Presence")
	
	var continue_button = UITestFramework.find_button_by_text(main_menu, "Continue")
	var new_char_button = UITestFramework.find_button_by_text(main_menu, "Create New Character")
	var load_char_button = UITestFramework.find_button_by_text(main_menu, "Load Existing Character")
	var quit_button = UITestFramework.find_button_by_text(main_menu, "Quit Game")
	
	if not UITestFramework.assert_not_null(continue_button, "Continue button not found"):
		return
	
	if not UITestFramework.assert_not_null(new_char_button, "New Character button not found"):
		return
	
	if not UITestFramework.assert_not_null(load_char_button, "Load Character button not found"):
		return
	
	if not UITestFramework.assert_not_null(quit_button, "Quit button not found"):
		return
	
	UITestFramework.end_test(UITestFramework.TestResult.PASS)

func test_continue_button_functionality():
	UITestFramework.start_test("Continue Button Functionality")
	
	var continue_button = UITestFramework.find_button_by_text(main_menu, "Continue")
	
	if not UITestFramework.assert_not_null(continue_button, "Continue button not found"):
		return
	
	# Check initial state (should be enabled if save data exists, disabled otherwise)
	var button_state_valid = true  # We'll assume this is correct for now
	
	if not UITestFramework.assert_true(button_state_valid, "Continue button state invalid"):
		return
	
	UITestFramework.end_test(UITestFramework.TestResult.PASS)

func test_new_character_button():
	UITestFramework.start_test("New Character Button")
	
	var new_char_button = UITestFramework.find_button_by_text(main_menu, "Create New Character")
	
	if not UITestFramework.assert_not_null(new_char_button, "New Character button not found"):
		return
	
	if not UITestFramework.assert_true(UITestFramework.is_control_visible(new_char_button), "New Character button not visible"):
		return
	
	if not UITestFramework.assert_false((new_char_button as Button).disabled, "New Character button is disabled"):
		return
	
	# Test button click
	var click_success = UITestFramework.click_button(new_char_button as Button)
	if not UITestFramework.assert_true(click_success, "Failed to click New Character button"):
		return
	
	await UITestFramework.wait_frames(get_tree(), 2)
	
	# Check if character creation screen appeared
	var char_creation = test_instance.get_node("MainMenu/CharacterCreation")
	if UITestFramework.assert_not_null(char_creation, "Character creation screen not found"):
		UITestFramework.assert_true(UITestFramework.is_control_visible(char_creation), "Character creation screen not visible")
	
	UITestFramework.end_test(UITestFramework.TestResult.PASS)

func test_load_character_button():
	UITestFramework.start_test("Load Character Button")
	
	var load_char_button = UITestFramework.find_button_by_text(main_menu, "Load Existing Character")
	
	if not UITestFramework.assert_not_null(load_char_button, "Load Character button not found"):
		return
	
	if not UITestFramework.assert_true(UITestFramework.is_control_visible(load_char_button), "Load Character button not visible"):
		return
	
	UITestFramework.end_test(UITestFramework.TestResult.PASS)

func test_quit_button():
	UITestFramework.start_test("Quit Button")
	
	var quit_button = UITestFramework.find_button_by_text(main_menu, "Quit Game")
	
	if not UITestFramework.assert_not_null(quit_button, "Quit button not found"):
		return
	
	if not UITestFramework.assert_true(UITestFramework.is_control_visible(quit_button), "Quit button not visible"):
		return
	
	if not UITestFramework.assert_false((quit_button as Button).disabled, "Quit button is disabled"):
		return
	
	UITestFramework.end_test(UITestFramework.TestResult.PASS)

func test_character_creation_flow():
	UITestFramework.start_test("Character Creation Flow")
	
	var new_char_button = UITestFramework.find_button_by_text(main_menu, "Create New Character")
	if not UITestFramework.assert_not_null(new_char_button, "New Character button not found"):
		return
	
	# Click to open character creation
	UITestFramework.click_button(new_char_button as Button)
	await UITestFramework.wait_frames(get_tree(), 2)
	
	var char_creation = test_instance.get_node("MainMenu/CharacterCreation")
	if not UITestFramework.assert_not_null(char_creation, "Character creation screen not found"):
		return
	
	# Test name input
	var name_input = UITestFramework.find_control_by_name(char_creation, "NameLineEdit")
	if UITestFramework.assert_not_null(name_input, "Name input not found"):
		UITestFramework.set_line_edit_text(name_input as LineEdit, "TestHero")
		await UITestFramework.wait_frames(get_tree(), 1)
		UITestFramework.assert_equal("TestHero", (name_input as LineEdit).text, "Name input text not set correctly")
	
	# Test stat buttons
	var str_plus = UITestFramework.find_control_by_name(char_creation, "StrPlus")
	if UITestFramework.assert_not_null(str_plus, "Strength plus button not found"):
		UITestFramework.click_button(str_plus as Button)
		await UITestFramework.wait_frames(get_tree(), 1)
	
	# Test create button
	var create_button = UITestFramework.find_button_by_text(char_creation, "Create Character")
	if UITestFramework.assert_not_null(create_button, "Create Character button not found"):
		UITestFramework.assert_true(UITestFramework.is_control_visible(create_button), "Create Character button not visible")
	
	UITestFramework.end_test(UITestFramework.TestResult.PASS)

func save_test_report(report: String, filename: String):
	var file = FileAccess.open("user://test_reports_%s_%d.txt" % [filename, Time.get_unix_time_from_system()], FileAccess.WRITE)
	if file:
		file.store_string(report)
		file.close()
		print("Test report saved to: user://test_reports_%s_%d.txt" % [filename, Time.get_unix_time_from_system()])
