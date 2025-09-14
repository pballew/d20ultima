extends Node

# Player Stats UI Tests
# Tests the player statistics display and updates

var test_scene: PackedScene
var test_instance: Node
var game_scene: Node
var player_stats_ui: Control
var player: Player

func _ready():
	run_all_tests()

func run_all_tests():
	UITestFramework.clear_results()
	print("Starting Player Stats UI Tests...")
	
	# Load the main game controller scene
	test_scene = load("res://scenes/GameController.tscn")
	test_instance = test_scene.instantiate()
	get_tree().root.add_child(test_instance)
	
	# Wait for scene to initialize
	await UITestFramework.wait_frames(get_tree(), 3)
	
	# Get references
	game_scene = test_instance.get_node("GameScene")
	player_stats_ui = game_scene.get_node("UI/PlayerStatsUI")
	player = game_scene.get_node("Player")
	
	# Start a test game to access player stats UI
	await setup_test_game()
	
	# Run individual tests
	await test_stats_ui_visibility()
	await test_character_name_display()
	await test_level_display()
	await test_health_display()
	await test_experience_display()
	await test_attributes_display()
	await test_combat_stats_display()
	await test_stats_updates()
	
	# Cleanup
	test_instance.queue_free()
	
	# Generate and save report
	var report = UITestFramework.generate_report()
	print(report)
	save_test_report(report, "player_stats_ui_tests")
	
	print("Player Stats UI Tests completed!")

func setup_test_game():
	# Create a test character
	var char_data = CharacterData.new()
	char_data.character_name = "TestMage"
	char_data.level = 3
	char_data.max_health = 85
	char_data.current_health = 65
	char_data.experience = 1500
	char_data.strength = 12
	char_data.dexterity = 14
	char_data.constitution = 13
	char_data.intelligence = 16
	char_data.wisdom = 15
	char_data.charisma = 11
	char_data.armor_class = 12
	char_data.attack_bonus = 3
	
	# Load character into player
	player.load_from_character_data(char_data)
	
	# Show game scene
	var game_controller = test_instance
	game_controller._on_start_game(char_data)
	
	await UITestFramework.wait_frames(get_tree(), 2)

func test_stats_ui_visibility():
	UITestFramework.start_test("Player Stats UI Visibility")
	
	if not UITestFramework.assert_not_null(player_stats_ui, "Player Stats UI not found"):
		return
	
	if not UITestFramework.assert_true(UITestFramework.is_control_visible(player_stats_ui), "Player Stats UI not visible"):
		return
	
	# Check background panel
	var background = player_stats_ui.get_node("Background")
	if not UITestFramework.assert_not_null(background, "Background panel not found"):
		return
	
	UITestFramework.end_test(UITestFramework.TestResult.PASS)

func test_character_name_display():
	UITestFramework.start_test("Character Name Display")
	
	var name_label = player_stats_ui.get_node("VBoxContainer/NameLabel")
	
	if not UITestFramework.assert_not_null(name_label, "Name label not found"):
		return
	
	var name_text = UITestFramework.get_label_text(name_label as Label)
	if not UITestFramework.assert_equal("TestMage", name_text, "Character name not displayed correctly"):
		return
	
	UITestFramework.end_test(UITestFramework.TestResult.PASS)

func test_level_display():
	UITestFramework.start_test("Level Display")
	
	var level_label = player_stats_ui.get_node("VBoxContainer/LevelLabel")
	
	if not UITestFramework.assert_not_null(level_label, "Level label not found"):
		return
	
	var level_text = UITestFramework.get_label_text(level_label as Label)
	if not UITestFramework.assert_true(level_text.contains("Level"), "Level text doesn't contain 'Level'"):
		return
	
	if not UITestFramework.assert_true(level_text.contains("3"), "Level text doesn't show correct level"):
		return
	
	UITestFramework.end_test(UITestFramework.TestResult.PASS)

func test_health_display():
	UITestFramework.start_test("Health Display")
	
	var health_label = player_stats_ui.get_node("VBoxContainer/HealthContainer/HealthLabel")
	var health_bar = player_stats_ui.get_node("VBoxContainer/HealthContainer/HealthBar")
	
	if not UITestFramework.assert_not_null(health_label, "Health label not found"):
		return
	
	if not UITestFramework.assert_not_null(health_bar, "Health bar not found"):
		return
	
	var health_text = UITestFramework.get_label_text(health_label as Label)
	if not UITestFramework.assert_true(health_text.contains("65") and health_text.contains("85"), "Health values not displayed correctly"):
		return
	
	# Test health bar value
	var health_bar_value = (health_bar as ProgressBar).value
	var expected_percentage = (65.0 / 85.0) * 100.0
	if not UITestFramework.assert_true(abs(health_bar_value - expected_percentage) < 1.0, "Health bar value incorrect"):
		return
	
	UITestFramework.end_test(UITestFramework.TestResult.PASS)

func test_experience_display():
	UITestFramework.start_test("Experience Display")
	
	var exp_label = player_stats_ui.get_node("VBoxContainer/ExperienceContainer/ExperienceLabel")
	var exp_bar = player_stats_ui.get_node("VBoxContainer/ExperienceContainer/ExperienceBar")
	
	if not UITestFramework.assert_not_null(exp_label, "Experience label not found"):
		return
	
	if not UITestFramework.assert_not_null(exp_bar, "Experience bar not found"):
		return
	
	var exp_text = UITestFramework.get_label_text(exp_label as Label)
	if not UITestFramework.assert_true(exp_text.contains("XP"), "Experience text doesn't contain 'XP'"):
		return
	
	UITestFramework.end_test(UITestFramework.TestResult.PASS)

func test_attributes_display():
	UITestFramework.start_test("Attributes Display")
	
	var stats_container = player_stats_ui.get_node("VBoxContainer/StatsContainer")
	
	if not UITestFramework.assert_not_null(stats_container, "Stats container not found"):
		return
	
	# Test individual attribute labels
	var attributes = ["Strength", "Dexterity", "Constitution", "Intelligence", "Wisdom", "Charisma"]
	var attribute_values = [12, 14, 13, 16, 15, 11]
	
	for i in range(attributes.size()):
		var attr_name = attributes[i]
		var expected_value = attribute_values[i]
		
		var label_name = attr_name + "Label"
		var attr_label = stats_container.get_node(label_name)
		
		if UITestFramework.assert_not_null(attr_label, "%s label not found" % attr_name):
			var attr_text = UITestFramework.get_label_text(attr_label as Label)
			var contains_value = attr_text.contains(str(expected_value))
			UITestFramework.assert_true(contains_value, "%s value not displayed correctly" % attr_name)
	
	UITestFramework.end_test(UITestFramework.TestResult.PASS)

func test_combat_stats_display():
	UITestFramework.start_test("Combat Stats Display")
	
	var combat_container = player_stats_ui.get_node("VBoxContainer/CombatContainer")
	
	if not UITestFramework.assert_not_null(combat_container, "Combat container not found"):
		return
	
	# Test AC display
	var ac_label = combat_container.get_node("ArmorClassLabel")
	if UITestFramework.assert_not_null(ac_label, "AC label not found"):
		var ac_text = UITestFramework.get_label_text(ac_label as Label)
		UITestFramework.assert_true(ac_text.contains("AC"), "AC text doesn't contain 'AC'")
		UITestFramework.assert_true(ac_text.contains("12"), "AC value not displayed correctly")
	
	# Test attack bonus display
	var attack_label = combat_container.get_node("AttackBonusLabel")
	if UITestFramework.assert_not_null(attack_label, "Attack bonus label not found"):
		var attack_text = UITestFramework.get_label_text(attack_label as Label)
		UITestFramework.assert_true(attack_text.contains("Attack"), "Attack text doesn't contain 'Attack'")
	
	UITestFramework.end_test(UITestFramework.TestResult.PASS)

func test_stats_updates():
	UITestFramework.start_test("Stats Updates")
	
	# Test health update
	player.current_health = 50
	player.max_health = 85
	
	# Trigger UI update
	if player_stats_ui.has_method("update_player_stats"):
		player_stats_ui.update_player_stats()
	elif player_stats_ui.has_method("setup_player_stats"):
		player_stats_ui.setup_player_stats(player)
	
	await UITestFramework.wait_frames(get_tree(), 1)
	
	# Check if health display updated
	var health_label = player_stats_ui.get_node("VBoxContainer/HealthContainer/HealthLabel")
	if UITestFramework.assert_not_null(health_label, "Health label not found for update test"):
		var health_text = UITestFramework.get_label_text(health_label as Label)
		UITestFramework.assert_true(health_text.contains("50"), "Health display not updated correctly")
	
	# Test level update
	player.level = 4
	
	# Trigger UI update again
	if player_stats_ui.has_method("update_player_stats"):
		player_stats_ui.update_player_stats()
	elif player_stats_ui.has_method("setup_player_stats"):
		player_stats_ui.setup_player_stats(player)
	
	await UITestFramework.wait_frames(get_tree(), 1)
	
	# Check if level display updated
	var level_label = player_stats_ui.get_node("VBoxContainer/LevelLabel")
	if UITestFramework.assert_not_null(level_label, "Level label not found for update test"):
		var level_text = UITestFramework.get_label_text(level_label as Label)
		UITestFramework.assert_true(level_text.contains("4"), "Level display not updated correctly")
	
	UITestFramework.end_test(UITestFramework.TestResult.PASS)

func save_test_report(report: String, filename: String):
	var file = FileAccess.open("user://test_reports_%s_%d.txt" % [filename, Time.get_unix_time_from_system()], FileAccess.WRITE)
	if file:
		file.store_string(report)
		file.close()
		print("Test report saved to: user://test_reports_%s_%d.txt" % [filename, Time.get_unix_time_from_system()])
